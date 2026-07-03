<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-02
    Modified: 2026-07-02
    File: Get-VSCodeSymlinkInfo.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Get-VSCodeSymlinkInfo {

    $root = Join-Path $env:LOCALAPPDATA "Programs"
    $symlinkPath = Join-Path $root "Microsoft VS Code"

    $info = [PSCustomObject]@{
        ActiveVersion       = $null
        TargetPath          = $null
        IsValid             = $false
        LastUpdateResult    = $script:LastUpdateResult
        LastFallbackReason  = $script:LastFallbackReason
    }

    if (-not (Test-Path $symlinkPath)) {
        return $info
    }

    try {
        $target = (Get-Item $symlinkPath).Target
        $info.TargetPath = $target

        if (Test-Path $target) {
            $info.IsValid = $true
        }

        $info.ActiveVersion = Split-Path $target -Leaf
    }
    catch {
        # leave defaults
    }

    return $info
}
