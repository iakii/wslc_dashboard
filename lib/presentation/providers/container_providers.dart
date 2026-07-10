import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/wsl_container.dart';
import '../../domain/entities/wsl_process_output.dart';
import 'session_providers.dart';

/// 容器列表
final containerListProvider =
    AsyncNotifierProvider<ContainerListNotifier, List<WslContainer>>(
        ContainerListNotifier.new);

class ContainerListNotifier extends AsyncNotifier<List<WslContainer>> {
  @override
  Future<List<WslContainer>> build() async {
    final repo = ref.read(wslcRepositoryProvider);
    return repo.listContainers();
  }

  Future<void> refresh() async {
    final repo = ref.read(wslcRepositoryProvider);
    state = await AsyncValue.guard(() => repo.listContainers());
  }

  Future<void> create({
    required String image,
    required String name,
    required List<String> cmd,
  }) async {
    final repo = ref.read(wslcRepositoryProvider);
    await repo.createContainer(image: image, name: name, cmd: cmd);
    await refresh();
  }

  Future<String> start(String containerId) async {
    final repo = ref.read(wslcRepositoryProvider);
    final logChannel = await repo.startContainer(containerId);
    await refresh();
    return logChannel;
  }

  Future<void> stop(String containerId) async {
    final repo = ref.read(wslcRepositoryProvider);
    await repo.stopContainer(containerId);
    await refresh();
  }

  Future<void> delete(String containerId) async {
    final repo = ref.read(wslcRepositoryProvider);
    await repo.deleteContainer(containerId);
    await refresh();
  }
}

/// 容器日志流（按 containerId 索引）
final containerLogsProvider =
    StreamProvider.family<WslProcessOutput, String>((ref, containerId) {
  final eventChannel =
      EventChannel('${AppConstants.wslcLogsPrefix}$containerId');
  return eventChannel.receiveBroadcastStream().map((data) {
    final map = Map<String, dynamic>.from(data as Map);
    return WslProcessOutput(
      stream: map['stream'] as String? ?? 'stdout',
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? 0,
    );
  });
});
