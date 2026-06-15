function Get-VSCodeVersions {
    [CmdletBinding()]
    param()

    $root = Join-Path $env:LOCALAPPDATA "Programs"
    $prefix = "VSCode-"

    $versions = Get-ChildItem $root -Directory |
        Where-Object { $_.Name -like "$prefix*" } |
        Sort-Object Name -Descending

    $versions | Select-Object Name, FullName, LastWriteTime
}
