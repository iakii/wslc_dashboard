/// 简单日志工具
class Logger {
  const Logger._();

  static void info(String message) {
    // ignore: avoid_print
    print('[INFO] $message');
  }

  static void error(String message, [Object? error]) {
    // ignore: avoid_print
    print('[ERROR] $message${error != null ? ' | $error' : ''}');
  }

  static void debug(String message) {
    // ignore: avoid_print
    print('[DEBUG] $message');
  }
}
