<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: Get-VSCodeLastResult.ps1
    Version: 1.0.0
    Description: Description goes here
#>

function Get-VSCodeLastResult {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        LastUpdateResult   = $script:LastUpdateResult
        LastFallbackReason = $script:LastFallbackReason
    }
}
