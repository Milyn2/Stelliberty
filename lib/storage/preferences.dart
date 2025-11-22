import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 通用应用持久化配置管理,管理主题、窗口、语言等应用级配置
class AppPreferences {
  AppPreferences._();

  static AppPreferences? _instance;
  static AppPreferences get instance => _instance ??= AppPreferences._();

  SharedPreferences? _prefs;

  // 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 确保 SharedPreferences 已初始化
  void _ensureInit() {
    if (_prefs == null) {
      throw Exception('AppPreferences 未初始化，请先调用 init()');
    }
  }

  // ==================== 存储键 ====================
  static const String _kThemeMode = 'theme_mode';
  static const String _kThemeColorIndex = 'theme_color_index';
  static const String _kWindowEffect = 'window_effect';
  static const String _kWindowPositionX = 'window_position_x';
  static const String _kWindowPositionY = 'window_position_y';
  static const String _kWindowWidth = 'window_width';
  static const String _kWindowHeight = 'window_height';
  static const String _kIsMaximized = 'is_maximized';
  static const String _kLanguageMode = 'language_mode';
  static const String _kAutoStartEnabled = 'auto_start_enabled';
  static const String _kSilentStartEnabled = 'silent_start_enabled';
  static const String _kMinimizeToTray = 'minimize_to_tray';
  static const String _kAppLogEnabled = 'app_log_enabled';

  // ==================== 主题配置 ====================

  // 获取主题模式
  ThemeMode getThemeMode() {
    _ensureInit();
    final mode = _prefs!.getString(_kThemeMode);
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // 保存主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _ensureInit();
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await _prefs!.setString(_kThemeMode, value);
  }

  // 获取主题颜色索引
  int getThemeColorIndex() {
    _ensureInit();
    return _prefs!.getInt(_kThemeColorIndex) ?? 0;
  }

  // 保存主题颜色索引
  Future<void> setThemeColorIndex(int index) async {
    _ensureInit();
    await _prefs!.setInt(_kThemeColorIndex, index);
  }

  // ==================== 窗口配置 ====================

  // 获取窗口效果
  String getWindowEffect() {
    _ensureInit();
    return _prefs!.getString(_kWindowEffect) ?? 'disabled';
  }

  // 保存窗口效果
  Future<void> setWindowEffect(String effect) async {
    _ensureInit();
    await _prefs!.setString(_kWindowEffect, effect);
  }

  // 获取窗口位置
  Offset? getWindowPosition() {
    _ensureInit();
    final x = _prefs!.getDouble(_kWindowPositionX);
    final y = _prefs!.getDouble(_kWindowPositionY);
    if (x != null && y != null) {
      return Offset(x, y);
    }
    return null;
  }

  // 保存窗口位置
  Future<void> setWindowPosition(Offset position) async {
    _ensureInit();
    await _prefs!.setDouble(_kWindowPositionX, position.dx);
    await _prefs!.setDouble(_kWindowPositionY, position.dy);
  }

  // 获取窗口大小
  Size? getWindowSize() {
    _ensureInit();
    final width = _prefs!.getDouble(_kWindowWidth);
    final height = _prefs!.getDouble(_kWindowHeight);
    if (width != null && height != null) {
      return Size(width, height);
    }
    return null;
  }

  // 保存窗口大小
  Future<void> setWindowSize(Size size) async {
    _ensureInit();
    await _prefs!.setDouble(_kWindowWidth, size.width);
    await _prefs!.setDouble(_kWindowHeight, size.height);
  }

  // 获取窗口是否最大化
  bool getIsMaximized() {
    _ensureInit();
    return _prefs!.getBool(_kIsMaximized) ?? false;
  }

  // 保存窗口最大化状态
  Future<void> setIsMaximized(bool isMaximized) async {
    _ensureInit();
    await _prefs!.setBool(_kIsMaximized, isMaximized);
  }

  // ==================== 语言配置 ====================

  // 获取语言模式
  String getLanguageMode() {
    _ensureInit();
    return _prefs!.getString(_kLanguageMode) ?? 'system';
  }

  // 保存语言模式
  Future<void> setLanguageMode(String mode) async {
    _ensureInit();
    await _prefs!.setString(_kLanguageMode, mode);
  }

  // ==================== 应用行为配置 ====================

  // 获取开机自启动状态
  bool getAutoStartEnabled() {
    _ensureInit();
    return _prefs!.getBool(_kAutoStartEnabled) ?? false;
  }

  // 保存开机自启动状态
  Future<void> setAutoStartEnabled(bool enabled) async {
    _ensureInit();
    await _prefs!.setBool(_kAutoStartEnabled, enabled);
  }

  // 获取静默启动状态
  bool getSilentStartEnabled() {
    _ensureInit();
    return _prefs!.getBool(_kSilentStartEnabled) ?? false;
  }

  // 保存静默启动状态
  Future<void> setSilentStartEnabled(bool enabled) async {
    _ensureInit();
    await _prefs!.setBool(_kSilentStartEnabled, enabled);
  }

  // 获取最小化到托盘状态
  bool getMinimizeToTray() {
    _ensureInit();
    return _prefs!.getBool(_kMinimizeToTray) ?? false; // 默认禁用
  }

  // 保存最小化到托盘状态
  Future<void> setMinimizeToTray(bool enabled) async {
    _ensureInit();
    await _prefs!.setBool(_kMinimizeToTray, enabled);
  }

  // 获取应用日志启用状态
  bool getAppLogEnabled() {
    _ensureInit();
    return _prefs!.getBool(_kAppLogEnabled) ?? false; // 默认禁用
  }

  // 保存应用日志启用状态
  Future<void> setAppLogEnabled(bool enabled) async {
    _ensureInit();
    await _prefs!.setBool(_kAppLogEnabled, enabled);
  }

  // ==================== 调试和重置 ====================

  // 获取所有存储的配置 (调试用)
  Map<String, dynamic> getAllSettings() {
    _ensureInit();
    final keys = [
      _kThemeMode,
      _kThemeColorIndex,
      _kWindowEffect,
      _kWindowPositionX,
      _kWindowPositionY,
      _kWindowWidth,
      _kWindowHeight,
      _kIsMaximized,
      _kLanguageMode,
      _kAutoStartEnabled,
      _kSilentStartEnabled,
      _kMinimizeToTray,
      _kAppLogEnabled,
    ];

    final Map<String, dynamic> settings = {};
    for (final key in keys) {
      if (_prefs!.containsKey(key)) {
        settings[key] = _prefs!.get(key);
      }
    }
    return settings;
  }

  // 重置所有应用配置到默认值
  Future<void> resetToDefaults() async {
    _ensureInit();
    final keys = [
      _kThemeMode,
      _kThemeColorIndex,
      _kWindowEffect,
      _kWindowPositionX,
      _kWindowPositionY,
      _kWindowWidth,
      _kWindowHeight,
      _kIsMaximized,
      _kLanguageMode,
      _kAutoStartEnabled,
      _kSilentStartEnabled,
      _kMinimizeToTray,
      _kAppLogEnabled,
    ];

    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }
}
