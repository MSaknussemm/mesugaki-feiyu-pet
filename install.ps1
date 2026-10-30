#Requires -Version 5.1
<#
.SYNOPSIS
    安装 / 卸载 bluewhale_tv 桌宠角色素材包。

.DESCRIPTION
    把 characters\bluewhale_tv 复制进 dsh-pet-indesktop（WebM 版）的角色目录。
    原角色会先被整体备份到 _internal\assets\_character-backups\，-Uninstall 可还原。
    不需要管理员权限。

.PARAMETER InstallDir
    桌宠安装目录。不填就自动从注册表 / 默认路径里找。

.PARAMETER Uninstall
    卸载：把当前 bluewhale_tv 移走，并还原最近一次备份。

.PARAMETER DryRun
    只打印计划，不动任何文件。

.PARAMETER Force
    桌宠正在运行时也照做（不推荐，程序会在退出时改写素材）。

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -DryRun

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [string]$InstallDir,
    [switch]$Uninstall,
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$CharacterId = 'bluewhale_tv'
$ScriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SourceDir   = Join-Path $ScriptRoot "characters\$CharacterId"
$ExeNames    = @('dsh-pet-standalone-webm-chat', 'dsh-pet-standalone-webm', 'dsh-pet-standalone')

function Write-Step([string]$Text) { Write-Host "  $Text" }
function Write-Head([string]$Text) { Write-Host ""; Write-Host $Text -ForegroundColor Cyan }

function Resolve-PetInstallDir {
    param([string]$Explicit)

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($Explicit) { $candidates.Add($Explicit) }

    $uninstallRoots = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($root in $uninstallRoots) {
        Get-ItemProperty $root -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like '*dsh-pet-standalone*' -and $_.InstallLocation } |
            ForEach-Object { $candidates.Add($_.InstallLocation.Trim('"')) }
    }

    if ($env:LOCALAPPDATA) {
        $candidates.Add((Join-Path $env:LOCALAPPDATA 'Programs\dsh-pet-standalone-webm-chat'))
        $candidates.Add((Join-Path $env:LOCALAPPDATA 'Programs\dsh-pet-standalone-webm'))
    }

    foreach ($dir in $candidates) {
        if (-not $dir) { continue }
        $chars = Join-Path $dir '_internal\assets\characters'
        if (Test-Path $chars) { return (Resolve-Path $dir).Path }
    }
    return $null
}

function Get-BackupRoot {
    param([string]$CharactersDir)
    $assets = Split-Path -Parent $CharactersDir
    return (Join-Path $assets '_character-backups')
}

function Get-LatestBackup {
    param([string]$BackupRoot)
    if (-not (Test-Path $BackupRoot)) { return $null }
    return Get-ChildItem $BackupRoot -Directory -Filter "$CharacterId-*" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "^$([regex]::Escape($CharacterId))-\d{8}-\d{6}$" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

# ---------------------------------------------------------------- 前置检查

Write-Host ""
Write-Host "bluewhale_tv 桌宠素材包" -ForegroundColor Cyan
Write-Host "----------------------------"

if (-not (Test-Path $SourceDir)) {
    throw "找不到素材目录：$SourceDir（请在解压后的仓库根目录运行本脚本）"
}

$installRoot = Resolve-PetInstallDir -Explicit $InstallDir
if (-not $installRoot) {
    throw @"
没找到桌宠安装目录。请用 -InstallDir 指定，例如：
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -InstallDir "D:\dsh-pet"
默认位置是 %LOCALAPPDATA%\Programs\dsh-pet-standalone-webm-chat
"@
}

$charactersDir = Join-Path $installRoot '_internal\assets\characters'
$targetDir     = Join-Path $charactersDir $CharacterId
$backupRoot    = Get-BackupRoot -CharactersDir $charactersDir

Write-Head "安装目录"
Write-Step $installRoot
Write-Step "角色目录：$charactersDir"

$running = @()
foreach ($name in $ExeNames) {
    $running += Get-Process -Name $name -ErrorAction SilentlyContinue
}
if ($running.Count -gt 0 -and -not $Force -and -not $DryRun) {
    Write-Host ""
    Write-Host "桌宠正在运行（PID: $($running.Id -join ', ')）。" -ForegroundColor Yellow
    Write-Host "建议先退出再装：它退出时会改写素材目录，可能把刚装好的片段覆盖掉。" -ForegroundColor Yellow
    $answer = Read-Host "仍然继续？输入 y 继续，其它任意键取消"
    if ($answer -ne 'y' -and $answer -ne 'Y') {
        Write-Host "已取消。" -ForegroundColor Yellow
        return
    }
}

# ---------------------------------------------------------------- 卸载

if ($Uninstall) {
    Write-Head "卸载"
    if (-not (Test-Path $targetDir)) {
        Write-Step "没有安装 $CharacterId，无需卸载。"
        return
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $removed = Join-Path $backupRoot "$CharacterId-removed-$stamp"
    if ($DryRun) {
        Write-Step "[DryRun] 会把 $targetDir 移到 $removed"
    } else {
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        Move-Item -Path $targetDir -Destination $removed
        Write-Step "已移走当前角色 → $removed"
    }

    $backup = Get-LatestBackup -BackupRoot $backupRoot
    if ($backup) {
        if ($DryRun) {
            Write-Step "[DryRun] 会还原备份：$($backup.FullName)"
        } else {
            Copy-Item -Path $backup.FullName -Destination $targetDir -Recurse -Force
            Write-Step "已还原备份：$($backup.Name)"
        }
    } else {
        Write-Step "没有更早的备份可还原，角色已从菜单里消失。"
    }
    Write-Host ""
    Write-Host "重启桌宠生效。备份都在：$backupRoot" -ForegroundColor Green
    return
}

# ---------------------------------------------------------------- 安装

Write-Head "复制素材"
$clipCount = @(Get-ChildItem (Join-Path $SourceDir 'videos') -Recurse -File -Filter '*.webm').Count
Write-Step ("源目录 {0} 段动画" -f $clipCount)

if ($DryRun) {
    Write-Step "[DryRun] 目标：$targetDir"
    if (Test-Path $targetDir) {
        Write-Step "[DryRun] 已存在同名角色，会先备份到 $backupRoot"
    }
    Write-Step "[DryRun] 完成。"
    return
}

if (Test-Path $targetDir) {
    $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = Join-Path $backupRoot "$CharacterId-$stamp"
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    Move-Item -Path $targetDir -Destination $backup
    Write-Step "已备份原角色 → $backup"
}

Copy-Item -Path $SourceDir -Destination $targetDir -Recurse -Force
$copied = @(Get-ChildItem (Join-Path $targetDir 'videos') -Recurse -File -Filter '*.webm').Count
Write-Step "已安装 $copied 段动画"

Write-Head "下一步"
Write-Step "1. 启动（或重启）桌宠"
Write-Step "2. 右键桌宠 → 角色 → $CharacterId"
Write-Step "3. 大小不合适就改「桌宠设置 → 缩放」"
Write-Host ""
Write-Host "卸载/还原：powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall" -ForegroundColor Green
