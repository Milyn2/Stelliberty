import 'dart:io';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:stelliberty/utils/logger.dart';

// 确保应用单实例运行
Future<void> ensureSingleInstance() async {
  // 关闭调试模式的单例检测跳过行为
  FlutterSingleInstance.debugMode = false;

  // 检测是否已有实例
  if (!await FlutterSingleInstance().isFirstInstance()) {
    Logger.info("检测到新实例，禁止启动");
    final err = await FlutterSingleInstance().focus();
    if (err != null) {
      Logger.error("聚焦运行实例时出错：$err");
    }
    exit(0);
  }
}
