/**
  ******************************************************************************
  * @file           : usart1_echo.c
  * @brief          : 自有最小示例：USART1 115200 8N1 轮询回显（仅参考、需适配）。
  *
  * 许可 / 位置 / 验证等级 / 前提 / 板上接线见 usart1_echo.h 的 @attention 段。
  * 只使用 HAL UART 轮询 API，无中断、无 DMA、无 printf 浮点依赖，便于按需裁剪。
  ******************************************************************************
  */

#include "usart1_echo.h"

#include <stddef.h>

int usart1_echo_poll_byte(UART_HandleTypeDef *huart, uint8_t *io_buf, uint32_t timeout_ms)
{
  if ((huart == NULL) || (io_buf == NULL)) {
    return -1;
  }

  if (HAL_UART_Receive(huart, io_buf, 1U, timeout_ms) != HAL_OK) {
    /* HAL_TIMEOUT 表示这段时间没有数据，属于正常情况，不是错误。 */
    return 0;
  }

  if (HAL_UART_Transmit(huart, io_buf, 1U, timeout_ms) != HAL_OK) {
    return -1;
  }

  return 1;
}

int usart1_send_string(UART_HandleTypeDef *huart, const char *str, uint32_t timeout_ms)
{
  size_t length = 0U;

  if ((huart == NULL) || (str == NULL)) {
    return -1;
  }

  while (str[length] != '\0') {
    ++length;
  }

  if (length == 0U) {
    return 0;
  }

  /* HAL_UART_Transmit 的形参是 uint16_t；超长字符串应分批发送，这里直接判掉。 */
  if (length > 0xFFFFU) {
    return -1;
  }

  if (HAL_UART_Transmit(huart, (const uint8_t *)str, (uint16_t)length, timeout_ms) != HAL_OK) {
    return -1;
  }

  return 0;
}
