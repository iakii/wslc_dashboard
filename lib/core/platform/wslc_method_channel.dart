import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// Dart 端 MethodChannel/EventChannel 封装（单例）
///
/// 所有与 C++/WinRT 原生层的通信都通过此类中转。
class WslcMethodChannel {
  WslcMethodChannel._();

  static final WslcMethodChannel instance = WslcMethodChannel._();

  final MethodChannel _channel =
      const MethodChannel(AppConstants.wslcApiChannel);

  // ======== Session ========

  Future<Map<dynamic, dynamic>> checkComponents() async {
    final result = await _channel.invokeMethod('checkComponents');
    return Map<dynamic, dynamic>.from(result as Map);
  }

  Future<Map<dynamic, dynamic>> createSession(
      Map<String, dynamic> config) async {
    final result = await _channel.invokeMethod('createSession', config);
    return Map<dynamic, dynamic>.from(result as Map);
  }

  Future<void> terminateSession() async {
    await _channel.invokeMethod('terminateSession');
  }

  Future<Map<dynamic, dynamic>> getSessionStatus() async {
    final result = await _channel.invokeMethod('getSessionStatus');
    return Map<dynamic, dynamic>.from(result as Map);
  }

  // ======== 镜像 ========

  Future<List<dynamic>> listImages() async {
    final result = await _channel.invokeMethod('listImages');
    return List<dynamic>.from(result as List);
  }

  Future<Map<dynamic, dynamic>> pullImage(String imageName) async {
    final result =
        await _channel.invokeMethod('pullImage', {'imageName': imageName});
    return Map<dynamic, dynamic>.from(result as Map);
  }

  Future<void> deleteImage(String imageId) async {
    await _channel.invokeMethod('deleteImage', {'imageId': imageId});
  }

  // ======== 容器 ========

  Future<List<dynamic>> listContainers() async {
    final result = await _channel.invokeMethod('listContainers');
    return List<dynamic>.from(result as List);
  }

  Future<Map<dynamic, dynamic>> createContainer(
      Map<String, dynamic> config) async {
    final result =
        await _channel.invokeMethod('createContainer', config);
    return Map<dynamic, dynamic>.from(result as Map);
  }

  Future<Map<dynamic, dynamic>> startContainer(String containerId) async {
    final result =
        await _channel.invokeMethod('startContainer', {'containerId': containerId});
    return Map<dynamic, dynamic>.from(result as Map);
  }

  Future<void> stopContainer(String containerId) async {
    await _channel.invokeMethod('stopContainer', {'containerId': containerId});
  }

  Future<void> deleteContainer(String containerId) async {
    await _channel.invokeMethod('deleteContainer', {'containerId': containerId});
  }

  // ======== EventChannel（日志流 / 进度流） ========

  /// 获取容器日志 EventChannel
  EventChannel logEventChannel(String containerId) {
    return EventChannel('${AppConstants.wslcLogsPrefix}$containerId');
  }

  /// 获取拉取进度 EventChannel
  EventChannel pullProgressEventChannel(String operationId) {
    return EventChannel('${AppConstants.wslcPullPrefix}$operationId');
  }
}
