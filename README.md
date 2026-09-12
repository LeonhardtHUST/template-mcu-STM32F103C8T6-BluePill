# stm32-digital-clock

基于 STM32F103C8T6 的数字时钟，华中科技大学电工基地的招新题目。

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
.vscode/                 # 任务、调试、推荐扩展配置
platformio.ini           # PlatformIO 工程配置
stm32-digital-clock.ioc  # CubeMX 配置（唯一事实来源，请用 CubeMX GUI 修改）
```

## 修改外设配置的流程

1. VS Code 任务面板运行 **STM32CubeMX: Open .ioc**（或直接用 CubeMX 打开 `.ioc`）
2. 配置完成后点 **GENERATE CODE**（工具链保持 `Makefile`，不要改目录结构）
3. 回到 VS Code，用户代码写在 `main.c` 的 `/* USER CODE BEGIN */ ... /* USER CODE END */` 之间
4. `pio run` 重新编译

无头生成（CI/脚本）可用任务 **STM32CubeMX: Generate Code (CLI)**，脚本见
`scripts/cubemx-generate.mx`。若相对路径解析失败，请把脚本中的 `.ioc` 路径改为绝对路径，
并按需修改 `tasks.json` 中 CubeMX 的安装路径。

## 工作流约定（重要）

- **不要手动编辑 `.ioc` 文件**：引脚、时钟、外设参数必须在 STM32CubeMX GUI 中配置并保存。
  CLI 脚本只负责加载已有 `.ioc` 并生成代码，不能设置外设参数。
- HAL / CMSIS / 启动文件 / 链接脚本 **由 PlatformIO 的 framework 提供**，因此：
  - `Core/Src/system_stm32f1xx.c` 已在 `platformio.ini` 中排除，避免与 framework 的 CMSIS 重复定义符号；
  - `Drivers/`、`Makefile` 不参与 PlatformIO 编译，已加入 `.gitignore`；
  - 使用 PlatformIO 自带的 `STM32F103C8TX_FLASH.ld`，不再依赖 CubeMX 生成的链接脚本，
    避免每次 Generate Code 后需要手动补全 `.init_array` 等段。
- 新增外设后，若 `Core/Inc/stm32f1xx_hal_conf.h` 缺少对应 `HAL_XXX_MODULE_ENABLED`，
  在 CubeMX 中重新生成即可（CubeMX 会覆盖该文件，用户代码不要写在该文件里）。
- 当前时钟配置为默认 HSI 8 MHz。如需 HSE + 72 MHz，请在 CubeMX GUI 的
  *RCC / Clock Configuration* 中配置，保存后重新生成代码。

## 故障排查

- **`pio` 命令不存在**：安装 PlatformIO IDE 扩展后重启 VS Code，或 `pip install platformio`。
- **找不到下载器**：默认走 CMSIS-DAP（`upload_protocol = cmsis-dap`，底层调用 PlatformIO 自带的
  OpenOCD + `interface/cmsis-dap.cfg`）。用 ST-Link 就把 `platformio.ini` 里的
  `upload_protocol` / `debug_tool` 改回 `stlink`，并同步修改 `.vscode/launch.json` 的 `configFiles`。
  注意野火 **FireDAP Lite 固件仅支持 SWD，不支持 JTAG**。
- **SWD 连接失败（`cannot read IDR` / `No ACK`）**：优先检查 SWDIO/SWCLK 是否接反、GND 是否共地、
  目标板是否独立供电；必要时降低 `debug_speed` 或改用「连接时复位」（`connect_assert_srst`）。
- **重复定义符号**：检查是否把 `Drivers/` 加入编译，或把 `system_stm32f1xx.c` 的排除规则删除了。
- **Flash 溢出**：PlatformIO 默认链接脚本按 64K 配置，若实际为 128K 需在 `platformio.ini` 中重新指定合适的 `board_build.ldscript`。
