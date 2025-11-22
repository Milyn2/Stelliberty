// Stelliberty Service
//
// 后台服务程序，负责以管理员权限运行 Clash 核心
//
// 用法：
//   stelliberty-service              - 运行服务
//   stelliberty-service install      - 安装并启动服务
//   stelliberty-service uninstall    - 停止并卸载服务
//   stelliberty-service start        - 启动服务
//   stelliberty-service stop         - 停止服务

use anyhow::Result;
use stelliberty_service::{check_privileges, handle_command, logger, print_privilege_error, run};

fn main() -> Result<()> {
    // 处理命令行参数
    let args: Vec<String> = std::env::args().collect();

    // 检查是否是查询命令（不需要管理员权限）
    let is_query_command = args.len() > 1 && matches!(args[1].as_str(), "status" | "logs");

    // 检查权限（查询命令除外）
    if !is_query_command && !check_privileges() {
        print_privilege_error();
        std::process::exit(1);
    }

    if let Some(()) = handle_command(&args)? {
        // 命令已处理完成，退出
        return Ok(());
    }

    // 初始化日志（只在运行服务时初始化）
    logger::init_logger();

    // 运行服务
    tokio::runtime::Runtime::new()?.block_on(run())
}
