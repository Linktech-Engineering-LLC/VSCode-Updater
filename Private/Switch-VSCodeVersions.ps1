<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-06-14
    Modified: 2026-06-14
    File: Switch-VSCodeVersions.ps1
    Version: 1.0.0
    Description: Description goes here
#>

function Switch-VSCodeVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VersionName
    )

    $root = Join-Path $env:LOCALAPPDATA "Programs"
    $target = Join-Path $root $VersionName
    $linkPath = Join-Path $root "Microsoft VS Code"

    if (-not (Test-Path $target)) {
        Write-Log "[SWITCH] Version not found: $VersionName"
        return 80
    }

    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
    }

    Write-Log "[SWITCH] Linking '$linkPath' -> '$target'"
    New-Item -ItemType SymbolicLink -Path $linkPath -Target $target | Out-Null

    Write-Log "[SWITCH] Version switched successfully"
    return 0
}
