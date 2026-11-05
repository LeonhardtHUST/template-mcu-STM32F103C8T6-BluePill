# 示例目录说明与统一接入流程

> **本目录是副本（2026-11-05 建立）**：`docs/bluepill/examples/` 是仓库根级 `examples/` 的**镜像副本**，
> 目的是让 `scripts/init-project.sh|ps1 --drop-examples` 删掉根级示例后，资料区
> （`docs/bluepill/examples.md` / `board-pinout.md` / `SOURCES.md`）不出现死链。
> **两处需同步、以根级为准**；`--drop-examples` 只删根级 `examples/`，**不动本副本**。
> 副本内的相对链接已按本目录层级重算（指向 `examples/` 之外的链接比根级多一～两层 `../`）。
> 改内容请改根级再整体重新镜像，不要只改副本；**重新镜像会覆盖本目录，这段说明需在镜像后贴回**
> （同步步骤与链接改写规则见 [`../examples.md`](../examples.md) §3）。

本目录是**自有示例源码 + 只读配方的整理层**：把常见外设的最小可复用代码与接入步骤写清楚，
方便往本模板（HSI 8 MHz + PC13 闪灯 + SWD 的最小骨架）里加功能。

- 本目录**不参与固件构建**：`platformio.ini` 的 `src_dir = Core/Src`，
  `examples/` 与 `test/` 都在编译范围之外。
- 本目录**不含任何第三方整包**；官方 / 社区例程只给链接，见
  [`../examples.md`](../examples.md)（资料侧索引，与本目录互指）。
- 按 Q4 拍板：**索引 + 2 个自有示例源码**，标注「仅参考、需适配」，验证等级 L1 / L2 口径，
  **不要求 `pio run`**、不触发 L3 / L4。
- 骨架 `Core/` 始终保持 CubeMX 生成的文件；任何示例的业务代码都不得覆盖生成文件，
  只能写进 `main.c` 的 `USER CODE BEGIN/END` 块（[`../AGENTS.md`](../../../AGENTS.md) §2.2）。

## 目录结构

```text
examples/
├── INDEX.md                  # 3 行总表（外设 / 复杂度 / 验证等级 / 源码 / 配方）
├── README.md                 # 本文件：统一接入路径 + 4 栏配方模板
├── recipes/                  # 只读配方，固定 4 栏
│   ├── gpio-blink.md
│   ├── usart1-115200.md
│   └── host-regression.md    # L2 主机回归（复用仓库已有 test/，不复制源码）
├── gpio-blink/               # 自有示例 1：PC13 点灯（L0）
│   ├── README.md
│   ├── blink.c
│   └── blink.h
└── usart1-115200/            # 自有示例 2：USART1 轮询回显（L0）
    ├── README.md
    ├── usart1_echo.c
    └── usart1_echo.h
```

## 统一接入路径（5 步）

所有外设配方都走同一条路，**不要跳过第 1 步直接拷 `.c`**：

1. **把外设配置抄进本仓根目录的 `.ioc`**（`Mcu.IP*` / `Mcu.Pin*` / `<Pin>.Signal` /
   `<IP>.IPParameters` 白名单一起补），然后在 CubeMX 里 `project generate`。
   首选 GUI；脚本化用 `scripts/cubemx-generate.mx`。这是 `AGENTS.md` §2.1 / §2.3 要求的变更。
2. **核验生成物（L4）**：日志 `Cannot map signal` 为 0，`OptionalMessage_ERROR` 只允许出现在
   **豁免清单**里 —— `Pin<N> (VP_RIF_VS_RIF1)` 一条，以及 DMA 导入顺序噪音
   （每个 DMA 请求块恰好 8 条 `IP (DMA) : Parameter (...) has Id (...) currently not set`）
   （门槛见 [`../../../AGENTS.md`](../../../AGENTS.md) §2.3），
   `Core/Src/main.c` 里出现对应的 `MX_xxx_Init()`。CubeMX 的错误是**静默**的（D5）。
3. **只拷源码进 `Core/`**：业务代码放进 `main.c` 的 USER CODE 块或独立用户源码，
   优先用 [`../Core/Inc/bluepill.h`](../../../Core/Inc/bluepill.h) 的 `BP_*` 宏表达板上接线；
   `Drivers/`、启动文件、`.mxproject`、Keil 样板一律丢掉。
4. **`pio run`（L3）**：记录 PlatformIO 报告的 **Flash / RAM 字节数**；
   工程源码是 `-std=c11 -Wall -Wextra -Werror`，告警会直接报错。
5. **按 L2 / L3 / L5 验证**：能主机编译的纯 C 先跑 L2（见 `recipes/host-regression.md`）；
   影响运行时行为的改动最终必须 **L5 实板**确认（LED / 串口 / 波形）。
   **「构建通过不等于能用」**——见根级 README 与 `AGENTS.md` §3。

> L2 主机回归配方是这条路径的**例外**：它不涉及外设、不改 `.ioc`、不需要 L4，
> 只跑两条 gcc 命令（见 `recipes/host-regression.md`）。

## 配方模板（固定 4 栏）

每篇配方按同样 4 栏写，按顺序读：

| 栏 | 内容 | 为什么 |
| -- | ---- | ------ |
| ① 对应 IP / 配置 | 要往根目录 `.ioc` 里抄的 `Mcu.IP*` / `Mcu.Pin*` / `<Pin>.Signal` / 参数白名单 | 决定第 1 步抄什么；白名单漏一个参数就会静默失效（D3） |
| ② 可复用文件清单 | 哪些 `.c` / `.h` 值得拷进 `Core/`，哪些是生成物 / Keil 样板要丢 | 避免把 `Drivers/`、`system_stm32f1xx.c`、`.uvprojx` 混进构建 |
| ③ 与 PlatformIO 的差异 | 例程是 CubeIDE / MDK-ARM；HAL 由 framework 提供；`CoupleFile=false` | 防止把示例目录当可构建工程跑 `pio run` |
| ④ 接入步骤 + 已知坑 | 上面 5 步的具体化，加电平 / 接线 / 生成边界的陷阱 | 让每一步都能独立复核，并落到 L3 / L5 |

## 与资料侧索引的关系

| 这边（源码侧） | 那边（资料侧） |
| -------------- | -------------- |
| [`INDEX.md`](INDEX.md) 的 3 行自有示例 | [`../examples.md`](../examples.md) 的例程索引与适配成本 |
| `recipes/` 的四栏配方 | 资料侧 §2 的 CubeIDE / MDK → PlatformIO 差异表 |
| 本目录的 `.c` / `.h` | 资料侧只有链接，不放源码原件 |

两处用相对链接互指；资料侧只存链接与索引，**原始整包例程不入库**。

## 已知坑速查

- [占位符清单 D1–D5](../../../TEMPLATE-PLACEHOLDERS.md)：`formatOnSave` 重排 `main.c`、
  `.ioc` 行尾、参数白名单、`S_` 信号前缀、生成错误静默丢弃外设。
- [工程规约 §3](../../../AGENTS.md)：L0–L5 验证关卡、「构建通过不等于能用」、两条 gcc 回归命令。
- [板级引脚定义](../../../Core/Inc/bluepill.h)：`BP_*` 只描述「信号 → 引脚」，模式 / AF / 上下拉 /
  时钟归 `.ioc` 管。
- [板卡硬件坑](../board-pinout.md)：PC13 低电平点亮、USB D+ 上拉电阻、
  +5V 与 USB 不可同时供电等 6 条。
