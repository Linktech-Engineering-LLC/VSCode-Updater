<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-07-17
    File: Private/Invoke-InstallerWatchdog.ps1
    Version: 1.1.0
    Description: Monitors the VS Code installer and related worker processes for CPU and disk activity,
                 detects idle or stalled states, and terminates processes when the installer becomes
                 unresponsive. Uses real-time loop deltas and basic invariants for stability.
#>
# PSScriptAnalyzer SuppressMessage = PSUseApprovedVerbs "Intentional verb"
function Invoke-InstallerWatchdog {
    [OutputType([Int32])]
    param(
        $ChildProcess,
        [int]$ParentPID,
        [int]$IdleTimeout
    )

    if ($ParentPID -eq 0 -or -not (Get-Process -Id $ParentPID -ErrorAction SilentlyContinue)) {
        Write-VSCodeUpdaterLog "[WATCHDOG] Invalid parent PID ($ParentPID) — aborting watchdog"
        return [WatchdogExitCode]::Unknown
    }

    if ($script:SafeMode) {
        Write-VSCodeUpdaterLog "[WATCHDOG] SAFE MODE — watchdog disabled"
        return [WatchdogExitCode]::Success
    }

    $idleSeconds = 0.0
    $activeSeconds = 0.0
    $fsIdleSeconds = 0.0
    $lastState = ""
    $lastCPU = 0.0
    $lastDisk = 0

    # Detect real VS Code install path from the 'code' command
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue

    $installPaths = @()

    if ($codeCmd -and $codeCmd.Source) {
        $installPaths += (Split-Path $codeCmd.Source -Parent)
    }

    # Fallbacks
    $installPaths += @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code",
        "$env:LOCALAPPDATA\Programs\VSCode",
        $env:TEMP
    )

    $lastWriteTime = Get-Date
    $fsLogCooldown = 30
    $lastFsLog = (Get-Date).AddSeconds(-10)

    $lastLoopTime = Get-Date

    Write-VSCodeUpdaterLog "[WATCHDOG] Monitoring child PID $($ChildProcess.Id), parent PID $ParentPID"

    # Grace period: let installer initialize
    Start-Sleep -Seconds 3
    $fsIdleSeconds = 0.0
    $idleSeconds = 0.0
    $activeSeconds = 0.0

    while ($true) {
        $now = Get-Date
        $delta = ($now - $lastLoopTime).TotalSeconds
        if ($delta -lt 0) { $delta = 0 }
        $lastLoopTime = $now

        $fsIdleSeconds += $delta
        $idleSeconds += $delta
        $activeSeconds += $delta

        $child = Get-Process -Id $ChildProcess.Id -ErrorAction SilentlyContinue

        if (-not $child) {
            $newChild = Get-Process -ErrorAction SilentlyContinue |
                Where-Object { $_.Parent.Id -eq $ParentPID }

            if ($newChild) {
                Write-VSCodeUpdaterLog "[WATCHDOG] Child replaced — new PID $($newChild.Id)"
                $ChildProcess = $newChild
                continue
            }

            Write-VSCodeUpdaterLog "[WATCHDOG] Child exited — success"
            return [WatchdogExitCode]::Success
        }

        try {
            $latestWrite = $null

            foreach ($path in $installPaths) {
                try {
                    if (Test-Path $path) {
                        $candidate = Get-ChildItem -Recurse $path -File -ErrorAction SilentlyContinue |
                            Where-Object {
                                $_.Extension -notin '.log', '.tmp', '.bak' -and
                                $_.FullName -notmatch '\\logs?\\' -and
                                $_.FullName -notmatch '\\Crashpad\\'
                            } |
                            Sort-Object LastWriteTime |
                            Select-Object -Last 1

                        if ($candidate -and (!$latestWrite -or $candidate.LastWriteTime -gt $latestWrite.LastWriteTime)) {
                            $latestWrite = $candidate
                        }
                    }
                }
                catch {
                    Write-VSCodeUpdaterLog "[WATCHDOG] FS scan exception on $($path): $($_.Exception.Message)"
                }
            }

            if ($latestWrite -and $latestWrite.LastWriteTime -gt $lastWriteTime) {
                if ((Get-Date) -gt $lastFsLog.AddSeconds($fsLogCooldown)) {
                    Write-VSCodeUpdaterLog "[WATCHDOG] FS activity: $($latestWrite.FullName)"
                    $lastFsLog = Get-Date
                }

                $lastWriteTime = $latestWrite.LastWriteTime
                $fsIdleSeconds = 0.0
                $activeSeconds = 0.0
                $idleSeconds = 0.0
            }
        }
        catch {
            Write-VSCodeUpdaterLog "[WATCHDOG] Exception: $($_.Exception.Message)"
        }

        if ($fsIdleSeconds -ge $IdleTimeout) {
            Write-VSCodeUpdaterLog "[WATCHDOG] FS stall after {0:N2}s — killing installer" -f $fsIdleSeconds
            Stop-Process -Id $ChildProcess.Id -Force -ErrorAction SilentlyContinue
            Stop-Process -Id $ParentPID -Force -ErrorAction SilentlyContinue
            return [WatchdogExitCode]::FSStalled
        }

        $cpuNow = $child.CPU
        $diskNow = $child.IOReadBytes + $child.IOWriteBytes

        $cpuDelta = $cpuNow - $lastCPU
        $diskDelta = $diskNow - $lastDisk

        $lastCPU = $cpuNow
        $lastDisk = $diskNow

        if ($cpuDelta -eq 0 -and $diskDelta -eq 0) {
            if ($lastState -ne "Idle") {
                Write-VSCodeUpdaterLog "[WATCHDOG] Child transitioned to idle"
                $lastState = "Idle"
            }

            if ($idleSeconds -ge $IdleTimeout) {
                Write-VSCodeUpdaterLog "[WATCHDOG] Idle stall after {0:N2}s — killing parent" -f $idleSeconds
                Stop-Process -Id $ParentPID -Force -ErrorAction SilentlyContinue
                Wait-Process -Id $ChildProcess.Id -ErrorAction SilentlyContinue
                return [WatchdogExitCode]::IdleStalled
            }
        }
        else {
            if ($lastState -ne "Active") {
                Write-VSCodeUpdaterLog "[WATCHDOG] Child transitioned to active"
                $lastState = "Active"
            }

            if ($cpuDelta -eq 0 -and $diskDelta -eq 0) {
                if ($activeSeconds -ge $IdleTimeout) {
                    Write-VSCodeUpdaterLog "[WATCHDOG] Active stall after {0:N2}s — killing parent and child" -f $activeSeconds
                    Stop-Process -Id $ChildProcess.Id -Force -ErrorAction SilentlyContinue
                    Stop-Process -Id $ParentPID -Force -ErrorAction SilentlyContinue
                    return [WatchdogExitCode]::ActiveStalled
                }
            }
            else {
                $activeSeconds = 0.0
            }

            $idleSeconds = 0.0
        }

        Start-Sleep -Seconds 2
    }
}
