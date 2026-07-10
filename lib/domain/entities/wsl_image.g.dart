// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wsl_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WslImageImpl _$$WslImageImplFromJson(Map<String, dynamic> json) =>
    _$WslImageImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      tag: json['tag'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WslImageImplToJson(_$WslImageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tag': instance.tag,
      'sizeBytes': instance.sizeBytes,
      'createdAt': instance.createdAt.toIso8601String(),
    };
