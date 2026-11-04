# Blue Pill 例程索引与适配成本（资料侧索引）

> 本文件是 **`docs/bluepill/` 资料生态位里的例程索引**（S3 自有），只放链接、索引与适配说明；
> **实际可直接复用的源码在仓库根级 [`examples/`](../../examples/INDEX.md)**，两处用相对链接互指。
> 原始整包例程（Keil / CubeIDE 工程、`Drivers/` 副本、`.hex`、`.uvprojx` 等）**一律不入库**。
> 逐条资料的直链、编号、许可、访问证据见 [`SOURCES.md`](SOURCES.md)。

## 0. 先说结论：三类例程，只有一类「能直接拷」

| 来源 | 层级 / 许可 | 本仓库怎么处置 | 能否直接拷源码 |
| ---- | ----------- | -------------- | -------------- |
| **#5 STM32CubeF1 Examples**（NUCLEO-F103RB） | S1 厂商官方·芯片级；STM32 Projects = ST SLA0044，basic Examples 与 HAL = BSD-3-Clause（#5b `LICENSE.md` 实测 1,642 B） | 只存官方直链索引，**不入库原件**（ST Terms of Use） | 否：面向 NUCLEO-F103RB / CubeIDE，且属另一块板（LQFP64 / F103RB / 128 KB），须逐文件判许可后适配 |
| **#11 miniwinwm/BluePillDemo** | S2 社区权威·板级；MIT（Copyright (c) 2018 John Blaiklock），作者标 `No further updates`、最后提交 2023-05-14 | 只存链接索引 | 否：CubeIDE 工程需适配 PlatformIO，已停更；如取单文件须保留 MIT 声明 |
| **根级 [`examples/`](../../examples/INDEX.md)** | **S3 本仓库自有** | **入库 2 个自有最小示例源码**（GPIO 点灯、USART1 115200） | 是：仅 `.c` / `.h` + 说明，默认可自由再分发 |

> **官方边界**：#5 是「大厂官方例程」，但针对 **NUCLEO-F103RB 评估板**，不是 Blue Pill 例程；
> #11 是社区 MIT 例程；本仓库 `examples/` 是自研源码。三者都**不得标成「ST 官方 Blue Pill 例程」**（[`README.md`](README.md) §0）。
> 按 Q4 拍板：**原始整包例程不入库**，示例标注「仅参考、需适配」，验证等级 L1 / L2，**不要求 `pio run`**、不触发 L3 / L4。

## 1. 例程索引（只存链接，逐条对齐 `SOURCES.md`）

| id | 名称 | 来源 / 层级 | 类型 | 许可与再分发 | 直链 / 位置 | 处置 |
| -- | ---- | ----------- | ---- | ------------ | ----------- | ---- |
| 5 | STM32CubeF1 官方例程（STM32F103RB-Nucleo/Examples） | ST / S1 厂商官方·芯片级 | 例程（HAL / CubeMX） | STM32 Projects = ST SLA0044；basic Examples / HAL = BSD-3-Clause；**ST Terms of Use 禁止再分发原件** | <https://github.com/STMicroelectronics/STM32CubeF1/tree/master/Projects/STM32F103RB-Nucleo/Examples> | 只存链接（Release v1.8.6，2024-08-02） |
| 5b | CubeF1 `LICENSE.md` | ST / S1 | 许可原文 | 组件许可表（实测 1,642 B） | <https://github.com/STMicroelectronics/STM32CubeF1/blob/master/LICENSE.md> | 只作许可判断引用 |
| 11 | miniwinwm/BluePillDemo | John Blaiklock / S2 社区权威·板级 | 例程（CubeIDE） | MIT，Copyright (c) 2018 John Blaiklock | <https://github.com/miniwinwm/BluePillDemo> | 只存链接索引（约 30 工程，未实测；已停更） |
| 12 | ST 社区「STM32 Blue Pill」帖 | ST 官方社区（版主发言，非产品文档） | 事实依据 | 社区内容，仅引用 | <https://community.st.com/others-hardware-and-software-57/stm32-blue-pill-63640> | 其 Best answer 指向 #11；用于说明官方立场，不是例程 |
| S3-OWN | 根级 `examples/` 自有示例 | 本仓库 / S3 自有 | GPIO 点灯、USART1 115200 + 配方 + 主机回归说明 | `self-owned` | [`../../examples/INDEX.md`](../../examples/INDEX.md) | **入库**，见 §3 |

## 2. 适配成本：CubeIDE / MDK → PlatformIO

把 #5（CubeIDE / HAL）或 #11（CubeIDE）或任何 MDK-ARM 例程搬进本模板时，成本集中在下面四类差异。

### 2.1 工具链与工程结构差异

| 项 | 外部例程（CubeIDE / MDK-ARM） | 本模板（PlatformIO + STM32CubeMX） |
| -- | ----------------------------- | ---------------------------------- |
| 工程文件 | `.ioc` + `.project` / `.cproject`，或 `.uvprojx` / `.uvoptx` | 根目录 `.ioc` + `platformio.ini`（工程名见 `README.md`） |
| 构建 | CubeIDE 自带 GCC / Keil ARMCC | `pio run`（`ststm32@20.0.0` + `framework-stm32cubef1@1.8.7` 锁定组合） |
| HAL / CMSIS / 启动文件 / 链接脚本 | 工程内自带整份 `Drivers/` | 全部由 `framework-stm32cubef1` 提供；`Drivers/**` 已在 `.gitignore` 排除 |
| 源码目录 | `Core/Src` + `Core/Inc`（`CoupleFile` 常为 true，外设初始化单独成文件） | `src_dir = Core/Src`、`include_dir = Core/Inc`；`CoupleFile=false`，`MX_xxx_Init()` 集中在 `main.c` |
| `system_stm32f1xx.c` | 参与构建 | **已从构建排除**（`build_src_filter = +<*> -<system_stm32f1xx.c>`），加回会与 framework 的 CMSIS 重复定义 |
| 编译选项 | 例程自带 | `-std=c11 -Wall -Wextra -Werror` + `--print-memory-usage` + `-Wl,-Map`（见 `platformio.ini`） |

### 2.2 哪些文件可以拷，哪些必须丢

| 文件 | 处理 | 理由 |
| ---- | ---- | ---- |
| 例程业务代码里的 `USER CODE BEGIN ... END` 段（如回调、状态机、纯 HAL API 调用） | **可拷**，放进 `main.c` 的 USER CODE 块或独立用户源码 | 与工具链无关，且符合 `AGENTS.md` §2.2「用户代码只写在 USER CODE 块内」 |
| `int __io_putchar(int ch)` / `int __io_getchar(void)` 之类的用户适配层 | **可拷** | 本模板 `Core/Src/stdio_port.c` 正是为它准备的；不要把适配逻辑写回会被 CubeMX 覆盖的 `syscalls.c` |
| 独立的算法 / 协议解析 `.c` / `.h`（不依赖 HAL） | **可拷** | 符合 `AGENTS.md` §2.8「业务逻辑与 HAL 解耦」，还能用主机 GCC 跑 L2 回归 |
| `main.c` / `main.h` / `stm32f1xx_it.c` / `stm32f1xx_hal_msp.c` / `stm32f1xx_hal_conf.h` | **不拷整文件**，只抄需要的配置思路 | 都是 CubeMX 生成物，整文件覆盖会破坏生成骨架；缺 `HAL_XXX_MODULE_ENABLED` 就在 `.ioc` 加外设再生成 |
| `gpio.c` / `usart.c` / `tim.c`（`CoupleFile=true` 才有） | **只摘参数，不整文件拷** | 本模板 `CoupleFile=false`，把参数抄进 `.ioc` 再生成即可 |
| `Drivers/**`、`startup_*.s`、`*.ld`、`system_stm32f1xx.c` | **丢掉** | framework 已提供；入库会重复定义或产生巨大体积（`AGENTS.md` §2.4） |
| `MDK-ARM/**`、`.uvprojx` / `.uvoptx` / `.hex` / `Debug/` / `Release/` | **丢掉** | Keil 样板；`.hex` / `.uvprojx` / `.uvoptx` 已被 `.gitignore` 忽略 |
| `.mxproject`、`.cproject` / `.project` | **丢掉** | 生成物元数据；本模板刻意入库自己的 `.mxproject`（相对路径、可审阅 diff），不要拿例程的覆盖 |
| PDF 原理图 / 屏幕资料 / 整包 zip | **不入库** | 版权与体积见 [`README.md`](README.md) §7；本目录禁止 `*.pdf`（#7 条件项除外）/ `*.zip` / `Drivers/` 副本 |

### 2.3 接入路径（统一 5 步，根级 `examples/README.md` 同口径）

1. **把外设配置抄进本仓根目录的 `.ioc`**（`Mcu.IP*` / `Mcu.Pin*` / `<Pin>.Signal` / `<IP>.IPParameters` 白名单一起补），CubeMX GUI 或 `scripts/cubemx-generate.mx` 生成。
2. **核验生成物**（L4）：日志无 `Cannot map` / `OptionalMessage_ERROR`，`Core/Src/main.c` 里出现对应的 `MX_xxx_Init()`（见 `AGENTS.md` §2.3 / `TEMPLATE-PLACEHOLDERS.md` D5）。
3. **只拷源码**：业务代码放进 USER CODE 块或独立 `.c` / `.h`；CubeMX 生成物、Keil 样板、`Drivers/` 一律丢。
4. **`pio run`**（L3）：记录 PlatformIO 报告的 Flash / RAM 字节数。
5. **按 L2 / L3 / L5 验证**：能主机编译的纯 C 先跑 L2；影响运行时行为的改动最终必须 L5 实板确认（LED / 串口 / 波形）——**「编译通过」不等于「能用」**。

> 注意：本模板 `.ioc` 当前是 **HSI 8 MHz + PC13 闪灯 + SWD**，未启用 USART1 / USB；
> 任何「串口 115200」「USB CDC」类示例都必须先在 `.ioc` 里加外设再生成，不能直接 `pio run` 期望它工作。

### 2.4 许可与版权注意

- #5 的 STM32 Projects 走 **ST SLA0044**、basic Examples 与 HAL 走 **BSD-3-Clause**，且 ST Terms of Use（#13）禁止未经书面许可复制 / 上传 / 再分发 → **只存直链**。
- #11 是 MIT，允许再分发但**必须保留 Copyright (c) 2018 John Blaiklock 与许可全文**；本仓库不取它的单文件，因此只需在索引里标许可。
- 从任何外部例程取单文件前，先确认该文件属于哪个许可组件，并在 `SOURCES.md` 登记来源与许可；**不确定就只留链接**。
- 本仓库自研的 `examples/` 不存在上述许可链问题，是默认推荐的可复用源码。

## 3. 与根级 `examples/` 互指

| 本文件（资料侧） | 根级（源码侧） | 关系 |
| ---------------- | -------------- | ---- |
| 本文件 §1 例程索引、§2 适配成本 | [`../../examples/INDEX.md`](../../examples/INDEX.md) | 索引里 S3-OWN 两行指向根级示例 |
| — | [`../../examples/README.md`](../../examples/README.md) | 统一接入路径、配方四栏模板、验证等级口径 |
| — | [`../../examples/recipes/`](../../examples/recipes/) | GPIO / USART1 / 主机回归三篇配方（四栏） |
| — | `../../examples/gpio-blink/`、`../../examples/usart1-115200/` | 2 个自有最小示例源码（仅 `.c` / `.h` + 说明） |
| — | [`../../test/stdio_port_test.c`](../../test/stdio_port_test.c) | 复用 A 已有的纯 C 主机回归样例（L2），**不反向搬 B 仓的复制品** |

**两边都不进 `Core/`、不改 `.ioc`、不参与固件构建**（`platformio.ini` 的 `src_dir = Core/Src`，`examples/` 与 `test/` 均在编译范围之外）。

## 4. 相关入口

- 资料总索引与官方边界：[`README.md`](README.md)
- 逐条来源 / 许可台账：[`SOURCES.md`](SOURCES.md)
- 板级引脚与硬件坑：[`board-pinout.md`](board-pinout.md)
- 工程规约（L0–L5、USER CODE 块、生成边界）：[`../../AGENTS.md`](../../AGENTS.md)
- 占位符与已知陷阱：[`../../TEMPLATE-PLACEHOLDERS.md`](../../TEMPLATE-PLACEHOLDERS.md)
