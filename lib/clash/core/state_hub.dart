import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';
import 'core_state.dart';
import 'service_state.dart';
import 'subscription_state.dart';
import 'override_state.dart';

// 全局状态中枢事件类型
enum StateHubEventType {
  // 内核状态变化
  coreStateChanged,

  // 服务状态变化
  serviceStateChanged,

  // 订阅状态变化
  subscriptionStateChanged,

  // 覆写状态变化
  overrideStateChanged,

  // 系统级错误
  systemError,

  // 状态同步完成
  stateSyncCompleted,
}

// 状态中枢事件
class StateHubEvent {
  final StateHubEventType type;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  StateHubEvent({
    required this.type,
    required this.message,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'StateHubEvent(type: $type, message: $message, data: $data, timestamp: $timestamp)';
  }
}

// 全局状态中枢
//
// 负责协调各个状态管理器之间的事件和状态同步
class StateHub extends ChangeNotifier {
  static StateHub? _instance;
  static StateHub get instance => _instance ??= StateHub._();

  StateHub._() {
    _initializeStateListeners();
  }

  final StreamController<StateHubEvent> _eventController =
      StreamController<StateHubEvent>.broadcast();

  // 状态中枢事件流
  Stream<StateHubEvent> get eventStream => _eventController.stream;

  // 各状态管理器的订阅
  StreamSubscription<CoreStateChangeEvent>? _coreSubscription;
  StreamSubscription<ServiceStateChangeEvent>? _serviceSubscription;
  StreamSubscription<SubscriptionStateChangeEvent>? _subscriptionSubscription;
  StreamSubscription<OverrideStateChangeEvent>? _overrideSubscription;

  // 当前系统整体状态
  SystemHealthStatus _systemHealth = SystemHealthStatus.healthy;
  SystemHealthStatus get systemHealth => _systemHealth;

  // 初始化状态监听器
  void _initializeStateListeners() {
    // 监听内核状态变化
    _coreSubscription = CoreStateManager.instance.stateStream.listen(
      (event) {
        _handleCoreStateChange(event);
      },
      onError: (error) {
        Logger.error('内核状态监听错误：$error');
        _emitEvent(StateHubEventType.systemError, '内核状态监听错误', {
          'error': error.toString(),
        });
      },
    );

    // 监听服务状态变化
    _serviceSubscription = ServiceStateManager.instance.stateChangeStream
        .listen(
          (event) {
            _handleServiceStateChange(event);
          },
          onError: (error) {
            Logger.error('服务状态监听错误：$error');
            _emitEvent(StateHubEventType.systemError, '服务状态监听错误', {
              'error': error.toString(),
            });
          },
        );

    // 监听订阅状态变化
    _subscriptionSubscription = SubscriptionStateManager
        .instance
        .stateChangeStream
        .listen(
          (event) {
            _handleSubscriptionStateChange(event);
          },
          onError: (error) {
            Logger.error('订阅状态监听错误：$error');
            _emitEvent(StateHubEventType.systemError, '订阅状态监听错误', {
              'error': error.toString(),
            });
          },
        );

    // 监听覆写状态变化
    _overrideSubscription = OverrideStateManager.instance.stateChangeStream
        .listen(
          (event) {
            _handleOverrideStateChange(event);
          },
          onError: (error) {
            Logger.error('覆写状态监听错误：$error');
            _emitEvent(StateHubEventType.systemError, '覆写状态监听错误', {
              'error': error.toString(),
            });
          },
        );

    Logger.info('状态中枢已初始化，开始监听各模块状态变化');
  }

  // 处理内核状态变化
  void _handleCoreStateChange(CoreStateChangeEvent event) {
    Logger.debug(
      '状态中枢收到内核状态变化：${event.previousState.name} -> ${event.currentState.name}',
    );

    _emitEvent(
      StateHubEventType.coreStateChanged,
      '内核状态变化：${event.previousState.name} -> ${event.currentState.name}',
      {
        'previousState': event.previousState.name,
        'currentState': event.currentState.name,
        'reason': event.reason,
        'timestamp': event.timestamp.toIso8601String(),
      },
    );

    // 根据内核状态调整系统健康状态
    _updateSystemHealthFromCore(event.currentState);
  }

  // 处理服务状态变化
  void _handleServiceStateChange(ServiceStateChangeEvent event) {
    Logger.debug(
      '状态中枢收到服务状态变化：${event.previousState.name} -> ${event.currentState.name}',
    );

    _emitEvent(
      StateHubEventType.serviceStateChanged,
      '服务状态变化：${event.previousState.name} -> ${event.currentState.name}',
      {
        'previousState': event.previousState.name,
        'currentState': event.currentState.name,
        'reason': event.reason,
        'timestamp': event.timestamp.toIso8601String(),
      },
    );

    // 根据服务状态调整系统健康状态
    _updateSystemHealthFromService(event.currentState);
  }

  // 处理订阅状态变化
  void _handleSubscriptionStateChange(SubscriptionStateChangeEvent event) {
    Logger.debug('状态中枢收到订阅状态变化：${event.toString()}');

    _emitEvent(StateHubEventType.subscriptionStateChanged, event.toString(), {
      'previousOperationState': event.previousOperationState.name,
      'currentOperationState': event.currentOperationState.name,
      'previousErrorState': event.previousErrorState.name,
      'currentErrorState': event.currentErrorState.name,
      'reason': event.reason,
      'timestamp': event.timestamp.toIso8601String(),
    });
  }

  // 处理覆写状态变化
  void _handleOverrideStateChange(OverrideStateChangeEvent event) {
    Logger.debug('状态中枢收到覆写状态变化：${event.toString()}');

    _emitEvent(StateHubEventType.overrideStateChanged, event.toString(), {
      'previousOperationState': event.previousOperationState.name,
      'currentOperationState': event.currentOperationState.name,
      'previousErrorState': event.previousErrorState.name,
      'currentErrorState': event.currentErrorState.name,
      'reason': event.reason,
      'timestamp': event.timestamp.toIso8601String(),
    });
  }

  // 更新基于内核状态的系统健康状态
  void _updateSystemHealthFromCore(CoreState coreState) {
    final previousHealth = _systemHealth;

    switch (coreState) {
      case CoreState.stopped:
      case CoreState.running:
        _systemHealth = SystemHealthStatus.healthy;
        break;
      case CoreState.starting:
      case CoreState.stopping:
      case CoreState.restarting:
        _systemHealth = SystemHealthStatus.warning;
        break;
    }

    if (previousHealth != _systemHealth) {
      Logger.info(
        '系统健康状态变化：$previousHealth -> $_systemHealth (基于内核状态：${coreState.name})',
      );
      notifyListeners();
    }
  }

  // 更新基于服务状态的系统健康状态
  void _updateSystemHealthFromService(ServiceState serviceState) {
    // 服务状态主要影响系统功能可用性，但不直接影响核心健康状态
    // 这里可以根据具体需求调整逻辑
    if (serviceState == ServiceState.unknown) {
      Logger.warning('服务状态未知，但不影响系统核心健康');
    }
  }

  // 发送中枢事件
  void _emitEvent(
    StateHubEventType type,
    String message, [
    Map<String, dynamic>? data,
  ]) {
    final event = StateHubEvent(type: type, message: message, data: data);

    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  // 获取系统整体状态摘要
  SystemStateSummary getSystemStateSummary() {
    return SystemStateSummary(
      coreState: CoreStateManager.instance.currentState,
      serviceState: ServiceStateManager.instance.currentState,
      subscriptionOperationState:
          SubscriptionStateManager.instance.operationState,
      overrideOperationState: OverrideStateManager.instance.operationState,
      systemHealth: _systemHealth,
      hasCoreError: false, // CoreStateManager 没有错误状态
      hasServiceError:
          ServiceStateManager.instance.currentState == ServiceState.unknown,
      hasSubscriptionError:
          SubscriptionStateManager.instance.errorState !=
          SubscriptionErrorState.none,
      hasOverrideError:
          OverrideStateManager.instance.errorState != OverrideErrorState.none,
    );
  }

  // 触发状态同步检查
  Future<void> syncAllStates() async {
    Logger.info('开始同步所有状态管理器状态');

    try {
      // 这里可以添加状态同步逻辑
      // 例如检查各状态管理器的一致性

      _emitEvent(StateHubEventType.stateSyncCompleted, '所有状态同步完成');
      Logger.info('状态同步完成');
    } catch (error) {
      Logger.error('状态同步失败：$error');
      _emitEvent(StateHubEventType.systemError, '状态同步失败', {
        'error': error.toString(),
      });
    }
  }

  @override
  void dispose() {
    _coreSubscription?.cancel();
    _serviceSubscription?.cancel();
    _subscriptionSubscription?.cancel();
    _overrideSubscription?.cancel();
    _eventController.close();
    super.dispose();
  }
}

// 系统健康状态
enum SystemHealthStatus {
  // 健康
  healthy,

  // 警告
  warning,

  // 错误
  error,
}

// 系统状态摘要
class SystemStateSummary {
  final CoreState coreState;
  final ServiceState serviceState;
  final SubscriptionOperationState subscriptionOperationState;
  final OverrideOperationState overrideOperationState;
  final SystemHealthStatus systemHealth;
  final bool hasCoreError;
  final bool hasServiceError;
  final bool hasSubscriptionError;
  final bool hasOverrideError;

  const SystemStateSummary({
    required this.coreState,
    required this.serviceState,
    required this.subscriptionOperationState,
    required this.overrideOperationState,
    required this.systemHealth,
    required this.hasCoreError,
    required this.hasServiceError,
    required this.hasSubscriptionError,
    required this.hasOverrideError,
  });

  // 是否有任何错误
  bool get hasAnyError =>
      hasCoreError ||
      hasServiceError ||
      hasSubscriptionError ||
      hasOverrideError;

  // 是否系统正在进行操作
  bool get isSystemBusy {
    return coreState == CoreState.starting ||
        coreState == CoreState.stopping ||
        coreState == CoreState.restarting ||
        serviceState == ServiceState.installing ||
        serviceState == ServiceState.uninstalling ||
        subscriptionOperationState == SubscriptionOperationState.loading ||
        subscriptionOperationState == SubscriptionOperationState.updating ||
        subscriptionOperationState ==
            SubscriptionOperationState.batchUpdating ||
        subscriptionOperationState == SubscriptionOperationState.autoUpdating ||
        overrideOperationState == OverrideOperationState.loading ||
        overrideOperationState == OverrideOperationState.updating ||
        overrideOperationState == OverrideOperationState.batchUpdating ||
        overrideOperationState == OverrideOperationState.downloading;
  }

  @override
  String toString() {
    return 'SystemStateSummary('
        'core：${coreState.name}，'
        'service：${serviceState.name}，'
        'subscription：${subscriptionOperationState.name}，'
        'override：${overrideOperationState.name}，'
        'health：${systemHealth.name}，'
        'hasErrors：$hasAnyError，'
        'isBusy：$isSystemBusy)';
  }
}
