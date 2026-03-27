function Get-FileHashSafe {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return $null }

    try {
        return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash
    }
    catch {
        Write-Log "[ERROR] Failed to compute hash for $Path : $($_.Exception.Message)"
        return $null
    }
}
