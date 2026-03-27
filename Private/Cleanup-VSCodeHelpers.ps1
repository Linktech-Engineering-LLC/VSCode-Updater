function Cleanup-VSCodeHelpers {
    Write-Log "[CLEANUP] Checking for VS Code helper processes"

    $helpers = Get-Process powershell -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Path -like '*CodeSetup*' -or
            $_.CommandLine -match 'CodeSetup' -or
            $_.CommandLine -match 'VSCodeSetup'
        }

    if ($helpers) {
        Write-Log "[CLEANUP] Terminating helper PIDs: $($helpers.Id -join ', ')"
        $helpers | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    $tmp = Get-Process -Name "VSCodeSetup.tmp" -ErrorAction SilentlyContinue
    if ($tmp) {
        Write-Log "[CLEANUP] Terminating VSCodeSetup.tmp PID: $($tmp.Id)"
        $tmp | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
