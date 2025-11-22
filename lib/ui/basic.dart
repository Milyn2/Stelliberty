import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stelliberty/theme/dynamic_theme.dart';
import 'package:stelliberty/providers/window_effect_provider.dart';
import 'package:stelliberty/ui/layout/main_layout.dart';
import 'package:stelliberty/ui/layout/title_bar.dart';
import 'package:stelliberty/clash/manager/manager.dart';
import 'package:stelliberty/utils/logger.dart';

// 应用的根 Widget，负责提供动态主题和生命周期管理。
class BasicLayout extends StatefulWidget {
  const BasicLayout({super.key});

  @override
  State<BasicLayout> createState() => _BasicLayoutState();
}

class _BasicLayoutState extends State<BasicLayout> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // 注册应用生命周期监听器
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 移除应用生命周期监听器
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 当应用即将退出时，清理 Clash 进程
    if (state == AppLifecycleState.detached) {
      Logger.info('应用即将退出，正在清理 Clash 进程...');
      _cleanupOnExit();
    }
  }

  // 应用退出时的清理工作
  void _cleanupOnExit() {
    try {
      // 同步停止 Clash（先禁用代理，再停止核心）
      ClashManager.instance.disableSystemProxy();
      ClashManager.instance.stopCore();
      Logger.info('Clash 进程清理完成');
    } catch (e) {
      Logger.error('清理 Clash 进程时出错：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const DynamicThemeApp(home: AppContent());
  }
}

// 应用的主要内容区，负责构建应用外壳（Scaffold）并响应窗口效果。
class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WindowEffectProvider>(
      builder: (context, windowEffectProvider, child) {
        return Scaffold(
          // 根据窗口效果提供者（WindowEffectProvider）的状态，动态设置背景色
          backgroundColor: windowEffectProvider.windowEffectBackgroundColor,
          body: const _AppBody(), // 将核心布局提取到独立的 Widget
        );
      },
    );
  }
}

// 应用的核心布局，包含标题栏和主页。
class _AppBody extends StatelessWidget {
  const _AppBody();

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 只在桌面平台显示自定义标题栏
        if (!_isMobile) const WindowTitleBar(),
        const Expanded(child: HomePage()),
      ],
    );
  }
}
