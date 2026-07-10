import 'package:fluent_ui/fluent_ui.dart';

/// Fluent Design 主题配置
class AppTheme {
  AppTheme._();

  static FluentThemeData light() {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: Colors.blue,
      fontFamily: 'HarmonyOS Sans SC',
      scaffoldBackgroundColor: const Color(0xFFF5F5F5).withAlpha(133),
    );
  }

  static FluentThemeData dark() {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: Colors.blue,
      fontFamily: 'HarmonyOS Sans SC',
      scaffoldBackgroundColor: const Color(0xFF1B1B1F).withAlpha(133),
    );
  }
}
