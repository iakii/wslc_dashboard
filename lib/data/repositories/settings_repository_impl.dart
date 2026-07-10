import 'package:nativeapi/nativeapi.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/repositories/settings_repository.dart';

/// 设置持久化仓库实现（使用 nativeapi Preferences）
///
/// Preferences 存储字符串值，布尔值用 'true'/'false' 字符串表示。
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final Preferences _prefs;

  @override
  bool getTheme() => _prefs.get(AppConstants.prefTheme, 'true') == 'true';

  @override
  Future<void> setTheme(bool isDark) async {
    _prefs.set(AppConstants.prefTheme, isDark.toString());
  }

  @override
  bool getAutoStart() =>
      _prefs.get(AppConstants.prefAutoStart, 'false') == 'true';

  @override
  Future<void> setAutoStart(bool enabled) async {
    _prefs.set(AppConstants.prefAutoStart, enabled.toString());
  }

  @override
  bool getMinimizeToTray() =>
      _prefs.get(AppConstants.prefMinimizeToTray, 'true') == 'true';

  @override
  Future<void> setMinimizeToTray(bool enabled) async {
    _prefs.set(AppConstants.prefMinimizeToTray, enabled.toString());
  }

  void dispose() => _prefs.dispose();
}
