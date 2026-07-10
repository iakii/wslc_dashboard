/// 应用设置持久化抽象接口
abstract class SettingsRepository {
  bool getTheme();
  Future<void> setTheme(bool isDark);

  bool getAutoStart();
  Future<void> setAutoStart(bool enabled);

  bool getMinimizeToTray();
  Future<void> setMinimizeToTray(bool enabled);
}
