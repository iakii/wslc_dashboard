---
name: win32-lean-and-mean-scope
description: WIN32_LEAN_AND_MEAN 在 Flutter Windows 构建中必须按文件限域
metadata:
  type: reference
---

在 Flutter Windows 桌面项目中，`WIN32_LEAN_AND_MEAN` 不能通过 `target_compile_definitions` 项目全局定义。

问题：全局定义会导致 Flutter 自带的 `utils.cpp` 编译失败（找不到 `CommandLineToArgvW`），
因为该函数声明在 `<shellapi.h>` 中，而 `WIN32_LEAN_AND_MEAN` 会阻止 `windows.h` 自动包含此头文件。

解决方案：使用 CMake 的 `set_source_files_properties(... PROPERTIES COMPILE_DEFINITIONS "WIN32_LEAN_AND_MEAN")`，
仅对有需求的编译单元（包含 `wslcsdk.h` 的文件）启用该宏。

受影响的编译单元：
- `wslc/wslc_native_plugin.cpp`
- `wslc/wslc_service_bridge.cpp`
- `flutter_window.cpp`（间接包含 wslcsdk.h）

**Why:** WIN32_LEAN_AND_MEAN 在 Flutter Windows runner 中必须按文件限域，避免破坏 Flutter 自有代码。
**How to apply:** 使用 set_source_files_properties 而非 target_compile_definitions 项目全局方式。
