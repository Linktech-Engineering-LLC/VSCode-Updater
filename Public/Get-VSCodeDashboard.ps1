<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-06-14
    Modified: 2026-06-14
    File: Get-VSCodeDashboard.ps1
    Version: 1.0.0
    Description: Description goes here
#>

function Get-VSCodeDashboard {
    [CmdletBinding()]
    param()

    $root     = Join-Path $env:LOCALAPPDATA "Programs"
    $linkPath = Join-Path $root "Microsoft VS Code"

    # Symlink info (more reliable than .Target)
    $info        = Get-VSCodeSymlinkInfo
    $symlinkOK   = $info.IsValid
    $currentTarget = $info.Target

    # Installed versions
    $versions = Get-VSCodeVersions

    # Launch test (Safe Mode aware)
    $launchOK = $false
    $codeExe  = Join-Path $linkPath "Code.exe"

    if (-not $script:SafeMode -and (Test-Path $codeExe)) {
        try {
            $p = Start-Process $codeExe -PassThru -ErrorAction Stop
            Start-Sleep -Milliseconds 1200
            $launchOK = -not $p.HasExited
            if ($launchOK) { $p | Stop-Process -Force }
        }
        catch { }
    }

    # Cache path (safe resolution)
    $cachePath = $null
    try {
        $cachePath = (Resolve-Path (Join-Path $PSScriptRoot "..\Cache")).Path
    }
    catch { }

    # Last update log
    $lastLog = Get-ChildItem "$env:TEMP" -Filter "VSCodeUpdater*.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    [PSCustomObject]@{
        SymlinkValid      = $symlinkOK
        LinkType          = $info.LinkType
        CurrentTarget     = $currentTarget
        Launches          = $launchOK
        InstalledVersions = $versions.Name
        VersionCount      = $versions.Count
        ActiveVersion     = if ($currentTarget) { Split-Path $currentTarget -Leaf } else { $null }
        CachePath         = $cachePath
        LastUpdateLog     = if ($lastLog) { $lastLog.FullName } else { $null }
    }
}
