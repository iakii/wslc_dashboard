#include "wslc_native_plugin.h"

#include <flutter/standard_method_codec.h>

#include <sstream>
#include <windows.h>

/**
 * MethodChannel name - must match Dart side AppConstants.wslcApiChannel
 */
static constexpr char kChannelName[] = "com.wslc.dashboard/api";

// ============================================================
// Utility Functions
// ============================================================

namespace wslc_util {

std::string WideToUtf8(PCWSTR wide) {
  if (!wide) return {};
  int len = WideCharToMultiByte(CP_UTF8, 0, wide, -1, nullptr, 0, nullptr, nullptr);
  if (len <= 0) return {};
  // Allocate full buffer including null terminator
  std::string result(static_cast<size_t>(len), '\0');
  int written = WideCharToMultiByte(CP_UTF8, 0, wide, -1,
                                     result.data(), len, nullptr, nullptr);
  if (written > 0) {
    // Remove the trailing null terminator from the std::string length
    result.resize(static_cast<size_t>(written) - 1);
  }
  return result;
}

std::wstring Utf8ToWide(PCSTR utf8) {
  if (!utf8) return {};
  int len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, nullptr, 0);
  if (len <= 0) return {};
  // Allocate full buffer including null terminator
  std::wstring result(static_cast<size_t>(len), L'\0');
  int written = MultiByteToWideChar(CP_UTF8, 0, utf8, -1,
                                     result.data(), len);
  if (written > 0) {
    // Remove the trailing null terminator from the std::wstring length
    result.resize(static_cast<size_t>(written) - 1);
  }
  return result;
}

std::string HresultToString(HRESULT hr) {
  switch (hr) {
    // WSLC-specific error codes
    case 0x80040601: return "WSLC_E_IMAGE_NOT_FOUND";
    case 0x80040602: return "WSLC_E_CONTAINER_PREFIX_AMBIGUOUS";
    case 0x80040603: return "WSLC_E_CONTAINER_NOT_FOUND";
    case 0x80040604: return "WSLC_E_VOLUME_NOT_FOUND";
    case 0x80040605: return "WSLC_E_CONTAINER_NOT_RUNNING";
    case 0x80040606: return "WSLC_E_CONTAINER_IS_RUNNING";
    case 0x80040607: return "WSLC_E_SESSION_RESERVED";
    case 0x80040608: return "WSLC_E_INVALID_SESSION_NAME";
    case 0x80040609: return "WSLC_E_NETWORK_NOT_FOUND";
    case 0x8004060A: return "WSLC_E_WU_SEARCH_FAILED";
    case 0x8004060B: return "WSLC_E_SDK_UPDATE_NEEDED";
    case 0x8004060C: return "WSLC_E_CONTAINER_DISABLED";
    case 0x8004060D: return "WSLC_E_REGISTRY_BLOCKED_BY_POLICY";
    case 0x8004060E: return "WSLC_E_VOLUME_NOT_AVAILABLE";
    case 0x8004060F: return "WSLC_E_SESSION_NOT_FOUND";
    // Standard HRESULTs
    case E_INVALIDARG:  return "E_INVALIDARG";
    case E_OUTOFMEMORY: return "E_OUTOFMEMORY";
    case E_FAIL:        return "E_FAIL";
    default: {
      if (SUCCEEDED(hr)) return "S_OK";
      char buf[32];
      snprintf(buf, sizeof(buf), "NATIVE_ERROR_0x%08lX",
               static_cast<unsigned long>(hr));
      return buf;
    }
  }
}

}  // namespace wslc_util

// ============================================================
// WslcNativePlugin Implementation
// ============================================================

WslcNativePlugin::WslcNativePlugin(flutter::BinaryMessenger* messenger)
    : serviceBridge_(std::make_unique<WslcServiceBridge>()),
      sessionBridge_(std::make_unique<WslcSessionBridge>()),
      imageBridge_(std::make_unique<WslcImageBridge>(messenger)),
      containerBridge_(std::make_unique<WslcContainerBridge>()),
      processBridge_(std::make_unique<WslcProcessBridge>(messenger)) {
  // Create MethodChannel and set handler
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  // Bind MethodCall handler; lifecycle managed by this object
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        HandleMethodCall(call, std::move(result));
      });
}

WslcNativePlugin::~WslcNativePlugin() {
  // Clear MethodChannel handler to prevent dangling pointer
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
  }

  // Join all background threads before destroying bridges
  for (auto& t : backgroundThreads_) {
    if (t.joinable()) {
      t.join();
    }
  }
  backgroundThreads_.clear();
}

void WslcNativePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();

  if (method == "checkComponents") {
    HandleCheckComponents(std::move(result));
  } else if (method == "createSession") {
    HandleCreateSession(*call.arguments(), std::move(result));
  } else if (method == "terminateSession") {
    HandleTerminateSession(std::move(result));
  } else if (method == "getSessionStatus") {
    HandleGetSessionStatus(std::move(result));
  } else if (method == "listImages") {
    HandleListImages(std::move(result));
  } else if (method == "pullImage") {
    HandlePullImage(*call.arguments(), std::move(result));
  } else if (method == "deleteImage") {
    HandleDeleteImage(*call.arguments(), std::move(result));
  } else if (method == "listContainers") {
    HandleListContainers(std::move(result));
  } else if (method == "createContainer") {
    HandleCreateContainer(*call.arguments(), std::move(result));
  } else if (method == "startContainer") {
    HandleStartContainer(*call.arguments(), std::move(result));
  } else if (method == "stopContainer") {
    HandleStopContainer(*call.arguments(), std::move(result));
  } else if (method == "deleteContainer") {
    HandleDeleteContainer(*call.arguments(), std::move(result));
  } else {
    result->NotImplemented();
  }
}

// ======== Utility Methods ========

int64_t WslcNativePlugin::GetInt(const flutter::EncodableMap& map,
                                   const std::string& key,
                                   int64_t defaultValue) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it != map.end()) {
    if (std::holds_alternative<int32_t>(it->second)) {
      return static_cast<int64_t>(std::get<int32_t>(it->second));
    }
    if (std::holds_alternative<int64_t>(it->second)) {
      return std::get<int64_t>(it->second);
    }
  }
  return defaultValue;
}

std::string WslcNativePlugin::GetString(const flutter::EncodableMap& map,
                                         const std::string& key,
                                         const std::string& defaultValue) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it != map.end() && std::holds_alternative<std::string>(it->second)) {
    return std::get<std::string>(it->second);
  }
  return defaultValue;
}

// ======== Method Handlers ========

void WslcNativePlugin::HandleCheckComponents(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!serviceBridge_) {
    result->Error("PLUGIN_ERROR", "WslcNativePlugin not initialized");
    return;
  }

  auto missingFlags = serviceBridge_->GetMissingComponents();
  auto version = serviceBridge_->GetVersion();

  // Merge session status (if a session exists) into the response
  auto sessionStatus = sessionBridge_->GetStatus();

  flutter::EncodableMap response;
  response[flutter::EncodableValue("missing")] =
      flutter::EncodableValue(static_cast<int64_t>(missingFlags));
  response[flutter::EncodableValue("version")] =
      flutter::EncodableValue(version);
  response[flutter::EncodableValue("isRunning")] =
      flutter::EncodableValue(sessionStatus.isRunning);
  response[flutter::EncodableValue("imageCount")] =
      flutter::EncodableValue(static_cast<int64_t>(sessionStatus.imageCount));
  response[flutter::EncodableValue("containerCount")] =
      flutter::EncodableValue(static_cast<int64_t>(sessionStatus.containerCount));

  result->Success(flutter::EncodableValue(response));
}

void WslcNativePlugin::HandleCreateSession(
    const flutter::EncodableValue& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* map = std::get_if<flutter::EncodableMap>(&args);
  if (!map) {
    result->Error("INVALID_ARGUMENTS", "Expected a map");
    return;
  }

  auto name = GetString(*map, "name", "wslc_dashboard");
  auto dataPath = GetString(*map, "dataPath", "");
  auto cpuCount = GetInt(*map, "cpuCount", 2);
  auto memoryMB = GetInt(*map, "memoryMB", 2048);

  // Run on background thread (CreateSession is blocking)
  RunOnBackground([this, name, dataPath, cpuCount, memoryMB,
                   result = std::move(result)]() mutable {
    std::string errorMsg;
    auto status = sessionBridge_->Create(
        name, dataPath, static_cast<int>(cpuCount),
        static_cast<int>(memoryMB), errorMsg);

    if (status.isRunning) {
      flutter::EncodableMap response;
      response["sessionId"] = status.sessionId;
      response["isRunning"] = status.isRunning;
      response["imageCount"] = static_cast<int64_t>(status.imageCount);
      response["containerCount"] = static_cast<int64_t>(status.containerCount);
      response["version"] = "";
      result->Success(flutter::EncodableValue(response));
    } else {
      result->Error("CREATE_FAILED", errorMsg);
    }
  });
}

void WslcNativePlugin::HandleTerminateSession(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  RunOnBackground([this, result = std::move(result)]() mutable {
    sessionBridge_->Terminate();
    flutter::EncodableMap response;
    response["success"] = true;
    result->Success(flutter::EncodableValue(response));
  });
}

void WslcNativePlugin::HandleGetSessionStatus(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!sessionBridge_->IsValid()) {
    result->Error("NOT_READY", "No active session");
    return;
  }

  auto status = sessionBridge_->GetStatus();
  flutter::EncodableMap response;
  response["isRunning"] = status.isRunning;
  response["imageCount"] = static_cast<int64_t>(status.imageCount);
  response["containerCount"] = static_cast<int64_t>(status.containerCount);
  response["version"] = status.version;
  response["startedAt"] = static_cast<int64_t>(status.startedAt);
  result->Success(flutter::EncodableValue(response));
}

void WslcNativePlugin::HandleListImages(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!sessionBridge_->IsValid()) {
    result->Error("SESSION_NOT_READY", "No active session");
    return;
  }

  WslcSession session = sessionBridge_->GetHandle();

  RunOnBackground([this, session, result = std::move(result)]() mutable {
    std::string errorMsg;
    auto images = imageBridge_->ListImages(session, errorMsg);

    if (images.IsNull()) {
      result->Error("LIST_FAILED", errorMsg);
    } else {
      result->Success(images);
    }
  });
}

void WslcNativePlugin::HandlePullImage(
    const flutter::EncodableValue& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* map = std::get_if<flutter::EncodableMap>(&args);
  if (!map) {
    result->Error("INVALID_ARGUMENTS", "Expected a map");
    return;
  }

  auto imageName = GetString(*map, "imageName");
  if (imageName.empty()) {
    result->Error("INVALID_ARGUMENTS", "imageName is required");
    return;
  }

  if (!sessionBridge_->IsValid()) {
    result->Error("SESSION_NOT_READY", "No active session");
    return;
  }

  // StartPull is fast (only sets up EventChannel), no background thread needed
  WslcSession session = sessionBridge_->GetHandle();
  std::string operationId = imageBridge_->StartPull(session, imageName);

  flutter::EncodableMap response;
  response["operationId"] = operationId;
  result->Success(flutter::EncodableValue(response));
}

void WslcNativePlugin::HandleDeleteImage(
    const flutter::EncodableValue& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* map = std::get_if<flutter::EncodableMap>(&args);
  if (!map) {
    result->Error("INVALID_ARGUMENTS", "Expected a map");
    return;
  }

  auto imageId = GetString(*map, "imageId");
  if (imageId.empty()) {
    result->Error("INVALID_ARGUMENTS", "imageId is required");
    return;
  }

  if (!sessionBridge_->IsValid()) {
    result->Error("SESSION_NOT_READY", "No active session");
    return;
  }

  WslcSession session = sessionBridge_->GetHandle();

  RunOnBackground([this, session, imageId,
                   result = std::move(result)]() mutable {
    std::string errorMsg;
    bool ok = imageBridge_->DeleteImage(session, imageId, errorMsg);

    if (ok) {
      flutter::EncodableMap response;
      response["success"] = true;
      result->Success(flutter::EncodableValue(response));
    } else {
      result->Error("DELETE_FAILED", errorMsg);
    }
  });
}

// ======== Container Handlers ========

void WslcNativePlugin::HandleListContainers(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!sessionBridge_->IsValid()) {
    result->Error("SESSION_NOT_READY", "No active session");
    return;
  }

  RunOnBackground([this, result = std::move(result)]() mutable {
    std::string errorMsg;
    auto list = containerBridge_->List(errorMsg);
    result->Success(list);
  });
}

void WslcNativePlugin::HandleCreateContainer(
    const flutter::EncodableValue& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* map = std::get_if<flutter::EncodableMap>(&args);
  if (!map) {
    result->Error("INVALID_ARGUMENTS", "Expected a map");
    return;
  }

  auto image = GetString(*map, "image");
  auto name = GetString(*map, "name");
  // Parse cmd as list of strings (Dart sends List<String>)
  std::vector<std::string> cmd;
  auto cmdIt = map->find(flutter::EncodableValue("cmd"));
  if (cmdIt != map->end() && std::holds_alternative<flutter::EncodableList>(cmdIt->second)) {
    const auto& cmdList = std::get<flutter::EncodableList>(cmdIt->second);
    for (const auto& item : cmdList) {
      if (std::holds_alternative<std::string>(item)) {
        cmd.push_back(std::get<std::string>(item));
      }
    }
  }

  if (image.empty()) {
    result->Error("INVALID_ARGUMENTS", "image is required");
    return;
  }

  if (!sessionBridge_->IsValid()) {
    result->Error("SESSION_NOT_READY", "No active session");
    return;
  }

  WslcSession session = sessionBridge_->GetHandle();

  RunOnBackground([this, session, image, name, cmd,
                   result = std::move(result)]() mutable {
    std::string errorMsg;
    auto info = containerBridge_->Create(session, image, name, cmd, errorMsg);

    if (info.containerId.empty()) {
      result->Error("CREATE_FAILED", errorMsg);
      return;
    }

    flutter::EncodableMap response;
    response["id"] = info.containerId;
    response["name"] = info.name;
    response["imageName"] = info.imageName;
    response["status"] = WslcContainerBridge::StateString(info.state);
    // Convert to ISO 8601 string
    {
      time_t secs = static_cast<time_t>(info.createdAt / 1000);
      struct tm tm_buf;
      gmtime_s(&tm_buf, &secs);
      char buf[32];
      strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &tm_buf);
      response["createdAt"] = std::string(buf);
    }
    result->Success(flutter::EncodableValue(response));
  });
}

void WslcNativePlugin::HandleStartContainer(
    const flutter::EncodableValue& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* map = std::get_if<flutter::EncodableMap>(&args);
  if (!map) {
    result->Error("INVALID_ARGUMENTS", "Expected a map");
    return;
  }

  auto containerId = GetString(*map, "containerId");
  if (containerId.empty()) {
    result->Error("INVALID_ARGUMENTS", "containerId is required");
    return;
  }

  // Container is created with an init process (/bin/sleep 86400), so
  // WslcStartContainer will not cause immediate exit. After start, create
  // a separate log stream process (/bin/sh) for user interaction.
  RunOnBackground([this, containerId,
                   result = std::move(result)]() mutable {
    std::string errorMsg;
    if (!containerBridge_->Start(containerId, errorMsg)) {
      result->Error("START_FAILED", errorMsg);
      return;
    }

    WslcContainer handle = containerBridge_->GetHandle(containerId);
    std::vector<std::string> cmd = {"/bin/sh"};
    std::string logError;
    if (!processBridge_->StartLogStream(handle, containerId, cmd, logError)) {
      result->Error("PROCESS_FAILED", logError);
      return;
    }

    containerBridge_->SetRunning(containerId);
    flutter::EncodableMap response;
    response["success"] = true;
    response["logChannel"] = containerId;
    result->Success(flutter::EncodableValue(response));
  });
}

void WslcNativePlugin::HandleStopContainer(
    const flutter::EncodableValue& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* map = std::get_if<flutter::EncodableMap>(&args);
  if (!map) {
    result->Error("INVALID_ARGUMENTS", "Expected a map");
    return;
  }

  auto containerId = GetString(*map, "containerId");
  if (containerId.empty()) {
    result->Error("INVALID_ARGUMENTS", "containerId is required");
    return;
  }

  RunOnBackground([this, containerId,
                   result = std::move(result)]() mutable {
    // Stop log streaming first
    processBridge_->StopLogStream(containerId);

    std::string errorMsg;
    bool ok = containerBridge_->Stop(containerId, errorMsg);

    if (ok) {
      flutter::EncodableMap response;
      response["success"] = true;
      result->Success(flutter::EncodableValue(response));
    } else {
      result->Error("STOP_FAILED", errorMsg);
    }
  });
}

void WslcNativePlugin::HandleDeleteContainer(
    const flutter::EncodableValue& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* map = std::get_if<flutter::EncodableMap>(&args);
  if (!map) {
    result->Error("INVALID_ARGUMENTS", "Expected a map");
    return;
  }

  auto containerId = GetString(*map, "containerId");
  if (containerId.empty()) {
    result->Error("INVALID_ARGUMENTS", "containerId is required");
    return;
  }

  RunOnBackground([this, containerId,
                   result = std::move(result)]() mutable {
    // Stop log streaming
    processBridge_->StopLogStream(containerId);

    std::string errorMsg;
    bool ok = containerBridge_->Delete(containerId, errorMsg);

    if (ok) {
      flutter::EncodableMap response;
      response["success"] = true;
      result->Success(flutter::EncodableValue(response));
    } else {
      result->Error("DELETE_FAILED", errorMsg);
    }
  });
}
