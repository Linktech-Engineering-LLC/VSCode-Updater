<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: Start-VSCodeUpdaterGUI.Tests.ps1
    Version: 1.0.0
    Description: Description goes here
#>
# Load the module from the repo BEFORE entering InModuleScope

InModuleScope VSCode-Updater {

    Describe 'Get-SelectedVersionName' {

        It 'returns the selected version name from the DataGrid' {
            $grid = [pscustomobject]@{ SelectedItem = [pscustomobject]@{ Name = 'VSCode-1.92.0' } }

            $result = Get-SelectedVersionName -DataGrid $grid

            $result | Should -Be 'VSCode-1.92.0'
        }

        It 'returns null when nothing is selected' {
            $grid = [pscustomobject]@{ SelectedItem = $null }

            $result = Get-SelectedVersionName -DataGrid $grid

            $result | Should -BeNullOrEmpty
        }

        It 'returns Version when Name is missing' {
            $grid = [pscustomobject]@{ SelectedItem = [pscustomobject]@{ Version = 'VSCode-1.92.0' } }

            $result = Get-SelectedVersionName -DataGrid $grid

            $result | Should -Be 'VSCode-1.92.0'
        }
    }
}
