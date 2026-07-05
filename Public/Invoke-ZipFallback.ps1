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
    [CmdletBinding()]
    param(
        [string]$Reason = "Unknown"
    )

    if ($script:SafeMode) {
        _out "SAFE MODE — ZIP fallback skipped." "Yellow"
        return 0
    }

    # Record fallback state
    $script:LastUpdateResult   = "Fallback"
    $script:LastFallbackReason = $Reason

    Write-Log "[FALLBACK] ZIP fallback triggered — Reason: $Reason"

    # Cache directory
    $cacheDir = Join-Path $PSScriptRoot "..\Cache"
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    }

    # ZIP URL
    $zipUrl  = "https://update.code.visualstudio.com/latest/win32-x64-archive/stable"
    $zipPath = Join-Path $cacheDir "VSCode.zip"

    # Download with retry
    Write-Log "[FALLBACK] Downloading ZIP archive"
    for ($i = 1; $i -le 3; $i++) {
        try {
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
            break
        }
        catch {
            Write-Log "[FALLBACK] Download attempt $i failed: $($_.Exception.Message)"
            Start-Sleep -Milliseconds 300
        }
    }

    if (-not (Test-Path $zipPath)) {
        Write-Log "[FALLBACK] ZIP download failed — no file present"
        return 95
    }

    # Validate ZIP size
    $info = Get-Item $zipPath -ErrorAction SilentlyContinue
    if ($info.Length -lt 1MB) {
        Write-Log "[FALLBACK] ZIP too small (<1MB) — invalid download"
        return 96
    }

    # Extract
    $version   = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $targetDir = Join-Path $env:LOCALAPPDATA "Programs\VSCode-$version"

    Write-Log "[FALLBACK] Extracting ZIP to $targetDir"
    try {
        Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
    }
    catch {
        Write-Log "[FALLBACK] ZIP extraction failed: $($_.Exception.Message)"
        return 97
    }

    # Validate extracted folder
    $codeExe = Join-Path $targetDir "Code.exe"
    if (-not (Test-Path $codeExe)) {
        Write-Log "[FALLBACK] Extracted folder missing Code.exe — invalid fallback"
        return 98
    }

    # Symlink path
    $linkPath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"

    # Remove old symlink/junction
    if (Test-Path $linkPath) {
        Write-Log "[FALLBACK] Removing existing VS Code directory/symlink"
        Remove-Item $linkPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Create new junction
    Write-Log "[FALLBACK] Creating junction to new version"
    try {
        cmd /c mklink /J "$linkPath" "$targetDir" | Out-Null
    }
    catch {
        Write-Log "[FALLBACK] Failed to create junction: $($_.Exception.Message)"
        return 99
    }

    # Prune old versions
    Update-VSCodeVersions -Keep 3

    Write-Log "[FALLBACK] ZIP fallback completed successfully"
    return 0
}
