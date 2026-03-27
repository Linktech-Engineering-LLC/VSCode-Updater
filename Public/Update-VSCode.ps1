function Update-VSCode {
    [CmdletBinding()]
    param(
        [switch]$SkipUpdate,
        [int]$RetryCount = 3,
        [int]$IdleTimeout = 120
    )

    # =====================================================================
    #  Initialization + Metadata Banner
    # =====================================================================

    $scriptName    = "Update-VSCode"
    $scriptVersion = "2.0.0"

    $codeExe    = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
    $codeRoot   = Split-Path $codeExe -Parent
    $cacheDir   = "$PSScriptRoot/../Cache"
    $cachedInstaller = Join-Path $cacheDir "VSCodeSetup.exe"
    $tempInstaller   = Join-Path $env:TEMP "VSCodeSetup.tmp"
    $installerUrl    = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"

    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    }

    Write-Log "==============================================================================="
    Write-Log "  $scriptName started — Version $scriptVersion"
    Write-Log "  Host: $env:COMPUTERNAME"
    Write-Log "  User: $env:USERNAME"
    Write-Log "  RetryCount=$RetryCount  IdleTimeout=$IdleTimeout"
    Write-Log "==============================================================================="

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
        Write-Log "----- $scriptName ended (exit 20) -----"
        return 20
    }

    # =====================================================================
    #  Download + Cache Installer
    # =====================================================================

    Write-Log "[DOWNLOAD] Downloading installer to: $tempInstaller"

    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $tempInstaller -UseBasicParsing
    }
    catch {
        Write-Log "[ERROR] Failed to download installer: $($_.Exception.Message)"
        Write-Log "----- $scriptName ended (exit 10) -----"
        return 10
    }

    $cachedHash = Get-FileHashSafe -Path $cachedInstaller
    $newHash    = Get-FileHashSafe -Path $tempInstaller

    Write-Log "[HASH] Cached:    $cachedHash"
    Write-Log "[HASH] Downloaded: $newHash"

    if ($cachedHash -and $newHash -and ($cachedHash -eq $newHash)) {
        Write-Log "[CACHE] Installer unchanged — using cached copy"
        Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Log "[CACHE] Updating cached installer"
        Copy-Item $tempInstaller $cachedInstaller -Force
        Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue
    }

    if (-not (Test-Path $cachedInstaller)) {
        Write-Log "[ERROR] Cached installer missing after update"
        Write-Log "----- $scriptName ended (exit 12) -----"
        return 12
    }

    # =====================================================================
    #  Retry Loop
    # =====================================================================

    $attempt     = 0
    $maxAttempts = $RetryCount + 1

    while ($attempt -lt $maxAttempts) {
        $attempt++
        Write-Log "[ATTEMPT] Installer attempt $attempt of $maxAttempts"

        try {
            # Launch installer
            $p = Start-InstallerDetached -Path $cachedInstaller
            $parentPID = $p.Id
            Write-Log "[DETECT] Parent PID: $parentPID"

            Start-Sleep -Milliseconds 300

            # Detect child worker
            $child = Get-Process -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Id -ne $parentPID -and
                    $_.StartTime -gt $p.StartTime -and
                    (
                        $_.ProcessName -like "CodeSetup*"      -or
                        $_.ProcessName -like "VSCodeSetup*"    -or
                        $_.ProcessName -match "^is-[A-Za-z0-9]+$" -or
                        $_.ProcessName -match "tmp$"           -or
                        $_.ProcessName -match "tmp.exe$"       -or
                        $_.Path -like "*CodeSetup*"            -or
                        $_.CommandLine -match "CodeSetup"      -or
                        $_.CommandLine -match "VSCodeSetup"
                    )
                } |
                Sort-Object StartTime |
                Select-Object -Last 1

            if ($child) {
                Write-Log "[DETECT] Child worker PID: $($child.Id)"
                $childPID = $child.Id
            }
            else {
                Write-Log "[DETECT] No child detected — using parent as fallback"
                $childPID = $parentPID
            }

            $childProcess = Get-Process -Id $childPID -ErrorAction SilentlyContinue
            $result = Watchdog-MonitorInstaller -ChildProcess $childProcess -ParentPID $parentPID -IdleTimeout $IdleTimeout
        }
        catch {
            Write-Log "[ERROR] Installer start failure: $($_.Exception.Message)"
            if ($attempt -ge $maxAttempts) {
                Write-Log "----- $scriptName ended (exit 13) -----"
                return 13
            }
            Write-Log "[RETRY] Retrying due to start failure"
            continue
        }

        Cleanup-VSCodeHelpers
        Cleanup-InnoSetupWorkers

        if ($result -eq "Success") {
            Write-Log "[SUCCESS] Installer completed successfully on attempt $attempt"
            break
        }

        Write-Log "[STALL] Installer stalled on attempt $attempt"

        if ($attempt -ge $maxAttempts) {
            Write-Log "[FAIL] Installer stalled after $attempt attempts — aborting"
            Write-Log "----- $scriptName ended (exit 14) -----"
            return 14
        }

        Write-Log "[RETRY] Cleaning processes and artifacts before retry"

        Cleanup-VSCodeHelpers
        Cleanup-InnoSetupWorkers

        Get-Process Code, CodeHelper*, CodeSetup*, VSCodeSetup* -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
    }

    # =====================================================================
    #  Finalization
    # =====================================================================

    Write-Log "[FINAL] Waiting for cleanup to settle"
    Start-Sleep -Seconds 5

    Write-Log "[FINAL] Update-VSCode completed successfully"
    Write-Log "==============================================================================="

    return 0
}
