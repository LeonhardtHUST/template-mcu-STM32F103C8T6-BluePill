# 派生工程模板回填审核记录

审核日期：2026-10-15。模板基线：`f709264`。
来源：`hust-sti-measure-2026/docs/TEMPLATE-UPDATE-REPORT.md`，来源仓库 HEAD
为 `0c64d10ba4e3c57bd0145a079d3d7adf1f9dfab7`。
报告 SHA-256：`f57eb391ba7300cb05bd9593e76672fa82f3180c0ff47f64656e29b6ad26aaf5`。
来源报告未修改；本文件记录模板侧独立审查与验证结果。

## 逐项结论

| 条目 | 结论与实际落地 | 模板侧验证 | 提交 |
| --- | --- | --- | --- |
| T-1 | 采纳统一 LF；明确 checkout/编辑器遵循 LF，但 CubeMX 写回时工作区仍可能是 CRLF。保留 HEX 原始字节策略 | L1 + L3；CRLF/LF 比对无内容 diff，固件哈希未变 | `f86b5b9` |
| T-2 | 修正后采纳；把 penv/Scripts **前置**到 PATH，避免已有失效 shim 优先匹配 | L1；JSONC 解析、模拟同一 PATH 的新进程执行 pio --version 成功，未通过 VS Code UI 新建终端复测 | `4432f48` |
| T-3 | 部分采纳；工程源码严格检查与 map 默认启用，浮点 printf 改为注释形式按需开启 | L3；详细命令核对作用域，浮点成本对照，恢复默认后构建通过 | `be46192` |
| T-4 | 采纳 release 父目录与文件例外、c_cpp_properties、after 和 CodeBuddy 缓存忽略 | L1；8 项忽略规则检查通过 | `8518f49` |
| T-5 | 部分采纳知识文档；补显式 USBPrescaler，撤销无条件寄存器补丁。**即用配方暂不过审** | L1；三组隔离生成核对，仍有 VP_RIF 诊断，未通过完整 L4；USB 变体未构建、未做 L5 | `c125c71` |
| T-6 | 校正后采纳排查文档；保留故障与来源，限定 HAL 状态机和专用恢复策略的适用范围 | L1；对照锁定包源码、模板错误路径及派生提交 | `98bdb6f` |
| T-7 | 采纳版本口径、目录和格式化约束；构建数字要求仅适用于实际做过构建的提交 | L1；同步 AGENTS 与占位符清单，未升级工具链或 FW_F1 | `04939f5` |
| T-8 | 采纳 test/ 命名并同步全部原有路径；测试仍由系统 GCC 直接运行 | L2 + L3；两组回归通过，固件不包含测试源码 | `90d4e0c` |
| T-9 | 采纳 README 的终端、构建选项、工具版本及 HAL/USB 文档入口 | L1；核对配置与文档链接 | `525c050` |

## 不能照搬的关键结论

1. **报告有现状误判。** 模板原 `.ioc` 没有 `RCC.USBFreq_Value=72000000`，
   该值出现在派生工程；模板 B8 当时也尚未改成“以 exe 为准”。报告声称 AGENTS 已要求
   “零告警”，原文也无此硬性条款，严格告警是本次新增策略。
2. **最小模板不默认链接浮点 printf。** 该选项在未调用 printf 的闪灯程序中也增加
   Flash 10164 B、静态 RAM 480 B。不能将报告的“纯告警选项零体积变化”套用于整个 T-3。
3. **USB 派生频率不代替真实分频选择。** 在 72 MHz PLL 下明确配置
   `RCC.USBPrescaler=RCC_USBCLKSOURCE_PLL_DIV1_5` 并加入 RCC 白名单，就能生成正确代码。
   未证明 CubeMX 6.18.1 必然生成错误 USB 分频；无条件清 USBPRE 的补丁未采纳。
   F103 USB 也不是固定除以 1.5，48 MHz PLL 可以直供。
4. **HAL 整体状态和通道状态不同。** 锁定包的 Base_Start 会令整体 State 为 BUSY，
   IC_Start_DMA 则检查通道状态；“前者一定导致后者 HAL_BUSY”不成立。
5. **停止 DMA 不总会停止计数器。** __HAL_TIM_DISABLE 仅在所有 CCxE/CCxNE 关闭后清 CEN，
   不能将仍有 PWM 通道运行的情况混入同一结论。
6. **启动后清标志不能通用化。** DMA 可能已搬运启动窗口中的样本；不能保证样本未进入缓冲区，
   也不能保证只计算相邻差值就安全。保留为需要连续性检查与实板证据的专用策略。
7. **Error_Handler 直接返回未过审。** 初始化失败后继续运行需要完整的降级设计；
   PCLK 读数不能证明时钟源、SystemCoreClock 与串口波特率都正确。模板保留停机行为。
8. **派生故障记录不等于模板实板通过。** 例如 `d741bfa` 的提交正文明确写着实板待人工确认，
   不能把报告“每条均实板定位”的概括当作本次 L5 证据。

详细分析见 [HAL-PITFALLS.md](HAL-PITFALLS.md) 与
[TOOLING-cubemx.md](TOOLING-cubemx.md) §3.5.6。

## 本次验证证据

PlatformIO Core 6.2.0，使用仓库原有锁定包。当前 shell 的 pio shim 失效，
构建实际调用 `$env:USERPROFILE\.platformio\penv\Scripts\platformio.exe run`；
详细编译命令用 `run -v` 核对。系统 GCC 回归实际执行：

```powershell
gcc -std=c11 -Wall -Wextra -Werror Core/Src/stdio_port.c test/stdio_port_test.c -o .pio/template-audit/stdio-test.exe
& .pio/template-audit/stdio-test.exe
gcc -std=c11 -Wall -Wextra -Werror -DTEST_BACKEND Core/Src/stdio_port.c test/stdio_port_test.c -o .pio/template-audit/stdio-backend-test.exe
& .pio/template-audit/stdio-backend-test.exe
```

所有编译与执行退出码均为 0。构建结果按 PlatformIO 的静态占用口径记录：

| 构建 | Flash | RAM | 结果 |
| --- | ---: | ---: | --- |
| 原模板基线 | 2652 B | 44 B | 通过 |
| LF + 严格源码选项 + map | 2652 B | 44 B | 通过，固件字节不变 |
| 临时强制链接 _printf_float | 12816 B | 524 B | 通过，nm 确认存在该符号 |
| 最终默认配置 + test/ | 2652 B | 44 B | 通过，两组主机回归均通过 |

RAM 数字不代表运行时峰值；链接器另报默认配置含预留段的 RAM 1584 B、FLASH 2928 B，
与 PlatformIO 的统计口径不同。默认固件前后 SHA-256 均为：
`343f4687e5ffcdaec37a50f234c33424e894b8277a9f42d299b308ce52bb28fc`。

源码命令确认 `-std=c11 -Wall -Wextra -Werror` 只施加于工程源码，HAL/CMSIS 未增加
`-Wextra/-Werror`；`firmware.map` 实际生成。未改动业务源码或默认引脚/时钟。

USB 生成在 `.pio/template-audit/` 下完成三组对照，执行本机 Java + CubeMX `-q`，
exe 6.18.1-RC2、数据库 DB.6.0.181、FW_F1 V1.8.7：

| 输入 | 观察结果 |
| --- | --- |
| 报告写法，USBFreq=48 MHz 但无 USBPrescaler | 日志有 Clock 未就绪，退出码仍为 0，仍生成 CDC 文件且选择 PLL 直供 |
| 补 USBPrescaler 并加入 RCC.IPParameters | 正确生成 PLL_DIV1_5，仍有继承的 RCC 参数诊断与 VP_RIF 诊断 |
| 去掉无效 RCC 缓存字段，只保留必要时钟配置与显式分频 | 正确分频、CDC 文件、PCD 模块、IRQ 与初始化调用均存在，仅剩一条 VP_RIF 诊断 |

最后一组仍有 `(OptionalMessage_ERROR) Pin11 (VP_RIF_VS_RIF1) cannot be retrieved for this MCU`，
来源**在当时尚未定位**，故当时判为**完整 L4 未通过**（本行保留为当时的判定记录）。因此只落地已核对的说明和边界，没有把生成实验变成默认 USB 功能。
该诊断的成因已于 2026-11-05 定位为 CubeMX 6.18.1-RC2 的 F1 文本导入缺陷，L4 门槛已据此改为白名单式，
见 [`TOOLING-cubemx.md`](TOOLING-cubemx.md) §3.5.6.1 与 [`AGENTS.md`](../AGENTS.md) §2.3。
临时输入、日志和产物保留在本机 `.pio/template-audit/`，未加入模板版本库。

## 范围与剩余事项

- 未改变 `.ioc`、Core 生成文件的入库内容，未引入派生工程的业务代码、中间件、网页、交付件或 ST-Link 默认配置。
- 工作开始时已有 `.vscode/extensions.json`、`.vscode/launch.json` 修改；两者 SHA-256
  复核一致，未暂存或提交。已有的 c_cpp_properties 现按规则忽略，IDE 可随配置重新生成它。
- O-1 保持 HEX binary；O-2 未引入强制归档 plan 的制度；O-3 文档骨架与 O-4 HAL mock 范例均暂缓。
  CodeBuddy 会话缓存的忽略属于 T-4，不能替代共享设计文档。
- 文本行尾检查、忽略规则、Markdown 本地链接和提交 diff 空白检查通过；提交保留 SSH 签名。
- **L5 未执行**；本次默认固件与基线字节一致，也未借用派生工程的实板验收结果。

参考：[PlatformIO build_src_flags](https://docs.platformio.org/en/latest/projectconf/sections/env/options/build/build_src_flags.html)、
[VS Code 终端环境继承](https://code.visualstudio.com/docs/terminal/advanced#_environment-inheritance)、
[ST HAL 的 USB 分频定义](https://github.com/STMicroelectronics/stm32f1xx-hal-driver/blob/master/Inc/stm32f1xx_hal_rcc_ex.h)。
可变上游文档仅用于核对语义，HAL 具体行为以本次锁定包实现为准。
