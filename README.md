# template-mcu-STM32F103C8T6-BluePill

STM32F103C8T6 最小工程模板，默认使用 HSI 8 MHz、PC13 闪灯和 ST-Link/SWD。
沿用 `stm32-digital-clock.ioc` 工程文件名；复制模板后可继续直接使用。

本项目采用 **STM32CubeMX + PlatformIO + VS Code** 混合工作流：

- **STM32CubeMX**：管脚/时钟/外设配置，生成 `Core/Inc`、`Core/Src`
- **PlatformIO**：编译、烧录、调试（HAL / CMSIS / 启动文件由 `framework-stm32cubef1` 提供）
- **VS Code**：编辑器与调试前端

## 快速开始

```bash
# 1. 安装 VS Code 推荐扩展（打开工程时会提示安装）
#    PlatformIO IDE / STM32 VS Code Extension / Cortex-Debug / C/C++

# 2. 编译（首次会自动下载 ststm32 平台与 HAL 包）
pio run

# 3. 烧录（ST-Link 探针接 SWD：SWDIO-PA13、SWCLK-PA14、GND 共地，目标板供电）
pio run -t upload

# 4. 调试：VS Code 运行面板选择 "Debug (OpenOCD / ST-Link)"
```

常用命令：

| 命令 | 说明 |
| --- | --- |
| `pio run -e genericSTM32F103C8` | 构建默认环境 |
| `pio run -t upload` | 烧录 |
| `pio run -t clean` | 清理构建产物 |
| `pio device monitor` | 串口监视（默认 115200，需自行启用 USART） |

## 目录结构

```text
Core/Inc                 # CubeMX 生成的用户头文件（含 stm32f1xx_hal_conf.h）
Core/Inc/bluepill.h      # 人工维护的板级「信号→引脚」映射（BP_ 前缀，CubeMX 不覆盖）
Core/Src                 # CubeMX 生成的用户源码（PlatformIO 的 src_dir）
Drivers/                 # CubeMX 生成的 HAL/CMSIS 库（不参与 PIO 编译，已 git 忽略）
scripts/                 # CubeMX 命令行脚本 + 初始化 / clangd 辅助脚本
test/                    # 系统 GCC 主机回归（不使用 pio test / Unity）
examples/                # 自有最小示例 + 配方（可选资料，不参与固件构建）
docs/bluepill/           # 板卡资料单一权威入口（官方直链索引 + 三级来源 + 自有整理）
.vscode/                 # 任务、调试、推荐扩展配置
platformio.ini           # PlatformIO 工程配置
stm32-digital-clock.ioc  # CubeMX 配置（唯一事实来源）
AGENTS.md                # agent 工作约束（提交规范 / 硬约束 / 验证关卡）
TEMPLATE-PLACEHOLDERS.md # 复制模板后需要人工修改的占位符清单
commitlint.config.mjs    # 提交信息校验规则（仅 devDependencies，见「提交规范」）
.vite-hooks/commit-msg   # 提交信息校验钩子（手写源文件，需自己启用）
docs/                    # 补充文档（如 docs/TOOLING-cubemx.md）
```

**零新增运行时依赖**：本模板的固件构建只依赖 STM32CubeMX 生成的 `Core/` 与 PlatformIO 的
`framework-stm32cubef1`；`platformio.ini` 的锁定组合（`ststm32@20.0.0` /
`framework-stm32cubef1@1.8.7` / `toolchain-gccarmnoneeabi@1.70201.0` /
`tool-ldscripts-ststm32@0.3.0`）**不动**，也不新建自定义 `boards/` 目录。
根目录的 `package.json` / `pnpm-lock.yaml` 只装 commitlint 两个 devDependencies，
**仅用于提交信息校验，不进固件、不参与 `pio run`、不污染跨平台**：
未安装 `node_modules` 时 `pio run` 仍应通过（0.5 追加闸门）。详见「提交规范」。

## 修改外设配置的流程

1. VS Code 任务面板运行 **STM32CubeMX: Open .ioc**（或直接用 CubeMX 打开 `.ioc`）
2. 配置完成后点 **GENERATE CODE**（工具链保持 `Makefile`，不要改目录结构）
3. 回到 VS Code，用户代码写在 `main.c` 的 `/* USER CODE BEGIN */ ... /* USER CODE END */` 之间
4. `pio run` 重新编译

无头生成（CI/脚本）可用任务 **STM32CubeMX: Generate Code (CLI)**，脚本见
`scripts/cubemx-generate.mx`。该脚本用**相对路径**加载 `.ioc`，因此工作目录必须是项目根目录
（`tasks.json` 已设 `cwd`）。若 CubeMX 不在默认安装目录，需同步改 `tasks.json` 中的路径。

## 工作流约定（重要）

- **`.ioc` 是唯一事实来源；改它的首选方式是 CubeMX GUI。**
  手改 `.ioc` 文本**并非不可行** —— 实测 CubeMX 的 `-q` 脚本模式确实能接受手写的时钟/外设/GPIO 参数
  （已验证 HSE+PLL×9=72 MHz、USART1 115200 异步、GPIO 上拉输入都能正确落到生成的 `main.c`）。
  但 **CubeMX 对 `.ioc` 的错误是非致命的**：信号名这类枚举写错时会**静默丢弃**该外设，
  `project generate` 仍返回成功，只在日志里留一行 `(OptionalMessage_ERROR) Cannot map signal ...`。
  所以手改 `.ioc` 后**必须**核验：① 日志里没有 `Cannot map`；② 生成的 `main.c` 里有对应的 `MX_xxx_Init()`。
  已知陷阱、正确的枚举写法（如 PA0 上 TIM2 通道 1 是 `S_TIM2_CH1_ETR`）见
  **[`TEMPLATE-PLACEHOLDERS.md`](TEMPLATE-PLACEHOLDERS.md)**。
  更安全的脚本化路径是用已全局安装的 CubeMX MCP —— 见 [`docs/TOOLING-cubemx.md`](docs/TOOLING-cubemx.md)。
- HAL / CMSIS / 启动文件 / 链接脚本 **由 PlatformIO 的 framework 提供**，因此：
  - `Core/Src/system_stm32f1xx.c` 已在 `platformio.ini` 中排除，避免与 framework 的 CMSIS 重复定义符号；
  - `Drivers/`、`Makefile` 不参与 PlatformIO 编译，已加入 `.gitignore`；
  - 使用 PlatformIO 自带的 `STM32F103C8TX_FLASH.ld`，不再依赖 CubeMX 生成的链接脚本，
    避免每次 Generate Code 后需要手动补全 `.init_array` 等段。
- 新增外设后，若 `Core/Inc/stm32f1xx_hal_conf.h` 缺少对应 `HAL_XXX_MODULE_ENABLED`，
  在 CubeMX 中重新生成即可（CubeMX 会覆盖该文件，用户代码不要写在该文件里）。
- 当前时钟配置为默认 HSI 8 MHz。如需 HSE + 72 MHz，请在 CubeMX GUI 的
   *RCC / Clock Configuration* 中配置，保存后重新生成代码。

## 模板占位符与初始条件

复制本模板后**必须人工修改**的内容（绝对路径、工程名、工具链前提、已知陷阱）统一列在
**[`TEMPLATE-PLACEHOLDERS.md`](TEMPLATE-PLACEHOLDERS.md)**。要点：

| 类别 | 例子 |
| --- | --- |
| 必须替换 | `scripts/cubemx-init.mx` 的 `__PROJECT_DIR__`；工程名 `stm32-digital-clock`（六处要一起改） |
| 视硬件而定 | 探针（默认 `stlink`，可切换 `cmsis-dap`）、`board`、Flash 容量、CubeMX 安装路径 |
| 环境前提 | 已装 CubeMX + FW_F1 包、PlatformIO Core、主机 GCC（仅回归测试用） |
| 已知陷阱 | `formatOnSave` 会重排 `main.c`；`.ioc` 的 `*IPParameters` 白名单；信号名的 `S_` 前缀 |

agent 的工作约束（提交规范、硬约束、验证关卡）见 **[`AGENTS.md`](AGENTS.md)**。

## 默认引脚与时钟

当前模板是**最小骨架**：根目录 `.ioc` 配了 HSI 8 MHz（未启用 PLL，不是 72 MHz）、
PC13 板载 LED（`GPIO_Output`）与 PA13/PA14 的 SWD 调试口，`Core/Src/main.c` 里是
`HAL_GPIO_TogglePin(GPIOC, GPIO_PIN_13)` + `HAL_Delay(500)` 闪灯。

| 项 | 当前值 | 由谁决定 |
| -- | ------ | -------- |
| 系统时钟 | HSI 8 MHz（`SystemClock_Config()`，无 PLL） | `.ioc` 的 RCC |
| 板载 LED | PC13，**低电平点亮**（Sink 接法） | `.ioc` + 板卡页 [#8](docs/bluepill/SOURCES.md) |
| 调试口 | PA13 = SWDIO、PA14 = SWCLK（默认 ST-Link / SWD） | `.ioc` 的 SYS |
| USART1 / USB | **未启用**（PA9/PA10、PA11/PA12 是板上固定接线） | 需要时在 `.ioc` 里加外设 |

板上「哪条信号接在哪个引脚」是**死的接线**，登记在
[`Core/Inc/bluepill.h`](Core/Inc/bluepill.h) 的 `BP_` 宏里；
**GPIO 模式 / AF / 上下拉 / 速度 / 时钟树一律由 `.ioc` 决定**，头文件不写配置。
完整 40-pin 速查、引脚复用与 6 条硬件坑见
[`docs/bluepill/board-pinout.md`](docs/bluepill/board-pinout.md)。

## 板级引脚映射

[`Core/Inc/bluepill.h`](Core/Inc/bluepill.h) 是**人工维护**的头文件，CubeMX 既不生成也不覆盖；
它的 `#include "bluepill.h"` 放在 [`Core/Inc/main.h`](Core/Inc/main.h) 的
`/* USER CODE BEGIN Includes */` 块内，因此 `project generate` 之后仍保留。

- 只描述「信号 → 引脚」（`BP_LED_*` / `BP_SWDIO_*` / `BP_SWCLK_*` / `BP_USB_*` /
  `BP_USART1_*` / `BP_BOOT1_*`），用 `BP_` 前缀避免与 CubeMX 的 `GPIO_Label` 宏撞名。
- `.ioc` 仍是唯一事实来源；**不要**用头文件反过来改 `.ioc` 的引脚 / 时钟 / 外设。
- 板型差异、克隆芯片、USB D+ 上拉电阻等坑见
  [`board-pinout.md`](docs/bluepill/board-pinout.md)；派生到别的板卡时按
  [`TEMPLATE-PLACEHOLDERS.md`](TEMPLATE-PLACEHOLDERS.md) H 节重填宏与资料台账。

## 提交规范

提交信息沿用 `AGENTS.md` §1 的**中文 Conventional Commits**：`<type>(<scope>): <中文简述>`，
简述动词开头、≤ 50 字、结尾不加句号；正文写明验证等级（L0–L5，没验证就写「未验证」）；
做过构建要记 PlatformIO 报告的 Flash / RAM 字节数；禁止 `--no-verify` /
`--no-gpg-sign` 与 AI 署名尾注（`Co-Authored-By` / `Generated by` 等）。

仓库提供了 [`commitlint.config.mjs`](commitlint.config.mjs)（extends
`@commitlint/config-conventional` + 内联自定义规则）与手写入库的
[`.vite-hooks/commit-msg`](.vite-hooks/commit-msg)。**启用由使用者自己执行**
（本仓库不代为修改 `.git/config`，也不执行任何提交）：

```bash
pnpm install                          # 仅安装 2 个 devDependencies，不进固件
git config core.hooksPath .vite-hooks # 启用提交信息校验钩子
```

机器能拦截：中文简述 / 首字汉字 / ≤ 50 字 / 结尾无句号、验证等级（L0–L5 或「未验证」）、
正文提到构建却缺 Flash / RAM 数字、AI 署名。纯文档正文写「未运行构建」可豁免构建数字。

**人工核对清单（机器判不了的项）**：

| 项 | 为什么机器判不了 | 怎么核 |
| -- | ---------------- | ------ |
| 简述**动词开头** | 中文动词没有可靠词表／分词，正则会大量误伤「新增文档」「补充资料」这类合法简述 | 提交前自己读一遍，确认简述是「动词 + 对象」；规则里只校验首字为汉字 |
| 正文明说「为什么这么改」 | 语义判断 | 别复述 diff |
| 一个提交只做一件事（原子性） | 需要看 diff | 格式化 / 行尾归一单独开 `style:` / `chore:` 提交 |
| 验证等级是否属实 | 机器只检查「写了」，不检查「真跑了」 | 只写实际执行过的等级，不复用旧 Flash/RAM 数字 |

**钩子管格式，`AGENTS.md` 管代码与生成边界**；本仓库**不提供任何跳过钩子的方式**，
校验失败请修改提交信息，不要用环境变量或 `--no-verify` 绕过。

## clangd 初始化（换机器重跑）

`compile_commands.json` / `.clangd` / `.cache/` 都是本机生成物，已被 `.gitignore` 忽略，
**换机器、换 PlatformIO Core 目录后要重跑**：

```bash
./scripts/init-clangd.sh        # 或 Windows: powershell -ExecutionPolicy Bypass -File .\scripts\init-clangd.ps1
./scripts/disable-clangd.sh     # 关闭时清理（也有同名 .ps1）
```

脚本直接用 PlatformIO 原生的 `pio run -t compiledb`，**不需要 Node / 转发层**；
`--query-driver` 是 clangd 的启动参数，脚本会打印建议配置但**不代改 `.vscode/settings.json`**
（本模板 4 个 `.vscode` 文件刻意入库，Q8 保持现状）。处理 `Core/**` 前留意
`TEMPLATE-PLACEHOLDERS.md` D1 的 `formatOnSave` 陷阱。

## 脚本本体

| 脚本 | 作用 |
| ---- | ---- |
| `scripts/init-project.sh` / `.ps1` | 初始化新工程：A2 六处联动（`.ioc` 文件名、`ProjectName`、`ProjectFileName`、`.vscode/tasks.json`、`scripts/cubemx-generate.mx`、`README.md`）+ 仓库名 + README 标题；`--dry-run` 只打印不写文件、`--yes` 用默认值、`--flash 64k\|128k`（默认 64k，选 128K 提示同步 `board_build.ldscript`）、`--drop-examples` 顺带删除根级 `examples/` 与 README 的 EXAMPLES 标记区块（默认保留；`docs/bluepill/examples/` 副本保留） |
| `scripts/cubemx-init.mx` / `cubemx-generate.mx` | CubeMX 命令行脚本；`__PROJECT_DIR__` 绝对路径需人工填 |
| `scripts/init-clangd.sh\|.ps1`、`disable-clangd.sh\|.ps1` | clangd 编译数据库生成 / 清理 |
| `.vite-hooks/commit-msg` | 提交信息校验钩子（手写源文件，需自己启用） |

初始化脚本**不代做**的人工会明确打印出来：`cubemx-init.mx` 的 `__PROJECT_DIR__` 绝对路径、
目录名、`git remote -v` 远端地址、clangd 重新生成索引，以及资料台账字段按新板卡重填。
脚本不执行任何 git 写操作、不碰 `.git/config`、不改 `platformio.ini` 的锁定组合、
不动 `.ioc` 的引脚 / 时钟 / 外设内容。用法与参数见
[`TEMPLATE-PLACEHOLDERS.md`](TEMPLATE-PLACEHOLDERS.md) F–I 节。

## 资料入口

[`docs/bluepill/`](docs/bluepill/README.md) 是板卡与芯片资料的**单一权威入口**，
形态是「**官方直链索引 + 三级来源标注 + 少量自有整理 + 版权 / 体积硬约束**」，不是资料堆：

| 入口 | 去哪里 |
| ---- | ------ |
| 主索引（三级口径、四类入口对照、无官方厂商澄清、芯片手册直链） | [`docs/bluepill/README.md`](docs/bluepill/README.md) |
| 逐条来源 / 许可 / 访问证据台账（一行一条宽表） | [`docs/bluepill/SOURCES.md`](docs/bluepill/SOURCES.md) |
| 40-pin 速查、引脚复用、6 条硬件坑、最小系统要点 | [`docs/bluepill/board-pinout.md`](docs/bluepill/board-pinout.md) |
| 例程索引与 CubeIDE / MDK → PlatformIO 适配成本 | [`docs/bluepill/examples.md`](docs/bluepill/examples.md) |
| 示例资料副本（`--drop-examples` 删掉根级 `examples/` 后仍可查） | [`docs/bluepill/examples/README.md`](docs/bluepill/examples/README.md) |

三条必须记住的边界：

- **Blue Pill 没有「官方厂商」**：板卡页标 `Brand: Unknown` / `Origin: China`，PlatformIO 板卡定义
  `"vendor": "Generic"`，ST 官方社区版主明确表示 ST 资源只支持正品 ST 产品。够得上「大厂官方」的
  只有**芯片级**文档（DS5319 / RM0008 / AN2586 / CubeF1 Examples）。
- **MB1136 属于 NUCLEO-F103RB 板卡，不是 Blue Pill 原理图**：LQFP64 / F103RB / 128 KB，仅作
  ST 官方硬件设计范例，只存链接、不入库 PDF 原件。
- **本仓库不分发第三方原件**：ST Terms of Use 禁止未经书面许可复制 / 上传 / 再分发，
  所有 ST 官方 PDF **只存官方直链 + 自研摘要**；社区原理图按 Q9 条件入库且附
  [`ATTRIBUTION.md`](docs/bluepill/ATTRIBUTION.md)（适用范围仅限该原理图）。
  新增资料合计 **≤ 15 MB**（Q12 拍板，未收紧到 5 MB）。

<!-- BEGIN EXAMPLES -->
## examples

[`examples/`](examples/INDEX.md) 是**可选资料**：2 个自有最小示例（GPIO 点灯、USART1 115200）
+ 索引 + 3 篇四栏配方 + 复用仓库已有 `test/stdio_port_test.c` 的 L2 主机回归说明。
全部标注「**仅参考、需适配**」，**不进 `Core/`、不改 `.ioc`、不参与固件构建**，
按 Q4 拍板**不要求 `pio run`**、不触发 L3 / L4。统一接入路径是
「把外设配置抄进 `.ioc` → 生成 → 只拷源码 → `pio run` → 按 L2 / L3 / L5 验证」，见
[`examples/README.md`](examples/README.md)；资料侧索引与源码侧用相对链接互指。

派生工程不需要示例时，初始化脚本支持 `--drop-examples`（PowerShell 用 `-DropExamples`）
一并删掉根级 `examples/` 与本节（本节被 `<!-- BEGIN EXAMPLES -->` / `<!-- END EXAMPLES -->` 包住，
脚本按标记成对删除，不会留死链）；**`docs/bluepill/examples/` 的资料副本不受该参数影响**，
删掉根级示例后资料区仍可查。
<!-- END EXAMPLES -->

## 故障排查

- **`pio` 命令不存在**：安装 PlatformIO IDE 扩展后重启 VS Code，或 `pip install platformio`。
  Windows 集成终端通过 [settings.json](.vscode/settings.json) 的
  `terminal.integrated.env.windows` 将默认 `penv\Scripts` 放在 PATH 开头，
  避免旧的 pio shim 抢先匹配；修改设置后新建终端，再用 `Get-Command pio` 与 `pio --version` 核对。
  自定义 Core 目录时同步调整此路径；只更新系统 PATH 不会更新已打开终端的环境。
- **找不到下载器**：默认走 ST-Link（`upload_protocol = stlink`、`debug_tool = stlink`），
  底层调用 PlatformIO 自带的 OpenOCD + `interface/stlink.cfg`。
  Cortex-Debug 的 Debug/Attach 使用 `scripts/openocd-stlink.cfg`；锁定的 OpenOCD 包使用
  原生 `st-link` 驱动和 `transport select swd`。
  改用 CMSIS-DAP 时，将上述两项改为 `cmsis-dap`，并将 `.vscode/launch.json` 中两个
  `configFiles` 切换到 `scripts/openocd-cmsis-dap.cfg`。野火 FireDAP Lite 固件仅支持 SWD。
- **SWD 连接失败（`cannot read IDR` / `No ACK`）**：优先检查 SWDIO/SWCLK 是否接反、GND 是否共地、
  目标板是否独立供电；必要时降低 `debug_speed` 或改用「连接时复位」（`connect_assert_srst`）。
  ST-Link 报 `target voltage may be too low` / `init mode failed` 时，另查目标供电与 VTref 接线，
  以具体探针的引脚定义为准。
- **重复定义符号**：检查是否把 `Drivers/` 加入编译，或把 `system_stm32f1xx.c` 的排除规则删除了。
- **Flash 溢出**：PlatformIO 默认链接脚本按 64K 配置，若实际为 128K 需在 `platformio.ini` 中重新指定合适的 `board_build.ldscript`。

## 模板维护与验证

- 固定 ststm32 20.0.0、CubeF1 1.8.7、GCC ARM 7.2.1 和链接脚本包 0.3.0；
  CubeMX 实际版本以 exe 属性/运行日志为准，`.ioc` 的 6.17.0 是历史戳。
  本机工具记录见 [CubeMX 工具说明](docs/TOOLING-cubemx.md) §1.1。
  升级时需同步验证生成代码与构建，避免单独升级 HAL。
- 工程源码使用 C11、`-Wall -Wextra -Werror`；严格选项不施加于 HAL/CMSIS。
  每次链接输出 `.pio/build/genericSTM32F103C8/firmware.map`，便于检查段和符号布局。
  newlib-nano 默认不含浮点 printf；需要 `%f` 时，在 `platformio.ini` 中取消
  `-Wl,-u,_printf_float` 的注释并重新构建。它会增加 Flash/RAM，模板默认按需开启。
- `board_build.stm32cube.custom_config_header = yes` 保证使用 `Core/Inc/stm32f1xx_hal_conf.h`。
- Cortex-Debug 配置支持默认安装目录下的 Windows、Linux/macOS；WSL 使用 Linux 路径，
  探针还需能够被 WSL 访问。自定义 PlatformIO 安装目录需同步修改调试路径。
  启动调试使用 PlatformIO 的 Pre-Debug 任务生成调试固件；Attach 不自动构建或烧录。
- `Core/Src/stdio_port.c` 覆盖 CubeMX 的弱 `_read` / `_write`，适用于当前 newlib 工具链。
  未提供后端时返回 `-1` 并设置 `errno = ENOSYS`，不会调用不存在的函数。
  需要串口时，在独立用户源码中实现 `int __io_putchar(int ch)` 和
  `int __io_getchar(void)`：成功返回字符（0..255），失败返回负数。
  适配层在失败时返回已完成的字节数，或 `-1` / `EIO`；它本身不初始化 USART。
  不要把适配逻辑写回会被 CubeMX 重新生成的 `syscalls.c`。

### 验证关卡（L0–L5，沿用 AGENTS.md §3）

按改动类型选最小充分集，并在提交信息里写明做到了哪一级；**构建通过不等于能用**，
影响运行时行为的改动必须实板确认，并在结论里区分「编译通过」与「实板验证过」。

| 等级 | 做什么 | 适用 |
| ---- | ------ | ---- |
| L0 未验证 | 只读检查 | 仅限纯文档 |
| L1 静态 | 人工核对文件内容一致性 | 文档、配置 |
| L2 主机回归 | 下方两条 gcc 命令 | 动了 `Core/Src/stdio_port.c` 等可主机编译的代码 |
| L3 构建 | `pio run` | 任何影响编译的改动 |
| L4 生成核验 | CubeMX `-q` 重新生成后核对 `main.c` 的 `MX_xxx_Init` 与日志 | 任何 `.ioc` 改动（**必须**） |
| L5 实板 | 烧录 + 观察现象（LED / 串口 / 波形） | 影响运行时行为的改动 |

主机回归测试（需要 GCC，不需要开发板）：

```bash
# Linux / macOS
gcc -std=c11 -Wall -Wextra -Werror Core/Src/stdio_port.c test/stdio_port_test.c -o /tmp/stdio-test && /tmp/stdio-test
gcc -std=c11 -Wall -Wextra -Werror -DTEST_BACKEND Core/Src/stdio_port.c test/stdio_port_test.c -o /tmp/stdio-backend-test && /tmp/stdio-backend-test
pio run
```

Windows 下把输出路径 `/tmp/...` 换成当前目录，例如 `-o stdio-test.exe && ./stdio-test.exe`；
用项目内临时目录（如 `./.tmp-test/`）时**跑完删掉，别留在工作区**。
纯文档 / 配置只做 L1 时明确写「未运行构建」，**不复用旧构建数字**作为本次证据。

编译通过不代替实板验证：首次使用需检查烧录、PC13 闪灯、断点与 Attach。

HAL 状态机、UART 接收中断、共享定时器和错误路径的排查见
[HAL-PITFALLS.md](docs/HAL-PITFALLS.md)。USB CDC 的配置观察与尚未通过的生成门槛见
[TOOLING-cubemx.md](docs/TOOLING-cubemx.md) §3.5.6；模板没有内置 USB 中间件。

本次派生工程回填的逐项取舍、提交与验证证据见
[TEMPLATE-UPDATE-AUDIT.md](docs/TEMPLATE-UPDATE-AUDIT.md)。
