# Blue Pill 板卡引脚速查与最小系统（自研整理）

> 本文件由本仓库自行整理（**S3 自有**），数据引自 S1 / S2 资料并逐条注明出处：
> 板级 40-pin 排针、电源、板载 LED 接法与硬件坑引自 **#8 STM32-base 板卡页**、**#7 社区原版原理图**（按 Q9 条件入库，见 [`ATTRIBUTION.md`](ATTRIBUTION.md)）；
> 芯片级复用功能引自 **#1 DS5319 datasheet** / **#4 RM0008 参考手册**（ST 官方直链，不入库原件）；
> 最小系统设计要点引自 **#3 AN2586 Rev 8.0**（ST 官方·芯片级）与 **#6 MB1136 原理图**（**归属 NUCLEO-F103RB 板卡，是另一块板，仅作 ST 官方硬件设计范例，不是 Blue Pill 原理图**）。
> 逐条资料的直链、编号、许可、访问证据见 [`SOURCES.md`](SOURCES.md)；四级入口对照见 [`README.md`](README.md)。

## 0. 使用边界（先读）

- **`.ioc` 是唯一事实来源**（[`AGENTS.md`](../../AGENTS.md) §2.1）：GPIO 模式、复用功能（AF）、上下拉、时钟树只认仓库根目录的 `.ioc`（模板默认工程名见 `README.md`，派生后由 `scripts/init-project.sh|ps1` 同步改名）。
  本文件与 [`Core/Inc/bluepill.h`](../../Core/Inc/bluepill.h) 都**只描述「板上哪条信号接在哪个引脚」**，不替代 `.ioc` 的配置。
- **板上丝印编号、排针编号、元件位号一律以 [#7 原理图](https://stm32-base.org/assets/pdf/boards/original-schematic-STM32F103C8T6-Blue_Pill.pdf) / [#8 板卡页](https://stm32-base.org/boards/STM32F103C8T6-Blue-Pill.html) 为准**。
  Blue Pill 是社区通用兼容板（#8 实测 `Brand: Unknown` / `Origin: China`），**没有官方厂商**，不同批次 / 不同板厂的丝印、电阻值、元件型号可能不同；本文件不凭空编造板上元件位号或丝印。
- 本实施轮用 WebFetch 核对了 #8 页面（标题 `STM32F103C8T6 - Blue Pill | STM32-base project`），下表 40-pin 排针、电源、LED 接法与 USB / +5V 两条警告逐字取自该页；#7 原理图 PDF 已按 Q9 条件入库，文件头 `%PDF-1.3`、实测 151,372 B。
- **官方边界**：够得上「大厂官方」的只有芯片级资料（#1 / #3 / #4 / #5 / #2）；Blue Pill 板级引脚事实一律标 **社区权威·板级**（S2），不得写成 ST 官方。

## 1. 板载资源速查（来自 #8 板卡页）

| 项 | 值 | 出处 |
| -- | -- | ---- |
| MCU | STM32F103C8T6，Arm Cortex-M3，LQFP48，最高 72 MHz | #8 / #1 |
| 存储器 | FLASH 64 KiB，SRAM 20 KiB（另有 128K 争议，见 §4.5） | #8 / #9 |
| 振荡器 | HSI 8 MHz、LSI 40 kHz、HSE 8 MHz、LSE 32.768 kHz | #8 |
| 3.3 V 稳压器 | 上海 TX6211B（SOT23-5），输入 +3.6～+5.5 V，输出 3.3 V @ 300 mA | #8 |
| 供电来源 | 任意 +3.3 V 引脚 / 任意 +5 V 引脚 / USB Micro 连接器 +5 V | #8 |
| VDDA / VSSA / VREF- / VREF+ | 板卡页标注 `No`（未单独引出） | #8 |
| 备用电池 | 无 | #8 |
| PCB | 蓝色，23 mm × 53 mm，面包板安装 | #8 |
| 输入 | RESET 按键（接 NRST，低电平有效）、BOOT0 跳线、BOOT1 跳线（接 PB2） | #8 |
| 输出 | PWR 电源 LED（接 +3.3 V）、User LED（接 PC13，**Sink / 灌电流接法**） | #8 |
| 连接器 | Header 1（20×1）、Header 2（20×1）、SWD 排针（4×1）、USB Micro | #8 |
| 品牌 / 产地 | `Brand: Unknown` / `Origin: China`，名称源于 STM32duino 论坛帖、《黑客帝国》 | #8 / #12 |

## 2. 40-pin 速查（2×20 排针）

> 「丝印」列为 #8 板卡页记录的排针标注，**以 [#7 原理图](https://stm32-base.org/assets/pdf/boards/original-schematic-STM32F103C8T6-Blue_Pill.pdf) / [#8 板卡页](https://stm32-base.org/boards/STM32F103C8T6-Blue-Pill.html) 为准**。
> 「常见复用」只列芯片级公开事实中最常用的项，**完整复用表与 AF 配置以 #1 DS5319 / #4 RM0008 及本仓 `.ioc` 为准**；未列项不代表没有复用功能。

### 2.1 Header 1（#8：20×1 排针，Name / Connected to）

| # | 丝印 | 连接 | 常见复用（芯片级，见 #1 / #4） |
| - | ---- | ---- | ------------------------------ |
| 1 | VB | VBAT | 备份域供电 |
| 2 | C13 | PC13 | 板载 User LED（低电平点亮）、TAMPER-RTC |
| 3 | C14 | PC14 | OSC32_IN（LSE 32.768 kHz） |
| 4 | C15 | PC15 | OSC32_OUT（LSE 32.768 kHz） |
| 5 | A0 | PA0 | ADC1_IN0、WKUP、TIM2_CH1 |
| 6 | A1 | PA1 | ADC1_IN1、TIM2_CH2 |
| 7 | A2 | PA2 | ADC1_IN2、TIM2_CH3、USART2_TX |
| 8 | A3 | PA3 | ADC1_IN3、TIM2_CH4、USART2_RX |
| 9 | A4 | PA4 | ADC1_IN4、SPI1_NSS |
| 10 | A5 | PA5 | ADC1_IN5、SPI1_SCK |
| 11 | A6 | PA6 | ADC1_IN6、SPI1_MISO |
| 12 | A7 | PA7 | ADC1_IN7、SPI1_MOSI |
| 13 | B0 | PB0 | ADC1_IN8、TIM3_CH3 |
| 14 | B1 | PB1 | ADC1_IN9、TIM3_CH4 |
| 15 | B10 | PB10 | USART3_TX、TIM2_CH3 |
| 16 | B11 | PB11 | USART3_RX、TIM2_CH4 |
| 17 | R | NRST | 复位按键（低电平有效） |
| 18 | 3.3 | +3.3 V rail | 电源 |
| 19 | G | Ground | 地 |
| 20 | G | Ground | 地 |

### 2.2 Header 2（#8：20×1 排针，Name / Connected to）

| # | 丝印 | 连接 | 常见复用（芯片级，见 #1 / #4） |
| - | ---- | ---- | ------------------------------ |
| 1 | 3.3 | +3.3 V rail | 电源 |
| 2 | G | Ground | 地 |
| 3 | 5V | +5 V rail | 电源（**与 USB +5V 直连，见 §4.2**） |
| 4 | B9 | PB9 | TIM4_CH4、I2C1_SDA（重映射） |
| 5 | B8 | PB8 | TIM4_CH3、I2C1_SCL（重映射） |
| 6 | B7 | PB7 | I2C1_SDA、TIM4_CH2 |
| 7 | B6 | PB6 | I2C1_SCL、TIM4_CH1 |
| 8 | B5 | PB5 | I2C1_SMBA、TIM3_CH2 |
| 9 | B4 | PB4 | JNTRST（SPI1_MISO 重映射） |
| 10 | B3 | PB3 | JTDO（SPI1_SCK 重映射） |
| 11 | A15 | PA15 | JTDI（SPI1_NSS 重映射） |
| 12 | A12 | PA12 | **USB D+（DP）** |
| 13 | A11 | PA11 | **USB D-（DM）** |
| 14 | A10 | PA10 | **USART1_RX** |
| 15 | A9 | PA9 | **USART1_TX** |
| 16 | A8 | PA8 | TIM1_CH1、MCO |
| 17 | B15 | PB15 | SPI2_MOSI、TIM1_CH3N |
| 18 | B14 | PB14 | SPI2_MISO、TIM1_CH2N |
| 19 | B13 | PB13 | SPI2_SCK、TIM1_CH1N |
| 20 | B12 | PB12 | SPI2_NSS、TIM1_BKIN |

### 2.3 SWD 排针与 USB 连接器（#8）

| 连接器 | # | 丝印 | 连接 |
| ------ | - | ---- | ---- |
| SWD（4×1） | 1 | 3V3 | +3.3 V rail |
| SWD（4×1） | 2 | DIO | **PA13（SWDIO）** |
| SWD（4×1） | 3 | CLK | **PA14（SWCLK）** |
| SWD（4×1） | 4 | GND | Ground |
| USB Micro | 1 | VCC | +5 V rail |
| USB Micro | 2 | D- | **PA11（USB DM）** |
| USB Micro | 3 | D+ | **PA12（USB DP）** |
| USB Micro | 4 | ID | N.C. |
| USB Micro | 5 | GND | Ground |

> **板上固定接线的宏定义**：[`Core/Inc/bluepill.h`](../../Core/Inc/bluepill.h) 用 `BP_` 前缀登记 LED、SWD、USB、USART1、BOOT1 的「信号 → 引脚」；模式 / AF / 上下拉 / 时钟一律由 `.ioc` 决定。

## 3. 引脚复用要点（芯片级，注明出处）

- **PA9 / PA10 = USART1_TX / RX**，**PA11 / PA12 = USB DM / DP**，**PA13 / PA14 = SWDIO / SWCLK**，**BOOT1 跳线接 PB2**（PLAN §2.9 归纳；USART1 / SWD 引脚与 [#8](https://stm32-base.org/boards/STM32F103C8T6-Blue-Pill.html) 排针表一致，USB 与 SWD 由 #8 连接器表直接给出）。
- **PA13 / PA14 / PA15 / PB3 / PB4** 上电默认是 JTAG/SWD 调试口；要用 PA15 / PB3 / PB4 做 GPIO 或 SPI1 重映射，须在 `.ioc` 里关闭 JTAG-DP、保留 SW-DP（见 #4 RM0008 的 AFIO_MAPR）。这不是板级事实，是芯片级约束。
- **PC13 / PC14 / PC15** 属备份域，驱动能力受限；PC13 已接板载 LED（Sink），不宜再作高速翻转或大电流输出（芯片级见 #1 / #4）。
- **PC14 / PC15** 板上对应 LSE 32.768 kHz 晶振（#8 Oscillators），是否启用由 `.ioc` 决定。
- 完整引脚复用矩阵以 **#1 DS5319** / **#4 RM0008** 官方手册为准；本表只是速查，不代替手册，也不代替 `.ioc`。

## 4. 板级硬件坑清单（6 条，逐条注明出处）

> 以下 6 条为 PLAN §2.9 归纳的板级已知坑，属自有整理；#8 页面给出其中两条的原文警告，其余注明来源层级。

### 4.1 USB D+ 上拉电阻阻值不对（10 kΩ / 4.7 kΩ vs 规范 1.5 kΩ）

- #8 原文（*Warning*）："This board may have a wrong value of resistor on the USB D+ pin. Instead of a 1.5kΩ it has either a 10kΩ or 4.7kΩ resistor. This can be solved by replacing the resistor with the right value."
- 后果：USB 全速设备靠 D+ 上拉告知主机「插入的是全速设备」，阻值不对会导致**枚举失败 / 时好时坏**；这是 Blue Pill USB 不工作最常见的硬件根因。
- 电阻在板上的**位号以 [#7 原理图](https://stm32-base.org/assets/pdf/boards/original-schematic-STM32F103C8T6-Blue_Pill.pdf) 为准**，本文件不编造位号。

### 4.2 +5V 与 USB 直连且无保护，不可同时供电

- #8 原文（*Warning*）："The +5V pins on this board are directly connected to the +5V pin of the USB connector. There is no protection in place. Do not power this board through USB and an external power supply at the same time."
- 后果：USB 与外部 5 V 同时接上会形成两路电源顶撞，**可能损坏板卡或主机 USB 口**；只选一路供电。

### 4.3 PC13 板载 LED 低电平点亮（Sink 接法）

- #8「User LED」记录：`Name PC13` / `Connected to PC13` / `Mode Sink`；即 LED 另一端接 +3.3 V，MCU 灌电流点亮。
- 后果：`HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, GPIO_PIN_RESET)` **亮**，`GPIO_PIN_SET` **灭**；写反会看到「一直灭」或「一直亮」的错觉。
- 本模板 `.ioc` 把 `PC13-TAMPER-RTC` 配为 `GPIO_Output`，`Core/Src/main.c` 用 `HAL_GPIO_TogglePin(GPIOC, GPIO_PIN_13)` 闪灯；初始电平为 `GPIO_PIN_RESET`（亮）。

### 4.4 关键信号占脚：USB / USART1 / SWD / BOOT

| 信号 | 引脚 | 说明 |
| ---- | ---- | ---- |
| USB | PA11（DM）/ PA12（DP） | #8 USB 连接器表；用 USB 时这两脚不能再作 GPIO |
| USART1 | PA9（TX）/ PA10（RX） | PLAN §2.9；本模板 `.ioc` **当前未启用 USART1**，示例见 [`examples.md`](examples.md) |
| SWD | PA13（SWDIO）/ PA14（SWCLK） | #8 SWD 排针表 + 本模板 `.ioc` 的 `SYS_JTMS-SWDIO` / `SYS_JTCK-SWCLK` |
| BOOT0 / BOOT1 | BOOT0 跳线 / PB2 跳线 | #8 Inputs；BOOT0 为芯片专用引脚，PB2 常作 BOOT1 |

> 这些占脚是「板上接线是死的」那一层语义，正是 [`bluepill.h`](../../Core/Inc/bluepill.h) 要登记的内容；**模式 / AF / 时钟由 `.ioc` 管**。

### 4.5 C8T6 64K / 128K Flash 争议

- PlatformIO 内置板卡定义 **#9** 明确写 `"name": "STM32F103C8 (20k RAM. 64k Flash)"`、`maximum_size: 65536`；#8 板卡页也标 `FLASH 64KiB / SRAM 20KiB`。
- 但社区长期有「部分 C8T6 实际有 128 KB Flash」的说法（同一 die 未做完整测试 / 未标注）。**以实测为准，不要默认按 128K 写固件**。
- 若确需按 128K 使用，在 `platformio.ini` 加 `board_build.ldscript` 指向合适的链接脚本（见 [`TEMPLATE-PLACEHOLDERS.md`](../../TEMPLATE-PLACEHOLDERS.md) B3）；派生脚本提供 `--flash 128k` 选项并提示同步该项。

### 4.6 克隆 / 兼容芯片可能导致 ST-Link 连不上

- Blue Pill 是社区兼容板，#8 标 `Brand: Unknown`，PlatformIO 板卡定义 #9 标 `"vendor": "Generic"`；ST 官方社区技术版主 Peter BENSCH（#12，2025-04-25）明确表示 ST 资源只支持正品 ST 产品，不保证克隆 / 假冒芯片能与官方固件正常工作，并锁帖。
- 后果：部分克隆芯片的 SWD IDCODE / 调试逻辑与正品不同，**ST-Link 可能连不上或读不到 ID**；先排查 SWDIO/SWCLK 是否接反、GND 共地、目标独立供电（见根级 [README 故障排查](../../README.md)），再考虑芯片本身。
- 这一条与「Blue Pill 没有官方厂商」是同一事实的两面，不得把板卡资料标成 ST 官方。

## 5. 最小系统要点（电源 / 复位 / BOOT0 / HSE / SWD）

> 本节为**自研摘要**，把芯片级官方推荐与板级实测分开写，避免把「官方推荐」误当成「Blue Pill 板卡图纸」。

### 5.1 电源

- 板级（#8）：三种供电来源（+3.3 V 引脚 / +5 V 引脚 / USB +5 V），经 TX6211B 稳压到 3.3 V；**+5 V 与 USB 直连无保护，不可同时供电**（§4.2）；VDDA / VSSA / VREF± 未单独引出。
- 芯片级（**#3 AN2586 Rev 8.0**，ST 官方应用笔记，针对 STM32F10xxx **MCU** 硬件开发，不是 Blue Pill 板卡图纸）：每个 VDD 引脚就近放去耦电容、VDDA 建议经磁珠 / 电感与 VDD 隔离并单独去耦、VREF+ 视 ADC 精度需求处理、复位与启动引脚的推荐接法、PCB 布线建议。
- **#6 MB1136 原理图**可作为 ST 官方**硬件设计范例 / 最小系统与外设接法参考**，但它**归属 NUCLEO-F103RB 板卡**（LQFP64 / STM32F103**RB** / 128 KB Flash），**不是 Blue Pill 原理图**（Blue Pill 为 LQFP48 / C8T6 / 64 KB）；见 [`README.md`](README.md) §5 与 `SOURCES.md` #6 / #6b。
- 归属提醒：AN2586 属 **STM32F103x8/B 芯片**（S1 芯片级），MB1136 属 **NUCLEO-F103RB 板卡**（另板、仅设计范例），二者都不是 Blue Pill 板级资料。

### 5.2 复位

- 板级（#8）：RESET 按键接 `NRST`，低电平有效；排针 Header 1 第 17 脚也引出 NRST。
- 芯片级（#3 AN2586）：NRST 内部已有上拉，外部按键通常配一只对地电容做去抖；具体参数以官方手册为准，本文件不编造数值。

### 5.3 BOOT0 / BOOT1

- 板级（#8）：BOOT0 为 2-way 跳线，BOOT1 跳线接 **PB2**；跳线在板上的丝印编号以 #7 / #8 为准。
- 芯片级（#1 / #4，启动模式）：BOOT0 = 0 从主 Flash 启动；BOOT0 = 1 且 BOOT1 = 0 进系统存储器（ USART1 串口下载）；BOOT1 与 BOOT0 组合决定 SRAM 启动模式。**烧录 / 调试时先确认 BOOT0 跳线在 0**，否则会出现「下载成功但不跑」。
- 注意 PB2 同时是 BOOT1，作 GPIO 前须确认启动模式不受影响。

### 5.4 时钟（HSE 8 MHz）

- 板级（#8）：板上 HSE 8 MHz、LSE 32.768 kHz；芯片内部 HSI 8 MHz、LSI 40 kHz。
- **本模板 `.ioc` 当前使用 HSI 8 MHz**（`RCC`/`SystemClock_Config()` 为 HSI、无 PLL），并非 72 MHz；切到 HSE + PLL×9 = 72 MHz 需在 CubeMX GUI 的 *RCC / Clock Configuration* 配置后重新生成（见根级 [README 工作流约定](../../README.md)）。**时钟树一律由 `.ioc` 决定**，本文件与 `bluepill.h` 都不写时钟配置。
- 芯片级（#3 AN2586）：HSE / LSE 晶振的负载电容与布线建议见官方手册；板上实际负载电容值以 #7 原理图为准，本文件不编造。

### 5.5 SWD 调试

- 板级（#8）：4-pin 排针 `3V3 / DIO(PA13) / CLK(PA14) / GND`；本模板默认探针 `stlink`，走 SWD（`platformio.ini` 的 `upload_protocol` / `debug_tool`）。
- 接线：SWDIO-PA13、SWCLK-PA14、GND 共地，目标板独立供电；换 CMSIS-DAP 时同步改 `platformio.ini` 与 `.vscode/launch.json` 的 `configFiles`（见 [`TEMPLATE-PLACEHOLDERS.md`](../../TEMPLATE-PLACEHOLDERS.md) B1）。
- 克隆芯片的连不上问题见 §4.6。

## 6. 与仓库内其它文件的对应关系

| 想知道 | 去哪里 |
| ------ | ------ |
| 逐条资料的直链 / 编号 / 许可 / 访问证据 | [`SOURCES.md`](SOURCES.md) |
| 官方 / 社区三级口径、四类入口对照表、版权与体积策略 | [`README.md`](README.md) |
| 板上固定接线的 `BP_` 宏 | [`Core/Inc/bluepill.h`](../../Core/Inc/bluepill.h) |
| 实际生效的 GPIO / 时钟 / 外设配置 | 仓库根目录的 `.ioc`（唯一事实来源，文件名由工程名决定） |
| 例程索引与适配成本 | [`examples.md`](examples.md) → [`../../examples/INDEX.md`](../../examples/INDEX.md) |
| 派生 / 改名 / Flash 容量选项 | [`TEMPLATE-PLACEHOLDERS.md`](../../TEMPLATE-PLACEHOLDERS.md) |
