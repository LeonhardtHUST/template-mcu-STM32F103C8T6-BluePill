/**
  ******************************************************************************
  * @file           : blink.h
  * @brief          : 自有最小示例：板载 PC13 LED 点灯（仅参考、需适配）。
  *
  * @attention
  * ------------------------------------------------------------------------------------------------
  * 许可：本文件由本仓库自研（S3 自有），随模板自由再分发。
  * 位置：examples/gpio-blink/，**不在** platformio.ini 的 src_dir(Core/Src) 内，
  *       因此不参与固件构建、不需要也不应该为它跑 pio run / 改 .ioc。
  * 验证等级：L0（未验证）。本文件未经本模板编译、未上板；接入前请按
  *           examples/recipes/gpio-blink.md 的 5 步流程自行补 L3 / L5。
  *
  * 板上事实：Blue Pill 的 User LED 接 PC13，灌电流(Sink)接法，**低电平点亮**
  *           （来源：#8 STM32-base 板卡页 User LED: PC13 / Mode Sink；见
  *           docs/bluepill/board-pinout.md §4.3）。故 RESET = 亮、SET = 灭。
  *
  * 接入提示：本模板 Core/Inc/bluepill.h 已提供 BP_LED_GPIO_PORT / BP_LED_GPIO_PIN，
  *           接入后建议改用那两个宏，并删掉本文件里的默认宏；本示例为保持自包含
  *           （不依赖 Core/ 路径）才自带一份默认值。
  * GPIO 模式 / 速度 / 上下拉 / 时钟一律由 .ioc 决定，本头文件不写配置。
  ******************************************************************************
  */

#ifndef EXAMPLES_BLINK_H
#define EXAMPLES_BLINK_H

#include <stdint.h>
#include "stm32f1xx_hal.h"

#ifdef __cplusplus
extern "C" {
#endif

/** @brief 初始化 PC13 为推挽输出，并把 LED 置为灭（高电平）。
  * @note  调用前请确认 GPIOC 时钟已在 MX_GPIO_Init() 中使能；重复使能是安全的。
  */
void blink_init(void);

/** @brief 翻转 LED 状态。配合 HAL_Delay(500) 即为 1 Hz 闪灯。 */
void blink_toggle(void);

/** @brief 直接置灯。
  * @param on 非 0 = 点亮（输出低电平）；0 = 熄灭（输出高电平）。
  */
void blink_set(uint8_t on);

#ifdef __cplusplus
}
#endif

#endif /* EXAMPLES_BLINK_H */
