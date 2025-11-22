import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stelliberty/clash/data/clash_model.dart';
import 'package:stelliberty/utils/logger.dart';
import 'package:stelliberty/clash/config/clash_defaults.dart';
import 'package:stelliberty/clash/network/api_client.dart';

// 延迟测试工具类
class DelayTester {
  // 默认测试URL
  static String get defaultTestUrl => ClashDefaults.defaultTestUrl;

  // 超时时间（毫秒）
  static int get timeoutMs => ClashDefaults.proxyDelayTestTimeout;

  // Clash API 客户端（用于统一延迟测试）
  static ClashApiClient? _apiClient;

  // 设置 Clash API 客户端（在 Clash 启动时调用）
  static void setApiClient(ClashApiClient? client) {
    _apiClient = client;
    if (client != null) {
      Logger.info('Clash API 客户端已设置，统一延迟测试已启用');
    } else {
      Logger.warning('Clash API 客户端已移除，延迟测试不可用');
    }
  }

  // 检查延迟测试是否可用
  static bool get isAvailable => _apiClient != null;

  // 测试单个代理节点的延迟
  //
  // [proxyNode] 要测试的代理节点
  // [testUrl] 测试URL，默认使用Google的204页面
  // 返回延迟毫秒数，-1表示测试失败
  static Future<int> testProxyDelay(
    ProxyNode proxyNode, {
    String? testUrl,
  }) async {
    // 检查节点名称是否有效
    if (proxyNode.name.isEmpty) {
      Logger.warning('无效的代理节点：节点名称为空');
      return -1;
    }

    if (_apiClient == null) {
      Logger.error('Clash API 客户端未设置，无法进行延迟测试。请先启动 Clash。');
      return -1;
    }

    final url = testUrl ?? defaultTestUrl;
    Logger.info('开始测试代理 ${proxyNode.name} 的延迟（统一延迟测试）：$url');

    try {
      final delay = await _apiClient!.testProxyDelay(
        proxyNode.name,
        testUrl: url,
        timeoutMs: timeoutMs,
      );

      if (delay > 0) {
        Logger.info('延迟测试成功：${proxyNode.name} - ${delay}ms');
      } else {
        Logger.warning('延迟测试失败：${proxyNode.name} - 超时或协议错误');
      }

      return delay;
    } catch (e) {
      Logger.error('测试代理 ${proxyNode.name} 延迟失败：$e');
      return -1;
    }
  }

  // 批量测试多个代理节点的延迟
  //
  // [proxyNodes] 要测试的代理节点列表
  // [testUrl] 测试URL
  // [concurrency] 并发数，默认为5
  // [batchSize] 每批处理的数量，默认为100
  // 返回 Map[String, int]，key是节点名称，value是延迟毫秒数
  static Future<Map<String, int>> testMultipleProxyDelays(
    List<ProxyNode> proxyNodes, {
    String? testUrl,
    int concurrency = 5,
    int batchSize = 100,
  }) async {
    if (_apiClient == null) {
      Logger.error('Clash API 客户端未设置，无法进行批量延迟测试。请先启动 Clash。');
      return {};
    }

    final results = <String, int>{};
    final url = testUrl ?? defaultTestUrl;

    Logger.info('开始批量测试 ${proxyNodes.length} 个代理节点的延迟（统一延迟测试）');

    // 将节点列表分成更大的批次
    final batches = <List<ProxyNode>>[];
    for (int i = 0; i < proxyNodes.length; i += batchSize) {
      batches.add(proxyNodes.skip(i).take(batchSize).toList());
    }

    // 处理每个大批次
    for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];
      final batchResults = <String, int>{};

      // 在每个大批次内，使用并发限制进行测试
      for (int i = 0; i < batch.length; i += concurrency) {
        final concurrentNodes = batch.skip(i).take(concurrency).toList();

        // 并发测试一组节点
        final futures = concurrentNodes.map((node) async {
          final delay = await testProxyDelay(node, testUrl: url);
          return MapEntry(node.name, delay);
        });

        final concurrentResults = await Future.wait(futures);
        for (final entry in concurrentResults) {
          batchResults[entry.key] = entry.value;
        }
      }

      results.addAll(batchResults);
      Logger.info(
        '已完成批次 ${batchIndex + 1}/${batches.length}，共 ${results.length}/${proxyNodes.length} 个节点',
      );
    }

    Logger.info(
      '批量延迟测试完成，成功测试: ${results.values.where((d) => d > 0).length}/${proxyNodes.length}',
    );
    return results;
  }

  // 测试URL的可达性（不通过代理）
  static Future<int> testDirectConnection(String testUrl) async {
    final stopwatch = Stopwatch()..start();

    try {
      final client = HttpClient();
      client.connectionTimeout = Duration(milliseconds: timeoutMs);

      final request = await client.getUrl(Uri.parse(testUrl));
      final response = await request.close().timeout(
        Duration(milliseconds: timeoutMs),
      );

      await response.drain();
      client.close();

      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      Logger.error('直连测试失败：$e');
      return -1;
    }
  }

  // 统一延迟测试方法
  // 这个方法提供了更统一的接口，用于处理所有类型的延迟测试
  //
  // [nodeName] 节点名称
  // [proxyNode] 代理节点对象
  // [testUrl] 测试URL
  // [onStart] 测试开始的回调
  // [onComplete] 测试完成的回调
  static Future<int> unifiedDelayTest({
    required String nodeName,
    required ProxyNode proxyNode,
    String? testUrl,
    VoidCallback? onStart,
    Function(int delay)? onComplete,
  }) async {
    // 触发开始回调（设置延迟为0表示正在测试）
    onStart?.call();

    // 执行实际的延迟测试
    final delay = await testProxyDelay(proxyNode, testUrl: testUrl);

    // 触发完成回调
    onComplete?.call(delay);

    return delay;
  }

  // 批量统一延迟测试
  // 提供更好的状态管理和回调机制
  static Future<void> batchUnifiedDelayTest({
    required List<ProxyNode> proxyNodes,
    String? testUrl,
    Function(String nodeName)? onNodeStart,
    Function(String nodeName, int delay)? onNodeComplete,
    VoidCallback? onBatchComplete,
  }) async {
    if (_apiClient == null) {
      Logger.error('Clash API 客户端未设置，无法进行批量延迟测试。请先启动 Clash。');
      onBatchComplete?.call();
      return;
    }

    final url = testUrl ?? defaultTestUrl;
    final batchSize = 100; // 固定批量大小
    final concurrency = 5; // 固定并发数

    Logger.info('开始批量统一延迟测试');

    // 将节点分批
    final batches = <List<ProxyNode>>[];
    for (int i = 0; i < proxyNodes.length; i += batchSize) {
      batches.add(proxyNodes.skip(i).take(batchSize).toList());
    }

    // 处理每批
    for (final batch in batches) {
      final futures = <Future>[];

      for (int i = 0; i < batch.length; i += concurrency) {
        final concurrentNodes = batch.skip(i).take(concurrency).toList();

        for (final node in concurrentNodes) {
          futures.add(
            Future(() async {
              // 触发开始回调
              onNodeStart?.call(node.name);

              // 执行测试
              final delay = await testProxyDelay(node, testUrl: url);

              // 触发完成回调
              onNodeComplete?.call(node.name, delay);
            }),
          );
        }

        // 等待当前并发组完成
        await Future.wait(futures);
        futures.clear();
      }
    }

    // 所有批次完成
    onBatchComplete?.call();
  }
}
