function Start-InstallerDetached {
    param([string]$Path)

    Write-Log "[INSTALL] Launching installer detached: $Path"

    return Start-Process $Path `
        -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode' `
        -WindowStyle Hidden `
        -NoNewWindow:$false `
        -PassThru
}
