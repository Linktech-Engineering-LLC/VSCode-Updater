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
function Normalize-Scalar {
    param($Value)
    if ($Value -is [System.Array]) {
        return $Value[-1]
    }
    return $Value
}
function Test-InstallerValid {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $false
    }

    $info = Get-Item $Path -ErrorAction SilentlyContinue
    if ($info.Length -lt 1MB) {
        Write-VSCodeUpdaterLog "[INSTALLER] File too small (<1MB): $Path"
        return $false
    }

    if ($info.Extension -ne ".exe") {
        Write-VSCodeUpdaterLog "[INSTALLER] Invalid extension: $($info.Extension)"
        return $false
    }

    return $true
}

function Get-Installer {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$CachePath,

        [ValidateSet("Skip", "Force", "Normal")]
        [string]$DownloadMode = "Normal"
    )

    Write-VSCodeUpdaterLog "[INSTALLER] Mode: $DownloadMode"

    switch ($DownloadMode) {

        "Skip" {
            Write-VSCodeUpdaterLog "[INSTALLER] Skip mode — using cached installer only"

            if (-not (Test-InstallerValid -Path $CachePath)) {
                Write-VSCodeUpdaterLog "[INSTALLER] Skip mode failed — cached installer missing or invalid"
                return $null
            }

            return $CachePath
        }

        "Force" {
            Write-VSCodeUpdaterLog "[INSTALLER] Force mode — downloading fresh installer"

            try {
                Invoke-WebRequest -Uri $Url -OutFile $CachePath -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-VSCodeUpdaterLog "[INSTALLER] Forced download failed: $($_.Exception.Message)"
                return $null
            }

            if (-not (Test-InstallerValid -Path $CachePath)) {
                Write-VSCodeUpdaterLog "[INSTALLER] Forced download produced invalid installer"
                return $null
            }

            return $CachePath
        }

        "Normal" {
            Write-VSCodeUpdaterLog "[INSTALLER] Normal mode — checking cache"

            if (Test-InstallerValid -Path $CachePath) {
                Write-VSCodeUpdaterLog "[INSTALLER] Cached installer exists — checking for update"

                $temp = Join-Path $env:TEMP "installer.tmp.exe"

                if (Test-Path $temp) {
                    Remove-Item $temp -Force -ErrorAction SilentlyContinue | Out-Null
                }

                try {
                    Invoke-WebRequest -Uri $Url -OutFile $temp -UseBasicParsing -ErrorAction Stop
                }
                catch {
                    Write-VSCodeUpdaterLog "[INSTALLER] Failed to download installer: $($_.Exception.Message)"
                    return $null
                }

                if (-not (Test-InstallerValid -Path $temp)) {
                    Write-VSCodeUpdaterLog "[INSTALLER] Downloaded installer is invalid"
                    Remove-Item $temp -Force -ErrorAction SilentlyContinue | Out-Null
                    return $null
                }

                $cachedHash = Normalize-Scalar(Get-FileHashSafe -Path $CachePath)
                $newHash = Normalize-Scalar(Get-FileHashSafe -Path $temp)

                Write-VSCodeUpdaterLog "[INSTALLER] Cached hash: $cachedHash"
                Write-VSCodeUpdaterLog "[INSTALLER] New hash:    $newHash"

                if ($cachedHash -eq $newHash) {
                    Write-VSCodeUpdaterLog "[INSTALLER] Installer unchanged — keeping cached copy"
                    Remove-Item $temp -Force -ErrorAction SilentlyContinue | Out-Null
                    return $CachePath
                }

                Write-VSCodeUpdaterLog "[INSTALLER] Installer updated — replacing cached copy"
                Copy-Item $temp $CachePath -Force
                Remove-Item $temp -Force -ErrorAction SilentlyContinue | Out-Null
                return $CachePath
            }

            Write-VSCodeUpdaterLog "[INSTALLER] No cached installer — downloading fresh copy"

            try {
                Invoke-WebRequest -Uri $Url -OutFile $CachePath -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-VSCodeUpdaterLog "[INSTALLER] Failed to download installer: $($_.Exception.Message)"
                return $null
            }

            if (-not (Test-InstallerValid -Path $CachePath)) {
                Write-VSCodeUpdaterLog "[INSTALLER] Fresh download produced invalid installer"
                return $null
            }

            return $CachePath
        }
    }
}
