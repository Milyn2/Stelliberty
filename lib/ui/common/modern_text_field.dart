import 'package:flutter/material.dart';

// 现代化的文本输入框组件
//
// 与 ModernDropdownButton 风格统一的输入框
class ModernTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final bool enabled;
  final bool obscureText;
  final EdgeInsetsGeometry? contentPadding;
  final double? height;

  const ModernTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.obscureText = false,
    this.contentPadding,
    this.height,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  bool _isFocused = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 计算背景颜色
    Color backgroundColor;
    if (!widget.enabled) {
      backgroundColor = theme.colorScheme.surface.withAlpha(100);
    } else if (_isFocused) {
      backgroundColor = Color.alphaBlend(
        theme.colorScheme.primary.withAlpha(10),
        theme.colorScheme.surface.withAlpha(255),
      );
    } else if (_isHovering) {
      backgroundColor = Color.alphaBlend(
        theme.colorScheme.onSurface.withAlpha(10),
        theme.colorScheme.surface.withAlpha(255),
      );
    } else {
      backgroundColor = theme.colorScheme.surface.withAlpha(255);
    }

    // 边框颜色
    Color borderColor;
    if (widget.errorText != null) {
      borderColor = theme.colorScheme.error;
    } else if (!widget.enabled) {
      borderColor = theme.colorScheme.outline.withAlpha(50);
    } else if (_isFocused) {
      borderColor = theme.colorScheme.primary.withAlpha(180);
    } else if (_isHovering) {
      borderColor = theme.colorScheme.outline.withAlpha(150);
    } else {
      borderColor = theme.colorScheme.outline.withAlpha(100);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标签
          if (widget.labelText != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                widget.labelText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _isFocused
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha(180),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          // 输入框
          Focus(
            onFocusChange: (focused) => setState(() => _isFocused = focused),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: widget.height,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 2 : 1.5,
                ),
                boxShadow: [
                  if (_isFocused)
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                maxLines: widget.maxLines,
                enabled: widget.enabled,
                obscureText: widget.obscureText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withAlpha(100),
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: _isFocused
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha(150),
                        )
                      : null,
                  suffixIcon: widget.suffixIcon,
                  suffixText: widget.suffixText,
                  suffixStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      widget.contentPadding ??
                      EdgeInsets.symmetric(
                        horizontal: widget.prefixIcon != null ? 12 : 16,
                        vertical: 14,
                      ),
                ),
              ),
            ),
          ),
          // 错误文本或帮助文本
          if (widget.errorText != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                widget.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontSize: 11,
                ),
              ),
            ),
          ] else if (widget.helperText != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                widget.helperText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(130),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
