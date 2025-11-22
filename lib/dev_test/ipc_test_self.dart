import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:stelliberty/clash/services/process_service.dart';
import 'package:stelliberty/clash/config/config_injector.dart';
import 'package:stelliberty/clash/storage/preferences.dart';
import 'package:stelliberty/utils/logger.dart';

// IPC 功能自测试
//
// 测试 Clash 核心的 Named Pipe (Windows) / Unix Socket (Unix) 功能
// 使用项目内置的测试配置文件
class IpcTestSelf {
  static Future<void> run() async {
    Logger.info('开始 Clash IPC 功能自测试');

    try {
      // 0. 初始化 ClashPreferences（测试需要）
      await ClashPreferences.instance.init();
      Logger.info('✓ Preferences 已初始化');

      // 1. 获取测试配置文件路径
      final testConfigPath = await _getTestConfigPath();
      Logger.info('✓ 测试配置文件: $testConfigPath');

      // 2. 生成带 IPC 端点的运行时配置
      final runtimeConfigPath = await _generateRuntimeConfig(testConfigPath);
      Logger.info('✓ 运行时配置已生成: $runtimeConfigPath');

      // 3. 启动 Clash 核心
      final pid = await _startClashCore(runtimeConfigPath);
      Logger.info('✓ Clash 核心已启动 (PID: $pid)');

      // 4. 等待 IPC 端点就绪
      await Future.delayed(const Duration(seconds: 2));

      // 5. 验证 IPC 端点存在
      final ipcPath = _getIpcPath();
      final exists = await _checkIpcEndpoint(ipcPath);

      if (exists) {
        Logger.info('✓ IPC 端点已创建: $ipcPath');
      } else {
        Logger.error('✗ IPC 端点未找到: $ipcPath');
        throw Exception('IPC 端点创建失败');
      }

      // 6. 测试 IPC 连接（通过 Rust 层）
      // 注意：这里只测试端点存在性，实际的 HTTP-over-IPC 由 Rust 层实现
      Logger.info('✓ IPC 测试完成！');

      Logger.info('测试结果：成功 ✓');
      Logger.info('');
      Logger.info('下一步：');
      Logger.info('1. 手动终止 Clash 进程（PID: $pid）');
      Logger.info('2. 或者运行清理命令');
      Logger.info('');

      // 测试成功，退出进程
      exit(0);
    } catch (e, stack) {
      Logger.error('✗ IPC 测试失败: $e');
      Logger.error('堆栈: $stack');

      // 测试失败，退出进程
      exit(1);
    }
  }

  // 获取测试配置文件路径
  static Future<String> _getTestConfigPath() async {
    // 开发模式下直接使用 assets 目录（与 override_test.dart 相同）
    final testConfigPath = path.join('assets', 'test', 'config', 'test.yaml');

    final file = File(testConfigPath);
    if (!await file.exists()) {
      throw Exception('测试配置文件不存在: $testConfigPath');
    }

    return testConfigPath;
  }

  // 生成运行时配置（注入 IPC 端点）
  static Future<String> _generateRuntimeConfig(String testConfigPath) async {
    // 使用 ConfigInjector 生成包含 IPC 端点的配置
    final runtimePath = await ConfigInjector.injectCustomConfigParams(
      configPath: testConfigPath,
      httpPort: 17890, // 测试端口，避免冲突
      ipv6: false,
      tunEnable: false,
      tunStack: 'mixed',
      tunDevice: 'Stelliberty-Test',
      tunAutoRoute: false,
      tunAutoDetectInterface: false,
      tunDnsHijack: const ['any:53'],
      tunStrictRoute: false,
      tunMtu: 1500,
      tunAutoRedirect: false,
      tunRouteExcludeAddress: const [],
      tunDisableIcmpForwarding: false,
      allowLan: false,
      tcpConcurrent: false,
      geodataLoader: 'memconservative',
      findProcessMode: 'off',
      clashCoreLogLevel: 'debug', // 详细日志
      externalController: '', // 禁用 HTTP API（只用 IPC）
      externalControllerSecret: '',
      unifiedDelay: false,
      mode: 'rule',
    );

    if (runtimePath == null) {
      throw Exception('运行时配置生成失败');
    }

    return runtimePath;
  }

  // 启动 Clash 核心
  static Future<int> _startClashCore(String configPath) async {
    final processService = ProcessService();
    final execPath = await ProcessService.getExecutablePath();

    await processService.start(
      executablePath: execPath,
      configPath: configPath,
      apiHost: '127.0.0.1',
      apiPort: 19090, // 测试 API 端口
    );

    // 给一点时间让进程启动
    await Future.delayed(const Duration(milliseconds: 500));

    return 0;
  }

  // 获取 IPC 端点路径
  static String _getIpcPath() {
    if (Platform.isWindows) {
      return r'\\.\pipe\stelliberty';
    } else {
      return '/tmp/stelliberty.sock';
    }
  }

  // 检查 IPC 端点是否存在
  static Future<bool> _checkIpcEndpoint(String ipcPath) async {
    if (Platform.isWindows) {
      // Windows Named Pipe 检查
      // Named Pipes 是核心对象，不能直接用 File 检查
      // 需要通过 PowerShell 或 API 检查
      try {
        final result = await Process.run('powershell', [
          '-Command',
          '[System.IO.Directory]::GetFiles("\\\\.\\\\pipe\\\\")',
        ]);

        if (result.exitCode == 0) {
          final pipes = result.stdout.toString();
          // 提取 pipe 名称（去掉路径前缀）
          final pipeName = ipcPath.replaceAll(r'\\.\pipe\', '');
          return pipes.contains(pipeName);
        }
        return false;
      } catch (e) {
        Logger.warning('检查 Named Pipe 失败: $e');
        return false;
      }
    } else {
      // Unix Socket 可以直接检查文件
      final file = File(ipcPath);
      return await file.exists();
    }
  }
}
