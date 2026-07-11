import 'package:nativeapi/nativeapi.dart';
import '../../domain/repositories/session_preferences_repository.dart';

/// Dashboard session 名称持久化实现。
///
/// 存储为 Preferences 中的逗号分隔字符串，key = 'dashboard_sessions'。
class SessionPreferencesRepositoryImpl implements SessionPreferencesRepository {
  SessionPreferencesRepositoryImpl(this._prefs);

  final Preferences _prefs;

  static const _key = 'dashboard_sessions';

  @override
  List<String> getDashboardSessionNames() {
    final raw = _prefs.get(_key, '');
    if (raw.isEmpty) return [];
    return raw.split(',').where((s) => s.isNotEmpty).toList();
  }

  @override
  Future<void> addDashboardSessionName(String name) async {
    final names = getDashboardSessionNames();
    if (!names.contains(name)) {
      names.add(name);
      _prefs.set(_key, names.join(','));
    }
  }

  @override
  Future<void> removeDashboardSessionName(String name) async {
    final names = getDashboardSessionNames();
    names.remove(name);
    _prefs.set(_key, names.join(','));
  }

  void dispose() => _prefs.dispose();
}
