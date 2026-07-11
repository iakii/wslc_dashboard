#ifndef WSLC_PROCESS_BRIDGE_H_
#define WSLC_PROCESS_BRIDGE_H_

#include <flutter/encodable_value.h>
#include <flutter/binary_messenger.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler.h>
#include <flutter/event_sink.h>

#include <atomic>
#include <map>
#include <memory>
#include <string>
#include <wslcsdk.h>

/**
 * @file wslc_process_bridge.h
 * @brief Process management and container log streaming via EventChannel.
 *
 * When a container is started, a process (e.g. /bin/sh) is created
 * with stdout/stderr callbacks. The callbacks push log events to Dart
 * via EventChannel.
 */

namespace wslc_util {
std::string HresultToString(HRESULT hr);
std::string WideToUtf8(PCWSTR wide);
std::wstring Utf8ToWide(PCSTR utf8);
}  // namespace wslc_util

/**
 * @brief Manages EventChannel lifecycle for container log streaming.
 *
 * OnListenInternal creates a process inside the container with stdout/stderr
 * callbacks. The callbacks fire from SDK internal threads and push log
 * events to the EventSink. The process handle is released on cancel/exit.
 */
class ContainerLogStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  ContainerLogStreamHandler(WslcContainer container,
                            const std::vector<std::string>& cmd);
  ~ContainerLogStreamHandler() override;

  /// Create the container process (blocking, requires COM on calling thread).
  /// Called from StartLogStream on the background thread immediately after
  /// WslcStartContainer to prevent container exit before listener attaches.
  bool CreateProcess(std::string& errorMsg);

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
      override;

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue* arguments) override;

 private:
  /// Callbacks invoked by SDK on internal threads
  static void CALLBACK OnStdOut(WslcProcessIOHandle io,
                                const BYTE* data, uint32_t len, PVOID ctx);
  static void CALLBACK OnStdErr(WslcProcessIOHandle io,
                                const BYTE* data, uint32_t len, PVOID ctx);
  static void CALLBACK OnExit(INT32 exitCode, PVOID ctx);

  /// Push a log event to the EventSink
  void PushLog(const std::string& stream, const std::string& text);

  WslcContainer container_;
  WslcProcess process_ = nullptr;
  std::vector<std::string> cmd_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
  std::atomic<bool> cancelled_{false};
  bool com_initialized_ = false;  // COM initialized on handler thread

  /// Track early exit before listener attaches
  std::atomic<bool> exited_{false};
  int exit_code_ = 0;
};

/**
 * @brief Process management bridge.
 *
 * Owns EventChannel instances for active log streams.
 */
class WslcProcessBridge {
 public:
  explicit WslcProcessBridge(flutter::BinaryMessenger* messenger);
  ~WslcProcessBridge();

  // Non-copyable
  WslcProcessBridge(const WslcProcessBridge&) = delete;
  WslcProcessBridge& operator=(const WslcProcessBridge&) = delete;

  /**
   * @brief Start log streaming for a container (non-blocking).
   * Creates an EventChannel and spawns a process with I/O callbacks.
   * @param container  Valid container handle
   * @param containerId  Hex ID used for the EventChannel name
   * @param cmd  Command to run (e.g. {"/bin/sh"})
   * @return true on success
   */
  bool StartLogStream(WslcContainer container, const std::string& containerId,
                      const std::vector<std::string>& cmd,
                      std::string& errorMsg);

  /**
   * @brief Stop log streaming for a container.
   */
  void StopLogStream(const std::string& containerId);

 private:
  flutter::BinaryMessenger* messenger_;
  std::map<std::string,
           std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>>
      activeStreams_;
};

#endif  // WSLC_PROCESS_BRIDGE_H_
