<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/Write-VSCodeUpdaterLog.ps1
    Version: 1.0.0
    Description: Writes timestamped log entries to the VSCode-Updater log file with deterministic formatting.
#>
function Write-VSCodeUpdaterLog {
    param([string]$Message)

    $mutex = New-Object System.Threading.Mutex($false, "VSCodeUpdaterLogLock")
    $mutex.WaitOne()

    try {
        $logRoot = "C:\Logs"
        $logFile = Join-Path $logRoot "Update-Code.log"
        if (-not (Test-Path $logRoot)) {
            New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
        }

        if ($script:SafeMode) {
            $Message = "[SAFE] $Message"
        }

        $Message = $Message -replace "`r|`n", " "
        $Message = $Message.Trim()

        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $line = "$timestamp $Message"

        # Duplicate prevention
        if (Test-Path $logFile) {
            $lastLine = Get-Content $logFile -Tail 1 -ErrorAction SilentlyContinue
            $lastMsg = $lastLine -replace '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\s+', ''

            if ($lastMsg -eq $Message) {
                return
            }
        }

        Add-Content -Path $logFile -Value $line -ErrorAction Stop | Out-Null
    }
    finally {
        $mutex.ReleaseMutex() | Out-Null
    }

    return
}
