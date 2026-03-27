function Cleanup-InnoSetupWorkers {
    Write-Log "[CLEANUP] Checking for InnoSetup workers"

    $workers = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -like "$env:TEMP\is-*.tmp" }

    if ($workers) {
        Write-Log "[CLEANUP] Terminating InnoSetup worker PIDs: $($workers.Id -join ', ')"
        $workers | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
