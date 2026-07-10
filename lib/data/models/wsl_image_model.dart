import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/wsl_image.dart';

part 'wsl_image_model.g.dart';

/// 镜像 JSON 序列化模型
@JsonSerializable()
class WslImageModel {
  final String id;
  final String name;
  final String tag;
  final int sizeBytes;
  final DateTime createdAt;

  const WslImageModel({
    required this.id,
    required this.name,
    required this.tag,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory WslImageModel.fromJson(Map<String, dynamic> json) =>
      _$WslImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$WslImageModelToJson(this);

  WslImage toDomain() => WslImage(
        id: id,
        name: name,
        tag: tag,
        sizeBytes: sizeBytes,
        createdAt: createdAt,
      );
}
