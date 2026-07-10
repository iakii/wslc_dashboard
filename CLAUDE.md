# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**wslc_dashboard** — 一个基于 Flutter 的 Windows 桌面应用，用于管理和监控 WSLC（Windows Subsystem for Linux）容器。目标是为 WSL 实例提供图形化界面，替代命令行操作。

## 构建与运行

```bash
# 获取依赖
flutter pub get

# 运行（Windows 桌面）
flutter run -d windows

# 构建发布版本
flutter build windows

# 静态分析
flutter analyze

# 运行所有测试
flutter test

# 运行单个测试文件
flutter test test/widget_test.dart

# 运行特定测试（按名称过滤）
flutter test --name "Counter increments"

# 更新依赖到最新兼容版本
flutter pub upgrade --major-versions

# 检查依赖更新
flutter pub outdated
```

## 项目架构

### 当前状态

项目由 `flutter create` 生成，使用默认的 Flutter 计数器模板，尚未包含业务逻辑。

### 目标架构

WSL 管理 GUI 工具，核心能力包括：
- 通过 `wsl.exe` CLI 与 WSL 交互（列举、启动、停止、配置容器）
- 实时展示容器状态（CPU/内存/磁盘使用）
- 容器终端快速访问

### 关键目录结构

| 目录/文件 | 说明 |
|-----------|------|
| `lib/` | Dart 源代码主目录 |
| `lib/main.dart` | 应用入口 |
| `windows/` | Windows 平台相关代码（CMake、C++ runner） |
| `test/` | 测试文件 |
| `windows/runner/` | Windows 桌面窗口 C++ runner |

### 平台层注意

- 项目使用 Flutter Windows 桌面平台，**不支持** Web、Android、iOS
- 通过 `Process.run('wsl.exe', [...])` 与 WSL CLI 交互（需处理进程 stdout/stderr 编码）
- Windows 特有路径处理（反斜杠、驱动器号）
- 注意与 Windows Terminal / conhost 的集成

## 技术栈

- **Dart SDK**: ^3.12.2
- **框架**: Flutter（Windows 桌面）
- **UI**: `fluent_ui` ^4.x（Fluent Design 风格）
- **状态管理**: `flutter_riverpod` + `riverpod_annotation`
- **原生系统 API**: `nativeapi` ^0.1.4（窗口管理、托盘、偏好设置、UrlOpener、开机自启动）
- **原生 WSL API**: C++/WinRT + MethodChannel → `Microsoft.WSL.Containers` NuGet
- **模型序列化**: `freezed` + `json_serializable`
- **代码生成**: `build_runner`
- **分析工具**: `flutter_lints`（遵循 `package:flutter_lints/flutter.yaml` 规则）
