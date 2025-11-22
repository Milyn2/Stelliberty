import 'package:flutter/material.dart';
import 'package:stelliberty/i18n/i18n.dart';
import 'package:stelliberty/clash/storage/preferences.dart';
import 'package:stelliberty/ui/common/modern_feature_card.dart';
import 'package:stelliberty/ui/common/modern_dropdown_menu.dart';
import 'package:stelliberty/ui/common/modern_dropdown_button.dart';

// User-Agent 配置卡片
class UserAgentCard extends StatefulWidget {
  const UserAgentCard({super.key});

  @override
  State<UserAgentCard> createState() => _UserAgentCardState();
}

class _UserAgentCardState extends State<UserAgentCard> {
  late String _selectedUserAgent;
  bool _isHoveringOnMenu = false;

  // 可选的 User-Agent 列表
  static const List<Map<String, String>> _userAgentOptions = [
    {'value': 'clash', 'label': 'clash'},
    {'value': 'clash-verge', 'label': 'clash-verge'},
    {'value': 'clash.meta', 'label': 'clash.meta'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedUserAgent = ClashPreferences.instance.getUserAgent();
  }

  Future<void> _onUserAgentChanged(String userAgent) async {
    setState(() {
      _selectedUserAgent = userAgent;
    });
    await ClashPreferences.instance.setUserAgent(userAgent);
  }

  @override
  Widget build(BuildContext context) {
    return ModernFeatureCard(
      isSelected: false,
      onTap: () {},
      enableHover: false,
      enableTap: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧图标和标题
            Row(
              children: [
                const Icon(Icons.badge_outlined),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate.userAgent.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      context.translate.userAgent.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            // 右侧下拉菜单
            MouseRegion(
              onEnter: (_) => setState(() => _isHoveringOnMenu = true),
              onExit: (_) => setState(() => _isHoveringOnMenu = false),
              child: ModernDropdownMenu<String>(
                items: _userAgentOptions.map((e) => e['value']!).toList(),
                selectedItem: _selectedUserAgent,
                onSelected: _onUserAgentChanged,
                itemToString: (value) {
                  final option = _userAgentOptions.firstWhere(
                    (e) => e['value'] == value,
                    orElse: () => {'value': value, 'label': value},
                  );
                  return option['label']!;
                },
                child: CustomDropdownButton(
                  text: _userAgentOptions.firstWhere(
                    (e) => e['value'] == _selectedUserAgent,
                    orElse: () => {
                      'value': _selectedUserAgent,
                      'label': _selectedUserAgent,
                    },
                  )['label']!,
                  isHovering: _isHoveringOnMenu,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
