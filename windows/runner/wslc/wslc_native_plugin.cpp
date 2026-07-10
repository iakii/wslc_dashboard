#include "wslc_native_plugin.h"

#include <flutter/standard_method_codec.h>

#include <sstream>

/**
 * MethodChannel name - must match Dart side AppConstants.wslcApiChannel
 */
static constexpr char kChannelName[] = "com.wslc.dashboard/api";

WslcNativePlugin::WslcNativePlugin(flutter::BinaryMessenger* messenger)
    : serviceBridge_(std::make_unique<WslcServiceBridge>()) {
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
  // Clear handler to prevent dangling pointer
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
  }
}

void WslcNativePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();

  if (method == "checkComponents") {
    HandleCheckComponents(std::move(result));
  } else {
    result->NotImplemented();
  }
}

void WslcNativePlugin::HandleCheckComponents(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!serviceBridge_) {
    result->Error("PLUGIN_ERROR", "WslcNativePlugin not initialized");
    return;
  }

  // Query component status
  auto missingFlags = serviceBridge_->GetMissingComponents();
  auto version = serviceBridge_->GetVersion();

  // Build response map: {"missing": int, "version": string}
  flutter::EncodableMap response;
  response[flutter::EncodableValue("missing")] =
      flutter::EncodableValue(static_cast<int64_t>(missingFlags));
  response[flutter::EncodableValue("version")] =
      flutter::EncodableValue(version);

  result->Success(flutter::EncodableValue(response));
}
