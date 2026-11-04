#!/usr/bin/env bash
#
# 初始化 clangd 语义索引：生成 compile_commands.json、写 .clangd。
#
# 用法：
#   ./scripts/init-clangd.sh
#
# 说明：
#   - 使用 PlatformIO 原生 `pio run -t compiledb`，不需要 Node / .mjs 转发层。
#   - compile_commands.json / .clangd / .cache/ 都已被 .gitignore 忽略，不入库、不进固件。
#   - **不动 .vscode/settings.json**：本模板 4 个 .vscode 文件刻意入库（Q8），
#     clangd 的启动参数只在这里打印提示，由使用者自行决定是否加到编辑器设置。
#   - 换机器 / 换 PlatformIO Core 目录后需要重跑本脚本。
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v pio >/dev/null 2>&1; then
  echo "错误：找不到 pio，请先安装 PlatformIO Core（pip install platformio）或 VS Code 的 PlatformIO IDE 插件" >&2
  exit 1
fi

echo "==> [1/2] 生成 compile_commands.json（pio run -t compiledb）"
pio run -t compiledb

# .clangd 让 clangd 在本项目使用根目录的编译数据库。
# 注意：--query-driver 是 clangd 的启动参数，不能写进 .clangd（会被当成未知字段），
# 因此只在下方打印建议，由使用者放进 VS Code 的 clangd.arguments。
echo "==> [2/2] 写入 .clangd"
printf '%s\n' \
  '# 由 scripts/init-clangd.sh 生成；本文件已被 .gitignore 忽略。' \
  'CompileFlags:' \
  '  CompilationDatabase: .' \
  > .clangd

echo
echo "完成。compile_commands.json 与 .clangd 已生成（均被 .gitignore 忽略）。"
echo
echo "提示：clangd 需要 --query-driver 才能使用 ARM 交叉编译器的头文件，"
echo "      请把下面这段加到 VS Code 设置（本脚本不代改 .vscode/settings.json）："
echo
echo '  "clangd.arguments": ['
echo '    "--compile-commands-dir=${workspaceFolder}",'
echo '    "--query-driver=**/arm-none-eabi-gcc,**/arm-none-eabi-g++,**/arm-none-eabi-gcc.exe,**/arm-none-eabi-g++.exe",'
echo '    "--background-index"'
echo '  ],'
echo
echo "处理 Core/** 前请留意 TEMPLATE-PLACEHOLDERS.md D1：formatOnSave 会重排生成文件。"
echo "最后在 VS Code 命令面板执行：clangd: Restart language server"
echo "恢复 / 关闭：./scripts/disable-clangd.sh"
