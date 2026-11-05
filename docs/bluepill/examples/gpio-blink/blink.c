/**
  ******************************************************************************
  * @file           : blink.c
  * @brief          : 自有最小示例：板载 PC13 LED 点灯（仅参考、需适配）。
  *
  * 许可 / 位置 / 验证等级 / 接入提示见 blink.h 的 @attention 段。
  * 本文件只使用 HAL 的 GPIO API，不含时钟树、不含中断、不含业务逻辑与 HAL 的耦合，
  * 便于拷进 main.c 的 USER CODE 块或独立用户源码。
  ******************************************************************************
  */

#include "blink.h"

/* 自包含的板上接线默认值（不依赖 Core/Inc 路径）。
   接入本模板后请改为 #include "bluepill.h" 并用 BP_LED_GPIO_PORT / BP_LED_GPIO_PIN。 */
#ifndef BLINK_LED_GPIO_PORT
#define BLINK_LED_GPIO_PORT GPIOC
#endif
#ifndef BLINK_LED_GPIO_PIN
#define BLINK_LED_GPIO_PIN GPIO_PIN_13
#endif

void blink_init(void)
{
  GPIO_InitTypeDef gpio_init = {0};

  __HAL_RCC_GPIOC_CLK_ENABLE();

  /* PC13 低电平点亮：初始输出高电平 = 灭。 */
  HAL_GPIO_WritePin(BLINK_LED_GPIO_PORT, BLINK_LED_GPIO_PIN, GPIO_PIN_SET);

  gpio_init.Pin = BLINK_LED_GPIO_PIN;
  gpio_init.Mode = GPIO_MODE_OUTPUT_PP;
  gpio_init.Pull = GPIO_NOPULL;
  gpio_init.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(BLINK_LED_GPIO_PORT, &gpio_init);
}

void blink_toggle(void)
{
  HAL_GPIO_TogglePin(BLINK_LED_GPIO_PORT, BLINK_LED_GPIO_PIN);
}

void blink_set(uint8_t on)
{
  /* Sink 接法：on -> RESET(亮)，off -> SET(灭)。 */
  const GPIO_PinState level = (on != 0U) ? GPIO_PIN_RESET : GPIO_PIN_SET;
  HAL_GPIO_WritePin(BLINK_LED_GPIO_PORT, BLINK_LED_GPIO_PIN, level);
}
