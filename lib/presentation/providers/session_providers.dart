import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/platform/wslc_method_channel.dart';
import '../../data/datasources/wslc_native_datasource.dart';
import '../../data/repositories/wslc_repository_impl.dart';
import '../../domain/entities/wsl_session.dart';
import '../../domain/repositories/wslc_repository.dart';

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

/// Session 状态
final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, WslSession>(SessionNotifier.new);

class SessionNotifier extends AsyncNotifier<WslSession> {
  @override
  Future<WslSession> build() async {
    final repo = ref.read(wslcRepositoryProvider);
    return repo.checkComponents();
  }

  Future<void> createSession({
    required String name,
    required String dataPath,
    required int cpuCount,
    required int memoryMB,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(wslcRepositoryProvider);
    state = await AsyncValue.guard(() => repo.createSession(
          name: name,
          dataPath: dataPath,
          cpuCount: cpuCount,
          memoryMB: memoryMB,
        ));
  }

  Future<void> terminateSession() async {
    final repo = ref.read(wslcRepositoryProvider);
    await repo.terminateSession();
    state = await AsyncValue.guard(() => repo.checkComponents());
  }

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
