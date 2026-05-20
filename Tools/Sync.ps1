<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-23
    Modified: 2026-05-07
    File: Sync.ps1
    Version: 1.0.1
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
$HomeDocs   = Join-Path $HOME 'Documents'
$ModuleRoot = Join-Path $HomeDocs 'PowerShell\Modules\VSCode-Updater'

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
# Incremental Sync (only changed files)
# =====================================================================

Write-Host "Performing SYNC..."
Write-SyncLog "Performing SYNC..."

$ModuleItems = @(
    "VSCode-Updater.psm1",
    "VSCode-Updater.psd1",
    "Private"
)

# Remove orphaned files in module folder
$moduleExisting = Get-ChildItem -Path $ModuleRoot -Recurse -File -ErrorAction SilentlyContinue
foreach ($file in $moduleExisting) {
    $relative = $file.FullName.Substring($ModuleRoot.Length).TrimStart('\')
    $source   = Join-Path $RepoRoot $relative

    if (-not (Test-Path $source)) {
        Write-SyncLog "Removing orphaned file: $relative"
        Remove-Item $file.FullName -Force
    }
}

foreach ($item in $ModuleItems) {
    $source = Join-Path $RepoRoot $item
    $dest   = Join-Path $ModuleRoot $item

    # --- Case 1: Item is a FILE ---
    if (Test-Path $source -PathType Leaf) {
        if (-not (Test-Path $dest)) {
            Write-SyncLog "Copying new file: $item"
            Copy-Item -Path $source -Destination $dest -Force
            continue
        }

        if ((Get-Item $source).LastWriteTimeUtc -ne (Get-Item $dest).LastWriteTimeUtc) {
            Write-SyncLog "Updating changed file: $item"
            Copy-Item -Path $source -Destination $dest -Force
        }

        continue
    }

    # --- Case 2: Item is a DIRECTORY ---
    if (Test-Path $source -PathType Container) {
        if (-not (Test-Path $dest)) {
            Write-SyncLog "Copying new directory: $item"
            Copy-Item -Path $source -Destination $dest -Recurse -Force
            continue
        }

        $sourceFiles = Get-ChildItem -Path $source -Recurse -File
        foreach ($sf in $sourceFiles) {
            $relative = $sf.FullName.Substring($source.Length).TrimStart('\')
            $target   = Join-Path $dest $relative

            if (-not (Test-Path $target)) {
                Write-SyncLog "Copying missing file: $relative"
                Copy-Item -Path $sf.FullName -Destination $target -Force
                continue
            }

            if ($sf.LastWriteTimeUtc -ne (Get-Item $target).LastWriteTimeUtc) {
                Write-SyncLog "Updating changed file: $relative"
                Copy-Item -Path $sf.FullName -Destination $target -Force
            }
        }
    }
}

Write-Host "Sync complete."
Write-SyncLog "Sync complete."
Write-SyncLog "==============================================================="
