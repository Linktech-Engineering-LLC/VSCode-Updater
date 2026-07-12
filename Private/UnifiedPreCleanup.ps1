<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-11
    Modified: 2026-07-11
    File: Private/UnifiedPreCleanup.ps1
    Version: 1.0.0
    Description: Description goes here
#>


function Invoke-VSUPreCleanup {

    param(
        [string]$InstallRoot
    )

    Write-Log "[PRE] Starting unified pre‑installation cleanup"

    # =====================================================================
    # 1. Kill ALL VS Code processes
    # =====================================================================

    $vsProcesses = @(
        "Code",
        "Code - Insiders",
        "CodeHelper",
        "CodeHelper.exe",
        "CodeHelper64",
        "CodeHelper32"
    )

    foreach ($p in $vsProcesses) {
        Get-Process -Name $p -ErrorAction SilentlyContinue |
            ForEach-Object {
                Write-Log "[PRE] Killing VS Code process: $($_.Name) (PID=$($_.Id))"
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
    }

    # =====================================================================
    # 2. Kill ALL installer/bootstrapper/worker processes
    # =====================================================================

    $installerProcesses = @(
        "VSCodeSetup",
        "CodeSetup",
        "setup",
        "is-",
        "innosetup"
    )

    foreach ($p in $installerProcesses) {
        Get-Process -Name $p -ErrorAction SilentlyContinue |
            ForEach-Object {
                Write-Log "[PRE] Killing installer/bootstrapper: $($_.Name) (PID=$($_.Id))"
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
    }

    # =====================================================================
    # 3. Remove symlink if it exists
    # =====================================================================

    $symlinkPath = Join-Path $InstallRoot "VSCode"

    if (Test-Path $symlinkPath) {
        $item = Get-Item $symlinkPath -Force

        if ($item.Attributes -match "ReparsePoint") {
            Write-Log "[PRE] Removing VSCode junction: $symlinkPath"
            Remove-Item $symlinkPath -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Log "[PRE] VSCode path exists but is not a junction — removing"
            Remove-Item $symlinkPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # =====================================================================
    # 4. Prune old installation folders (keep newest two)
    # =====================================================================

    Write-Log "[PRE] Pruning old installation folders"

    $patternOld = '^VSCode-\d{8}-\d{6}$'
    $patternNew = '^VSCode-\d{14}$'

    $folders = Get-ChildItem $InstallRoot -Directory |
        Where-Object {
            $_.Name -match $patternOld -or
            $_.Name -match $patternNew
        } |
        Sort-Object Name -Descending

    if ($folders.Count -gt 2) {
        $toDelete = $folders | Select-Object -Skip 2
        foreach ($f in $toDelete) {
            Write-Log "[PRE] Removing old version folder: $($f.FullName)"
            Remove-Item $f.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # =====================================================================
    # 5. Remove debris (staging, partial installs, temp folders)
    # =====================================================================

    Write-Log "[PRE] Removing debris"

    $debrisPatterns = @(
        "new_*",
        "tmp_*",
        "partial_*",
        "is-*.tmp",
        "is-*.bin",
        "innosetup.tmp"
    )

    foreach ($pattern in $debrisPatterns) {
        Get-ChildItem $InstallRoot -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object {
                Write-Log "[PRE] Removing debris: $($_.FullName)"
                Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
    }

    # =====================================================================
    # 6. Clean installation path (your existing function)
    # =====================================================================

    Write-Log "[PRE] Cleaning installation path"
    CleanCodePath | Out-Null

    # =====================================================================
    # 7. Validate environment
    # =====================================================================

    Write-Log "[PRE] Validating installer environment"
    Test-InstallerEnvironment | Out-Null

    # =====================================================================
    # 8. Freeze remediation (optional)
    # =====================================================================

    if ($script:VSU_SafeInstallerMode) {
        Write-Log "[PRE] Safe installer mode enabled — applying freeze remediation"
        Invoke-InstallerFreezeRemediation | Out-Null
    }
    else {
        Write-Log "[PRE] Safe installer mode disabled — skipping freeze remediation"
    }

    Write-Log "[PRE] Unified pre‑installation cleanup complete"
}
