#ifndef WSLC_NATIVE_PLUGIN_H_
#define WSLC_NATIVE_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>

#include "wslc_service_bridge.h"

/**
 * @file wslc_native_plugin.h
 * @brief WSL Container native bridge plugin entry point
 *
 * Registers MethodChannel "com.wslc.dashboard/api" and dispatches
 * incoming method calls to the appropriate bridge handler.
 */
class WslcNativePlugin {
 public:
  explicit WslcNativePlugin(flutter::BinaryMessenger* messenger);
  ~WslcNativePlugin();

  // Non-copyable
  WslcNativePlugin(const WslcNativePlugin&) = delete;
  WslcNativePlugin& operator=(const WslcNativePlugin&) = delete;

 private:
  /// MethodChannel dispatch entry
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // ======== Method Handlers ========

  /// checkComponents: query WSL component status
  void HandleCheckComponents(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // ======== Members ========

  /// MethodChannel instance
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  /// WSL service bridge (component check)
  std::unique_ptr<WslcServiceBridge> serviceBridge_;
};

#endif  // WSLC_NATIVE_PLUGIN_H_
