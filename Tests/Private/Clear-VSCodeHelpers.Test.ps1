<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: Cleanup-VSCodeHelpers.Test.ps1
    Version: 1.0.0
    Description: Description goes here
#>

# Requires -Version 7.0
# Pester 5.x test for Cleanup-VSCodeHelpers

Describe "Clear-VSCodeHelpers" -Tag 'Private' {

    BeforeAll {
        . "$PSScriptRoot/../../Private/Clear-VSCodeHelpers.ps1"
        . "$PSScriptRoot/../../Private/Write-Log.ps1"
    }

    Context "When helper processes exist" {

        BeforeEach {
            Mock -CommandName Get-Process -MockWith {
                @(
                    [pscustomobject]@{ Name = "Code"; Id = 101 }
                    [pscustomobject]@{ Name = "CodeHelper"; Id = 102 }
                    [pscustomobject]@{ Name = "Setup"; Id = 103 }
                    [pscustomobject]@{ Name = "VSCodeSetup"; Id = 104 }
                )
            }

            Mock -CommandName Stop-Process
            Mock Write-Log {}
        }

        It "terminates all matching helper processes" {
            Cleanup-VSCodeHelpers
            Should -Invoke -CommandName Stop-Process -Times 4
        }
    }

    Context "When no helper processes exist" {

        BeforeEach {
            Mock -CommandName Get-Process -MockWith { @() }
            Mock -CommandName Stop-Process
            Mock Write-Log {}
        }

        It "does not attempt to terminate anything" {
            Cleanup-VSCodeHelpers
            Should -Invoke -CommandName Stop-Process -Times 0
        }
    }
}
