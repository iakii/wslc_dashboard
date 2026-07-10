import 'package:freezed_annotation/freezed_annotation.dart';

part 'wsl_container.freezed.dart';
part 'wsl_container.g.dart';

/// WSL 容器状态枚举
enum ContainerStatus { created, running, stopped, deleting, unknown }

/// WSL 容器领域实体
@freezed
class WslContainer with _$WslContainer {
  const factory WslContainer({
    required String id,
    required String name,
    required String imageName,
    required ContainerStatus status,
    required DateTime createdAt,
  }) = _WslContainer;

  factory WslContainer.fromJson(Map<String, dynamic> json) =>
      _$WslContainerFromJson(json);
}
