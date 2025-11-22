import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stelliberty/utils/logger.dart';

// 覆写操作状态枚举
enum OverrideOperationState {
  // 空闲状态
  idle,

  // 正在加载
  loading,

  // 正在更新单个覆写
  updating,

  // 正在批量更新
  batchUpdating,

  // 正在下载远程覆写
  downloading,
}

// 覆写错误状态枚举
enum OverrideErrorState {
  // 无错误
  none,

  // 初始化错误
  initializationError,

  // 网络错误
  networkError,

  // 文件系统错误
  fileSystemError,

  // 格式错误
  formatError,

  // 未知错误
  unknownError,
}

// 覆写状态扩展方法
extension OverrideOperationStateExtension on OverrideOperationState {
  // 是否为空闲状态
  bool get isIdle => this == OverrideOperationState.idle;

  // 是否正在加载
  bool get isLoading => this == OverrideOperationState.loading;

  // 是否正在更新（任何类型的更新）
  bool get isUpdating =>
      this == OverrideOperationState.updating ||
      this == OverrideOperationState.batchUpdating ||
      this == OverrideOperationState.downloading;

  // 是否正在批量更新
  bool get isBatchUpdating => this == OverrideOperationState.batchUpdating;

  // 是否正在下载
  bool get isDownloading => this == OverrideOperationState.downloading;

  // 是否为忙碌状态（非空闲）
  bool get isBusy => !isIdle;
}

// 覆写状态变化事件
class OverrideStateChangeEvent {
  final OverrideOperationState previousOperationState;
  final OverrideOperationState currentOperationState;
  final OverrideErrorState previousErrorState;
  final OverrideErrorState currentErrorState;
  final DateTime timestamp;
  final String? reason;

  const OverrideStateChangeEvent({
    required this.previousOperationState,
    required this.currentOperationState,
    required this.previousErrorState,
    required this.currentErrorState,
    required this.timestamp,
    this.reason,
  });

  @override
  String toString() {
    final operationChanged = previousOperationState != currentOperationState;
    final errorChanged = previousErrorState != currentErrorState;

    final parts = <String>[];
    if (operationChanged) {
      parts.add(
        '操作状态：${previousOperationState.name} -> ${currentOperationState.name}',
      );
    }
    if (errorChanged) {
      parts.add('错误状态：${previousErrorState.name} -> ${currentErrorState.name}');
    }

    final changes = parts.join('，');
    return '覆写状态变化事件($changes${reason != null ? '，原因：$reason' : ''})';
  }
}

// 覆写更新进度信息
class OverrideUpdateProgress {
  final int current;
  final int total;
  final String? currentItemName;

  const OverrideUpdateProgress({
    required this.current,
    required this.total,
    this.currentItemName,
  });

  // 是否正在更新
  bool get isUpdating => total > 0 && current < total;

  // 更新进度百分比（0-100）
  double get percentage => total > 0 ? (current / total * 100) : 0.0;

  // 是否已完成
  bool get isCompleted => total > 0 && current >= total;

  @override
  String toString() {
    return 'OverrideUpdateProgress($current/$total${currentItemName != null ? '，当前：$currentItemName' : ''})';
  }
}

// 覆写状态管理器
class OverrideStateManager extends ChangeNotifier {
  static final OverrideStateManager _instance =
      OverrideStateManager._internal();
  static OverrideStateManager get instance => _instance;
  OverrideStateManager._internal();

  // 当前状态
  OverrideOperationState _operationState = OverrideOperationState.idle;
  OverrideErrorState _errorState = OverrideErrorState.none;
  String? _errorMessage;
  OverrideUpdateProgress _updateProgress = const OverrideUpdateProgress(
    current: 0,
    total: 0,
  );

  // 单个覆写更新状态追踪
  final Set<String> _updatingOverrideIds = <String>{};

  // 状态变化事件流
  final StreamController<OverrideStateChangeEvent> _stateChangeController =
      StreamController<OverrideStateChangeEvent>.broadcast();

  /// 当前操作状态
  OverrideOperationState get operationState => _operationState;

  /// 当前错误状态
  OverrideErrorState get errorState => _errorState;

  /// 错误消息
  String? get errorMessage => _errorMessage;

  /// 更新进度
  OverrideUpdateProgress get updateProgress => _updateProgress;

  // 状态变化事件流
  Stream<OverrideStateChangeEvent> get stateChangeStream =>
      _stateChangeController.stream;

  // 便捷方法 - 是否为空闲状态
  bool get isIdle => _operationState.isIdle;

  // 便捷方法 - 是否正在加载
  bool get isLoading => _operationState.isLoading;

  // 便捷方法 - 是否正在更新
  bool get isUpdating => _operationState.isUpdating;

  // 便捷方法 - 是否正在批量更新
  bool get isBatchUpdating => _operationState.isBatchUpdating;

  // 便捷方法 - 是否正在下载
  bool get isDownloading => _operationState.isDownloading;

  // 便捷方法 - 是否为忙碌状态
  bool get isBusy => _operationState.isBusy;

  // 便捷方法 - 是否有错误
  bool get hasError => _errorState != OverrideErrorState.none;

  // 检查指定覆写是否正在更新
  bool isOverrideUpdating(String overrideId) {
    return _updatingOverrideIds.contains(overrideId);
  }

  // 获取正在更新的覆写ID列表
  Set<String> get updatingOverrideIds => Set.unmodifiable(_updatingOverrideIds);

  // 更新状态
  void _updateState({
    OverrideOperationState? operationState,
    OverrideErrorState? errorState,
    String? errorMessage,
    OverrideUpdateProgress? updateProgress,
    String? reason,
  }) {
    final previousOperationState = _operationState;
    final previousErrorState = _errorState;

    // 更新状态
    if (operationState != null) _operationState = operationState;
    if (errorState != null) _errorState = errorState;
    if (errorMessage != null) _errorMessage = errorMessage;
    if (updateProgress != null) _updateProgress = updateProgress;

    // 清除错误消息（如果错误状态变为none）
    if (_errorState == OverrideErrorState.none) {
      _errorMessage = null;
    }

    // 发送状态变化事件
    if (previousOperationState != _operationState ||
        previousErrorState != _errorState) {
      final event = OverrideStateChangeEvent(
        previousOperationState: previousOperationState,
        currentOperationState: _operationState,
        previousErrorState: previousErrorState,
        currentErrorState: _errorState,
        timestamp: DateTime.now(),
        reason: reason,
      );

      _stateChangeController.add(event);

      // 注意：状态变化已由 StateHub 统一处理和打印，这里不再重复打印
      // 避免与 StateHub 的日志重复
    }

    notifyListeners();
  }

  /// 设置为空闲状态
  void setIdle({String? reason}) {
    _updateState(
      operationState: OverrideOperationState.idle,
      errorState: OverrideErrorState.none,
      updateProgress: const OverrideUpdateProgress(current: 0, total: 0),
      reason: reason ?? '设置为空闲状态',
    );
  }

  /// 设置为加载状态
  void setLoading({String? reason}) {
    _updateState(
      operationState: OverrideOperationState.loading,
      errorState: OverrideErrorState.none,
      reason: reason ?? '开始加载',
    );
  }

  /// 设置为更新状态
  void setUpdating({String? reason}) {
    _updateState(
      operationState: OverrideOperationState.updating,
      errorState: OverrideErrorState.none,
      reason: reason ?? '开始更新',
    );
  }

  /// 设置为批量更新状态
  void setBatchUpdating({required int total, String? reason}) {
    _updateState(
      operationState: OverrideOperationState.batchUpdating,
      errorState: OverrideErrorState.none,
      updateProgress: OverrideUpdateProgress(current: 0, total: total),
      reason: reason ?? '开始批量更新',
    );
  }

  /// 设置为下载状态
  void setDownloading({String? reason}) {
    _updateState(
      operationState: OverrideOperationState.downloading,
      errorState: OverrideErrorState.none,
      reason: reason ?? '开始下载',
    );
  }

  /// 更新批量更新进度
  void updateBatchProgress({
    required int current,
    String? currentItemName,
    String? reason,
  }) {
    if (!isBatchUpdating) return;

    _updateState(
      updateProgress: OverrideUpdateProgress(
        current: current,
        total: _updateProgress.total,
        currentItemName: currentItemName,
      ),
      reason: reason,
    );
  }

  /// 设置错误状态
  void setError({
    required OverrideErrorState errorState,
    String? errorMessage,
    String? reason,
  }) {
    _updateState(
      operationState: OverrideOperationState.idle,
      errorState: errorState,
      errorMessage: errorMessage,
      reason: reason ?? '发生错误',
    );
  }

  // 添加正在更新的覆写ID
  void addUpdatingOverride(String overrideId, {String? reason}) {
    if (_updatingOverrideIds.add(overrideId)) {
      Logger.debug(
        '覆写状态：添加更新中的覆写 $overrideId${reason != null ? '，原因：$reason' : ''}',
      );
      notifyListeners();
    }
  }

  // 移除正在更新的覆写ID
  void removeUpdatingOverride(String overrideId, {String? reason}) {
    if (_updatingOverrideIds.remove(overrideId)) {
      Logger.debug(
        '覆写状态：移除更新中的覆写 $overrideId${reason != null ? '，原因：$reason' : ''}',
      );
      notifyListeners();
    }
  }

  // 清除所有正在更新的覆写ID
  void clearUpdatingOverrides({String? reason}) {
    if (_updatingOverrideIds.isNotEmpty) {
      _updatingOverrideIds.clear();
      Logger.debug('覆写状态：清除所有更新中的覆写${reason != null ? '，原因：$reason' : ''}');
      notifyListeners();
    }
  }

  // 重置状态管理器
  void reset({String? reason}) {
    _updatingOverrideIds.clear();
    _updateState(
      operationState: OverrideOperationState.idle,
      errorState: OverrideErrorState.none,
      updateProgress: const OverrideUpdateProgress(current: 0, total: 0),
      reason: reason ?? '重置状态管理器',
    );
  }

  @override
  void dispose() {
    _stateChangeController.close();
    super.dispose();
  }
}
