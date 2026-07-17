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

    if ($script:SafeMode) {
        _out "SAFE MODE — Switch skipped." "Yellow"
        return 0
    }

    $root     = Join-Path $env:LOCALAPPDATA "Programs"
    $target   = Join-Path $root $VersionName
    $linkPath = Join-Path $root "Microsoft VS Code"

    # Validate target exists
    if (-not (Test-Path $target)) {
        Write-VSCodeUpdaterLog "[SWITCH] Version not found: $VersionName"
        return 80
    }

    # Validate target is a real VS Code install
    $codeExe     = Join-Path $target "Code.exe"
    $resources   = Join-Path $target "resources"
    $productJson = Join-Path $resources "app\product.json"

    if (-not (Test-Path $codeExe)) {
        Write-VSCodeUpdaterLog "[SWITCH] Target missing Code.exe: $target"
        return 81
    }
    if (-not (Test-Path $resources)) {
        Write-VSCodeUpdaterLog "[SWITCH] Target missing resources folder: $target"
        return 82
    }
    if (-not (Test-Path $productJson)) {
        Write-VSCodeUpdaterLog "[SWITCH] Target missing product.json: $target"
        return 83
    }

    # Skip locked folders
    try {
        $null = Get-ChildItem $target -ErrorAction Stop
    }
    catch {
        Write-VSCodeUpdaterLog "[SWITCH] Target folder is locked or inaccessible: $target"
        return 84
    }

    # Remove old symlink/junction
    if (Test-Path $linkPath) {
        Write-VSCodeUpdaterLog "[SWITCH] Removing existing symlink/junction"
        Remove-Item $linkPath -Force -ErrorAction SilentlyContinue
    }

    # Create new symlink
    Write-VSCodeUpdaterLog "[SWITCH] Linking '$linkPath' -> '$target'"
    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $target | Out-Null
    }
    catch {
        Write-VSCodeUpdaterLog "[SWITCH] Failed to create symlink: $($_.Exception.Message)"
        return 85
    }

    # Validate symlink
    $info = Get-VSCodeSymlinkInfo
    if (-not $info.IsValid) {
        Write-VSCodeUpdaterLog "[SWITCH] Symlink validation failed after switch"
        return 86
    }

    Write-VSCodeUpdaterLog "[SWITCH] Version switched successfully"
    return 0
}
