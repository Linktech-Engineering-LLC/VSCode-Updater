<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: Update-VSCodeVersions.ps1
    Version: 1.0.0
    Description: Description goes here
#>

function Update-VSCodeVersions {
    [CmdletBinding()]
    param(
        [int]$Keep = 3
    )

    $root = Join-Path $env:LOCALAPPDATA "Programs"
    $prefix = "VSCode-"
    $linkPath = Join-Path $root "Microsoft VS Code"

    # Determine active version (symlink target)
    $active = $null
    if (Test-Path $linkPath) {
        try {
            $active = (Get-Item $linkPath).Target | Resolve-Path
        }
        catch {
            Write-Log "[CLEANUP] Warning: Failed to resolve active symlink"
        }
    }

    $versions = Get-ChildItem $root -Directory |
        Where-Object { $_.Name -like "$prefix*" } |
        Sort-Object Name -Descending

    if ($versions.Count -le $Keep) {
        Write-Log "[CLEANUP] No old versions to remove"
        return 0
    }

    $toDelete = $versions | Select-Object -Skip $Keep
    $removed = 0

    foreach ($dir in $toDelete) {

        # Skip active version
        if ($active -and ($dir.FullName -eq $active)) {
            Write-Log "[CLEANUP] Skipping active version: $($dir.FullName)"
            continue
        }

        # Skip locked folders
        try {
            $null = Get-ChildItem $dir.FullName -ErrorAction Stop
        }
        catch {
            Write-Log "[CLEANUP] Folder locked or inaccessible: $($dir.FullName)"
            continue
        }

        Write-Log "[CLEANUP] Removing old VS Code version: $($dir.FullName)"

        try {
            Remove-Item $dir.FullName -Recurse -Force -ErrorAction Stop
            $removed++
        }
        catch {
            Write-Log "[CLEANUP] Failed to remove $($dir.FullName): $($_.Exception.Message)"
        }
    }

    Write-Log "[CLEANUP] Removed $removed old version(s)"
    return $null
}
