/// MethodChannel 名称常量
class AppConstants {
  AppConstants._();

  /// WSL Container 原生 API 通道
  static const String wslcApiChannel = 'com.wslc.dashboard/api';

  /// 容器日志 EventChannel 前缀
  static const String wslcLogsPrefix = 'com.wslc.dashboard/events/logs/';

  /// 拉取进度 EventChannel 前缀
  static const String wslcPullPrefix = 'com.wslc.dashboard/events/pull/';

  /// 默认 Session 配置
  static const String defaultSessionName = 'wslc_dashboard';
  static const String defaultDataPath = r'%LOCALAPPDATA%\wslc_dashboard';
  static const int defaultCpuCount = 2;
  static const int defaultMemoryMB = 2048;

  /// 窗口配置
  static const double defaultWindowWidth = 1280;
  static const double defaultWindowHeight = 800;
  static const double minWindowWidth = 900;
  static const double minWindowHeight = 600;

  /// Preferences 键名
  static const String prefTheme = 'theme';
  static const String prefAutoStart = 'auto_start';
  static const String prefMinimizeToTray = 'minimize_to_tray';
}
