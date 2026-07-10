/// 领域层错误抽象
sealed class Failure {
  const Failure(this.message);
  final String message;
}

/// WSL 组件未安装
class WslcNotInstalled extends Failure {
  const WslcNotInstalled(super.message);
}

/// Session 未启动
class SessionNotReady extends Failure {
  const SessionNotReady([super.message = 'WSL Session 未启动']);
}

/// 原生调用失败
class NativeApiFailure extends Failure {
  const NativeApiFailure(super.message, {this.code});
  final int? code;
}

/// 操作超时
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}
