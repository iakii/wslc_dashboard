// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wsl_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WslSessionImpl _$$WslSessionImplFromJson(Map<String, dynamic> json) =>
    _$WslSessionImpl(
      isRunning: json['isRunning'] as bool,
      imageCount: (json['imageCount'] as num).toInt(),
      containerCount: (json['containerCount'] as num).toInt(),
      version: json['version'] as String? ?? '',
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
    );

Map<String, dynamic> _$$WslSessionImplToJson(_$WslSessionImpl instance) =>
    <String, dynamic>{
      'isRunning': instance.isRunning,
      'imageCount': instance.imageCount,
      'containerCount': instance.containerCount,
      'version': instance.version,
      'startedAt': instance.startedAt?.toIso8601String(),
    };
