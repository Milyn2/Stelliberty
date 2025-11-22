import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stelliberty/providers/content_provider.dart';
import 'package:stelliberty/ui/widgets/content_body.dart';
import 'package:stelliberty/ui/pages/settings/appearance_settings_page.dart';
import 'package:stelliberty/ui/pages/settings/language_settings_page.dart';
import 'package:stelliberty/ui/pages/settings/settings_overview_page.dart';
import 'package:stelliberty/ui/pages/settings/clash_features_page.dart';
import 'package:stelliberty/ui/pages/settings/clash/network_settings_page.dart';
import 'package:stelliberty/ui/pages/settings/clash/port_control_page.dart';
import 'package:stelliberty/ui/pages/settings/clash/system_integration_page.dart';
import 'package:stelliberty/ui/pages/settings/clash/dns_config_page.dart';
import 'package:stelliberty/ui/pages/settings/clash/performance_page.dart';
import 'package:stelliberty/ui/pages/settings/clash/logs_debug_page.dart';
import 'package:stelliberty/ui/pages/proxy_page.dart';
import 'package:stelliberty/ui/pages/subscription_page.dart';
import 'package:stelliberty/ui/pages/override_page.dart';
import 'package:stelliberty/ui/pages/home_page.dart';
import 'package:stelliberty/ui/pages/connection_page.dart';
import 'package:stelliberty/ui/pages/log_page.dart';

import 'sidebar.dart';

// 主页面，包含固定的侧边栏和动态的内容区域
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        HomeSidebar(),
        VerticalDivider(width: 2, thickness: 2),
        Expanded(child: _DynamicContentArea()),
      ],
    );
  }
}

// 根据 ContentProvider 的状态动态构建右侧内容区域
class _DynamicContentArea extends StatelessWidget {
  const _DynamicContentArea();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, provider, child) {
        return ContentBody(
          child: Align(
            alignment: Alignment.topLeft, // 强制内容靠左上对齐
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(provider.currentView),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(ContentView view) {
    switch (view) {
      case ContentView.home:
        return const HomePageContent();
      case ContentView.proxy:
        return const ProxyPage();
      case ContentView.connections:
        return const ConnectionPageContent();
      case ContentView.subscriptions:
        return const SubscriptionPage();
      case ContentView.overrides:
        return const OverridePage();
      case ContentView.logs:
        return const LogPage();
      case ContentView.settingsOverview:
        return const SettingsOverviewPage();
      case ContentView.settingsAppearance:
        return const AppearanceSettingsPage();
      case ContentView.settingsBehavior:
        return const BehaviorSettingsPage();
      case ContentView.settingsLanguage:
        return const LanguageSettingsPage();
      case ContentView.settingsClashFeatures:
        return const ClashFeaturesPage();
      case ContentView.settingsClashNetworkSettings:
        return const NetworkSettingsPage();
      case ContentView.settingsClashPortControl:
        return const PortControlPage();
      case ContentView.settingsClashSystemIntegration:
        return const SystemIntegrationPage();
      case ContentView.settingsClashDnsConfig:
        return const DnsConfigPage();
      case ContentView.settingsClashPerformance:
        return const PerformancePage();
      case ContentView.settingsClashLogsDebug:
        return const LogsDebugPage();
    }
  }
}
