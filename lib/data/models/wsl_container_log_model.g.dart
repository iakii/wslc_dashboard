// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wsl_container_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WslContainerLogModel _$WslContainerLogModelFromJson(
  Map<String, dynamic> json,
) => WslContainerLogModel(
  stream: json['stream'] as String,
  text: json['text'] as String,
  timestamp: (json['timestamp'] as num).toInt(),
);

Map<String, dynamic> _$WslContainerLogModelToJson(
  WslContainerLogModel instance,
) => <String, dynamic>{
  'stream': instance.stream,
  'text': instance.text,
  'timestamp': instance.timestamp,
};
