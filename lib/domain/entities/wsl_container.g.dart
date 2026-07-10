// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wsl_container.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WslContainerImpl _$$WslContainerImplFromJson(Map<String, dynamic> json) =>
    _$WslContainerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      imageName: json['imageName'] as String,
      status: $enumDecode(_$ContainerStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WslContainerImplToJson(_$WslContainerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imageName': instance.imageName,
      'status': _$ContainerStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ContainerStatusEnumMap = {
  ContainerStatus.created: 'created',
  ContainerStatus.running: 'running',
  ContainerStatus.stopped: 'stopped',
  ContainerStatus.deleting: 'deleting',
  ContainerStatus.unknown: 'unknown',
};
