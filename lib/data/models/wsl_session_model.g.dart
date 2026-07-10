// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wsl_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WslSessionModel _$WslSessionModelFromJson(Map<String, dynamic> json) =>
    WslSessionModel(
      isRunning: json['isRunning'] as bool,
      imageCount: (json['imageCount'] as num).toInt(),
      containerCount: (json['containerCount'] as num).toInt(),
      version: json['version'] as String? ?? '',
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
    );

Map<String, dynamic> _$WslSessionModelToJson(WslSessionModel instance) =>
    <String, dynamic>{
      'isRunning': instance.isRunning,
      'imageCount': instance.imageCount,
      'containerCount': instance.containerCount,
      'version': instance.version,
      'startedAt': instance.startedAt?.toIso8601String(),
    };
