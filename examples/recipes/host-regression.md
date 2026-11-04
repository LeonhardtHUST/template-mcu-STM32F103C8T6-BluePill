# 配方：纯 C 主机回归（L2，复用仓库已有 `test/`）

> 对应 [`../INDEX.md`](../INDEX.md) 第 3 行，验证等级 **L2（主机回归）**。
> **本配方不复制任何源码**：A 仓库本身就有 [`test/stdio_port_test.c`](../../test/stdio_port_test.c)
> 与 [`Core/Src/stdio_port.c`](../../Core/Src/stdio_port.c)，它们是**源头**。
> 不反向搬 B 仓 `examples/stdio_port/` 里的复制品，避免两份重复、两套路径。
> 四栏模板见 [`../README.md`](../README.md)；资料侧索引见
> [`../../docs/bluepill/examples.md`](../../docs/bluepill/examples.md)。

## ① 对应 IP / 配置

**无外设、无 `.ioc` 改动、无开发板。** 这是纯 C 逻辑，只依赖标准库：

| 文件 | 作用 |
| ---- | ---- |
| `Core/Src/stdio_port.c` | 覆盖 CubeMX 的弱 `_read` / `_write`；无后端时返回 `-1` 并置 `errno = ENOSYS` |
| `test/stdio_port_test.c` | 用 `assert` 覆盖正常 / 非法 fd / 非法长度 / 0 字节 / 后端成功与失败路径 |
| `platformio.ini` | 注明 `test/` 在 `src_dir` 之外、**不参与固件构建** |

`AGENTS.md` §2.8 要求「业务逻辑与 HAL 解耦，可在主机上跑的部分不依赖 HAL 头文件」——
`stdio_port.c` 正是这个范式的例子：只用 `<errno.h>` / `<stddef.h>` 之类的标准头。

## ② 可复用文件清单

| 文件 | 处理 | 理由 |
| ---- | ---- | ---- |
| `test/stdio_port_test.c` | **就地复用**，不要复制 | 已经在仓库里，是源头；复制会产生两份重复 |
| `Core/Src/stdio_port.c` | **就地引用** | gcc 回归时直接编它，不进 `pio` 的 `src_dir` 之外 |
| 新增的纯 C 算法模块 | 放进 `Core/Src/` 且**不 include HAL 头** | 才能用主机 GCC 跑 L2（§2.8） |
| `examples/stdio_port/` 之类复制品 | **不建** | 与 `test/` 重复；B 仓那份是从 A 复制过去的 |

## ③ 与 PlatformIO 的差异

| 项 | 固件构建 | 主机回归 |
| -- | -------- | -------- |
| 编译器 | `arm-none-eabi-gcc`（framework） | 系统 `gcc`（本机 15.2.0） |
| 入口 | `main()` in `Core/Src/main.c` + CubeMX 生成物 | `main()` in `test/stdio_port_test.c` |
| 命令 | `pio run` | `gcc -std=c11 -Wall -Wextra -Werror ...` |
| 是否要开发板 | 烧录才要 | **不需要** |
| `test/` 的角色 | 不在 `src_dir` 内，不参与 | 被测对象/测试驱动 |

- **不要**用 `pio test` / Unity：本模板明确用系统 GCC 跑纯 C 回归。
- 两条 gcc 命令见 [`../../AGENTS.md`](../../AGENTS.md) §3 与根级 README「模板维护与验证」。

## ④ 接入步骤 + 已知坑（统一 5 步的本配方变体）

L2 配方**不走**「抄 `.ioc` → 生成 → 烧录」那条路，它是给「改了可主机编译的纯 C 代码」用的：

1. **不改 `.ioc`**（无外设变化）。
2. **无需 CubeMX 生成 / L4**（没有 `.ioc` 改动）。
3. **不动 `Core/` 生成物**：把可主机编译的逻辑放在不依赖 HAL 的源文件里。
4. **跑主机回归（L2）**，两条命令（Windows 把 `/tmp` 换成项目内临时路径，用完删掉）：

   ```bash
   gcc -std=c11 -Wall -Wextra -Werror Core/Src/stdio_port.c test/stdio_port_test.c -o ./.tmp-test/stdio-test && ./.tmp-test/stdio-test
   gcc -std=c11 -Wall -Wextra -Werror -DTEST_BACKEND Core/Src/stdio_port.c test/stdio_port_test.c -o ./.tmp-test/stdio-backend-test && ./.tmp-test/stdio-backend-test
   ```

   `-DTEST_BACKEND` 那一条会启用 `__io_putchar` / `__io_getchar` 桩，覆盖后端成功与
   `EIO` 失败路径；两条都通过才算 L2 过。
5. **固件侧仍按 L3 / L5 单独验证**：`pio run`（记录 Flash / RAM）与实板现象，
   **主机回归通过不等于固件能用**（反之亦然）。

**已知坑**：

- `-Werror` 会让任何告警变错误；新增桩函数时留意未使用参数。
- `stdio_port.c` 的弱符号覆盖只对当前 newlib 工具链有效，换 FW/工具链要重验。
- 不要把适配逻辑写回 `syscalls.c`（CubeMX 会覆盖）。
- Windows 下 `/tmp` 不存在，输出路径换项目内临时目录并清理，别把 `.exe` 留在仓库里。
- 纯文档 / 配置改动只做 L1 时明确写「未运行构建」，不要复用旧的 Flash/RAM 数字。
