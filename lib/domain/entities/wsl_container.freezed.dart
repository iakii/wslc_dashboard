// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wsl_container.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WslContainer _$WslContainerFromJson(Map<String, dynamic> json) {
  return _WslContainer.fromJson(json);
}

/// @nodoc
mixin _$WslContainer {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get imageName => throw _privateConstructorUsedError;
  ContainerStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this WslContainer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WslContainer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WslContainerCopyWith<WslContainer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WslContainerCopyWith<$Res> {
  factory $WslContainerCopyWith(
    WslContainer value,
    $Res Function(WslContainer) then,
  ) = _$WslContainerCopyWithImpl<$Res, WslContainer>;
  @useResult
  $Res call({
    String id,
    String name,
    String imageName,
    ContainerStatus status,
    DateTime createdAt,
  });
}

/// @nodoc
class _$WslContainerCopyWithImpl<$Res, $Val extends WslContainer>
    implements $WslContainerCopyWith<$Res> {
  _$WslContainerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WslContainer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imageName = null,
    Object? status = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            imageName: null == imageName
                ? _value.imageName
                : imageName // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ContainerStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WslContainerImplCopyWith<$Res>
    implements $WslContainerCopyWith<$Res> {
  factory _$$WslContainerImplCopyWith(
    _$WslContainerImpl value,
    $Res Function(_$WslContainerImpl) then,
  ) = __$$WslContainerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String imageName,
    ContainerStatus status,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$WslContainerImplCopyWithImpl<$Res>
    extends _$WslContainerCopyWithImpl<$Res, _$WslContainerImpl>
    implements _$$WslContainerImplCopyWith<$Res> {
  __$$WslContainerImplCopyWithImpl(
    _$WslContainerImpl _value,
    $Res Function(_$WslContainerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WslContainer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imageName = null,
    Object? status = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$WslContainerImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        imageName: null == imageName
            ? _value.imageName
            : imageName // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ContainerStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WslContainerImpl implements _WslContainer {
  const _$WslContainerImpl({
    required this.id,
    required this.name,
    required this.imageName,
    required this.status,
    required this.createdAt,
  });

  factory _$WslContainerImpl.fromJson(Map<String, dynamic> json) =>
      _$$WslContainerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String imageName;
  @override
  final ContainerStatus status;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'WslContainer(id: $id, name: $name, imageName: $imageName, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WslContainerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.imageName, imageName) ||
                other.imageName == imageName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, imageName, status, createdAt);

  /// Create a copy of WslContainer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WslContainerImplCopyWith<_$WslContainerImpl> get copyWith =>
      __$$WslContainerImplCopyWithImpl<_$WslContainerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WslContainerImplToJson(this);
  }
}

abstract class _WslContainer implements WslContainer {
  const factory _WslContainer({
    required final String id,
    required final String name,
    required final String imageName,
    required final ContainerStatus status,
    required final DateTime createdAt,
  }) = _$WslContainerImpl;

  factory _WslContainer.fromJson(Map<String, dynamic> json) =
      _$WslContainerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get imageName;
  @override
  ContainerStatus get status;
  @override
  DateTime get createdAt;

  /// Create a copy of WslContainer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WslContainerImplCopyWith<_$WslContainerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
