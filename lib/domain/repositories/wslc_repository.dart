import '../entities/wsl_container.dart';
import '../entities/wsl_image.dart';
import '../entities/wsl_session.dart';

/// WSL Container 操作抽象接口
abstract class WslcRepository {
  // ======== Session ========
  Future<WslSession> checkComponents();
  Future<WslSession> createSession({
    required String name,
    required String dataPath,
    required int cpuCount,
    required int memoryMB,
  });
  Future<void> terminateSession();

  // ======== 镜像 ========
  Future<List<WslImage>> listImages();
  Future<String> pullImage(String imageName);
  Future<void> deleteImage(String imageId);

  // ======== 容器 ========
  Future<List<WslContainer>> listContainers();
  Future<WslContainer> createContainer({
    required String image,
    required String name,
    required List<String> cmd,
  });
  Future<String> startContainer(String containerId);
  Future<void> stopContainer(String containerId);
  Future<void> deleteContainer(String containerId);
}
