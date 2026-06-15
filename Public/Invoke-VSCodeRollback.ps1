function Invoke-VSCodeRollback {
    [CmdletBinding()]
    param()

    $root = Join-Path $env:LOCALAPPDATA "Programs"
    $prefix = "VSCode-"
    $linkPath = Join-Path $root "Microsoft VS Code"

    # List all versioned installs
    $versions = Get-ChildItem $root -Directory |
        Where-Object { $_.Name -like "$prefix*" } |
        Sort-Object Name -Descending

    if ($versions.Count -lt 2) {
        Write-Log "[ROLLBACK] Not enough versions to roll back"
        return 90
    }

    $currentTarget = (Get-Item $linkPath -ErrorAction SilentlyContinue).Target
    $previous = $versions[1].FullName

    Write-Log "[ROLLBACK] Current: $currentTarget"
    Write-Log "[ROLLBACK] Rolling back to: $previous"

    # Remove current symlink
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
    }

    # Create new symlink
    New-Item -ItemType SymbolicLink -Path $linkPath -Target $previous | Out-Null

    Write-Log "[ROLLBACK] Rollback complete"
    return 0
}
