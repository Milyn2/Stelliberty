import 'dart:ui';
import 'package:flutter/material.dart';

// 一个可感知悬停状态的、完全自定义的菜单项组件。
//
// 用于 `CustomPopupMenu`，以实现自定义的选中和悬停效果。
class _HoverableMenuItem<T> extends StatefulWidget {
  final T value;
  final T selectedValue;
  final String displayName;
  final ValueChanged<T> onSelected;

  const _HoverableMenuItem({
    super.key,
    required this.value,
    required this.selectedValue,
    required this.displayName,
    required this.onSelected,
  });

  @override
  State<_HoverableMenuItem<T>> createState() => _HoverableMenuItemState<T>();
}

class _HoverableMenuItemState<T> extends State<_HoverableMenuItem<T>> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.value == widget.selectedValue;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          widget.onSelected(widget.value);
          Navigator.of(context).pop(); // 手动关闭菜单
        },
        child: SizedBox(
          height: 36,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected || _isHovering)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withAlpha(38)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 22, right: 12),
                  child: Text(
                    widget.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 一个高度可定制的、通用的弹出式菜单按钮。
//
// 它允许完全自定义触发器（child）和菜单项的样式。
class ModernDropdownMenu<T> extends StatefulWidget {
  // 触发菜单的子组件。
  final Widget child;

  // 菜单项的数据列表。
  final List<T> items;

  // 当前选中的数据项。
  final T selectedItem;

  // 将数据项转换为显示字符串的函数。
  final String Function(T item) itemToString;

  // 选中菜单项时的回调。
  final ValueChanged<T> onSelected;

  const ModernDropdownMenu({
    super.key,
    required this.child,
    required this.items,
    required this.selectedItem,
    required this.itemToString,
    required this.onSelected,
  });

  @override
  State<ModernDropdownMenu<T>> createState() => _ModernDropdownMenuState<T>();
}

class _ModernDropdownMenuState<T> extends State<ModernDropdownMenu<T>> {
  final GlobalKey _key = GlobalKey();

  void _showMenu(BuildContext context) {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // 为滚动创建专用的 ScrollController
    final scrollController = ScrollController();

    // 计算菜单高度（最多显示6行）
    const itemHeight = 36.0;
    const maxVisibleItems = 6;
    const padding = 8.0; // 上下 padding 各 4
    final menuHeight =
        (widget.items.length > maxVisibleItems
            ? maxVisibleItems * itemHeight
            : widget.items.length * itemHeight) +
        padding;

    // 计算菜单位置
    double? top;
    double? bottom;
    bool showAbove = false; // 标记是否在按钮上方显示

    // 检查底部是否有足够空间
    if (offset.dy + menuHeight <= screenSize.height) {
      // 在按钮下方显示（默认），从按钮顶部开始，覆盖按钮
      top = offset.dy;
    } else if (offset.dy + size.height >= menuHeight) {
      // 在按钮上方显示，菜单底部对齐按钮底部，覆盖按钮
      bottom = screenSize.height - offset.dy - size.height;
      showAbove = true;
    } else {
      // 上下都放不下，在下方显示
      top = offset.dy;
    }

    // 计算右对齐位置
    double right = screenSize.width - offset.dx - size.width;

    // 确保不超出屏幕边界
    if (right < 0) {
      right = 0;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              top: top,
              right: right,
              bottom: bottom,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Material(
                    elevation: 0,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withAlpha((255 * 0.8).round()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha((255 * 0.2).round()),
                        width: 2,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: size.width,
                          maxWidth: 200, // 降低最大宽度
                          maxHeight: menuHeight - padding, // 限制最大高度
                        ),
                        child: IntrinsicWidth(
                          child: widget.items.length > maxVisibleItems
                              ? Scrollbar(
                                  controller: scrollController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: widget.items.map((item) {
                                        return _HoverableMenuItem<T>(
                                          value: item,
                                          selectedValue: widget.selectedItem,
                                          displayName: widget.itemToString(
                                            item,
                                          ),
                                          onSelected: widget.onSelected,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: widget.items.map((item) {
                                    return _HoverableMenuItem<T>(
                                      value: item,
                                      selectedValue: widget.selectedItem,
                                      displayName: widget.itemToString(item),
                                      onSelected: widget.onSelected,
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            alignment: showAbove
                ? Alignment.bottomRight
                : Alignment.topRight, // 根据位置调整锚点
            child: child,
          ),
        );
      },
    ).then((_) {
      // 菜单关闭后清理 ScrollController
      scrollController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: () => _showMenu(context),
      child: widget.child,
    );
  }
}
