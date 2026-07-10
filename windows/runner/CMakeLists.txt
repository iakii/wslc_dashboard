cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
  # WSL Container native bridge source files
  "wslc/wslc_native_plugin.cpp"
  "wslc/wslc_service_bridge.cpp"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
# Enable C++ exceptions for error handling
target_compile_definitions(${BINARY_NAME} PRIVATE "_HAS_EXCEPTIONS=1")

# Per-file definitions: only files that include wslcsdk.h need WIN32_LEAN_AND_MEAN
# to avoid winsock.h vs winsock2.h conflict.
set_source_files_properties(
  "wslc/wslc_native_plugin.cpp"
  "wslc/wslc_service_bridge.cpp"
  "flutter_window.cpp"
  PROPERTIES COMPILE_DEFINITIONS "WIN32_LEAN_AND_MEAN"
)

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
# wslc/ header search path
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/wslc")

# ======== WSL Containers SDK Integration ========
# The Microsoft.WSL.Containers NuGet package provides:
#   - include/wslcsdk.h  (C-style API declarations)
#   - runtimes/win-x64/native/wslcsdk.dll
#   - runtimes/win-x64/wslcsdk.lib
#   - cmake/Microsoft.WSL.ContainersConfig.cmake

# Auto-restore NuGet packages if missing
set(NUGET_PACKAGES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/packages")
set(NUGET_SDK_DIR "${NUGET_PACKAGES_DIR}/Microsoft.WSL.Containers.2.9.3")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/packages.config"
   AND NOT EXISTS "${NUGET_SDK_DIR}")
  find_program(NUGET nuget)
  if(NUGET)
    message(STATUS "Restoring NuGet packages...")
    execute_process(
      COMMAND "${NUGET}" restore "${CMAKE_CURRENT_SOURCE_DIR}/packages.config"
              -PackagesDirectory "${NUGET_PACKAGES_DIR}"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      RESULT_VARIABLE NUGET_RESULT
    )
    if(NUGET_RESULT EQUAL 0)
      message(STATUS "NuGet packages restored")
    else()
      message(WARNING "NuGet restore failed. Run: nuget restore windows/runner/packages.config")
    endif()
  else()
    message(WARNING "nuget.exe not found. Run: nuget restore windows/runner/packages.config")
  endif()
endif()

# Use the package's CMake config to set up include dirs and link libraries
if(EXISTS "${NUGET_SDK_DIR}/cmake/Microsoft.WSL.ContainersConfig.cmake")
  set(Microsoft.WSL.Containers_DIR "${NUGET_SDK_DIR}/cmake")
  find_package(Microsoft.WSL.Containers REQUIRED CONFIG)
  target_link_libraries(${BINARY_NAME} PRIVATE Microsoft.WSL.Containers::SDK)

  # Copy wslcsdk.dll to output directory (IMPORTED_SHARED targets need explicit copy)
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      "$<TARGET_PROPERTY:Microsoft.WSL.Containers::SDK,IMPORTED_LOCATION>"
      "$<TARGET_FILE_DIR:${BINARY_NAME}>"
    COMMENT "Copying wslcsdk.dll to output directory"
  )
  message(STATUS "WSL Containers SDK: include=${NUGET_SDK_DIR}/include lib=${NUGET_SDK_DIR}/runtimes/win-x64/wslcsdk.lib")
else()
  message(WARNING "WSL Containers SDK not found at ${NUGET_SDK_DIR}. "
          "Run: nuget restore windows/runner/packages.config")
endif()

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
