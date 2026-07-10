#include "wslc_service_bridge.h"

bool WslcServiceBridge::IsAvailable() {
  WslcComponentFlags flags = WSLC_COMPONENT_FLAG_NONE;
  HRESULT hr = WslcGetMissingComponents(&flags);
  return SUCCEEDED(hr) && flags == WSLC_COMPONENT_FLAG_NONE;
}

std::string WslcServiceBridge::GetVersion() {
  WslcVersion version = {};
  HRESULT hr = WslcGetVersion(&version);
  if (SUCCEEDED(hr)) {
    return std::to_string(version.major) + "." +
           std::to_string(version.minor) + "." +
           std::to_string(version.revision);
  }
  return "0.0.0";
}

uint32_t WslcServiceBridge::GetMissingComponents() {
  WslcComponentFlags flags = WSLC_COMPONENT_FLAG_NONE;
  HRESULT hr = WslcGetMissingComponents(&flags);
  return SUCCEEDED(hr) ? static_cast<uint32_t>(flags) : 0xFFFFFFFF;
}
