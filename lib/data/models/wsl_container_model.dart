import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/wsl_container.dart';

part 'wsl_container_model.g.dart';

/// 容器 JSON 序列化模型
@JsonSerializable()
class WslContainerModel {
  final String id;
  final String name;
  final String imageName;
  final String status;
  final DateTime createdAt;

  const WslContainerModel({
    required this.id,
    required this.name,
    required this.imageName,
    required this.status,
    required this.createdAt,
  });

  factory WslContainerModel.fromJson(Map<String, dynamic> json) =>
      _$WslContainerModelFromJson(json);

  Map<String, dynamic> toJson() => _$WslContainerModelToJson(this);

  /// 将状态字符串映射为枚举
  ContainerStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'created':
        return ContainerStatus.created;
      case 'running':
        return ContainerStatus.running;
      case 'stopped':
      case 'exited':
        return ContainerStatus.stopped;
      case 'deleting':
        return ContainerStatus.deleting;
      default:
        return ContainerStatus.unknown;
    }
  }

  WslContainer toDomain() => WslContainer(
        id: id,
        name: name,
        imageName: imageName,
        status: _parseStatus(status),
        createdAt: createdAt,
      );
}
