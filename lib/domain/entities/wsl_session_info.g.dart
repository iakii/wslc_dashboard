// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wsl_session_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WslSessionInfoImpl _$$WslSessionInfoImplFromJson(Map<String, dynamic> json) =>
    _$WslSessionInfoImpl(
      id: (json['id'] as num).toInt(),
      creatorPid: (json['creatorPid'] as num).toInt(),
      displayName: json['displayName'] as String,
      isManagedByDashboard: json['isManagedByDashboard'] as bool? ?? false,
    );

Map<String, dynamic> _$$WslSessionInfoImplToJson(
  _$WslSessionInfoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'creatorPid': instance.creatorPid,
  'displayName': instance.displayName,
  'isManagedByDashboard': instance.isManagedByDashboard,
};
