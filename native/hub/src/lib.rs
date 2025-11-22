// Rust 原生模块入口
//
// 为 Flutter 应用提供系统级功能支持，包括进程管理、网络配置和系统集成

mod clash;
mod network;
mod system;
mod utils;

use rinf::{dart_shutdown, write_interface};

write_interface!();

// 原生模块主入口
//
// 启动并维护所有原生功能模块的生命周期：
// - 日志系统初始化
// - 网络模块初始化
// - 系统模块初始化
// - Clash 模块初始化
#[tokio::main(flavor = "current_thread")]
async fn main() {
    utils::init_logger::setup_logger();

    network::init();
    system::init();
    clash::init();

    dart_shutdown().await;

    // 清理 Clash 进程
    clash::process::cleanup();
}
