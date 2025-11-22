import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stelliberty/utils/logger.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/styles/github-dark.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:stelliberty/i18n/i18n.dart';
import 'package:stelliberty/ui/widgets/modern_toast.dart';

// 订阅文件编辑器对话框
//
// 支持编辑订阅配置文件（YAML格式），提供：
// - 代码高亮和行号显示
// - 异步加载优化（大文件友好）
// - 修改状态跟踪和警告
// - 文件保存和验证
class FileEditorDialog extends StatefulWidget {
  // 文件名称
  final String fileName;

  // 初始文件内容
  final String initialContent;

  // 保存回调函数
  final Future<bool> Function(String content) onSave;

  const FileEditorDialog({
    super.key,
    required this.fileName,
    required this.initialContent,
    required this.onSave,
  });

  // 显示文件编辑器对话框
  static Future<void> show(
    BuildContext context, {
    required String fileName,
    required String initialContent,
    required Future<bool> Function(String content) onSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FileEditorDialog(
        fileName: fileName,
        initialContent: initialContent,
        onSave: onSave,
      ),
    );
  }

  @override
  State<FileEditorDialog> createState() => _FileEditorDialogState();
}

class _FileEditorDialogState extends State<FileEditorDialog>
    with TickerProviderStateMixin {
  late final CodeLineEditingController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  // 内容是否被修改
  bool _isModified = false;

  // 是否正在保存
  bool _isSaving = false;

  // 是否正在初始化编辑器（用于大文件异步加载）
  bool _isInitializing = true;

  // 缓存的行数（避免频繁计算）
  int _lineCount = 0;

  // 缓存的字符数（避免频繁计算）
  int _charCount = 0;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // 异步初始化编辑器（避免阻塞 UI 线程）
    _initializeEditor();
  }

  // 异步初始化编辑器
  // 使用 microtask 避免大文本加载时阻塞 UI
  Future<void> _initializeEditor() async {
    await Future.microtask(() {
      _controller = CodeLineEditingController.fromText(widget.initialContent);
      _controller.addListener(_onContentChanged);
      _updateStats();
    });

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 内容变化回调
  void _onContentChanged() {
    final isModified = _controller.text != widget.initialContent;
    if (isModified != _isModified) {
      setState(() {
        _isModified = isModified;
      });
    }
    _updateStats();
  }

  // 更新统计数据（字符数和行数）
  // 使用缓存避免频繁重新计算和不必要的 setState
  void _updateStats() {
    final text = _controller.text;
    final newCharCount = text.length;
    final newLineCount = text.split('\n').length;

    if (newCharCount != _charCount || newLineCount != _lineCount) {
      if (mounted) {
        setState(() {
          _charCount = newCharCount;
          _lineCount = newLineCount;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // 背景遮罩
              Container(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.3),
              ),
              // 对话框内容
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: _buildDialog(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 构建对话框主体
  Widget _buildDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 900,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: _isInitializing
                        ? _buildLoadingIndicator()
                        : _buildEditor(),
                  ),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建加载指示器（初始化编辑器时显示）
  Widget _buildLoadingIndicator() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // 构建对话框头部
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.code, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.translate.fileEditor.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (_isModified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.translate.fileEditor.modified,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.fileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleCancel,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建代码编辑器
  Widget _buildEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            CodeEditor(
              controller: _controller,
              padding: const EdgeInsets.only(
                left: 5,
                right: 0,
                top: 0,
                bottom: 0,
              ),
              scrollbarBuilder: (context, child, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 6),
                  child: Scrollbar(
                    controller: details.controller,
                    thumbVisibility: false,
                    child: Transform.translate(
                      offset: const Offset(0, -0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              indicatorBuilder:
                  (context, editingController, chunkController, notifier) {
                    return Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: DefaultCodeLineNumber(
                            controller: editingController,
                            notifier: notifier,
                          ),
                        ),
                        const SizedBox(width: 16), // 分隔线1px + 右侧间距15px
                      ],
                    );
                  },
              style: CodeEditorStyle(
                fontSize: 14,
                fontFamily: GoogleFonts.notoSansMono().fontFamily,
                selectionColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                codeTheme: CodeHighlightTheme(
                  languages: {'yaml': CodeHighlightThemeMode(mode: langYaml)},
                  theme: Theme.of(context).brightness == Brightness.dark
                      ? githubDarkTheme
                      : atomOneDarkTheme,
                ),
              ),
            ),
            // 分隔线独立覆盖（固定在行号右侧）
            Positioned(
              left: 50, // 左边距5 + 行号宽度约40 + 右边距5
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建底部操作栏
  Widget _buildActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.3),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.translate.fileEditor.stats
                    .replaceAll('{chars}', _charCount.toString())
                    .replaceAll('{lines}', _lineCount.toString()),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _isSaving ? null : _handleCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.6),
                ),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.6),
              ),
              child: Text(
                context.translate.fileEditor.cancelButton,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: (_isSaving || !_isModified) ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                shadowColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
              child: _isSaving
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(context.translate.fileEditor.savingButton),
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(context.translate.fileEditor.saveButton),
            ),
          ],
        ),
      ),
    );
  }

  // 处理取消操作
  void _handleCancel() {
    if (_isModified) {
      // 有未保存修改时显示确认对话框
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.translate.fileEditor.discardTitle),
          content: Text(context.translate.fileEditor.discardMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.translate.fileEditor.cancelButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(context.translate.fileEditor.discardConfirm),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) {
          _closeDialog();
        }
      });
    } else {
      _closeDialog();
    }
  }

  // 关闭对话框（带退出动画）
  void _closeDialog() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // 处理保存操作
  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await widget.onSave(_controller.text);

      if (!mounted) return;

      if (success) {
        ModernToast.success(context, context.translate.fileEditor.saveSuccess);
        _closeDialog();
      } else {
        setState(() {
          _isSaving = false;
        });
        ModernToast.error(context, context.translate.fileEditor.saveFailed);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      Logger.error('保存文件失败: $e');
      ModernToast.error(
        context,
        context.translate.fileEditor.saveError.replaceAll(
          '{error}',
          e.toString(),
        ),
      );
    }
  }
}
