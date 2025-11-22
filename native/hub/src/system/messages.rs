// 系统配置消息协议
//
// 目的：定义开机自启动等系统配置的通信接口

use rinf::{DartSignal, RustSignal};
use serde::{Deserialize, Serialize};

// Dart → Rust：获取开机自启状态
#[derive(Deserialize, DartSignal)]
pub struct GetAutoStartStatus;

// Dart → Rust：设置开机自启状态
#[derive(Deserialize, DartSignal)]
pub struct SetAutoStartStatus {
    pub enabled: bool,
}

// Rust → Dart：开机自启状态响应
#[derive(Serialize, RustSignal)]
pub struct AutoStartStatusResult {
    pub enabled: bool,
    pub error_message: Option<String>,
}

use crate::system::auto_start;
use log::{error, info};

impl GetAutoStartStatus {
    // 查询当前自启动配置状态
    //
    // 目的：读取系统中的开机自启动设置
    pub fn handle(&self) {
        info!("收到获取开机自启动状态请求");

        let (enabled, error_message) = match auto_start::get_auto_start_status() {
            Ok(status) => (status, None),
            Err(err) => {
                error!("获取开机自启状态失败：{}", err);
                (false, Some(err))
            }
        };

        let response = AutoStartStatusResult {
            enabled,
            error_message,
        };

        response.send_signal_to_dart();
    }
}

impl SetAutoStartStatus {
    // 修改自启动配置
    //
    // 目的：启用或禁用应用程序的开机自启动
    pub fn handle(&self) {
        info!("收到设置开机自启动状态请求：enabled={}", self.enabled);

        let (enabled, error_message) = match auto_start::set_auto_start_status(self.enabled) {
            Ok(status) => (status, None),
            Err(err) => {
                error!("设置开机自启状态失败：{}", err);
                (false, Some(err))
            }
        };

        let response = AutoStartStatusResult {
            enabled,
            error_message,
        };

        response.send_signal_to_dart();
    }
}
