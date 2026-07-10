// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wsl_image_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WslImageModel _$WslImageModelFromJson(Map<String, dynamic> json) =>
    WslImageModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tag: json['tag'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WslImageModelToJson(WslImageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tag': instance.tag,
      'sizeBytes': instance.sizeBytes,
      'createdAt': instance.createdAt.toIso8601String(),
    };
