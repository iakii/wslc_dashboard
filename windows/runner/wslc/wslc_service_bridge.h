#ifndef WSLC_SERVICE_BRIDGE_H_
#define WSLC_SERVICE_BRIDGE_H_

#include <string>

// NOTE: WIN32_LEAN_AND_MEAN must be defined before including this header.
// This is handled per-file via CMake set_source_files_properties.
#include <wslcsdk.h>

/**
 * @file wslc_service_bridge.h
 * @brief Wraps the C-style wslcsdk.h API for WSL component checks.
 *
 * Uses WslcGetMissingComponents() and WslcGetVersion() directly.
 */
class WslcServiceBridge {
 public:
  WslcServiceBridge() = default;
  ~WslcServiceBridge() = default;

  // Non-copyable
  WslcServiceBridge(const WslcServiceBridge&) = delete;
  WslcServiceBridge& operator=(const WslcServiceBridge&) = delete;

  /// Whether all WSL components are available
  bool IsAvailable();

  /// Get WSL SDK version as "major.minor.revision"
  std::string GetVersion();

  /// Get missing components bitmask (WslcComponentFlags), 0 = all ready
  uint32_t GetMissingComponents();
};

#endif  // WSLC_SERVICE_BRIDGE_H_
