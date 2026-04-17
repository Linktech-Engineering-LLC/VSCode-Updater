<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-17
    File: Private/Watchdog-MonitorInstaller.ps1
    Version: 1.0.0
    Description: Monitors the VS Code installer and related worker processes for CPU and disk activity, detects idle or stalled states, and terminates processes when the installer becomes unresponsive.
#>
function Watchdog-MonitorInstaller {
    param(
        $ChildProcess,
        [int]$ParentPID,
        [int]$IdleTimeout
    )

    $idleSeconds    = 0
    $lastState      = ""
    $lastCPU        = 0
    $lastDisk       = 0
    $fsIdleSeconds  = 0
    $activeSeconds  = 0
    $installPath    = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
    $lastWriteTime  = (Get-Date)
    $fsLogCooldown  = 30   # seconds
    $lastFsLog      = (Get-Date).AddSeconds(-10)

    Write-Log "[WATCHDOG] Monitoring child PID $($ChildProcess.Id), parent PID $ParentPID"

    while ($true) {
        Start-Sleep -Seconds 2

        # Always re-query the child process — never trust the stale snapshot
        $child = Get-Process -Id $ChildProcess.Id -ErrorAction SilentlyContinue
        if (-not $child) {
            Write-Log "[WATCHDOG] Child exited — success"
            return "Success"
        }

        # Increment FS idle timer every loop
        $fsIdleSeconds += 2

		# Detect file system activity in the VS Code directory (exclude logs/temp)
		try {
			$latestWrite = Get-ChildItem -Recurse $installPath -File -ErrorAction SilentlyContinue |
				Where-Object {
					$_.Extension -notin '.log', '.tmp', '.bak' -and
					$_.FullName -notmatch '\\logs?\\' -and
					$_.FullName -notmatch '\\Crashpad\\' -and
					$_.FullName -notmatch '\\User Data\\' -and
					$_.FullName -notmatch '\\WebView2\\'
				} |
				Sort-Object LastWriteTime |
				Select-Object -Last 1

			if ($latestWrite -and $latestWrite.LastWriteTime -gt $lastWriteTime) {
				if ((Get-Date) -gt $lastFsLog.AddSeconds($fsLogCooldown)) {
					Write-Log "[WATCHDOG] FS activity (real installer file): $($latestWrite.Name)"
					$lastFsLog = Get-Date
				}

				$lastWriteTime = $latestWrite.LastWriteTime
				$fsIdleSeconds = 0
				$activeSeconds = 0
				$idleSeconds   = 0
			}
		}
		catch {
			# Directory may not exist yet — ignore
		}

        # Filesystem stall detection
        if ($fsIdleSeconds -ge $IdleTimeout) {
            Write-Log "[WATCHDOG] No filesystem activity for $IdleTimeout seconds — killing installer"
            Stop-Process -Id $ChildProcess.Id -Force -ErrorAction SilentlyContinue
            Stop-Process -Id $ParentPID     -Force -ErrorAction SilentlyContinue
            return "FS-Stalled"
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

                return "Idle-Stalled"
            }
        }
        else {
            # Detect transition to active
            if ($lastState -ne "Active") {
                Write-Log "[WATCHDOG] Child transitioned to active"
                $lastState = "Active"
            }

            # Detect stalled active state
            if ($cpu -eq $lastCPU -and $disk -eq $lastDisk) {
                $activeSeconds += 2

                if ($activeSeconds -ge $IdleTimeout) {
                    Write-Log "[WATCHDOG] Child is stalled in active state — killing parent PID $ParentPID and child PID $($ChildProcess.Id)"

                    Stop-Process -Id $ChildProcess.Id -Force -ErrorAction SilentlyContinue
                    Stop-Process -Id $ParentPID     -Force -ErrorAction SilentlyContinue

                    try {
                        Wait-Process -Id $ChildProcess.Id -Timeout 10 -ErrorAction SilentlyContinue
                    }
                    catch {
                        Write-Log "[WATCHDOG] Child did not exit within timeout — continuing anyway"
                    }

                    return "Active-Stalled"
                }
            }
            else {
                # Progress is being made
                $activeSeconds = 0
            }

            # Update last metrics
            $lastCPU  = $cpu
            $lastDisk = $disk

            # Reset idle counter
            $idleSeconds = 0
        }
    }
}
