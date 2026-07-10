import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/wsl_session.dart';

part 'wsl_session_model.g.dart';

/// Session JSON 序列化模型
@JsonSerializable()
class WslSessionModel {
  final bool isRunning;
  final int imageCount;
  final int containerCount;
  final String version;
  final DateTime? startedAt;

  const WslSessionModel({
    required this.isRunning,
    required this.imageCount,
    required this.containerCount,
    this.version = '',
    this.startedAt,
  });

  factory WslSessionModel.fromJson(Map<String, dynamic> json) =>
      _$WslSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$WslSessionModelToJson(this);

  /// 映射为领域实体
  WslSession toDomain() => WslSession(
        isRunning: isRunning,
        imageCount: imageCount,
        containerCount: containerCount,
        version: version,
        startedAt: startedAt,
      );
}
