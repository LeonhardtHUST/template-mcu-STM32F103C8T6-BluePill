# 示例：USART1 115200 轮询回显

> **仅参考、需适配**｜**验证等级 L0（未验证）**｜本仓库自研（S3 自有，可自由再分发）
>
> 本目录**不进 `Core/`、不改 `.ioc`、不参与固件构建**，按 Q4 拍板**不要求 `pio run`**。
> **重要前提**：本模板 `.ioc` 当前**未启用 USART1**，用本示例前必须按
> [`../recipes/usart1-115200.md`](../recipes/usart1-115200.md) 的第 1~2 步先在 CubeMX 里配置并生成。

## 文件

| 文件 | 说明 |
| ---- | ---- |
| `usart1_echo.h` | 两个 API：`usart1_echo_poll_byte()` 收 1 字节并回显；`usart1_send_string()` 发字符串 |
| `usart1_echo.c` | 只用 HAL UART 轮询 API；不绑定全局句柄名，句柄由调用方传入 |

## 参数与接线（依据）

| 项 | 值 | 出处 |
| -- | -- | ---- |
| 波特率 / 帧格式 | 115200 / 8N1 / 异步 | 示例约定；**实际由 `.ioc` 决定** |
| TX / RX | PA9 / PA10 | PLAN §2.9；[`board-pinout.md`](../../docs/bluepill/board-pinout.md) §4.4 |
| 板级宏 | `BP_USART1_TX_*` / `BP_USART1_RX_*` | [`Core/Inc/bluepill.h`](../../Core/Inc/bluepill.h) |
| 当前时钟 | HSI 8 MHz | 本模板 `.ioc`；波特率精度依赖时钟树，切 HSE/PLL 后须重新核对 |

## 最小接入示意（先在 CubeMX 启用 USART1 并生成）

```c
/* main.c -> USER CODE BEGIN Includes */
#include "usart1_echo.h"    /* 拷进 Core/Inc/ 或加 -I 指向 examples/usart1-115200/ */

/* main.c -> USER CODE BEGIN 2（huart1 由 MX_USART1_UART_Init() 生成） */
extern UART_HandleTypeDef huart1;
uint8_t io_buf[1] = {0};
usart1_send_string(&huart1, "USART1 115200 ready\r\n", 100U);

/* main.c -> USER CODE BEGIN 3（在 while(1) 内，非阻塞轮询） */
(void)usart1_echo_poll_byte(&huart1, io_buf, 10U);
```

> `usart1_echo_poll_byte()` 超时返回 0（没有数据，主循环继续），不要把它写成死等；
> 需要中断 / DMA / printf 重定向时另立文件，不要在 CubeMX 生成物里改。

## 已知坑

- **没在 `.ioc` 启用 USART1 就编译**：`huart1` 不存在、`MX_USART1_UART_Init()` 不生成；
  CubeMX 对手改 `.ioc` 的错误是**静默**的，必须核验日志无 `Cannot map`（`AGENTS.md` §2.3 / D5）。
- **PA9/PA10 被占用**：这两脚也是 USB/其它复用的邻区，接线前查 `board-pinout.md` §2.2。
- **TX/RX 接反、忘了共地**：USB 转串口要交叉接 TX↔RX、RX↔TX、GND↔GND。
- **波特率不准**：当前是 HSI 8 MHz，切到 HSE + PLL 72 MHz 后重新核对 USART 分频。
- **printf 浮点**：newlib-nano 默认不含 `%f`，需要时在 `platformio.ini` 里启
  `-Wl,-u,_printf_float`（会增加 Flash/RAM），与 UART 初始化是两件事。
- **编译通过不等于能用**：串口是否真有波形 / 字符，必须 L5 实板确认。

## 互指

- 配方（四栏 + 5 步接入）：[`../recipes/usart1-115200.md`](../recipes/usart1-115200.md)
- 总索引：[`../INDEX.md`](../INDEX.md) ｜ 说明与统一接入路径：[`../README.md`](../README.md)
- 资料侧例程索引：[`../../docs/bluepill/examples.md`](../../docs/bluepill/examples.md)
