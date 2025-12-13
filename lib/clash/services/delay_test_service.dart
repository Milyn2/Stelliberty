import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stelliberty/clash/data/clash_model.dart';
import 'package:stelliberty/clash/config/clash_defaults.dart';
import 'package:stelliberty/clash/utils/delay_tester.dart';
import 'package:stelliberty/utils/logger.dart';

// 延迟测试服务
class DelayTestService {
  // 测试代理延迟（支持代理组）
  // 使用 Clash API 进行统一延迟测试（需要 Clash 正在运行）
  // 注意：此方法不修改传入的 proxyNodes Map，仅返回延迟值
  //
  // 重要：不递归解析代理组，直接测试传入的节点名称
  // 如果是代理组，Clash API 会测试该代理组当前选中的节点
  static Future<int> testProxyDelay(
    String proxyName,
    Map<String, ProxyNode> proxyNodes,
    List<ProxyGroup> allProxyGroups,
    Map<String, String> selectedMap, {
    String? testUrl,
  }) async {
    final node = proxyNodes[proxyName];
    if (node == null) {
      Logger.warning('代理节点不存在：$proxyName');
      return -1;
    }

    // 关键：检查 DelayTester 是否可用（即 Clash API 客户端是否已设置）
    if (!DelayTester.isAvailable) {
      Logger.error('Clash 未运行或 API 未就绪，无法进行延迟测试');
      return -1;
    }

    final delay = await DelayTester.testProxyDelay(node, testUrl: testUrl);

    return delay;
  }

  // 批量测试代理组中所有节点的延迟
  // 使用滑动窗口并发策略，保持固定并发数，一个完成立即启动下一个
  // 每个节点测试完成后立即回调，实现真正的流式更新
  static Future<Map<String, int>> testGroupDelays(
    String groupName,
    Map<String, ProxyNode> proxyNodes,
    List<ProxyGroup> allProxyGroups,
    Map<String, String> selectedMap, {
    String? testUrl,
    Function(String nodeName)? onNodeStart,
    Function(String nodeName, int delay)? onNodeComplete,
  }) async {
    final group = allProxyGroups.firstWhere(
      (g) => g.name == groupName,
      orElse: () => throw Exception('Group not found: $groupName'),
    );

    // 获取所有要测试的代理名称（包括代理组和实际节点）
    final proxyNames = group.all.where((proxyName) {
      final node = proxyNodes[proxyName];
      return node != null; // 只要存在就可以测试
    }).toList();

    if (proxyNames.isEmpty) {
      Logger.warning('代理组 $groupName 中没有可测试的节点');
      return {};
    }

    // 使用动态并发数（基于 CPU 核心数）
    final concurrency = ClashDefaults.dynamicDelayTestConcurrency;
    Logger.info(
      '开始测试代理组 $groupName 中的 ${proxyNames.length} 个项目（滑动窗口并发数：$concurrency）',
    );

    // 存储所有节点的延迟结果
    final delayResults = <String, int>{};
    int successCount = 0;
    int completedCount = 0;

    // 滑动窗口并发：使用 Completer 跟踪任务完成状态
    final inProgress = <Completer<void>>[];
    int nextIndex = 0;

    // 启动初始批次的任务（最多 concurrency 个）
    while (nextIndex < proxyNames.length && inProgress.length < concurrency) {
      final proxyName = proxyNames[nextIndex];
      nextIndex++;

      final completer = Completer<void>();
      _testSingleNode(
        proxyName,
        proxyNodes,
        allProxyGroups,
        selectedMap,
        testUrl,
        onNodeStart,
        onNodeComplete,
        delayResults,
        () => successCount++,
        () => completedCount++,
        proxyNames.length,
      ).then((_) => completer.complete()).catchError(completer.completeError);

      inProgress.add(completer);
    }

    // 持续监控并启动新任务（滑动窗口核心逻辑）
    while (inProgress.isNotEmpty) {
      // 等待任意一个任务完成（非阻塞等待，保持窗口满载）
      await Future.any(inProgress.map((c) => c.future));

      // 移除所有已完成的任务
      inProgress.removeWhere((completer) => completer.isCompleted);

      // 如果还有待测试的节点，启动新任务补充窗口
      while (nextIndex < proxyNames.length && inProgress.length < concurrency) {
        final proxyName = proxyNames[nextIndex];
        nextIndex++;

        final completer = Completer<void>();
        _testSingleNode(
          proxyName,
          proxyNodes,
          allProxyGroups,
          selectedMap,
          testUrl,
          onNodeStart,
          onNodeComplete,
          delayResults,
          () => successCount++,
          () => completedCount++,
          proxyNames.length,
        ).then((_) => completer.complete()).catchError(completer.completeError);

        inProgress.add(completer);
      }
    }

    Logger.info('延迟测试完成，成功：$successCount/${proxyNames.length}');

    return delayResults;
  }

  // 测试单个节点（内部方法）
  static Future<void> _testSingleNode(
    String proxyName,
    Map<String, ProxyNode> proxyNodes,
    List<ProxyGroup> allProxyGroups,
    Map<String, String> selectedMap,
    String? testUrl,
    Function(String nodeName)? onNodeStart,
    Function(String nodeName, int delay)? onNodeComplete,
    Map<String, int> delayResults,
    VoidCallback onSuccess,
    VoidCallback onComplete,
    int totalCount,
  ) async {
    // 通知节点开始测试
    onNodeStart?.call(proxyName);

    // 执行测试
    final delay = await testProxyDelay(
      proxyName,
      proxyNodes,
      allProxyGroups,
      selectedMap,
      testUrl: testUrl,
    );

    // 保存延迟结果
    delayResults[proxyName] = delay;

    // 更新计数
    if (delay > 0) {
      onSuccess();
    }
    onComplete();

    // 通知节点测试完成
    onNodeComplete?.call(proxyName, delay);
  }
}
