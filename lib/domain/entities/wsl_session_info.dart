import 'package:freezed_annotation/freezed_annotation.dart';

part 'wsl_session_info.freezed.dart';
part 'wsl_session_info.g.dart';

/// Session 信息实体（用于列表展示和选择）。
///
/// 区别于 [WslSession]（表示当前活跃 session 的运行状态），
/// 本实体表示通过 CLI 查询到的 session 元信息。
@freezed
class WslSessionInfo with _$WslSessionInfo {
  const factory WslSessionInfo({
    /// Session 系统 ID（wslc system session list 中的 ID 列）
    required int id,

    /// 创建者进程 PID
    required int creatorPid,

    /// 显示名称
    required String displayName,

    /// Dashboard 是否可操作此 session（自己通过 SDK 创建的）
    @Default(false) bool isManagedByDashboard,
  }) = _WslSessionInfo;

  factory WslSessionInfo.fromJson(Map<String, dynamic> json) =>
      _$WslSessionInfoFromJson(json);
}
