Describe "CleanCodePath" {
    BeforeAll {
        . "$PSScriptRoot/../../Private/CleanCodePath.ps1"
        . "$PSScriptRoot/../../Private/Write-Log.ps1"
    }

    It "skips when path does not exist" {
        Mock Test-Path { return $false }
        Mock Write-Log {}

        CleanCodePath -Path "C:\Fake"

        Assert-MockCalled Write-Log -Times 1 -ParameterFilter { $Message -match "skipping" }
    }

    It "removes lock files" {
        Mock Test-Path { return $true }
        Mock Get-ChildItem { return @( [pscustomobject]@{ Name="is-123.tmp"; FullName="C:\Fake\is-123.tmp" } ) }
        Mock Remove-Item {}
        Mock Write-Log {}

        CleanCodePath -Path "C:\Fake"

        Assert-MockCalled Remove-Item -Times 1
    }
}
