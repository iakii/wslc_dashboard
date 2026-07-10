#ifndef WSLC_IMAGE_BRIDGE_H_
#define WSLC_IMAGE_BRIDGE_H_

#include <flutter/encodable_value.h>
#include <flutter/binary_messenger.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler.h>
#include <flutter/event_sink.h>

#include <atomic>
#include <map>
#include <memory>
#include <string>
#include <thread>
#include <wslcsdk.h>

/**
 * @file wslc_image_bridge.h
 * @brief Image management bridge: list, pull (with progress events), delete.
 *
 * PullImage is a two-phase operation:
 * 1. StartPull() returns an operationId immediately
 * 2. When Dart subscribes to EventChannel("events/pull/{id}"),
 *    the StreamHandler spawns a background thread and streams progress.
 */

// Forward declare utilities
namespace wslc_util {
std::string HresultToString(HRESULT hr);
std::string WideToUtf8(PCWSTR wide);
}  // namespace wslc_util

/**
 * @brief Manages the EventChannel lifecycle for a single pull operation.
 *
 * OnListenInternal spawns a std::thread that calls WslcPullSessionImage
 * (blocking). Progress callbacks fire from that thread and push to the
 * EventSink. The thread is joined when the stream is cancelled or pull
 * completes.
 */
class PullStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  PullStreamHandler(WslcSession session, std::string imageName);
  ~PullStreamHandler() override;

 protected:
  // StreamHandler virtual methods (override OnListenInternal/OnCancelInternal,
  // NOT OnListen/OnCancel which are public non-virtual)
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
      override;

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue* arguments) override;

 private:
  /// Progress callback invoked by SDK during WslcPullSessionImage.
  /// Static method; context is the PullStreamHandler instance.
  static HRESULT CALLBACK OnProgress(
      const WslcImageProgressMessage* progress, PVOID context);

  /// Convert WslcImageProgressStatus enum to string
  static std::string StatusString(WslcImageProgressStatus s);

  std::atomic<bool> cancelled_{false};
  WslcSession session_;
  std::string imageName_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
  std::thread worker_;
};

/**
 * @brief Image management bridge.
 *
 * Owns EventChannel instances for active pull operations.
 * All methods that call blocking SDK functions should be invoked
 * from a background thread (except StartPull which returns immediately).
 */
class WslcImageBridge {
 public:
  explicit WslcImageBridge(flutter::BinaryMessenger* messenger);
  ~WslcImageBridge();

  // Non-copyable
  WslcImageBridge(const WslcImageBridge&) = delete;
  WslcImageBridge& operator=(const WslcImageBridge&) = delete;

  /**
   * @brief List images in the session (BLOCKING).
   * @param session  Valid session handle
   * @param errorMsg (out) Error description on failure
   * @return EncodableValue list of maps, or null EncodableValue on failure
   */
  flutter::EncodableValue ListImages(WslcSession session,
                                     std::string& errorMsg);

  /**
   * @brief Initiate an image pull (non-blocking, sets up EventChannel).
   * @param session    Valid session handle
   * @param imageName  Image reference (e.g. "alpine:latest")
   * @return operationId string
   */
  std::string StartPull(WslcSession session, const std::string& imageName);

  /**
   * @brief Delete an image by name or ID (BLOCKING).
   * @param session  Valid session handle
   * @param imageId  Image name or hex ID
   * @param errorMsg (out) Error description on failure
   * @return true on success
   */
  bool DeleteImage(WslcSession session, const std::string& imageId,
                   std::string& errorMsg);

 private:
  struct PullOperation {
    std::string operationId;
    std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> channel;
    // handler ownership is transferred to EventChannel via SetStreamHandler
  };

  flutter::BinaryMessenger* messenger_;
  std::map<std::string, std::unique_ptr<PullOperation>> activePulls_;
  int nextOperationId_ = 1;
};

#endif  // WSLC_IMAGE_BRIDGE_H_
