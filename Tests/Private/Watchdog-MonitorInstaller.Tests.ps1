Describe "Watchdog-MonitorInstaller" {
    BeforeAll {
        . "$PSScriptRoot/../../Private/Watchdog-MonitorInstaller.ps1"
        . "$PSScriptRoot/../../Private/Write-Log.ps1"
    }

    It "returns Success when child exits immediately" {
        $fake = [pscustomobject]@{
            Id = 1234
            HasExited = $true
        }

        $result = Watchdog-MonitorInstaller -ChildProcess $fake -ParentPID 999 -IdleTimeout 10
        $result | Should -Be "Success"
    }
}
