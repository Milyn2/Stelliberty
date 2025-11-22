import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stelliberty/i18n/i18n.dart';
import 'package:stelliberty/clash/providers/clash_provider.dart';
import 'package:stelliberty/clash/storage/preferences.dart';
import 'package:stelliberty/clash/config/clash_defaults.dart';
import 'package:stelliberty/ui/common/modern_feature_card.dart';
import 'package:stelliberty/ui/common/modern_text_field.dart';

// 端口设置配置卡片
class PortSettingsCard extends StatefulWidget {
  const PortSettingsCard({super.key});

  @override
  State<PortSettingsCard> createState() => _PortSettingsCardState();
}

class _PortSettingsCardState extends State<PortSettingsCard> {
  late final TextEditingController _mixedPortController;
  late final TextEditingController _socksPortController;
  late final TextEditingController _httpPortController;
  late final ClashProvider _clashProvider;

  // 错误状态
  String? _mixedPortError;
  String? _socksPortError;
  String? _httpPortError;

  @override
  void initState() {
    super.initState();
    _clashProvider = Provider.of<ClashProvider>(context, listen: false);
    _mixedPortController = TextEditingController(
      text: ClashPreferences.instance.getMixedPort().toString(),
    );
    _socksPortController = TextEditingController(
      text: ClashPreferences.instance.getSocksPort()?.toString() ?? '',
    );
    _httpPortController = TextEditingController(
      text: ClashPreferences.instance.getHttpPort()?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _mixedPortController.dispose();
    _socksPortController.dispose();
    _httpPortController.dispose();
    super.dispose();
  }

  // 验证端口号
  // [value] 端口字符串
  // [allowEmpty] 是否允许为空（用于可选端口）
  String? _validatePort(String value, {bool allowEmpty = false}) {
    if (value.isEmpty) {
      return allowEmpty ? null : context.translate.portSettings.portError;
    }

    final port = int.tryParse(value);
    if (port == null) {
      return context.translate.portSettings.portInvalid;
    }

    if (port < 1 || port > 65535) {
      return context.translate.portSettings.portRange;
    }

    return null;
  }

  // 处理混合端口提交
  void _handleMixedPortSubmit(String value) {
    final error = _validatePort(value);
    if (error != null) {
      setState(() {
        _mixedPortError = error;
        // 恢复有效值
        _mixedPortController.text = ClashPreferences.instance
            .getMixedPort()
            .toString();
      });
      return;
    }

    setState(() => _mixedPortError = null);
    final port = int.parse(value);
    _clashProvider.configService.setMixedPort(port);
  }

  // 处理 SOCKS 端口提交
  void _handleSocksPortSubmit(String value) {
    if (value.isEmpty) {
      setState(() => _socksPortError = null);
      _clashProvider.configService.setSocksPort(null);
      return;
    }

    final error = _validatePort(value, allowEmpty: true);
    if (error != null) {
      setState(() {
        _socksPortError = error;
        // 恢复有效值
        _socksPortController.text =
            ClashPreferences.instance.getSocksPort()?.toString() ?? '';
      });
      return;
    }

    setState(() => _socksPortError = null);
    final port = int.parse(value);
    _clashProvider.configService.setSocksPort(port);
  }

  // 处理 HTTP 端口提交
  void _handleHttpPortSubmit(String value) {
    if (value.isEmpty) {
      setState(() => _httpPortError = null);
      _clashProvider.configService.setHttpPort(null);
      return;
    }

    final error = _validatePort(value, allowEmpty: true);
    if (error != null) {
      setState(() {
        _httpPortError = error;
        // 恢复有效值
        _httpPortController.text =
            ClashPreferences.instance.getHttpPort()?.toString() ?? '';
      });
      return;
    }

    setState(() => _httpPortError = null);
    final port = int.parse(value);
    _clashProvider.configService.setHttpPort(port);
  }

  @override
  Widget build(BuildContext context) {
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
            // 标题区域
            Row(
              children: [
                const Icon(Icons.settings_ethernet_outlined),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate.clashFeatures.portSettings.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      context.translate.clashFeatures.portSettings.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 端口输入区域
            ModernTextField(
              controller: _mixedPortController,
              keyboardType: TextInputType.number,
              labelText: context.translate.clashFeatures.portSettings.mixedPort,
              hintText: ClashDefaults.mixedPort.toString(),
              errorText: _mixedPortError,
              onSubmitted: _handleMixedPortSubmit,
            ),
            const SizedBox(height: 12),
            ModernTextField(
              controller: _socksPortController,
              keyboardType: TextInputType.number,
              labelText: context.translate.clashFeatures.portSettings.socksPort,
              hintText:
                  context.translate.clashFeatures.portSettings.emptyToDisable,
              errorText: _socksPortError,
              onSubmitted: _handleSocksPortSubmit,
            ),
            const SizedBox(height: 12),
            ModernTextField(
              controller: _httpPortController,
              keyboardType: TextInputType.number,
              labelText: context.translate.clashFeatures.portSettings.httpPort,
              hintText:
                  context.translate.clashFeatures.portSettings.emptyToDisable,
              errorText: _httpPortError,
              onSubmitted: _handleHttpPortSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
