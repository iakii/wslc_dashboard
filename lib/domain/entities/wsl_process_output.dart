/// 容器进程输出数据块（stdout/stderr）
class WslProcessOutput {
  const WslProcessOutput({
    required this.stream,
    required this.text,
    required this.timestamp,
  });

  /// 'stdout' | 'stderr' | 'exit'
  final String stream;

  final String text;

  final int timestamp;

  @override
  String toString() => '[${stream == 'stdout' ? 'out' : 'err'}] $text';
}
