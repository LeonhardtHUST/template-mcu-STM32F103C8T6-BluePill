#Requires -Version 5.1
<#
.SYNOPSIS
    校验 docs/bluepill/examples/（资料侧副本）与根级 examples/（原件）是否仍然镜像一致。

.DESCRIPTION
    副本存在的意义是让 scripts/init-project.ps1 --drop-examples 删掉根级示例后资料区不自断链。
    副本靠 `Remove-Item -Recurse -Force docs/bluepill/examples` + `Copy-Item -Recurse examples` 整体镜像，
    手改副本、只改一侧、或镜像后忘了把「本目录是副本」blockquote 贴回，都会让两棵树漂移。
    本脚本把这件事变成一条可重复执行的命令，替代「改动后逐条 ls 抽查」。

    与 scripts/check-examples-mirror.sh 逻辑等价、判定一致、退出码一致，但为**原生 PowerShell 实现**，
    不调用 bash / Git Bash。脚本未签名，需要绕过执行策略：
        powershell -ExecutionPolicy Bypass -File .\scripts\check-examples-mirror.ps1

    Windows PowerShell 5.1 上不写 $LASTEXITCODE 之外的退出码来源，param 里不加 -Verbose 冲突项。

.PARAMETER 无
    无参数、无副作用：只读文件，不写仓库，不跑构建，不碰 .ioc / Core/。

.EXITCODES
    0  一致：结构与字节全等、正文归一化后全等、两棵树都没有死链
       （含「根级 examples/ 不存在 -> 跳过结构/字节/正文比对」但副本死链扫描仍通过的情形）
    1  发现不一致或死链；逐条打印漂移文件与死链位置
    2  前置条件错误：不在本模板仓库根、或副本目录 docs/bluepill/examples/ 不存在

.NOTES
    判据（只有下面两条算「合法差异」，其余一律算漂移）：

    1. 副本里指向 examples/ 之外的 Markdown 链接，比根级多 1~3 层 ../（链接目标层级差）；
       examples/ 内部互链（gpio-blink/…、recipes/…、INDEX.md、README.md）保持不变。
       因此正文比对先把「反引号路径标签 + 链接目标」整体折叠成 [LINK]，
       再把剩余链接的 ](...) 折叠成 ](LINK)；折叠掉的正是标签层级与目标层级这两类合法差异。
       （链接标签本身也是路径、也会跟着多 ../，例如 [`../docs/bluepill/examples.md`] 在副本里是
       [`../examples.md`]，所以标签必须一起折叠，否则同一句话会被误判为正文漂移。）

    2. 副本 README.md 顶部多一段以 `> **本目录是副本` 开头、到第一个空行结束的 blockquote；
       根级 README.md 没有。正文比对对副本 README 剔除这段，并双向断言其存在性
       （副本必须有、根级必须没有），防止镜像后忘记贴回或误贴到根级。

    四项检查：
       [1/4] 结构      两棵树相对路径集合必须完全相等（根级不存在时 SKIP）
       [2/4] 源码/二进制 所有非 .md 文件逐字节比对
       [3/4] 正文      所有 .md 归一化后逐行比对 + 副本 README blockquote 双向断言
       [4/4] 死链      两棵树所有 .md 的 ](target) 解析相对路径，必须落在真实文件或目录上

    已知局限（不要据此扩大判定）：
       - 链接用正则抽取，代码块里出现的 `](` 字面量会被当成链接（当前仓库无此情况）。
       - 只校验链接目标能否解析到真实文件或目录，不校验语义，也不校验 #fragment 锚点是否存在。
       - [1] 只比文件、不比空目录，空目录增删不会报出。
       - 折叠 [`path`](target) 会掩盖「反引号路径标签被改坏」这类改动；
         纯文字标签（如 [工程规约 §3](...)）参与比对，改字仍会被抓到。
       - 不跟随符号链接、不做路径大小写归一（Windows 大小写不敏感属已知平台差异）。
#>

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Split-Path $PSScriptRoot -Parent)).ProviderPath
Set-Location $repoRoot

$srcDir = 'examples'
$copyDir = Join-Path (Join-Path 'docs' 'bluepill') 'examples'
$bannerRegex = '^> \*\*本目录是副本'
$bannerText = '> **本目录是副本'

$script:drift = 0
$script:dead = 0
$script:checkedLinks = 0
$script:skippedLinks = 0

# 前置条件：必须站在本模板仓库根，且副本目录存在。
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'AGENTS.md') -PathType Leaf)) {
    Write-Host "错误：当前目录不是本模板仓库根（缺少 AGENTS.md）：$repoRoot"
    exit 2
}
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'docs\bluepill') -PathType Container)) {
    Write-Host "错误：当前目录不是本模板仓库根（缺少 docs/bluepill/）：$repoRoot"
    exit 2
}
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $copyDir) -PathType Container)) {
    Write-Host "错误：副本目录不存在：$repoRoot\$copyDir"
    Write-Host "      预期先执行：Remove-Item -Recurse -Force $copyDir; Copy-Item -Recurse $srcDir $copyDir（见 docs/bluepill/examples.md §3）"
    exit 2
}

# 目录下所有文件的相对路径（正斜杠归一），用于结构比对。
function Get-RelativeFileList {
    param([Parameter(Mandatory)][string]$Directory)

    $root = (Resolve-Path -LiteralPath $Directory).ProviderPath
    $result = New-Object System.Collections.Generic.List[string]
    $items = Get-ChildItem -LiteralPath $root -Recurse -File -Force
    foreach ($item in $items) {
        $rel = $item.FullName.Substring($root.Length)
        $rel = $rel.TrimStart([char[]]@('\', '/'))
        $result.Add($rel.Replace('\', '/'))
    }
    return ,$result.ToArray()
}

# 归一化一个 Markdown 文件并返回行数组：
#   1) [`反引号路径标签`](target) -> [LINK]
#   2) 剩余 ](target)            -> ](LINK)
#   3) -DropBanner 时剔除「本目录是副本」blockquote（含其后的空行）
# 行数组**不裁尾**：与 check-examples-mirror.sh 的逐行 read 口径一致，
# 文件末尾多出的空行属于真实差异，必须被报出来（否则 printf '\n\n' 这类改动会被吞掉）。
# 文件缺失时返回一行哨兵而不是抛异常：结构不一致时脚本必须继续跑完 [4/4] 与汇总行。
function Get-NormalizedLines {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$DropBanner
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ,@('<<MISSING>>')
    }

    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    if ($null -eq $text) { $text = '' }

    $raw = $text -split "\r?\n"
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($item in $raw) { $lines.Add($item) }

    $out = New-Object System.Collections.Generic.List[string]
    $skipping = $false
    foreach ($line in $lines) {
        $norm = [regex]::Replace($line, '\[`[^`]*`\]\([^)]*\)', '[LINK]')
        $norm = [regex]::Replace($norm, '\]\([^)]*\)', '](LINK)')
        if ($DropBanner) {
            if ((-not $skipping) -and ($norm -match $bannerRegex)) {
                $skipping = $true
                continue
            }
            if ($skipping) {
                if ($norm -match '^\s*$') { $skipping = $false }
                continue
            }
        }
        $out.Add($norm)
    }
    return ,$out.ToArray()
}

# 逐字节比较；不做哈希，避免对算法名做假设。
function Test-SameBytes {
    param(
        [Parameter(Mandatory)][string]$Left,
        [Parameter(Mandatory)][string]$Right
    )

    $lb = [System.IO.File]::ReadAllBytes($Left)
    $rb = [System.IO.File]::ReadAllBytes($Right)
    if ($lb.Length -ne $rb.Length) { return $false }
    for ($i = 0; $i -lt $lb.Length; $i++) {
        if ($lb[$i] -ne $rb[$i]) { return $false }
    }
    return $true
}

# 文件是否含「本目录是副本」blockquote；文件缺失当作不含（由调用方判 FAILED），不抛异常。
function Test-FileContainsBanner {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    foreach ($line in [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) {
        if ($line -match $bannerRegex) { return $true }
    }
    return $false
}

# 扫描一棵树的所有 .md 的相对链接是否可达。
function Invoke-DeadLinkScan {
    param([Parameter(Mandatory)][string]$Directory)

    $root = (Resolve-Path -LiteralPath $Directory).ProviderPath
    $files = Get-ChildItem -LiteralPath $root -Recurse -File -Force | Where-Object { $_.Name -like '*.md' } | Sort-Object FullName
    foreach ($file in $files) {
        $relPath = $file.FullName.Substring($root.Length)
        $relPath = $relPath.TrimStart([char[]]@('\', '/')).Replace('\', '/')
        $baseDir = Split-Path -Parent $file.FullName
        $lines = [System.IO.File]::ReadAllLines($file.FullName, [System.Text.Encoding]::UTF8)
        for ($i = 0; $i -lt $lines.Length; $i++) {
            $lineNo = $i + 1
            foreach ($m in [regex]::Matches($lines[$i], '\]\(([^)]*)\)')) {
                $target = $m.Groups[1].Value
                if ($target -eq '') { $script:skippedLinks = $script:skippedLinks + 1; continue }
                if ($target -match '^https?://') { $script:skippedLinks = $script:skippedLinks + 1; continue }
                if ($target -match '^mailto:') { $script:skippedLinks = $script:skippedLinks + 1; continue }
                if ($target.StartsWith('#')) { $script:skippedLinks = $script:skippedLinks + 1; continue }
                if ($target.StartsWith('/')) { $script:skippedLinks = $script:skippedLinks + 1; continue }

                $pathPart = $target.Split('#')[0]
                if ($pathPart.Length -ge 2 -and $pathPart.StartsWith('<') -and $pathPart.EndsWith('>')) {
                    $pathPart = $pathPart.Substring(1, $pathPart.Length - 2)
                }
                if ($pathPart -eq '') { $script:skippedLinks = $script:skippedLinks + 1; continue }

                $script:checkedLinks = $script:checkedLinks + 1
                $full = [System.IO.Path]::Combine($baseDir, $pathPart)
                if (-not (Test-Path -LiteralPath $full)) {
                    Write-Host ('             {0}:{1} → {2}' -f $relPath, $lineNo, $target)
                    $script:dead = $script:dead + 1
                }
            }
        }
    }
}

Write-Host "仓库根：$repoRoot"
Write-Host "原件：$srcDir/    副本：docs/bluepill/examples/"
Write-Host ''

# ---------------------------------------------------------------------------
Write-Host '==> [1/4] 结构：两棵树的相对路径集合'
# ---------------------------------------------------------------------------
$haveRoot = Test-Path -LiteralPath (Join-Path $repoRoot $srcDir) -PathType Container
$copyList = Get-RelativeFileList -Directory $copyDir

if ($haveRoot) {
    $srcList = Get-RelativeFileList -Directory $srcDir
    $srcSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($p in $srcList) { [void]$srcSet.Add($p) }
    $copySet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($p in $copyList) { [void]$copySet.Add($p) }
    $onlySrc = @($srcList | Where-Object { -not $copySet.Contains($_) } | Sort-Object)
    $onlyCopy = @($copyList | Where-Object { -not $srcSet.Contains($_) } | Sort-Object)

    if ($onlySrc.Count -eq 0 -and $onlyCopy.Count -eq 0) {
        Write-Host ('    OK      两边都是 {0} 个文件，路径集合完全相等' -f $copyList.Count)
    }
    else {
        $script:drift = $script:drift + 1
        Write-Host '    FAILED  路径集合不一致（< 只在根级 / > 只在副本）：'
        foreach ($p in $onlySrc) { Write-Host ('             < {0}' -f $p) }
        foreach ($p in $onlyCopy) { Write-Host ('             > {0}' -f $p) }
    }
}
else {
    Write-Host "    SKIP    根级 $srcDir/ 不存在（已执行 --drop-examples 或已删除），跳过整树结构比对"
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '==> [2/4] 源码/二进制：所有非 Markdown 文件逐字节比对'
# ---------------------------------------------------------------------------
$sourceCount = 0
if ($haveRoot) {
    $byteBad = New-Object System.Collections.Generic.List[string]
    foreach ($rel in $srcList) {
        if ($rel -like '*.md') { continue }
        $sourceCount = $sourceCount + 1
        $left = Join-Path (Join-Path $repoRoot $srcDir) ($rel.Replace('/', '\'))
        $right = Join-Path (Join-Path $repoRoot $copyDir) ($rel.Replace('/', '\'))
        $leftOk = Test-Path -LiteralPath $left -PathType Leaf
        $rightOk = Test-Path -LiteralPath $right -PathType Leaf
        if ((-not $leftOk) -or (-not $rightOk)) {
            $byteBad.Add($rel)
            continue
        }
        if (-not (Test-SameBytes -Left $left -Right $right)) { $byteBad.Add($rel) }
    }

    if ($byteBad.Count -gt 0) {
        $script:drift = $script:drift + 1
        Write-Host '    FAILED  以下非 Markdown 文件字节不一致（或一侧缺失）：'
        foreach ($rel in $byteBad) { Write-Host ('             {0}' -f $rel) }
    }
    else {
        Write-Host ('    OK      {0} 个非 Markdown 文件逐字节相同' -f $sourceCount)
    }
}
else {
    Write-Host "    SKIP    根级 $srcDir/ 不存在，没有对照可比"
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '==> [3/4] 正文：Markdown 归一化后逐行比对'
# ---------------------------------------------------------------------------
$mdCount = 0
if ($haveRoot) {
    $bodyBad = New-Object System.Collections.Generic.List[string]
    foreach ($rel in $srcList) {
        if ($rel -notlike '*.md') { continue }
        $mdCount = $mdCount + 1
        $srcPath = Join-Path (Join-Path $repoRoot $srcDir) ($rel.Replace('/', '\'))
        $copyPath = Join-Path (Join-Path $repoRoot $copyDir) ($rel.Replace('/', '\'))
        # 一侧缺失时只记漂移、不动用 .NET 读取：结构检查已报出，这里必须继续跑完 [4/4] 与汇总行。
        if (-not (Test-Path -LiteralPath $srcPath -PathType Leaf)) {
            $bodyBad.Add($rel)
            Write-Host ('             --- {0}（根级缺失，结构检查应已报出）' -f $rel)
            continue
        }
        if (-not (Test-Path -LiteralPath $copyPath -PathType Leaf)) {
            $bodyBad.Add($rel)
            Write-Host ('             --- {0}（副本缺失，结构检查应已报出）' -f $rel)
            continue
        }
        $srcNorm = Get-NormalizedLines -Path $srcPath
        if ($rel -eq 'README.md') {
            $copyNorm = Get-NormalizedLines -Path $copyPath -DropBanner
        }
        else {
            $copyNorm = Get-NormalizedLines -Path $copyPath
        }
        if ($srcNorm.Length -ne $copyNorm.Length) {
            $bodyBad.Add($rel)
            Write-Host ('             --- {0}（归一化后行数 {1} vs {2}）' -f $rel, $srcNorm.Length, $copyNorm.Length)
            continue
        }
        $diffIndex = -1
        for ($i = 0; $i -lt $srcNorm.Length; $i++) {
            if ($srcNorm[$i] -cne $copyNorm[$i]) { $diffIndex = $i; break }
        }
        if ($diffIndex -ge 0) {
            $bodyBad.Add($rel)
            Write-Host ('             --- {0}（归一化后第 {1} 行起不同）' -f $rel, ($diffIndex + 1))
            $limit = [Math]::Min($diffIndex + 3, $srcNorm.Length - 1)
            for ($i = $diffIndex; $i -le $limit; $i++) {
                Write-Host ('             - {0}' -f $srcNorm[$i])
                Write-Host ('             + {0}' -f $copyNorm[$i])
            }
        }
    }

    if ($bodyBad.Count -gt 0) {
        $script:drift = $script:drift + 1
        Write-Host ('    FAILED  {0} 个 Markdown 正文在归一化后仍不一致（见上）' -f $bodyBad.Count)
    }
    else {
        Write-Host ('    OK      {0} 个 Markdown 归一化后正文全等' -f $mdCount)
    }

    # blockquote 双向断言：副本必须有、根级必须没有。
    $copyReadme = Join-Path (Join-Path $repoRoot $copyDir) 'README.md'
    $srcReadme = Join-Path (Join-Path $repoRoot $srcDir) 'README.md'
    if (Test-FileContainsBanner -Path $copyReadme) {
        Write-Host ('    OK      副本 README 含合法差异段「{0}」' -f $bannerText)
    }
    else {
        $script:drift = $script:drift + 1
        Write-Host ('    FAILED  副本 README 缺少「{0}」blockquote（镜像后忘记贴回？）' -f $bannerText)
    }
    if (Test-FileContainsBanner -Path $srcReadme) {
        $script:drift = $script:drift + 1
        Write-Host ('    FAILED  根级 README 不应出现「{0}」blockquote（只属于副本）' -f $bannerText)
    }
    else {
        Write-Host '    OK      根级 README 不含该 blockquote'
    }
}
else {
    Write-Host "    SKIP    根级 $srcDir/ 不存在，没有对照可比"
    foreach ($rel in $copyList) {
        if ($rel -like '*.md') { $mdCount = $mdCount + 1 }
    }
    $copyReadme = Join-Path (Join-Path $repoRoot $copyDir) 'README.md'
    if (Test-FileContainsBanner -Path $copyReadme) {
        Write-Host ('    OK      副本 README 仍含「{0}」blockquote' -f $bannerText)
    }
    else {
        $script:drift = $script:drift + 1
        Write-Host ('    FAILED  副本 README 缺少「{0}」blockquote' -f $bannerText)
    }
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '==> [4/4] 死链：两棵树 Markdown 相对链接的可解析性'
# ---------------------------------------------------------------------------
if ($haveRoot) {
    Invoke-DeadLinkScan -Directory $srcDir
}
else {
    Write-Host "    （根级 $srcDir/ 不存在，只扫副本）"
}
Invoke-DeadLinkScan -Directory $copyDir

if ($script:dead -eq 0) {
    Write-Host ('    OK      {0} 条本地相对链接全部可达' -f $script:checkedLinks)
}
else {
    Write-Host ('    FAILED  {0} 条死链（格式：文件:行号 → 目标）' -f $script:dead)
}

# ---------------------------------------------------------------------------
Write-Host ''
$fileCount = 0
$mdTotal = 0
$sourceTotal = 0
foreach ($rel in $copyList) {
    $fileCount = $fileCount + 1
    if ($rel -like '*.md') { $mdTotal = $mdTotal + 1 } else { $sourceTotal = $sourceTotal + 1 }
}

Write-Host "统计口径：根级 $srcDir/ 为对照，文件数 / md 数 / 源码数按副本 docs/bluepill/examples/ 计。"
if ($script:skippedLinks -gt 0) {
    Write-Host ('（另有 {0} 条外部链接 / 锚点 / 绝对路径未校验）' -f $script:skippedLinks)
}
Write-Host ('结果：{0} 个文件 / {1} 个 md / {2} 个源码 / {3} 条链接，{4} 处漂移，{5} 条死链' -f `
    $fileCount, $mdTotal, $sourceTotal, $script:checkedLinks, $script:drift, $script:dead)

if ($script:drift -eq 0 -and $script:dead -eq 0) {
    Write-Host 'OK'
    exit 0
}

Write-Host 'FAILED'
exit 1
