# 模板占位符与初始条件（PLACEHOLDERS）

本文件列出**复制本模板后必须人工修改的占位符**，以及无法靠代码消除的"初始条件"。
新建工程时请逐条过一遍；agent 拿到本模板后也应以本文件为清单先做核对。

> 约定：本模板中**没有任何**指向原作者机器的绝对路径是"可用的"——凡是绝对路径都属于占位符。

---

## A. 必须替换（阻塞项）

| # | 位置 | 当前值 / 占位符 | 应改成 | 说明 |
| - | ---- | -------------- | ------ | ---- |
| A1 | `scripts/cubemx-init.mx:5` | `project path __PROJECT_DIR__` | 本副本的**绝对路径**，如 `D:\Projects\foo\my-board` | 该脚本用于"从 MCU 裸建工程"，CubeMX 脚本**不支持变量**，必须硬写绝对路径。仅用 `scripts/cubemx-generate.mx` 的话可以不碰它。 |
| A2 | `stm32-digital-clock.ioc` | 工程名 `stm32-digital-clock` | 你的工程名 | 工程名同时出现在：`ProjectManager.ProjectName`、`ProjectManager.ProjectFileName`、文件名本身、`.vscode/tasks.json`、`scripts/cubemx-generate.mx`、`README.md`。**六处要一起改**，否则 CubeMX 会按新名字再生成一套目录。 |
| A3 | 仓库自身 | 仓库名 `template-mcu-STM32F103C8T6-BluePill` | 你的仓库名 | `git remote -v` 指向模板仓库时，提交会推到模板去。新建仓库后确认 remote。 |
| A4 | `README.md:1` | `# template-mcu-STM32F103C8T6-BluePill` | 你的项目名 | 纯展示，但会误导协作者。 |

## B. 视硬件/工具链而定（可能不用改）

| # | 位置 | 当前值 | 何时需要改 |
| - | ---- | ------ | ---------- |
| B1 | `platformio.ini` `upload_protocol` / `debug_tool`；`.vscode/launch.json` 的 `configFiles` | `stlink`；`scripts/openocd-stlink.cfg`（原生 ST-Link 驱动，SWD） | 换 CMSIS-DAP 时将两项改为 `cmsis-dap`，并将 Debug/Attach 的 `configFiles` 切到已提供的 `scripts/openocd-cmsis-dap.cfg`。 |
| B2 | `platformio.ini` `board` | `genericSTM32F103C8` | 换芯片型号时。同时 `.ioc` 的 `Mcu.CPN`、`DeviceId`、`Mcu.Name`、`Mcu.Package` 要同步。 |
| B3 | `STM32F103C8TX_FLASH.ld` | 按 **64K** Flash 配置 | 若实际是 128K（C8T6 有 64K/128K 两种说法，以实测为准），在 `platformio.ini` 加 `board_build.ldscript` 指定合适脚本。 |
| B4 | `.vscode/tasks.json` `windows.command` | `${env:ProgramFiles}\STMicroelectronics\...\STM32CubeMX.exe` | CubeMX **不在默认安装目录**时。默认装在 `C:\Program Files\...` 则无需改。 |
| B5 | `.vscode/tasks.json` `linux.command` | `STM32CubeMX` | Linux 下要求该命令在 `PATH` 中。 |
| B6 | `.vscode/launch.json`、`.vscode/settings.json` 的终端 PATH | `${env:USERPROFILE}/.platformio/...` | PlatformIO Core/包目录被 `PLATFORMIO_CORE_DIR` 改到别处时，同步调整调试路径和 `penv/Scripts` 路径（WSL 也要留意）。 |
| B7 | `platformio.ini` 的版本锁定 | `ststm32@20.0.0`、`framework-stm32cubef1@1.8.7`、`toolchain-gccarmnoneeabi@1.70201.0`、`tool-ldscripts-ststm32@0.3.0` | 升级时**必须一起验证**"生成代码 + 构建"两者，不要单独升 HAL。 |
| B8 | `.ioc` 与 CubeMX 版本 | 历史戳 `MxCube.Version=6.17.0`、`MxDb.Version=DB.6.0.170`；FW_F1 锁定 V1.8.7 | 实际工具版本看 exe/运行日志（本机记录为 6.18.1-RC2，见 tooling §1.1），不要仅相信旧戳。迁移后审阅工具写回并验证生成 + 构建，保留 FW_F1 版本锁，不必同时升级固件包。 |

## C. 环境前提（不是文件，但缺了就跑不起来）

| # | 前提 | 检查方式 | 缺失后果 |
| - | ---- | -------- | -------- |
| C1 | STM32CubeMX 6.x 已安装 | `Test-Path "$env:ProgramFiles\STMicroelectronics\STM32Cube\STM32CubeMX\STM32CubeMX.exe"` | 无法改 `.ioc`、无法生成 `Core/` |
| C2 | 已安装 FW_F1 包（V1.8.7） | CubeMX → Help → Manage embedded software packages | `project generate` 失败 |
| C3 | PlatformIO Core | `pio --version` | 无法构建/烧录 |
| C4 | 主机 GCC（仅跑 `test/stdio_port_test.c` 需要） | `gcc --version` | 回归测试跑不了；`pio run` 不受影响 |
| C5 | 默认 ST-Link，使用 SWD；目标板正确供电、共地，VTref 接线按探针定义 | 看探针型号与接线；原生驱动要求 ST-LINK/V2 固件 V2J24 或更新，或 STLINK-V3 | 探针/驱动/固件不匹配或目标无电会连接失败；改用 FireDAP Lite 时也只能走 SWD |
| C6 | 首次 `pio run` 需联网下载 ststm32 平台与 HAL 包 | — | 离线首次构建失败 |

## D. 已知陷阱（不改也会踩）

| # | 陷阱 | 现状 | 建议 |
| - | ---- | ---- | ---- |
| D1 | `.vscode/settings.json` 开了 `editor.formatOnSave: true` | 保存 `Core/Src/main.c` 会被 clang-format 整体重排，产生与 CubeMX 无关的巨大 diff | 处理 `Core/**` 时建议关掉 formatOnSave，或加 `.clang-format` + `// clang-format off` 保护 |
| D2 | `.ioc` 行尾 | CubeMX 写 **CRLF**；Git 入库/checkout 与编辑器统一 LF，`text` 属性在 add/比对时归一化 | 不必手工转回 CRLF；不要提交纯行尾变化，异常时用 `git ls-files --eol` 核对 |
| D3 | `.ioc` 内的 `*IPParameters` 白名单 | 每个外设有一行 `<IP>.IPParameters=a,b,c`，只有列在这里的 key 才被识别 | 手改 `.ioc` 加参数时，**必须同步补进该行**，否则 CubeMX 静默忽略 |
| D4 | 信号名是 `S_` 前缀的枚举 | 例如 PA0 上 TIM2 通道 1 的**正确**写法是 `S_TIM2_CH1_ETR`，写成 `TIM2_CH1_ETR` 会失败 | 见 D5 的校验流程 |
| D5 | CubeMX 对 `.ioc` 的错误是**非致命**的 | 信号名写错时只在日志里留一行 `(OptionalMessage_ERROR) Cannot map signal ...`，`project generate` 依然返回成功，外设被静默丢弃 | 改过 `.ioc` 后**必须**核验：①日志有无 `Cannot map`；②生成的 `main.c` 里有没有对应的 `MX_xxx_Init` |
| D6 | `Drivers/` 被 git 忽略 | `Drivers/**` + `!Drivers/**/.gitkeep` | 新克隆的仓库里 `Drivers/` 只有 `.gitkeep`，这是**预期**的：HAL/CMSIS 由 PlatformIO framework 提供，不需要提交 |

---

## E. 推荐的「改配置」流程（含校验）

模板原 README 曾说"不要手动编辑 `.ioc`"。经实测**该说法过强**：
CubeMX 的 `-q` 脚本模式确实能接受手写的时钟/外设/GPIO 参数（已验证 HSE+PLL×9=72 MHz、USART1 115200 异步、GPIO 上拉输入均可生效），
但**复杂外设（如 TIM 输入捕获）的信号名极易写错，且失败是静默的**（见 D5）。

因此按优先级：

1. **首选**：用 CubeMX GUI 改，保存后 `project generate`。
2. **脚本化/headless**：用 `scripts/cubemx-generate.mx`（加载已有 `.ioc` → 生成）。
3. **手改 `.ioc`**：仅限小改动，且**必须**做完 D5 的两项核验。
4. **有 MCP 就用 MCP**：`vscode-cube-mcp`（见 `docs/TOOLING-cubemx.md`）提供
   `cubemx_load`（只读回读）/ `cubemx_configure`（带备份写回）/ `cubemx_generate`，
   并强制 `.ioc` 路径白名单 —— 比裸手改安全。

## F. 初始化脚本（`scripts/init-project.sh|ps1`）能做什么、不能做什么

复制模板后可以用脚本把「六处联动」一次改完，但**它不是全自动**。用法：

```bash
bash scripts/init-project.sh <新工程名> [--yes] [--dry-run] [--flash 64k|128k]
# Windows PowerShell：
#   powershell -ExecutionPolicy Bypass -File .\scripts\init-project.ps1 <新工程名> [--Yes] [--DryRun] [--Flash 64k|128k]
```

| 项 | 说明 |
| -- | ---- |
| 自动改（A2 六处联动） | ① 根 `.ioc` 文件名 ② `.ioc` 内 `ProjectManager.ProjectName` ③ `ProjectManager.ProjectFileName` ④ `.vscode/tasks.json` 里引用的 `.ioc` 名 ⑤ `scripts/cubemx-generate.mx` 里 `config load` 的 `.ioc` 名 ⑥ `README.md` 里提到的工程名 / `.ioc` 名；另自动改 A3 仓库名、A4 README 标题 |
| 自动改（Q5 询问） | 用平实大白话问「**新建的工程要把资料原件放进仓库吗？**」，默认**允许**、可手动改；按回答 patch `AGENTS.md` 里 `<!-- BEGIN: BP_THIRD_PARTY_ORIGINAL_RULE -->` / `<!-- END: BP_THIRD_PARTY_ORIGINAL_RULE -->` 标记块（允许 → 移除该约束；不允许 → 写入该约束）。提问文案不含任何生僻术语 |
| `--dry-run` | **不写任何文件**，只打印将做什么（含将 patch 的 `AGENTS.md` 内容）；可用来先审阅再真跑 |
| `--yes` | 跳过逐项确认，用默认值（工程名必填、资料原件默认允许、flash 默认 64k） |
| **仍需人工项**（脚本会明确打印，且不自动填绝对路径） | ① `scripts/cubemx-init.mx` 的 `__PROJECT_DIR__`（CubeMX `.mx` 脚本不支持变量，必须硬写本副本绝对路径）② 目录名 / 仓库文件夹名 ③ `git remote -v` 指向的远端地址 ④ clangd 重新生成索引（换机器后重跑 `scripts/init-clangd.sh|ps1`） |
| **不会改** | `.ioc` 的引脚 / 时钟 / 外设配置、`platformio.ini` 的锁定组合、`Core/Src/**`、`Core/Inc/stm32f1xx_hal_conf.h`、`.git/config`（含 `core.hooksPath`）、用户既有的 `.vscode` 未提交改动 |

## G. `--flash` 选项与 64K / 128K Flash（Q7）

- 默认 **`--flash 64k`**：与 PlatformIO 内置 `genericSTM32F103C8.json`、现有
  `STM32F103C8TX_FLASH.ld`、上文 **B3** 一致，脚本**不改 `platformio.ini`**。
- 选 **`--flash 128k`** 时：脚本只**打印提醒**——C8T6 有 64K / 128K 两种说法，以实测为准；
  若确需按 128K 使用，须人工在 `platformio.ini` 里同步设置
  `board_build.ldscript` 指向合适的链接脚本（脚本不代改，避免动到版本锁定组合）。
- 不引入自定义 `boards/` 目录；`docs/bluepill/genericSTM32F103C8.json` 只是**资料副本**，
  绝不放到 `boards/`。

## H. 派生到别的板卡时：`SOURCES.md` 哪些字段要重填

[`docs/bluepill/SOURCES.md`](docs/bluepill/SOURCES.md) 是「一行一条」的宽表。换板卡时
**不要沿用旧行的来源结论**，逐条按新板卡重填下列字段（其余字段也要相应核对）：

| 字段 | 为什么要重填 |
| ---- | ------------ |
| `id` / `title` | 沿用 2.7 的编号规则增补 / 校正，不重编号；标题换成新板卡资料名 |
| `tier` / `official_level` | S1「厂商官方·芯片级」与 S2「社区权威·板级」不得混标；换芯片 / 换板后权威来源可能整体变化 |
| `belongs_to` | **防误标核心**：`STM32F103x8/B 芯片` / `Blue Pill 板卡` / `NUCLEO-F103RB 板卡` / `本仓库自有`。例如 MB1136 必须写 `NUCLEO-F103RB 板卡`，绝不能写成新板卡 |
| `doc_no` | 文档编号 / 版本按新芯片重填；按 Q14 只记编号 + 官方动态链接，不锁具体 Rev |
| `covers` / `publisher` | 覆盖的资料类型、发布方随板卡变化 |
| `url` | 换成新板卡的官方 / 社区直链；**失效项不得作为可入库直链**，须给 `fallback` |
| `license` / `redistribution` | 换资料就要重新判断许可；「标未验证」时禁止 `store = file` |
| `store` / `local_path` | 默认 `link`；只有 S3 自有与显式例外可 `file`，`local_path` 必须在小写资料目录内 |
| `size_bytes` / `verified` / `verified_on` / `access_evidence` | **实测字节数、HTTP 状态 / 页面标题 / 下载字节数、核验日期**必须重新实测；`store = link` 填 `0`，不得把「估计·未实测」写成已实测 |
| `attribution` / `notes` | 条件入库的署名指向、易误导点（如「非本板卡原理图」）随板卡变化 |
| 末尾汇总行 | 总条数 / 按 tier 分组 / link-only 条数 / 实际入库文件数 / 合计体积 / 最近核验日期全部重算 |

同时：`docs/bluepill/README.md`（主索引）、`board-pinout.md`（40-pin 速查与硬件坑）、
`examples.md`（例程索引）、`ATTRIBUTION.md`（若条件入库了原理图）都要按新板卡重写；
`Core/Inc/bluepill.h` 的 `BP_` 宏要以**本工程 `.ioc` 与新板卡资料**为依据，不得照抄别的板。

## I. 板级映射头与提交校验（新增文件说明）

| 文件 | 人工维护？ | 说明 |
| ---- | ---------- | ---- |
| `Core/Inc/bluepill.h` | 是，人工维护 | `BP_` 前缀，只描述「信号 → 引脚」；模式 / AF / 上下拉 / 时钟一律由 `.ioc` 决定。CubeMX 既不生成也不覆盖；include 放在 `main.h` 的 `/* USER CODE BEGIN Includes */` 内，重新生成后保留 |
| `commitlint.config.mjs` + `package.json` + `.vite-hooks/commit-msg` | 否 | Node 工具链**仅用于提交信息校验**（devDependencies），不进固件、不参与 `pio run`、不污染跨平台；启用命令见根级 README，**不提供任何跳过钩子的方式** |
| `scripts/init-clangd.sh|ps1` / `disable-clangd.sh|ps1` | 否 | 生成 / 移除 clangd 编译数据库与 `.clangd`（均已被 `.gitignore` 忽略）；**换机器要重跑** |
