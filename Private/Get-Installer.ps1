<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/Get-Installer.ps1
    Version: 1.0.0
    Description: Retrieves the VS Code installer deterministically with support for Skip, Force, and Normal download modes, including hash validation and temp file cleanup.
#>
function Get-Installer {
    [CmdletBinding()]
    param(
        [string]$Url,
        [string]$CachePath,

        [ValidateSet("Skip","Force","Normal")]
        [string]$DownloadMode = "Normal"
    )

    Write-Log "[DOWNLOAD] Mode: $DownloadMode"

    # --- Helper: validate installer file ---
    function Test-InstallerValid($Path) {
        if (-not (Test-Path $Path)) { return $false }

        $info = Get-Item $Path -ErrorAction SilentlyContinue
        if ($info.Length -lt 1MB) {
            Write-Log "[DOWNLOAD] Installer too small (<1MB): $Path"
            return $false
        }
        if ($info.Extension -notin ".exe") {
            Write-Log "[DOWNLOAD] Installer extension invalid: $($info.Extension)"
            return $false
        }
        return $true
    }

    switch ($DownloadMode) {

        "Skip" {
            Write-Log "[DOWNLOAD] Skip mode — using cached installer only"

            if (-not (Test-InstallerValid $CachePath)) {
                Write-Log "[ERROR] Skip mode used but cached installer is missing or invalid"
                return $null
            }

            return $CachePath
        }

        "Force" {
            Write-Log "[DOWNLOAD] Force mode — downloading fresh installer"

            try {
                Invoke-WebRequest -Uri $Url -OutFile $CachePath -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-Log "[ERROR] Forced download failed: $($_.Exception.Message)"
                return $null
            }

            if (-not (Test-InstallerValid $CachePath)) {
                Write-Log "[ERROR] Forced download produced invalid installer"
                return $null
            }

            return $CachePath
        }

        "Normal" {
            Write-Log "[DOWNLOAD] Normal mode — checking cache"

            if (Test-InstallerValid $CachePath) {
                Write-Log "[DOWNLOAD] Cached installer exists — checking for update"

                $temp = Join-Path $env:TEMP "installer.exe"

                # Clean stale temp file
                if (Test-Path $temp) {
                    Remove-Item $temp -Force -ErrorAction SilentlyContinue
                }

                # Download new installer
                try {
                    Invoke-WebRequest -Uri $Url -OutFile $temp -UseBasicParsing -ErrorAction Stop
                }
                catch {
                    Write-Log "[ERROR] Failed to download installer: $($_.Exception.Message)"
                    return $null
                }

                if (-not (Test-InstallerValid $temp)) {
                    Write-Log "[ERROR] Downloaded installer is invalid"
                    Remove-Item $temp -Force -ErrorAction SilentlyContinue
                    return $null
                }

                $cachedHash = Get-FileHashSafe -Path $CachePath
                $newHash    = Get-FileHashSafe -Path $temp

                Write-Log "[DOWNLOAD] Cached hash: $cachedHash"
                Write-Log "[DOWNLOAD] New hash:    $newHash"

                if ($cachedHash -eq $newHash) {
                    Write-Log "[DOWNLOAD] Installer unchanged — keeping cached copy"
                    Remove-Item $temp -Force -ErrorAction SilentlyContinue
                    return $CachePath
                }

                Write-Log "[DOWNLOAD] Installer updated — replacing cached copy"
                Copy-Item $temp $CachePath -Force
                Remove-Item $temp -Force -ErrorAction SilentlyContinue
                return $CachePath
            }

            # No cache exists — download fresh
            Write-Log "[DOWNLOAD] No cached installer — downloading fresh copy"

            try {
                Invoke-WebRequest -Uri $Url -OutFile $CachePath -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-Log "[ERROR] Failed to download installer: $($_.Exception.Message)"
                return $null
            }

            if (-not (Test-InstallerValid $CachePath)) {
                Write-Log "[ERROR] Fresh download produced invalid installer"
                return $null
            }

            return $CachePath
        }
    }
}
