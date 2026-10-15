# template-mcu-STM32F103C8T6

STM32F103C8T6 最小工程模板，默认使用 HSI 8 MHz、PC13 闪灯和 CMSIS-DAP/SWD。
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

# 3. 烧录（CMSIS-DAP 探针接 SWD：SWDIO-PA13、SWCLK-PA14、GND 共地）
pio run -t upload

# 4. 调试：VS Code 运行面板选择 "Debug (OpenOCD / CMSIS-DAP)"
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
Core/Src                 # CubeMX 生成的用户源码（PlatformIO 的 src_dir）
Drivers/                 # CubeMX 生成的 HAL/CMSIS 库（不参与 PIO 编译，已 git 忽略）
scripts/                 # CubeMX 命令行脚本
test/                    # 系统 GCC 主机回归（不使用 pio test / Unity）
.vscode/                 # 任务、调试、推荐扩展配置
platformio.ini           # PlatformIO 工程配置
stm32-digital-clock.ioc  # CubeMX 配置（唯一事实来源）
AGENTS.md                # agent 工作约束（提交规范 / 硬约束 / 验证关卡）
TEMPLATE-PLACEHOLDERS.md # 复制模板后需要人工修改的占位符清单
docs/                    # 补充文档（如 docs/TOOLING-cubemx.md）
```

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
| 视硬件而定 | 探针（`cmsis-dap` / `stlink`）、`board`、Flash 容量、CubeMX 安装路径 |
| 环境前提 | 已装 CubeMX + FW_F1 包、PlatformIO Core、主机 GCC（仅回归测试用） |
| 已知陷阱 | `formatOnSave` 会重排 `main.c`；`.ioc` 的 `*IPParameters` 白名单；信号名的 `S_` 前缀 |

agent 的工作约束（提交规范、硬约束、验证关卡）见 **[`AGENTS.md`](AGENTS.md)**。

## 故障排查

- **`pio` 命令不存在**：安装 PlatformIO IDE 扩展后重启 VS Code，或 `pip install platformio`。
  Windows 集成终端通过 [settings.json](.vscode/settings.json) 的
  `terminal.integrated.env.windows` 将默认 `penv\Scripts` 放在 PATH 开头，
  避免旧的 pio shim 抢先匹配；修改设置后新建终端，再用 `Get-Command pio` 与 `pio --version` 核对。
  自定义 Core 目录时同步调整此路径；只更新系统 PATH 不会更新已打开终端的环境。
- **找不到下载器**：默认走 CMSIS-DAP（`upload_protocol = cmsis-dap`，底层调用 PlatformIO 自带的
  OpenOCD + `interface/cmsis-dap.cfg`）。用 ST-Link 就把 `platformio.ini` 里的
  `upload_protocol` / `debug_tool` 改回 `stlink`，并将 `scripts/openocd-cmsis-dap.cfg` 改用
  `interface/stlink.cfg` 和 `transport select hla_swd`。
  注意野火 **FireDAP Lite 固件仅支持 SWD，不支持 JTAG**。
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

主机回归测试（需要 GCC，不需要开发板）：

```bash
# Linux / macOS
gcc -std=c11 -Wall -Wextra -Werror Core/Src/stdio_port.c test/stdio_port_test.c -o /tmp/stdio-test && /tmp/stdio-test
gcc -std=c11 -Wall -Wextra -Werror -DTEST_BACKEND Core/Src/stdio_port.c test/stdio_port_test.c -o /tmp/stdio-backend-test && /tmp/stdio-backend-test
pio run
```

Windows 下把输出路径 `/tmp/...` 换成当前目录，例如 `-o stdio-test.exe && ./stdio-test.exe`。

编译通过不代替实板验证：首次使用需检查烧录、PC13 闪灯、断点与 Attach。

HAL 状态机、UART 接收中断、共享定时器和错误路径的排查见
[HAL-PITFALLS.md](docs/HAL-PITFALLS.md)。USB CDC 的配置观察与尚未通过的生成门槛见
[TOOLING-cubemx.md](docs/TOOLING-cubemx.md) §3.5.6；模板没有内置 USB 中间件。
