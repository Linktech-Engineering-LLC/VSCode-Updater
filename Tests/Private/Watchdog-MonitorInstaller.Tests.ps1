function Watchdog-MonitorInstaller {
    param(
        $ChildProcess,
        [int]$ParentPID,
        [int]$IdleTimeout
    )

    $idleSeconds = 0
    $lastState   = ""

    Write-Log "[WATCHDOG] Monitoring child PID $($ChildProcess.Id), parent PID $ParentPID"

    while ($true) {
        Start-Sleep -Seconds 2

        # Always re-query the child process — never trust the stale snapshot
        $child = Get-Process -Id $ChildProcess.Id -ErrorAction SilentlyContinue
        if (-not $child) {
            Write-Log "[WATCHDOG] Child exited — success"
            return "Success"
        }

        $cpu  = $child.CPU
        $disk = $child.IOReadBytes + $child.IOWriteBytes

        if ($cpu -eq 0 -and $disk -eq 0) {
            $idleSeconds += 2

            if ($lastState -ne "Idle") {
                Write-Log "[WATCHDOG] Child transitioned to idle"
                $lastState = "Idle"
            }

            Write-Log "[WATCHDOG] Idle for $idleSeconds seconds"

            if ($idleSeconds -ge $IdleTimeout) {
                Write-Log "[WATCHDOG] Idle threshold reached — killing parent PID $ParentPID"
                Stop-Process -Id $ParentPID -Force -ErrorAction SilentlyContinue

                Write-Log "[WATCHDOG] Waiting for child PID $($ChildProcess.Id) to exit"
                Wait-Process -Id $ChildProcess.Id -ErrorAction SilentlyContinue

                return "Success"
            }
        }
        else {
            if ($lastState -ne "Active") {
                Write-Log "[WATCHDOG] Child transitioned to active"
                $lastState = "Active"
            }
            $idleSeconds = 0
        }
    }
}
