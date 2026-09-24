# 用 AI/CLI 修改 STM32CubeMX 配置：本机已装工具与实测结论

本文记录**本机（Leon 的 Windows 开发机）已经全局安装**的 CubeMX 自动化能力、如何接入，
以及一次真实实测得到的结论（哪些做法可行、哪些会静默失败）。
目的是让**任何** agent（不限于某个客户端）都能复用同一套能力，不必重新调研。

---

## 1. 已安装：`vscode-cube-mcp`（全局，MCP server）

| 项 | 值 |
| -- | -- |
| 包 | `vscode-cube-mcp` **v0.4.2**（MIT，PyPI） |
| 安装方式 | `uv tool install vscode-cube-mcp` |
| 可执行文件 | `C:\Users\Leon\.local\bin\vscode-cube-mcp.exe` |
| 是否在 PATH | ✅ `C:\Users\Leon\.local\bin` 已在用户 PATH 中，**新开进程即可直接调用** |
| 上游 | https://github.com/h666zhang/vscode-cube-mcp |
| 依赖 | Python ≥3.10、STM32CubeMX 6.x（本机 `C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeMX\STM32CubeMX.exe`） |

**为什么选它**：它只依赖 CubeMX（本机没装 STM32CubeIDE），原生面向 Windows，
且内置 STM32F103 的引脚→信号名对照与 TIM 配置补丁 —— 正好补上 §3 里那个"静默失败"的坑。

### 用户级环境变量（已写入，`User` 作用域，任何 agent 都能读到）

| 变量 | 当前值 |
| ---- | ------ |
| `ST_CUBEMX_EXE` | `C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeMX\STM32CubeMX.exe` |
| `ST_CUBEMX_ALLOWED_ROOTS` | `D:\Projects;C:\Users\Leon\WorkBuddy` |
| `ST_CUBEMX_TIMEOUT` | `300`（秒） |

> `ALLOWED_ROOTS` 是**安全白名单**：超出范围的 `.ioc` 路径会被拒绝。
> 换机器 / 换工作目录时要改这一项，否则工具会报"路径不在允许范围内"。

### 接入 MCP 客户端

任何 MCP 客户端都按同一段配置接入（`env` 可省略，因为有用户级环境变量兜底）：

```json
{
  "mcpServers": {
    "vscode-cube-mcp": {
      "command": "C:/Users/Leon/.local/bin/vscode-cube-mcp.exe",
      "args": [],
      "env": {
        "ST_CUBEMX_EXE": "C:/Program Files/STMicroelectronics/STM32Cube/STM32CubeMX/STM32CubeMX.exe",
        "ST_CUBEMX_ALLOWED_ROOTS": "D:/Projects;C:/Users/Leon/WorkBuddy",
        "ST_CUBEMX_TIMEOUT": "300"
      }
    }
  }
}
```

### 工具清单（9 个，实测握手返回）

| 工具 | 作用 | 是否写文件 |
| ---- | ---- | ---------- |
| `cubemx_help` | 内置帮助：可用模板、各外设配置命令、已知坑（陌生 agent **建议第一个调用**） | 否 |
| `cubemx_load` | 加载 `.ioc` 并回读关键配置 | 否（只读） |
| `cubemx_configure` | 加载 `.ioc` → 执行 `set` 命令 → 写回（**先备份**） | 是 |
| `cubemx_generate` | 加载 `.ioc` 并 `project generate`，产出 HAL 工程 | 是 |
| `cubemx_export_pinout` | 导出引脚配置 CSV | 否 |
| `cubemx_new_project` | 从零建工程（内置最小模板库 + `commands` 现配外设） | 是 |
| `cubemx_remove_peripheral` | 从 `.ioc` 移除外设（文本方式，会同步 `Mcu.Pin*`/`PinsNb`/`functionlistsort`） | 是 |
| `cubemx_add_source` | 把自定义源文件加入 CMake 源列表 | 是 |
| `cubemx_script` | 任意 CubeMX 脚本命令序列（逃生通道，原样传给 `-q`） | 取决于脚本 |

### 冒烟测试（不依赖任何客户端）

```powershell
# 进程能起来并保持等待 = server 正常（stdio 协议，Ctrl+C 退出）
C:\Users\Leon\.local\bin\vscode-cube-mcp.exe
```

已实测通过完整的 MCP 握手：`initialize` 返回 `serverInfo.name = "Vscode_cube_mcp"`、
`protocolVersion = 2024-11-05`；`tools/list` 返回上述 9 个工具。

---

## 2. 直接调 CubeMX CLI（不装任何东西也能用）

CubeMX 自带命令行脚本模式，上面那个 MCP 本质就是它的封装。原始用法：

```powershell
$mx = 'C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeMX'
# 推荐用官方文档给的调用式（本机实测可行）
& "$mx\jre\bin\java.exe" -jar "$mx\STM32CubeMX.exe" -q 'C:\path\to\script.mx'
```

`script.mx` 每行一条命令，常用：

```
config load  C:\path\to\proj.ioc     # 加载（相对路径依赖 cwd，建议写绝对路径）
project generate                     # 生成代码；不带路径则生成到 .ioc 所在目录
config save  C:\path\to\proj.ioc     # 原地规范化写回
config saveas C:\path\to\other.ioc   # 另存（注意：会同时改工程名，见 §3）
csv pinout   C:\path\pins.csv        # 导出引脚表
exit
```

本机实测一次完整"加载 + 生成"约 **155 秒**（CubeMX 是 JVM 应用，启动慢），超时阈值别设太小。

---

## 3. 实测结论：手改 `.ioc` 到底行不行？

用真实实验（STM32F103C8T6 模板 `.ioc`，手写文本 → `-q` 生成）验证：

### ✅ 可行

手写的这些配置被 CubeMX **完整接受**，并正确反映到生成的 `Core/Src/main.c`：

| 手写内容 | 结果 |
| -------- | ---- |
| `RCC.HSE_VALUE=8000000` + `RCC.PLLMUL=RCC_PLL_MUL9` + `PLLSourceVirtual=RCC_PLLSOURCE_HSE` + `SYSCLKSource=RCC_SYSCLKSOURCE_PLLCLK` | ✅ 生成 `RCC_PLLSOURCE_HSE` + `RCC_PLL_MUL9`，主频到 **72 MHz**（APB1 36 / APB2 72） |
| `USART1.VirtualMode=VM_ASYNC` + `BaudRate=115200` + `PA9/PA10` 信号 | ✅ 生成 `MX_USART1_UART_Init()` |
| `PB0.Signal=GPIO_Input` + `GPIO_PuPd=GPIO_PULLUP` | ✅ 生成 `GPIO_PIN_0` 上拉输入 |

并且 CubeMX 会把文件**规范化**：重排 `Mcu.Pin*`、重算派生参数（补上 `RCC.ADCFreqValue`、`APB2TimFreq_Value` 等）、
把新 key 并入 `RCC.IPParameters`。**所以 headless 产生的 `.ioc` 就是 CubeMX 自己的格式，GUI 能继续处理**。

> 结论：模板 README 原先写的"不要手动编辑 `.ioc`，CLI 只能加载不能设置参数"**不准确** —— CLI 确实能设置参数。

### ❌ 但会静默失败（真正的坑）

同一批实验里，TIM2 输入捕获**没有生效**：`Mcu.IP3=TIM2` 从输出的 `.ioc` 里消失了、
`PA0-WKUP.Signal` 被剥离、`main.c` 里没有 `MX_TIM2_Init()`，而 `project generate` **依然返回成功**。

原因在日志里只有一行 INFO：

```
[INFO] ImportTextPane:234 - (OptionalMessage_ERROR) Cannot map signal (TIM2_CH1_ETR) on pin (PA0-WKUP)
```

根因：**PA0 上的信号名是带 `S_` 前缀的组合枚举**，正确写法是 `S_TIM2_CH1_ETR`（不是 `TIM2_CH1_ETR`）。

由此得到两条**必须遵守**的规则：

1. `.ioc` 里每个外设有一行 `<IP>.IPParameters=a,b,c` 白名单 —— **手加的参数必须同步补进这一行**，否则被忽略。
2. 任何 `.ioc` 改动后**必须核验**：①日志里没有 `Cannot map` / `OptionalMessage_ERROR`；
   ②生成的 `main.c` 里有对应的 `MX_xxx_Init()`。**"generate 返回 0"不等于"配置生效了"。**

### ⚠️ 其它实测细节

- `config saveas` 会把 `ProjectManager.ProjectName` / `ProjectFileName` 一起改成新文件名，
  想"原地规范化"要用 `config save`，不是 `saveas`。
- CubeMX 会弹出 GUI 对话框（迁移/提示类）—— `-q` 并非完全无人值守，**首次在新版本上运行需要有人点一下**。
- 想批量改 `.ioc` 建议直接用 `cubemx_configure`（带备份 + 路径白名单），比裸手改安全。

---

## 4. 调研过但**不推荐**的方案（省得再查一遍）

| 方案 | 结论 | 理由 |
| ---- | ---- | ---- |
| `stm32cubemx-mcp`（Wafleem） | ❌ 不装 | 安全模型很好（SHA-256 + 备份 + plan/apply），但**项目生成依赖 STM32CubeIDE**，本机只装了 CubeMX；且需 `pipx`（本机没有，只有 `uv`） |
| `stm32pio`（PyPI） | ❌ 不装 | 最后一次发版 **2021-10-07**，已 5 年未维护；社区反馈常见生成报错；且它面向 PlatformIO 工程重建，与本模板既有的 `platformio.ini` 会冲突 |
| ClawHub `stm32-cubemx` skill | ❌ 不装 | 是给 OpenClaw 的技能（本质是一份"怎么用 CubeMX CLI"的文档 + 目录约定），不是可执行能力；能力本身我们已经有了 |
| STM32Cube-MCP（brovk2008） | ❌ 不装 | 34 个工具里大部分是烧录/GDB/串口/IDE GUI 自动化，远超"改配置"需求，且会碰硬件 |

**结论：CubeMX 官方 CLI（已在系统 PATH）是底座，`vscode-cube-mcp` 是安全封装，二者已装好。不要再装重复能力。**
