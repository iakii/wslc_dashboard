---
name: wsl-containers-sdk-api-type
description: Microsoft.WSL.Containers 2.9.3 SDK 是 C 风格 API，非 C++/WinRT
metadata:
  type: reference
---

Microsoft.WSL.Containers NuGet 包（v2.9.3）提供的是 **C 风格 API**（头文件 `wslcsdk.h`），
而非原始计划假设的 C++/WinRT 投影（`winrt/Microsoft.WSL.Containers.h`）。

关键差异：
- 函数签名：`STDAPI WslcGetMissingComponents(_Out_ WslcComponentFlags* flags)` — 返回 HRESULT
- 数据结构：C 结构体而非 WinRT 类（如 `WslcVersion { uint32_t major, minor, revision; }`）
- 错误处理：HRESULT 而非 `winrt::hresult_error` 异常
- 枚举：`WslcComponentFlags`（位掩码）而非 `ComponentFlags` 枚举类
- 编译选项：不需要 `/ZW`、`/await`、`WindowsApp.lib`

影响：
- 阶段 2+ 的原生桥接应使用 `WslcCreateSession`、`WslcPullSessionImage` 等 C 函数
- 回调机制使用函数指针而非 `IAsyncOperationWithProgress`
- 进程 I/O 使用 `WslcStdIOCallback` 回调而非 EventChannel 原生流

**Why:** 原始计划假设 Microsoft.WSL.Containers 提供 C++/WinRT 投影 API，实际 SDK 采用 C 风格接口以提高兼容性。
**How to apply:** 所有后续阶段调用 SDK 函数时使用 `#include <wslcsdk.h>` + C 风格调用模式，不要使用 `winrt::` 命名空间。
