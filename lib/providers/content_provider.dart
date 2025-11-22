import 'package:flutter/material.dart';

// 定义右侧内容区域可显示的视图类型
enum ContentView {
  // 主页相关视图
  home,
  proxy,
  subscriptions,
  overrides,
  connections,
  logs,

  // 设置相关视图
  settingsOverview,
  settingsAppearance,
  settingsLanguage,
  settingsClashFeatures,
  settingsBehavior,

  // Clash 特性子页面（命名以 settings 开头保持侧边栏选中状态）
  settingsClashNetworkSettings,
  settingsClashPortControl,
  settingsClashSystemIntegration,
  settingsClashDnsConfig,
  settingsClashPerformance,
  settingsClashLogsDebug,
}

// 管理右侧内容区域的视图切换
class ContentProvider extends ChangeNotifier {
  ContentView _currentView = ContentView.home;

  // 获取当前视图类型
  ContentView get currentView => _currentView;

  // 切换到指定视图，变化时通知监听器
  void switchView(ContentView newView) {
    if (_currentView != newView) {
      _currentView = newView;
      notifyListeners();
    }
  }
}
