#!/usr/bin/env bash
#
# 初始化新工程：把模板里的工程名 / 仓库名一次改到位（A2 六处联动 + A3 仓库名 + A4 README 标题）。
#
# 用法：
#   ./scripts/init-project.sh <新工程名> [选项]
#
# 选项：
#   --repo-name <名字>        新仓库名（默认与新工程名相同）
#   --yes, -y                 不问，直接用默认值（资料原件默认允许、Flash 默认 64k）
#   --dry-run, -n             只打印将做什么，不写任何文件（含将 patch 的 AGENTS.md 内容）
#   --flash 64k|128k          Flash 容量，默认 64k；选 128k 时提示同步 board_build.ldscript
#   --keep-originals yes|no   新建的工程是否把资料原件放进仓库，默认 yes（允许）
#   -h, --help                显示本帮助
#
# 说明：
#   - 只替换两处字面串：OLD_PROJECT（工程名）与 OLD_REPO（仓库名），外加根 .ioc 文件名重命名。
#   - 不改 .ioc 的引脚 / 时钟 / 外设内容，不改 platformio.ini，不改 Core/Src/**。
#   - 不执行任何 git 写操作：不碰 .git/config、不碰 remote、不 commit、不改 hooksPath。
#   - 不自动填写绝对路径：scripts/cubemx-init.mx 的 __PROJECT_DIR__ 始终留给人工处理。
#   - AGENTS.md 的第三方原件约束用成对 HTML 注释标记块做稳定替换，可重复运行。
#
# 示例：
#   ./scripts/init-project.sh my-board --dry-run
#   ./scripts/init-project.sh my-board --repo-name my-repo --yes --flash 128k
#   ./scripts/init-project.sh my-board --yes --keep-originals no
#
set -euo pipefail

OLD_PROJECT='stm32-digital-clock'
OLD_REPO='template-mcu-STM32F103C8T6-BluePill'
OLD_IOC="${OLD_PROJECT}.ioc"
BEGIN_MARK='<!-- BEGIN: BP_THIRD_PARTY_ORIGINAL_RULE -->'
END_MARK='<!-- END: BP_THIRD_PARTY_ORIGINAL_RULE -->'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

NEW_PROJECT=''
NEW_REPO=''
DRY_RUN=0
ASSUME_YES=0
FLASH='64k'
KEEP_ORIGINALS='yes'

usage() {
  sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
}

die() {
  printf '错误：%s\n' "$*" >&2
  exit 1
}

# ---- 参数解析 ----
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --yes|-y)
      ASSUME_YES=1
      shift
      ;;
    --dry-run|-n)
      DRY_RUN=1
      shift
      ;;
    --flash)
      [ "$#" -ge 2 ] || die '--flash 需要一个值：64k 或 128k'
      FLASH="$2"
      shift 2
      ;;
    --flash=*)
      FLASH="${1#*=}"
      shift
      ;;
    --repo-name)
      [ "$#" -ge 2 ] || die '--repo-name 需要一个名字'
      NEW_REPO="$2"
      shift 2
      ;;
    --repo-name=*)
      NEW_REPO="${1#*=}"
      shift
      ;;
    --keep-originals)
      [ "$#" -ge 2 ] || die '--keep-originals 需要 yes 或 no'
      KEEP_ORIGINALS="$2"
      shift 2
      ;;
    --keep-originals=*)
      KEEP_ORIGINALS="${1#*=}"
      shift
      ;;
    --name)
      [ "$#" -ge 2 ] || die '--name 需要一个名字'
      NEW_PROJECT="$2"
      shift 2
      ;;
    --name=*)
      NEW_PROJECT="${1#*=}"
      shift
      ;;
    -*)
      die "未知选项：$1（用 --help 看用法）"
      ;;
    *)
      if [ -z "$NEW_PROJECT" ]; then
        NEW_PROJECT="$1"
      else
        die "只接受一个位置参数作为新工程名，多余参数：$1"
      fi
      shift
      ;;
  esac
done

# ---- 校验 ----
[ -n "$NEW_PROJECT" ] || die '缺少新工程名。用法：init-project.sh <新工程名> [--yes] [--dry-run]'
[[ "$NEW_PROJECT" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || \
  die "新工程名只能用字母、数字、点、下划线、连字符，且必须以字母或数字开头：$NEW_PROJECT"
if [ -z "$NEW_REPO" ]; then
  NEW_REPO="$NEW_PROJECT"
fi
[[ "$NEW_REPO" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || \
  die "新仓库名只能用字母、数字、点、下划线、连字符，且必须以字母或数字开头：$NEW_REPO"
case "$FLASH" in
  64k|128k) ;;
  *) die '--flash 只能是 64k 或 128k' ;;
esac
case "$KEEP_ORIGINALS" in
  yes|no) ;;
  *) die '--keep-originals 只能是 yes 或 no' ;;
esac
[ "$NEW_PROJECT" != "$OLD_PROJECT" ] || die '新工程名不能与模板默认工程名相同'

# ---- 平实大白话询问（Q5）：文案不含任何术语 ----
if [ "$ASSUME_YES" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
  printf '新建的工程要把资料原件放进仓库吗？[Y/n] '
  answer=''
  read -r answer || answer=''
  case "$answer" in
    n|N|no|NO|No|不|不允许) KEEP_ORIGINALS='no' ;;
    *) KEEP_ORIGINALS='yes' ;;
  esac
fi

# ---- AGENTS.md 标记块的两份内容 ----
# 「允许」= 不写第三方原件约束；「不允许」= 写入约束。两份都保留标记，便于重复运行。
read -r -d '' ALLOW_BLOCK <<'EOF' || true
<!-- 初始化时选择了「要把资料原件放进仓库」，因此这里不写入第三方原件约束。 -->
<!-- 本工程的资料许可、体积与来源由维护者自行判断；如需恢复约束，重跑 scripts/init-project.sh 并选择「不允许」。 -->
EOF

read -r -d '' DENY_BLOCK <<'EOF' || true
12. **第三方原件一律不入库**（初始化时选择了「不要把资料原件放进仓库」）。
    「第三方原件」指**版权不属于本仓库、由外部创作并发布的文件本体**：ST 官方 PDF（datasheet /
    参考手册 / 应用笔记 / MB1136 原理图）、社区原理图、整包例程、`Drivers/` 副本、第三方引脚图 /
    照片等。**不含**自研 Markdown、自绘 SVG、自写源码、单纯的 URL 直链，以及「不复制原文图表」
    的自研摘要。资料目录（[`docs/bluepill/`](docs/bluepill/README.md)）只放**官方直链索引 +
    三级来源标注 + 少量自有整理**，字段与许可判断以 [`SOURCES.md`](docs/bluepill/SOURCES.md)
    为唯一台账：S1/S2 条目默认 `store = link`，`license = 未验证` 时禁止 `store = file`。
    **两个显式例外**（须逐条登记许可与出处，不得扩大）：#9 PlatformIO `genericSTM32F103C8.json`
    （Apache-2.0，1,150 B，仅作 `docs/bluepill/` 资料副本，绝不进 `boards/`）、
    #7 社区 Blue Pill 原理图（条件入库，必须附 [`ATTRIBUTION.md`](docs/bluepill/ATTRIBUTION.md)，
    且仅解决署名可追溯、不构成 ST 要求的 `prior written permission`）。
    若要改变本约束，重跑 `scripts/init-project.sh|ps1` 并在询问时选「允许」即可。
EOF

if [ "$KEEP_ORIGINALS" = 'yes' ]; then
  AGENTS_BLOCK="$ALLOW_BLOCK"
  ORIGINALS_WORD='允许（不写入第三方原件约束）'
else
  AGENTS_BLOCK="$DENY_BLOCK"
  ORIGINALS_WORD='不允许（写入第三方原件约束）'
fi

# ---- 联动文件清单 ----
LINKED_FILES=(
  '.vscode/tasks.json'
  'scripts/cubemx-generate.mx'
  'scripts/cubemx-init.mx'
  'README.md'
  'TEMPLATE-PLACEHOLDERS.md'
  'docs/bluepill/README.md'
  'docs/bluepill/SOURCES.md'
)

# ---- 执行 / 预演 ----
if [ "$DRY_RUN" -eq 1 ]; then
  printf '== 预演（--dry-run）：不写任何文件 ==\n\n'
else
  printf '== 初始化新工程 ==\n\n'
fi

printf '新工程名： %s\n' "$NEW_PROJECT"
printf '新仓库名： %s\n' "$NEW_REPO"
printf 'Flash   ： %s\n' "$FLASH"
printf '资料原件： %s\n' "$ORIGINALS_WORD"
printf '\n'

# 1) .ioc 内容 + 文件名（A2 的 ProjectName / ProjectFileName / 文件名三处）
if [ -f "$OLD_IOC" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[预演] 改写 %s ：%s -> %s ；%s -> %s\n' \
      "$OLD_IOC" "$OLD_PROJECT" "$NEW_PROJECT" "$OLD_REPO" "$NEW_REPO"
    printf '[预演] 重命名 %s -> %s.ioc\n' "$OLD_IOC" "$NEW_PROJECT"
  else
    sed -i "s/${OLD_PROJECT}/${NEW_PROJECT}/g; s/${OLD_REPO}/${NEW_REPO}/g" "$OLD_IOC"
    mv "$OLD_IOC" "${NEW_PROJECT}.ioc"
    printf '[已改] %s -> %s.ioc（含 ProjectName / ProjectFileName）\n' "$OLD_IOC" "$NEW_PROJECT"
  fi
else
  printf '[跳过] 未找到 %s（可能已经改过名）\n' "$OLD_IOC"
fi

# 2) 其余联动文件
for f in "${LINKED_FILES[@]}"; do
  if [ ! -f "$f" ]; then
    printf '[跳过] 未找到 %s\n' "$f"
    continue
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[预演] 改写 %s ：%s -> %s ；%s -> %s\n' \
      "$f" "$OLD_PROJECT" "$NEW_PROJECT" "$OLD_REPO" "$NEW_REPO"
  else
    sed -i "s/${OLD_PROJECT}/${NEW_PROJECT}/g; s/${OLD_REPO}/${NEW_REPO}/g" "$f"
    printf '[已改] %s\n' "$f"
  fi
done

# 3) AGENTS.md 的 Q5 patch（成对标记块稳定替换）
printf '\n[AGENTS.md] 将把标记块 %s ... %s 的内容替换为：\n' "$BEGIN_MARK" "$END_MARK"
printf '%s\n' "$AGENTS_BLOCK"
if [ "$DRY_RUN" -eq 0 ]; then
  if grep -qF "$BEGIN_MARK" AGENTS.md && grep -qF "$END_MARK" AGENTS.md; then
    block_tmp="${REPO_ROOT}/.agents-block.tmp"
    full_tmp="${REPO_ROOT}/.agents-full.tmp"
    printf '%s\n' "$AGENTS_BLOCK" > "$block_tmp"
    awk -v begin="$BEGIN_MARK" -v end="$END_MARK" -v blockfile="$block_tmp" '
      $0 == begin { print; while ((getline line < blockfile) > 0) print line; close(blockfile); skip=1; next }
      $0 == end   { skip=0; print; next }
      skip        { next }
                  { print }
    ' AGENTS.md > "$full_tmp"
    mv "$full_tmp" AGENTS.md
    rm -f "$block_tmp"
    printf '[已改] AGENTS.md 标记块内容\n'
  else
    printf '[跳过] AGENTS.md 缺少成对标记，未修改（请人工核对）\n' >&2
  fi
else
  printf '[预演] 不写 AGENTS.md（上面就是要写入的内容）\n'
fi

# 4) Flash 选项提示（脚本不改 platformio.ini）
printf '\n'
if [ "$FLASH" = '128k' ]; then
  printf '[提醒] 你选了 128K Flash：请在 platformio.ini 里同步设置\n'
  printf '        board_build.ldscript 指向 128K 链接脚本（脚本不代改），并以实测容量为准。\n'
  printf '        C8T6 有 64K / 128K 两种说法，见 TEMPLATE-PLACEHOLDERS.md B3 / G 节。\n'
else
  printf '[默认] 64K Flash：与内置 genericSTM32F103C8.json、STM32F103C8TX_FLASH.ld 一致，\n'
  printf '        不改 platformio.ini，也不新建自定义 boards/ 目录。\n'
fi

# 5) 仍需人工项（脚本不自动填绝对路径、不碰 git）
printf '\n== 仍需人工处理（脚本不代做）==\n'
printf '  1. scripts/cubemx-init.mx 里的 project path __PROJECT_DIR__：填本工程的绝对路径\n'
printf '     （CubeMX 的 .mx 脚本不支持变量，脚本不会自动填）。\n'
printf '  2. 目录名：把仓库文件夹本身改成新名字。\n'
printf '  3. remote：git remote -v 仍指向模板仓库，自己改成新仓库地址（脚本不碰 git 配置）。\n'
printf '  4. clangd：换机器后重跑 scripts/init-clangd.sh（或 .ps1）重新生成索引。\n'
printf '  5. 资料：docs/bluepill/SOURCES.md 的字段、docs/bluepill/README.md 主索引、\n'
printf '     board-pinout.md / examples.md / Core/Inc/bluepill.h 要按新板卡重填（见 PLACEHOLDERS H 节）。\n'

if [ "$DRY_RUN" -eq 1 ]; then
  printf '\n预演结束：以上都没有写入任何文件。确认后再去掉 --dry-run 重跑。\n'
else
  printf '\n完成。建议先 git diff 检查一遍，再按上面的清单处理人工项。\n'
fi
