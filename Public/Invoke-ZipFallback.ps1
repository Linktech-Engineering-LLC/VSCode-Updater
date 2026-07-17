<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-06-14
    Modified: 2026-06-14
    File: Private/Invoke-ZipFallback.ps1
    Version: 1.0.0
    Description: Retrieves the zipped VSCode package and installs it
#>
function Invoke-ZipFallback {
    [OutputType([Int32])]
    [CmdletBinding()]
    param(
        [string]$Reason = "Unknown"
    )

    if ($script:SafeMode) {
        _out "SAFE MODE — ZIP fallback skipped." "Yellow"
        return [WatchdogExitCode]::FallbackFailed
    }

    $script:LastUpdateResult = "Fallback"
    $script:LastFallbackReason = $Reason

    Write-VSCodeUpdaterLog "[FALLBACK] ZIP fallback triggered — Reason: $Reason"

    $cacheDir = Join-Path $PSScriptRoot "..\Cache"
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    }

    $zipUrl = "https://update.code.visualstudio.com/latest/win32-x64-archive/stable"
    $zipPath = Join-Path $cacheDir "VSCode.zip"

    Write-VSCodeUpdaterLog "[FALLBACK] Downloading ZIP archive"

    for ($i = 1; $i -le 3; $i++) {
        try {
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
            break
        }
        catch {
            Write-VSCodeUpdaterLog "[FALLBACK] Download attempt $i failed: $($_.Exception.Message)"
            Start-Sleep -Milliseconds 300
        }
    }

    if (-not (Test-Path $zipPath)) {
        Write-VSCodeUpdaterLog "[FALLBACK] ZIP download failed — no file present"
        return [WatchdogExitCode]::FallbackFailed
    }

    $info = Get-Item $zipPath -ErrorAction SilentlyContinue
    if ($info.Length -lt 1MB) {
        Write-VSCodeUpdaterLog "[FALLBACK] ZIP too small (<1MB) — invalid download"
        return [WatchdogExitCode]::FallbackFailed
    }

    $version = (Get-Date).ToString("yyyyMMddHHmmss")
    $targetDir = Join-Path $env:LOCALAPPDATA "Programs\VSCode-$version"

    Write-VSCodeUpdaterLog "[FALLBACK] Extracting ZIP to $targetDir"

    try {
        Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
    }
    catch {
        Write-VSCodeUpdaterLog "[FALLBACK] ZIP extraction failed: $($_.Exception.Message)"
        return [WatchdogExitCode]::FallbackFailed
    }

    $codeExe = Join-Path $targetDir "Code.exe"
    if (-not (Test-Path $codeExe)) {
        Write-VSCodeUpdaterLog "[FALLBACK] Extracted folder missing Code.exe — invalid fallback"
        return [WatchdogExitCode]::MissingCodeExe
    }

    $linkPath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"

    if (Test-Path $linkPath) {
        Write-VSCodeUpdaterLog "[FALLBACK] Removing existing VS Code directory/symlink"
        Remove-Item $linkPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }

    Write-VSCodeUpdaterLog "[FALLBACK] Creating junction to new version"

    try {
        cmd /c mklink /J "$linkPath" "$targetDir" | Out-Null
    }
    catch {
        Write-VSCodeUpdaterLog "[FALLBACK] Failed to create junction: $($_.Exception.Message)"
        return [WatchdogExitCode]::FallbackFailed
    }

    Update-VSCodeVersions -Keep 3 | Out-Null

    Write-VSCodeUpdaterLog "[FALLBACK] ZIP fallback completed successfully"
    return [WatchdogExitCode]::Success
}
