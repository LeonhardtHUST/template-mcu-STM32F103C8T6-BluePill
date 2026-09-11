#include "stm32f1xx.h"

uint32_t SystemCoreClock = 8000000;

void SystemInit(void)
{
#if defined (DATA_IN_ExtSRAM) || defined (DATA_IN_ExtSDRAM)
  SystemInit_ExtMemCtl();
#endif
  SCB->VTOR = FLASH_BASE;
}

void SystemCoreClockUpdate(void)
{
  SystemCoreClock = 72000000;
}
