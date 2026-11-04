# 归属声明：Blue Pill 社区原版原理图（清单 #7）

> **适用范围（先读，最重要）**：本文件**仅适用于 `SOURCES.md` 清单 #7 的社区 Blue Pill 原理图**
> （本目录 `original-schematic.pdf`，实测 151,372 B，文件头 `%PDF-1.3`），按用户 2026-11-04 拍板的 Q9「条件入库 + `ATTRIBUTION.md`」落盘。
>
> 它**只解决来源与署名可追溯**，**不构成** ST Terms of Use 要求的 `prior written permission`。
> 因此：
> - **不为** DS5319 / RM0008 / AN2586 / MB1136 等 **ST 官方 PDF** 入库原件开绿灯（这些一律只存官方直链 + 自研摘要，见 `SOURCES.md` #1 / #3 / #4 / #6）；
> - **不为** ST 官方例程整包、PinoutDB 引脚图（`Diagram & Layout © Oliver Weinhold`）开绿灯；
> - **不适用于**用户本机的正点原子 / M48Z-M3 商业配套资料（见 `SOURCES.md` 末节「用户本机资料登记」）——那是另一套版权状态未核实的资料，需单独取得授权并单独提交，不享受本文件的条件入库口径。

## 1. 原件信息

| 项 | 内容 |
| -- | ---- |
| 清单编号 | **#7**（语义 id `S2-BP-SCHEMATIC`） |
| 名称 | Blue Pill 原版原理图 |
| 来源页 | <https://stm32-base.org/boards/STM32F103C8T6-Blue-Pill.html>（STM32-base 板卡页，清单 #8） |
| 下载直链 | <https://stm32-base.org/assets/pdf/boards/original-schematic-STM32F103C8T6-Blue_Pill.pdf> |
| 文件名 | `original-schematic-STM32F103C8T6-Blue_Pill.pdf`（原件名标 `original`） |
| 本地副本 | `docs/bluepill/original-schematic.pdf` |
| 下载日期 | **2026-11-04** |
| 实测体积 | **151,372 B ≈ 148 KB**，curl 代理 HTTP=200、`application/pdf`，文件头 `%PDF-1.3` |
| 来源分级 | **S2 社区权威·板级**（不是厂商官方；Blue Pill 无官方厂商） |
| 归属对象 | `Blue Pill 板卡` |

## 2. 版权状态（如实写明，不做结论式断言）

- **站点仓库**：STM32-base 站点仓库为 **MIT**，Copyright (c) 2020 Thomas Gravekamp（清单 #8b，`LICENSE` 实测 1,073 B）；MIT 覆盖**站点源码**，**未必覆盖**原理图原件。
- **原理图原件**：来自第三方 **vcc-gnd.com / 板厂**，**原作者授权链不明**——「站点 MIT ≠ 原件版权清晰」。
- **本仓库结论**：**原件版权未核实**，`license` 在 `SOURCES.md` 记为 `未验证`，`redistribution` 记为 `条件允许`；本文件不宣称已获得任何再分发授权。
- `ATTRIBUTION.md` 只做署名与来源可追溯，不改变上述状态。

## 3. 使用范围与限制

1. **仅非商业学习使用**：本副本只作为板级引脚 / 最小系统核对的参考资料，供本模板及其派生工程的学习者查阅。
2. **不改动原件**：副本按下载字节原样入库，未做任何修改；`.gitattributes` 把 `*.pdf` 声明为 `binary`，入库后不可逐行审阅、不能产生可审 diff。
3. **上游可要求移除**：若原理图原作者、vcc-gnd.com、STM32-base project 或其它权利人提出异议，**本仓库将按上游要求移除该 PDF**，并同步把 `SOURCES.md` #7 的 `store` 改回 `link`、删除本文件；移除不影响 `board-pinout.md` 等自研整理文档。
4. **不构成书面许可**：本文件不是、也不能替代 ST 或其它权利人出具的 `prior written permission`；任何超出「仅非商业学习」的使用（含商业分发、再授权）都需另行取得授权。
5. **体积**：该 PDF 计入 `docs/bluepill/` 的 **≤ 15 MB** 硬上限（Q12），实测 151,372 B，远低于上限；但**体积合规不等于版权合规**（验收判据 5）。

## 4. 与台账 / 主索引的对应

- `SOURCES.md` #7 条目：`store = file`、`local_path = docs/bluepill/original-schematic.pdf`、`size_bytes = 151372`、`attribution = ATTRIBUTION.md`。
- 主索引 [`README.md`](README.md) §4 / §9 与 [`board-pinout.md`](board-pinout.md) §0 都指向本文件。
- 若将来移除该 PDF，须同时更新 `SOURCES.md` 汇总行的「实际入库文件数 / 合计体积」与 `README.md` §9 文件清单，避免留下死链。
