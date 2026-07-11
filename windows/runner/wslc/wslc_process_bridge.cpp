#include "wslc_process_bridge.h"

#include <flutter/standard_method_codec.h>

#include <ctime>
#include <sstream>

// CoTaskMemFree
#include <combaseapi.h>

// ============================================================
// ContainerLogStreamHandler Implementation
// ============================================================

ContainerLogStreamHandler::ContainerLogStreamHandler(
    WslcContainer container, const std::vector<std::string>& cmd)
    : container_(container), cmd_(cmd) {}

ContainerLogStreamHandler::~ContainerLogStreamHandler() {
  cancelled_ = true;
  if (process_) {
    WslcReleaseProcess(process_);
    process_ = nullptr;
  }
  if (com_initialized_) {
    CoUninitialize();
    com_initialized_ = false;
  }
}

bool ContainerLogStreamHandler::CreateProcess(std::string& errorMsg) {
  if (process_) return true;

  WslcProcessSettings procSettings;
  HRESULT hr = WslcInitProcessSettings(&procSettings);
  if (FAILED(hr)) {
    errorMsg = "Failed to init process settings: " +
               wslc_util::HresultToString(hr);
    return false;
  }

  std::vector<PCSTR> argv;
  for (const auto& arg : cmd_) {
    argv.push_back(arg.c_str());
  }
  hr = WslcSetProcessSettingsCmdLine(&procSettings, argv.data(),
                                      argv.size());
  if (FAILED(hr)) {
    errorMsg = "Failed to set command line: " +
               wslc_util::HresultToString(hr);
    return false;
  }

  WslcProcessCallbacks callbacks = {};
  callbacks.onStdOut = &OnStdOut;
  callbacks.onStdErr = &OnStdErr;
  callbacks.onExit = &OnExit;
  hr = WslcSetProcessSettingsCallbacks(&procSettings, &callbacks, this);
  if (FAILED(hr)) {
    errorMsg = "Failed to register callbacks: " +
               wslc_util::HresultToString(hr);
    return false;
  }

  PWSTR errorMsgW = nullptr;
  hr = WslcCreateContainerProcess(container_, &procSettings,
                                   &process_, &errorMsgW);
  if (FAILED(hr)) {
    if (errorMsgW) {
      errorMsg = wslc_util::WideToUtf8(errorMsgW);
      CoTaskMemFree(errorMsgW);
    } else {
      errorMsg = "Process creation failed: " +
                 wslc_util::HresultToString(hr);
    }
    return false;
  }

  if (errorMsgW) CoTaskMemFree(errorMsgW);
  return true;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
ContainerLogStreamHandler::OnListenInternal(
    const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  sink_ = std::move(events);

  // If process exited before the Dart listener attached, replay the exit event
  if (exited_) {
    PushLog("exit", std::to_string(exit_code_));
    sink_->EndOfStream();
    sink_.reset();
    return nullptr;
  }

  // If process was not pre-created (should not normally happen), fall back
  if (!process_) {
    CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    com_initialized_ = true;
    std::string errorMsg;
    if (!CreateProcess(errorMsg)) {
      PushLog("stderr", errorMsg);
      PushLog("exit", "");
      sink_->EndOfStream();
      sink_.reset();
    }
  }

  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
ContainerLogStreamHandler::OnCancelInternal(
    const flutter::EncodableValue* arguments) {
  cancelled_ = true;
  if (process_) {
    WslcReleaseProcess(process_);
    process_ = nullptr;
  }
  sink_.reset();
  if (com_initialized_) {
    CoUninitialize();
    com_initialized_ = false;
  }
  return nullptr;
}

void CALLBACK ContainerLogStreamHandler::OnStdOut(
    WslcProcessIOHandle io, const BYTE* data, uint32_t len, PVOID ctx) {
  auto* self = static_cast<ContainerLogStreamHandler*>(ctx);
  if (self->cancelled_ || !self->sink_) return;

  std::string text(reinterpret_cast<const char*>(data), len);
  self->PushLog("stdout", text);
}

void CALLBACK ContainerLogStreamHandler::OnStdErr(
    WslcProcessIOHandle io, const BYTE* data, uint32_t len, PVOID ctx) {
  auto* self = static_cast<ContainerLogStreamHandler*>(ctx);
  if (self->cancelled_ || !self->sink_) return;

  std::string text(reinterpret_cast<const char*>(data), len);
  self->PushLog("stderr", text);
}

void CALLBACK ContainerLogStreamHandler::OnExit(INT32 exitCode, PVOID ctx) {
  auto* self = static_cast<ContainerLogStreamHandler*>(ctx);
  if (self->cancelled_) return;

  // Track exit even without sink (process may exit before Dart attaches)
  self->exited_ = true;
  self->exit_code_ = exitCode;

  if (self->sink_) {
    self->PushLog("exit", std::to_string(exitCode));
    self->sink_->EndOfStream();
    self->sink_.reset();
  }
}

void ContainerLogStreamHandler::PushLog(const std::string& stream,
                                         const std::string& text) {
  if (!sink_) return;
  flutter::EncodableMap event;
  event["stream"] = stream;
  event["text"] = text;
  event["timestamp"] = static_cast<int64_t>(time(nullptr));
  sink_->Success(flutter::EncodableValue(event));
}

// ============================================================
// WslcProcessBridge Implementation
// ============================================================

WslcProcessBridge::WslcProcessBridge(flutter::BinaryMessenger* messenger)
    : messenger_(messenger) {}

WslcProcessBridge::~WslcProcessBridge() {
  // EventChannel objects destroyed here; their destructors cancel handlers
}

bool WslcProcessBridge::StartLogStream(
    WslcContainer container, const std::string& containerId,
    const std::vector<std::string>& cmd, std::string& errorMsg) {
  if (!container) {
    errorMsg = "Invalid container handle";
    return false;
  }

  // Cancel existing stream for this container
  StopLogStream(containerId);

  // Build channel name
  std::string channelName = "com.wslc.dashboard/events/logs/" + containerId;

  // Create handler and create process immediately on the calling thread.
  // This prevents a race where the container exits before Dart attaches.
  auto handler = std::make_unique<ContainerLogStreamHandler>(container, cmd);
  if (!handler->CreateProcess(errorMsg)) {
    return false;
  }

  auto channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger_, channelName,
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetStreamHandler(std::move(handler));

  activeStreams_[containerId] = std::move(channel);
  return true;
}

void WslcProcessBridge::StopLogStream(const std::string& containerId) {
  activeStreams_.erase(containerId);
  // EventChannel destructor -> handler destructor -> process released
}
