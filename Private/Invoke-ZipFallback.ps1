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

    Write-Log "[FALLBACK] ZIP fallback triggered — Reason: $Reason"
    
    # Ensure cache directory exists
    $cacheDir = Join-Path $PSScriptRoot "..\Cache"
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    }

    # 1. Determine latest version ZIP URL
    $zipUrl = "https://update.code.visualstudio.com/latest/win32-x64-archive/stable"

    # 2. Download ZIP to cache
    $zipPath = Join-Path $cacheDir "VSCode.zip"
    Write-Log "[FALLBACK] Downloading ZIP archive"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

    # 3. Extract to versioned folder
    $version = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $targetDir = Join-Path $env:LOCALAPPDATA "Programs\VSCode-$version"

    Write-Log "[FALLBACK] Extracting ZIP to $targetDir"
    Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force

    # 4. Replace broken install with symlink
    $linkPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"

    if (Test-Path $linkPath) {
        Write-Log "[FALLBACK] Removing existing VS Code directory/symlink"
        Remove-Item $linkPath -Recurse -Force
    }

    Write-Log "[FALLBACK] Creating symlink to new version"
    New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetDir | Out-Null

    # 5. Version retention cleanup
    Manage-VSCodeVersions -Keep 3

    Write-Log "[FALLBACK] ZIP fallback completed successfully"
    return 0
}
