#include "wslc_image_bridge.h"

#include <flutter/standard_method_codec.h>

#include <ctime>
#include <iomanip>
#include <sstream>

// CoTaskMemFree is in combaseapi.h, excluded by WIN32_LEAN_AND_MEAN
#include <combaseapi.h>

// ============================================================
// PullStreamHandler Implementation
// ============================================================

PullStreamHandler::PullStreamHandler(WslcSession session, std::string imageName)
    : session_(session), imageName_(std::move(imageName)) {}

PullStreamHandler::~PullStreamHandler() {
  cancelled_ = true;
  if (worker_.joinable()) {
    worker_.join();
  }
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
PullStreamHandler::OnListenInternal(
    const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  sink_ = std::move(events);

  // Start the blocking pull on a background thread
  worker_ = std::thread([this]() {
    WslcPullImageOptions options = {};
    options.uri = imageName_.c_str();
    options.progressCallback = &OnProgress;
    options.progressCallbackContext = this;

    PWSTR errorMsg = nullptr;
    HRESULT hr = WslcPullSessionImage(session_, &options, &errorMsg);

    if (cancelled_) return;

    if (FAILED(hr)) {
      std::string msg;
      if (errorMsg) {
        msg = wslc_util::WideToUtf8(errorMsg);
        CoTaskMemFree(errorMsg);
      } else {
        msg = "Pull failed: " + wslc_util::HresultToString(hr);
      }
      if (sink_) {
        flutter::EncodableMap err;
        err["status"] = "error";
        err["message"] = msg;
        sink_->Success(flutter::EncodableValue(err));
        sink_->EndOfStream();
      }
    } else {
      if (sink_) {
        flutter::EncodableMap done;
        done["status"] = "completed";
        sink_->Success(flutter::EncodableValue(done));
        sink_->EndOfStream();
      }
    }
  });

  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
PullStreamHandler::OnCancelInternal(const flutter::EncodableValue* arguments) {
  cancelled_ = true;
  sink_.reset();
  // worker_ will be joined in destructor
  return nullptr;
}

HRESULT CALLBACK PullStreamHandler::OnProgress(
    const WslcImageProgressMessage* progress, PVOID context) {
  auto* self = static_cast<PullStreamHandler*>(context);
  if (self->cancelled_) return E_ABORT;
  if (!self->sink_ || !progress) return S_OK;

  flutter::EncodableMap event;
  event["id"] = progress->id ? std::string(progress->id) : "";
  event["status"] = StatusString(progress->status);
  event["currentBytes"] =
      flutter::EncodableValue(static_cast<int64_t>(progress->detail.currentBytes));
  event["totalBytes"] =
      flutter::EncodableValue(static_cast<int64_t>(progress->detail.totalBytes));

  self->sink_->Success(flutter::EncodableValue(event));
  return S_OK;
}

std::string PullStreamHandler::StatusString(WslcImageProgressStatus s) {
  switch (s) {
    case WSLC_IMAGE_PROGRESS_STATUS_PULLING:     return "Pulling";
    case WSLC_IMAGE_PROGRESS_STATUS_WAITING:     return "Waiting";
    case WSLC_IMAGE_PROGRESS_STATUS_DOWNLOADING: return "Downloading";
    case WSLC_IMAGE_PROGRESS_STATUS_VERIFYING:   return "Verifying";
    case WSLC_IMAGE_PROGRESS_STATUS_EXTRACTING:  return "Extracting";
    case WSLC_IMAGE_PROGRESS_STATUS_COMPLETE:    return "Pull complete";
    default:                                     return "Unknown";
  }
}

// ============================================================
// WslcImageBridge Implementation
// ============================================================

WslcImageBridge::WslcImageBridge(flutter::BinaryMessenger* messenger)
    : messenger_(messenger) {}

WslcImageBridge::~WslcImageBridge() {
  // EventChannel objects will be destroyed first, then their internal
  // shared_ptr<StreamHandler> will release our handler (joined in dtor).
}

flutter::EncodableValue WslcImageBridge::ListImages(
    WslcSession session, std::string& errorMsg) {
  if (session == nullptr) {
    errorMsg = "No active session";
    return flutter::EncodableValue();
  }

  WslcImageInfo* images = nullptr;
  uint32_t count = 0;
  HRESULT hr = WslcListSessionImages(session, &images, &count);

  if (FAILED(hr)) {
    errorMsg = "WslcListSessionImages failed: " +
               wslc_util::HresultToString(hr);
    return flutter::EncodableValue();
  }

  flutter::EncodableList result;
  if (images && count > 0) {
    for (uint32_t i = 0; i < count; ++i) {
      const auto& info = images[i];
      flutter::EncodableMap item;

      // Parse name:tag from image name (e.g. "library/alpine:latest")
      std::string fullName(info.name);
      std::string imageName;
      std::string tag = "latest";
      size_t lastSlash = fullName.rfind('/');
      size_t colonPos = fullName.rfind(':');
      // Tag is after the last ':' that appears after the last '/'
      if (colonPos != std::string::npos &&
          (lastSlash == std::string::npos || colonPos > lastSlash)) {
        imageName = fullName.substr(0, colonPos);
        tag = fullName.substr(colonPos + 1);
      } else {
        imageName = fullName;
      }

      // ID: hex-encode first 16 bytes of sha256 digest
      std::stringstream idHex;
      idHex << std::hex << std::setfill('0');
      for (int j = 0; j < 16; ++j) {
        idHex << std::setw(2) << static_cast<int>(info.sha256[j]);
      }

      item["id"] = idHex.str();
      item["name"] = imageName;
      item["tag"] = tag;
      item["sizeBytes"] = static_cast<int64_t>(info.sizeBytes);
            // Convert unix timestamp to ISO 8601 string for DateTime.parse
      {
        time_t t = static_cast<time_t>(info.createdUnixTime);
        struct tm tm_buf;
        gmtime_s(&tm_buf, &t);
        char buf[32];
        strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &tm_buf);
        item["createdAt"] = std::string(buf);
      }

      result.push_back(flutter::EncodableValue(item));
    }
  }

  CoTaskMemFree(images);
  return flutter::EncodableValue(result);
}

std::string WslcImageBridge::StartPull(
    WslcSession session, const std::string& imageName) {
  // Generate unique operation ID
  std::stringstream opId;
  opId << "pull_" << nextOperationId_++;

  // Build the EventChannel name
  std::stringstream channelName;
  channelName << "com.wslc.dashboard/events/pull/" << opId.str();

  // Create handler and transfer ownership to EventChannel
  auto handler = std::make_unique<PullStreamHandler>(session, imageName);

  auto channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger_, channelName.str(),
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetStreamHandler(std::move(handler));

  // Store the channel (it internally owns the handler via shared_ptr)
  auto op = std::make_unique<PullOperation>();
  op->operationId = opId.str();
  op->channel = std::move(channel);

  std::string id = opId.str();
  activePulls_[id] = std::move(op);
  return id;
}

bool WslcImageBridge::DeleteImage(
    WslcSession session, const std::string& imageId, std::string& errorMsg) {
  if (session == nullptr) {
    errorMsg = "No active session";
    return false;
  }

  PWSTR errorMessage = nullptr;
  HRESULT hr = WslcDeleteSessionImage(session, imageId.c_str(), &errorMessage);

  if (FAILED(hr)) {
    if (errorMessage) {
      errorMsg = wslc_util::WideToUtf8(errorMessage);
      CoTaskMemFree(errorMessage);
    } else {
      errorMsg = "Delete failed: " + wslc_util::HresultToString(hr);
    }
    return false;
  }

  return true;
}
