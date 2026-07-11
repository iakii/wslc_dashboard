# 多 Session 管理 — 实施方案

## 背景 & 约束

- **SDK 限制 (v2.9.3)**：`wslcsdk.dll` 没有 `WslcEnumSessions`/`WslcOpenSession` API。只能创建新 session、管理当前持有的 session。
- **CLI 能力**：`wslc system session list` 可列出所有活动 session（包括 CLI 和 SDK 创建的）。
- **数据类型**：`wslc system session list` 输出为固定列宽的 ASCII 表格：

  ```
  ID   创建者 PID   显示名称
  1    39644     wslc-cli-Kai
  31   39648     wslc_dashboard
  ```

- **核心结论**：Dashboard 只能操作自己通过 SDK 创建的 session。CLI 创建的 session 可在列表中展示但标记为"只读"。

## 设计目标

1. Session 列表页：展示所有活动 session（Shell 查询）+ Dashboard 历史 session（本地偏好）
2. Session 选择器：用户可选择/切换 session，所有镜像/容器操作跟随选中的 session
3. 创建自定义 session：保留原有对话框，创建后自动加入历史
4. 默认自动创建：保持上一轮的改动，应用启动时自动创建默认 session

## 改动范围

### 1. 新 Entity：`WslSessionInfo`（用于列表展示）

**文件**：`lib/domain/entities/wsl_session_info.dart`（新建）

```dart
@freezed
class WslSessionInfo with _$WslSessionInfo {
  const factory WslSessionInfo({
    required int id,
    required int creatorPid,
    required String displayName,
    required bool isManagedByDashboard, // Dashboard 是否可操作此 session
  }) = _WslSessionInfo;
}
```

### 2. Shell 数据源：`WslcCliDatasource`

**文件**：`lib/data/datasources/wslc_cli_datasource.dart`（新建）

- `Future<List<WslSessionInfo>> listSessions()` — 调用 `wslc system session list`，解析表格
- 解析逻辑：跳过标题行，按列宽切分（ID: 左对齐~5字符, 创建者 PID: 中间, 显示名称: 右列）
- 标记 `isManagedByDashboard`：与本地偏好中记录的 Dashboard session 名称比对

### 3. 本地偏好：`SessionPreferences`

**扩展**：`lib/data/repositories/settings_repository_impl.dart` 或新建 `session_preferences.dart`

- `List<String> getDashboardSessionNames()` — 返回 Dashboard 创建过的 session 名称列表
- `void addDashboardSessionName(String name)` — 记录
- `void removeDashboardSessionName(String name)` — 移除

使用 `nativeapi::Preferences` 存储，key 为 `dashboard_sessions`，值用逗号分隔。

### 4. Provider 层重构

**文件**：`lib/presentation/providers/session_providers.dart`

改动：

```
移除:
  sessionProvider (AsyncNotifierProvider<SessionNotifier, WslSession>)
  isSessionReadyProvider

新增:
  sessionListProvider (FutureProvider<List<WslSessionInfo>>)
    → 调用 WslcCliDatasource.listSessions()
  
  selectedSessionNameProvider (StateProvider<String?>)
    → 当前选中 session 的 displayName，null = 未选择

  selectedSessionProvider (AsyncNotifierProvider<SelectedSessionNotifier, WslSession>)
    → 根据 selectedSessionName 创建/管理 session
    → build(): 若 selectedSessionName 变化 → checkComponents → 必要时 createSession
    → 暴露 create/terminate/refresh 方法

  isSessionReadyProvider
    → 派生自 selectedSessionProvider
```

### 5. Dashboard 页面重构

**文件**：`lib/presentation/pages/dashboard_page.dart`

改为两级结构：

```
Session 列表区（顶部）
  ┌─────────────────────────────────────┐
  │ Session: [wslc_dashboard ▼]  [刷新] │  ← 下拉选择器
  │ 状态: ● 活跃  镜像: 3  容器: 2       │
  └─────────────────────────────────────┘

Session 详情区（下方）
  ┌─────────────────────────────────────┐
  │ 镜像数: 3  容器数: 2                │
  │ 启动时间: 2026-07-11 10:30          │
  │ [终止 Session] [创建新 Session…]    │
  └─────────────────────────────────────┘
```

无 session 时：显示 session 列表 + "创建新 Session" 按钮 + "刷新列表" 按钮。

### 6. 镜像/容器页面适配

**文件**：`lib/presentation/pages/images_page.dart`、`containers_page.dart`

- 读取 `selectedSessionProvider` 确定当前 session
- session 未就绪时禁用操作按钮，显示提示
- 操作都通过 `selectedSessionProvider` 的 repo 调用

### 7. shell 原生桥接（可选优化）

如果 Dart 的 `Process.run` 调用 `wslc` 耗时较长（~0.5-1s），可考虑在 C++ 层通过 `CreateProcess` 调用。先使用 Dart `Process.run` 实现，性能不够再优化。

## 实施顺序

| Phase | 任务 | 依赖 |
|-------|------|------|
| 1 | `WslSessionInfo` 实体 + Freezed 生成 | 无 |
| 2 | `WslcCliDatasource` shell 调用 + 表格解析 | Phase 1 |
| 3 | `SessionPreferences` 本地持久化 | 无 |
| 4 | Provider 层重构（sessionList/selectedSession） | Phase 1,2,3 |
| 5 | Dashboard 页面重构（列表 + 选择器） | Phase 4 |
| 6 | 镜像/容器页面 session 适配 | Phase 4,5 |
| 7 | 回退「自动创建默认 session」逻辑（合并到 selectedSession） | Phase 4 |
| 8 | 测试 + 静态分析 | Phase 5,6,7 |

## 风险

1. **Shell 解析脆弱**：`wslc` CLI 表格格式可能因版本/语言变化。用正则按列宽解析，失败时 fallback 为空列表。
2. **Session 切换开销**：SDK 层面切换 session = 终止当前 + 创建新的，可能耗时数秒。
3. **Session 名称冲突**：如果 CLI 和 Dashboard 创建同名 session，列表会合并但 `isManagedByDashboard` 标记会区分。

## 验证标准

- `wslc system session list` 输出正确解析为 `WslSessionInfo` 列表
- Dashboard 下拉选择器显示所有 session
- 选中 Dashboard session → 可正常操作镜像/容器
- 选中 CLI session → 操作按钮禁用，显示提示
- 创建/终止 session 后列表自动刷新
- 应用重启后 Dashboard session 历史保留
