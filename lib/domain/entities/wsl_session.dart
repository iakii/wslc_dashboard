import 'package:freezed_annotation/freezed_annotation.dart';

part 'wsl_session.freezed.dart';
part 'wsl_session.g.dart';

/// WSL Session 领域实体
@freezed
class WslSession with _$WslSession {
  const factory WslSession({
    required bool isRunning,
    required int imageCount,
    required int containerCount,
    @Default('') String version,
    DateTime? startedAt,
  }) = _WslSession;

  factory WslSession.fromJson(Map<String, dynamic> json) =>
      _$WslSessionFromJson(json);
}
