<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: Get-SelectedVersionName.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Get-SelectedVersionName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$DataGrid
    )

    $item = $DataGrid.SelectedItem
    if (-not $item) { return $null }

    # Prefer Name (GUI standard)
    if ($item.PSObject.Properties.Name -contains 'Name') {
        return [string]$item.Name
    }

    # Fallback for older tests or alternate data sources
    if ($item.PSObject.Properties.Name -contains 'Version') {
        return [string]$item.Version
    }

    return $null
}
