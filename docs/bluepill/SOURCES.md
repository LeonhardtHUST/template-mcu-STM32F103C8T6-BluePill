# Blue Pill 资料来源台账（SOURCES.md）

> **单一权威台账**：`docs/bluepill/` 下每一条资料的来源分级、归属、许可、入库判定与访问证据都在这里登记。
> 一行一条、宽表、可 `grep`（例如 `grep -n 'DS5319' SOURCES.md`、`grep -n 'NUCLEO-F103RB' SOURCES.md`）。
> 主索引（三级口径、四类入口、版权与体积策略）见 [`README.md`](README.md)；
> 条件入库原件的归属声明见 [`ATTRIBUTION.md`](ATTRIBUTION.md)（**适用范围仅限 #7**）。
> 本仓库（`template-mcu-STM32F103C8T6-BluePill`，远端 `LeonhardtHUST/template-mcu-STM32F103C8T6-BluePill`）
> 不分发第三方原件，请点链接到原站获取。

## 0. 字段说明（表头下紧跟；每行必填，不留空）

| 字段 | 含义 |
| ---- | ---- |
| `id` | 沿用 §2.7 的编号 `1` / `2` / `2b` … `14`，按 id 增补校正、**不重编号**；自研文件统一 `S3-OWN` 组 |
| `tier` | `S1`（ST 官方·芯片级）/ `S2`（社区权威·板级）/ `S3`（自有整理） |
| `official_level` | `厂商官方·芯片级` / `社区权威·板级` / `ST 官方社区（版主发言，非产品文档）` / `自有整理`；S1 与 S2 **不得混标** |
| `title` | 资料名称 |
| `doc_no` | 文档编号 / 版本；无则 `—`。按 Q14 只记编号 + 官方动态链接，**不锁具体 Rev** |
| `belongs_to` | 归属对象（防 MB1136 误标而设）：`STM32F103x8/B 芯片` / `Blue Pill 板卡` / `NUCLEO-F103RB 板卡` / `本仓库自有` |
| `covers` | 覆盖类型：`原理图` / `引脚图` / `datasheet` / `例程` / `最小系统` / `板卡定义` / `许可·法务` |
| `publisher` | 发布方 |
| `url` | S1/S2 填官方直链（逐字照抄 PM 清单）；S3 填仓库内相对路径；**失效项不得作为可入库直链** |
| `license` | 许可判断：ST Terms of Use / SLA0044 / BSD-3-Clause / Apache-2.0 / MIT / `© Oliver Weinhold` / `self-owned` / `未验证` / `link-only`（仅存链接且未核验第三方许可时填，避免虚构结论） |
| `redistribution` | 是否允许入库原件：`不允许` / `仅摘录` / `条件允许` / `允许` / `自有` / `未验证` |
| `store` | `link`（只存链接）/ `quote`（摘录进自研文档并注明出处）/ `file`（入库原件）。**仅 S3 + #9 + #7 可为 `file`** |
| `local_path` | 仅 `store = file` 时填；其余填 `—`。`genericSTM32F103C8.json` 必须在 `docs/bluepill/`，**绝不进 `boards/`** |
| `size_bytes` | 实测字节数；**`store = link` 一律 `0`**（实测字节数记在 `access_evidence`）。#7 = 151372、#9 = 1150 |
| `verified` | `已核验` / `未验证` / `估计·未实测` |
| `verified_on` | 核验日期与方式；未核验填 `—（原因）` |
| `access_evidence` | HTTP 状态 / `Content-Type` / 页面标题 / 下载字节数；按 Q10 **保留访问证据** |
| `fallback` | 失效 / 未验证项的备选直链或检索方式；正常条目填 `—` |
| `attribution` | 条件入库（#7）指向 `ATTRIBUTION.md`；其余填 `—` |
| `notes` | 易误导点、体积估计、许可链说明 |

### 核验证据口径（Q10 已拍板保留）

- **「PM 2026-11-04 记录（沿用、本轮未二次核验）」**：PM 经 `127.0.0.1:7897` 代理实测得到的直链 / 页面标题 / HTTP 状态 / 下载字节数，本实施轮**沿用记录、未对这些链接做二次核验**，不得写成「本轮已实测」。
- **「本实施轮实测下载」**：主理人在本实施轮前置阶段实际下载并落盘的 **#7**（`original-schematic.pdf`，HTTP=200、151,372 B、`%PDF-1.3`）与 **#9**（`genericSTM32F103C8.json`，HTTP=200、1,150 B、`text/plain`）；本实施轮另用 WebFetch 复核了 **#8** 板卡页并取得 40-pin 引脚表（见 #8 行）。
- 标「估计·未实测」的体积与 Rev **一律照实保留**，不得写成已实测；`application/pdf` 仅证明链接有效，不代表已下载校验内容。
- **本台账仅作索引落位与许可判断记录，不构成入库授权**。

---

## 1. 权威资料清单（19 条，逐条对应 §2.7）

| id | tier | official_level | title | doc_no | belongs_to | covers | publisher | url | license | redistribution | store | local_path | size_bytes | verified | verified_on | access_evidence | fallback | attribution | notes |
| -- | ---- | -------------- | ----- | ------ | ---------- | ------ | --------- | --- | ------- | -------------- | ----- | ---------- | ---------- | -------- | ----------- | ---------------- | -------- | ----------- | ----- |
| 1 | S1 | 厂商官方·芯片级 | STM32F103x8/xB Datasheet | DS5319（按 Q14 只记编号，不锁 Rev） | STM32F103x8/B 芯片 | datasheet | STMicroelectronics | `https://www.st.com/resource/en/datasheet/stm32f103c8.pdf` | ST Terms of Use | 不允许 | link | — | 0 | 估计·未实测 | —（本机代理对 st.com PDF 字节流超时，体积与 Rev 未逐页实测） | PM 2026-11-04 记录（沿用、本轮未二次核验）：WebFetch 返回 `Content-Type: application/pdf` | 浏览器直连或换网络下载；中国站 #2b 的 datasheet 直链 | — | 用户点名的芯片 datasheet，权威必链；按 Q2 只存链接 + 自研摘要，**不入库 PDF 原件**；体积估计 2–3 MB，未实测 |
| 2 | S1 | 厂商官方·芯片级 | STM32F103C8 产品页 | —（标题实测） | STM32F103x8/B 芯片 | datasheet（文档入口） | STMicroelectronics | `https://www.st.com/en/microcontrollers-microprocessors/stm32f103c8.html` | ST Terms of Use | 不允许 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验） | WebFetch 200，标题 `STM32F103C8 \| Product - STMicroelectronics` | 中国站 #2b | — | 可追溯最新 Rev 的官方锚点；按 Q14 不锁 Rev |
| 2b | S1 | 厂商官方·芯片级 | 同上中国站镜像 + datasheet 直链 | —（标题实测） | STM32F103x8/B 芯片 | datasheet（备选直链） | STMicroelectronics | `https://www.st.com.cn/zh/microcontrollers-microprocessors/stm32f103c8.html` ; `https://www.st.com.cn/resource/en/datasheet/stm32f103c8.pdf` | ST Terms of Use | 不允许 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验） | WebFetch 200，标题 `STM32F103C8 \| 产品 - 意法半导体`；datasheet 直链返回 `application/pdf` | 作为 #1 的备选；浏览器直连 | — | 中文界面、国内可达性备选；PDF 体积未实测，不入库 |
| 3 | S1 | 厂商官方·芯片级 | AN2586 Getting started with STM32F10xxx hardware development | AN2586 Rev 8.0 / 2022-12-09（产品页所列；PDF 未逐页实测） | STM32F103x8/B 芯片 | 最小系统 | STMicroelectronics | `https://www.st.com/resource/en/application_note/an2586-getting-started-with-stm32f10xxx-hardware-development-stmicroelectronics.pdf` | ST Terms of Use | 不允许 | link | — | 0 | 估计·未实测 | —（本机代理对 st.com PDF 字节流超时，体积未逐页实测） | PM 2026-11-04 记录（沿用、本轮未二次核验）：WebFetch `application/pdf`；产品页列 Rev 8.0 | 浏览器直连或换网络下载 | — | 官方电源 / 时钟 / 复位 / 调试 / PCB 推荐；`board-pinout.md` §5 摘录并注明**芯片级**归属；体积估计 1–2 MB，未实测 |
| 4 | S1 | 厂商官方·芯片级 | RM0008 参考手册 | RM0008 / CD00171190；Rev 未核验 | STM32F103x8/B 芯片 | datasheet（参考手册） | STMicroelectronics | `https://www.st.com/resource/en/reference_manual/rm0008-stm32f103xx-advanced-armbased-32bit-mcus-stmicroelectronics.pdf` | ST Terms of Use | 不允许 | link | — | 0 | 估计·未实测 | —（本机代理对 st.com PDF 字节流超时，体积与 Rev 未实测） | PM 2026-11-04 记录（沿用、本轮未二次核验）：WebFetch `application/pdf` | 浏览器直连或换网络下载 | — | 寄存器级权威，体积估计 8–12 MB，未实测；不入库 |
| 5 | S1 | 厂商官方·芯片级 | STM32CubeF1 官方例程（STM32F103RB-Nucleo/Examples） | Release v1.8.6 / 2024-08-02 | NUCLEO-F103RB 板卡 | 例程 | STMicroelectronics | `https://github.com/STMicroelectronics/STM32CubeF1/tree/master/Projects/STM32F103RB-Nucleo/Examples` | SLA0044（STM32 Projects）/ BSD-3-Clause（basic Examples、HAL） | 仅摘录 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验） | WebFetch 200，标题 `STM32CubeF1/Projects/STM32F103RB-Nucleo/Examples at master · STMicroelectronics/STM32CubeF1 · GitHub` | #11 BluePillDemo（MIT 社区例程）/ 本仓库自有 `examples/` | — | 唯一「大厂官方例程」，但**归属 NUCLEO-F103RB 板**、需适配，不是 Blue Pill 例程；仓库用 git submodule，ZIP 不含 submodule；组件许可见 #5b |
| 5b | S1 | 厂商官方·芯片级 | CubeF1 `LICENSE.md` 许可原文 | —（组件许可表） | STM32F103x8/B 芯片 | 许可·法务 | STMicroelectronics | `https://github.com/STMicroelectronics/STM32CubeF1/blob/master/LICENSE.md` | SLA0044 / BSD-3-Clause 组件许可表 | 仅摘录 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验） | curl 代理 HTTP=200，`text/plain`，**实测 1,642 B**（仅索引引用，未入库，故 size_bytes=0） | — | — | 判断能否再分发；CubeF1 仓库根目录许可，非 Blue Pill 板级资料 |
| 6 | S1 | 厂商官方·芯片级（归属 NUCLEO-F103RB，非 Blue Pill） | NUCLEO-F103RB 官方原理图 MB1136 | MB1136 Rev 1.0 / 2022-08-18（另有 c04 / c05） | **NUCLEO-F103RB 板卡** | 原理图 | STMicroelectronics | `https://www.st.com/resource/en/schematic_pack/mb1136-default-c03_schematic.pdf` | ST Terms of Use | 不允许 | link | — | 0 | 估计·未实测 | —（本机代理对 st.com PDF 字节流超时，体积未逐页实测） | PM 2026-11-04 记录（沿用、本轮未二次核验）：WebFetch `application/pdf`；产品页 #6b 列 Schematic Pack | 浏览器直连；#6b 产品页 Schematic Pack | — | **⚠ MB1136 不是 Blue Pill 原理图**；LQFP64 / STM32F103**RB** / 128 KB，与 Blue Pill 的 LQFP48 / C8T6 / 64 KB 不同。按 Q11 纳入但强警示，**只存链接、不入库 PDF 原件**；`ATTRIBUTION.md` 不适用于本条；体积估计 0.2–1 MB，未实测 |
| 6b | S1 | 厂商官方·芯片级（归属 NUCLEO-F103RB，非 Blue Pill） | NUCLEO-F103RB 产品页 | Schematic Pack 3 份 + BOM | **NUCLEO-F103RB 板卡** | 原理图（资料入口） | STMicroelectronics | `https://www.st.com/en/evaluation-tools/nucleo-f103rb.html` | ST Terms of Use | 不允许 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验） | WebFetch 200，标题 `NUCLEO-F103RB \| Product - STMicroelectronics` | — | — | 官方原理图可追溯锚点；**另一块板，仅作官方硬件设计范例**；禁止写成「Blue Pill 官方原理图」 |
| 7 | S2 | 社区权威·板级 | Blue Pill 原版原理图 | 文件名标 `original`；文件头 `%PDF-1.3` | Blue Pill 板卡 | 原理图 | STM32-base project | `https://stm32-base.org/assets/pdf/boards/original-schematic-STM32F103C8T6-Blue_Pill.pdf` | 未验证（站点 MIT；原件来自第三方 vcc-gnd.com / 板厂，原作者授权链不明） | 条件允许 | **file** | `docs/bluepill/original-schematic.pdf` | **151372** | 已核验 | **2026-11-04 本实施轮实测下载**（curl 代理 HTTP=200 / `application/pdf` / 151,372 B / 文件头 `%PDF-1.3`），PM 2026-11-04 记录沿用 | 本实施轮实测下载 HTTP=200，`application/pdf`，151,372 B，落盘字节数与台账一致；站点来源页见 #8 | 若上游要求移除则退回「只存链接」模式，见 `ATTRIBUTION.md` | **`ATTRIBUTION.md`**（站点 MIT / 原件版权未核实 / 仅非商业学习 / 上游可要求移除） | 按 Q9 **条件入库**；板级原理图社区权威来源，**不是厂商官方**；`ATTRIBUTION.md` 适用范围**仅限本条**，不构成 ST 要求的 `prior written permission`，不得为 ST PDF 或正点原子资料开绿灯 |
| 8 | S2 | 社区权威·板级 | Blue Pill 板卡页（引脚表 / 电源 / 已知坑） | —（标题实测） | Blue Pill 板卡 | 引脚图 / 最小系统 | STM32-base project | `https://stm32-base.org/boards/STM32F103C8T6-Blue-Pill.html` | MIT（站点源码；文字宜自研整理并注明出处） | 仅摘录 | quote | — | 0 | 已核验 | **2026-11-04 本实施轮 WebFetch 复核**（标题与 40-pin 引脚表一致）；PM 2026-11-04 记录沿用 | WebFetch 200，标题 `STM32F103C8T6 - Blue Pill \| STM32-base project`；本实施轮复核取得 20+20 引脚表、SWD/USB 引脚、电源、`Brand: Unknown / Origin: China`、USB D+ 电阻与 +5V 警告，落进 `board-pinout.md` | #7 原理图 / #10 PinoutDB | — | 「无官方厂商」直接证据；板级事实以本条 + #7 为准；**自研摘要进 `board-pinout.md`，不复制整页** |
| 8b | S2 | 社区权威·板级 | STM32-base 站点仓库 LICENSE | MIT（Copyright (c) 2020 Thomas Gravekamp） | Blue Pill 板卡 | 许可·法务 | STM32-base project | `https://github.com/STM32-base/STM32-base.github.io` | MIT | 仅摘录 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验） | WebFetch 200 标 `MIT license`；curl raw **实测 1,073 B**（仅索引引用，未入库，故 size_bytes=0） | — | — | MIT 覆盖站点源码，**未必覆盖第三方原理图原件**（#7 授权链存疑）；判断 #7/#8 可否入库的依据 |
| 9 | S2 | 社区权威·板级（PlatformIO 官方维护自身库，非 ST 官方） | PlatformIO 板卡定义 `genericSTM32F103C8.json` | master；`mcu stm32f103c8t6` / `cortex-m3` / `64K Flash, 20K RAM` / `openocd_target stm32f1x` / `"vendor": "Generic"` | Blue Pill 板卡 | 板卡定义 | PlatformIO | `https://github.com/platformio/platform-ststm32/blob/master/boards/genericSTM32F103C8.json` ; raw `https://raw.githubusercontent.com/platformio/platform-ststm32/master/boards/genericSTM32F103C8.json` | Apache-2.0（保留版权 / 许可声明即可再分发） | 允许 | **file** | `docs/bluepill/genericSTM32F103C8.json` | **1150** | 已核验 | **2026-11-04 本实施轮实测下载**（curl raw HTTP=200 / `text/plain` / 1,150 B），PM 2026-11-04 记录沿用 | 本实施轮实测下载 HTTP=200，`text/plain`，1,150 B，落盘字节数与台账一致 | #9b PlatformIO 文档页 | —（Apache-2.0 许可与版权归属在 `README.md` §4 及本行保留记录） | 与 `platformio.ini` 的 `board = genericSTM32F103C8` 直接对应；`vendor: Generic` 是板卡非 ST 官方硬证据；**仅作资料副本，绝不进 `boards/`、不改 `platformio.ini`**；原始文件不含版权头 |
| 9b | S2 | 社区权威·板级（PlatformIO 官方维护自身库，非 ST 官方） | PlatformIO 板卡文档页 | —（标题实测） | Blue Pill 板卡 | 板卡定义（文档） | PlatformIO | `https://docs.platformio.org/en/latest/boards/ststm32/genericSTM32F103C8.html` | link-only（文档站自有版权，未核验第三方许可结论） | 不允许 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验） | WebFetch 200，标题 `STM32F103C8 (20k RAM. 64k Flash) — PlatformIO latest documentation` | #9 板卡定义资料副本 | — | `board` 用法、上传 / 调试协议；只存链接 |
| 10 | S2 | 社区权威·板级 | PinoutDB Blue Pill 引脚图 | —（标题实测） | Blue Pill 板卡 | 引脚图 | PinoutDB | `https://pinoutdb.org/en/component/stm32f103c8t6-bluepill` | `© Oliver Weinhold`（`Diagram & Layout`，图形有独立版权）；图未实测 | 不允许 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验；页面已核验，图形未实测） | WebFetch 200，标题 `STM32F103C8T6 'Blue Pill' Board Pinout & Pin Reference \| PinoutDatabase` | #8 STM32-base 板卡页 / #7 原理图 | — | 40-pin 引脚表完整，是已失效 reblag.dk 引脚图的备选；**图形不入库**；个人站点，社区权威而非厂商官方 |
| 11 | S2 | 社区权威·板级 | miniwinwm/BluePillDemo | 作者标 `No further updates`；最后提交 2023-05-14 | Blue Pill 板卡 | 例程 | John Blaiklock | `https://github.com/miniwinwm/BluePillDemo` | MIT（Copyright (c) 2018 John Blaiklock，保留声明即可再分发） | 仅摘录 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验；整仓约 30 工程未实测） | WebFetch 200，标题 `GitHub - miniwinwm/BluePillDemo: A collection of small example projects tailored for the Blue Pill board created in STM32CubeIDE. No further updates.` | #5 CubeF1 官方例程 / 本仓库自有 `examples/` | — | ST 官方社区帖 Best answer 推荐；含 ADC/CAN/EXTI/Flash/FreeRTOS/I2C/PWM/SPI/OLED/UART；CubeIDE 工程需适配 PlatformIO、已停更；**只存链接索引**，不整包搬运 |
| 12 | S1 | ST 官方社区（版主发言，非产品文档） | ST 社区「STM32 Blue Pill」帖 | 版主 Peter BENSCH 2025-04-25 | Blue Pill 板卡 | 许可·法务（官方立场事实依据） | ST 官方社区 | `https://community.st.com/others-hardware-and-software-57/stm32-blue-pill-63640` | link-only（社区内容，仅引用） | 不允许 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验） | WebFetch 200，标题 `STM32 Blue Pill \| Community` | — | — | 官方立场铁证（ST 不支持克隆 / 假冒芯片、CubeMX 只有 ST 板），并锁帖；Best answer 指向 #11；**不是产品文档**，不得当作官方技术资料 |
| 13 | S1 | 厂商官方·芯片级 | ST Terms of Use | —（网页条款无编号；本次未记录 HTTP 状态码，不编造） | STM32F103x8/B 芯片 | 许可·法务 | STMicroelectronics | `https://www.st.com/content/st_com/en/about/terms-of-use.html` | ST Terms of Use（本体） | 不允许 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验）：WebSearch 命中并读取全文 | WebSearch 命中并读取全文；*Restrictions on use of content* 原文：`"the Materials may not be reproduced, uploaded, linked to another URL, copied, transmitted, modified, displayed or distributed in any form without ST's prior written permission"`，授权仅 `"solely for your personal use, to view and browse"`；**未记录 HTTP 状态码** | — | — | 版权决策依据：所有 ST 官方 PDF（DS5319 / RM0008 / AN2586 / MB1136）一律不入库原件 |
| 14 | S2 | 社区权威·板级 | Blue Pill 板卡实物照片 | —（另有 -2 / -3 / -4） | Blue Pill 板卡 | 板卡定义（实物外观参考） | STM32-base project | `https://stm32-base.org/assets/img/boards/STM32F103C8T6_Blue_Pill-1.jpg` | 未验证（站点 MIT，照片版权归属不明） | 不允许 | link | — | 0 | 已核验 | 2026-11-04 PM 记录（沿用、本轮未二次核验；实测下载字节数已记录） | curl 代理 HTTP=200，`image/jpeg`，**实测 543,336 B ≈ 531 KB**（仅记录，未入库，故 size_bytes=0） | #8 板卡页（含 -2/-3/-4 图片链接） | — | 体积偏大、非必需，只存链接；照片版权归属不明，不入库图形 |

> **分级自检**：S1 = `1, 2, 2b, 3, 4, 5, 5b, 6, 6b, 12, 13`（11 条）；S2 = `7, 8, 8b, 9, 9b, 10, 11, 14`（8 条）；合计 19 条，无 S1/S2 混标。
> `belongs_to` 中 **#6 / #6b / #5 / #5b 明确写 NUCLEO-F103RB 板卡 / 芯片级**，**无任何一处**把 MB1136 写成 Blue Pill。
> 除 **#9（Apache-2.0 资料副本）** 与 **#7（Q9 条件入库原理图）** 外，所有 S1/S2 条目 `store` 均为 `link` / `quote`。

---

## 2. S3 自有文件清单（本仓库自研，默认可自由再分发）

> 仓库级声明：本目录的自研 Markdown、自写源码为本仓库自有整理，其中引用的数据来自第 1 节 S1/S2 来源并已逐条注明出处；
> 第三方来源的入库文件（#9 / #7）在第 1 节单独标许可。自研文件**未逐文件写许可头**不影响判定（§5.4 判据 3）。
> 逐文件 `size_bytes` 为本实施轮写完后的实测值，见第 6 节汇总行。

| id | tier | official_level | title | doc_no | belongs_to | covers | publisher | url | license | redistribution | store | local_path | size_bytes | verified | verified_on | access_evidence | fallback | attribution | notes |
| -- | ---- | -------------- | ----- | ------ | ---------- | ------ | --------- | --- | ------- | -------------- | ----- | ---------- | ---------- | -------- | ----------- | ---------------- | -------- | ----------- | ----- |
| S3-OWN | S3 | 自有整理 | 主索引 `README.md` | — | 本仓库自有 | 许可·法务（索引） | 本仓库 | [`README.md`](README.md) | self-owned | 自有 | file | `docs/bluepill/README.md` | 见 §6 | 已核验 | 2026-11-04 本实施轮落盘并静态核对 | 本实施轮相对链接核对、字段口径与 `SOURCES.md` 一致 | — | — | 三级口径、无官方厂商澄清、四类入口对照、版权与 ≤ 15 MB 体积策略、芯片手册官方直链；主理人已写好，本实施轮按需小幅引用 |
| S3-OWN | S3 | 自有整理 | 来源台账 `SOURCES.md`（本文件） | — | 本仓库自有 | 许可·法务 | 本仓库 | [`SOURCES.md`](SOURCES.md) | self-owned | 自有 | file | `docs/bluepill/SOURCES.md` | 见 §6 | 已核验 | 2026-11-04 本实施轮落盘并静态核对 | 19 条逐行核对、失效项备选、汇总行实测 | — | — | 单一权威台账；派生到新板卡时按 `TEMPLATE-PLACEHOLDERS.md` H 节重填字段 |
| S3-OWN | S3 | 自有整理 | 板卡引脚速查 `board-pinout.md` | — | 本仓库自有 | 引脚图 / 最小系统 | 本仓库 | [`board-pinout.md`](board-pinout.md) | self-owned | 自有 | file | `docs/bluepill/board-pinout.md` | 见 §6 | 已核验 | 2026-11-04 本实施轮落盘，#8 页面 WebFetch 复核 | 40-pin 表与 6 条硬件坑逐字取自 #8；引 #3 / #6 均标注芯片级 / 另板归属 | — | — | 自研整理（数据引自 #1/#3/#4/#6/#7/#8 并注明出处），**不复制整页扫描或图形** |
| S3-OWN | S3 | 自有整理 | 例程索引 `examples.md` | — | 本仓库自有 | 例程 | 本仓库 | [`examples.md`](examples.md) | self-owned | 自有 | file | `docs/bluepill/examples.md` | 见 §6 | 已核验 | 2026-11-05 与副本链接改造同轮复核 | 与本目录 `examples/` 副本相对链接互指核对 | — | — | 资料侧索引 + CubeIDE/MDK → PlatformIO 适配成本；与 [`examples/INDEX.md`](examples/INDEX.md) 互指 |
| S3-OWN | S3 | 自有整理 | 归属声明 `ATTRIBUTION.md` | — | 本仓库自有 | 许可·法务 | 本仓库 | [`ATTRIBUTION.md`](ATTRIBUTION.md) | self-owned | 自有 | file | `docs/bluepill/ATTRIBUTION.md` | 见 §6 | 已核验 | 2026-11-04 本实施轮落盘并静态核对 | 适用范围仅限 #7 的声明已核对 | — | 指向 #7 | **只解决 #7 的署名与来源可追溯**，不构成 ST 的 `prior written permission`，不得为 ST PDF / 正点原子资料开绿灯 |
| S3-OWN | S3 | 自有整理 | 板级映射头 `bluepill.h` | — | 本仓库自有 | 板卡定义（信号→引脚） | 本仓库 | [`../../Core/Inc/bluepill.h`](../../Core/Inc/bluepill.h) | self-owned | 自有 | file | `Core/Inc/bluepill.h` | 见 §6 | 已核验 | 2026-11-04 本实施轮落盘，宏依据逐条对照 `.ioc` / `board-pinout.md` | 每个 `BP_*` 宏均可在 `.ioc` 或 #8 板卡页找到依据；`.ioc` 未被改动 | — | — | 人工维护，只描述「信号→引脚」；模式 / AF / 上下拉 / 时钟由 `.ioc` 决定；include 在 `main.h` 的 USER CODE Includes 块内 |
| S3-OWN | S3 | 自有整理 | 根级 `examples/`（2 个自有示例 + 索引 + 3 篇配方） | — | 本仓库自有 | 例程 | 本仓库 | [`examples/INDEX.md`](examples/INDEX.md) | self-owned | 自有 | file | `examples/**`（原件）+ `docs/bluepill/examples/**`（副本） | 见 §6 | 已核验 | 2026-11-05 副本落盘并逐条核对链接 | INDEX 每行验证等级、配方四栏、副本内相对链接层级重算核对；**不进 `Core/`、不改 `.ioc`、不参与固件构建** | — | — | 按 Q4 只有 2 个自有最小示例（GPIO 点灯、USART1 115200），标注「仅参考、需适配」、L0/L2，**不要求 `pio run`**；复用仓库已有 `test/stdio_port_test.c`（L2），不反向搬 B 仓复制品；`docs/bluepill/examples/` 为资料区副本（同步、根级为准，`--drop-examples` 不删副本） |

---

## 3. 已失效 / 未验证项（6 条，一律给备选，禁止作为可入库直链）

> 初版口径曾把「STM32duino wiki」列为社区权威板级来源，最终核验为 `fetch failed` / GitHub 404，
> 已按本表**降级为失效项**；Blue Pill 板级事实改以 STM32-base（#7 / #8）为准，PlatformIO 板卡定义以 #9 为准。

| # | 失效 / 未验证直链 | 实测结论 | 备选（不得作为可入库直链） | 本实施轮处置 |
| - | ------------------ | -------- | -------------------------- | ------------ |
| F1 | `http://reblag.dk/wordpress/wp-content/uploads/2016/07/The-Generic-STM32F103-Pinout-Diagram.pdf` | 实测 404 | **#10 PinoutDB** 或 **#8 STM32-base** | 沿用 PM 2026-11-04 记录，本轮未二次核验；不写入第 1 节台账 |
| F2 | `https://wiki.stm32duino.com/doku.php?id=blue_pill` | WebFetch `fetch failed`（未验证） | **#8 / #7** | 同上；不作为可达主来源（见 §2.3 规则⑤） |
| F3 | `https://github.com/stm32duino/wiki/wiki/Blue-Pill` | 实测 GitHub 404 | **#8 / #7** | 同上 |
| F4 | `https://cdn.promelec.ru/upload/items/2026/09/18/Blue%20Pill%20-%20STM32Fx_.pdf` | 代理字节流 000（未验证），仅线索，不采用 | **#8 / #7** | 同上；不列为本仓库可入库直链 |
| F5 | `https://www.st.com/stonline/products/literature/ds/13587/stm32f103tb.pdf`（老 DS5319 Rev 19 镜像） | 仅搜索结果、未实测 | **#1** 或 **#2b** | 同上；按 Q14 不锁 Rev、不采用镜像 |
| F6 | STM32duino wiki 提到的 `Vcc-gnd.com-STM32F103C8-schematic.pdf`、`Bluepillpinout.gif` | 原站不可达，不列直链 | **#7 / #8** | 同上；#7 已从 stm32-base.org 取得并条件入库 |

---

## 4. 本机限制（§2.7.4，如实记录，不得写成已实测）

- 代理（`127.0.0.1:7897`）对 `www.st.com` / `www.st.com.cn` 的 **PDF 字节流持续超时**（HTTP=000、0 bytes；`-I` 只拿到 `HTTP/1.1 200 Connection established` 隧道）；Windows curl 另有 schannel 吊销报错（用 `--ssl-no-revoke` 规避）。
- 因此 **#1 / #3 / #4 / #6 的体积与 Rev 未逐页实测**，一律标「估计·未实测」，体积估计值照实保留在第 1 节 `notes`；`application/pdf` **仅证明链接有效**，不代表已下载校验内容。
- st.com 域 PDF 建议**浏览器直连或换网络下载**；`stm32-base.org` / `raw.githubusercontent.com` 的 #7 / #9 在**本实施轮已实测下载成功**（HTTP=200，字节数与台账一致），#8b 的 1,073 B 为 PM 2026-11-04 记录沿用。
- 本实施轮**未对第 1 节其余链接做二次核验**，也未下载任何 ST 官方 PDF；不得把沿用记录写成「本轮实测」。

---

## 5. 用户本机资料登记（非仓库内容，不随仓库分发）

> 按 Q13 补充节：本地正点原子 / M48Z-M3 兼容板资料只**交叉核对存在与轻量文件清单**，登记为
> 「**用户本机资料、非仓库内容、不随仓库分发**」；**不得照抄引脚、不得入库**，
> 1.5 GB 整包**绝不入库**，且**不适用** Q9 的 `ATTRIBUTION.md` 豁免（商业配套资料，版权状态未核实）。
> `bluepill.h` 的引脚宏以本仓库 `.ioc` 与 `board-pinout.md` 为准，本资料仅用于交叉核对。

| 项 | 内容 | 核验口径 |
| -- | ---- | -------- |
| 本机路径 | `D:\Users\Leon\Downloads\BaiduNetdiskDownload\STM32F103版` | **本实施轮用 `ls -d` 确认目录存在**；绝对路径只作「参考资料位置」登记，不是可用配置 |
| 板型 | ATK-DNM48Z-M3 / M48Z-M3 最小系统板，STM32F103 版，Blue Pill 兼容板 | PM 2026-11-04 记录沿用；板型差异须人工核对，不得照抄引脚 |
| 目录总体积 | 1.5 GB（`5，软件资料` 1.2 G、`7，STM32参考资料` 244 M、`4，程序源码` 36 M、`8，增值资料` 27 M 等） | PM 2026-11-04 实测记录沿用，本轮未二次实测 |
| 文件构成 | 46 个 PDF、8 个 zip、视频教程、例程包；含 `stm32cube_fw_f1_v180.zip` / `v183.zip`、精简版 CMSIS | 同上 |
| 轻量文件清单 | `3，原理图/ATK-DNM48Z-M3 STM32F103版 V1.0.pdf` **481,903 B**；`3，原理图/STM32F103最小系统板IO引脚分配表.xlsx` **13,566 B**；`M48Z-M3最小系统板硬件参考手册——STM32F103版.pdf` **1,474,348 B**；`M48Z-M3最小系统板使用指南——STM32F103版.pdf` **7,083,832 B** | PM 2026-11-04 实测记录沿用；**本实施轮用 `find` 交叉核对这 4 个轻量文件名与字节数，逐字一致**（目录总体积 1.5 GB 与文件构成未二次实测） |
| 版权状态 | 正点原子商业配套资料，**未核实**；默认只登记路径与文件清单 | 若要把其原理图 PDF 入库，须单独取得授权并单独 commit，**不适用 `ATTRIBUTION.md` 豁免** |
| 入库判定 | **不入库**（`store = link` 都不适用，因为它没有可公开直链）；不计入 `docs/bluepill/` 体积 | 1.5 GB 远超 ≤ 15 MB 上限，且与 `AGENTS.md` §2.4「`Drivers/` 不入库」冲突 |
| 与本台账的关系 | 仅登记，不占第 1 节的 19 条编号，不计入「实际入库文件数」/「合计体积」 | 派生到别的板卡时此项须整体删除或替换 |

---

## 6. 汇总行

| 指标 | 值 |
| ---- | -- |
| **主台账总条数** | **19** 条（§2.7 的 `1, 2, 2b, 3, 4, 5, 5b, 6, 6b, 7, 8, 8b, 9, 9b, 10, 11, 12, 13, 14`），另有 S3 自有文件清单 7 行（§2）、失效项 6 条（§3） |
| **按 tier 分组** | **S1 = 11** 条（`1, 2, 2b, 3, 4, 5, 5b, 6, 6b, 12, 13`）；**S2 = 8** 条（`7, 8, 8b, 9, 9b, 10, 11, 14`）；**S3 = 7** 行自有文件（不计入 19 条主台账） |
| **link-only 条数（`store = link`）** | **16** 条（`1, 2, 2b, 3, 4, 5, 5b, 6, 6b, 8b, 9b, 10, 11, 12, 13, 14`）；另有 `store = quote` 1 条（#8）、`store = file` 2 条（#7 / #9） |
| **实际入库文件数（`docs/bluepill/`）** | **18** 个：顶层 **7** 个（`README.md`、`SOURCES.md`、`board-pinout.md`、`examples.md`、`ATTRIBUTION.md`、`genericSTM32F103C8.json`（#9 资料副本）、`original-schematic.pdf`（#7 条件入库））+ `examples/` 副本 **11** 个（2026-11-05 新增，见下方第二张表） |
| **合计体积（`docs/bluepill/` 入库文件实测字节数）** | **实测合计 272840 B ≈ 266 KB ≤ 15 MB**（Q12 硬上限，未收紧到 5 MB）；逐文件实测见下表 |
| **最近核验日期** | **2026-11-05**（2026-11-04 PM 逐行清单记录 + #7 / #9 实测下载、#8 页面 WebFetch 复核；2026-11-05 新增 `examples/` 副本并重算体积） |

逐文件实测（顶层 7 个，2026-11-05 用 `wc -c` 复测，单位 B）：

| 文件 | 实测字节数 |
| ---- | ---------- |
| `docs/bluepill/README.md` | 17413 |
| `docs/bluepill/SOURCES.md` | 见下方自引用说明（本表写完后复测） |
| `docs/bluepill/board-pinout.md` | 15802 |
| `docs/bluepill/examples.md` | 11930 |
| `docs/bluepill/ATTRIBUTION.md` | 4111 |
| `docs/bluepill/genericSTM32F103C8.json` | 1150 |
| `docs/bluepill/original-schematic.pdf` | 151372 |
| **小计（顶层 7 个）** | **235242 B**（不含 `SOURCES.md` 自身时 201778 B） |

`docs/bluepill/examples/` 副本 11 个文件（根级 `examples/` 的镜像，2026-11-05 新增，同步口径见 `examples/README.md` 顶部说明）：

| 文件 | 实测字节数 |
| ---- | ---------- |
| `docs/bluepill/examples/INDEX.md` | 3115 |
| `docs/bluepill/examples/README.md` | 6288 |
| `docs/bluepill/examples/gpio-blink/README.md` | 2748 |
| `docs/bluepill/examples/gpio-blink/blink.c` | 1663 |
| `docs/bluepill/examples/gpio-blink/blink.h` | 2187 |
| `docs/bluepill/examples/recipes/gpio-blink.md` | 4649 |
| `docs/bluepill/examples/recipes/host-regression.md` | 4214 |
| `docs/bluepill/examples/recipes/usart1-115200.md` | 5103 |
| `docs/bluepill/examples/usart1-115200/README.md` | 3079 |
| `docs/bluepill/examples/usart1-115200/usart1_echo.c` | 1554 |
| `docs/bluepill/examples/usart1-115200/usart1_echo.h` | 2998 |
| **小计（副本 11 个）** | **37598 B** |

| 口径 | 值 |
| ---- | -- |
| **合计（18 个入库文件）** | **272840 B ≈ 266 KB**（`du -sb docs/bluepill` 实测 272840 B；`du -sh` 另计文件系统块开销） |

> 注：`SOURCES.md` 记录自身字节数属于自引用，回填本表后其字节数会有微调；
> 本表「合计」取复测值（顶层 7 个 + 副本 11 个）；最终以
> `find docs/bluepill -type f -exec cat {} + | wc -c` 逐文件求和实测为准，恒远低于 15 MB（POSIX 写法，GNU / BSD / macOS 通用；GNU find 的 -printf 与 du -sb 不跨平台）。

> 体积判据与版权判据**相互独立**：不得以「体积没超 15 MB」论证 ST 官方 PDF 可以入库原件（§5.4 判据 5）。
> 统计口径为「本次新增且将纳入 git 跟踪的文件合计字节数」；`du -sh docs/bluepill` 仅作辅助观察。
> 根级 `examples/`（**worktree 实测 37,025 B**，非 HEAD 旧值）与 `Core/Inc/bluepill.h` 不计入 `docs/bluepill/` 体积，但已在 §2 登记；
> `docs/bluepill/examples/` 是**资料区副本**，在 `docs/bluepill/` 内，**计入**体积。
