/**
  ******************************************************************************
  * @file           : bluepill.h
  * @brief          : Blue Pill 板卡「信号 -> 引脚」映射（人工维护，非 CubeMX 生成物）。
  *
  * @attention
  * ------------------------------------------------------------------------------------------------
  * 本文件只回答一个问题：板上哪条信号固定接在哪个引脚。它 **不是** 配置：
  *   - GPIO 模式 / 复用功能(AF) / 上下拉 / 速度 / 时钟树 **一律由仓库根目录的 `.ioc` 决定**；
  *   - 本文件不写任何模式、不初始化任何外设、不产生任何代码；
  *   - `.ioc` 仍是唯一事实来源（见 AGENTS.md §2.1），不得用本文件反过来改 `.ioc`。
  *
  * 每个宏的依据（`.ioc` 或板级资料，二者之一可查）：
  *   BP_LED_*        -> .ioc: PC13-TAMPER-RTC.Signal=GPIO_Output；#8 板卡页 User LED: PC13 (Mode Sink)
  *   BP_SWDIO_*      -> .ioc: PA13.Signal=SYS_JTMS-SWDIO；#8 SWD header DIO=PA13
  *   BP_SWCLK_*      -> .ioc: PA14.Signal=SYS_JTCK-SWCLK；#8 SWD header CLK=PA14
  *   BP_USB_DM/DP_*  -> #8 USB connector: D- = PA11, D+ = PA12；PLAN §2.9「PA11/PA12 = USB」
  *   BP_USART1_*     -> PLAN §2.9「PA9/PA10 = USART1」；board-pinout.md §2.2 / §4.4（芯片级默认复用）
  *   BP_BOOT1_*      -> #8 Inputs: BOOT1 jumper 接 PB2；board-pinout.md §4.4 / §5.3
  *
  * 注意：本模板 `.ioc` **当前只启用** PC13(GPIO_Output) 与 PA13/PA14(SWD)，
  * 使用 HSI 8 MHz；USART1 / USB 并未启用。下面这些宏描述的是「板上接线是死的」，
  * 并 **不表示** 该外设已经配置完成 —— 要用串口 / USB，请先在 `.ioc` 里加外设再生成（L4 核验）。
  *
  * BOOT0 是芯片专用启动引脚（经跳线选择），不是 GPIO，故不定义 BP_BOOT0_GPIO_* 宏；
  * 板上 HSE 8 MHz 晶振是否启用、PLL 如何配置由 `.ioc` 的 RCC 决定（.ioc: RCC.HSE_VALUE=8000000），
  * 本文件不写时钟参数。板上丝印 / 元件位号以 #7 原理图 / #8 板卡页为准，不在此编造。
  *
  * 本文件位于 CubeMX 管理的 `Core/Inc/`，但 CubeMX **既不生成也不覆盖**它：
  * include 放在 `main.h` 的 USER CODE BEGIN Includes 块内（为避免提前闭合本注释，
  * 此处不写出成对的斜杠星号标记），重新生成后保留。
  * 派生到别的板卡时按新板卡资料重填，**不要照抄别的板**。
  * 详见 docs/bluepill/board-pinout.md 与 docs/bluepill/SOURCES.md。
  ******************************************************************************
  */

#ifndef BLUEPILL_H
#define BLUEPILL_H

#include "stm32f1xx_hal.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ---- 板载用户 LED：PC13，灌电流(Sink)接法，低电平点亮 ---- */
#define BP_LED_GPIO_PORT          GPIOC
#define BP_LED_GPIO_PIN           GPIO_PIN_13

/* ---- SWD 调试口：PA13 = SWDIO，PA14 = SWCLK ---- */
#define BP_SWDIO_GPIO_PORT        GPIOA
#define BP_SWDIO_GPIO_PIN         GPIO_PIN_13
#define BP_SWCLK_GPIO_PORT        GPIOA
#define BP_SWCLK_GPIO_PIN         GPIO_PIN_14

/* ---- USB（Micro-USB）：PA11 = D-(DM)，PA12 = D+(DP) ---- */
#define BP_USB_DM_GPIO_PORT       GPIOA
#define BP_USB_DM_GPIO_PIN        GPIO_PIN_11
#define BP_USB_DP_GPIO_PORT       GPIOA
#define BP_USB_DP_GPIO_PIN        GPIO_PIN_12

/* ---- USART1：PA9 = TX，PA10 = RX（.ioc 当前未启用，见上方说明）---- */
#define BP_USART1_TX_GPIO_PORT    GPIOA
#define BP_USART1_TX_GPIO_PIN     GPIO_PIN_9
#define BP_USART1_RX_GPIO_PORT    GPIOA
#define BP_USART1_RX_GPIO_PIN     GPIO_PIN_10

/* ---- BOOT1 跳线：PB2（BOOT0 为专用引脚，不在此定义 GPIO 宏）---- */
#define BP_BOOT1_GPIO_PORT        GPIOB
#define BP_BOOT1_GPIO_PIN         GPIO_PIN_2

#ifdef __cplusplus
}
#endif

#endif /* BLUEPILL_H */
