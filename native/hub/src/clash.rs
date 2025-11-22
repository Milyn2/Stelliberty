// Clash 代理核心管理
//
// 支持两种模式：
// 1. 直接进程管理模式 - 直接启动 Clash 核心进程
// 2. 服务模式 - 通过系统服务以管理员权限运行 Clash 核心，支持 TUN 模式

use rinf::DartSignal;
use tokio::spawn;

pub mod config;
pub mod messages;
pub mod network;
pub mod r#override;
pub mod process;
pub mod service;
pub mod subscription;

pub use messages::{StartClashProcess, StopClashProcess};
pub use service::{GetServiceStatus, InstallService, StartClash, StopClash, UninstallService};

/// 初始化 Clash 模块
///
/// 启动所有 Clash 相关的消息监听器
pub fn init() {
    log::info!("初始化 Clash 消息监听器");

    // IPC 网络通信
    network::init_rest_api_listeners();

    // 直接进程管理模式

    // 启动 Clash 进程
    spawn(async {
        let receiver = StartClashProcess::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            tokio::task::spawn_blocking(move || {
                message.handle();
            })
            .await
            .unwrap_or_else(|e| log::error!("处理启动进程请求失败：{}", e));
        }
    });

    // 停止 Clash 进程
    spawn(async {
        let receiver = StopClashProcess::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            tokio::task::spawn_blocking(move || {
                message.handle();
            })
            .await
            .unwrap_or_else(|e| log::error!("处理停止进程请求失败：{}", e));
        }
    });

    // 服务模式

    // 获取服务状态
    spawn(async {
        let receiver = GetServiceStatus::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            tokio::spawn(async move {
                message.handle().await;
            });
        }
    });

    // 安装服务
    spawn(async {
        let receiver = InstallService::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            tokio::spawn(async move {
                message.handle().await;
            });
        }
    });

    // 卸载服务
    spawn(async {
        let receiver = UninstallService::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            tokio::spawn(async move {
                message.handle().await;
            });
        }
    });

    // 通过服务启动 Clash
    spawn(async {
        let receiver = StartClash::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            tokio::spawn(async move {
                message.handle().await;
            });
        }
    });

    // 通过服务停止 Clash
    spawn(async {
        let receiver = StopClash::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            tokio::spawn(async move {
                message.handle().await;
            });
        }
    });

    // 启动配置覆写监听器
    r#override::init_message_listeners();

    // 启动配置生成监听器
    config::init_message_listeners();
}
