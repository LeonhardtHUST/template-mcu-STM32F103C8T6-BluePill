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
2. **exe 的 PE 版本号基本可信，但 `.ioc` 里的版本戳会骗人**：
   `C:\ST\STM32CubeMX\STM32CubeMX.exe` 的 FileVersion 报 `6.18.1-RC2`，这是**真的**。
   反过来，`.ioc` 里写着 `MxCube.Version=6.17.0` / `MxDb.Version=DB.6.0.170` **才是假的** ——
   那是模板继承下来的旧戳，CubeMX 会**原样保留**。
   让 CubeMX 自己 `config save`/`saveas` 一次，写回的就是真版本（`6.18.1` / `DB.6.0.181`）。
   **判断版本：看 exe 属性，或让它自己 save 一次看写回值；不要信 `.ioc` 里的旧戳。**
   ⚠️ 这个旧戳不只是难看 —— 它就是 `-q` 卡死的原因（版本不匹配 → 弹迁移框），见 §3.5.1。

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

本机实测结果（**版本已更正，见 §3.5**）：

| 引脚 | 库里的原子信号名（查用） | 写进 `.ioc` 的组合名（写用） |
| ---- | ------------------------ | ---------------------------- |
| `PA0-WKUP` | `TIM2_CH1`、`TIM2_ETR` | **`S_TIM2_CH1_ETR`** |

于是：`TIM2_CH1_ETR`（无 `S_`）在任何情况下都不对；
`.ioc` 里必须写**组合名** `S_TIM2_CH1_ETR`；而查"这脚能用什么"要查库里的**原子名**。
这两者不是一个层面的东西 —— 早期文档把二者混为一谈，是错的。

> **通用结论：不要照抄任何外部文档或记忆里的信号名，一律先查本机 `db\mcu\*.xml`。**
> 这也是为什么该工具内置了自己维护的引脚→信号对照表。

由此得到两条**必须遵守**的规则：

1. `.ioc` 里每个外设有一行 `<IP>.IPParameters=a,b,c` 白名单 —— **手加的参数必须同步补进这一行**，否则被忽略。
2. 任何 `.ioc` 改动后**必须核验**：①日志里 `Cannot map signal` 为 **0**，`OptionalMessage_ERROR`
   只允许出现在 `AGENTS.md` §2.3 的**豁免清单**里（`Pin<N> (VP_RIF_VS_RIF1)` 与 DMA 导入顺序噪音，
   两类消息的实测原文行见 §3.5.6.1 / §3.5.6.2）；
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

## 3.5 2026-09-25 端到端复测：更正 + 完整可用配方

把「HSE 8 MHz ×9 = 72 MHz + TIM2_CH1 输入捕获(PA0) + USART1 115200 + PB0 上拉按键」
整条链路真跑通了一次（沙箱 `_iotest/r5`，生成物 `Core/Src/tim.c` 里有完整 `MX_TIM2_Init`）。
过程中**推翻了本文档早期的三条结论**：

| 项 | 早期结论（错） | **实测真相** |
| -- | --- | --- |
| 本机 CubeMX 版本 | `6.17.0` / `DB.6.0.170` | **`6.18.1` / `DB.6.0.181`**。`.ioc` 里的 6.17.0 是**模板继承的旧戳被原样保留**；要看真实版本必须让 CubeMX 自己 `config save` 一次再看写回值 |
| PA0 的信号名 | `TIM2_CH1` | `.ioc` 要写**组合名 `S_TIM2_CH1_ETR`**；`db\mcu\*.xml` 列的是原子名。见 §3 更正表 |
| `-q` 卡死原因 | 卡在更新器/插件扫描（`Updater is busy`） | **真凶是 `ProjectManager.AskForMigrate=true`** → 弹模态迁移框等人点，无头模式永久挂住。`Updater is busy` / `Failed to refresh advertisement data` **只是噪音，不阻塞**（带这行 ERROR 也生成了两次） |

### 3.5.1 卡死根治：关掉 AskForMigrate

```powershell
# .ioc 里把 ProjectManager.AskForMigrate 改成 false（生成前每次都要关！CubeMX 的 save 会改回 true）
(Get-Content $ioc -Raw) -replace 'ProjectManager\.AskForMigrate=true', 'ProjectManager.AskForMigrate=false' |
  Set-Content $ioc -NoNewline -Encoding UTF8
```

现象特征：`~\.stm32cubemx\STM32CubeMX.log` 停在 `UtilMem:75 - Begin LoadConfig()` 后整段无输出，进程 >300 s 不退出。
历史上"手点一次 Yes 就好了"正是点了这个框。

### 3.5.2 `cubemx_configure` ≠ `cubemx_new_project`（**关键**）

`cubemx_configure` 是**纯脚本透传**：

```python
lines = [f'config load "{ap}"']
lines.extend(commands)            # 你的命令原样喂给 CubeMX -q 脚本引擎
lines.append(f'config saveas "{ap}"')
```

它**不做任何文本注入** —— 把 `set ip parameters TIM2 InputCapture ...` 交给它，CubeMX 回 `OK` 然后什么都不做
（实测：三个命令全 `OK`，`.ioc` 里**一个字节的 TIM2 都没变**）。真正的注入逻辑写在 `cubemx_new_project` 里。

**可用配方（`cubemx_new_project`）**：

```json
{"project_name": "freqtest", "project_dir": "<绝对路径>", "mcu": "STM32F103C8T6",
 "clock_source": "HSE", "pll_mul": 9,
 "commands": ["set ip parameters TIM2 InputCapture PA0-WKUP S_TIM2_CH1_ETR Prescaler 1 Period 65536",
              "set pin PB0 GPIO_Input",
              "set pin PA9 USART1_TX", "set pin PA10 USART1_RX", "set mode USART1 Asynchronous"]}
```

返回 `TIM2 已注入输入捕获标准表达(引脚 PA0-WKUP/S_TIM2_CH1_ETR, IC1 上升沿 + IC2 下降沿, ...)`，
生成物实测包含：

```c
void MX_TIM2_Init(void) {
  htim2.Instance = TIM2;
  htim2.Init.Prescaler = 1-1;      /* PSC = 0，注意是"未求值表达式"，合法 C */
  htim2.Init.Period = 65536-1;     /* ARR = 65535 */
  HAL_TIM_IC_Init(&htim2);
  sConfigIC.ICPolarity = TIM_INPUTCHANNELPOLARITY_RISING;
  sConfigIC.ICSelection = TIM_ICSELECTION_DIRECTTI;
  sConfigIC.ICPrescaler = TIM_ICPSC_DIV1;
  HAL_TIM_IC_ConfigChannel(&htim2, &sConfigIC, TIM_CHANNEL_1);
}
```

`Prescaler n` / `Period n` 会以 **`n-1` 字面量**写进 `.ioc`（`Prescaler 1` → `1-1`）
—— 所以**传的是分频数/计数长度，不是最终寄存器值**：要 PSC=0/ARR=65535 就传 `Prescaler 1 Period 65536`。
这也说明 `Period=65536-1` 是 CubeMX 认可的**原生形态**（它自己 `saveas` 也原样保留）。

### 3.5.3 ⛔ TIM 通道参数改不动（CubeMX 6.18.1 的真实限制）

想让 `IC1PSC = ÷8`（该次 TIM2 实验要求每 8 个上升沿捕获一次），三种办法**全部失败**，生成代码恒为 `TIM_ICPSC_DIV1`：

| 办法 | 结果 |
| ---- | ---- |
| 文本改 `TIM2.IC1Prescaler=TIM_ICPSC_DIV8` | ❌ 生成 DIV1 |
| `set ip parameters TIM2 IC1Prescaler TIM_ICPSC_DIV8` | ⚠️ **能**改到 `.ioc`（连 CubeMX `saveas` 出的也是 DIV8），但生成仍是 DIV1 |
| 同一脚本 `config load` → `set` → `project generate` | ❌ 生成 DIV1 |

根因：`config load` 时 CubeMX 会**按 `SH.<signal>.0=...` 表达式重建 TIM 通道模型**，
通道级参数（`IC1Polarity/IC1Selection/IC1Prescaler/IC1Filter`）用默认值填，**文件里的值被忽略**。
副作用之一：IC2 参数也会被一起丢掉（`SH` 只声明了 CH1）—— 对本工程恰好是我们想要的。

**对策：`÷8` 写进用户代码**，放 `/* USER CODE BEGIN TIM2_Init 2 */`（CubeMX 不会覆盖）。
**该实验工程的补充代码如下**；模板默认未启用 TIM2，`Core/Src/main.c` 中没有此补丁：

```c
TIM2->CCMR1 &= ~TIM_CCMR1_IC1PSC;   /* 只清 IC1PSC[1:0]（bit3:2），保留 CC1S=01 */
TIM2->CCMR1 |= TIM_CCMR1_IC1PSC;    /* 0b11 = 每 8 个事件捕获一次 */
```

好处：不依赖 CubeMX 的生成行为，重新 generate 也不会丢。
时机：晚于 `HAL_TIM_IC_ConfigChannel`；`HAL_TIM_IC_Start_DMA` 运行时不会再动这两个位。

### 3.5.4 其它复测坑

- **`project path` 指到别处 + 未规范化的 `.ioc` → 路径被叠两次**
  （`…\r9\gen\freqtest\C:\Users\…\r9\gen\freqtest\Core\Src\sysmem.c`）。先生成到 `.ioc` 同目录，或先 `config save` 规范化。
- **判断"生效"永远看生成物**。`config load` / `set` / `saveas` 可以全 `OK` 而结果全是默认值。
  要在 `.ioc` 层面判定，用 `config load` + `config saveas` 到新路径再 diff —— **能被保存下来的才是真的**。

### 3.5.5 ✅ DMA 块怎么写（2026-09-25 新验证）

`.ioc` 里 DMA 的键是 `Dma.<请求名>.<序号>.<参数>` —— **请求名不是 IP 名**。
权威来源：`db\mcu\IP\DMA-STM32F103G_dma_v1_0_Modes.xml`（本芯片 DMA IP `Version="STM32F103G_dma_v1_0"`）
里的 `<RefMode Name="TIM2_CH1">`；它嵌在 `<Mode Name="DMA1_Channel5">` 之下
→ **TIM2_CH1 固定映射 DMA1_Channel5**（与 RM0008 一致）。

```ini
Dma.Request0=TIM2_CH1
Dma.RequestsNb=1
Dma.TIM2_CH1.0.Direction=DMA_PERIPH_TO_MEMORY
Dma.TIM2_CH1.0.Instance=DMA1_Channel5
Dma.TIM2_CH1.0.MemDataAlignment=DMA_MDATAALIGN_HALFWORD
Dma.TIM2_CH1.0.MemInc=DMA_MINC_ENABLE
Dma.TIM2_CH1.0.Mode=DMA_NORMAL
Dma.TIM2_CH1.0.PeriphDataAlignment=DMA_PDATAALIGN_HALFWORD
Dma.TIM2_CH1.0.PeriphInc=DMA_PINC_DISABLE
Dma.TIM2_CH1.0.Priority=DMA_PRIORITY_LOW
Dma.TIM2_CH1.0.RequestParameters=Instance,Direction,PeriphInc,MemInc,PeriphDataAlignment,MemDataAlignment,Mode,Priority
```

另需：`NVIC.*` 加一行
`NVIC.DMA1_Channel5_IRQn=true\:0\:0\:false\:false\:true\:false\:true\:false`
（9 段掩码，照 `SysTick_IRQn` 的形态写，CubeMX 原样保留）；
并把 `MX_DMA_Init` 排进 `ProjectManager.functionlistsort`，**要排在用到 DMA 的外设之前**。
无需改 `Mcu.IP*` —— CubeMX 自己会把 `DMA` 加进 `Mcu.IP0`。

**生成物（逐条核对过）**

| 文件 | 得到 |
| ---- | ---- |
| `Core/Src/main.c` | `DMA_HandleTypeDef hdma_tim2_ch1;` + `MX_DMA_Init()`（内含 `HAL_NVIC_SetPriority/EnableIRQ(DMA1_Channel5_IRQn)`） |
| `Core/Src/stm32f1xx_hal_msp.c` | `hdma_tim2_ch1.Instance = DMA1_Channel5;`（含 7 个 `Init.*`） + `__HAL_LINKDMA(htim_ic,hdma[TIM_DMA_ID_CC1],hdma_tim2_ch1);` |
| `Core/Src/stm32f1xx_it.c` | `DMA1_Channel5_IRQHandler()` |

> ⚠️ **日志会报 8 行"假错误"**：每个参数一行
> `IP (DMA) : Parameter (xxx) has Id (TIM2_CH1) currently not set`。
> 这是**导入顺序噪音** —— CubeMX 按字母序先解析 `Dma.*`、后解析 `Mcu.IP*`，
> 解析 DMA 时 TIM2 尚未建立。**生成结果完全正确，不要去"修"它。**
> 2026-11-05 补测：这 8 行**确实带 `(OptionalMessage_ERROR)` 前缀**（原文行见 §3.5.6.2），
> 已按「已知豁免项」写进 `AGENTS.md` §2.3 的豁免清单（含识别条件），不是靠"顺手忽略"混过去。
> `Pin10 (VP_RIF_VS_RIF1) cannot be retrieved` 同属豁免清单（成因见 §3.5.6 的 2026-11-05 定位）。
> ⚠️ 但 `RCC ... has invalid value` **不在豁免内**：它同样带 `(OptionalMessage_ERROR)`，语义是
> 「缓存时钟值与本工程实际配置不一致」，属**真错误** —— 按 §3.5.6 的做法清掉过期 RCC 缓存字段后
> 它就会消失（2026-10-15 的 `usb-report` 日志里有、`usb-clean` 日志里没有，正是清理前后的对照）。
> 本行此前的"同理忽略 `RCC ... has invalid value`"措辞是错的，2026-11-05 已更正。

**附带澄清：`CoupleFile` 决定生成物形状**

`ProjectManager.CoupleFile=false`（本模板与 measure 仓库都是）→ **不生成**
`gpio.c` / `tim.c` / `usart.c` / `dma.c`，所有 `MX_xxx_Init()` 全部落在 `Core/Src/main.c`。
沙箱 r5 之所以有 `tim.c`，是因为它 `CoupleFile=true`。
**别因为「没看到 `tim.c`」就以为外设没生效 —— 去看 `main.c`。**

### 3.5.6 USB Device (CDC)：配置核对与 2026-10-15 生成实验

这是派生工程报告的审核补充，**不是完整通过 L4/L5 的即用配方**。
模板仍保持 HSI 8 MHz 与 PC13；USB 只在 `.pio/template-audit/` 隔离副本中实验，
没有把 USB_DEVICE/Middlewares 或时钟更改写入模板配置。

前提是已配置有效的 USB 48 MHz 时钟。F103C8 可使用 HSE 8 MHz ×9 得到 PLL 72 MHz，
USB 再除以 1.5；也支持 PLL 48 MHz 直供，不能笼统说“F103 的 USB 固定除以 1.5”。
应先用 GUI 配置时钟，或完整核对 RCC 参数与 HSE 引脚。

USB 配置的主要键如下。`Mcu.IP*`/`Mcu.Pin*` 序号、总数应在现有清单上追加并重算，
不要照抄其他工程的数字；下段不包含这些动态序号。

```ini
NVIC.USB_LP_CAN1_RX0_IRQn=true\:0\:0\:false\:false\:true\:false\:true\:false
PA11.Mode=Device
PA11.Signal=USB_DM
PA12.Mode=Device
PA12.Signal=USB_DP
USB.DeviceSpeed=PCD_SPEED_FULL
USB.IPParameters=DeviceSpeed,low_power_enable,lpm_enable,battery_charging_enable
USB.battery_charging_enable=DISABLE
USB.low_power_enable=DISABLE
USB.lpm_enable=DISABLE
USB_DEVICE.CLASS_NAME_FS=CDC
USB_DEVICE.IPParameters=VirtualMode,VirtualModeFS,CLASS_NAME_FS
USB_DEVICE.VirtualMode=Cdc
USB_DEVICE.VirtualModeFS=Cdc_FS
VP_USB_DEVICE_VS_USB_DEVICE_CDC_FS.Mode=CDC_FS
VP_USB_DEVICE_VS_USB_DEVICE_CDC_FS.Signal=USB_DEVICE_VS_USB_DEVICE_CDC_FS
```

同时核对以下清单：

- `Mcu.IP*` 登记 `USB` 和 `USB_DEVICE`，并更新 `Mcu.IPNb`。
- `Mcu.Pin*` 登记 PA11、PA12 和 `VP_USB_DEVICE_VS_USB_DEVICE_CDC_FS`，并更新 `Mcu.PinsNb`。
- `ProjectManager.functionlistsort` 追加序号唯一的
  `<序号>-MX_USB_DEVICE_Init-USB_DEVICE-false-HAL-false`。
- 在 PLL 为 72 MHz 的前提下，设置下面两项，并将 `USBPrescaler`、`USBFreq_Value`
  都加入已有 `RCC.IPParameters`；保留其他有效时钟参数。

```ini
RCC.USBPrescaler=RCC_USBCLKSOURCE_PLL_DIV1_5
RCC.USBFreq_Value=48000000
```

**审核纠正**：仅写 `USBFreq_Value=48000000` 是不够的；它是派生频率，不能代替分频选择。
隔离对照中，遗漏 `USBPrescaler` 时生成了 `RCC_USBCLKSOURCE_PLL`，日志出现
`IP not ready for code generation: Clock`，但进程仍返回 0 且产出了 CDC 文件。
不能断言出现此日志就“一定中止、不生成文件”。显式补充分频参数后生成的是：

```c
PeriphClkInit.UsbClockSelection = RCC_USBCLKSOURCE_PLL_DIV1_5;
```

因此未采纳报告中无条件在 SysInit 写 `CLEAR_BIT(RCC->CFGR, RCC_CFGR_USBPRE)` 的补丁。
应优先修正 `.ioc`，复核生成的 `UsbClockSelection` 和实际 USB 时钟；
不要把派生工程的整个 `RCC_CFGR=0x001d040a` 当作通用验收值。
当前 HAL 中 `RCC_USBCLKSOURCE_PLL` 表示 PLL 直供，`PLL_DIV1_5` 表示除以 1.5。

生成物应逐一核对：

| 位置 | 应有内容 |
| --- | --- |
| `USB_DEVICE/App/usb_device.c`、`.h` | `MX_USB_DEVICE_Init()` 定义与声明 |
| `USB_DEVICE/App/usbd_desc.*`、`usbd_cdc_if.*` | 描述符与 CDC 接口 |
| `USB_DEVICE/Target/usbd_conf.*` | HAL_PCD 桥接、`USBD_LL_*` 与 USB NVIC |
| `Middlewares/ST/STM32_USB_Device_Library/` | USB Device 核心与 CDC 类库 |
| `Core/Src/main.c` | `MX_USB_DEVICE_Init()` 调用及正确 USB 分频 |
| `Core/Inc/stm32f1xx_hal_conf.h`、`Core/Src/stm32f1xx_it.c` | PCD 模块启用、USB IRQ handler |

只启用裸 `USB` 外设并不等于启用 CDC 中间件。纳入构建时还要增加源文件白名单与包含路径、
排除库内 `*_template.c`，避免重复定义。当前模板 `src_dir = Core/Src` 不会编译这些目录，
所以不能只生成文件就声称固件支持 CDC。对第三方中间件告警应单独评估，不能一律放宽工程告警。

**本次验证边界**：CubeMX exe 为 6.18.1-RC2，数据库写回为 DB.6.0.181，固件包 V1.8.7。
清理无效的历史 RCC 缓存参数后，正确分频及上述 CDC 生成物均存在，
没有 `Cannot map` 或 `IP not ready`；仍有一条
`(OptionalMessage_ERROR) Pin11 (VP_RIF_VS_RIF1) cannot be retrieved for this MCU`。
**该诊断的来源已于 2026-11-05 定位**（见下），是工具级缺陷、与工程配置无关；
`AGENTS.md` §2.3 的 L4 门槛已据此改为白名单式：**本节这条 `VP_RIF_VS_RIF1` 与 §3.5.6.2 的 DMA 导入顺序噪音可豁免**，
其余 `OptionalMessage_ERROR` 一律按失败处理；两类豁免出现时都必须在提交正文里逐条注明。
本文配置核对为 L1，隔离生成仅提供观察证据；未构建或烧录 USB 变体，未做枚举/收发 L5。

#### 3.5.6.1 `VP_RIF_VS_RIF1` 诊断已定位：CubeMX 6.18.1-RC2 的 F1 文本导入缺陷（2026-11-05）

**结论**：这是 `-q` 脚本模式**文本导入路径**（日志里的 `ImportTextPane:234`）对 STM32F1 系列的
工具级缺陷 —— 导入器在遍历完 `Mcu.Pin*` 之后会去解析一个 F1 专有的重映射虚拟引脚
`VP_RIF_VS_RIF1`，而该型号器件库里没有这个虚拟引脚，于是留下一条 `(OptionalMessage_ERROR)`。
它与 **`.ioc` 内容、引脚配置、版本戳都无关**：进程仍返回 0，生成物完整正确。

对照实验（同一台机器、同一个 exe，全部在仓库外的隔离副本里做；
**本机留证**，路径 `D:/Projects/GitHub/.tmp-l4-exp/`，每次运行后立刻复制
`~/.stm32cubemx/STM32CubeMX.log`）。**该副本与 `~/.stm32cubemx/` 都在仓库外、不入库、
可能被清理**，所以下表之后把关键日志原文行内联，读者不必去本机找：

| # | 动作 | `OptionalMessage_ERROR` | `Cannot map` |
| - | ---- | ----------------------- | ------------ |
| 1 | 副本 `.ioc` 只做 `config load` + `config save`（仅刷版本戳，不生成） | **1** 条 `Pin3 (VP_RIF_VS_RIF1)` | 0 |
| 2 | 刷新版本戳后再 `project generate` | **1** 条 `Pin3` | 0 |
| 3 | `load STM32F103C8Tx` 新建工程后 `project generate`（**不经文本导入**） | **0** 条 | 0 |
| 4 | 把第 3 步 CubeMX **自己产出**的 `freshprobe.ioc`（`Mcu.PinsNb=2`、全文无 `VP_RIF`）再 `config load` + `project generate` | **1** 条 `Pin2` | 0 |
| 5 | QA 独立复跑第 4 步 | **1** 条 `Pin2` | 0 |

**日志原文行**（取自上述运行的本机留证，`ImportTextPane:234` 前缀与时间戳原样，未改写）：

```text
2026-11-05 15:09:36,387 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) Pin3 (VP_RIF_VS_RIF1) cannot be retrieved for this MCU
2026-11-05 15:13:41,507 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) Pin2 (VP_RIF_VS_RIF1) cannot be retrieved for this MCU
```

第一行出自第 1 行实验（`.tmp-l4-exp/log-save-run.log:328`，`Mcu.PinsNb=3`），
第二行出自第 4 行实验（`.tmp-l4-exp/log-freshreload-run.log:318`，`Mcu.PinsNb=2`）；
第 3 行实验的 `log-fresh-run.log` 里该字符串**出现 0 次**。三份留证都是本机文件
（仓库外，不入库），故上面两行按原文内联，作为判据的可见证据。

**判据**（两条都成立，才可当作"已知豁免项"而不是"顺手放过"）：

1. 走 `config load`（文本导入）→ **必现且恰好 1 条**；用 `load <MCU>` 在内存里建模 → **0 条**；
2. 诊断里的序号 `<N>` **恒等于**该 `.ioc` 的 `Mcu.PinsNb`（上表第 1/2 行 `PinsNb=3` → `Pin3`，
   第 4 行 `PinsNb=2` → `Pin2`），说明它表示"一个被遍历到的虚拟引脚"，不是某个真实引脚出错。

生成行为不受影响，四个核验点在第 2 次运行里同时确认：生成的 `Core/Src/main.c` 仍有
`MX_GPIO_Init()`（声明 / 调用 / 定义分别在 50 / 88 / 147 行）；
`Core/Inc/main.h` 的 `#include "bluepill.h"` 仍在 `/* USER CODE BEGIN Includes */` 块内；
这两份生成物与仓库现有文件**忽略行尾后逐字节一致**（`diff --strip-trailing-cr` 无输出）。

`config save` 的 side effect（供判断"要不要顺手刷版本戳"）：`MxCube.Version` 6.17.0 → 6.18.1、
`MxDb.Version` DB.6.0.170 → DB.6.0.181，另新增 3 条 `PCC.*` 显示参数
（`PCC.Bar.Display=Horizontal Bar`、`PCC.SequenceTime=1.0 ms`、`PCC.SequenceTime.Unit=ms`），
**没有任何引脚 / 时钟 / 外设语义变化**；`.ioc` 会被改写成 CRLF，但 `.gitattributes` 的
`text=auto eol=lf` 会在 `add` / `diff` 时归一化，不会产生整文件 diff。
**本轮不采纳该改动：它关不掉这条诊断，纯属无收益的改动。**
`AGENTS.md` §2.3 的 L4 门槛依据本节的判据改成了白名单式。

#### 3.5.6.2 `IP (DMA)` 与 `IP (RCC)` 两类消息的 tag 实测（2026-11-05）

**要回答的问题**：§3.5.5 让读者忽略 `IP (DMA) : Parameter (...) has Id (...) currently not set`
与 `RCC ... has invalid value` 两类消息，但 §2.3 的新白名单最初只列了 `VP_RIF_VS_RIF1`。
若这两类也带 `(OptionalMessage_ERROR)` 前缀，**DMA / RCC 场景下 L4 门槛就不可达**。

**结论（两类都带 tag，但处置不同）**：

| 消息 | 日志 tag（实测） | 处置 |
| ---- | ---------------- | ---- |
| `IP (DMA) : Parameter (<参数名>) has Id (<请求名>) currently not set` | **`(OptionalMessage_ERROR)`** | 计入 §2.3 **豁免清单**：文本导入顺序噪音，每个 DMA 请求块**恰好 8 条**，生成物完全正确 |
| `IP (RCC) : Parameter (<名>) has invalid value (<值>)` | **`(OptionalMessage_ERROR)`** | **不豁免**：缓存时钟值与实际配置不一致的**真错误**，清掉过期 RCC 缓存字段即消失（§3.5.6 的 2026-10-15 对照） |

**实验**（隔离副本 `D:/Projects/GitHub/.tmp-dma-probe/`，仓库外，跑完即删；
每次运行后立刻复制 `~/.stm32cubemx/STM32CubeMX.log` 留证，用 `diff` 取新增行）：

1. `load STM32F103C8Tx` + `project generate` → **0 条**（不经文本导入，同 §3.5.6.1 判据 1）。
2. `set ip parameters TIM2 InputCapture PA0-WKUP S_TIM2_CH1_ETR Prescaler 1 Period 65536`
   返回 `OK` 但 `.ioc` 里一个字节的 TIM2 都没有 —— 与 §3.5.2 记录一致，**别指望这条命令**。
3. 文本手工加 `PA0-WKUP.Signal=S_TIM2_CH1_ETR` + `TIM2.*`：`PA0-WKUP.Mode` 写
   `Input Capture` / `Input_Capture_CH1` / `Input Capture mode` 依次得到
   `(OptionalMessage_WARN) Unknown mode (...) for pin (PA0-WKUP)` +
   `(OptionalMessage_ERROR) Unable to find appropriate mode for pin (PA0-WKUP)`，
   TIM2 始终不落地（`Mcu.IPNb` 回到 3）→ 这条路径**不适合**做 DMA 复现。
4. 改用 USART1 异步 + `Dma.USART1_TX.0.*`（`DMA1_Channel4`）：若 `.ioc` 的 `Mcu.IP*` 里
   **没有 DMA**，整个 `Dma.*` 块被**静默丢弃**，日志**零消息**（容易误判成"没问题"）。
5. 在 4 的基础上显式写 `Mcu.IP<n>=DMA` + `Mcu.IPNb+1` → **必现 8 条 `(OptionalMessage_ERROR)`**，
   同时 `MX_DMA_Init()` 与 `__HAL_LINKDMA` 正常生成。下面就是第 5 步的**日志原文行**。

```text
2026-11-05 16:56:24,822 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) Pin4 (VP_RIF_VS_RIF1) cannot be retrieved for this MCU
2026-11-05 16:56:25,758 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) IP (DMA) : Parameter (Instance) has Id (USART1_TX) currently not set
2026-11-05 16:56:25,758 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) IP (DMA) : Parameter (Direction) has Id (USART1_TX) currently not set
2026-11-05 16:56:25,758 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) IP (DMA) : Parameter (PeriphInc) has Id (USART1_TX) currently not set
2026-11-05 16:56:25,758 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) IP (DMA) : Parameter (MemInc) has Id (USART1_TX) currently not set
2026-11-05 16:56:25,759 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) IP (DMA) : Parameter (PeriphDataAlignment) has Id (USART1_TX) currently not set
2026-11-05 16:56:25,759 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) IP (DMA) : Parameter (MemDataAlignment) has Id (USART1_TX) currently not set
2026-11-05 16:56:25,759 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) IP (DMA) : Parameter (Mode) has Id (USART1_TX) currently not set
2026-11-05 16:56:25,759 [INFO] ImportTextPane:234 - (OptionalMessage_ERROR) IP (DMA) : Parameter (Priority) has Id (USART1_TX) currently not set
```

8 条 = `Dma.<请求>.0.RequestParameters` 里那 8 个参数，顺序也一致；
`<参数名>` 固定为 `Instance` / `Direction` / `PeriphInc` / `MemInc` /
`PeriphDataAlignment` / `MemDataAlignment` / `Mode` / `Priority`，
`<请求名>` 就是 `Dma.Request0` 里写的请求（这次 `USART1_TX`，§3.5.5 那次 `TIM2_CH1`）。
**故识别条件可写成机械判据**：条数 = 8 × DMA 请求块数、参数名取自固定 8 项、请求名与 `Dma.Request*` 一致。

**生成物证据**（同一份产物，`runW/probe/`）：

- `Src/main.c`：`static void MX_DMA_Init(void);`（53 行）、调用 `MX_DMA_Init();`（93 行）、
  定义（182 行）三处齐全；
- `Src/stm32f1xx_hal_msp.c`：`hdma_usart1_tx.Instance = DMA1_Channel4;`（118 行）与
  `__HAL_LINKDMA(huart,hdmatx,hdma_usart1_tx);`（131 行）。
  → **8 条 ERROR 与代码正确性无关**，属导入顺序噪音。

**RCC 那三行的原文**（本机 2026-10-15 审计产物，出自 `.pio/template-audit/` ——
`.pio/` 已被 `.gitignore` 排除，**新克隆的仓库里没有这些 log**；
**本机可复核，原文内联于下**，不要把它当公共可复核证据）：

```text
.pio/template-audit/usb-report/generate.log:367  (OptionalMessage_ERROR) IP (RCC) : Parameter (ADCFreqValue) has invalid value (36000000)
.pio/template-audit/usb-report/generate.log:368  (OptionalMessage_ERROR) IP (RCC) : Invalid parameter (FamilyName)
.pio/template-audit/usb-report/generate.log:369  (OptionalMessage_ERROR) IP (RCC) : Parameter (MCOFreq_Value) has invalid value (72000000)
```

注意第 368 行**形态不同**：它是 `Invalid parameter (FamilyName)`，不是 `has invalid value`。
按 `AGENTS.md` §2.3 的「其余必须为 0」，它与非豁免的 `has invalid value` **同样判失败**，
所以 **RCC 这一类整体不豁免** —— 不要以为"只有 `has invalid value` 才挡"。

清理过期 RCC 缓存参数后的 `usb-clean/generate.log`（同一 `.pio/` 本机留证，不入库）
只剩 `Pin11 (VP_RIF_VS_RIF1)` 一条 —— **三行全部消失**，所以它们都是真错误、都不进豁免清单。

**边界说明**：

- `(OptionalMessage_WARN) ...` 不是 ERROR，不计入门槛（本次实测：`Unknown mode (...) for pin (...)`）；
- `(OptionalMessage_ERROR) Unable to find appropriate mode for pin (...)` 是 ERROR 且**不在豁免内**；
- 只有一个 `Dma.*` 块、`Mcu.IP*` 里却没有 `DMA` 时，块被静默丢弃、日志无任何消息 ——
  **"日志干净"不等于"DMA 生效"**，判定生效永远看生成物（`MX_DMA_Init` / `__HAL_LINKDMA`）。

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

> **2026-10-15 默认配置更新**：模板已改用 ST-Link/SWD，PlatformIO 的烧录与调试均为 `stlink`，
> Cortex-Debug 使用 `scripts/openocd-stlink.cfg`。锁定的 OpenOCD 包中 `interface/stlink.cfg`
> 使用原生 `st-link` 驱动，选择 `transport select swd`。
> 下面的 CMSIS-DAP 配置与命令保留为历史实测及切回 CMSIS-DAP 时的参考，不代表当前默认配置。

本机另外还装了两个**碰硬件**的 MCP server（机器级说明见
`C:\Users\Leon\.workbuddy\mcp-servers\PROJECT-SETUP.md`）。它们**不能替代**上面的
`vscode-cube-mcp`（一个只改配置、一个只碰硬件），分工如下：

> **先回答一个常见误解：这两个 server 都不管 `.ioc`。**
> 2026-09-25 对三个 server 各做了一次真实 MCP 握手（`initialize` + `tools/list`），结果：
>
> | server | 工具数 | 有 `.ioc` 相关工具吗 |
> | ------ | ------ | -------------------- |
> | `vscode-cube-mcp` | 9 | **全部 9 个**都是 `.ioc` 工具 |
> | `agentic-hil` | 43 | **0 个**（工具族 = probe/flash/debug/COM/CAN/test-reactor/project_config） |
> | `stm32-stlink`(stmcp) | 19 | **0 个**（工具族 = probe/debug/flash/breakpoint/memory/register） |
>
> 原因是文件类型上的硬门槛：
> - `agentic-hil` 的 `artifacts.allowed_extensions` 默认只有 `[".elf", ".hex", ".bin"]`，
>   且 `validation.inspect_known_formats=true` —— `.ioc` 会被当成未知格式拒掉。
>   它唯一的"写配置"工具 `project_config_set` / `project_config_create` 写的是**它自己的 YAML**，不是 `.ioc`。
> - `stmcp` **根本没有通用的主机文件读写工具**：它能碰的主机文件只有 `debug_connect` 的 `elfPath` 和
>   `flash_standalone` 的 `file`（都喂给 gdb / Programmer_CLI）。名字像"文件读写"的
>   `memory_read` / `memory_write` 读的是**目标芯片内存**，是另一回事。

| server | 本工程能否用 | 说明 |
| ------ | ------------ | ---- |
| `stm32-stlink`（stmcp） | 工具类型匹配，待实板验证 | 基于 `ST-LINK_gdbserver` + `STM32_Programmer_CLI`，与当前 ST-Link 默认探针类型匹配；早期 FireDAP Lite 下不适用的结论已过时，不能据此声称当前机器已连通 |
| `agentic-hil` | 可配置 OpenOCD 后端，待实板验证 | ST-Link 使用 `interface/stlink.cfg`、`target/stm32f1x.cfg`；下列 CMSIS-DAP 历史示例需按实际探针调整 |

`agentic-hil` 用在 CMSIS-DAP 板子上的历史要点（当时实测环境 `agentic-hil` 0.21.5）：

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
