import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stelliberty/clash/data/subscription_model.dart';
import 'package:stelliberty/clash/providers/subscription_provider.dart';
import 'package:stelliberty/i18n/i18n.dart';
import 'package:stelliberty/ui/widgets/modern_toast.dart';

// 订阅卡片组件
//
// 显示订阅的详细信息，包括：
// - 订阅名称和图标
// - 订阅 URL
// - 状态标签（自动更新、更新间隔、上次更新时间、更新中状态）
// - 流量统计信息
// - 操作菜单（更新、编辑、复制链接、删除）
class SubscriptionCard extends StatelessWidget {
  // 订阅数据
  final Subscription subscription;

  // 是否为当前选中的订阅
  final bool isSelected;

  // 点击卡片的回调
  final VoidCallback? onTap;

  // 更新订阅的回调
  final VoidCallback? onUpdate;

  // 编辑订阅配置的回调
  final VoidCallback? onEdit;

  // 编辑订阅文件的回调
  final VoidCallback? onEditFile;

  // 删除订阅的回调
  final VoidCallback? onDelete;

  // 管理规则覆写的回调
  final VoidCallback? onManageOverride;

  // 查看提供者的回调
  final VoidCallback? onViewProvider;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.isSelected = false,
    this.onTap,
    this.onUpdate,
    this.onEdit,
    this.onEditFile,
    this.onDelete,
    this.onManageOverride,
    this.onViewProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        final isUpdating = provider.isSubscriptionUpdating(subscription.id);
        final isBatchUpdating = provider.isBatchUpdating;
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final mixColor = isDark ? Colors.black : Colors.white;
        final mixOpacity = 0.1;

        return Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Color.alphaBlend(
                  mixColor.withValues(alpha: mixOpacity),
                  isSelected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.2)
                      : colorScheme.surface.withValues(
                          alpha: isDark ? 0.7 : 0.85,
                        ),
                ),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary.withValues(
                          alpha: isDark ? 0.7 : 0.6,
                        )
                      : colorScheme.outline.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? colorScheme.primary.withValues(
                            alpha: isDark ? 0.3 : 0.15,
                          )
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: isSelected ? 12 : 8,
                    offset: Offset(0, isSelected ? 3 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题行
                        _buildTitleRow(context, isUpdating, isBatchUpdating),

                        const SizedBox(height: 8),

                        // URL
                        _buildUrlText(),

                        const SizedBox(height: 8),

                        // 状态标签与流量进度条并排（只有真正有流量数据时才显示进度条）
                        if (subscription.info != null &&
                            subscription.info!.total > 0)
                          _buildStatusWithTraffic(context)
                        else
                          _buildStatusChips(context),

                        // 错误信息显示
                        if (subscription.lastError != null) ...[
                          const SizedBox(height: 12),
                          _buildErrorInfo(context),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 灰色蒙层（更新时显示）
            if (isUpdating)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.translate.subscription.updating,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 构建标题行
  Widget _buildTitleRow(
    BuildContext context,
    bool isUpdating,
    bool isBatchUpdating,
  ) {
    final isDisabled = isUpdating || isBatchUpdating;

    return Row(
      children: [
        Icon(
          Icons.rss_feed,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            subscription.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isSelected)
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
        const SizedBox(width: 8),
        // 独立更新按钮
        if (!subscription.isLocalFile)
          IconButton(
            onPressed: isDisabled ? null : onUpdate,
            icon: Icon(
              Icons.sync_rounded,
              size: 20,
              color: isDisabled
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.primary,
            ),
            tooltip: context.translate.subscription.updateCard,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        // 更多操作菜单
        _buildPopupMenu(context),
      ],
    );
  }

  // 构建 URL 文本
  Widget _buildUrlText() {
    return Text(
      subscription.url,
      style: TextStyle(color: Colors.grey[600], fontSize: 12),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // 构建状态标签（无流量信息时使用）
  Widget _buildStatusChips(BuildContext context) {
    return _buildStatusText(context);
  }

  // 构建状态文本
  Widget _buildStatusText(BuildContext context) {
    final List<InlineSpan> children = [];

    // 自动更新状态
    children.add(
      TextSpan(
        text: subscription.isLocalFile
            ? context.translate.subscription.localTypeLabel
            : (subscription.autoUpdate
                  ? context.translate.subscription.autoUpdateLabel
                  : context.translate.subscription.manualUpdateLabel),
        style: TextStyle(
          color: subscription.isLocalFile
              ? Colors.grey
              : (subscription.autoUpdate ? Colors.green : Colors.grey),
          fontSize: 11,
        ),
      ),
    );

    // 距下次更新时间（仅远程订阅+自动更新+有更新记录时显示）
    if (!subscription.isLocalFile &&
        subscription.autoUpdate &&
        subscription.lastUpdateTime != null) {
      children.add(
        const TextSpan(
          text: ' | ',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
      );
      children.add(
        TextSpan(
          text: _formatNextUpdate(context),
          style: const TextStyle(color: Colors.purple, fontSize: 11),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: children),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // 构建弹出菜单
  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'editFile':
            onEditFile?.call();
            break;
          case 'copy':
            _copyUrl(context);
            break;
          case 'override':
            onManageOverride?.call();
            break;
          case 'provider':
            onViewProvider?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 12),
              Text(context.translate.subscription.menu.configEdit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'editFile',
          child: Row(
            children: [
              const Icon(Icons.code, size: 20),
              const SizedBox(width: 12),
              Text(context.translate.subscription.menu.fileEdit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'override',
          child: Row(
            children: [
              const Icon(Icons.rule, size: 20),
              const SizedBox(width: 12),
              Text(context.translate.subscription.menu.overrideManage),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'provider',
          child: Row(
            children: [
              const Icon(Icons.extension, size: 20),
              const SizedBox(width: 12),
              Text(context.translate.subscription.menu.providerView),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              const Icon(Icons.copy, size: 20),
              const SizedBox(width: 12),
              Text(context.translate.subscription.menu.copyLink),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                context.translate.subscription.menu.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建状态与流量并排显示
  Widget _buildStatusWithTraffic(BuildContext context) {
    final info = subscription.info!;
    final usagePercentage = info.usagePercentage;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 左侧：状态标签
        _buildStatusText(context),
        const SizedBox(width: 16),
        // 中间：流量进度条（垂直居中对齐）
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usagePercentage / 100,
                minHeight: 6,
                backgroundColor: Colors.grey.withAlpha((255 * 0.2).round()),
                valueColor: AlwaysStoppedAnimation<Color>(
                  usagePercentage < 80 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 右侧：流量数值
        Text(
          '${_formatBytes(info.used)}/${_formatBytes(info.total)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: usagePercentage < 80 ? Colors.green : Colors.red,
          ),
        ),
        // 到期时间（如果有）
        if (info.expire > 0) ...[
          const SizedBox(width: 12),
          Text(
            info.isExpired
                ? context.translate.subscription.expired
                : _formatExpireDate(info.expire, context),
            style: TextStyle(
              fontSize: 11,
              color: info.isExpired ? Colors.red : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  // 复制 URL
  void _copyUrl(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: subscription.url));
      if (context.mounted) {
        ModernToast.success(context, '链接已复制到剪贴板');
      }
    } catch (e) {
      if (context.mounted) {
        ModernToast.error(context, '复制失败: $e');
      }
    }
  }

  // 构建错误信息
  Widget _buildErrorInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subscription.lastError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }

  // 格式化距下次更新时间
  String _formatNextUpdate(BuildContext context) {
    if (subscription.lastUpdateTime == null) {
      return context.translate.subscription.pendingUpdate;
    }

    final trans = context.translate.subscription;
    final nextUpdateTime = subscription.lastUpdateTime!.add(
      subscription.autoUpdateInterval,
    );
    final now = DateTime.now();

    // 如果已经过了更新时间
    if (now.isAfter(nextUpdateTime)) {
      return trans.pendingUpdate;
    }

    final diff = nextUpdateTime.difference(now);

    if (diff.inMinutes < 1) return trans.willUpdate;
    if (diff.inMinutes < 60) {
      return trans.updateAfterMinutes.replaceAll(
        '{n}',
        diff.inMinutes.toString(),
      );
    }
    if (diff.inHours < 24) {
      return trans.updateAfterHours.replaceAll('{n}', diff.inHours.toString());
    }
    return trans.updateAfterDays.replaceAll('{n}', diff.inDays.toString());
  }

  // 格式化过期日期
  String _formatExpireDate(int timestamp, BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = date.difference(now);

    final trans = context.translate.subscription;

    if (diff.inDays > 30) {
      return trans.remainingMonths.replaceAll(
        '{n}',
        (diff.inDays / 30).floor().toString(),
      );
    }
    return trans.remainingDays.replaceAll('{n}', diff.inDays.toString());
  }
}
