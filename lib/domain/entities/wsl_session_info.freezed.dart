// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wsl_session_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WslSessionInfo _$WslSessionInfoFromJson(Map<String, dynamic> json) {
  return _WslSessionInfo.fromJson(json);
}

/// @nodoc
mixin _$WslSessionInfo {
  /// Session 系统 ID（wslc system session list 中的 ID 列）
  int get id => throw _privateConstructorUsedError;

  /// 创建者进程 PID
  int get creatorPid => throw _privateConstructorUsedError;

  /// 显示名称
  String get displayName => throw _privateConstructorUsedError;

  /// Dashboard 是否可操作此 session（自己通过 SDK 创建的）
  bool get isManagedByDashboard => throw _privateConstructorUsedError;

  /// Serializes this WslSessionInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WslSessionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WslSessionInfoCopyWith<WslSessionInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WslSessionInfoCopyWith<$Res> {
  factory $WslSessionInfoCopyWith(
    WslSessionInfo value,
    $Res Function(WslSessionInfo) then,
  ) = _$WslSessionInfoCopyWithImpl<$Res, WslSessionInfo>;
  @useResult
  $Res call({
    int id,
    int creatorPid,
    String displayName,
    bool isManagedByDashboard,
  });
}

/// @nodoc
class _$WslSessionInfoCopyWithImpl<$Res, $Val extends WslSessionInfo>
    implements $WslSessionInfoCopyWith<$Res> {
  _$WslSessionInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WslSessionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? creatorPid = null,
    Object? displayName = null,
    Object? isManagedByDashboard = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            creatorPid: null == creatorPid
                ? _value.creatorPid
                : creatorPid // ignore: cast_nullable_to_non_nullable
                      as int,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            isManagedByDashboard: null == isManagedByDashboard
                ? _value.isManagedByDashboard
                : isManagedByDashboard // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WslSessionInfoImplCopyWith<$Res>
    implements $WslSessionInfoCopyWith<$Res> {
  factory _$$WslSessionInfoImplCopyWith(
    _$WslSessionInfoImpl value,
    $Res Function(_$WslSessionInfoImpl) then,
  ) = __$$WslSessionInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int creatorPid,
    String displayName,
    bool isManagedByDashboard,
  });
}

/// @nodoc
class __$$WslSessionInfoImplCopyWithImpl<$Res>
    extends _$WslSessionInfoCopyWithImpl<$Res, _$WslSessionInfoImpl>
    implements _$$WslSessionInfoImplCopyWith<$Res> {
  __$$WslSessionInfoImplCopyWithImpl(
    _$WslSessionInfoImpl _value,
    $Res Function(_$WslSessionInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WslSessionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? creatorPid = null,
    Object? displayName = null,
    Object? isManagedByDashboard = null,
  }) {
    return _then(
      _$WslSessionInfoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        creatorPid: null == creatorPid
            ? _value.creatorPid
            : creatorPid // ignore: cast_nullable_to_non_nullable
                  as int,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        isManagedByDashboard: null == isManagedByDashboard
            ? _value.isManagedByDashboard
            : isManagedByDashboard // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WslSessionInfoImpl implements _WslSessionInfo {
  const _$WslSessionInfoImpl({
    required this.id,
    required this.creatorPid,
    required this.displayName,
    this.isManagedByDashboard = false,
  });

  factory _$WslSessionInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$WslSessionInfoImplFromJson(json);

  /// Session 系统 ID（wslc system session list 中的 ID 列）
  @override
  final int id;

  /// 创建者进程 PID
  @override
  final int creatorPid;

  /// 显示名称
  @override
  final String displayName;

  /// Dashboard 是否可操作此 session（自己通过 SDK 创建的）
  @override
  @JsonKey()
  final bool isManagedByDashboard;

  @override
  String toString() {
    return 'WslSessionInfo(id: $id, creatorPid: $creatorPid, displayName: $displayName, isManagedByDashboard: $isManagedByDashboard)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WslSessionInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.creatorPid, creatorPid) ||
                other.creatorPid == creatorPid) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.isManagedByDashboard, isManagedByDashboard) ||
                other.isManagedByDashboard == isManagedByDashboard));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    creatorPid,
    displayName,
    isManagedByDashboard,
  );

  /// Create a copy of WslSessionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WslSessionInfoImplCopyWith<_$WslSessionInfoImpl> get copyWith =>
      __$$WslSessionInfoImplCopyWithImpl<_$WslSessionInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WslSessionInfoImplToJson(this);
  }
}

abstract class _WslSessionInfo implements WslSessionInfo {
  const factory _WslSessionInfo({
    required final int id,
    required final int creatorPid,
    required final String displayName,
    final bool isManagedByDashboard,
  }) = _$WslSessionInfoImpl;

  factory _WslSessionInfo.fromJson(Map<String, dynamic> json) =
      _$WslSessionInfoImpl.fromJson;

  /// Session 系统 ID（wslc system session list 中的 ID 列）
  @override
  int get id;

  /// 创建者进程 PID
  @override
  int get creatorPid;

  /// 显示名称
  @override
  String get displayName;

  /// Dashboard 是否可操作此 session（自己通过 SDK 创建的）
  @override
  bool get isManagedByDashboard;

  /// Create a copy of WslSessionInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WslSessionInfoImplCopyWith<_$WslSessionInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
