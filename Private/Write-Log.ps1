function Write-Log {
    param([string]$Message)

    $logRoot = "C:\Logs"
    $logFile = Join-Path $logRoot "Update-Code.log"

    if (-not (Test-Path $logRoot)) {
        New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFile -Value "$timestamp $Message"
}
