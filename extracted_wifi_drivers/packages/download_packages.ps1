#!/usr/bin/env powershell
$ErrorActionPreference = "Stop"

$Repos = @(
    "https://downloads.immortalwrt.org/snapshots/targets/airoha/an7581/packages",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/base",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/airoha",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/pon_drivers",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/packages",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/luci",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/routing"
)

$OutputDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$PackageListFile = Join-Path $OutputDir "full_package_list.txt"
$FailedLog = Join-Path $OutputDir "download_failed.txt"
$SuccessLog = Join-Path $OutputDir "download_success.txt"

$packages = Get-Content $PackageListFile | Where-Object { $_ -and !$_.StartsWith("#") }
Write-Host ("发现 $($packages.Count) 个包待下载") -ForegroundColor Cyan

$existing = Get-ChildItem $OutputDir -Filter "apk" | Where-Object { $_.Extension -eq ".apk" } | Select-Object -ExpandProperty Name
Write-Host ("已存在 $($existing.Count) 个 .apk 文件") -ForegroundColor Green

$toDownload = @()
foreach ($pkg in $packages) {
    $apkFile = "$pkg.apk"
    if ($existing -notcontains $apkFile) {
        $toDownload += $pkg
    }
}

Write-Host ("需要下载: $($toDownload.Count) 个包") -ForegroundColor Yellow

if ($toDownload.Count -eq 0) {
    Write-Host "所有包已下载完成！" -ForegroundColor Green
    return
}

$successCount = 0
$failed = @()

function Try-DownloadPackage {
    param($packageName)
    
    foreach ($repo in $Repos) {
        $urls = @(
            "$repo/$packageName.apk",
            "$repo/packages/$packageName.apk"
        )
        
        foreach ($url in $urls) {
            try {
                $localPath = Join-Path $OutputDir "$packageName.apk"
                $headers = @{}
                
                if (Test-Path $localPath) {
                    $downloaded = (Get-Item $localPath).Length
                    $headers['Range'] = "bytes=$downloaded-"
                } else {
                    $downloaded = 0
                }
                
                $response = Invoke-WebRequest -Uri $url -Headers $headers -TimeoutSec 30 -ErrorAction Stop
                
                if ($response.StatusCode -in 200, 206) {
                    $mode = if ($downloaded -gt 0) { "Append" } else { "Create" }
                    $stream = [System.IO.File]::Open($localPath, $mode)
                    $stream.Write($response.Content, 0, $response.Content.Length)
                    $stream.Close()
                    
                    $finalSize = (Get-Item $localPath).Length
                    $expected = $downloaded + $response.Content.Length
                    if ($expected -gt 0 -and $finalSize -ne $expected) {
                        Write-Warning ("  Size mismatch: $packageName ($finalSize/$expected)")
                    }
                    return $true, $url
                }
                elseif ($response.StatusCode -eq 416) {
                    return $true, $url
                }
            }
            catch { }
        }
    }
    return $false, $null
}

Write-Host "开始下载..." -ForegroundColor Cyan

foreach ($pkg in $toDownload) {
    $result = Try-DownloadPackage $pkg
    if ($result[0]) {
        $successCount++
        Write-Host ("OK [$successCount/$($toDownload.Count)] $pkg <- $($result[1])") -ForegroundColor Green
        "$pkg`t$($result[1])" | Out-File -FilePath $SuccessLog -Encoding UTF8 -Append
    } else {
        $failed += $pkg
        Write-Host ("FAILED: $pkg") -ForegroundColor Red
        $pkg | Out-File -FilePath $FailedLog -Encoding UTF8 -Append
    }
}

Write-Host ("============================================================")
Write-Host ("下载完成: 成功 $successCount, 失败 $($failed.Count)") -ForegroundColor Cyan
if ($failed.Count -gt 0) {
    Write-Host ("失败列表已保存至: $FailedLog") -ForegroundColor Yellow
    Write-Host ("失败的包可手动从软件源网页下载:") -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host ("  $_") }
}
Write-Host ("============================================================")