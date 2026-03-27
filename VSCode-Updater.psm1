# Load private functions
Get-ChildItem -Path "$PSScriptRoot/Private" -Filter *.ps1 |
    ForEach-Object { . $_.FullName }

# Load public functions
Get-ChildItem -Path "$PSScriptRoot/Public" -Filter *.ps1 |
    ForEach-Object { . $_.FullName }

Export-ModuleMember -Function Update-VSCode
