// 系统集成功能
//
// 目的：提供与操作系统深度集成的能力，如开机自启动管理、UWP 回环豁免等

use rinf::DartSignal;
use tokio::spawn;

pub mod auto_start;
#[cfg(target_os = "windows")]
pub mod loopback;
pub mod messages;

#[allow(unused_imports)]
pub use auto_start::{get_auto_start_status, set_auto_start_status};
#[allow(unused_imports)]
pub use messages::{AutoStartStatusResult, GetAutoStartStatus, SetAutoStartStatus};

// 启动系统配置相关的消息监听器
//
// 建立自启动状态管理的响应通道
fn init_message_listeners() {
    spawn(async {
        let receiver = GetAutoStartStatus::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            dart_signal.message.handle();
        }
        log::info!("获取自启动状态消息通道已关闭，退出监听器");
    });

    // 监听设置自启动状态信号
    spawn(async {
        let receiver = SetAutoStartStatus::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            dart_signal.message.handle();
        }
        log::info!("设置自启动状态消息通道已关闭，退出监听器");
    });
}

// 初始化系统模块
//
// 准备所有系统集成功能的运行环境，包括：
// - 自启动管理初始化
// - 系统配置消息监听器
// - UWP 回环豁免消息监听器（仅 Windows）
pub fn init() {
    auto_start::init();
    init_message_listeners();

    // UWP 回环豁免仅在 Windows 平台可用
    #[cfg(target_os = "windows")]
    loopback::init();
}
