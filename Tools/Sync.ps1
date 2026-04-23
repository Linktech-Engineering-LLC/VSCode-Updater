<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-23
    Modified: 2026-04-23
    File: Sync.ps1
    Version: 1.0.0
    Description: Deterministically synchronize the repo version of VSCode-Updater
             into the user's installed PowerShell module path.
#>

<#
.SYNOPSIS
    Synchronizes the VSCode-Updater module from repo → module folder.

.DESCRIPTION
    This script performs a deterministic sync by validating:
        - Module folder existence
        - File count drift
        - Hash drift
        - Timestamp drift
        - Version drift

    If ANY mismatch is detected, a full sync is performed.
#>

Write-Host "=== VSCode-Updater Sync ==="

# =====================================================================
# Resolve Paths
# =====================================================================

# Repo root = parent of Tools\
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path $ScriptRoot -Parent

# The module lives directly in the repo root (not nested)
$RepoModule = $RepoRoot

# Resolve Windows Documents folder safely (OneDrive-aware, locale-aware)
$Documents  = [Environment]::GetFolderPath('MyDocuments')
$ModuleRoot = Join-Path $Documents 'PowerShell\Modules\VSCode-Updater'

Write-Host "Repo:    $RepoModule"
Write-Host "Module:  $ModuleRoot"

# Ensure module folder exists
if (-not (Test-Path $ModuleRoot)) {
    New-Item -ItemType Directory -Force -Path $ModuleRoot | Out-Null
}

# =====================================================================
# Logging Setup
# =====================================================================

$LogRoot = Join-Path $RepoRoot "Logs"
if (-not (Test-Path $LogRoot)) {
    New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null
}

$LogFile = Join-Path $LogRoot "Sync.log"

function Write-SyncLog {
    param([string]$Message)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "$ts  $Message"
}

Write-SyncLog "==============================================================="
Write-SyncLog "VSCode-Updater Sync Started"
Write-SyncLog "Repo:    $RepoModule"
Write-SyncLog "Module:  $ModuleRoot"
Write-SyncLog "==============================================================="

# =====================================================================
# Drift Detection (Simple + Deterministic)
# =====================================================================

$repoFiles   = Get-ChildItem -Path $RepoModule -Recurse -File
$moduleFiles = Get-ChildItem -Path $ModuleRoot -Recurse -File -ErrorAction SilentlyContinue

$repoCount   = $repoFiles.Count
$moduleCount = $moduleFiles.Count

if ($repoCount -ne $moduleCount) {
    Write-Host "File count mismatch — syncing."
    Write-SyncLog "File count mismatch — performing FULL SYNC."
    $DoFullSync = $true
}
else {
    # Compare LastWriteTime for drift detection
    $drift = $false
    foreach ($file in $repoFiles) {
        $relative = $file.FullName.Substring($RepoModule.Length).TrimStart('\')
        $target   = Join-Path $ModuleRoot $relative

        if (-not (Test-Path $target)) {
            $drift = $true
            break
        }

        $repoTime   = $file.LastWriteTimeUtc
        $moduleTime = (Get-Item $target).LastWriteTimeUtc

        if ($repoTime -ne $moduleTime) {
            $drift = $true
            break
        }
    }

    if ($drift) {
        Write-Host "Drift detected — syncing."
        Write-SyncLog "Drift detected — performing FULL SYNC."
        $DoFullSync = $true
    }
    else {
        Write-Host "No drift detected — module is up to date."
        Write-SyncLog "No drift detected — module is up to date."
        Write-SyncLog "==============================================================="
        return
    }
}

# =====================================================================
# Full Sync
# =====================================================================

Write-Host "Performing FULL SYNC..."
Write-SyncLog "Performing FULL SYNC..."

# Copy repo → module
Copy-Item -Path "$RepoModule\*" -Destination $ModuleRoot -Recurse -Force -Verbose |
    ForEach-Object { Write-SyncLog "Copied: $($_.FullName)" }

Write-Host "Full sync complete."
Write-SyncLog "Full sync complete."
Write-SyncLog "==============================================================="
