#Requires -Version 5.1
<#
.SYNOPSIS
    关闭 clangd 语义索引：移除 .clangd 与编译数据库，把智能感知交回 PlatformIO。

.DESCRIPTION
    只删本机生成物，不动版本库、不动 .vscode/settings.json（Q8 保持现状）。
    .clangd / compile_commands.json / .cache 均被 .gitignore 忽略，可随时重跑
    init-clangd.ps1 恢复。不需要 Node / .mjs 转发层。

    脚本未签名，需要绕过执行策略：
        powershell -ExecutionPolicy Bypass -File .\scripts\disable-clangd.ps1
#>

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

Write-Host '==> [1/2] 删除 .clangd'
$clangdPath = Join-Path $repoRoot '.clangd'
if (Test-Path $clangdPath) {
    Remove-Item $clangdPath -Force
    Write-Host '    已删除 .clangd'
}
else {
    Write-Host '    未找到 .clangd，跳过'
}

Write-Host '==> [2/2] 删除 compile_commands.json'
$dbPath = Join-Path $repoRoot 'compile_commands.json'
if (Test-Path $dbPath) {
    Remove-Item $dbPath -Force
    Write-Host '    已删除 compile_commands.json'
}
else {
    Write-Host '    未找到 compile_commands.json，跳过'
}

Write-Host ''
Write-Host '完成。若 VS Code 设置里加过 clangd.arguments，请自行移除或把 clangd 扩展设为 Disable (Workspace)。'
Write-Host '恢复：powershell -ExecutionPolicy Bypass -File .\scripts\init-clangd.ps1'
