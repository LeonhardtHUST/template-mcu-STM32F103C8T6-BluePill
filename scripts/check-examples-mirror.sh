#!/usr/bin/env bash
#
# 校验 docs/bluepill/examples/（资料侧副本）与根级 examples/（原件）是否仍然镜像一致。
#
# 用途：
#   副本存在的意义是让 scripts/init-project.sh|ps1 --drop-examples 删掉根级示例后
#   资料区不自断链。副本靠 `rm -rf docs/bluepill/examples && cp -r examples ...` 整体镜像，
#   手改副本、只改一侧、或镜像后忘了把「本目录是副本」blockquote 贴回，都会让两棵树漂移。
#   本脚本把这件事变成一条可重复执行的命令，替代「改动后逐条 ls 抽查」。
#
# 用法：
#   ./scripts/check-examples-mirror.sh
#   （Windows 原生版：powershell -ExecutionPolicy Bypass -File .\scripts\check-examples-mirror.ps1）
#
#   无参数、无副作用：只读文件，不写仓库也不写临时文件（全部走进程替换），
#   不跑构建，不碰 .ioc / Core/。
#
# 退出码：
#   0  一致：结构与字节全等、正文归一化后全等、两棵树都没有死链
#      （含「根级 examples/ 不存在 → 跳过结构/字节/正文比对」但副本死链扫描仍通过的情形）
#   1  发现不一致或死链；逐条打印漂移文件与死链位置
#   2  前置条件错误：不在本模板仓库根、或副本目录 docs/bluepill/examples/ 不存在
#
# 判据（只有下面两条算「合法差异」，其余一律算漂移）：
#   1. 副本里指向 examples/ 之外的 Markdown 链接，比根级多 1～3 层 ../（链接目标层级差）；
#      examples/ 内部互链（gpio-blink/…、recipes/…、INDEX.md、README.md）保持不变。
#      因此正文比对先把「反引号路径标签 + 链接目标」整体折叠成 [LINK]，
#      再把剩余链接的 ](...) 折叠成 ](LINK)；折叠掉的正是标签层级与目标层级这两类合法差异。
#      （链接标签本身也是路径、也会跟着多 ../，例如 [`../docs/bluepill/examples.md`] 在副本里
#      是 [`../examples.md`]，所以标签必须一起折叠，否则同一句话会被误判为正文漂移。）
#   2. 副本 README.md 顶部多一段以 `> **本目录是副本` 开头、到第一个空行结束的 blockquote；
#      根级 README.md 没有。正文比对对副本 README 剔除这段，并双向断言其存在性
#      （副本必须有、根级必须没有），防止镜像后忘记贴回或误贴到根级。
#
# 四项检查：
#   [1/4] 结构        两棵树相对路径集合必须完全相等（根级不存在时 SKIP）
#   [2/4] 源码/二进制  所有非 .md 文件逐字节比对（cmp -s）
#   [3/4] 正文        所有 .md 归一化后逐行比对 + 副本 README blockquote 双向断言
#   [4/4] 死链        两棵树所有 .md 的 ](target) 解析相对路径，必须落在真实文件或目录上
#
# 已知局限（不要据此扩大判定）：
#   - 链接用正则抽取，代码块里出现的 `](` 字面量会被当成链接（当前仓库无此情况）。
#   - 只校验链接目标能否解析到真实文件或目录，不校验语义，也不校验 #fragment 锚点是否存在。
#   - [1] 只比文件、不比空目录（find -type f），空目录增删不会报出。
#   - 折叠 [`path`](target) 会掩盖「反引号路径标签被改坏」这类改动；
#     纯文字标签（如 [工程规约 §3](...)）参与比对，改字仍会被抓到。
#   - 不跟随符号链接、不做路径大小写归一（Windows 大小写不敏感属已知平台差异）。
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SRC_DIR='examples'
COPY_DIR='docs/bluepill/examples'
BANNER_RE='^> \*\*本目录是副本'
BANNER_TEXT='> **本目录是副本'

drift=0        # 漂移项计数（结构 / 字节 / 正文 / blockquote 断言）
dead=0         # 死链条数
checked_links=0
skipped_links=0

# 前置条件：必须站在本模板仓库根，且副本目录存在。
if [ ! -f 'AGENTS.md' ] || [ ! -d 'docs/bluepill' ]; then
  echo "错误：当前目录不是本模板仓库根（缺少 AGENTS.md 或 docs/bluepill/）：$REPO_ROOT" >&2
  exit 2
fi
if [ ! -d "$COPY_DIR" ]; then
  echo "错误：副本目录不存在：$REPO_ROOT/$COPY_DIR" >&2
  echo "      预期先执行：rm -rf $COPY_DIR && cp -r $SRC_DIR $COPY_DIR（见 docs/bluepill/examples.md §3）" >&2
  exit 2
fi

# 两棵树的相对路径清单（相对各自根目录，正斜杠，字节序排序）。
src_list()  { ( cd "$SRC_DIR"  && find . -type f | sed 's|^\./||' | LC_ALL=C sort ); }
copy_list() { ( cd "$COPY_DIR" && find . -type f | sed 's|^\./||' | LC_ALL=C sort ); }

# 归一化一个 Markdown 文件到标准输出：
#   1) [`反引号路径标签`](target) → [LINK]（标签层级与目标层级一起折叠）
#   2) 剩余 ](target)            → ](LINK)
#   3) mode='copy' 且是副本 README 时，剔除「本目录是副本」blockquote（含其后的空行）
normalize_md() {
  local file="$1"
  local mode="$2"

  if [ "$mode" = 'copy' ]; then
    sed -E 's/\[`[^`]*`\]\([^)]*\)/[LINK]/g; s/\]\([^)]*\)/](LINK)/g' "$file" |
      awk '
        skipping == 0 && /^> \*\*本目录是副本/ { skipping = 1; next }
        skipping == 1 { if ($0 ~ /^[[:space:]]*$/) { skipping = 0 } ; next }
        { print }
      '
  else
    sed -E 's/\[`[^`]*`\]\([^)]*\)/[LINK]/g; s/\]\([^)]*\)/](LINK)/g' "$file"
  fi
}

copy_count=$(copy_list | wc -l | tr -d ' ')
md_count=$(copy_list | grep -c '\.md$' || true)
source_count=$(copy_list | grep -vc '\.md$' || true)

echo "仓库根：$REPO_ROOT"
echo "原件：$SRC_DIR/    副本：$COPY_DIR/"
echo

# ---------------------------------------------------------------------------
echo '==> [1/4] 结构：两棵树的相对路径集合'
# ---------------------------------------------------------------------------
have_root=0
if [ -d "$SRC_DIR" ]; then
  have_root=1
  if diff <(src_list) <(copy_list) > /dev/null; then
    echo "    OK      两边都是 $copy_count 个文件，路径集合完全相等"
  else
    drift=$((drift + 1))
    echo '    FAILED  路径集合不一致（< 只在根级 / > 只在副本）：'
    diff <(src_list) <(copy_list) | grep -E '^[<>]' | sed 's/^/             /' || true
  fi
else
  echo "    SKIP    根级 $SRC_DIR/ 不存在（已执行 --drop-examples 或已删除），跳过整树结构比对"
fi

# ---------------------------------------------------------------------------
echo
echo '==> [2/4] 源码/二进制：所有非 Markdown 文件逐字节比对'
# ---------------------------------------------------------------------------
if [ "$have_root" = '1' ]; then
  byte_bad=''
  src_source_count=0
  while IFS= read -r rel; do
    src_source_count=$((src_source_count + 1))
    if ! cmp -s "$SRC_DIR/$rel" "$COPY_DIR/$rel"; then
      byte_bad="${byte_bad}${rel}"$'\n'
    fi
  done < <(src_list | grep -v '\.md$' || true)

  if [ -n "$byte_bad" ]; then
    drift=$((drift + 1))
    echo '    FAILED  以下非 Markdown 文件字节不一致（或一侧缺失）：'
    printf '%s' "$byte_bad" | sed 's/^/             /'
  else
    echo "    OK      $src_source_count 个非 Markdown 文件逐字节相同"
  fi
else
  echo "    SKIP    根级 $SRC_DIR/ 不存在，没有对照可比"
fi

# ---------------------------------------------------------------------------
echo
echo '==> [3/4] 正文：Markdown 归一化后逐行比对'
# ---------------------------------------------------------------------------
if [ "$have_root" = '1' ]; then
  body_bad=0
  while IFS= read -r rel; do
    # 一侧缺失时只记漂移，不让 sed 去读不存在的文件（结构检查已报出）：
    # 否则 stderr 会刷 can't read，diff 还会把整篇当成「内容被删」，误导成整棵树被清空。
    if [ ! -f "$SRC_DIR/$rel" ] || [ ! -f "$COPY_DIR/$rel" ]; then
      body_bad=$((body_bad + 1))
      echo "             --- $rel（一侧缺失，结构检查应已报出）"
      continue
    fi
    if [ "$rel" = 'README.md' ]; then
      copy_mode='copy'
    else
      copy_mode='root'
    fi
    if diff -q <(normalize_md "$SRC_DIR/$rel" 'root') \
               <(normalize_md "$COPY_DIR/$rel" "$copy_mode") > /dev/null; then
      continue
    fi
    body_bad=$((body_bad + 1))
    diff -u --label "$SRC_DIR/$rel" --label "$COPY_DIR/$rel" \
      <(normalize_md "$SRC_DIR/$rel" 'root') \
      <(normalize_md "$COPY_DIR/$rel" "$copy_mode") | sed 's/^/             /' || true
  done < <(src_list | grep '\.md$' || true)

  if [ "$body_bad" -gt 0 ]; then
    drift=$((drift + 1))
    echo "    FAILED  $body_bad 个 Markdown 正文在归一化后仍不一致（见上）"
  else
    echo "    OK      $md_count 个 Markdown 归一化后正文全等"
  fi

  # blockquote 双向断言：副本必须有、根级必须没有。
  if grep -q -- "$BANNER_RE" "$COPY_DIR/README.md"; then
    echo "    OK      副本 README 含合法差异段「$BANNER_TEXT」"
  else
    drift=$((drift + 1))
    echo "    FAILED  副本 README 缺少「$BANNER_TEXT」blockquote（镜像后忘记贴回？）"
  fi
  if grep -q -- "$BANNER_RE" "$SRC_DIR/README.md"; then
    drift=$((drift + 1))
    echo "    FAILED  根级 README 不应出现「$BANNER_TEXT」blockquote（只属于副本）"
  else
    echo "    OK      根级 README 不含该 blockquote"
  fi
else
  echo "    SKIP    根级 $SRC_DIR/ 不存在，没有对照可比"
  if grep -q -- "$BANNER_RE" "$COPY_DIR/README.md"; then
    echo "    OK      副本 README 仍含「$BANNER_TEXT」blockquote"
  else
    drift=$((drift + 1))
    echo "    FAILED  副本 README 缺少「$BANNER_TEXT」blockquote"
  fi
fi

# ---------------------------------------------------------------------------
echo
echo '==> [4/4] 死链：两棵树 Markdown 相对链接的可解析性'
# ---------------------------------------------------------------------------

# 抽取 ](target)，逐条按所在文件目录解析；外部链接 / 锚点 / 绝对路径跳过。
scan_dead_links() {
  local dir="$1"
  local md rel base lineno target path

  while IFS= read -r md; do
    rel="${md#"$dir"/}"
    base="$(dirname "$md")"
    while IFS=$'\t' read -r lineno target; do
      case "$target" in
        'http://'*|'https://'*|'mailto:'*|'#'*|'/'*|'')
          skipped_links=$((skipped_links + 1))
          continue
          ;;
      esac
      path="${target%%#*}"
      if [ "${path#<}" != "$path" ] && [ "${path%>}" != "$path" ]; then
        path="${path#<}"
        path="${path%>}"
      fi
      if [ -z "$path" ]; then
        skipped_links=$((skipped_links + 1))
        continue
      fi
      checked_links=$((checked_links + 1))
      if [ ! -e "$base/$path" ]; then
        echo "             $rel:$lineno → $target"
        dead=$((dead + 1))
      fi
    done < <(awk '{
        rest = $0
        while (match(rest, /\]\([^)]*\)/)) {
          print NR "\t" substr(rest, RSTART + 2, RLENGTH - 3)
          rest = substr(rest, RSTART + RLENGTH)
        }
      }' "$md")
  done < <(find "$dir" -type f -name '*.md' | LC_ALL=C sort)
}

if [ "$have_root" = '1' ]; then
  scan_dead_links "$SRC_DIR"
else
  echo "    （根级 $SRC_DIR/ 不存在，只扫副本）"
fi
scan_dead_links "$COPY_DIR"

if [ "$dead" -eq 0 ]; then
  echo "    OK      $checked_links 条本地相对链接全部可达"
else
  echo "    FAILED  $dead 条死链（格式：文件:行号 → 目标）"
fi

# ---------------------------------------------------------------------------
echo
echo "统计口径：根级 $SRC_DIR/ 为对照，文件数 / md 数 / 源码数按副本 $COPY_DIR/ 计。"
if [ "$skipped_links" -gt 0 ]; then
  echo "（另有 $skipped_links 条外部链接 / 锚点 / 绝对路径未校验）"
fi
echo "结果：${copy_count} 个文件 / ${md_count} 个 md / ${source_count} 个源码 / ${checked_links} 条链接，${drift} 处漂移，${dead} 条死链"

if [ "$drift" -eq 0 ] && [ "$dead" -eq 0 ]; then
  echo 'OK'
  exit 0
fi

echo 'FAILED'
exit 1
