import '../../core/platform/wslc_method_channel.dart';

/// 原生调用适配器
///
/// 封装 WslcMethodChannel 的单例调用，提供类型安全的数据源接口。
/// 后续可在此层添加缓存、重试逻辑。
class WslcNativeDatasource {
  final WslcMethodChannel _channel = WslcMethodChannel.instance;

  // ======== Session ========
  Future<Map<String, dynamic>> checkComponents() async {
    final raw = await _channel.checkComponents();
    return raw.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createSession(
      Map<String, dynamic> config) async {
    final raw = await _channel.createSession(config);
    return raw.cast<String, dynamic>();
  }

  Future<void> terminateSession() => _channel.terminateSession();

  Future<Map<String, dynamic>> getSessionStatus() async {
    final raw = await _channel.getSessionStatus();
    return raw.cast<String, dynamic>();
  }

  // ======== 镜像 ========
  Future<List<Map<String, dynamic>>> listImages() async {
    final raw = await _channel.listImages();
    return raw.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> pullImage(String imageName) async {
    final raw = await _channel.pullImage(imageName);
    return raw.cast<String, dynamic>();
  }

  Future<void> deleteImage(String imageId) => _channel.deleteImage(imageId);

  // ======== 容器 ========
  Future<List<Map<String, dynamic>>> listContainers() async {
    final raw = await _channel.listContainers();
    return raw.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createContainer(
      Map<String, dynamic> config) async {
    final raw = await _channel.createContainer(config);
    return raw.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> startContainer(String containerId) async {
    final raw = await _channel.startContainer(containerId);
    return raw.cast<String, dynamic>();
  }

  Future<void> stopContainer(String containerId) =>
      _channel.stopContainer(containerId);

  Future<void> deleteContainer(String containerId) =>
      _channel.deleteContainer(containerId);
}
