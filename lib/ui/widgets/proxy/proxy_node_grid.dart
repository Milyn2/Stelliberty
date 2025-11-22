import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stelliberty/clash/providers/clash_provider.dart';
import 'package:stelliberty/clash/data/clash_model.dart';
import 'package:stelliberty/ui/widgets/proxy/proxy_node_card.dart';
import 'package:stelliberty/ui/notifiers/proxy_notifier.dart';
import 'package:stelliberty/utils/logger.dart';
import 'package:stelliberty/i18n/i18n.dart';

// 代理节点网格状态（用于 Selector）
class _ProxyNodeGridState {
  final Map<String, dynamic> proxyNodes;
  final Set<String> testingNodes;
  final bool isBatchTesting;
  final int updateCount;
  final String? selectedProxyName; // 关键：选中的节点名称

  const _ProxyNodeGridState({
    required this.proxyNodes,
    required this.testingNodes,
    required this.isBatchTesting,
    required this.updateCount,
    required this.selectedProxyName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ProxyNodeGridState &&
          runtimeType == other.runtimeType &&
          proxyNodes.length == other.proxyNodes.length &&
          testingNodes.length == other.testingNodes.length &&
          isBatchTesting == other.isBatchTesting &&
          updateCount == other.updateCount &&
          selectedProxyName == other.selectedProxyName;

  @override
  int get hashCode =>
      proxyNodes.length.hashCode ^
      testingNodes.length.hashCode ^
      isBatchTesting.hashCode ^
      updateCount.hashCode ^
      selectedProxyName.hashCode;
}

// 代理节点网格列表组件
class ProxyNodeGrid extends StatefulWidget {
  final ClashProvider clashProvider;
  final String selectedGroupName; // 改为只传递组名
  final ProxyNotifier viewModel; // 用于排序
  final ScrollController scrollController;
  final Function(int) onCrossAxisCountChanged;
  final Function(String groupName, String proxyName) onSelectProxy;
  final Function(String proxyName) onTestDelay;

  const ProxyNodeGrid({
    super.key,
    required this.clashProvider,
    required this.selectedGroupName,
    required this.viewModel,
    required this.scrollController,
    required this.onCrossAxisCountChanged,
    required this.onSelectProxy,
    required this.onTestDelay,
  });

  @override
  State<ProxyNodeGrid> createState() => _ProxyNodeGridWidgetState();
}

class _ProxyNodeGridWidgetState extends State<ProxyNodeGrid> {
  int _lastCrossAxisCount = 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 3.0, 5.0),
        child: ListenableBuilder(
          listenable: widget.viewModel, // 监听排序变化
          builder: (context, _) {
            return Selector<ClashProvider, _ProxyNodeGridState>(
              selector: (_, clash) {
                // 先获取 selectedGroup 以获取最新的 now 值
                final selectedGroup = clash.proxyGroups.firstWhere(
                  (g) => g.name == widget.selectedGroupName,
                  orElse: () => clash.proxyGroups.isNotEmpty
                      ? clash.proxyGroups.first
                      : ProxyGroup(name: '', type: '', now: null, all: []),
                );

                return _ProxyNodeGridState(
                  proxyNodes: clash.proxyNodes,
                  testingNodes: clash.testingNodes,
                  isBatchTesting: clash.isBatchTesting,
                  updateCount: clash.proxyNodesUpdateCount,
                  selectedProxyName: selectedGroup.now, // 关键：传递选中节点名
                );
              },
              builder: (context, state, child) {
                // 从最新的 clash.proxyGroups 中获取 selectedGroup
                final clashProvider = context.read<ClashProvider>();
                final selectedGroup = clashProvider.proxyGroups.firstWhere(
                  (g) => g.name == widget.selectedGroupName,
                  orElse: () => clashProvider.proxyGroups.first,
                );

                // 应用排序
                final sortedProxyNames = widget.viewModel.getSortedProxyNames(
                  selectedGroup.all,
                );
                final sortedGroup = selectedGroup.copyWith(
                  all: sortedProxyNames,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final int crossAxisCount = (constraints.maxWidth / 280)
                        .floor()
                        .clamp(2, 4);

                    // 只在列数变化时调用回调
                    if (crossAxisCount != _lastCrossAxisCount) {
                      _lastCrossAxisCount = crossAxisCount;
                      widget.onCrossAxisCountChanged(crossAxisCount);
                    }

                    return GridView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 20.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        mainAxisExtent: 88.0,
                      ),
                      itemCount: sortedGroup.all.length,
                      // 优化渲染性能
                      cacheExtent: 500.0,
                      addAutomaticKeepAlives: true,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) {
                        final proxyName = sortedGroup.all[index];
                        final node = state.proxyNodes[proxyName];

                        if (node == null) {
                          // 简化日志输出，避免滚动时性能问题
                          Logger.warning('节点信息不可用: $proxyName');

                          return Card(
                            child: ListTile(
                              title: Text(
                                proxyName,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                context.translate.proxy.nodeInfoUnavailable,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }

                        final isSelected = sortedGroup.now == proxyName;
                        final isWaitingTest = state.testingNodes.contains(
                          proxyName,
                        );

                        // 使用 RepaintBoundary 隔离重绘，优化渲染性能
                        return RepaintBoundary(
                          child: ProxyNodeCard(
                            node: node,
                            isSelected: isSelected,
                            isClashRunning: widget.clashProvider.isRunning,
                            isWaitingTest: isWaitingTest,
                            onTap: () => widget.onSelectProxy(
                              sortedGroup.name,
                              proxyName,
                            ),
                            onTestDelay: () => widget.onTestDelay(proxyName),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
