# Requires -Version 7.0
# Pester 5.x test for fallback deadlock detection in Update-VSCode

Describe "Update-VSCode Fallback Deadlock Handling" -Tag 'Update' {

    BeforeAll {
        # Import the function under test
        . "$PSScriptRoot/../../Public/Update-VSCode.ps1"

        # Stub Write-Log to avoid real output
        function Write-Log { param($m) }
    }

    Context "When no child worker is detected" {

        BeforeEach {
            # Fake parent process returned by Start-InstallerDetached
            $fakeParent = [pscustomobject]@{
                Id        = 9999
                StartTime = (Get-Date)
            }

            # Mock Start-InstallerDetached to always return the fake parent
            Mock -CommandName Start-InstallerDetached -MockWith { $fakeParent }

            # Mock Get-Process so NO child worker is ever detected
            Mock -CommandName Get-Process -MockWith {
                # Only return the parent process, never a child
                return @(
                    [pscustomobject]@{
                        Id           = 9999
                        StartTime    = $fakeParent.StartTime
                        ProcessName  = "Setup"
                        CPU          = 1
                        IOReadBytes  = 100
                        IOWriteBytes = 200
                    }
                )
            }

            # Track Stop-Process calls
            Mock -CommandName Stop-Process

            # Watchdog should NEVER be called in fallback mode
            Mock -CommandName Watchdog-MonitorInstaller
        }

        It "kills the parent and retries instead of using fallback" {

            # Run the updater with RetryCount=1 to force a single retry
            Update-VSCode -RetryCount 1 | Out-Null

            # Validate parent was killed
            Should -Invoke -CommandName Stop-Process -Times 1 -Exactly

            # Validate watchdog was NEVER invoked
            Should -Invoke -CommandName Watchdog-MonitorInstaller -Times 0
        }
    }
}
