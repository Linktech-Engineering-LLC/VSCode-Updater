<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-06
    Modified: 2026-07-06
    File: Set-VSCodeSafeInstallerMode.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Set-VSCodeSafeInstallerMode {
    [CmdletBinding()]
    param(
        [bool]$Enabled
    )

    $script:VSU_SafeInstallerMode = $Enabled
    Write-Log "[CONFIG] Safe installer mode set to: $Enabled"
}
Export-ModuleMember -Function Set-VSCodeSafeInstallerMode
