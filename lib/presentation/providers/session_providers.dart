import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nativeapi/nativeapi.dart';
import '../../core/constants/app_constants.dart';
import '../../core/platform/wslc_method_channel.dart';
import '../../data/datasources/wslc_cli_datasource.dart';
import '../../data/datasources/wslc_native_datasource.dart';
import '../../data/repositories/session_preferences_repository.dart';
import '../../domain/repositories/session_preferences_repository.dart';
import '../../data/repositories/wslc_repository_impl.dart';
import '../../domain/entities/wsl_session.dart';
import '../../domain/entities/wsl_session_info.dart';
import '../../domain/repositories/wslc_repository.dart';

// ============================================================
// 基础依赖
// ============================================================

/// WSL MethodChannel 单例
final wslcChannelProvider = Provider<WslcMethodChannel>((ref) {
  return WslcMethodChannel.instance;
});

/// 原生数据源
final wslcDatasourceProvider = Provider<WslcNativeDatasource>((ref) {
  return WslcNativeDatasource();
});

/// WSL 仓库
final wslcRepositoryProvider = Provider<WslcRepository>((ref) {
  final datasource = ref.watch(wslcDatasourceProvider);
  return WslcRepositoryImpl(datasource);
});

/// CLI 数据源（wslc system session list）
final cliDatasourceProvider = Provider<WslcCliDatasource>((ref) {
  return WslcCliDatasource();
});

/// Session 名称持久化
final sessionPrefsProvider = Provider<SessionPreferencesRepository>((ref) {
  final prefs = Preferences();
  return SessionPreferencesRepositoryImpl(prefs);
});

// ============================================================
// Session 列表（来自 CLI）
// ============================================================

/// Dashboard 创建过的 session 名称列表（持久化）
final dashboardSessionNamesProvider = Provider<List<String>>((ref) {
  return ref.watch(sessionPrefsProvider).getDashboardSessionNames();
});

/// 所有活动 session 列表（来自 wslc CLI）
final sessionListProvider = FutureProvider<List<WslSessionInfo>>((ref) async {
  final cli = ref.watch(cliDatasourceProvider);
  final names = ref.watch(dashboardSessionNamesProvider);
  return cli.listSessions(dashboardSessionNames: names);
});

/// 当前选中 session 的显示名称（影响 activeSession 的创建/切换）
final selectedSessionNameProvider =
    StateProvider<String>((ref) => AppConstants.defaultSessionName);

// ============================================================
// 活跃 Session（SDK 管理）
// ============================================================

/// 当前活跃 Session 状态
final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, WslSession>(SessionNotifier.new);

class SessionNotifier extends AsyncNotifier<WslSession> {
  @override
  Future<WslSession> build() async {
    final repo = ref.read(wslcRepositoryProvider);
    // 先检查 WSL 组件和 session 缓存状态
    final components = await repo.checkComponents();
    // Session 未运行时，自动用默认配置创建（用户无感知）
    if (!components.isRunning) {
      final name = ref.read(selectedSessionNameProvider);
      return _createAndRecord(repo, name);
    }
    return components;
  }

  /// 创建 session 并记录到本地偏好
  Future<WslSession> _createAndRecord(WslcRepository repo, String name) async {
    final session = await repo.createSession(
      name: name,
      dataPath: AppConstants.defaultDataPath,
      cpuCount: AppConstants.defaultCpuCount,
      memoryMB: AppConstants.defaultMemoryMB,
    );
    // 记录此 session 名称到本地偏好
    ref.read(sessionPrefsProvider).addDashboardSessionName(name);
    // 刷新 session 列表
    ref.invalidate(sessionListProvider);
    return session;
  }

  /// 手动创建 session（用户指定参数）
  Future<void> createSession({
    required String name,
    required String dataPath,
    required int cpuCount,
    required int memoryMB,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(wslcRepositoryProvider);
    state = await AsyncValue.guard(() async {
      final session = await repo.createSession(
        name: name,
        dataPath: dataPath,
        cpuCount: cpuCount,
        memoryMB: memoryMB,
      );
      // 记录并刷新
      ref.read(sessionPrefsProvider).addDashboardSessionName(name);
      ref.read(selectedSessionNameProvider.notifier).state = name;
      ref.invalidate(sessionListProvider);
      return session;
    });
  }

  /// 切换到指定名称的 session（终止当前 + 创建新的）
  Future<void> switchToSession(String name) async {
    state = const AsyncLoading();
    final repo = ref.read(wslcRepositoryProvider);
    try {
      // 先终止当前 session（如果存在）
      await repo.terminateSession();
    } catch (_) {
      // 忽略终止失败（可能本来就没有 session）
    }
    state = await AsyncValue.guard(() => _createAndRecord(repo, name));
    ref.read(selectedSessionNameProvider.notifier).state = name;
  }

  /// 终止当前 session
  Future<void> terminateSession() async {
    final repo = ref.read(wslcRepositoryProvider);
    await repo.terminateSession();
    state = await AsyncValue.guard(() => repo.checkComponents());
    ref.invalidate(sessionListProvider);
  }

  /// 刷新 session 状态
  Future<void> refresh() async {
    final repo = ref.read(wslcRepositoryProvider);
    state = await AsyncValue.guard(() => repo.checkComponents());
  }
}

/// Session 是否就绪（派生状态）
final isSessionReadyProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider).whenOrNull(
        data: (s) => s.isRunning,
      ) ?? false;
});
