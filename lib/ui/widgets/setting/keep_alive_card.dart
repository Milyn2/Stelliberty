import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stelliberty/i18n/i18n.dart';
import 'package:stelliberty/clash/providers/clash_provider.dart';
import 'package:stelliberty/clash/storage/preferences.dart';
import 'package:stelliberty/ui/common/modern_feature_card.dart';
import 'package:stelliberty/ui/common/modern_text_field.dart';
import 'package:stelliberty/ui/common/modern_switch.dart';

// TCP 保持活动配置卡片
class KeepAliveCard extends StatefulWidget {
  const KeepAliveCard({super.key});

  @override
  State<KeepAliveCard> createState() => _KeepAliveCardState();
}

class _KeepAliveCardState extends State<KeepAliveCard> {
  late bool _keepAliveEnabled;
  late final TextEditingController _keepAliveIntervalController;

  @override
  void initState() {
    super.initState();
    _keepAliveEnabled = ClashPreferences.instance.getKeepAliveEnabled();
    _keepAliveIntervalController = TextEditingController(
      text: ClashPreferences.instance.getKeepAliveInterval().toString(),
    );
  }

  @override
  void dispose() {
    _keepAliveIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernFeatureCard(
      isSelected: false,
      onTap: () {},
      enableHover: false,
      enableTap: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 开关行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧图标和标题
                Row(
                  children: [
                    const Icon(Icons.timer_outlined),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.translate.clashFeatures.keepAlive.title,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          context.translate.clashFeatures.keepAlive.subtitle,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                // 右侧开关
                ModernSwitch(
                  value: _keepAliveEnabled,
                  onChanged: (value) async {
                    setState(() => _keepAliveEnabled = value);
                    final clashProvider = Provider.of<ClashProvider>(
                      context,
                      listen: false,
                    );
                    await ClashPreferences.instance.setKeepAliveEnabled(value);
                    if (!mounted) return;
                    clashProvider.configService.setKeepAlive(_keepAliveEnabled);
                  },
                ),
              ],
            ),

            // 间隔输入框（固定展开）
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.translate.clashFeatures.keepAlive.intervalLabel,
                  style: theme.textTheme.titleSmall,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: ModernTextField(
                        controller: _keepAliveIntervalController,
                        keyboardType: TextInputType.number,
                        hintText: '30',
                        height: 36,
                        onChanged: (value) {
                          final interval = int.tryParse(value);
                          if (interval != null && interval > 0) {
                            ClashPreferences.instance.setKeepAliveInterval(
                              interval,
                            );
                            final clashProvider = Provider.of<ClashProvider>(
                              context,
                              listen: false,
                            );
                            clashProvider.configService.setKeepAlive(
                              _keepAliveEnabled,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.translate.clashFeatures.keepAlive.intervalUnit,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
