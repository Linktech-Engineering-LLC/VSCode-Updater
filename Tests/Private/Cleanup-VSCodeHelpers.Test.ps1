# Requires -Version 7.0
# Pester 5.x test for Cleanup-VSCodeHelpers

Describe "Cleanup-VSCodeHelpers" -Tag 'Private' {

    BeforeAll {
        # Import the function under test
        . "$PSScriptRoot/../../Private/Cleanup-VSCodeHelpers.ps1"
        . "$PSScriptRoot/../../Private/Write-Log.ps1"

    }

    Context "When helper processes exist" {

        BeforeEach {
            # Mock Get-Process to simulate running processes
            Mock -CommandName Get-Process -MockWith {
                @(
                    [pscustomobject]@{ Name = "Code"; Id = 101 }
                    [pscustomobject]@{ Name = "CodeHelper"; Id = 102 }
                    [pscustomobject]@{ Name = "Setup"; Id = 103 }
                    [pscustomobject]@{ Name = "VSCodeSetup"; Id = 104 }
                )
            }

            # Mock Stop-Process to track calls
            Mock -CommandName Stop-Process
        }

        It "terminates all matching helper processes" {
            Cleanup-VSCodeHelpers

            # Validate Stop-Process was called for each PID
            Should -Invoke -CommandName Stop-Process -Times 4
        }
    }

    Context "When no helper processes exist" {

        BeforeEach {
            Mock -CommandName Get-Process -MockWith { @() }
            Mock -CommandName Stop-Process
        }

        It "does not attempt to terminate anything" {
            Cleanup-VSCodeHelpers

            Should -Invoke -CommandName Stop-Process -Times 0
        }
    }
}
