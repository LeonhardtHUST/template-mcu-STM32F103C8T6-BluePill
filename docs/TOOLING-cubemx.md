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
| 依赖 | Python ≥3.10、STM32CubeMX 6.x（本机 `C:\ST\STM32CubeMX\STM32CubeMX.exe`，见 §1.1） |

**为什么选它**：它只依赖 CubeMX，原生面向 Windows，
且内置 STM32F103 的引脚→信号名对照与 TIM 配置补丁 —— 正好补上 §3 里那个"静默失败"的坑。

### 1.1 ⚠️ CubeMX 安装位置（换机器时第一个要确认的东西）

本机 `C:\ST` 下有 **4 套 ST 工具**，容易踩错：

| 路径 | 是什么 | 能否给 `vscode-cube-mcp` 用 |
| ---- | ------ | --------------------------- |
| `C:\ST\STM32CubeMX` | **经典 CubeMX**，`-q` 脚本模式就在这 | ✅ **就是它**（唯一一份 `STM32CubeMX.exe`） |
| `C:\ST\STM32CubeMX2_1.1.1` | CubeMX **2**（下一代，架构不同） | ❌ 无 `db\mcu`，`-q` 用法也不同 |
| `C:\ST\STM32CubeIDE_2.2.0` | STM32CubeIDE | ❌ 不提供独立 `STM32CubeMX.exe` |
| `C:\ST\STM32CubeCLT_1.22.0` | 命令行工具链 | ❌ 只有 gdb/Programmer_CLI |

两个必须知道的坑：

1. **官方安装器默认会装到 `C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeMX\`，
   但本机那个目录不存在**（历史残留路径）。定位时**不要靠猜标准路径，直接全盘搜**：
   ```powershell
   Get-ChildItem "C:\" -Recurse -Depth 4 -Filter "STM32CubeMX.exe" -ErrorAction SilentlyContinue |
     Select-Object -ExpandProperty FullName
   ```
2. **exe 的 PE 版本号会骗人**：`C:\ST\STM32CubeMX\STM32CubeMX.exe` 的 FileVersion 报
   `6.18.1-RC2`，但真正跑起来写进 `.ioc` 的是 `MxCube.Version=6.17.0` / `MxDb.Version=DB.6.0.170`。
   **判断版本一律看生成的 `.ioc`，不要看文件属性。**

> 2026-09-24 复查：`ST_CUBEMX_EXE` 曾被写成那个不存在的 `Program Files\...` 路径，
> 导致全局装好的 MCP **实际不可用**（只是没人去调它所以没暴露）。已修正为 `C:\ST\STM32CubeMX\STM32CubeMX.exe`。

### 用户级环境变量（已写入，`User` 作用域，任何 agent 都能读到）

| 变量 | 当前值 |
| ---- | ------ |
| `ST_CUBEMX_EXE` | `C:\ST\STM32CubeMX\STM32CubeMX.exe` |
| `ST_CUBEMX_ALLOWED_ROOTS` | `D:\Projects;C:\Users\Leon\WorkBuddy` |
| `ST_CUBEMX_TIMEOUT` | `300`（秒） |

> 校验方法（PowerShell 里 `$env:X` 读不到刚写入的变量，必须走 .NET API）：
> ```powershell
> [Environment]::GetEnvironmentVariable('ST_CUBEMX_EXE','User')
> ```

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
        "ST_CUBEMX_EXE": "C:/ST/STM32CubeMX/STM32CubeMX.exe",
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
$mx = 'C:\ST\STM32CubeMX'
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

根因：**信号名必须与 CubeMX 器件数据库一致，而数据库版本会变。**

直接查本机数据库就能拿到权威答案 —— 每个 `<Pin>` 节点列出了该引脚在本型号上
可用的全部信号名：

```text
<CubeMX 安装目录>\db\mcu\STM32F103C(8-B)Tx.xml
```

> 文件名的括号是陷阱：`*103C8*` **匹配不到** `STM32F103C(8-B)Tx.xml`。
> 要搜就用 `*F103*` 或 `*C(8-B)*`。本机实测路径 = `C:\ST\STM32CubeMX\db\mcu\STM32F103C(8-B)Tx.xml`。

本机（`MxCube.Version=6.17.0` / `MxDb.Version=DB.6.0.170`）的实测结果，
2026-09-24 用 `<Pin Name="PA0...">` 节点重新提取复核过：

| 引脚 | 可用 TIM2 信号 |
| ---- | -------------- |
| `PA0-WKUP` | **`TIM2_CH1`**、`TIM2_ETR` |

于是：`TIM2_CH1_ETR` 在任何版本都不存在；
`S_TIM2_CH1_ETR` 是 **CubeMX 6.18** 的写法（本机 6.17 数据库里查不到，实测
连 `S_TIM2_CH1` 这个前缀都不存在，**不要在 6.17 上用**）；本机正确写法是 `TIM2_CH1`。

> **通用结论：不要照抄任何外部文档或记忆里的信号名，一律先查本机 `db\mcu\*.xml`。**
> 这也是为什么该工具内置了自己维护的引脚→信号对照表。

由此得到两条**必须遵守**的规则：

1. `.ioc` 里每个外设有一行 `<IP>.IPParameters=a,b,c` 白名单 —— **手加的参数必须同步补进这一行**，否则被忽略。
2. 任何 `.ioc` 改动后**必须核验**：①日志里没有 `Cannot map` / `OptionalMessage_ERROR`；
   ②生成的 `main.c` 里有对应的 `MX_xxx_Init()`。**"generate 返回 0"不等于"配置生效了"。**

### ⚠️ 其它实测细节

- `config saveas` 会把 `ProjectManager.ProjectName` / `ProjectFileName` 一起改成新文件名，
  想"原地规范化"要用 `config save`，不是 `saveas`。
- **`-q` 不保证无人值守（实测 3 次中 2 次卡住）**：卡点固定在 CubeMX 的**更新器 / 插件扫描阶段**，
  日志停在 `[ERROR] WebUtils:658 - Updater is busy`、`[WARN] ThirdParty:871 - waiting for
  thirdparty lock release`，且 `~\.stm32cubemx\plugins\updater`、`plugins\power` 的时间戳
  与停滞时刻吻合。此时进程会一直挂着不退出（一次实测停滞 >10 分钟）。
  **对策：必须设超时并强杀进程树** —— `vscode-cube-mcp` 已内置（`ST_CUBEMX_TIMEOUT` 默认 240s，
  超时后强杀进程树）。裸调 CLI 时请自行加超时。卡住后若日志再无新增，直接杀掉重试即可。
- 首次在新版本上运行可能弹一次迁移/提示对话框，需要有人点一下；之后一般不再出现。
- 想批量改 `.ioc` 建议直接用 `cubemx_configure`（带备份 + 路径白名单），比裸手改安全。

---

## 4. 调研过但**不推荐**的方案（省得再查一遍）

| 方案 | 结论 | 理由 |
| ---- | ---- | ---- |
| `stm32cubemx-mcp`（Wafleem） | ❌ 不装 | 安全模型很好（SHA-256 + 备份 + plan/apply），但**代码生成走 STM32CubeIDE**（本机虽有 `C:\ST\STM32CubeIDE_2.2.0`，但它的生成路径与 CubeMX CLI 不是一回事，且要另配 IDE 工作区）；安装依赖 `pipx`（本机只有 `uv`）。能力已被 `vscode-cube-mcp` 覆盖 |
| `stm32pio`（PyPI） | ❌ 不装 | 最后一次发版 **2021-10-07**，已 5 年未维护；社区反馈常见生成报错；且它面向 PlatformIO 工程重建，与本模板既有的 `platformio.ini` 会冲突 |
| ClawHub `stm32-cubemx` skill | ❌ 不装 | 是给 OpenClaw 的技能（本质是一份"怎么用 CubeMX CLI"的文档 + 目录约定），不是可执行能力；能力本身我们已经有了 |
| STM32Cube-MCP（brovk2008） | ❌ 不装 | 34 个工具里大部分是烧录/GDB/串口/IDE GUI 自动化，远超"改配置"需求，且会碰硬件 |

**结论：CubeMX 官方 CLI 是底座，`vscode-cube-mcp` 是安全封装，二者已装好。不要再装重复能力。**

---

## 5. 烧录 / 实板侧的 MCP（与本节主题不同，但同属一条工具链）

本机另外还装了两个**碰硬件**的 MCP server（机器级说明见
`C:\Users\Leon\.workbuddy\mcp-servers\PROJECT-SETUP.md`）。它们**不能替代**上面的
`vscode-cube-mcp`（一个只改配置、一个只碰硬件），分工如下：

| server | 本工程能否用 | 说明 |
| ------ | ------------ | ---- |
| `stm32-stlink`（stmcp） | ❌ **不适用** | 整个架构建立在 `ST-LINK_gdbserver` + `STM32_Programmer_CLI` 之上，两者都只认 ST-LINK。本工程用的是**野火 FireDAP Lite（CMSIS-DAP，仅 SWD）**，stmcp 根本驱动不了 |
| `agentic-hil` | ✅ **适用** | `debuggers.<名>.type` 枚举含 `openocd` / `pyocd`，这两个后端都支持 CMSIS-DAP，是将来做**实板验证（L5）**的正路 |

`agentic-hil` 用在 CMSIS-DAP 板子上的要点（实测环境 `agentic-hil` 0.21.5）：

1. **配置不在仓库里**，按工作目录哈希生成，在
   `%APPDATA%\agentic-hil\projects\<文件夹名>-<hash>\config.yaml`。
   这是故意的（agent 改不了自己的权限）。
2. **不要手写配置**（所有权限默认 `false`，手写等于什么都没开）。用 CLI：
   `agentic-hil init`（建配置+doctor）/ `agentic-hil adopt-hardware`（补硬件身份）
   / `agentic-hil grant <权限名>`（按需开关单条权限）。
3. **必须覆盖这两个 OpenOCD 配置项**（默认值是 ST-LINK 形状的）：
   ```yaml
   debuggers:
     dap:
       type: "openocd"
       executable: "C:/Users/Leon/.platformio/packages/tool-openocd/bin/openocd.exe"
       interface_cfg: "interface/cmsis-dap.cfg"   # 默认 interface/stlink.cfg
       target_cfg: "target/stm32f1x.cfg"          # 默认 target/stm32f4x.cfg
       interface: "SWD"                            # 大写！枚举 SWD / JTAG
       connect_mode: "under_reset"                 # 下划线！枚举 hotplug / under_reset
   ```
   字段拼写是坑：`interface` 大写、`connect_mode` 用下划线（和 stmcp 的小写 `swd` 不一样）。
4. **OpenOCD 不在 PATH 上**：`agentic-hil debugger-probes` 实测报
   `openocd (OpenOCD) not on this host`，因为 PlatformIO 把它装在
   `~/.platformio/packages/tool-openocd/bin`，且脚本目录是
   `.../tool-openocd/openocd/scripts`（**不是** `.../tool-openocd/scripts`）。
   所以 `executable` 必须写绝对路径，别指望自动发现。
5. **一个 SWD 只能有一个主人**：OpenOCD / pyocd / agentic-hil / stmcp 会互抢探针，
   报 "unable to find a matching CMSIS-DAP device" 或 busy 时先查是否有残留进程。

裸调 OpenOCD（不经过任何 MCP）的已验证命令见 skill `stm32-cmsis-dap-flash` §4：

```bash
"$OCD" -s "$SCR" -f interface/cmsis-dap.cfg -c "transport select swd" -f target/stm32f1x.cfg \
  -c "init" -c "flash probe 0" \
  -c "program .pio/build/genericSTM32F103C8/firmware.elf verify reset exit"
```
