#ifndef WSLC_NATIVE_PLUGIN_H_
#define WSLC_NATIVE_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>

#include <objbase.h>

#include <memory>
#include <string>
#include <thread>
#include <vector>

#include "wslc_service_bridge.h"
#include "wslc_session_bridge.h"
#include "wslc_image_bridge.h"
#include "wslc_container_bridge.h"
#include "wslc_process_bridge.h"

/**
 * @file wslc_native_plugin.h
 * @brief WSL Container native bridge plugin entry point
 *
 * Registers MethodChannel "com.wslc.dashboard/api" and dispatches
 * incoming method calls to the appropriate bridge handler.
 *
 * Blocking SDK calls are dispatched to background threads via std::thread.
 * Thread handles are stored and joined on destruction.
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

  /// checkComponents: query WSL component status (fast, no thread)
  void HandleCheckComponents(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// createSession: create a new WSL Container session (std::thread)
  void HandleCreateSession(
      const flutter::EncodableValue& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// terminateSession: stop the current session (std::thread)
  void HandleTerminateSession(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// getSessionStatus: return cached session state (fast, no thread)
  void HandleGetSessionStatus(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// listImages: enumerate images in the session (std::thread)
  void HandleListImages(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// pullImage: start image pull, return operationId (fast, sets up EventChannel)
  void HandlePullImage(
      const flutter::EncodableValue& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// deleteImage: remove an image by name/ID (std::thread)
  void HandleDeleteImage(
      const flutter::EncodableValue& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // ======== Container Handlers ========

  /// listContainers: enumerate all containers (std::thread)
  void HandleListContainers(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// createContainer: create a new container (std::thread)
  void HandleCreateContainer(
      const flutter::EncodableValue& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// startContainer: start a container + log stream (fast, sets up EventChannel)
  void HandleStartContainer(
      const flutter::EncodableValue& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// stopContainer: stop a running container (std::thread)
  void HandleStopContainer(
      const flutter::EncodableValue& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  /// deleteContainer: remove a container (std::thread)
  void HandleDeleteContainer(
      const flutter::EncodableValue& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // ======== Utility Helpers ========

  /// Extract int64_t from EncodableMap, with default
  static int64_t GetInt(const flutter::EncodableMap& map, const std::string& key,
                        int64_t defaultValue = 0);

  /// Extract string from EncodableMap, with default
  static std::string GetString(const flutter::EncodableMap& map,
                                const std::string& key,
                                const std::string& defaultValue = "");

  /// Launch a background task on a std::thread with COM initialized.
  /// SDK functions require COM to be initialized on the calling thread.
  template <typename F>
  void RunOnBackground(F&& task) {
    backgroundThreads_.emplace_back([task = std::forward<F>(task)]() mutable {
      HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
      task();
      if (SUCCEEDED(hr)) CoUninitialize();
    });
  }

  // ======== Members ========

  /// MethodChannel instance
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  /// WSL service bridge (component check)
  std::unique_ptr<WslcServiceBridge> serviceBridge_;

  /// WSL session bridge (lifecycle)
  std::unique_ptr<WslcSessionBridge> sessionBridge_;

  /// WSL image bridge (list, pull, delete)
  std::unique_ptr<WslcImageBridge> imageBridge_;

  /// WSL container bridge (CRUD)
  std::unique_ptr<WslcContainerBridge> containerBridge_;

  /// WSL process bridge (log streaming)
  std::unique_ptr<WslcProcessBridge> processBridge_;

  /// Background thread handles (joined on destruction)
  std::vector<std::thread> backgroundThreads_;
};

// ============================================================
// Shared Utility Functions
// ============================================================
namespace wslc_util {

/// Convert UTF-16 wide string to UTF-8 std::string
std::string WideToUtf8(PCWSTR wide);

/// Convert UTF-8 std::string to UTF-16 wide string
std::wstring Utf8ToWide(PCSTR utf8);

/// Convert HRESULT to human-readable string (includes WSLC error codes)
std::string HresultToString(HRESULT hr);

}  // namespace wslc_util

#endif  // WSLC_NATIVE_PLUGIN_H_
