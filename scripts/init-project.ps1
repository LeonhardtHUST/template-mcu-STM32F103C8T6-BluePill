#Requires -Version 5.1
<#
.SYNOPSIS
    初始化新工程：把模板里的工程名 / 仓库名一次改到位（A2 六处联动 + A3 仓库名 + A4 README 标题）。

.DESCRIPTION
    只替换两处字面串：OLD_PROJECT（工程名）与 OLD_REPO（仓库名），外加根 .ioc 文件名重命名。
    不改 .ioc 的引脚 / 时钟 / 外设内容，不改 platformio.ini，不改 Core/Src/**。
    不执行任何 git 写操作：不碰 .git/config、不碰 remote、不 commit、不改 hooksPath。
    不自动填写绝对路径：scripts/cubemx-init.mx 的 __PROJECT_DIR__ 始终留给人工处理。
    AGENTS.md 的第三方原件约束用成对 HTML 注释标记块做稳定替换，可重复运行。

    脚本未签名，需要绕过执行策略：
        powershell -ExecutionPolicy Bypass -File .\scripts\init-project.ps1 my-board -Yes

.PARAMETER NewProjectName
    新工程名（位置参数 0，必填）。只允许字母、数字、点、下划线、连字符，且以字母或数字开头。

.PARAMETER RepoName
    新仓库名，默认与新工程名相同。

.PARAMETER Yes
    不问，直接用默认值（资料原件默认允许、Flash 默认 64k）。

.PARAMETER DryRun
    只打印将做什么，不写任何文件（含将 patch 的 AGENTS.md 内容）。

.PARAMETER Flash
    Flash 容量：64k（默认）或 128k。选 128k 时提示同步 board_build.ldscript。

.PARAMETER KeepOriginals
    yes（默认，允许把资料原件放进仓库 → 不写约束）或 no（写入第三方原件约束）。

.PARAMETER DropExamples
    顺带删除根级 examples/ 与 README 的 EXAMPLES 标记区块。默认保留；
    docs/bluepill/examples/ 资料副本不受影响（它保证资料区不死链）。

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\init-project.ps1 my-board -DryRun
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\init-project.ps1 my-board -RepoName my-repo -Yes -Flash 128k
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\init-project.ps1 my-board -Yes -KeepOriginals no
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\init-project.ps1 my-board -Yes -DropExamples
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$NewProjectName,

    [string]$RepoName = '',

    [Alias('y')]
    [switch]$Yes,

    [Alias('n')]
    [switch]$DryRun,

    [ValidateSet('64k', '128k')]
    [string]$Flash = '64k',

    [ValidateSet('yes', 'no')]
    [string]$KeepOriginals = 'yes',

    [switch]$DropExamples
)

$ErrorActionPreference = 'Stop'

$oldProject = 'stm32-digital-clock'
$oldRepo    = 'template-mcu-STM32F103C8T6-BluePill'
$oldIoc     = "$oldProject.ioc"
$beginMark  = '<!-- BEGIN: BP_THIRD_PARTY_ORIGINAL_RULE -->'
$endMark    = '<!-- END: BP_THIRD_PARTY_ORIGINAL_RULE -->'
$examplesBegin = '<!-- BEGIN EXAMPLES -->'
$examplesEnd   = '<!-- END EXAMPLES -->'

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

if ([string]::IsNullOrWhiteSpace($NewProjectName)) {
    throw '缺少新工程名。用法：init-project.ps1 <新工程名> [-Yes] [-DryRun]'
}
if ($NewProjectName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw "新工程名只能用字母、数字、点、下划线、连字符，且必须以字母或数字开头：$NewProjectName"
}
if ([string]::IsNullOrWhiteSpace($RepoName)) { $RepoName = $NewProjectName }
if ($RepoName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw "新仓库名只能用字母、数字、点、下划线、连字符，且必须以字母或数字开头：$RepoName"
}
if ($NewProjectName -eq $oldProject) {
    throw '新工程名不能与模板默认工程名相同'
}

# ---- 平实大白话询问（Q5）：文案不含任何术语 ----
if (-not $Yes -and -not $DryRun) {
    $answer = Read-Host '新建的工程要把资料原件放进仓库吗？[Y/n]'
    if ($answer -match '^(n|N|no|NO|No|不|不允许)$') {
        $KeepOriginals = 'no'
    }
    else {
        $KeepOriginals = 'yes'
    }
}

# ---- AGENTS.md 标记块的两份内容（单引号 here-string，避免 $ 与反引号被解释）----
$allowBlock = @'
<!-- 初始化时选择了「要把资料原件放进仓库」，因此这里不写入第三方原件约束。 -->
<!-- 本工程的资料许可、体积与来源由维护者自行判断；如需恢复约束，重跑 scripts/init-project.ps1 并选择「不允许」。 -->
'@

$denyBlock = @'
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
'@

if ($KeepOriginals -eq 'yes') {
    $agentsBlock = $allowBlock
    $originalsWord = '允许（不写入第三方原件约束）'
}
else {
    $agentsBlock = $denyBlock
    $originalsWord = '不允许（写入第三方原件约束）'
}

# ---- examples/ 的去留（默认保留；-DropExamples 才删）----
if ($DropExamples) {
    $examplesWord = '删除（同时清理 README 的 EXAMPLES 标记区块）'
}
else {
    $examplesWord = '保留'
}

# UTF-8 无 BOM + LF，避免 clangd / Git 行尾噪声
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Write-TextFile([string]$path, [string]$text) {
    $normalized = $text -replace "`r`n", "`n"
    if (-not $normalized.EndsWith("`n")) { $normalized += "`n" }
    [System.IO.File]::WriteAllText((Join-Path $repoRoot $path), $normalized, $utf8NoBom)
}
function Read-TextFile([string]$path) {
    return [System.IO.File]::ReadAllText((Join-Path $repoRoot $path))
}

$linkedFiles = @(
    '.vscode/tasks.json',
    'scripts/cubemx-generate.mx',
    'scripts/cubemx-init.mx',
    'README.md',
    'TEMPLATE-PLACEHOLDERS.md',
    'docs/bluepill/README.md',
    'docs/bluepill/SOURCES.md'
)

if ($DryRun) {
    Write-Host '== 预演（-DryRun）：不写任何文件 =='
    Write-Host ''
}
else {
    Write-Host '== 初始化新工程 =='
    Write-Host ''
}

Write-Host "新工程名： $NewProjectName"
Write-Host "新仓库名： $RepoName"
Write-Host "Flash   ： $Flash"
Write-Host "资料原件： $originalsWord"
Write-Host "示例目录： $examplesWord"
Write-Host ''

# 1) .ioc 内容 + 文件名（A2 的 ProjectName / ProjectFileName / 文件名三处）
$iocPath = Join-Path $repoRoot $oldIoc
if (Test-Path $iocPath) {
    if ($DryRun) {
        Write-Host "[预演] 改写 $oldIoc ：$oldProject -> $NewProjectName ；$oldRepo -> $RepoName"
        Write-Host "[预演] 重命名 $oldIoc -> $NewProjectName.ioc"
    }
    else {
        $content = (Read-TextFile $oldIoc).Replace($oldProject, $NewProjectName).Replace($oldRepo, $RepoName)
        Write-TextFile $oldIoc $content
        Move-Item -Path $iocPath -Destination (Join-Path $repoRoot "$NewProjectName.ioc") -Force
        Write-Host "[已改] $oldIoc -> $NewProjectName.ioc（含 ProjectName / ProjectFileName）"
    }
}
else {
    Write-Host "[跳过] 未找到 $oldIoc（可能已经改过名）"
}

# 2) 其余联动文件
foreach ($f in $linkedFiles) {
    $full = Join-Path $repoRoot $f
    if (-not (Test-Path $full)) {
        Write-Host "[跳过] 未找到 $f"
        continue
    }
    if ($DryRun) {
        Write-Host "[预演] 改写 $f ：$oldProject -> $NewProjectName ；$oldRepo -> $RepoName"
    }
    else {
        $content = (Read-TextFile $f).Replace($oldProject, $NewProjectName).Replace($oldRepo, $RepoName)
        Write-TextFile $f $content
        Write-Host "[已改] $f"
    }
}

# 3) AGENTS.md 的 Q5 patch（成对标记块稳定替换）
Write-Host ''
Write-Host "[AGENTS.md] 将把标记块 $beginMark ... $endMark 的内容替换为："
Write-Host $agentsBlock
if (-not $DryRun) {
    $agentsPath = Join-Path $repoRoot 'AGENTS.md'
    $agentsText = Read-TextFile 'AGENTS.md'
    if ($agentsText.Contains($beginMark) -and $agentsText.Contains($endMark)) {
        $escapedBegin = [regex]::Escape($beginMark)
        $escapedEnd   = [regex]::Escape($endMark)
        $pattern = "(?s)($escapedBegin).*?($escapedEnd)"
        $replacement = '$1' + "`n" + ($agentsBlock -replace "`r`n", "`n") + "`n" + '$2'
        $newText = [regex]::Replace($agentsText, $pattern, $replacement)
        Write-TextFile 'AGENTS.md' $newText
        Write-Host '[已改] AGENTS.md 标记块内容'
    }
    else {
        Write-Warning 'AGENTS.md 缺少成对标记，未修改（请人工核对）。'
    }
}
else {
    Write-Host '[预演] 不写 AGENTS.md（上面就是要写入的内容）'
}

# 4) 可选：删除 examples/（等价能力来自 B 仓的 remove-examples；A 用 PowerShell 实现，
#    不引入 .mjs 转发层，且只在 -DropExamples 时生效，默认不动 examples/）
if ($DropExamples) {
    Write-Host ''
    Write-Host '[examples] 处理计划：'
    $examplesPath = Join-Path $repoRoot 'examples'
    $examplesExists = Test-Path -LiteralPath $examplesPath -PathType Container
    if ($examplesExists) {
        $exampleFileCount = @(Get-ChildItem -LiteralPath $examplesPath -Recurse -File -Force).Count
        Write-Host "  删除 examples/（当前 $exampleFileCount 个文件）"
    }
    else {
        Write-Host '  examples/ 不存在，无需删除'
    }

    # 成对标记必须各出现且仅出现一次，缺一半就拒绝猜、交人工处理，避免留死链。
    $readmePath = Join-Path $repoRoot 'README.md'
    $readmeReady = $false
    if (Test-Path -LiteralPath $readmePath) {
        $readmeText = Read-TextFile 'README.md'
        $beginCount = ([regex]::Matches($readmeText, '(?m)^' + [regex]::Escape($examplesBegin) + '\r?$')).Count
        $endCount   = ([regex]::Matches($readmeText, '(?m)^' + [regex]::Escape($examplesEnd)   + '\r?$')).Count
        if ($beginCount -eq 1 -and $endCount -eq 1) {
            $readmeReady = $true
            Write-Host "  README.md 移除 $examplesBegin 与 $examplesEnd 之间的区块（含两行标记）"
        }
        else {
            Write-Warning 'README.md 的 EXAMPLES 标记不成对，跳过清理（请人工核对 examples/ 死链）。'
        }
    }
    else {
        Write-Warning 'README.md 不存在，跳过清理。'
    }
    Write-Host '  docs/bluepill/examples/ 资料副本不在删除范围内（资料区据此保持可达）。'

    if ($DryRun) {
        Write-Host '[预演] 不删除任何目录、不写 README.md'
    }
    else {
        $deleteFailed = $false
        if ($examplesExists) {
            try {
                Remove-Item -LiteralPath $examplesPath -Recurse -Force -Confirm:$false -ErrorAction Stop
                Write-Host '[已删] examples/'
            }
            catch {
                # 本机若用 safe-delete 类 profile 覆盖了 Remove-Item，这里可能抛错。
                # 但有的封装是「先删（移进回收站）再抛」，所以**不能假定「抛了异常 ⇒ 什么都没删」**。
                # 必须回头查目录是否还在，两种结局都要保持状态一致：
                #   ① 目录还在   → 跳过 README 清理（目录 + 文档都留着，无死链）；
                #   ② 目录已消失 → 继续清理 README 区块（否则 README 立刻产生 examples/ 死链）。
                if (-not (Test-Path -LiteralPath $examplesPath)) {
                    $deleteFailed = $false
                    Write-Warning '删除 examples/ 抛异常但目录已消失（沙箱 / 回收站类 profile）：继续清理 README 的 EXAMPLES 区块。'
                }
                else {
                    $deleteFailed = $true
                    Write-Warning "删除 examples/ 失败：$($_.Exception.Message)"
                    Write-Warning '已跳过 README 清理以保持状态一致；请用 -NoProfile 重跑，或手工删掉 examples/ 后再清理 README 区块。'
                }
            }
        }
        if ($readmeReady -and -not $deleteFailed) {
            $options = [System.Text.RegularExpressions.RegexOptions]::Multiline -bor
                       [System.Text.RegularExpressions.RegexOptions]::Singleline
            # 连同区块后面那一个空行一起消费，避免留下两连空行。
            $pattern = '(?m)^' + [regex]::Escape($examplesBegin) + '\r?\n.*?^' + [regex]::Escape($examplesEnd) + '\r?\n(\r?\n)?'
            $cleaned = [regex]::Replace($readmeText, $pattern, '', $options)
            # 「目录结构」在代码块里，没法用标记块包住，按固定注释文本精确匹配删掉那一行。
            $cleaned = [regex]::Replace($cleaned, '(?m)^examples/[ \t]+# 自有最小示例[^\r\n]*\r?\n', '')
            Write-TextFile 'README.md' $cleaned
            Write-Host '[已改] README.md 移除 EXAMPLES 标记区块'
        }
    }
}

# 5) Flash 选项提示（脚本不改 platformio.ini）
Write-Host ''
if ($Flash -eq '128k') {
    Write-Host '[提醒] 你选了 128K Flash：请在 platformio.ini 里同步设置'
    Write-Host '        board_build.ldscript 指向 128K 链接脚本（脚本不代改），并以实测容量为准。'
    Write-Host '        C8T6 有 64K / 128K 两种说法，见 TEMPLATE-PLACEHOLDERS.md B3 / G 节。'
}
else {
    Write-Host '[默认] 64K Flash：与内置 genericSTM32F103C8.json、STM32F103C8TX_FLASH.ld 一致，'
    Write-Host '        不改 platformio.ini，也不新建自定义 boards/ 目录。'
}

# 6) 仍需人工项（脚本不自动填绝对路径、不碰 git）
Write-Host ''
Write-Host '== 仍需人工处理（脚本不代做）=='
Write-Host '  1. scripts/cubemx-init.mx 里的 project path __PROJECT_DIR__：填本工程的绝对路径'
Write-Host '     （CubeMX 的 .mx 脚本不支持变量，脚本不会自动填）。'
Write-Host '  2. 目录名：把仓库文件夹本身改成新名字。'
Write-Host '  3. remote：git remote -v 仍指向模板仓库，自己改成新仓库地址（脚本不碰 git 配置）。'
Write-Host '  4. clangd：换机器后重跑 scripts/init-clangd.ps1（或 .sh）重新生成索引。'
Write-Host '  5. 资料：docs/bluepill/SOURCES.md 的字段、docs/bluepill/README.md 主索引、'
Write-Host '     board-pinout.md / examples.md / Core/Inc/bluepill.h 要按新板卡重填（见 PLACEHOLDERS H 节）。'
if ($DropExamples) {
    Write-Host '  6. README「目录结构」代码块里的 examples/ 一行按固定注释文本匹配删除，'
    Write-Host '     若你改过该行注释，它会被保留下来，请手动核对并删掉。'
}

if ($DryRun) {
    Write-Host ''
    Write-Host '预演结束：以上都没有写入任何文件。确认后再去掉 -DryRun 重跑。'
}
else {
    Write-Host ''
    Write-Host '完成。建议先 git diff 检查一遍，再按上面的清单处理人工项。'
}
