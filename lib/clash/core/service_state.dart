import 'dart:async';
import 'package:flutter/foundation.dart';

// 服务状态枚举
enum ServiceState {
  // 服务未安装
  notInstalled,

  // 服务已安装但未运行
  installed,

  // 服务正在运行
  running,

  // 正在安装服务
  installing,

  // 正在卸载服务
  uninstalling,

  // 状态未知（检测失败）
  unknown,
}

// 服务状态扩展方法
extension ServiceStateExtension on ServiceState {
  // 是否已安装（卸载中也视为已安装，直到卸载完成）
  bool get isInstalled =>
      this == ServiceState.installed ||
      this == ServiceState.running ||
      this == ServiceState.uninstalling;

  // 是否正在运行
  bool get isRunning => this == ServiceState.running;

  // 是否正在处理操作（安装或卸载）
  bool get isProcessing =>
      this == ServiceState.installing || this == ServiceState.uninstalling;
}

// 服务状态变化事件
class ServiceStateChangeEvent {
  final ServiceState previousState;
  final ServiceState currentState;
  final DateTime timestamp;
  final String? reason;

  const ServiceStateChangeEvent({
    required this.previousState,
    required this.currentState,
    required this.timestamp,
    this.reason,
  });

  @override
  String toString() {
    return '服务状态变化事件(${previousState.name} -> ${currentState.name}${reason != null ? '，原因：$reason' : ''})';
  }
}

// 服务状态管理器
class ServiceStateManager extends ChangeNotifier {
  static final ServiceStateManager _instance = ServiceStateManager._internal();
  static ServiceStateManager get instance => _instance;
  ServiceStateManager._internal();

  ServiceState _currentState = ServiceState.unknown;
  final StreamController<ServiceStateChangeEvent> _stateChangeController =
      StreamController<ServiceStateChangeEvent>.broadcast();

  // 当前服务状态
  ServiceState get currentState => _currentState;

  // 状态变化事件流
  Stream<ServiceStateChangeEvent> get stateChangeStream =>
      _stateChangeController.stream;

  // 便捷方法 - 是否已安装
  bool get isInstalled => _currentState.isInstalled;

  // 便捷方法 - 是否正在运行
  bool get isRunning => _currentState.isRunning;

  // 便捷方法 - 是否正在处理操作
  bool get isProcessing => _currentState.isProcessing;

  // 更新服务状态
  void updateState(ServiceState newState, {String? reason}) {
    if (_currentState == newState) return;

    final previousState = _currentState;
    _currentState = newState;

    // 发送状态变化事件
    final event = ServiceStateChangeEvent(
      previousState: previousState,
      currentState: newState,
      timestamp: DateTime.now(),
      reason: reason,
    );

    _stateChangeController.add(event);
    notifyListeners();
  }

  // 设置为未安装状态
  void setNotInstalled({String? reason}) {
    updateState(ServiceState.notInstalled, reason: reason);
  }

  // 设置为已安装状态
  void setInstalled({String? reason}) {
    updateState(ServiceState.installed, reason: reason);
  }

  // 设置为运行状态
  void setRunning({String? reason}) {
    updateState(ServiceState.running, reason: reason);
  }

  // 设置为正在安装状态
  void setInstalling({String? reason}) {
    updateState(ServiceState.installing, reason: reason);
  }

  // 设置为正在卸载状态
  void setUninstalling({String? reason}) {
    updateState(ServiceState.uninstalling, reason: reason);
  }

  // 设置为未知状态
  void setUnknown({String? reason}) {
    updateState(ServiceState.unknown, reason: reason);
  }

  // 从字符串解析状态
  void updateFromStatusString(String statusStr, {String? reason}) {
    final ServiceState newState;
    switch (statusStr.toLowerCase()) {
      case 'running':
        newState = ServiceState.running;
        break;
      case 'stopped':
        newState = ServiceState.installed;
        break;
      case 'not_installed':
        newState = ServiceState.notInstalled;
        break;
      default:
        newState = ServiceState.unknown;
    }
    updateState(newState, reason: reason ?? '来自服务器的状态：$statusStr');
  }

  // 重置状态管理器
  void reset() {
    updateState(ServiceState.unknown, reason: '重置状态管理器');
  }

  @override
  void dispose() {
    _stateChangeController.close();
    super.dispose();
  }
}
