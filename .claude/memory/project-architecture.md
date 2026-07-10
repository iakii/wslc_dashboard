---
name: project-architecture
description: wslc_dashboard 的 Clean Architecture + Fluent UI + nativeapi 架构决策
metadata:
  type: project
---

## wslc_dashboard 架构

### 三层 Clean Architecture
- **domain/** — 纯 Dart，零依赖：entities(@freezed), repository 抽象接口, usecases
- **data/** — 数据实现：datasource(MethodChannel), models(@json_serializable + toDomain()), repository impl
- **presentation/** — Flutter UI：providers(Riverpod), pages(fluent_ui), widgets

### 关键依赖
| 用途 | 包 | 版本 |
|------|----|------|
| UI | fluent_ui | ^4.16.0 |
| 状态管理 | flutter_riverpod + riverpod_annotation | ^2.6.1 |
| 模型代码生成 | freezed + json_serializable + build_runner | |
| **原生系统 API** | **nativeapi** | **^0.1.4** |
| WSL 原生 API | C++/WinRT → Microsoft.WSL.Containers NuGet | (阶段 1) |

### 原生桥接策略
- **WSL API**: C++/WinRT + MethodChannel/EventChannel → Microsoft.WSL.Containers NuGet
- **系统功能**: nativeapi Dart 包（FFI 方式调用 nativeapi C++ 库）
- 两部分并行，互不依赖

### fluent_ui v4.16 注意点
- `NavigationView` 使用 `pane: NavigationPane(...)` 参数，无 `appBar` 参数
- `titleBar` 参数是 `Widget?`，非 `NavigationAppBar`
- `PaneDisplayMode.compact` 只在侧边显示图标，文字在 hover 时展开
- 图标: `FluentIcons.home`, `FluentIcons.settings`, `FluentIcons.cube_shape`, `FluentIcons.box_checkmark_solid`
