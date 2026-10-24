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
        Write-VSCodeUpdaterLog "[SYMLINK] Symlink missing: $symlinkPath"
        return $info
    }

    $logFile = "C:\Logs\Update-Code.log"

    if (Test-Path $logFile)
    {
        $log = Get-Content $logFile -Tail 500

        if ([string]::IsNullOrWhiteSpace($script:LastUpdateResult))
        {
            $lastUpdate = $log |
                Select-String "completed successfully" |
                Select-Object -Last 1

            if ($lastUpdate)
            {
                $info.LastUpdateResult = ($lastUpdate.Line -replace '^\S+\s+\S+\s+\[FALLBACK\]\s*','')
            }
        }
        else
        {
            $info.LastUpdateResult = $script:LastUpdateResult
        }

        if ([string]::IsNullOrWhiteSpace($script:LastFallbackReason))
        {
            $fallback = $log |
                Select-String "Reason:" |
                Select-Object -Last 1

            if ($fallback)
            {
                $info.LastFallbackReason = ($fallback.Line -replace '.*Reason:\s*','')
            }
        }
        else
        {
            $info.LastFallbackReason = $script:LastFallbackReason
        }
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
                Write-VSCodeUpdaterLog "[SYMLINK] Target exists but missing Code.exe: $target"
            }
        }
        else {
            Write-VSCodeUpdaterLog "[SYMLINK] Target missing or invalid: $target"
        }
    }
    catch {
        Write-VSCodeUpdaterLog "[SYMLINK] Failed to read symlink: $($_.Exception.Message)"
    }

    return $info
}
