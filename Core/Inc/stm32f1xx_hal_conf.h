#ifndef __STM32F1xx_HAL_CONF_H
#define __STM32F1xx_HAL_CONF_H

#ifdef __cplusplus
extern "C" {
#endif

#define HAL_MODULE_ENABLED
#define HAL_CORTEX_MODULE_ENABLED
#define HAL_GPIO_MODULE_ENABLED
#define HAL_RCC_MODULE_ENABLED

#include "stm32f1xx_hal_rcc.h"
#include "stm32f1xx_hal_gpio.h"
#include "stm32f1xx_hal_cortex.h"

#define HSE_VALUE              ((uint32_t)8000000)
#define HSE_STARTUP_TIMEOUT    ((uint32_t)100)
#define HSI_VALUE              ((uint32_t)8000000)
#define LSI_VALUE              ((uint32_t)40000)
#define LSE_VALUE              ((uint32_t)32768)
#define VDD_VALUE              ((uint32_t)3300)
#define TICK_INT_PRIORITY      ((uint32_t)0x0F)
#define USE_RTOS               0U
#define PREFETCH_ENABLE        1U

#ifdef  USE_FULL_ASSERT
void assert_failed(uint8_t* file, uint32_t line);
#endif

#ifdef __cplusplus
}
#endif

#endif /* __STM32F1xx_HAL_CONF_H */
