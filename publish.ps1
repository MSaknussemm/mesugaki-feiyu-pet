#Requires -Version 5.1
<#
.SYNOPSIS
    把本仓库推上 GitHub 并发一个 v1.0.0 Release。
.DESCRIPTION
    全程使用 GitHub 官方设备授权（浏览器点一下），不保存、不输入任何密码。
    第一次运行会依次完成：登录 → 建仓库 → push → 打 tag → 上传发布包。
.PARAMETER Repo
    GitHub 仓库名，默认 mesugaki-feiyu-pet。
.PARAMETER Zip
    要挂到 Release 的素材包路径。不填就自动找 ..\dist\*.zip。
.PARAMETER SkipRelease
    只推代码，不发 Release。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\publish.ps1
#>
[CmdletBinding()]
param(
    [string]$Repo = 'mesugaki-feiyu-pet',
    [string]$Zip,
    [switch]$SkipRelease
)

$ErrorActionPreference = 'Stop'
$Description = '雌小鬼肥鱼桌宠素材包：47 段 640×360 透明动画，用于 dsh-pet 桌宠换角色'

function Write-Step([string]$Text) { Write-Host "  $Text" }
function Write-Head([string]$Text) { Write-Host ""; Write-Host $Text -ForegroundColor Cyan }

# ---- 定位 gh / git（新装的程序可能还没进当前终端的 PATH）
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path', 'User')

$gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
if (-not $gh) {
    $fallback = 'C:\Program Files\GitHub CLI\gh.exe'
    if (Test-Path $fallback) { $gh = $fallback; $env:Path += ';C:\Program Files\GitHub CLI' }
    else { throw '找不到 gh。先装 GitHub CLI：winget install --id GitHub.cli -e' }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw '找不到 git。先装：winget install --id Git.Git -e（装完重开终端）'
}

Set-Location $PSScriptRoot

# ---- 1. 登录（设备授权，浏览器点一下）
Write-Head '1/5 检查 GitHub 登录状态'
& $gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Step '还没登录。接下来 gh 会打开浏览器并给一个一次性代码，'
    Write-Step '你在浏览器里输入代码、点 Authorize 就行 —— 不需要在这里敲密码。'
    & $gh auth login --hostname github.com --git-protocol https --web
    if ($LASTEXITCODE -ne 0) { throw '登录没有完成，脚本停止。' }
} else {
    $who = (& $gh api user --jq '.login' 2>$null)
    Write-Step "已登录：$who"
}

# ---- 2. 建仓库（已存在就跳过）
Write-Head '2/5 检查远程仓库'
& $gh repo view "$Repo" *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Step "仓库已存在：$Repo"
    $remotes = git remote
    if ($remotes -notcontains 'origin') {
        $owner = & $gh api user --jq '.login'
        git remote add origin "https://github.com/$owner/$Repo.git"
        Write-Step '已补上 origin'
    }
} else {
    Write-Step "创建并推送：$Repo（public）"
    & $gh repo create $Repo --public --source . --remote origin --push --description $Description
    if ($LASTEXITCODE -ne 0) { throw '创建仓库失败。' }
}

# ---- 3. push
Write-Head '3/5 推送代码'
git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host '  推送被拒，先同步远程再重试…' -ForegroundColor Yellow
    git pull --rebase origin main
    git push -u origin main
    if ($LASTEXITCODE -ne 0) { throw '推送失败，检查是否有冲突。' }
}

# ---- 4. tag
Write-Head '4/5 打标签 v1.0.0'
git rev-parse v1.0.0 *> $null
if ($LASTEXITCODE -ne 0) {
    git tag -a v1.0.0 -m 'v1.0.0 首次发布'
}
git push origin v1.0.0

if ($SkipRelease) {
    Write-Host ''
    Write-Host '已跳过 Release。' -ForegroundColor Green
    return
}

# ---- 5. Release
Write-Head '5/5 发布 v1.0.0'
if (-not $Zip) {
    $candidates = @(
        (Join-Path (Split-Path $PSScriptRoot -Parent) 'dist\*.zip'),
        (Join-Path $PSScriptRoot '*.zip')
    ) | ForEach-Object { Get-ChildItem $_ -ErrorAction SilentlyContinue }
    $Zip = ($candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
}
if (-not $Zip -or -not (Test-Path $Zip)) {
    Write-Host '  没找到 zip 附件，跳过 Release。' -ForegroundColor Yellow
    return
}
Write-Step ("附件：{0}（{1:N1} MB）" -f (Split-Path $Zip -Leaf), ((Get-Item $Zip).Length / 1MB))

$notes = @'
47 段 640×360 / 24 fps / VP9-alpha 透明动画，直接替换 dsh-pet 的角色。

- 分类：idle 6 / random 29 / click 8 / move 2 / turn 1 / drag 1
- 安装：解压后运行 `install.ps1`，或把 `characters/bluewhale_tv` 复制到 `<安装目录>\_internal\assets\characters\`
- 已知缺口：`events/` 为空，`turn/` 只有 1 段

素材许可：CC BY-NC-SA 4.0（署名 · 非商业 · 相同方式共享），脚本 MIT。
角色参考了社区「大肥鱼 / 鲸鱼娘」的人物设计语言，为独立角色。
'@

& $gh release view v1.0.0 *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Step 'Release 已存在，改为追加附件'
    & $gh release upload v1.0.0 $Zip --clobber
} else {
    & $gh release create v1.0.0 $Zip --title 'v1.0.0 · 雌小鬼肥鱼桌宠素材包' --notes $notes
}

Write-Host ''
Write-Host '完成。仓库地址：' -ForegroundColor Green
& $gh repo view $Repo --web 2>$null
