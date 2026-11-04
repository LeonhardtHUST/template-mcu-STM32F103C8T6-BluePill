# 示例：GPIO 点灯（PC13 板载 LED）

> **仅参考、需适配**｜**验证等级 L0（未验证）**｜本仓库自研（S3 自有，可自由再分发）
>
> 本目录**不进 `Core/`、不改 `.ioc`、不参与固件构建**（`platformio.ini` 的 `src_dir = Core/Src`），
> 按 Q4 拍板**不要求 `pio run`**，接入前请按 [`../recipes/gpio-blink.md`](../recipes/gpio-blink.md)
> 的 5 步流程自行补 L3（构建）与 L5（实板）。

## 文件

| 文件 | 说明 |
| ---- | ---- |
| `blink.h` | 三个 API：`blink_init()` / `blink_toggle()` / `blink_set(uint8_t on)` |
| `blink.c` | 只用 HAL GPIO API；PC13 推挽输出，灌电流(Sink)接法，低电平点亮 |

## 板上依据

| 项 | 值 | 出处 |
| -- | -- | ---- |
| LED 引脚 | PC13 | 本模板 `.ioc`（`PC13-TAMPER-RTC.Signal=GPIO_Output`）；#8 板卡页 `User LED: PC13` |
| 点亮电平 | **低电平（RESET）亮，高电平（SET）灭** | #8 板卡页 `Mode Sink`；[`board-pinout.md`](../../docs/bluepill/board-pinout.md) §4.3 |
| 当前时钟 | HSI 8 MHz（未启用 PLL，非 72 MHz） | 本模板 `.ioc` / `SystemClock_Config()` |

## 最小接入示意（**不要直接照抄进生成文件之外的地方**）

`.ioc` 已经把 PC13 配成 `GPIO_Output`，`Core/Src/main.c` 的 USER CODE 3 段已有
`HAL_GPIO_TogglePin(GPIOC, GPIO_PIN_13)` + `HAL_Delay(500)`。若想改用本示例：

```c
/* main.c -> USER CODE BEGIN Includes */
#include "blink.h"          /* 拷进 Core/Inc/ 或加 -I 指向 examples/gpio-blink/ */

/* main.c -> USER CODE BEGIN 2 */
blink_init();

/* main.c -> USER CODE BEGIN 3（在 while(1) 内） */
blink_toggle();
HAL_Delay(500);
```

接入时建议把 `blink.c` 里的 `BLINK_LED_GPIO_PORT` / `BLINK_LED_GPIO_PIN` 换成
[`Core/Inc/bluepill.h`](../../Core/Inc/bluepill.h) 的 `BP_LED_GPIO_PORT` / `BP_LED_GPIO_PIN`，
避免两份「引脚真相」各写一遍。

## 已知坑

- **写反电平**：PC13 是低电平点亮，`SET` 是灭；若看到「一直亮 / 一直灭」，先查这里。
- **PC13 驱动能力受限**：属备份域，不宜带大电流负载或高速翻转（芯片级见 DS5319 / RM0008）。
- **`Core/` 生成边界**：用户代码只能写在 `USER CODE BEGIN/END` 块内，否则下次生成被覆盖
  （[`AGENTS.md`](../../AGENTS.md) §2.2）。编辑 `Core/**` 前留意 `formatOnSave`（D1）。
- **编译通过不等于能用**：闪灯是否真在板子上跑，必须 L5 实板确认。

## 互指

- 配方（四栏 + 5 步接入）：[`../recipes/gpio-blink.md`](../recipes/gpio-blink.md)
- 总索引：[`../INDEX.md`](../INDEX.md) ｜ 说明与统一接入路径：[`../README.md`](../README.md)
- 资料侧例程索引：[`../../docs/bluepill/examples.md`](../../docs/bluepill/examples.md)
