import 'dart:async';
import 'package:flutter/foundation.dart';

// Clash 内核状态枚举，只包含目前实际使用的状态
enum CoreState {
  // 已停止 - 内核未运行
  stopped,

  // 正在启动 - 内核正在启动过程中
  starting,

  // 正在运行 - 内核正常运行中
  running,

  // 正在停止 - 内核正在停止过程中
  stopping,

  // 正在重启 - 内核正在重启过程中
  restarting,
}

// 内核状态扩展方法
extension CoreStateExtension on CoreState {
  /// 是否为运行状态
  bool get isRunning => this == CoreState.running;

  /// 是否为停止状态
  bool get isStopped => this == CoreState.stopped;

  /// 是否为过渡状态（正在执行某个操作）
  bool get isTransitioning => [
    CoreState.starting,
    CoreState.stopping,
    CoreState.restarting,
  ].contains(this);

  /// 是否可以启动
  bool get canStart => this == CoreState.stopped;

  /// 是否可以停止
  bool get canStop => this == CoreState.running;

  /// 是否可以重启
  bool get canRestart => this == CoreState.running;
}

// 内核状态变化事件
class CoreStateChangeEvent {
  // 之前的状态
  final CoreState previousState;

  // 当前状态
  final CoreState currentState;

  // 状态变化的原因（可选）
  final String? reason;

  // 状态变化的时间戳
  final DateTime timestamp;

  const CoreStateChangeEvent({
    required this.previousState,
    required this.currentState,
    this.reason,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'CoreStateChangeEvent(${previousState.name} -> ${currentState.name}${reason != null ? ', reason: $reason' : ''})';
  }
}

// 内核状态管理器，负责管理 Clash 内核的状态，提供状态变化通知
class CoreStateManager extends ChangeNotifier {
  // 当前状态
  CoreState _currentState = CoreState.stopped;

  // 获取当前状态
  CoreState get currentState => _currentState;

  // 状态变化流控制器
  final StreamController<CoreStateChangeEvent> _stateStreamController =
      StreamController<CoreStateChangeEvent>.broadcast();

  // 状态变化流
  Stream<CoreStateChangeEvent> get stateStream => _stateStreamController.stream;

  // 单例实例
  static final CoreStateManager _instance = CoreStateManager._internal();

  // 获取单例实例
  static CoreStateManager get instance => _instance;

  // 私有构造函数
  CoreStateManager._internal();

  // 工厂构造函数
  factory CoreStateManager() => _instance;

  // 状态变化方法 - 统一的状态变化入口
  void changeState(CoreState newState, {String? reason}) {
    if (_currentState == newState) {
      return; // 状态未变化，不触发通知
    }

    final previousState = _currentState;
    _currentState = newState;

    // 创建状态变化事件
    final event = CoreStateChangeEvent(
      previousState: previousState,
      currentState: newState,
      reason: reason,
      timestamp: DateTime.now(),
    );

    // 发送状态变化事件
    _stateStreamController.add(event);

    // 通知监听器
    notifyListeners();
  }

  // 便捷方法：设置为已停止状态
  void setStopped({String? reason}) {
    changeState(CoreState.stopped, reason: reason);
  }

  // 便捷方法：设置为正在启动状态
  void setStarting({String? reason}) {
    changeState(CoreState.starting, reason: reason);
  }

  // 便捷方法：设置为正在运行状态
  void setRunning({String? reason}) {
    changeState(CoreState.running, reason: reason);
  }

  // 便捷方法：设置为正在停止状态
  void setStopping({String? reason}) {
    changeState(CoreState.stopping, reason: reason);
  }

  // 便捷方法：设置为正在重启状态
  void setRestarting({String? reason}) {
    changeState(CoreState.restarting, reason: reason);
  }

  // 检查是否可以执行指定操作
  bool canPerformOperation(String operation) {
    switch (operation.toLowerCase()) {
      case 'start':
        return _currentState.canStart;
      case 'stop':
        return _currentState.canStop;
      case 'restart':
        return _currentState.canRestart;
      default:
        return false;
    }
  }

  @override
  void dispose() {
    _stateStreamController.close();
    super.dispose();
  }
}
