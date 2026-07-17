<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: Set-VSCodeSafeMode.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Set-VSCodeSafeMode {
    [CmdletBinding()]
    param([bool]$Enabled)

    $script:SafeMode = $Enabled

    if ($Enabled) {
        _out "[SAFE] SAFE MODE ENABLED" "Yellow"
        Write-VSCodeUpdaterLog "[SAFE] SAFE MODE ENABLED"
    }
    else {
        _out "[SAFE] SAFE MODE DISABLED" "Yellow"
        Write-VSCodeUpdaterLog "[SAFE] SAFE MODE DISABLED"
    }
}
