import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nativeapi/nativeapi.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

/// 设置仓库 — 默认延迟初始化
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = Preferences();
  return SettingsRepositoryImpl(prefs);
});

/// 暗色主题开关（可被设置页覆写）
final isDarkThemeProvider = StateProvider<bool>((ref) {
  // 默认亮色主题；不强制依赖 nativeapi
  return false;
});

/// 最小化到托盘（可被设置页覆写）
final minimizeToTrayProvider = StateProvider<bool>((ref) {
  return true;
});
