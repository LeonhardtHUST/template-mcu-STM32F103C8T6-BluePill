# examples 总索引

本表是**本仓库自有示例**（S3 自有）的索引，按 Q4 拍板只有 2 个可复用源码 + 1 个就地复用的
主机回归样例；**原始整包例程不入库**（官方 / 社区例程只给链接，见
[`../examples.md`](../examples.md)）。

- **复杂度**：低 = 单个外设；中 = 多个外设 / 中断 / DMA；高 = 协议栈 / RTOS / 多层中间件。
- **验证等级**：沿用 [`../AGENTS.md`](../../../AGENTS.md) §3 的 L0–L5 口径。
  两个自有示例**未经本模板编译、未上板**，默认 **L0（未验证）**，标注「仅参考、需适配」；
  主机回归样例复用仓库已有的 `test/`，可跑两条 gcc 命令，标 **L2**。
  接入后请自行补 **L3（pio run）** 与 **L5（实板）**。
- 所有示例都**不进 `Core/`、不改 `.ioc`、不参与固件构建**（`src_dir = Core/Src`），
  按 Q4 **不要求 `pio run`**、不触发 L3 / L4。

| # | 示例 | 对应外设 / 内容 | 复杂度 | 验证等级 | 源码 | 配方 |
| - | ---- | --------------- | ------ | -------- | ---- | ---- |
| 1 | GPIO 点灯（PC13 板载 LED，低电平点亮） | `GPIO_Output`；PC13 | 低 | **L0**（未验证，仅参考、需适配） | [`gpio-blink/`](gpio-blink/README.md) | [`recipes/gpio-blink.md`](recipes/gpio-blink.md) |
| 2 | USART1 115200 轮询回显 | `USART1`；PA9 / PA10；115200 8N1 | 低 | **L0**（未验证，仅参考、需适配） | [`usart1-115200/`](usart1-115200/README.md) | [`recipes/usart1-115200.md`](recipes/usart1-115200.md) |
| 3 | 纯 C 主机回归（复用仓库已有 `test/`） | 无外设；`_read` / `_write` 适配层 | 低 | **L2**（主机回归，两条 gcc 命令） | [`../test/stdio_port_test.c`](../../../test/stdio_port_test.c) + [`../Core/Src/stdio_port.c`](../../../Core/Src/stdio_port.c)（**就地复用，不复制**） | [`recipes/host-regression.md`](recipes/host-regression.md) |

## 两个要留意的地方

- **USART1 示例的前提**：本模板 `.ioc` 当前**未启用 USART1**（只配了 PC13 + SWD + HSI 8 MHz）。
  按配方的第 1~2 步先在 CubeMX GUI 启用并生成，再谈接入；不要直接 `pio run` 期望它工作。
- **主机回归样例是源头，不是复制品**：`test/stdio_port_test.c` 与 `Core/Src/stdio_port.c`
  本来就在 A 仓库里，不搬 B 仓 `examples/stdio_port/` 的复制品，避免两份重复、两套路径。

## 怎么用

1. 先看 [`README.md`](README.md) 的「统一接入路径（5 步）」与「配方模板（4 栏）」。
2. 按配方逐项核对，**别整目录拷**；用户代码只写进 `main.c` 的 USER CODE 块。
3. 资料侧（例程索引与适配成本）看 [`../examples.md`](../examples.md)，
   两处用相对链接互指。
4. 补充本章节之外的验证等级定义与两条 gcc 回归命令，见 [`../AGENTS.md`](../../../AGENTS.md) §3。

> 本目录是**可选资料**：整目录删除不影响固件构建，也不会触碰 `docs/bluepill/` 的资料台账。
> 删除后请顺手清掉根级 README「examples」章节里指向本目录的链接，避免死链。
