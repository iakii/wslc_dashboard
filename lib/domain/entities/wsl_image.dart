import 'package:freezed_annotation/freezed_annotation.dart';

part 'wsl_image.freezed.dart';
part 'wsl_image.g.dart';

/// WSL 容器镜像领域实体
@freezed
class WslImage with _$WslImage {
  const factory WslImage({
    required String id,
    required String name,
    required String tag,
    required int sizeBytes,
    required DateTime createdAt,
  }) = _WslImage;

  factory WslImage.fromJson(Map<String, dynamic> json) =>
      _$WslImageFromJson(json);
}
