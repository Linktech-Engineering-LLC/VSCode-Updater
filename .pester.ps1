# .pester.ps1
@{
    Run = @{
        Path = 'Tests'
    }
    ScriptBlock = {
        # Import module BEFORE discovery
        $modulePath = Join-Path $PSScriptRoot "VSCode-Updater.psd1"
        Import-Module $modulePath -Force
    }
}
