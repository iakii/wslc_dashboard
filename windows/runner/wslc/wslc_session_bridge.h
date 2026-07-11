#ifndef WSLC_SESSION_BRIDGE_H_
#define WSLC_SESSION_BRIDGE_H_

#include <mutex>
#include <string>
#include <wslcsdk.h>

/**
 * @file wslc_session_bridge.h
 * @brief Wraps WslcSession lifecycle: create, terminate, status query.
 *
 * All SDK functions are blocking. Callers must run bridge methods
 * on background threads to avoid blocking the Flutter UI thread.
 */
class WslcSessionBridge {
 public:
  WslcSessionBridge() = default;
  ~WslcSessionBridge();

  // Non-copyable
  WslcSessionBridge(const WslcSessionBridge&) = delete;
  WslcSessionBridge& operator=(const WslcSessionBridge&) = delete;

  /// Status returned by Create() / GetStatus()
  struct Status {
    std::string sessionId;
    bool isRunning = false;
    int imageCount = 0;
    int containerCount = 0;
    std::string version;
    int64_t startedAt = 0;  // unix millis, 0 if unknown
  };

  /**
   * @brief Create a WSL Container session (blocking).
   * @param name       Session display name
   * @param dataPath   Storage directory path (UTF-8)
   * @param cpuCount   CPU core count (0 = system default)
   * @param memoryMB   Memory limit in MB (0 = system default)
   * @param errorMsg   (out) Human-readable error on failure
   * @return Status on success; isRunning=false on failure
   */
  Status Create(const std::string& name, const std::string& dataPath,
                int cpuCount, int memoryMB, std::string& errorMsg);

  /**
   * @brief Terminate the current session (blocking).
   * Calls WslcTerminateSession + WslcReleaseSession.
   */
  void Terminate();

  /**
   * @brief Query cached session status.
   */
  Status GetStatus() const;

  /**
   * @brief Whether a session handle is currently held.
   */
  bool IsValid() const;

  /**
   * @brief Get the raw session handle for use by other bridges.
   * Caller must hold external synchronization.
   */
  WslcSession GetHandle() const;

 private:
  mutable std::mutex mutex_;
  WslcSession session_ = nullptr;

  // Cached status fields
  mutable std::string sessionId_;
  mutable bool isRunning_ = false;
  mutable int imageCount_ = 0;
  mutable int containerCount_ = 0;
};

#endif  // WSLC_SESSION_BRIDGE_H_
