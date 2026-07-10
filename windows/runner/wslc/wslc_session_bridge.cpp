#include "wslc_session_bridge.h"

#include <sstream>

// CoTaskMemFree requires explicit include (excluded by WIN32_LEAN_AND_MEAN)
#include <combaseapi.h>

// Forward declarations of utility functions (defined in wslc_native_plugin.cpp)
namespace wslc_util {
std::string WideToUtf8(PCWSTR wide);
std::wstring Utf8ToWide(PCSTR utf8);
std::string HresultToString(HRESULT hr);
}  // namespace wslc_util

WslcSessionBridge::~WslcSessionBridge() {
  // Best-effort terminate on destruction
  // Note: this may block briefly; caller should Terminate() explicitly before destruction
  if (session_ != nullptr) {
    WslcTerminateSession(session_);
    WslcReleaseSession(session_);
    session_ = nullptr;
  }
}

WslcSessionBridge::Status WslcSessionBridge::Create(
    const std::string& name, const std::string& dataPath,
    int cpuCount, int memoryMB, std::string& errorMsg) {
  Status status;
  std::lock_guard<std::mutex> lock(mutex_);

  if (session_ != nullptr) {
    errorMsg = "Session already exists. Terminate it first.";
    return status;
  }

  // Step 1: Initialize session settings
  // IMPORTANT: Hold wstring objects until WslcCreateSession completes.
  // The SDK may store pointers into these strings internally.
  std::wstring wname = wslc_util::Utf8ToWide(name.c_str());
  std::wstring wpath = wslc_util::Utf8ToWide(dataPath.c_str());
  WslcSessionSettings settings;
  HRESULT hr = WslcInitSessionSettings(wname.c_str(), wpath.c_str(), &settings);
  if (FAILED(hr)) {
    errorMsg = "WslcInitSessionSettings failed: " + wslc_util::HresultToString(hr);
    return status;
  }

  // Step 2: Configure CPU count
  hr = WslcSetSessionSettingsCpuCount(&settings, static_cast<uint32_t>(cpuCount));
  if (FAILED(hr)) {
    errorMsg = "WslcSetSessionSettingsCpuCount failed: " + wslc_util::HresultToString(hr);
    return status;
  }

  // Step 3: Configure memory
  hr = WslcSetSessionSettingsMemory(&settings, static_cast<uint32_t>(memoryMB));
  if (FAILED(hr)) {
    errorMsg = "WslcSetSessionSettingsMemory failed: " + wslc_util::HresultToString(hr);
    return status;
  }

  // Step 4: Create session (BLOCKING)
  PWSTR errorMessage = nullptr;
  hr = WslcCreateSession(&settings, &session_, &errorMessage);
  if (FAILED(hr)) {
    if (errorMessage) {
      errorMsg = wslc_util::WideToUtf8(errorMessage);
      CoTaskMemFree(errorMessage);
    } else {
      errorMsg = "WslcCreateSession failed: " + wslc_util::HresultToString(hr);
    }
    session_ = nullptr;
    return status;
  }

  // Success: build status
  isRunning_ = true;
  imageCount_ = 0;
  containerCount_ = 0;

  std::stringstream ss;
  ss << "0x" << std::hex << reinterpret_cast<uintptr_t>(session_);
  sessionId_ = ss.str();

  status.isRunning = true;
  status.sessionId = sessionId_;
  return status;
}

void WslcSessionBridge::Terminate() {
  std::lock_guard<std::mutex> lock(mutex_);

  if (session_ == nullptr) {
    return;
  }

  WslcTerminateSession(session_);
  WslcReleaseSession(session_);
  session_ = nullptr;
  isRunning_ = false;
  sessionId_.clear();
}

WslcSessionBridge::Status WslcSessionBridge::GetStatus() const {
  std::lock_guard<std::mutex> lock(mutex_);

  Status status;
  status.isRunning = isRunning_;
  status.sessionId = sessionId_;
  status.imageCount = imageCount_;
  status.containerCount = containerCount_;
  return status;
}

bool WslcSessionBridge::IsValid() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return session_ != nullptr;
}

WslcSession WslcSessionBridge::GetHandle() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return session_;
}
