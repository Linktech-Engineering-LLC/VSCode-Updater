Describe "Write-Log" {

    BeforeAll {
        . "$PSScriptRoot/../../Private/Write-Log.ps1"
    }

    It "creates the log directory if missing" {
        Mock Test-Path { return $false }
        Mock New-Item {}
        Mock Add-Content {}

        Write-Log "Hello"

        Should -Invoke New-Item -Times 1
    }

    It "writes a timestamped message" {
        Mock Test-Path { return $true }
        Mock Add-Content {}

        Write-Log "Test message"

        Should -Invoke Add-Content -Times 1
    }
}
