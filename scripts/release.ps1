<#
.SYNOPSIS
    为作品集发布新版本：创建 tag/Release 并上传附件。

.DESCRIPTION
    每次发版使用一个新 tag（如 v1.1、v1.2），旧版本会保留在 Releases 中。
    大文件放在 Release 附件里，不进入 Git 历史，仓库体积始终保持很小。

.EXAMPLE
    $env:GITHUB_TOKEN = '<your pat>'
    .\scripts\release.ps1 -Tag v1.1 -File 'E:\unitystudy\报告.zip' -AssetName GGST-analysis-report.zip

.EXAMPLE
    .\scripts\release.ps1 -Tag v1.2 -File 'D:\out\report.zip' -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^v\d+\.\d+(\.\d+)?$')]
    [string]$Tag,

    [Parameter(Mandatory = $true)]
    [string]$File,

    [string]$AssetName,
    [string]$Title,
    [string]$Notes = '',
    [string]$Repo = 'menjunhao/portfolio',
    [string]$Token = $env:GITHUB_TOKEN,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if (-not $AssetName) { $AssetName = "$Tag.zip" }
if (-not $Title) { $Title = "作品集 $Tag" }

if (-not (Test-Path -LiteralPath $File)) { throw "文件不存在：$File" }

$item = Get-Item -LiteralPath $File
$sizeMb = [math]::Round($item.Length / 1MB, 1)
if ($item.Length -gt 2GB) { throw "附件 $sizeMb MB 超过 Release 单文件上限 2 GB" }
if ($AssetName -match '[^\x20-\x7E]') {
    throw "AssetName 只能使用 ASCII 字符，中文名会被 GitHub 重置为 default.zip"
}

if ($DryRun) {
    [pscustomobject]@{
        Repo      = $Repo
        Tag       = $Tag
        Title     = $Title
        File      = $item.FullName
        SizeMB    = $sizeMb
        AssetName = $AssetName
    } | Format-List
    return
}

if (-not $Token) {
    throw "缺少 token：先执行 `$env:GITHUB_TOKEN = '<PAT>'，或使用 -Token 参数。"
}

function Invoke-Curl {
    param([string[]]$Arguments)
    $out = & curl.exe @Arguments
    if ($LASTEXITCODE -ne 0) { throw "curl 执行失败（exit=$LASTEXITCODE）" }
    return $out
}

$payload = @{ tag_name = $Tag; name = $Title; body = $Notes; draft = $false; prerelease = $false } | ConvertTo-Json
$payloadFile = Join-Path $env:TEMP "gh-release-$Tag.json"
[IO.File]::WriteAllText($payloadFile, $payload, (New-Object Text.UTF8Encoding($false)))

Write-Host "创建 Release $Tag ..."
$resp = Invoke-Curl @(
    '-sS', '-X', 'POST', "https://api.github.com/repos/$Repo/releases",
    '-H', "Authorization: Bearer $Token",
    '-H', 'Accept: application/vnd.github+json',
    '-H', 'Content-Type: application/json; charset=utf-8',
    '--data-binary', "@$payloadFile",
    '-w', "`n%{http_code}"
)
$status = $resp[-1]
$release = ($resp[0..($resp.Count - 2)] -join "`n") | ConvertFrom-Json
if ($status -ne '201') {
    throw "创建 Release 失败（HTTP $status）：$($release.message)。tag $Tag 可能已存在，请换一个版本号。"
}

$encodedName = [uri]::EscapeDataString($AssetName)
$uploadUrl = "https://uploads.github.com/repos/$Repo/releases/$($release.id)/assets?name=$encodedName"

Write-Host "上传 $($item.Name)（$sizeMb MB）..."
$up = Invoke-Curl @(
    '-sS', '-X', 'POST', $uploadUrl,
    '-H', "Authorization: Bearer $Token",
    '-H', 'Accept: application/vnd.github+json',
    '-H', 'Content-Type: application/zip',
    '--data-binary', "@$($item.FullName)",
    '-w', "`n%{http_code}"
)
$upStatus = $up[-1]
$asset = ($up[0..($up.Count - 2)] -join "`n") | ConvertFrom-Json
if ($upStatus -ne '201') {
    throw "上传失败（HTTP $upStatus）：$($asset.message)"
}

$row = "| $Tag | [$AssetName]($($asset.browser_download_url)) | $sizeMb MB | $(Get-Date -Format 'yyyy-MM-dd') |"

Write-Host ""
Write-Host "发布完成：$($release.html_url)"
Write-Host "下载地址：$($asset.browser_download_url)"
Write-Host ""
Write-Host "把下面这行加进 README 的版本历史表格："
Write-Host $row