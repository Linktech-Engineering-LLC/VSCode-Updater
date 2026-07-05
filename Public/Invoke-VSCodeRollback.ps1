<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: Invoke-VSCodeRollback.ps1
    Version: 1.0.0
    Description: Description goes here
#>

function Invoke-VSCodeRollback {
    [CmdletBinding()]
    param()

    if ($script:SafeMode) {
        _out "SAFE MODE — Rollback skipped." "Yellow"
        return 0
    }

    $root     = Join-Path $env:LOCALAPPDATA "Programs"
    $linkPath = Join-Path $root "Microsoft VS Code"

    # Hardened version list
    $versions = Get-VSCodeVersions | Where-Object { $_.IsValid } |
        Sort-Object VersionName -Descending

    if ($versions.Count -lt 2) {
        Write-Log "[ROLLBACK] Not enough valid versions to roll back"
        return 90
    }

    # Hardened symlink info
    $info = Get-VSCodeSymlinkInfo
    $currentTarget = $info.TargetPath
    $activeVersion = $info.ActiveVersion

    Write-Log "[ROLLBACK] Active version: $activeVersion"
    Write-Log "[ROLLBACK] Target path: $currentTarget"

    # Find active version in list
    $currentIndex = $versions.VersionName.IndexOf($activeVersion)
    if ($currentIndex -lt 0) {
        Write-Log "[ROLLBACK] Active version not found in version list — using newest"
        $currentIndex = 0
    }

    # Determine previous version
    $previousIndex = $currentIndex + 1
    if ($previousIndex -ge $versions.Count) {
        Write-Log "[ROLLBACK] No previous version found"
        return 91
    }

    $previous = $versions[$previousIndex].Path
    Write-Log "[ROLLBACK] Rolling back to: $previous"

    # Validate previous version
    if (-not (Test-Path $previous)) {
        Write-Log "[ROLLBACK] Previous version missing"
        return 92
    }

    # Skip locked folders
    try {
        $null = Get-ChildItem $previous -ErrorAction Stop
    }
    catch {
        Write-Log "[ROLLBACK] Previous version folder is locked or inaccessible"
        return 93
    }

    # Remove old symlink/junction
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force -ErrorAction SilentlyContinue
    }

    # Create new symlink
    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $previous | Out-Null
    }
    catch {
        Write-Log "[ROLLBACK] Failed to create symlink: $($_.Exception.Message)"
        return 94
    }

    Write-Log "[ROLLBACK] Rollback complete"
    return 0
}
