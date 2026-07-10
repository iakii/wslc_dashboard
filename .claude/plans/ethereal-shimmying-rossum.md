# 阶段 3 实施计划：容器管理 + 进程日志流

## 上下文（Context）

阶段 2 已完成 Session 创建/镜像管理。阶段 3 实现容器 CRUD + 启动容器内进程 + 实时日志流。

**关键差异与原计划：** 进程 I/O 使用 SDK 回调（`WslcStdIOCallback`），而非原始 IO Handle。回调在 SDK 内部线程中触发，通过 EventChannel 推送到 Dart。

## 实施文件清单

### 新建 C++（4 个）
- `windows/runner/wslc/wslc_container_bridge.h` — 容器 CRUD 声明
- `windows/runner/wslc/wslc_container_bridge.cpp` — Create/Start/Stop/Delete/List 实现
- `windows/runner/wslc/wslc_process_bridge.h` — 进程创建 + ContainerLogStreamHandler
- `windows/runner/wslc/wslc_process_bridge.cpp` — LogStreamHandler + Callback → EventSink

### 修改 C++（2 个）
- `windows/runner/wslc/wslc_native_plugin.h` — 添加 Container/Process bridge + 5 个方法
- `windows/runner/wslc/wslc_native_plugin.cpp` — HandleMethodCall 分发 + 处理器实现

### 修改 CMake（1 个）
- `windows/runner/CMakeLists.txt` — 添加 2 个新源文件 + WIN32_LEAN_AND_MEAN

### 修改 Dart（2 个）
- `lib/presentation/pages/containers_page.dart` — 完整 UI
- `lib/presentation/pages/container_detail_page.dart` — 日志终端 + 操作栏

### 不动文件
- Dart data/domain/providers 层（阶段 0 已完成）

## SDK API 关键点

**容器 CRUD（全部阻塞）：**
```
WslcInitContainerSettings(imageName, &settings)
WslcSetContainerSettingsName(&settings, name)
WslcCreateContainer(session, &settings, &container, &errorMsg)
WslcStartContainer(container, flags, &errorMsg)
WslcStopContainer(container, signal, timeoutSec, &errorMsg)
WslcDeleteContainer(container, flags, &errorMsg)
WslcGetContainerID(container, idBuffer[65])
WslcGetContainerState(container, &state)  // created=1, running=2, exited=3
```

**进程 + 日志流（回调模式）：**
```
WslcInitProcessSettings(&processSettings)
WslcSetProcessSettingsCmdLine(&processSettings, argv, argc)
WslcSetProcessSettingsCallbacks(&processSettings, &callbacks, context)
WslcCreateContainerProcess(container, &processSettings, &process, &errorMsg)

// Callbacks fire on SDK internal threads:
void OnStdOut(WslcProcessIOHandle io, const BYTE* data, uint32_t len, PVOID ctx);
void OnStdErr(WslcProcessIOHandle io, const BYTE* data, uint32_t len, PVOID ctx);
void OnExit(INT32 exitCode, PVOID ctx);
```

## 架构设计

### ContainerLogStreamHandler（类似 PullStreamHandler）

```
Dart: containerLogsProvider(id)
  → EventChannel("com.wslc.dashboard/events/logs/{containerId}")
    → ContainerLogStreamHandler  (继承 flutter::StreamHandler)
      ├── OnListenInternal: 创建 WslcProcess + 设置回调
      ├── 回调线程 → EventSink::Success(logEvent)
      └── OnCancelInternal: 取消回调, 清理
```

日志事件格式（EncodableMap）：
```json
{"stream": "stdout", "text": "line data\n", "timestamp": 1234567890}
{"stream": "stderr", "text": "error data\n", "timestamp": 1234567891}
{"stream": "exit", "text": "", "timestamp": 1234567892}
```

### WslcContainerBridge

持有活跃容器的 map：`map<containerId, WslcContainer>`。
- **ListContainers(session)** — 目前 SDK 没有直接 list 方法。需要通过 `WslcGetContainerID` + `WslcGetContainerState` + `WslcInspectContainer` 遍历已知容器。**简化方案：** 在 bridge 内部维护已创建容器的缓存列表。
- **Create(session, image, name, cmd[])** — 初始化 settings → 创建 → 返回 containerId
- **Start(session, containerId)** — 调用 WslcStartContainer
- **Stop(containerId, signal, timeout)** — 调用 WslcStopContainer
- **Delete(containerId, force)** — 调用 WslcDeleteContainer

### WslcProcessBridge

- **StartLogStream(session, containerId, cmd[])** — 设置 EventChannel + ContainerLogStreamHandler
- 管理活跃日志流：`map<containerId, unique_ptr<EventChannel>>`
- 每个容器只能有一个活跃日志流（重复订阅取消旧流）

## MethodChannel 协议

| Method | 输入 | 输出 | 线程 |
|--------|------|------|------|
| `listContainers` | `{}` | `[{id, name, imageName, status, createdAt}]` | 后台 |
| `createContainer` | `{image, name, cmd}` | `{containerId, name, imageName, status, ...}` | 后台 |
| `startContainer` | `{containerId}` | `{success, logChannel}` | 后台 |
| `stopContainer` | `{containerId}` | `{success}` | 后台 |
| `deleteContainer` | `{containerId}` | `{success}` | 后台 |

> **注意：** `cmd` 字段在 `createContainer` 中可用于设置初始命令，但日志流通过 `startContainer` 时创建的进程推送到 `events/logs/{containerId}` EventChannel。

## Flutter UI 设计

### ContainersPage
- `ConsumerWidget` → `containerListProvider`
- Loading / Error / Empty / Data 四状态
- 容器卡片：名称、镜像、状态标签（Created/Running/Stopped）
- 操作按钮：启动 / 停止
- "Create Container" 按钮 → ContentDialog（image, name, cmd）
- 点击容器卡片 → 导航到 ContainerDetailPage

### ContainerDetailPage
- 容器信息头部（名称、镜像、状态）
- 操作栏：启动 / 停止 / 删除
- 日志终端：自动滚动、stdout 白色 / stderr 红色
- 监听 `containerLogsProvider(containerId)` 实时显示日志

## 实施顺序

1. **wslc_container_bridge.h/.cpp** — 容器 CRUD
2. **wslc_process_bridge.h/.cpp** — ContainerLogStreamHandler + StartLogStream
3. **wslc_native_plugin.h/.cpp** — 添加 5 个方法处理器
4. **CMakeLists.txt** — 添加源文件
5. **containers_page.dart** — 完整 UI
6. **container_detail_page.dart** — 日志终端 + 操作

## 验证

```bash
flutter analyze          # Dart 零错误
flutter build windows    # C++ 编译 + 链接
flutter run -d windows   # 运行时
```

检查点：
1. 创建容器（alpine, "/bin/sh"）→ 列表显示
2. 启动容器 → 状态变为 Running
3. 进入详情页 → 日志终端实时显示 stdout
4. 停止容器 → 状态变为 Stopped，日志流结束
5. 删除容器 → 列表移除
