# WSL Container Dashboard — 完整实现方案

## 一、上下文（Context）

**问题：** 当前 WSL 容器功能需要通过 `wslc.exe` CLI 或编码操作，缺乏可视化 GUI 管理工具。

**目标：** 构建 Flutter Windows 桌面应用，通过 `Microsoft.WSL.Containers` C++/WinRT API 实现 WSL 容器图形化管理：Session、镜像拉取/浏览、容器生命周期、日志查看。使用 Fluent Design，支持系统托盘常驻。

**范围：** MVP（Session + 镜像 + 容器 + 日志 + 托盘 + 窗口管理），后续迭代增加高级功能。

---

## 二、技术栈

| 层 | 技术 |
|---|------|
| UI 框架 | Flutter + **fluent_ui**（Fluent Design） |
| 架构 | **Clean Architecture**（data / domain / presentation） |
| 状态管理 | **Riverpod**（flutter_riverpod + riverpod_annotation） |
| 原生 WSL API | C++/WinRT + MethodChannel / EventChannel → `Microsoft.WSL.Containers` NuGet |
| 原生系统 API | **nativeapi** ^0.1.4（窗口管理、托盘、偏好设置、UrlOpener、开机自启动） |
| 模型序列化 | freezed + json_serializable |
| 测试 | flutter_test + mockito |

---

## 三、项目目录结构

### lib/ 层（Clean Architecture）

```
lib/
├── main.dart                          # 入口：WidgetsFlutterBinding + WindowManager + ProviderScope
├── app.dart                           # FluentApp + NavigationView 导航壳
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Channel 名称、默认配置、注册表路径
│   ├── errors/
│   │   ├── failures.dart              # Failure sealed class
│   │   └── wslc_exception.dart
│   ├── platform/
│   │   └── wslc_method_channel.dart   # [核心] Dart 端 MethodChannel 封装（单例）
│   ├── theme/
│   │   └── app_theme.dart             # FluentThemeData + 亮/暗主题
│   └── utils/
│       └── logger.dart
│
├── data/                              # 数据层
│   ├── datasources/
│   │   └── wslc_native_datasource.dart    # 原生调用适配器（封装 WslcMethodChannel）
│   ├── models/
│   │   ├── wsl_session_model.dart     # @JsonSerializable + toDomain()
│   │   ├── wsl_image_model.dart
│   │   ├── wsl_container_model.dart
│   │   └── wsl_container_log_model.dart
│   └── repositories/
│       ├── wslc_repository_impl.dart  # 综合 repository（session + image + container）
│       └── settings_repository_impl.dart  # 自启动/托盘持久化
│
├── domain/                            # 领域层（纯 Dart，零依赖）
│   ├── entities/
│   │   ├── wsl_session.dart           # @freezed
│   │   ├── wsl_image.dart             # @freezed
│   │   ├── wsl_container.dart         # @freezed
│   │   └── wsl_process_output.dart    # stdout/stderr 数据块
│   ├── repositories/
│   │   ├── wslc_repository.dart       # 抽象接口
│   │   └── settings_repository.dart
│   └── usecases/
│       ├── session/
│       │   ├── check_components.dart
│       │   ├── initialize_session.dart
│       │   └── terminate_session.dart
│       ├── image/
│       │   ├── list_images.dart
│       │   ├── pull_image.dart
│       │   └── remove_image.dart
│       ├── container/
│       │   ├── create_container.dart
│       │   ├── start_container.dart
│       │   ├── stop_container.dart
│       │   ├── remove_container.dart
│       │   ├── list_containers.dart
│       │   └── get_container_logs.dart
│       └── settings/
│           ├── get_autostart.dart
│           ├── set_autostart.dart
│           ├── get_tray_setting.dart
│           └── set_tray_setting.dart
│
└── presentation/                      # 表现层
    ├── providers/
    │   ├── session_providers.dart     # wslcChannel → sessionNotifier
    │   ├── image_providers.dart       # imageListNotifier + pullProgressStream
    │   ├── container_providers.dart   # containerListNotifier + containerLogStream.family
    │   ├── settings_providers.dart    # autostart / minimizeToTray
    │   └── window_providers.dart      # WindowManager provider
    ├── pages/
    │   ├── dashboard_page.dart        # 概览页
    │   ├── images_page.dart           # 镜像管理
    │   ├── containers_page.dart       # 容器管理
    │   ├── container_detail_page.dart # 容器详情 + 日志终端
    │   └── settings_page.dart         # 设置
    └── widgets/
        ├── status_card.dart           # 状态卡片（Fluent Card）
        ├── image_list_tile.dart
        ├── container_list_tile.dart
        ├── log_viewer.dart            # 滚动日志终端（stdout 绿色 / stderr 红色）
        ├── pull_progress_dialog.dart  # 拉取进度 ContentDialog
        └── confirm_dialog.dart        # 通用确认对话框
```

### windows/runner/ 原生层（C++/WinRT）

```
windows/
├── CMakeLists.txt                     # [修改] 仅修改 _HAS_EXCEPTIONS 覆盖策略
├── flutter/
│   ├── generated_plugin_registrant.cc # 不变（不修改自动生成文件）
│   └── CMakeLists.txt                 # 不变
└── runner/
    ├── CMakeLists.txt                 # [修改] 核心：添加 wslc 源文件 + NuGet + WinRT 配置
    ├── packages.config                # [新建] NuGet 包声明
    ├── flutter_window.h               # [修改] 持有 WslcNativePlugin 成员
    ├── flutter_window.cpp             # [修改] OnCreate 中初始化 WslcNativePlugin
    ├── main.cpp                       # 不变（已有 CoInitializeEx）
    │
    └── wslc/                          # [新建] WSL Container 原生桥接
        ├── wslc_native_plugin.h       # 插件入口，持有 MethodChannel + Bridge 实例
        ├── wslc_native_plugin.cpp     # HandleMethodCall 分发
        ├── wslc_service_bridge.h      # WslcService 封装（CheckComponents）
        ├── wslc_service_bridge.cpp
        ├── wslc_session_bridge.h      # Session 封装（创建/终止/镜像/容器操作）
        ├── wslc_session_bridge.cpp    # ** 最核心文件 — 大部分业务逻辑在此 **
        ├── wslc_image_bridge.h        # 镜像拉取（IAsyncOperationWithProgress）
        ├── wslc_image_bridge.cpp
        ├── wslc_container_bridge.h    # 容器 CRUD
        ├── wslc_container_bridge.cpp
        ├── wslc_process_bridge.h      # Process stdout/stderr 流 → EventChannel
        ├── wslc_process_bridge.cpp
        └── wslc_async_utils.h         # WinRT async → Dart 桥接工具模板
```

---

## 四、MethodChannel / EventChannel 协议

### Channel 名称

```
com.wslc.dashboard/api              # MethodChannel — 请求/响应
com.wslc.dashboard/events/logs/{id} # EventChannel — 容器日志流（每容器一个）
com.wslc.dashboard/events/pull/{id} # EventChannel — 拉取进度流（每任务一个）
```

### Method 完整定义

| Method | 参数 | 返回值 | 说明 |
|--------|------|--------|------|
| `checkComponents` | — | `{"missing": int, "version": "1.0"}` | WSL 组件检查 + 版本 |
| `createSession` | `{"name":"app", "dataPath":"C:\\...", "cpuCount":4, "memoryMB":4096}` | `{"sessionId":"uuid"}` | 创建并启动 Session |
| `terminateSession` | — | `{"success":true}` | 终止当前 Session |
| `getSessionStatus` | — | `{"running":true, "imageCount":3, "containerCount":2}` | 查询状态 |
| `listImages` | — | `[{"id":"...", "name":"ubuntu:latest", "sizeBytes":123}]` | 镜像列表 |
| `pullImage` | `{"imageName":"docker.io/library/alpine:latest"}` | `{"operationId":"uuid"}` | 开始拉取，进度通过 EventChannel 推送 |
| `deleteImage` | `{"imageId":"..."}` | `{"success":true}` | 删除镜像 |
| `listContainers` | — | `[{"id":"...", "name":"web", "image":"...", "status":"running"}]` | 容器列表 |
| `createContainer` | `{"image":"ubuntu:latest", "name":"my-ctr", "cmd":["/bin/sh"]}` | `{"containerId":"uuid"}` | 创建 |
| `startContainer` | `{"containerId":"..."}` | `{"success":true, "logChannel":"logs/{id}"}` | 启动 + 返回日志 channel ID |
| `stopContainer` | `{"containerId":"..."}` | `{"success":true}` | 停止（SIGTERM） |
| `deleteContainer` | `{"containerId":"..."}` | `{"success":true}` | 删除 |

### EventChannel 事件

```json
// 日志
{"stream":"stdout", "text":"line\n", "timestamp": 1234567890}
{"stream":"stderr", "text":"error\n", "timestamp": 1234567891}
{"stream":"exit", "exitCode": 0}

// 拉取进度
{"status":"downloading", "currentBytes": 1234567, "totalBytes": 5678900}
{"status":"complete"}
{"status":"error", "message":"not found"}
```

---

## 五、C++/WinRT 原生层详细设计

### 5.1 异步桥接策略（核心）

WinRT 异步需要桥接到 Dart async。C++/WinRT 使用 `co_await` 协程。**关键模式：`winrt::fire_and_forget` + `std::move(result)`**

```cpp
// wslc_async_utils.h — 通用桥接模板
template<typename TResult>
winrt::fire_and_forget RunWinRTAsync(
    winrt::IAsyncOperation<TResult> operation,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result,
    std::function<flutter::EncodableValue(TResult)> converter) {
    try {
        auto value = co_await operation;
        result->Success(converter(value));
    } catch (const winrt::hresult_error& e) {
        result->Error(
            std::to_string(static_cast<int>(e.code().value)),
            winrt::to_string(e.message()));
    }
}
```

对于带进度的操作（如 PullImage），使用 `IAsyncOperationWithProgress`：
```cpp
auto pullOp = session.PullImageAsync(options);
pullOp.Progress([](auto&&, ImageProgress progress) {
    // 通过 EventSink 推送进度到 Dart
    eventSink->Success(EncodeProgress(progress));
});
co_await pullOp; // 等待完成
```

### 5.2 wslc_native_plugin.h — 插件入口

```cpp
class WslcNativePlugin {
public:
    explicit WslcNativePlugin(flutter::BinaryMessenger* messenger);
    ~WslcNativePlugin();

private:
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
    std::unique_ptr<WslcServiceBridge> serviceBridge_;
    std::unique_ptr<WslcSessionBridge> sessionBridge_;
    // EventChannel 实例管理（按 containerId / operationId 索引）
    std::map<std::string, std::unique_ptr<WslcProcessBridge>> processBridges_;
};
```

### 5.3 wslc_service_bridge — WslcService 封装

```cpp
class WslcServiceBridge {
public:
    bool IsAvailable();
    std::wstring GetVersion();
    winrt::Microsoft::WSL::Containers::ComponentFlags GetMissingComponents();
};
```

### 5.4 wslc_session_bridge — Session 封装（最核心）

```cpp
class WslcSessionBridge {
public:
    void CreateSession(const std::string& name, const std::string& dataPath,
                       int cpuCount, int memoryMB);
    void Terminate();
    bool IsRunning();
    SessionStatus GetStatus();

    // 镜像
    std::vector<ImageInfo> ListImages();
    winrt::IAsyncOperationWithProgress<...> PullImageAsync(const std::string& ref);
    void DeleteImage(const std::string& id);

    // 容器
    std::vector<ContainerInfo> ListContainers();
    std::string CreateContainer(const std::string& image, const std::string& name,
                                const std::vector<std::string>& cmd);
    std::string StartContainer(const std::string& id);   // 返回 logChannel ID
    void StopContainer(const std::string& id);
    void DeleteContainer(const std::string& id);

private:
    winrt::Microsoft::WSL::Containers::Session session_{ nullptr };
};
```

### 5.5 wslc_process_bridge — Process 日志流

```cpp
class WslcProcessBridge {
public:
    // 启动流式读取，通过 EventSink 推送到 Dart
    void StartStreaming(
        winrt::Microsoft::WSL::Containers::Process process,
        std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> eventSink);

private:
    void ReadStdoutLoop();  // 后台线程持续读取
    void ReadStderrLoop();
    void OnProcessExited(int exitCode);
};
```

---

## 六、CMake 构建配置

### 6.1 windows/runner/packages.config（新建）

```xml
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Microsoft.Windows.CppWinRT" version="2.0.240405.1" targetFramework="native" />
  <package id="Microsoft.WSL.Containers" version="1.0.0" targetFramework="native" />
</packages>
```

### 6.2 windows/runner/CMakeLists.txt 修改

关键变更：
1. 添加 wslc/ 源文件
2. NuGet 包恢复
3. **覆盖 `_HAS_EXCEPTIONS=1`**（C++/WinRT 协程必需）
4. 添加 `/await` 编译选项
5. 链接 `WindowsApp.lib`

详见实际实施时按需修改，核心点：
```cmake
# 在 apply_standard_settings(${BINARY_NAME}) 之后：
target_compile_definitions(${BINARY_NAME} PRIVATE "_HAS_EXCEPTIONS=1")
target_compile_options(${BINARY_NAME} PRIVATE "/await")
target_link_libraries(${BINARY_NAME} PRIVATE "WindowsApp.lib")

# 添加 wslc 源文件到 add_executable(...)
```

### 6.3 flutter_window.cpp 修改

```cpp
// OnCreate() 中 RegisterPlugins() 之后添加：
#include "wslc/wslc_native_plugin.h"

// 成员变量
std::unique_ptr<WslcNativePlugin> wslc_plugin_;

// OnCreate() 中：
wslc_plugin_ = std::make_unique<WslcNativePlugin>(
    flutter_controller_->engine()->messenger());
```

---

## 七、数据模型（domain 层 @freezed）

```dart
// wsl_session.dart
@freezed
class WslSession with _$WslSession {
  const factory WslSession({
    required bool isRunning,
    required int imageCount,
    required int containerCount,
    @Default('') String version,
    DateTime? startedAt,
  }) = _WslSession;
}

// wsl_image.dart
@freezed
class WslImage with _$WslImage {
  const factory WslImage({
    required String id,
    required String name,
    required String tag,
    required int sizeBytes,
    required DateTime createdAt,
  }) = _WslImage;
}

// wsl_container.dart
enum ContainerStatus { created, running, stopped, deleting, unknown }

@freezed
class WslContainer with _$WslContainer {
  const factory WslContainer({
    required String id,
    required String name,
    required String imageName,
    required ContainerStatus status,
    required DateTime createdAt,
  }) = _WslContainer;
}
```

---

## 八、Riverpod Provider 设计

```
wslcChannelProvider (Provider — 单例MethodChannel)
  └── wslcRepositoryProvider (Provider<WslcRepository>)
        ├── sessionProvider (AsyncNotifierProvider → WslSession)
        │     └── isSessionReadyProvider (derived bool)
        ├── imageListProvider (AsyncNotifierProvider → List<WslImage>)
        │     └── pullProgressProvider (StreamProvider.family → PullProgress)
        ├── containerListProvider (AsyncNotifierProvider → List<WslContainer>)
        │     └── containerLogsProvider (StreamProvider.family → LogOutput)
        ├── settingsRepositoryProvider
        │     ├── autostartProvider (AsyncNotifierProvider → bool)
        │     └── minimizeToTrayProvider (AsyncNotifierProvider → bool)
        └── windowManagerProvider (Provider<WindowManager>)
```

---

## 九、UI 页面设计（fluent_ui）

### 导航结构

```
FluentApp
└── NavigationView (侧边栏)
    ├── PaneItem: 概览 (FluentIcons.home)
    ├── PaneItem: 镜像 (FluentIcons.image)
    ├── PaneItem: 容器 (FluentIcons.docker_container)
    └── PaneItem: 设置 (FluentIcons.settings)

    右侧内容区 NavigationBody → 切换页面
```

### 各页面说明

**DashboardPage**
- Session 状态卡片 + 启动/停止按钮
- 统计数字（镜像/容器/运行中）
- 最近容器快速操作

**ImagesPage**
- 镜像卡片列表（fluent Card），显示名称/标签/大小/时间
- "拉取镜像"按钮 → ContentDialog 输入 `image:tag`
- 拉取进度条（ProgressBar + ProgressRing）
- 删除按钮 + 确认对话框

**ContainersPage**
- 容器列表（状态标签 Created/Running/Stopped）
- "创建容器"按钮 → ContentDialog 表单
- 每张卡片操作：启动 / 停止 / 删除
- 点击容器 → 进入 ContainerDetailPage

**ContainerDetailPage**
- 容器信息头部（名称、镜像、状态）
- 操作栏：启动 / 停止 / 重启 / 删除
- 日志终端（LogViewer）：自动滚动、stdout/stdin/stderr 颜色区分

**SettingsPage**
- WSL 组件状态 + 版本号
- Session 配置（CPU/内存/数据路径）
- ToggleSwitch: 开机自启动、最小化到托盘
- ToggleSwitch: 暗色/亮色主题

---

## 十、窗口管理与托盘集成（nativeapi）

### 窗口管理

```dart
import 'package:nativeapi/nativeapi.dart';

final windowManager = WindowManager.instance;
final window = windowManager.getCurrent();
window?.show();
window?.center();
window?.titleBarStyle = TitleBarStyle.hidden;

// 监听窗口事件
windowManager.addCallbackListener<WindowFocusedEvent>((event) {
  print('Window focused: ${event.windowId}');
});
```

### 系统托盘

```dart
final trayIcon = TrayIcon();
trayIcon.icon = Image.fromAsset('assets/tray_icon.png');
trayIcon.contextMenu = Menu.buildFrom([
  MenuItem(label: '显示窗口'),
  MenuItem(label: '退出'),
]);
trayIcon.contextMenuTrigger = ContextMenuTrigger.rightClicked;
trayIcon.on<TrayIconClickedEvent>((event) {
  print('Tray icon clicked');
});
```

### Preferences（持久化存储）

```dart
final prefs = Preferences();
prefs.set('theme', 'dark');
final theme = prefs.get('theme', 'light');
```

### 开机自启动

nativeapi 自 v0.1.2 起支持 Launch at Login API。

### UrlOpener

```dart
UrlOpener.instance.open('https://github.com');
```

---

## 十一、分阶段实施路线图

### 阶段 0：项目脚手架（已完成 ✅）

- [x] 项目已存在（flutter create）
- [x] 添加 pubspec.yaml 依赖：fluent_ui, flutter_riverpod, riverpod_annotation, freezed, json_serializable, nativeapi, build_runner
- [x] 创建完整 Clean Architecture 目录结构
- [x] core/ 层：constants, errors, platform(MethodChannel), theme, utils
- [x] domain/ 层：entities(3个@freezed + process_output), repositories(2个抽象接口)
- [x] data/ 层：datasource, models(4个json_serializable), repositories(2个实现)
- [x] presentation/ 层：providers(5组), pages(5个), widgets(占位)
- [x] 替换 main.dart 为 ProviderScope + FluentApp + WindowManager + TrayIcon
- [x] 配置 build_runner（freezed + json_serializable）
- [x] 配置 analysis_options.yaml
- [x] **验证：** `flutter analyze` ✅ / `flutter test` ✅ / 17 generated files

### 阶段 1：原生层基础 — C++/WinRT 桥接 + CheckComponents（预计 3-4h）

- [ ] 创建 `windows/runner/packages.config`
- [ ] 修改 `windows/runner/CMakeLists.txt`：添加 wslc 源文件 + NuGet 集成 + WinRT 编译选项
- [ ] 修改 `flutter_window.h/.cpp`：持有 WslcNativePlugin
- [ ] 实现 `wslc_native_plugin` + `wslc_service_bridge`（CheckComponents）
- [ ] 实现 `wslc_async_utils.h` 异步桥接工具
- [ ] Dart 端 `WslcMethodChannel` + `checkComponents()`
- [ ] 验证：**Dart 调用 `checkComponents()` 成功返回组件状态** ← 关键里程碑

### 阶段 2：Session + 镜像管理（预计 3-4h）

- [ ] 实现 `wslc_session_bridge` — CreateSession / TerminateSession
- [ ] 实现 `wslc_image_bridge` — ListImages / PullImage（进度事件）/ DeleteImage
- [ ] EventChannel 拉取进度流
- [ ] Dart domain 层：实体 + Repository 接口 + UseCase
- [ ] Dart data 层：Model（JSON）+ Datasource + RepositoryImpl
- [ ] Riverpod：sessionProvider, imageListProvider, pullProgressProvider
- [ ] UI：DashboardPage 基础 + ImagesPage（列表 + 拉取对话框 + 进度条）
- [ ] 验证：可列出镜像、拉取 `alpine:latest`（进度条可见）、删除镜像

### 阶段 3：容器管理（预计 3-4h）

- [ ] 实现 `wslc_container_bridge` — CRUD
- [ ] 实现 `wslc_process_bridge` — 日志 EventChannel
- [ ] Dart domain + data 层容器相关代码
- [ ] Riverpod：containerListProvider, containerLogsProvider.family
- [ ] UI：ContainersPage + ContainerDetailPage（LogViewer 终端）
- [ ] 验证：创建容器 → 启动 → 实时日志滚动 → 停止 → 删除

### 阶段 4：窗口管理 + 托盘 + 设置（预计 2-3h）

- [ ] window_manager 集成（尺寸/关闭行为）
- [ ] system_tray 集成（图标/菜单）
- [ ] SettingsPage UI（托盘/自启动/主题开关）
- [ ] settings_repository_impl + Riverpod providers
- [ ] 验证：关闭→托盘→恢复→右键退出 完整流程

### 阶段 5：开机自启动 + 收尾（预计 1-2h）

- [ ] win32_registry 实现自启动注册/取消
- [ ] DashboardPage 完善（统计卡片 + 快速操作）
- [ ] 全局错误处理（InfoBar 通知 + loading/error/empty 态）
- [ ] 暗色/亮色主题切换
- [ ] 更新 CLAUDE.md + README.md
- [ ] 端到端测试
- [ ] 验证：全功能流程测试通过

---

## 十二、验证方案

### 每阶段标准验证

```bash
flutter analyze                    # 零错误
flutter test                       # 所有测试通过
flutter build windows              # 构建成功（阶段 1 后启用）
flutter run -d windows             # 运行验证
```

### 关键里程碑验证

**阶段 1 里程碑（最重要）：**
- `Microsoft.WSL.Containers` NuGet 包正确链接
- C++ 端 `CheckComponents` 返回有效 ComponentFlags
- Dart 端能接收并显示结果
- C++/WinRT 异常（hresult_error）正确转换为 Dart Exception

**端到端验证：**
1. 启动 → Dashboard Session 状态 "未运行"
2. Settings → 配置 → 启动 Session → Dashboard 更新
3. Images → 拉取 `alpine:latest` → 进度条 → 完成
4. Containers → 创建（alpine, `/bin/sh`）→ 启动 → 日志终端实时滚动
5. 关闭窗口 → 托盘常驻 → 点击恢复
6. 开启自启动 → 注册表确认 → 重启验证

---

## 十三、待确认问题

1. **"nativeapi 库"：** 你提到使用 "nativeapi库" 实现托盘/窗口/自启动。当前方案选用：
   - WSL API：C++/WinRT + MethodChannel（原生桥接）
   - 窗口管理：`window_manager`（Dart package，底层调用 Win32）
   - 托盘：`system_tray`（Dart package）
   - 自启动：`win32_registry`（Dart package 封装 Win32 注册表 API）

   这些 Dart package 实质上都封装了原生 Win32 API。如果有特定的 "nativeapi" Dart 库需要替换，请告知。

用户答：使用https://github.com/libnativeapi/nativeapi 库处理 自启动，窗口管理，托盘 ，UrlOpener 打开文件和地址。

2. **Session 数据目录：** 默认使用 `%LOCALAPPDATA%\wslc_dashboard\`，启动时可配置。是否可以？
用户答：使用https://github.com/libnativeapi/nativeapi 库处理 Preferences 数据缓存等操作

3. **容器日志持久化：** 当前方案仅实时展示，不持久化到文件。是否需要保存日志到本地磁盘？
用户答：使用https://github.com/libnativeapi/nativeapi 库处理 Preferences 数据缓存等操作
