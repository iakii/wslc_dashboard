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
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
ContainerLogStreamHandler::OnListenInternal(
    const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  sink_ = std::move(events);

  // Build process settings
  WslcProcessSettings procSettings;
  HRESULT hr = WslcInitProcessSettings(&procSettings);
  if (FAILED(hr)) {
    if (sink_) {
      PushLog("stderr", "Failed to init process settings: " +
               wslc_util::HresultToString(hr));
      PushLog("exit", "");
      sink_->EndOfStream();
    }
    return nullptr;
  }

  // Set command line
  std::vector<PCSTR> argv;
  for (const auto& arg : cmd_) {
    argv.push_back(arg.c_str());
  }
  hr = WslcSetProcessSettingsCmdLine(&procSettings, argv.data(), argv.size());
  if (FAILED(hr)) {
    if (sink_) {
      PushLog("stderr", "Failed to set command line: " +
               wslc_util::HresultToString(hr));
      PushLog("exit", "");
      sink_->EndOfStream();
    }
    return nullptr;
  }

  // Register callbacks
  WslcProcessCallbacks callbacks = {};
  callbacks.onStdOut = &OnStdOut;
  callbacks.onStdErr = &OnStdErr;
  callbacks.onExit = &OnExit;
  hr = WslcSetProcessSettingsCallbacks(&procSettings, &callbacks, this);
  if (FAILED(hr)) {
    if (sink_) {
      PushLog("stderr", "Failed to register callbacks: " +
               wslc_util::HresultToString(hr));
      PushLog("exit", "");
      sink_->EndOfStream();
    }
    return nullptr;
  }

  // Create process in container
  PWSTR errorMsg = nullptr;
  hr = WslcCreateContainerProcess(container_, &procSettings,
                                   &process_, &errorMsg);
  if (FAILED(hr)) {
    std::string msg;
    if (errorMsg) {
      msg = wslc_util::WideToUtf8(errorMsg);
      CoTaskMemFree(errorMsg);
    } else {
      msg = wslc_util::HresultToString(hr);
    }
    if (sink_) {
      PushLog("stderr", "Process creation failed: " + msg);
      PushLog("exit", "");
      sink_->EndOfStream();
    }
    return nullptr;
  }

  // Free optional message even on success
  if (errorMsg) CoTaskMemFree(errorMsg);

  // Callbacks will now fire from SDK threads
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
  if (self->cancelled_ || !self->sink_) return;

  self->PushLog("exit", std::to_string(exitCode));
  self->sink_->EndOfStream();
  self->sink_.reset();
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

  // Create handler and EventChannel
  auto handler = std::make_unique<ContainerLogStreamHandler>(container, cmd);
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
