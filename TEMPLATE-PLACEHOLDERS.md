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
| A3 | 仓库自身 | 仓库名 `template-mcu-STM32F103C8T6` | 你的仓库名 | `git remote -v` 指向模板仓库时，提交会推到模板去。新建仓库后确认 remote。 |
| A4 | `README.md:1` | `# template-mcu-STM32F103C8T6` | 你的项目名 | 纯展示，但会误导协作者。 |

## B. 视硬件/工具链而定（可能不用改）

| # | 位置 | 当前值 | 何时需要改 |
| - | ---- | ------ | ---------- |
| B1 | `platformio.ini` `upload_protocol` / `debug_tool` | `cmsis-dap` | 换 ST-Link 时改为 `stlink`，并把 `scripts/openocd-cmsis-dap.cfg` 的 `interface/cmsis-dap.cfg` 改成 `interface/stlink.cfg`、`transport select hla_swd`。 |
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
| C4 | 主机 GCC（仅跑 `tests/stdio_port_test.c` 需要） | `gcc --version` | 回归测试跑不了；`pio run` 不受影响 |
| C5 | 探针固件：野火 FireDAP Lite **仅支持 SWD** | 看探针型号 | 用 JTAG 连不上 |
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
