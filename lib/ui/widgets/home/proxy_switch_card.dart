import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stelliberty/clash/manager/manager.dart';
import 'package:stelliberty/clash/providers/clash_provider.dart';
import 'package:stelliberty/clash/core/service_state.dart';
import 'package:stelliberty/ui/common/modern_switch.dart';
import 'package:stelliberty/ui/widgets/home/base_card.dart';
import 'package:stelliberty/i18n/i18n.dart';

/// 代理控制卡片
///
/// 提供代理开关、TUN 模式切换功能
class ProxySwitchCard extends StatelessWidget {
  const ProxySwitchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final clashProvider = context.watch<ClashProvider>();
    final clashManager = context.watch<ClashManager>();
    final serviceStateManager = context.watch<ServiceStateManager>();
    final isRunning = clashProvider.isRunning;
    final isProxyEnabled = clashManager.isSystemProxyEnabled;
    final isLoading = clashProvider.isLoading;
    final tunEnabled = clashProvider.tunEnabled;
    final isServiceInstalled = serviceStateManager.isInstalled;

    return BaseCard(
      icon: Icons.shield_outlined,
      title: context.translate.proxy.proxyControl,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isProxyEnabled ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isProxyEnabled
                ? context.translate.proxy.running
                : context.translate.proxy.stopped,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isProxyEnabled ? Colors.green : Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!Platform.isAndroid) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.translate.proxy.tunMode,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                    ),
                  ),
                  ModernSwitch(
                    value: tunEnabled,
                    onChanged: (isLoading || !isServiceInstalled)
                        ? null
                        : (value) async {
                            await clashProvider.setTunMode(value);
                          },
                  ),
                ],
              ),
            ),
            if (!isServiceInstalled)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  context.translate.proxy.tunRequiresService,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],

          ElevatedButton(
            onPressed: (isLoading || !isRunning)
                ? null
                : () async {
                    try {
                      if (isProxyEnabled) {
                        await clashProvider.disableSystemProxy();
                      } else {
                        await clashProvider.enableSystemProxy();
                      }
                    } catch (e) {
                      // 错误已经在 Provider 中记录
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isProxyEnabled
                  ? Colors.red.shade400
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              isProxyEnabled
                  ? context.translate.proxy.stopProxy
                  : context.translate.proxy.startProxy,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
