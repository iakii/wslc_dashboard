import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/wsl_process_output.dart';

part 'wsl_container_log_model.g.dart';

/// 容器日志 JSON 模型
@JsonSerializable()
class WslContainerLogModel {
  final String stream;
  final String text;
  final int timestamp;

  const WslContainerLogModel({
    required this.stream,
    required this.text,
    required this.timestamp,
  });

  factory WslContainerLogModel.fromJson(Map<String, dynamic> json) =>
      _$WslContainerLogModelFromJson(json);

  Map<String, dynamic> toJson() => _$WslContainerLogModelToJson(this);

  WslProcessOutput toDomain() => WslProcessOutput(
        stream: stream,
        text: text,
        timestamp: timestamp,
      );
}
