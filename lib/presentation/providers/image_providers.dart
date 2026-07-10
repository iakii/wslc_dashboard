import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/wsl_image.dart';
import 'session_providers.dart';

/// 镜像列表
final imageListProvider =
    AsyncNotifierProvider<ImageListNotifier, List<WslImage>>(
        ImageListNotifier.new);

class ImageListNotifier extends AsyncNotifier<List<WslImage>> {
  @override
  Future<List<WslImage>> build() async {
    final repo = ref.read(wslcRepositoryProvider);
    return repo.listImages();
  }

  Future<void> refresh() async {
    final repo = ref.read(wslcRepositoryProvider);
    state = await AsyncValue.guard(() => repo.listImages());
  }

  Future<void> pullImage(String name) async {
    // 1. 发起拉取请求，获得 operationId
    final repo = ref.read(wslcRepositoryProvider);
    final operationId = await repo.pullImage(name);

    // 2. 订阅进度 EventChannel
    final eventChannel =
        EventChannel('${AppConstants.wslcPullPrefix}$operationId');
    eventChannel
        .receiveBroadcastStream()
        .listen((data) {
      // 进度事件通过 pullProgressProvider 分发
      ref.read(pullProgressProvider.notifier).add(data);
    });

    // 3. 拉取完成后刷新列表
    await refresh();
  }

  Future<void> deleteImage(String imageId) async {
    final repo = ref.read(wslcRepositoryProvider);
    await repo.deleteImage(imageId);
    await refresh();
  }
}

/// 拉取进度流
final pullProgressProvider =
    NotifierProvider<PullProgressNotifier, AsyncValue<Map<String, dynamic>?>>(
        PullProgressNotifier.new);

class PullProgressNotifier extends Notifier<AsyncValue<Map<String, dynamic>?>> {
  @override
  AsyncValue<Map<String, dynamic>?> build() {
    return const AsyncData(null);
  }

  void add(dynamic data) {
    if (data is Map) {
      state = AsyncData(Map<String, dynamic>.from(data));
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}
