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

    $root = Join-Path $env:LOCALAPPDATA "Programs"
    $linkPath = Join-Path $root "Microsoft VS Code"

    $symlinkOK = Test-VSCodeSymlink
    $versions = Get-VSCodeVersions

    $currentTarget = $null
    if (Test-Path $linkPath) {
        $currentTarget = (Get-Item $linkPath).Target
    }

    $codeExe = Join-Path $linkPath "Code.exe"
    $launchOK = $false

    try {
        $p = Start-Process $codeExe -PassThru -ErrorAction Stop
        Start-Sleep -Milliseconds 800
        $launchOK = -not $p.HasExited
        if ($launchOK) { $p | Stop-Process -Force }
    }
    catch { }

    [PSCustomObject]@{
        SymlinkValid     = $symlinkOK
        CurrentTarget    = $currentTarget
        Launches         = $launchOK
        InstalledVersions = $versions.Name -join ", "
        VersionCount     = $versions.Count
        ActiveVersion    = Split-Path $currentTarget -Leaf
        CachePath        = Join-Path $PSScriptRoot "..\Cache"
        LastUpdateLog    = (Get-ChildItem "$env:TEMP" -Filter "VSCodeUpdater*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
    }
}
