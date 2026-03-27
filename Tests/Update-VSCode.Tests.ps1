Describe "Update-VSCode" {

    BeforeAll {
        # Load the module under test
        Import-Module "$PSScriptRoot/../VSCode-Updater.psd1" -Force

        # Load ALL private functions so mocks work
        Get-ChildItem "$PSScriptRoot/../Private" -Filter *.ps1 |
            ForEach-Object { . $_.FullName }
    }

    It "returns 20 when SkipUpdate is used" {
        # Prevent Write-Log from doing real work
        Mock Write-Log { } -ParameterFilter { $Message }

        $result = Update-VSCode -SkipUpdate
        $result | Should -Be 20
    }

    It "fails gracefully when download fails" {

        Mock Invoke-WebRequest { throw "Network error" } -ModuleName VSCode-Updater
        Mock Write-Log { } -ParameterFilter { $Message } -ModuleName VSCode-Updater

        Mock Watchdog-MonitorInstaller { return "Success" } -ModuleName VSCode-Updater
        Mock Start-InstallerDetached { return $true } -ModuleName VSCode-Updater
        Mock Cleanup-SetupBootstrapper { } -ModuleName VSCode-Updater
        Mock Cleanup-VSCodeHelpers { } -ModuleName VSCode-Updater
        Mock Cleanup-InnoSetupWorkers { } -ModuleName VSCode-Updater
        Mock CleanCodePath { } -ModuleName VSCode-Updater
        Mock Get-FileHashSafe { return "ABC123" } -ModuleName VSCode-Updater

        $result = Update-VSCode
        $result | Should -Be 10
    }
}
