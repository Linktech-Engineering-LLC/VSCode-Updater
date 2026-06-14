function Manage-VSCodeVersions {
    [CmdletBinding()]
    param(
        [int]$Keep = 3
    )

    $root = Join-Path $env:LOCALAPPDATA "Programs"
    $prefix = "VSCode-"

    $versions = Get-ChildItem $root -Directory |
        Where-Object { $_.Name -like "$prefix*" } |
        Sort-Object Name -Descending

    if ($versions.Count -le $Keep) {
        return
    }

    $toDelete = $versions | Select-Object -Skip $Keep

    foreach ($dir in $toDelete) {
        Write-Log "[CLEANUP] Removing old VS Code version: $($dir.FullName)"
        try {
            Remove-Item $dir.FullName -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Log "[CLEANUP] Failed to remove $($dir.FullName): $($_.Exception.Message)"
        }
    }
}
