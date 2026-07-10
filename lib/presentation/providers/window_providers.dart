import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nativeapi/nativeapi.dart';

/// WindowManager 单例
final windowManagerProvider = Provider<WindowManager>((ref) {
  return WindowManager.instance;
});
