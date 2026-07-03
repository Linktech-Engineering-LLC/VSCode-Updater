<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-06-14
    File: VSCode-Updater.psm1
    Version: 2.2.0
    Description: Module root for VSCode-Updater. Loads public functions, wires private helpers, and exposes the deterministic Update-VSCode entry point and related management commands.
#>

# Dot-source Public functions
Get-ChildItem -Path $PSScriptRoot/Public -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

# Load private functions
Get-ChildItem -Path "$PSScriptRoot/Private" -Filter *.ps1 |
    ForEach-Object { . $_.FullName }

function Update-VSCode {
    [CmdletBinding()]
    param(
        [switch]$SkipUpdate,
        [switch]$SkipDownload,
        [switch]$ForceDownload,
        [int]$RetryCount = 3,
        [int]$IdleTimeout = 600
    )
    $MaxRetries = 5   # hard ceiling for safety

    # =====================================================================
    #  Initialization + Metadata Banner
    # =====================================================================

    $scriptName    = "Update-VSCode"
    $scriptVersion = "2.1.0"

    $codeExe    = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
    $codeRoot   = Split-Path $codeExe -Parent
    $cacheDir   = "$PSScriptRoot/../Cache"
    $cachedInstaller = Join-Path $cacheDir "VSCodeSetup.exe"
    $installerUrl    = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
    $script:LastUpdateResult   = $null
    $script:LastFallbackReason = $null

    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    }

    Write-Log "==============================================================================="
    Write-Log "  $scriptName started — Version $scriptVersion"
    Write-Log "  Host: $env:COMPUTERNAME"
    Write-Log "  User: $env:USERNAME"
    Write-Log "  RetryCount=$RetryCount  IdleTimeout=$IdleTimeout"
    Write-Log "==============================================================================="

    # Guard: VS Code must not be running
    $running = Get-Process -Name "Code", "Code - Insiders" -ErrorAction SilentlyContinue

    if ($running) {
        Write-Host "VS Code is currently running."
        Write-Host "Updating requires closing VS Code."

        $choice = Read-Host "Close VS Code and continue? (Y/N)"

        if ($choice -notin @('Y','y')) {
            Write-Log -Level Warning -Message "User aborted update because VS Code was running."
            $script:LastUpdateResult   = "Failed"
            $script:LastFallbackReason = "User aborted because VS Code was running"
            return 30
        }

        Write-Log -Level Info -Message "Closing VS Code to continue update."
        $running | Stop-Process -Force
    }

    # =====================================================================
    #  Pre‑Cleanup
    # =====================================================================

    Cleanup-SetupBootstrapper
    Cleanup-VSCodeHelpers
    Cleanup-InnoSetupWorkers
    Start-Sleep -Seconds 2
    CleanCodePath
    Start-Sleep -Seconds 2

    # =====================================================================
    #  Skip Mode
    # =====================================================================

    if ($SkipUpdate) {
        Write-Log "[SKIP] SkipUpdate switch present — skipping update."
        $script:LastUpdateResult   = "Skipped"
        $script:LastFallbackReason = $null
        Write-Log "----- $scriptName ended (exit 20) -----"
        return 20
    }

    # =====================================================================
    #  Download + Cache Installer
    # =====================================================================
    $Mode = if ($SkipDownload) {
        "Skip"
    }
    elseif ($ForceDownload) {
        "Force"
    }
    else {
        "Normal"
    }

    Write-Host "Installer URL: '$installerUrl'"
    Write-Host "Length: $($installerUrl.Length)"

    Get-Installer -Url $installerUrl -CachePath $cachedInstaller -DownloadMode $Mode

    # --- HARD FAILURE CHECK ---
    if (-not (Test-Path $cachedInstaller)) {
        Write-Log "[ERROR] Cached installer missing after update"
        $script:LastUpdateResult   = "Failed"
        $script:LastFallbackReason = "Cached installer missing"
        Write-Log "----- $scriptName ended (exit 12) -----"
        return 12
    }

    # --- DIAGNOSTICS ---
    $size = (Get-Item $cachedInstaller).Length
    if ($size -lt 5MB) {
        Write-Log "[DETECT] Cached installer appears corrupted or incomplete (size: $size bytes)"
    }

    $installerItem = Get-Item $cachedInstaller
    $age = (Get-Date) - $installerItem.LastWriteTime
    if ($age.TotalDays -gt 7) {
        Write-Log "[DETECT] Cached installer is stale (age: $([math]::Round($age.TotalDays,2)) days)"
        Write-Log "[DETECT] This may indicate a past failed or incomplete update attempt."
    }

    $installDir = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
    if (Test-Path $installDir) {
        $lastWrite = (Get-Item $installDir).LastWriteTime
        if ($lastWrite -lt (Get-Date).AddMinutes(-10)) {
            Write-Log "[DETECT] Install directory timestamp unchanged. Installer may have exited without updating."
        }
    } else {
        Write-Log "[DETECT] VS Code install directory not found. Installation may be incomplete or corrupted."
    }

    # =====================================================================
    #  Retry Loop
    # =====================================================================

    Cleanup-InnoSetupWorkers
    Start-Sleep -Milliseconds 200

    if ($RetryCount -gt $MaxRetries) {
        Write-Log "[WARN] RetryCount ($RetryCount) exceeds maximum allowed ($MaxRetries). Clamping."
        $RetryCount = $MaxRetries
    }

    $attempt     = 0
    $maxAttempts = $RetryCount + 1

    while ($attempt -lt $maxAttempts) {
        $attempt++
        Write-Log "[ATTEMPT] Installer attempt $attempt of $maxAttempts"

        try {
            $p = Start-InstallerDetached -Path $cachedInstaller
            $parentPID = $p.Id
            Write-Log "[DETECT] Parent PID: $parentPID"

            $child = $null
            $detectTimeout = 10
            $elapsed = 0

            while (-not $child -and $elapsed -lt $detectTimeout) {
                Start-Sleep -Milliseconds 500
                $elapsed += 1

                $child = Get-CimInstance Win32_Process -Filter "ParentProcessId = $parentPID" -ErrorAction SilentlyContinue |
                    Sort-Object CreationDate |
                    Select-Object -Last 1
            }

            if ($child) {
                $childPID = $child.ProcessId
                Write-Log "[DETECT] Child worker PID: $childPID (found after ${elapsed}s)"
            } else {
                Write-Log "[DETECT] No child worker detected — treating as installer failure"
                Cleanup-VSCodeHelpers
                Cleanup-InnoSetupWorkers
                continue
            }

            $childProcess = Get-Process -Id $childPID -ErrorAction SilentlyContinue
            $result = Watchdog-MonitorInstaller -ChildProcess $childProcess -ParentPID $parentPID -IdleTimeout $IdleTimeout

            switch ($result) {
                "Success" {
                    Write-Log "[WATCHDOG] Installer exited normally"
                    Write-Log "----- $scriptName ended (exit 0) (Normal)-----"
                    $result = "Success"
                    break
                }

                "FS-Stalled" {
                    Write-Log "[WATCHDOG] Filesystem stall detected"
                    $result = "FS Stalled"
                    break
                }

                "Idle-Stalled" {
                    Write-Log "[WATCHDOG] CPU/Disk idle stall"
                    $result = "Idle Stall"
                    break
                }

                "Active-Stalled" {
                    Write-Log "[WATCHDOG] CPU/Disk active stall"
                    $result = "Active Stall"
                    break
                }

                default {
                    Write-Log "[WATCHDOG] Unexpected watchdog state: $result"
                    $result = "Unexpected Error"
                    break
                }
            }
        }
        catch {
            Write-Log "[ERROR] Installer start failure: $($_.Exception.Message)"
            if ($attempt -ge $maxAttempts) {
                Write-Log "----- $scriptName ended (exit 13) (Start Failure) -----"
                $script:LastUpdateResult   = "Failed"
                $script:LastFallbackReason = "Installer start failure"
                return 13
            }
            Write-Log "[RETRY] Retrying due to start failure"
            continue
        }

        Cleanup-VSCodeHelpers
        Cleanup-InnoSetupWorkers

        if ($result -eq "Success") {
            Write-Log "[SUCCESS] Installer completed successfully on attempt $attempt"
            $script:LastUpdateResult   = "Success"
            $script:LastFallbackReason = $null
            break
        }
        else {
            Write-Log "[STALL] Installer stalled on attempt $attempt"

            if ($result -like "*Stall*") {
                Write-Log "[STALL] Detected stall state '$result' — performing cleanup before fallback"
                Cleanup-VSCodeHelpers
                Cleanup-InnoSetupWorkers
                Write-Log "[STALL] Cleanup complete — invoking ZIP fallback"
                return Invoke-ZipFallback -Reason $result
            }

            if ($attempt -ge $maxAttempts) {
                Write-Log "[FAIL] Installer stalled after $attempt attempts — invoking ZIP fallback"
                return Invoke-ZipFallback -Reason "Installer stalled after $attempt attempts"
            }

            Write-Log "[RETRY] Cleaning processes and artifacts before retry"
            Cleanup-VSCodeHelpers
            Cleanup-InnoSetupWorkers
            continue
        }

        Get-Process Code, CodeHelper*, CodeSetup*, VSCodeSetup* -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
    }

    # =====================================================================
    #  Post‑Install Health Check
    # =====================================================================

    Write-Log "[CHECK] Running post-install health validation"

    if (-not (Test-Path $codeExe)) {
        Write-Log "[CHECK] Code.exe missing — triggering ZIP fallback"
        return Invoke-ZipFallback -Reason "Missing Code.exe"
    }

    try {
        $proc = Start-Process $codeExe -PassThru -ErrorAction Stop
        Start-Sleep -Seconds 2

        if ($proc.HasExited) {
            Write-Log "[CHECK] VS Code exited immediately — triggering ZIP fallback"
            return Invoke-ZipFallback -Reason "Launch failure"
        }

        $proc | Stop-Process -Force
    }
    catch {
        Write-Log "[CHECK] Exception launching VS Code: $($_.Exception.Message)"
        return Invoke-ZipFallback -Reason "Launch exception"
    }

    $debris = @(
        "$codeRoot\update.exe",
        "$codeRoot\*.tmp",
        "$codeRoot\*.partial"
    )

    foreach ($pattern in $debris) {
        if (Get-ChildItem $pattern -ErrorAction SilentlyContinue) {
            Write-Log "[CHECK] Detected leftover update debris — triggering ZIP fallback"
            return Invoke-ZipFallback -Reason "Debris detected"
        }
    }

    Write-Log "[CHECK] Health check passed — installer appears successful"

    # =====================================================================
    #  Finalization
    # =====================================================================

    Write-Log "[FINAL] Waiting for cleanup to settle"
    Start-Sleep -Seconds 5
    
    if ($attempt -lt $maxAttempts){
        Write-Log "[FINAL] Update-VSCode completed successfully after $attempt attempts"
        $script:LastUpdateResult   = "Success"
        $script:LastFallbackReason = $null
    } else {
        Write-Log "[FAIL] Errors encountered Updating VSCode"
        $script:LastUpdateResult   = "Failed"
        $script:LastFallbackReason = "Unknown finalization failure"
    }

    Write-Log "==============================================================================="

    return 0
}

Export-ModuleMember -Function Update-VSCode, `
    Get-VSCodeVersions, `
    Switch-VSCodeVersion, `
    Invoke-VSCodeRollback, `
    Test-VSCodeSymlink, `
    Start-VSCodeSafeMode, `
    Get-VSCodeDashboard, `
    Invoke-ZipFallback, `
    Get-VSCodeSymlinkInfo
