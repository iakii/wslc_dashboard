---
name: nuget-cmake-integration
description: Microsoft.WSL.Containers NuGet 包的 CMake 集成模式
metadata:
  type: reference
---

Microsoft.WSL.Containers NuGet 包（v2.9.3）自带 CMake Config 文件，集成方式：

```cmake
set(NUGET_SDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/packages/Microsoft.WSL.Containers.2.9.3")
set(Microsoft.WSL.Containers_DIR "${NUGET_SDK_DIR}/cmake")
find_package(Microsoft.WSL.Containers REQUIRED CONFIG)
target_link_libraries(${BINARY_NAME} PRIVATE Microsoft.WSL.Containers::SDK)
```

自动处理：
- 头文件路径：`packages/.../include/`
- 链接库：`packages/.../runtimes/win-x64/wslcsdk.lib`
- 运行时 DLL：`packages/.../runtimes/win-x64/native/wslcsdk.dll`

DLL 部署：由于是 `IMPORTED_SHARED` 目标，需要显式 POST_BUILD 复制：
```cmake
add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND "${CMAKE_COMMAND}" -E copy_if_different
    "$<TARGET_PROPERTY:Microsoft.WSL.Containers::SDK,IMPORTED_LOCATION>"
    "$<TARGET_FILE_DIR:${BINARY_NAME}>"
  COMMENT "Copying wslcsdk.dll to output directory"
)
```

NuGet 自动恢复（可选）：
```cmake
if(NOT EXISTS "${NUGET_SDK_DIR}")
  find_program(NUGET nuget)
  execute_process(COMMAND "${NUGET}" restore "packages.config" ...)
endif()
```

**Why:** NuGet 包的 CMake config 是最佳集成方式，避免手动猜测路径。
**How to apply:** 永远优先使用 find_package CONFIG 模式和 POST_BUILD DLL 复制。
