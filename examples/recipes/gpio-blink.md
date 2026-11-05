# 配方：GPIO 点灯（PC13 板载 LED）

> 对应 [`../INDEX.md`](../INDEX.md) 第 1 行，验证等级 **L0**（未验证，仅参考、需适配）。
> 源码：[`../gpio-blink/`](../gpio-blink/README.md)（S3 自研）。
> 四栏模板与统一接入路径见 [`../README.md`](../README.md)；资料侧索引见
> [`../../docs/bluepill/examples.md`](../../docs/bluepill/examples.md)。

## ① 对应 IP / 配置（抄进 `.ioc` 的内容）

GPIO 在 `.ioc` 里是**引脚级**配置，没有独立 `Mcu.IP*`。本模板**已经配好**，无需改动：

```ini
Mcu.Pin0=PC13-TAMPER-RTC
PC13-TAMPER-RTC.Locked=true
PC13-TAMPER-RTC.Signal=GPIO_Output
```

生成物 `Core/Src/main.c` 的 `MX_GPIO_Init()` 里：

```c
__HAL_RCC_GPIOC_CLK_ENABLE();
HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, GPIO_PIN_RESET);   /* 初始亮 */
GPIO_InitStruct.Pin = GPIO_PIN_13;
GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
GPIO_InitStruct.Pull = GPIO_NOPULL;
GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
```

- 板上事实：User LED 接 **PC13**、灌电流(Sink)接法、**低电平点亮**（#8 板卡页，见
  [`board-pinout.md`](../../docs/bluepill/board-pinout.md) §4.3）。
- 若手改 `.ioc` 加引脚，注意 `GPIOParameters` 白名单与 `S_` 信号前缀
  （[`TEMPLATE-PLACEHOLDERS.md`](../../TEMPLATE-PLACEHOLDERS.md) D3–D5）；本配方不需要改。

## ② 可复用文件清单（只拷源码）

| 文件 | 处理 | 理由 |
| ---- | ---- | ---- |
| [`../gpio-blink/blink.c`](../gpio-blink/blink.c) / `blink.h` | **可拷**（放进 `Core/Src` / `Core/Inc`，或加 `-I`） | 自研、只用 HAL GPIO API，与工具链无关 |
| `Core/Src/main.c` 的 USER CODE 块 | **只放调用**，不整文件拷 | 生成文件，用户代码只能写在 USER CODE 块内 |
| `Core/Inc/bluepill.h` 的 `BP_LED_GPIO_PORT` / `BP_LED_GPIO_PIN` | **用现成宏** | 避免两份「引脚真相」；接入时把示例自带默认宏换掉 |
| `Core/Src/gpio.c` / `Core/Inc/gpio.h`（外部例程才有） | 不拷 | 本模板 `CoupleFile=false`，`MX_GPIO_Init()` 集中在 `main.c` |
| `main.h` / `stm32f1xx_it.c` / `stm32f1xx_hal_msp.c` / `stm32f1xx_hal_conf.h` | 不拷 | CubeMX 覆盖生成 |
| `Drivers/**`、`startup_*.s`、`*.ld`、`system_stm32f1xx.c` | 丢掉 | framework 已提供；`system_stm32f1xx.c` 已从构建排除 |
| `.uvprojx` / `.uvoptx` / `*.hex` / MDK-ARM/ | 丢掉 | Keil 样板，已被 `.gitignore` 忽略 |

## ③ 与 PlatformIO 的差异

| 项 | 外部 CubeIDE / MDK 例程 | 本模板 |
| -- | ---------------------- | ------ |
| 构建 | CubeIDE 内建 GCC / Keil ARMCC | `pio run`（`ststm32@20.0.0` + `framework-stm32cubef1@1.8.7`，锁定组合不动） |
| HAL / CMSIS / 启动文件 / 链接脚本 | 工程自带 `Drivers/` | `framework-stm32cubef1` 提供，`Drivers/**` 不入库 |
| 源码目录 | `Core/Src` + `Core/Inc` | 同，但 `src_dir = Core/Src`；`examples/` **在编译范围之外** |
| 编译选项 | 例程自带 | `-std=c11 -Wall -Wextra -Werror` + `--print-memory-usage` + `-Wl,-Map` |

- **不要**对 `examples/gpio-blink/` 执行 `pio run`：那里没有 `platformio.ini`，也不在 `src_dir`。
- **不要**为跑本示例去改 `platformio.ini` 或 `.ioc` 的引脚/时钟（本模板已配好 PC13）。

## ④ 接入步骤 + 已知坑（统一 5 步）

1. **把外设配置抄进根目录 `.ioc`**：本配方**已配好 PC13**，跳过；若要加别的引脚才需要动 `.ioc`。
2. **生成并核验（L4）**：CubeMX GUI 或 `scripts/cubemx-generate.mx`；
   日志 `Cannot map signal` 为 0、`OptionalMessage_ERROR` 只允许豁免清单里的两类
   （`VP_RIF_VS_RIF1` 一条 + DMA 导入顺序噪音 8 条/请求块）
   （门槛见 [`AGENTS.md`](../../AGENTS.md) §2.3），`main.c` 里有 `MX_GPIO_Init()`。
3. **只拷源码**：`blink.c` / `blink.h` 拷进 `Core/`，调用写进 `main.c` 的 USER CODE 块，
   改用 `BP_LED_*` 宏；Keil 样板 / `Drivers/` 一律丢。
4. **`pio run`（L3）**：记录 PlatformIO 报告的 Flash / RAM 字节数。
5. **按 L2 / L3 / L5 验证**：本示例无可主机编译的纯 C 逻辑，L2 不适用；
   影响运行时行为，**最终必须 L5 实板**确认 LED 闪烁。「编译通过」不等于「能用」。

**已知坑**：

- PC13 **低电平点亮**（`SET` = 灭）；写反会看到「一直亮 / 一直灭」。
- PC13 属备份域、驱动能力受限，不宜带大电流 / 高速翻转。
- 编辑 `Core/**` 前关掉 `formatOnSave`（D1），且只写 USER CODE 块（§2.2）。
- 本模板当前时钟是 **HSI 8 MHz**，不是 72 MHz；`HAL_Delay()` 精度与时钟树相关。
