#ifndef WSLC_CONTAINER_BRIDGE_H_
#define WSLC_CONTAINER_BRIDGE_H_

#include <flutter/encodable_value.h>

#include <map>
#include <mutex>
#include <string>
#include <vector>
#include <wslcsdk.h>

/**
 * @file wslc_container_bridge.h
 * @brief Container CRUD bridge: create, start, stop, delete, list.
 *
 * Maintains an in-memory cache of created containers since the SDK
 * does not provide a direct "list containers" API.
 */

namespace wslc_util {
std::string HresultToString(HRESULT hr);
std::string WideToUtf8(PCWSTR wide);
}  // namespace wslc_util

/// Parsed container info
struct ContainerInfo {
  std::string containerId;  // 64-char hex ID
  std::string name;
  std::string imageName;
  int state = 0;            // WslcContainerState: 1=created, 2=running, 3=exited
  int64_t createdAt = 0;    // unix millis
};

class WslcContainerBridge {
 public:
  WslcContainerBridge() = default;
  ~WslcContainerBridge();

  // Non-copyable
  WslcContainerBridge(const WslcContainerBridge&) = delete;
  WslcContainerBridge& operator=(const WslcContainerBridge&) = delete;

  /**
   * @brief Create a container (BLOCKING).
   * @return ContainerInfo on success (state=WSLC_CONTAINER_STATE_CREATED)
   */
  ContainerInfo Create(WslcSession session, const std::string& image,
                       const std::string& name,
                       const std::vector<std::string>& cmd,
                       std::string& errorMsg);

  /**
   * @brief Start a stopped/created container (BLOCKING).
   */
  bool Start(const std::string& containerId, std::string& errorMsg);

  /**
   * @brief Stop a running container with SIGTERM (BLOCKING).
   */
  bool Stop(const std::string& containerId, std::string& errorMsg);

  /**
   * @brief Delete a container (BLOCKING).
   */
  bool Delete(const std::string& containerId, std::string& errorMsg);

  /**
   * @brief List all known containers (cached in-memory).
   * Returns fresh state by querying SDK for each container.
   */
  flutter::EncodableValue List(std::string& errorMsg);

  /**
   * @brief Get raw WslcContainer handle by ID.
   */
  WslcContainer GetHandle(const std::string& containerId);

  /// Update cached state to running (called when process creation succeeds
  /// without explicit WslcStartContainer)
  void SetRunning(const std::string& containerId);

  /// Convert WslcContainerState enum to string
  static std::string StateString(int state);
 private:

  struct Entry {
    WslcContainer handle;
    ContainerInfo info;
  };

  mutable std::mutex mutex_;
  std::map<std::string, Entry> containers_;  // keyed by hex containerId
};

#endif  // WSLC_CONTAINER_BRIDGE_H_
