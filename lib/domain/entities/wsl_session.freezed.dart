// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wsl_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WslSession _$WslSessionFromJson(Map<String, dynamic> json) {
  return _WslSession.fromJson(json);
}

/// @nodoc
mixin _$WslSession {
  bool get isRunning => throw _privateConstructorUsedError;
  int get imageCount => throw _privateConstructorUsedError;
  int get containerCount => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;

  /// Serializes this WslSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WslSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WslSessionCopyWith<WslSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WslSessionCopyWith<$Res> {
  factory $WslSessionCopyWith(
    WslSession value,
    $Res Function(WslSession) then,
  ) = _$WslSessionCopyWithImpl<$Res, WslSession>;
  @useResult
  $Res call({
    bool isRunning,
    int imageCount,
    int containerCount,
    String version,
    DateTime? startedAt,
  });
}

/// @nodoc
class _$WslSessionCopyWithImpl<$Res, $Val extends WslSession>
    implements $WslSessionCopyWith<$Res> {
  _$WslSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WslSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRunning = null,
    Object? imageCount = null,
    Object? containerCount = null,
    Object? version = null,
    Object? startedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            isRunning: null == isRunning
                ? _value.isRunning
                : isRunning // ignore: cast_nullable_to_non_nullable
                      as bool,
            imageCount: null == imageCount
                ? _value.imageCount
                : imageCount // ignore: cast_nullable_to_non_nullable
                      as int,
            containerCount: null == containerCount
                ? _value.containerCount
                : containerCount // ignore: cast_nullable_to_non_nullable
                      as int,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as String,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WslSessionImplCopyWith<$Res>
    implements $WslSessionCopyWith<$Res> {
  factory _$$WslSessionImplCopyWith(
    _$WslSessionImpl value,
    $Res Function(_$WslSessionImpl) then,
  ) = __$$WslSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isRunning,
    int imageCount,
    int containerCount,
    String version,
    DateTime? startedAt,
  });
}

/// @nodoc
class __$$WslSessionImplCopyWithImpl<$Res>
    extends _$WslSessionCopyWithImpl<$Res, _$WslSessionImpl>
    implements _$$WslSessionImplCopyWith<$Res> {
  __$$WslSessionImplCopyWithImpl(
    _$WslSessionImpl _value,
    $Res Function(_$WslSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WslSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRunning = null,
    Object? imageCount = null,
    Object? containerCount = null,
    Object? version = null,
    Object? startedAt = freezed,
  }) {
    return _then(
      _$WslSessionImpl(
        isRunning: null == isRunning
            ? _value.isRunning
            : isRunning // ignore: cast_nullable_to_non_nullable
                  as bool,
        imageCount: null == imageCount
            ? _value.imageCount
            : imageCount // ignore: cast_nullable_to_non_nullable
                  as int,
        containerCount: null == containerCount
            ? _value.containerCount
            : containerCount // ignore: cast_nullable_to_non_nullable
                  as int,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as String,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WslSessionImpl implements _WslSession {
  const _$WslSessionImpl({
    required this.isRunning,
    required this.imageCount,
    required this.containerCount,
    this.version = '',
    this.startedAt,
  });

  factory _$WslSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WslSessionImplFromJson(json);

  @override
  final bool isRunning;
  @override
  final int imageCount;
  @override
  final int containerCount;
  @override
  @JsonKey()
  final String version;
  @override
  final DateTime? startedAt;

  @override
  String toString() {
    return 'WslSession(isRunning: $isRunning, imageCount: $imageCount, containerCount: $containerCount, version: $version, startedAt: $startedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WslSessionImpl &&
            (identical(other.isRunning, isRunning) ||
                other.isRunning == isRunning) &&
            (identical(other.imageCount, imageCount) ||
                other.imageCount == imageCount) &&
            (identical(other.containerCount, containerCount) ||
                other.containerCount == containerCount) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isRunning,
    imageCount,
    containerCount,
    version,
    startedAt,
  );

  /// Create a copy of WslSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WslSessionImplCopyWith<_$WslSessionImpl> get copyWith =>
      __$$WslSessionImplCopyWithImpl<_$WslSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WslSessionImplToJson(this);
  }
}

abstract class _WslSession implements WslSession {
  const factory _WslSession({
    required final bool isRunning,
    required final int imageCount,
    required final int containerCount,
    final String version,
    final DateTime? startedAt,
  }) = _$WslSessionImpl;

  factory _WslSession.fromJson(Map<String, dynamic> json) =
      _$WslSessionImpl.fromJson;

  @override
  bool get isRunning;
  @override
  int get imageCount;
  @override
  int get containerCount;
  @override
  String get version;
  @override
  DateTime? get startedAt;

  /// Create a copy of WslSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WslSessionImplCopyWith<_$WslSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
