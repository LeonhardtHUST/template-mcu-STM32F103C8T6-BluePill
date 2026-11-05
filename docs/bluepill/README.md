# Blue Pill 板卡资料索引

> `docs/bluepill/` 是本仓库（`template-mcu-STM32F103C8T6-BluePill`，远端 `LeonhardtHUST/template-mcu-STM32F103C8T6-BluePill`）关于板卡与芯片资料的**单一权威入口**。
> 这里采用「**官方直链索引 + 三级来源标注 + 少量自有整理**」的轻量形态，**不是资料堆**：不入库厂商 PDF 原件、不入库整包例程、不入库 `Drivers/` 副本。
> 逐条资料的字段、许可判断、访问证据与失效链接，一律以 [`SOURCES.md`](SOURCES.md) 为唯一台账。

## 0. 先说结论：Blue Pill 没有「官方厂商」

Blue Pill 是社区通用板 / 兼容板，**不存在「大厂官方出品的 Blue Pill 原理图或例程」**。硬证据：

| 证据 | 原文 / 实测 |
| ---- | ----------- |
| STM32-base 板卡页（#8） | `Brand: Unknown` / `Origin: China`；名称来自 STM32duino 论坛帖、源于《黑客帝国》 |
| ST 官方社区技术版主 Peter BENSCH（#12，2025-04-25） | "This thread relates to a so-called Blue Pill, which uses illegally cloned STM32F103. ST resources are only dedicated to supporting genuine ST products. We are not committed to ensuring that clones/fakes products work properly with the firmware we provide." 并锁帖；同帖 Guru："CubeMX only has ST boards, not random third party boards." |
| PlatformIO 板卡定义（#9） | `"vendor": "Generic"` —— 板卡非 ST 官方的硬证据 |

因此「大厂官方 + 板级原理图 + 板级例程」这三个诉求**在板级无法同时满足**，必须拆开：

| 诉求 | 实际可满足的层级 | 本仓库的交付形态 |
| ---- | ---------------- | ---------------- |
| 大厂官方权威资料 | **仅 S1 芯片级** | DS5319 / RM0008 / AN2586 / STM32CubeF1 Examples 的官方直链索引（§3） |
| 含原理图 / 引脚图 | **S2 社区权威板级**（或 S3 自绘） | [`board-pinout.md`](board-pinout.md) 自研速查 + STM32-base / PinoutDB 链接，明确标注「非厂商官方」 |
| 含例程 | **S1**（ST 官方，针对 MCU / NUCLEO-F103RB）或 **S2**（BluePillDemo，MIT）或 **S3 自有** | 官方 / 社区例程只给链接；本仓库提供自有最小示例（[`examples.md`](examples.md) 与根级 `examples/`） |
| 把 datasheet 放进来 | S1，**默认只放链接，不放 PDF 原件** | §3「芯片手册」段 + `SOURCES.md` 记录 DS5319 官方直链（ST Terms of Use 禁止再分发，见 §7） |

**唯一同时满足「大厂官方 + 原理图」的是 NUCLEO-F103RB 的 MB1136，但它是另一块板**（见 §5），绝不能当作 Blue Pill 官方资料。

## 1. 来源三级分级（强制标注）

| 级别 | 名称 | 权威性与适用面 | 入库策略 | 典型条目 |
| ---- | ---- | -------------- | -------- | -------- |
| **S1** | **ST 官方 · 芯片级** | 权威最高，但**针对 MCU，不是针对 Blue Pill 板卡走线**；够得上「大厂官方」的只有这一类 | 默认 `store = link`（只存官方直链 + 文档编号）；必要时 `store = quote`（摘录必要表格 / 参数进自有文档并注明出处）。**ST 官方 PDF 一律不入库原件** | DS5319、RM0008、AN2586 Rev 8.0、STM32CubeF1 Examples v1.8.6、ST 产品页、NUCLEO-F103RB MB1136（**归属另板**） |
| **S2** | **社区权威 · 板级** | Blue Pill 板级事实（原理图 / 引脚图 / 板卡定义）的**实际来源**；不是厂商官方 | `store = link` 或 `quote`；`official_level` 必须写「社区权威·板级」，**禁止标成官方**。例外：#9 PlatformIO 板卡定义（Apache-2.0）可作资料副本 `store = file`；#7 社区原理图按 Q9 条件入库 | STM32-base 板卡页 / 原版原理图、PlatformIO `genericSTM32F103C8.json`、PinoutDB 引脚图、miniwinwm/BluePillDemo（MIT） |
| **S3** | **自有整理** | 本仓库自己绘制 / 撰写，版权归本仓库，默认可自由再分发 | `store = file` | 本目录下的 4 个 Markdown、`ATTRIBUTION.md`、自绘 SVG、根级 `examples/` 的自有示例源码 |

规则：

1. `SOURCES.md` 每条**必须**填 `tier` 与 `official_level`；本文件顶部口径与之保持一致。
2. S1 与 S2 **不得混标**：「厂商官方（芯片级）」与「社区权威（板级）」必须分开。
3. 任何 S1/S2 条目默认 `store = link`；只有 S3 与两个显式例外可 `store = file`：#9 Apache-2.0 板卡定义资料副本、#7 条件入库的社区原理图（须附 `ATTRIBUTION.md`）。
4. **STM32duino wiki 已失效**（`fetch failed` / GitHub 404），板级事实改以 STM32-base（#7 / #8）为准；失效与备选清单见 `SOURCES.md` 末节。
5. 仅存直链的条目若未核验第三方许可，`license` 填 `link-only`，**不强行给出许可结论**，避免为填字段而虚构。

**仓库级声明**：本目录的自研 Markdown 与自写源码为本仓库自有整理，其中引用的数据来自下列 S1/S2 来源并已逐条注明出处；第三方来源的入库文件（#9 / #7）在 `SOURCES.md` 中单独标许可。

## 2. 四类入口对照表

| 入口 | 权威层级 | 本仓库给什么 | 去哪里拿原件 |
| ---- | -------- | ------------ | ------------ |
| **原理图** | S1 官方（仅 NUCLEO-F103RB 范例）/ S2 社区（Blue Pill 板级） | [`board-pinout.md`](board-pinout.md) 的最小系统要点 + `SOURCES.md` 的 #6 / #7 链接；#7 条件入库副本 | ST 产品页（#6，非 Blue Pill）、stm32-base.org（#7） |
| **引脚图** | S2 社区 / S3 自有 | 自研 40-pin 速查与引脚复用表（[`board-pinout.md`](board-pinout.md)） | STM32-base 板卡页（#8）、PinoutDB（#10，图形有独立版权） |
| **datasheet** | S1 官方芯片级 | §3 的官方直链 + 文档编号 + 自研中文摘要要点 | ST 产品页 / datasheet 直链（#1 / #2 / #2b） |
| **例程** | S1 官方（NUCLEO-F103RB）/ S2 MIT 社区 / S3 自有 | [`examples.md`](examples.md) 索引 + 根级 `examples/` 的 2 个自有示例 | STM32CubeF1 Examples（#5）、BluePillDemo（#11） |

## 3. 芯片手册（S1 · 官方直链，不入库 PDF 原件）

按 Q2 / Q14 拍板：**只存官方直链 + 文档编号，不锁具体 Rev、不下载 PDF 原件**。以下链接逐字取自 `SOURCES.md` 对应条目。

| # | 资料 | 文档编号 | 官方直链 | 说明 |
| - | ---- | -------- | -------- | ---- |
| 1 | STM32F103x8/xB Datasheet | DS5319 | <https://www.st.com/resource/en/datasheet/stm32f103c8.pdf> | 用户点名的芯片 datasheet；C8 专用链接 Rev 未实测，按 Q14 不写 Rev |
| 2 | STM32F103C8 产品页 | — | <https://www.st.com/en/microcontrollers-microprocessors/stm32f103c8.html> | 可追溯最新 Rev 的官方锚点 |
| 2b | 中国站镜像 / 备选 | — | <https://www.st.com.cn/zh/microcontrollers-microprocessors/stm32f103c8.html>；datasheet 直链 <https://www.st.com.cn/resource/en/datasheet/stm32f103c8.pdf> | 中文界面、国内可达性备选 |
| 3 | AN2586 Getting started with STM32F10xxx hardware development | AN2586 Rev 8.0，2022-12-09 | <https://www.st.com/resource/en/application_note/an2586-getting-started-with-stm32f10xxx-hardware-development-stmicroelectronics.pdf> | 官方电源 / 时钟 / 复位 / 调试 / PCB 推荐；最小系统要点摘录见 `board-pinout.md` |
| 4 | RM0008 参考手册 | RM0008 / CD00171190；Rev 未核验 | <https://www.st.com/resource/en/reference_manual/rm0008-stm32f103xx-advanced-armbased-32bit-mcus-stmicroelectronics.pdf> | 寄存器级权威 |
| 5 | STM32CubeF1 官方例程 | Release v1.8.6，2024-08-02 | <https://github.com/STMicroelectronics/STM32CubeF1/tree/master/Projects/STM32F103RB-Nucleo/Examples> | 唯一「大厂官方例程」，但**归属 NUCLEO-F103RB 板**，需适配；许可见 `SOURCES.md` #5 / #5b |

> **本仓库不分发第三方原件，请点链接到原站获取。** ST Terms of Use 限制复制 / 上传 / 再分发（§7）；本机代理对 st.com 域 PDF 字节流超时，体积与 Rev 未逐页实测，台账中标「估计·未实测」的字段不得当成已实测。

## 4. 板级资料（S2 · 社区权威，非厂商官方）

| # | 资料 | 直链 / 本仓库位置 | 状态 |
| - | ---- | ----------------- | ---- |
| 7 | Blue Pill 原版原理图 | <https://stm32-base.org/assets/pdf/boards/original-schematic-STM32F103C8T6-Blue_Pill.pdf> | 按 Q9 **条件入库**（实测 151,372 B，文件头 `%PDF-1.3`），副本为本目录 `original-schematic.pdf`，须同时看 [`ATTRIBUTION.md`](ATTRIBUTION.md) |
| 8 | STM32-base 板卡页（引脚表 / 电源 / 已知坑） | <https://stm32-base.org/boards/STM32F103C8T6-Blue-Pill.html> | 只存链接 + 自研摘要（要点进 `board-pinout.md`） |
| 8b | STM32-base 站点仓库 LICENSE | <https://github.com/STM32-base/STM32-base.github.io> | MIT（Copyright (c) 2020 Thomas Gravekamp）；**站点 MIT ≠ 原理图原件版权清晰** |
| 9 | PlatformIO 板卡定义 `genericSTM32F103C8.json` | <https://github.com/platformio/platform-ststm32/blob/master/boards/genericSTM32F103C8.json> | **Apache-2.0 资料副本**，实测 1,150 B，落在本目录 `genericSTM32F103C8.json`。**仅作资料，绝不进 `boards/`、不改 `platformio.ini`** |
| 9b | PlatformIO 板卡文档页 | <https://docs.platformio.org/en/latest/boards/ststm32/genericSTM32F103C8.html> | 只存链接；`board` 用法与上传 / 调试协议 |
| 10 | PinoutDB Blue Pill 引脚图 | <https://pinoutdb.org/en/component/stm32f103c8t6-bluepill> | 只存链接；`Diagram & Layout © Oliver Weinhold`，图形不入库 |
| 11 | miniwinwm/BluePillDemo | <https://github.com/miniwinwm/BluePillDemo> | MIT（Copyright (c) 2018 John Blaiklock），已停更；只存链接索引 |
| 14 | Blue Pill 板卡实物照片 | <https://stm32-base.org/assets/img/boards/STM32F103C8T6_Blue_Pill-1.jpg> | 只存链接；实测 543,336 B，照片版权归属不明 |

**#9 许可声明**：该 JSON 来自 `platformio/platform-ststm32`（master），依 **Apache-2.0** 可再分发；原始文件本身不含版权头，来源、许可与版权归属在本文件及 `SOURCES.md` #9 条目中保留记录。它对应 `platformio.ini` 的 `board = genericSTM32F103C8`，`"vendor": "Generic"` 也是「板卡非 ST 官方」的硬证据。

## 5. 官方硬件设计范例：MB1136 属于 NUCLEO-F103RB，**不是 Blue Pill 原理图**

按 Q11 纳入索引但强警示；**只存链接、不入库 PDF 原件**。

| 项 | MB1136 / NUCLEO-F103RB | Blue Pill / STM32F103C8T6 |
| -- | ----------------------- | ------------------------- |
| 封装 | LQFP64 | LQFP48 |
| 芯片 | STM32F103**RB** | STM32F103**C8T6** |
| Flash | 128 KB | 64 KB（另有 128K 争议，见 `board-pinout.md`） |
| 归属 | ST 官方评估板 | 社区通用板，`Brand: Unknown` |

- #6 直链：<https://www.st.com/resource/en/schematic_pack/mb1136-default-c03_schematic.pdf>（另有 c04 / c05），Rev 1.0，2022-08-18
- #6b 产品页：<https://www.st.com/en/evaluation-tools/nucleo-f103rb.html>（Schematic Pack 3 份 + BOM）

在 `SOURCES.md` 中 `belongs_to = NUCLEO-F103RB 板卡`、`official_level` 标「厂商官方·芯片级（归属 NUCLEO-F103RB，非 Blue Pill）」、`notes` 带醒目提示。**禁止**在任何索引 / 注释里把它写成「Blue Pill 官方原理图」或「Blue Pill 原理图」。

## 6. 例程

| 来源 | 层级 / 许可 | 处置 |
| ---- | ----------- | ---- |
| STM32CubeF1 Examples（#5 / #5b） | S1；STM32 Projects = ST SLA0044，basic Examples 与 HAL = BSD-3-Clause（`LICENSE.md` 实测 1,642 B） | 只存链接索引；面向 NUCLEO-F103RB / CubeIDE，搬到 PlatformIO 需适配 |
| miniwinwm/BluePillDemo（#11） | S2；MIT，Copyright (c) 2018 John Blaiklock | 只存链接索引；CubeIDE 工程需适配 PIO、已停更 |
| 根级 `examples/` | S3 自有 | 2 个自有最小示例（GPIO 点灯、USART1 115200），标注「仅参考、需适配」，验证等级 L1 / L2，不触发 L3 / L4 |

**原始整包例程不入库**：不落 `Drivers/` 副本、`*.hex` / `*.uvprojx` / `*.uvoptx` / Keil 工程目录。适配成本与可拷 / 应丢的文件见 [`examples.md`](examples.md)。

## 7. 版权与降级方案

- **ST Terms of Use**（#13，<https://www.st.com/content/st_com/en/about/terms-of-use.html>）*Restrictions on use of content* 原文：`"the Materials may not be reproduced, uploaded, linked to another URL, copied, transmitted, modified, displayed or distributed in any form without ST's prior written permission"`，授权仅 `"solely for your personal use, to view and browse"`。该网页条款**无编号**、本次**未记录 HTTP 状态码**，不编造。→ **所有 ST 官方 PDF（DS5319 / RM0008 / AN2586 / MB1136 原理图）一律不入库原件**。
- **社区原理图授权链不明**：站点仓库 MIT，但 #7 原件来自第三方 vcc-gnd.com，原作者授权链不明；条件入库必须附 `ATTRIBUTION.md`。
- **图形有独立版权**：PinoutDB 引脚图标注 `Diagram & Layout © Oliver Weinhold`，只存链接。
- **例程许可需分辨**：CubeF1 `LICENSE.md` 的组件许可表、BluePillDemo 的 MIT；两者都不能整包搬运，只取明确可再分发的单文件并保留许可声明。
- `.gitattributes` 已把 `*.pdf` / `*.zip` 声明为 `binary`：入库后无法逐行审阅、无法产生可审 diff；这也是「最小模板」不收整包的原因。

默认采用的降级方案：

1. 只存官方直链 + 文档编号 / 版本 + 访问证据（`store = link`）；
2. 需要离线可用时，只把必要表格 / 参数摘录进 S3 自有文档（`store = quote`），注明出处，不复制整页扫描；
3. 例程只收 1–2 个明确可再分发的自有 / 宽松许可源码（`store = file`，仅 `.c` / `.h` + 说明）；
4. 版权存疑项一律 `store = link` 且 `license = 未验证`，并写明「本仓库不分发第三方原件，请点链接到原站获取」；
5. `docs/bluepill/` 下**禁止** `*.pdf`（条件项 #7 除外）/ `*.zip` / `*.pcbdoc` / `Drivers/` 副本 / Keil 工程目录 / `*.hex` / `*.uvprojx` / `*.uvoptx`。

`ATTRIBUTION.md` 的适用范围**仅限 #7 社区原理图**：它只解决来源与署名可追溯，**不构成 ST 要求的 `prior written permission`**，不得拿它为 MB1136 原理图或 datasheet 等 ST 官方 PDF 入库开绿灯；也不适用于用户本机的正点原子商业配套资料。

**体积硬上限**：本目录新增资料合计 **≤ 15 MB**（2026-11-04 拍板，统计口径为「本次新增且将纳入 git 跟踪的文件合计字节数」）。实际体积见 `SOURCES.md` 末尾汇总行。体积判据与版权判据相互独立，**不得以「体积没超」论证 ST 官方 PDF 可以入库原件**。

## 8. 怎么按 `SOURCES.md` 查

`SOURCES.md` 是**一行一条**的宽表，表头下紧跟字段说明，末尾有汇总行。常用查法：

- 按编号定位某条资料：`grep '^| 6 |' SOURCES.md`（MB1136），或 `grep -n 'DS5319' SOURCES.md`
- 查某条是否允许入库原件：`grep 'store = file' SOURCES.md` / 看 `redistribution` 列
- 查某个板的归属（防 MB1136 误标）：`grep 'NUCLEO-F103RB' SOURCES.md`
- 查失效链接与备选：`SOURCES.md` 末节「已失效 / 未验证项」表
- 派生到别的板卡时：`tier` / `official_level` / `belongs_to` / `url` / `doc_no` / `license` / `size_bytes` / `verified` / `access_evidence` 必须按新板卡重填，见 [`TEMPLATE-PLACEHOLDERS.md`](../../TEMPLATE-PLACEHOLDERS.md)

## 9. 本目录文件清单

| 文件 | 职责 | 来源 | 是否第三方原件 |
| ---- | ---- | ---- | -------------- |
| `README.md`（本文件） | 主索引：三级口径、四类入口、无官方厂商澄清、版权与体积策略、芯片手册直链 | S3 自有 | 否 |
| [`SOURCES.md`](SOURCES.md) | 单一权威台账：字段、逐行清单、失效项、本机限制、汇总行 | S3 自有 | 否 |
| [`board-pinout.md`](board-pinout.md) | 自研 40-pin 速查、板载资源、6 条硬件坑、最小系统要点 | S3 自有（引 S1/S2 已注明出处） | 否 |
| [`examples.md`](examples.md) | 例程索引 + 适配成本说明，与根级 `examples/` 互指 | S3 自有 | 否 |
| `genericSTM32F103C8.json` | PlatformIO 内置板卡定义的**资料副本**（Apache-2.0） | S2（#9） | 是（唯一推荐入库的非自有原件） |
| `original-schematic.pdf` | #7 社区原版原理图，按 Q9 条件入库 | S2（#7） | 是（条件入库，授权链存疑） |
| [`ATTRIBUTION.md`](ATTRIBUTION.md) | #7 的来源 / 直链 / 下载日期 / 版权状态 / 使用范围 | S3 自有 | 否 |
| [`examples/`](examples/README.md) | 根级 `examples/` 的镜像副本（2 个自有示例 + 3 篇配方），`--drop-examples` 不影响 | S3 自有 | 否 |

体积实测、许可与访问证据见 `SOURCES.md`。

## 10. 本机限制与失效链接（摘要）

- 代理对 `www.st.com` / `www.st.com.cn` 的 PDF 字节流持续超时（HTTP=000、0 bytes；`-I` 只拿到 `HTTP/1.1 200 Connection established` 隧道）；Windows curl 另有 schannel 吊销报错（用 `--ssl-no-revoke` 规避）。因此 #1 / #3 / #4 / #6 的体积与 Rev **未逐页实测**，台账标「估计·未实测」；`application/pdf` 仅证明链接有效，不代表已下载校验内容。
- st.com 域 PDF 建议浏览器直连或换网络下载；`stm32-base.org` / `raw.githubusercontent.com` 的 #7 / #9 在本实施轮已实测下载成功（HTTP=200，字节数与台账一致）。
- STM32duino wiki 与 reblag.dk 等 6 条失效 / 未验证直链及其备选见 `SOURCES.md` 末节，**不得作为可入库直链**。
