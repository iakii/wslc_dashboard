import '../../core/errors/failures.dart';
import '../../domain/entities/wsl_container.dart';
import '../../domain/entities/wsl_image.dart';
import '../../domain/entities/wsl_session.dart';
import '../../domain/repositories/wslc_repository.dart';
import '../datasources/wslc_native_datasource.dart';
import '../models/wsl_container_model.dart';
import '../models/wsl_image_model.dart';
import '../models/wsl_session_model.dart';

/// WSL Container 仓库实现
class WslcRepositoryImpl implements WslcRepository {
  WslcRepositoryImpl(this._datasource);

  final WslcNativeDatasource _datasource;

  // ======== Session ========

  @override
  Future<WslSession> checkComponents() async {
    try {
      final data = await _datasource.checkComponents();
      return WslSessionModel.fromJson(data).toDomain();
    } catch (e) {
      throw NativeApiFailure('组件检查失败: $e');
    }
  }

  @override
  Future<WslSession> createSession({
    required String name,
    required String dataPath,
    required int cpuCount,
    required int memoryMB,
  }) async {
    try {
      final data = await _datasource.createSession({
        'name': name,
        'dataPath': dataPath,
        'cpuCount': cpuCount,
        'memoryMB': memoryMB,
      });
      return WslSessionModel.fromJson(data).toDomain();
    } catch (e) {
      throw NativeApiFailure('创建 Session 失败: $e');
    }
  }

  @override
  Future<void> terminateSession() async {
    try {
      await _datasource.terminateSession();
    } catch (e) {
      throw NativeApiFailure('终止 Session 失败: $e');
    }
  }

  // ======== 镜像 ========

  @override
  Future<List<WslImage>> listImages() async {
    try {
      final list = await _datasource.listImages();
      return list.map((e) => WslImageModel.fromJson(e).toDomain()).toList();
    } catch (e) {
      throw NativeApiFailure('获取镜像列表失败: $e');
    }
  }

  @override
  Future<String> pullImage(String imageName) async {
    try {
      final data = await _datasource.pullImage(imageName);
      return data['operationId'] as String;
    } catch (e) {
      throw NativeApiFailure('拉取镜像失败: $e');
    }
  }

  @override
  Future<void> deleteImage(String imageId) async {
    try {
      await _datasource.deleteImage(imageId);
    } catch (e) {
      throw NativeApiFailure('删除镜像失败: $e');
    }
  }

  // ======== 容器 ========

  @override
  Future<List<WslContainer>> listContainers() async {
    try {
      final list = await _datasource.listContainers();
      return list
          .map((e) => WslContainerModel.fromJson(e).toDomain())
          .toList();
    } catch (e) {
      throw NativeApiFailure('获取容器列表失败: $e');
    }
  }

  @override
  Future<WslContainer> createContainer({
    required String image,
    required String name,
    required List<String> cmd,
  }) async {
    try {
      final data = await _datasource.createContainer({
        'image': image,
        'name': name,
        'cmd': cmd,
      });
      return WslContainerModel.fromJson(data).toDomain();
    } catch (e) {
      throw NativeApiFailure('创建容器失败: $e');
    }
  }

  @override
  Future<String> startContainer(String containerId) async {
    try {
      final data = await _datasource.startContainer(containerId);
      return data['logChannel'] as String;
    } catch (e) {
      throw NativeApiFailure('启动容器失败: $e');
    }
  }

  @override
  Future<void> stopContainer(String containerId) async {
    try {
      await _datasource.stopContainer(containerId);
    } catch (e) {
      throw NativeApiFailure('停止容器失败: $e');
    }
  }

  @override
  Future<void> deleteContainer(String containerId) async {
    try {
      await _datasource.deleteContainer(containerId);
    } catch (e) {
      throw NativeApiFailure('删除容器失败: $e');
    }
  }
}
