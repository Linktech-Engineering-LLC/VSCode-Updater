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

    $root        = Join-Path $env:LOCALAPPDATA "Programs"
    $symlinkPath = Join-Path $root "Microsoft VS Code"

    $info = [PSCustomObject]@{
        ActiveVersion       = $null
        TargetPath          = $null
        LinkType            = $null
        IsValid             = $false
        LastUpdateResult    = $script:LastUpdateResult
        LastFallbackReason  = $script:LastFallbackReason
    }

    if (-not (Test-Path $symlinkPath)) {
        Write-Log "[SYMLINK] Symlink missing: $symlinkPath"
        return $info
    }

    try {
        $item = Get-Item $symlinkPath -ErrorAction Stop
        $info.LinkType = $item.LinkType

        # Extract target for both symlink and junction
        $target = $item.Target
        $info.TargetPath = $target

        # Validate target
        if ($target -and (Test-Path $target)) {

            # Validate folder structure
            $codeExe = Join-Path $target "Code.exe"
            if (Test-Path $codeExe) {
                $info.IsValid = $true
                $info.ActiveVersion = Split-Path $target -Leaf
            }
            else {
                Write-Log "[SYMLINK] Target exists but missing Code.exe: $target"
            }
        }
        else {
            Write-Log "[SYMLINK] Target missing or invalid: $target"
        }
    }
    catch {
        Write-Log "[SYMLINK] Failed to read symlink: $($_.Exception.Message)"
    }

    return $info
}
