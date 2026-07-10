// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wsl_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WslImage _$WslImageFromJson(Map<String, dynamic> json) {
  return _WslImage.fromJson(json);
}

/// @nodoc
mixin _$WslImage {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get tag => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this WslImage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WslImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WslImageCopyWith<WslImage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WslImageCopyWith<$Res> {
  factory $WslImageCopyWith(WslImage value, $Res Function(WslImage) then) =
      _$WslImageCopyWithImpl<$Res, WslImage>;
  @useResult
  $Res call({
    String id,
    String name,
    String tag,
    int sizeBytes,
    DateTime createdAt,
  });
}

/// @nodoc
class _$WslImageCopyWithImpl<$Res, $Val extends WslImage>
    implements $WslImageCopyWith<$Res> {
  _$WslImageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WslImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tag = null,
    Object? sizeBytes = null,
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
            tag: null == tag
                ? _value.tag
                : tag // ignore: cast_nullable_to_non_nullable
                      as String,
            sizeBytes: null == sizeBytes
                ? _value.sizeBytes
                : sizeBytes // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$WslImageImplCopyWith<$Res>
    implements $WslImageCopyWith<$Res> {
  factory _$$WslImageImplCopyWith(
    _$WslImageImpl value,
    $Res Function(_$WslImageImpl) then,
  ) = __$$WslImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String tag,
    int sizeBytes,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$WslImageImplCopyWithImpl<$Res>
    extends _$WslImageCopyWithImpl<$Res, _$WslImageImpl>
    implements _$$WslImageImplCopyWith<$Res> {
  __$$WslImageImplCopyWithImpl(
    _$WslImageImpl _value,
    $Res Function(_$WslImageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WslImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tag = null,
    Object? sizeBytes = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$WslImageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        tag: null == tag
            ? _value.tag
            : tag // ignore: cast_nullable_to_non_nullable
                  as String,
        sizeBytes: null == sizeBytes
            ? _value.sizeBytes
            : sizeBytes // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$WslImageImpl implements _WslImage {
  const _$WslImageImpl({
    required this.id,
    required this.name,
    required this.tag,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory _$WslImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$WslImageImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String tag;
  @override
  final int sizeBytes;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'WslImage(id: $id, name: $name, tag: $tag, sizeBytes: $sizeBytes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WslImageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.tag, tag) || other.tag == tag) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, tag, sizeBytes, createdAt);

  /// Create a copy of WslImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WslImageImplCopyWith<_$WslImageImpl> get copyWith =>
      __$$WslImageImplCopyWithImpl<_$WslImageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WslImageImplToJson(this);
  }
}

abstract class _WslImage implements WslImage {
  const factory _WslImage({
    required final String id,
    required final String name,
    required final String tag,
    required final int sizeBytes,
    required final DateTime createdAt,
  }) = _$WslImageImpl;

  factory _WslImage.fromJson(Map<String, dynamic> json) =
      _$WslImageImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get tag;
  @override
  int get sizeBytes;
  @override
  DateTime get createdAt;

  /// Create a copy of WslImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WslImageImplCopyWith<_$WslImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
