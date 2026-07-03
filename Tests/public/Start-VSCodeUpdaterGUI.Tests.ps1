<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-03
    Modified: 2026-07-03
    File: Start-VSCodeUpdaterGUI.Tests.ps1
    Version: 1.0.0
    Description: Description goes here
#>

function Get-SelectedVersionName {
    param(
        [Parameter(Mandatory)]
        $DataGrid
    )

    if (-not $DataGrid.SelectedItem) {
        return $null
    }

    # Support both old and new property names
    if ($DataGrid.SelectedItem.PSObject.Properties.Match('Name')) {
        return $DataGrid.SelectedItem.Name
    }

    if ($DataGrid.SelectedItem.PSObject.Properties.Match('Version')) {
        return $DataGrid.SelectedItem.Version
    }

    return $null
}
