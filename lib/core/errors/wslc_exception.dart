/// WSL Container 异常包装
class WslcException implements Exception {
  const WslcException(this.message, {this.code});
  final String message;
  final int? code;

  @override
  String toString() => 'WslcException($code): $message';
}
