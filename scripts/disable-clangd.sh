#!/usr/bin/env bash
#
# 关闭 clangd 语义索引：移除 .clangd 与编译数据库，把智能感知交回 PlatformIO。
#
# 用法：
#   ./scripts/disable-clangd.sh
#
# 说明：
#   - 只删本机生成物，不动版本库、不动 .vscode/settings.json（Q8 保持现状）。
#   - .clangd / compile_commands.json / .cache 均被 .gitignore 忽略，可随时重跑
#     ./scripts/init-clangd.sh 恢复。
#   - 不需要 Node / .mjs 转发层。
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> [1/2] 删除 .clangd"
if [ -f .clangd ]; then
  rm -f .clangd
  echo "    已删除 .clangd"
else
  echo "    未找到 .clangd，跳过"
fi

echo "==> [2/2] 删除 compile_commands.json"
if [ -f compile_commands.json ]; then
  rm -f compile_commands.json
  echo "    已删除 compile_commands.json"
else
  echo "    未找到 compile_commands.json，跳过"
fi

echo
echo "完成。若 VS Code 设置里加过 clangd.arguments，请自行移除或把 clangd 扩展设为 Disable (Workspace)。"
echo "恢复：./scripts/init-clangd.sh"
