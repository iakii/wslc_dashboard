import 'dart:io';

import '../../domain/entities/wsl_session_info.dart';

/// 通过 shell 调用 wslc CLI 获取 session 列表（`wslc system session list`），
/// 解析其表格输出为 [WslSessionInfo]。
///
/// CLI 不可用或解析失败时静默降级，返回空列表。
class WslcCliDatasource {
  /// 调用 `wslc system session list` 并解析为 [WslSessionInfo] 列表。
  ///
  /// 输出格式（空格分隔的列）：
  /// ```
  /// ID   创建者 PID   显示名称
  /// 1    39644     wslc-cli-Kai
  /// 31   39648     wslc_dashboard
  /// ```
  Future<List<WslSessionInfo>> listSessions({
    List<String> dashboardSessionNames = const [],
  }) async {
    try {
      final result = await Process.run(
        'wslc',
        ['system', 'session', 'list'],
        runInShell: true,
      );
      if (result.exitCode != 0) return [];
      return _parseTable(result.stdout as String, dashboardSessionNames);
    } catch (e) {
      // wslc CLI 不可用或无 session — 静默降级返回空列表
      return [];
    }
  }

  /// 解析表格输出为 [WslSessionInfo] 列表。
  ///
  /// 跳过标题行（首行），后续行按连续空白切分为 ID、创建者 PID、
  /// 显示名称三列。名称可能含空格，使用 `sublist(2)` 取余列拼接。
  List<WslSessionInfo> _parseTable(
    String output,
    List<String> dashboardSessionNames,
  ) {
    final lines = output.trim().split('\n');
    // 仅有标题行或空输出
    if (lines.length < 2) return [];

    final result = <WslSessionInfo>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 3) continue;

      final id = int.tryParse(parts[0]);
      final pid = int.tryParse(parts[1]);
      // 显示名称可能包含空格，取第 3 列起拼接
      final name = parts.sublist(2).join(' ').trim();

      if (id == null || pid == null || name.isEmpty) continue;

      result.add(WslSessionInfo(
        id: id,
        creatorPid: pid,
        displayName: name,
        isManagedByDashboard: dashboardSessionNames.contains(name),
      ));
    }
    return result;
  }
}
