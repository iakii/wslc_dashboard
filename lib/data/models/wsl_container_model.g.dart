// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wsl_container_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WslContainerModel _$WslContainerModelFromJson(Map<String, dynamic> json) =>
    WslContainerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageName: json['imageName'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WslContainerModelToJson(WslContainerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imageName': instance.imageName,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
    };
