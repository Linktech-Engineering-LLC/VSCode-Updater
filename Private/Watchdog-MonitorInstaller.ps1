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
	if ($ParentPID -eq 0 -or -not (Get-Process -Id $ParentPID -ErrorAction SilentlyContinue)) {
		Write-Log "[WATCHDOG] Invalid parent PID ($ParentPID) — aborting watchdog"
		return 0
	}

    if ($script:SafeMode) {
        Write-Log "[WATCHDOG] SAFE MODE — watchdog disabled"
        return 0
    }

    $idleSeconds    = 0
    $activeSeconds  = 0
    $fsIdleSeconds  = 0
    $lastState      = ""
    $lastCPU        = 0
    $lastDisk       = 0
    $installPath    = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
    $lastWriteTime  = (Get-Date)
    $fsLogCooldown  = 30
    $lastFsLog      = (Get-Date).AddSeconds(-10)

    Write-Log "[WATCHDOG] Monitoring child PID $($ChildProcess.Id), parent PID $ParentPID"

    while ($true) {
        Start-Sleep -Seconds 2

        # Re-query child
        $child = Get-Process -Id $ChildProcess.Id -ErrorAction SilentlyContinue

        # Detect child replacement
        if (-not $child) {
            $newChild = Get-Process -ErrorAction SilentlyContinue |
                Where-Object { $_.Parent.Id -eq $ParentPID }

            if ($newChild) {
                Write-Log "[WATCHDOG] Child replaced — new PID $($newChild.Id)"
                $ChildProcess = $newChild
                continue
            }

            Write-Log "[WATCHDOG] Child exited — success"
            return 0
        }

        # FS idle timer
        $fsIdleSeconds += 2

        # Detect real installer writes
        try {
            $latestWrite = Get-ChildItem -Recurse $installPath -File -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Extension -notin '.log', '.tmp', '.bak' -and
                    $_.FullName -notmatch '\\logs?\\' -and
                    $_.FullName -notmatch '\\Crashpad\\'
                } |
                Sort-Object LastWriteTime |
                Select-Object -Last 1

            if ($latestWrite -and $latestWrite.LastWriteTime -gt $lastWriteTime) {
                if ((Get-Date) -gt $lastFsLog.AddSeconds($fsLogCooldown)) {
                    Write-Log "[WATCHDOG] FS activity: $($latestWrite.Name)"
                    $lastFsLog = Get-Date
                }

                $lastWriteTime = $latestWrite.LastWriteTime
                $fsIdleSeconds = 0
                $activeSeconds = 0
                $idleSeconds   = 0
            }
        }
        catch {}

        # FS stall
        if ($fsIdleSeconds -ge $IdleTimeout) {
            Write-Log "[WATCHDOG] FS stall — killing installer"
            Stop-Process -Id $ChildProcess.Id -Force -ErrorAction SilentlyContinue
            Stop-Process -Id $ParentPID     -Force -ErrorAction SilentlyContinue
            return 93
        }

        # CPU/disk delta
        $cpuNow  = $child.CPU
        $diskNow = $child.IOReadBytes + $child.IOWriteBytes

        $cpuDelta  = $cpuNow  - $lastCPU
        $diskDelta = $diskNow - $lastDisk

        $lastCPU  = $cpuNow
        $lastDisk = $diskNow

        # Idle
        if ($cpuDelta -eq 0 -and $diskDelta -eq 0) {
            $idleSeconds += 2

            if ($lastState -ne "Idle") {
                Write-Log "[WATCHDOG] Child transitioned to idle"
                $lastState = "Idle"
            }

            if ($idleSeconds -ge $IdleTimeout) {
                Write-Log "[WATCHDOG] Idle stall — killing parent"
                Stop-Process -Id $ParentPID -Force -ErrorAction SilentlyContinue
                Wait-Process -Id $ChildProcess.Id -ErrorAction SilentlyContinue
                return 91
            }

            continue
        }

        # Active
        if ($lastState -ne "Active") {
            Write-Log "[WATCHDOG] Child transitioned to active"
            $lastState = "Active"
        }

        # Active stall
        if ($cpuDelta -eq 0 -and $diskDelta -eq 0) {
            $activeSeconds += 2

            if ($activeSeconds -ge $IdleTimeout) {
                Write-Log "[WATCHDOG] Active stall — killing parent and child"
                Stop-Process -Id $ChildProcess.Id -Force -ErrorAction SilentlyContinue
                Stop-Process -Id $ParentPID     -Force -ErrorAction SilentlyContinue
                return 92
            }
        }
        else {
            $activeSeconds = 0
        }

        # Reset idle counter
        $idleSeconds = 0
    }
}
