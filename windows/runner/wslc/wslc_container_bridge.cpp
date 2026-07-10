#include "wslc_container_bridge.h"

#include <ctime>
#include <sstream>

// CoTaskMemFree requires explicit include
#include <combaseapi.h>

// ============================================================
// WslcContainerBridge Implementation
// ============================================================

WslcContainerBridge::~WslcContainerBridge() {
  // Release all container handles
  std::lock_guard<std::mutex> lock(mutex_);
  for (auto& pair : containers_) {
    if (pair.second.handle) {
      WslcReleaseContainer(pair.second.handle);
    }
  }
  containers_.clear();
}

ContainerInfo WslcContainerBridge::Create(
    WslcSession session, const std::string& image,
    const std::string& name, const std::vector<std::string>& cmd,
    std::string& errorMsg) {
  ContainerInfo result;
  if (!session) {
    errorMsg = "No active session";
    return result;
  }

  // Step 1: Init container settings
  WslcContainerSettings settings;
  HRESULT hr = WslcInitContainerSettings(image.c_str(), &settings);
  if (FAILED(hr)) {
    errorMsg = "WslcInitContainerSettings failed: " +
               wslc_util::HresultToString(hr);
    return result;
  }

  // Step 2: Set container name
  if (!name.empty()) {
    hr = WslcSetContainerSettingsName(&settings, name.c_str());
    if (FAILED(hr)) {
      errorMsg = "WslcSetContainerSettingsName failed: " +
                 wslc_util::HresultToString(hr);
      return result;
    }
  }

  // Step 3: Skip init process during creation.
  // The process will be created by WslcProcessBridge when the container is started.
  // Setting an init process here can cause SDK crashes with certain image/command combos.
  // cmd is stored but applied later via StartLogStream.

  // Step 4: Create container (BLOCKING)
  WslcContainer container = nullptr;
  PWSTR errorMessage = nullptr;
  hr = WslcCreateContainer(session, &settings, &container, &errorMessage);
  if (FAILED(hr)) {
    if (errorMessage) {
      errorMsg = wslc_util::WideToUtf8(errorMessage);
      CoTaskMemFree(errorMessage);
    } else {
      errorMsg = "WslcCreateContainer failed: " +
                 wslc_util::HresultToString(hr);
    }
    return result;
  }

  // Step 5: Get container ID
  char idBuf[65] = {};
  hr = WslcGetContainerID(container, idBuf);
  if (FAILED(hr)) {
    WslcReleaseContainer(container);
    errorMsg = "WslcGetContainerID failed";
    return result;
  }

  // Build result
  result.containerId = idBuf;
  result.name = name.empty() ? idBuf : name;
  result.imageName = image;
  result.state = WSLC_CONTAINER_STATE_CREATED;
  result.createdAt = static_cast<int64_t>(time(nullptr)) * 1000;

  // Cache the container
  {
    std::lock_guard<std::mutex> lock(mutex_);
    containers_[result.containerId] = {container, result};
  }

  return result;
}

bool WslcContainerBridge::Start(const std::string& containerId,
                                std::string& errorMsg) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = containers_.find(containerId);
  if (it == containers_.end()) {
    errorMsg = "Container not found: " + containerId;
    return false;
  }

  PWSTR errorMessage = nullptr;
  HRESULT hr = WslcStartContainer(it->second.handle,
                                   WSLC_CONTAINER_START_FLAG_NONE,
                                   &errorMessage);
  if (FAILED(hr)) {
    if (errorMessage) {
      errorMsg = wslc_util::WideToUtf8(errorMessage);
      CoTaskMemFree(errorMessage);
    } else {
      errorMsg = "WslcStartContainer failed: " +
                 wslc_util::HresultToString(hr);
    }
    return false;
  }

  it->second.info.state = WSLC_CONTAINER_STATE_RUNNING;
  return true;
}

bool WslcContainerBridge::Stop(const std::string& containerId,
                               std::string& errorMsg) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = containers_.find(containerId);
  if (it == containers_.end()) {
    errorMsg = "Container not found: " + containerId;
    return false;
  }

  PWSTR errorMessage = nullptr;
  HRESULT hr = WslcStopContainer(it->second.handle, WSLC_SIGNAL_SIGTERM,
                                  30, &errorMessage);
  if (FAILED(hr)) {
    if (errorMessage) {
      errorMsg = wslc_util::WideToUtf8(errorMessage);
      CoTaskMemFree(errorMessage);
    } else {
      errorMsg = "WslcStopContainer failed: " +
                 wslc_util::HresultToString(hr);
    }
    return false;
  }

  it->second.info.state = WSLC_CONTAINER_STATE_EXITED;
  return true;
}

bool WslcContainerBridge::Delete(const std::string& containerId,
                                 std::string& errorMsg) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = containers_.find(containerId);
  if (it == containers_.end()) {
    errorMsg = "Container not found: " + containerId;
    return false;
  }

  PWSTR errorMessage = nullptr;
  HRESULT hr = WslcDeleteContainer(it->second.handle,
                                    WSLC_DELETE_CONTAINER_FLAG_FORCE,
                                    &errorMessage);
  if (errorMessage) {
    // Free error message even on success (SDK may allocate info messages)
    CoTaskMemFree(errorMessage);
  }

  WslcReleaseContainer(it->second.handle);
  containers_.erase(it);
  return SUCCEEDED(hr);
}

flutter::EncodableValue WslcContainerBridge::List(std::string& errorMsg) {
  std::lock_guard<std::mutex> lock(mutex_);

  flutter::EncodableList list;
  for (auto& pair : containers_) {
    auto& entry = pair.second;
    auto& info = entry.info;

    // Refresh state from SDK
    if (entry.handle) {
      WslcContainerState state = WSLC_CONTAINER_STATE_INVALID;
      HRESULT hr = WslcGetContainerState(entry.handle, &state);
      if (SUCCEEDED(hr)) {
        info.state = static_cast<int>(state);
      }
    }

    flutter::EncodableMap item;
    item["id"] = info.containerId;
    item["name"] = info.name;
    item["imageName"] = info.imageName;
    item["status"] = StateString(info.state);
    // Convert unix timestamp (millis) to ISO 8601 string
    {
      time_t secs = static_cast<time_t>(info.createdAt / 1000);
      struct tm tm_buf;
      gmtime_s(&tm_buf, &secs);
      char buf[32];
      strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &tm_buf);
      item["createdAt"] = std::string(buf);
    }

    list.push_back(flutter::EncodableValue(item));
  }

  return flutter::EncodableValue(list);
}

WslcContainer WslcContainerBridge::GetHandle(const std::string& containerId) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = containers_.find(containerId);
  return (it != containers_.end()) ? it->second.handle : nullptr;
}

std::string WslcContainerBridge::StateString(int state) {
  switch (state) {
    case WSLC_CONTAINER_STATE_CREATED: return "created";
    case WSLC_CONTAINER_STATE_RUNNING: return "running";
    case WSLC_CONTAINER_STATE_EXITED:  return "stopped";
    case WSLC_CONTAINER_STATE_DELETED: return "deleting";
    default:                           return "unknown";
  }
}
