/**
  ******************************************************************************
  * @file           : usart1_echo.h
  * @brief          : 自有最小示例：USART1 115200 8N1 轮询回显（仅参考、需适配）。
  *
  * @attention
  * ------------------------------------------------------------------------------------------------
  * 许可：本文件由本仓库自研（S3 自有），随模板自由再分发。
  * 位置：examples/usart1-115200/，**不在** platformio.ini 的 src_dir(Core/Src) 内，
  *       因此不参与固件构建、不要求也不应该为它跑 pio run。
  * 验证等级：L0（未验证）。本文件未经本模板编译、未上板。
  *
  * 前提（**需自行适配**）：本模板 `.ioc` 当前**未启用 USART1**（只配了 PC13 + SWD + HSI 8 MHz）。
  *       要使用本示例，必须先在 CubeMX GUI 里启用 USART1 异步模式、115200 8N1，
  *       保存后 project generate，核验生成日志无 Cannot map 且 main.c 里有 MX_USART1_UART_Init()
  *       （L4，见 AGENTS.md §2.3），再把源码接进去。
  *
  * 板上接线：USART1_TX = PA9、USART1_RX = PA10（芯片级默认复用，见
  *           docs/bluepill/board-pinout.md §2.2 / §4.4；Core/Inc/bluepill.h 的
  *           BP_USART1_TX_* / BP_USART1_RX_*）。USB 转串口请交叉接 TX/RX 并共地。
  *
  * 设计：本示例**不绑定** CubeMX 生成的全局句柄名（如 huart1），而是把
  *       UART_HandleTypeDef* 作为参数传入，便于拷到任何工程；波特率 / 字长 / 停止位 /
  *       校验位 / 时钟一律由 .ioc 决定，本头文件不写配置。
  ******************************************************************************
  */

#ifndef EXAMPLES_USART1_ECHO_H
#define EXAMPLES_USART1_ECHO_H

#include <stdint.h>
#include "stm32f1xx_hal.h"

#ifdef __cplusplus
extern "C" {
#endif

/** @brief 轮询接收 1 字节并原样回显。
  * @param huart      已由 MX_USART1_UART_Init() 初始化好的 USART1 句柄（如 &huart1）。
  * @param io_buf     至少 1 字节的收发缓冲区。
  * @param timeout_ms 单次接收的 HAL 超时（毫秒）；建议 10~100，避免长时间阻塞主循环。
  * @retval  1 成功收到并回显 1 字节
  * @retval  0 超时、没有数据（正常，主循环继续跑）
  * @retval -1 发送失败或参数非法
  */
int usart1_echo_poll_byte(UART_HandleTypeDef *huart, uint8_t *io_buf, uint32_t timeout_ms);

/** @brief 发送一个以 '\0' 结尾的字符串（不含结尾 '\0'）。
  * @param huart      已初始化的 USART1 句柄。
  * @param str        待发送字符串，不允许为 NULL。
  * @param timeout_ms 整串发送的 HAL 超时（毫秒）。
  * @retval  0 成功
  * @retval -1 失败（参数非法或 HAL_UART_Transmit 返回非 HAL_OK）
  */
int usart1_send_string(UART_HandleTypeDef *huart, const char *str, uint32_t timeout_ms);

#ifdef __cplusplus
}
#endif

#endif /* EXAMPLES_USART1_ECHO_H */
