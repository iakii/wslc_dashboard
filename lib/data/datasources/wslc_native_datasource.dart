import '../../core/platform/wslc_method_channel.dart';

/// Native call adapter.
///
/// Wraps the WslcMethodChannel singleton, providing a type-safe data source
/// interface. Caching and retry logic can be added here later.
class WslcNativeDatasource {
  final WslcMethodChannel _channel = WslcMethodChannel.instance;

  // Helper: convert raw decoded Map to Map<String, dynamic>
  static Map<String, dynamic> _castMap(dynamic raw) {
    return Map<String, dynamic>.from(raw as Map);
  }

  // Helper: convert raw decoded List to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> _castList(List<dynamic> raw) {
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ======== Session ========
  Future<Map<String, dynamic>> checkComponents() async {
    final raw = await _channel.checkComponents();
    return _castMap(raw);
  }

  Future<Map<String, dynamic>> createSession(
      Map<String, dynamic> config) async {
    final raw = await _channel.createSession(config);
    return _castMap(raw);
  }

  Future<void> terminateSession() => _channel.terminateSession();

  Future<Map<String, dynamic>> getSessionStatus() async {
    final raw = await _channel.getSessionStatus();
    return _castMap(raw);
  }

  // ======== Images ========
  Future<List<Map<String, dynamic>>> listImages() async {
    final raw = await _channel.listImages();
    return _castList(raw);
  }

  Future<Map<String, dynamic>> pullImage(String imageName) async {
    final raw = await _channel.pullImage(imageName);
    return _castMap(raw);
  }

  Future<void> deleteImage(String imageId) => _channel.deleteImage(imageId);

  // ======== Containers ========
  Future<List<Map<String, dynamic>>> listContainers() async {
    final raw = await _channel.listContainers();
    return _castList(raw);
  }

  Future<Map<String, dynamic>> createContainer(
      Map<String, dynamic> config) async {
    final raw = await _channel.createContainer(config);
    return _castMap(raw);
  }

  Future<Map<String, dynamic>> startContainer(String containerId) async {
    final raw = await _channel.startContainer(containerId);
    return _castMap(raw);
  }

  Future<void> stopContainer(String containerId) =>
      _channel.stopContainer(containerId);

  Future<void> deleteContainer(String containerId) =>
      _channel.deleteContainer(containerId);
}
