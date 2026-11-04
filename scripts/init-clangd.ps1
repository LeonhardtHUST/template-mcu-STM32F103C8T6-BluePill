#Requires -Version 5.1
<#
.SYNOPSIS
    初始化 clangd 语义索引：生成 compile_commands.json、写 .clangd。

.DESCRIPTION
    使用 PlatformIO 原生 `pio run -t compiledb`，不需要 Node / .mjs 转发层。
    compile_commands.json / .clangd / .cache/ 都已被 .gitignore 忽略，不入库、不进固件。
    **不动 .vscode/settings.json**：本模板 4 个 .vscode 文件刻意入库（Q8），
    clangd 的启动参数只在这里打印提示，由使用者自行决定是否加到编辑器设置。
    换机器 / 换 PlatformIO Core 目录后需要重跑本脚本。

    脚本未签名，需要绕过执行策略：
        powershell -ExecutionPolicy Bypass -File .\scripts\init-clangd.ps1
#>

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

if (-not (Get-Command pio -ErrorAction SilentlyContinue)) {
    throw '找不到 pio，请先安装 PlatformIO Core（pip install platformio）或 VS Code 的 PlatformIO IDE 插件。'
}

# clangd 的 YAML 解析器不吃 BOM，统一用 UTF-8 无 BOM 写文件
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

Write-Host '==> [1/2] 生成 compile_commands.json（pio run -t compiledb）'
pio run -t compiledb
if ($LASTEXITCODE -ne 0) {
    throw "pio run -t compiledb 失败（退出码 $LASTEXITCODE）"
}

# --query-driver 是 clangd 启动参数，不能写进 .clangd，只在下方打印建议。
Write-Host '==> [2/2] 写入 .clangd'
$clangdLines = @(
    '# 由 scripts/init-clangd.ps1 生成；本文件已被 .gitignore 忽略。'
    'CompileFlags:'
    '  CompilationDatabase: .'
)
$clangdText = ($clangdLines -join "`n") + "`n"
[System.IO.File]::WriteAllText((Join-Path $repoRoot '.clangd'), $clangdText, $utf8NoBom)

Write-Host ''
Write-Host '完成。compile_commands.json 与 .clangd 已生成（均被 .gitignore 忽略）。'
Write-Host ''
Write-Host '提示：clangd 需要 --query-driver 才能使用 ARM 交叉编译器的头文件，'
Write-Host '      请把下面这段加到 VS Code 设置（本脚本不代改 .vscode/settings.json）：'
Write-Host ''
Write-Host '  "clangd.arguments": ['
Write-Host '    "--compile-commands-dir=${workspaceFolder}",'
Write-Host '    "--query-driver=**/arm-none-eabi-gcc,**/arm-none-eabi-g++,**/arm-none-eabi-gcc.exe,**/arm-none-eabi-g++.exe",'
Write-Host '    "--background-index"'
Write-Host '  ],'
Write-Host ''
Write-Host '处理 Core/** 前请留意 TEMPLATE-PLACEHOLDERS.md D1：formatOnSave 会重排生成文件。'
Write-Host '最后在 VS Code 命令面板执行：clangd: Restart language server'
Write-Host '恢复 / 关闭：powershell -ExecutionPolicy Bypass -File .\scripts\disable-clangd.ps1'
