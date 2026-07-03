<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-02
    Modified: 2026-07-02
    File: Start-VSCodeUpdaterGUI
    Version: 1.0.0
    Description: Description goes here
#>
Import-Module "$PSScriptRoot\..\VSCode-Updater.psd1" -Force

function Get-SelectedVersionName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$DataGrid
    )

    if ($null -eq $DataGrid -or $null -eq $DataGrid.SelectedItem) {
        return $null
    }

    $selectedItem = $DataGrid.SelectedItem
    if ($selectedItem.PSObject.Properties.Name -contains 'Name') {
        return [string]$selectedItem.Name
    }

    return $null
}

function Start-VSCodeUpdaterGUI {
    
    # Load WPF assemblies
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase


    # Resolve XAML path relative to the Public folder
    $xamlPath = Join-Path $PSScriptRoot "VSCodeUpdaterGUI.xaml"
    $xamlPath = (Resolve-Path $xamlPath).Path

    if (-not (Test-Path $xamlPath)) {
        throw "GUI XAML file not found: $xamlPath"
    }

    # Load XAML properly
    $xaml = Get-Content $xamlPath -Raw

    $utf8 = New-Object System.Text.UTF8Encoding
    $bytes = $utf8.GetBytes($xaml)
    $stream = New-Object System.IO.MemoryStream
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Position = 0

    $reader = [System.Xml.XmlReader]::Create($stream)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $dgVersions = $window.FindName("DgVersions")

    # Bind controls
    $btnUpdate   = $window.FindName("BtnUpdate")
    $btnRollback = $window.FindName("BtnRollback")
    $btnSwitch   = $window.FindName("BtnSwitch")
    $txtStatus   = $window.FindName("TxtStatus")
    $txtLog      = $window.FindName("TxtLog")
    $txtActiveVersion  = $window.FindName("TxtActiveVersion")
    $txtSymlinkTarget  = $window.FindName("TxtSymlinkTarget")
    $txtSymlinkValid   = $window.FindName("TxtSymlinkValid")
    $txtLastUpdate     = $window.FindName("TxtLastUpdate")
    $txtFallbackReason = $window.FindName("TxtFallbackReason")

    $info = Get-VSCodeSymlinkInfo
    $window.Resources["ActiveVersionName"] = $info.ActiveVersion

    $txtActiveVersion.Text = "Active Version: $($info.ActiveVersion)"
    $txtSymlinkTarget.Text = "Symlink Target: $($info.TargetPath)"
    $txtSymlinkValid.Text  = "Symlink Status: " + ($info.IsValid ? "Valid" : "Broken")
    $txtLastUpdate.Text    = "Last Update: $($info.LastUpdateResult)"
    $txtFallbackReason.Text = "Fallback Reason: $($info.LastFallbackReason)"

    # --- Real-time log tailing ---
    $logRoot = "C:\Logs"
    $logFile = Join-Path $logRoot "Update-Code.log"

    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(2)
    # Capture the variable explicitly
 
    $timer.Add_Tick({
        if (Test-Path $LogFile) {
            try {
                $txtLog.Text = (Get-Content $LogFile -Tail 200) -join "`r`n"
                $txtLog.ScrollToEnd()
            }
            catch {
                # Ignore transient file locks
            }
        }
    })
    $timer.Start()
    # --------------------------------

    # Load version list
    $dgVersions.ItemsSource = Get-VSCodeVersions
    # Highlight active version row
    $window.Add_Loaded({
        $active = $info.ActiveVersion

        foreach ($row in $dgVersions.Items)
        {
            if ($row.Name -eq $active)
            {
                $dgVersions.ScrollIntoView($row)

                $dgVersions.Dispatcher.Invoke({
                    $container = $dgVersions.ItemContainerGenerator.ContainerFromItem($row)
                    if ($null -ne $container) {
                        $container.Background = 'LightGreen'
                    }
                }, 'Render')
            }
        }
    })

    # Wire events
    $btnUpdate.Add_Click({
        $result = Update-VSCode
        $txtStatus.Text = "Update completed: $result"
        Update-VersionList
    })

    $btnRollback.Add_Click({
        $result = Invoke-VSCodeRollback
        $txtStatus.Text = "Rollback completed: $result"
        Update-VersionList
    })

    $btnSwitch.Add_Click({
        $selectedVersion = Get-SelectedVersionName -DataGrid $dgVersions

        if ($selectedVersion) {
            $result = Switch-VSCodeVersion -VersionName $selectedVersion
            $txtStatus.Text = "Switched to: $result"
            Update-VersionList
        }
        else {
            $txtStatus.Text = "Select a version before switching."
        }
    })

    # -----------------------------
    # Validate Symlink
    # -----------------------------
    $btnValidateSymlink.Add_Click({
        try {
            $result = Test-VSCodeSymlink
            $txtStatus.Text = "Symlink validation: $result"
            Update-SymlinkInfo
        }
        catch {
            $txtStatus.Text = "Symlink validation failed: $_"
        }
    })

    # -----------------------------
    # Start Safe Mode
    # -----------------------------
    $btnSafeMode.Add_Click({
        try {
            Start-VSCodeSafeMode
            $txtStatus.Text = "VS Code launched in Safe Mode."
        }
        catch {
            $txtStatus.Text = "Safe Mode launch failed: $_"
        }
    })

    # -----------------------------
    # Open Dashboard
    # -----------------------------
    $btnDashboard.Add_Click({
        try {
            Get-VSCodeDashboard
            $txtStatus.Text = "Dashboard opened."
        }
        catch {
            $txtStatus.Text = "Dashboard failed to open: $_"
        }
    })

    # -----------------------------
    # Pause / Resume Log
    # -----------------------------
    $btnPauseLog.Add_Click({
        if ($timer.IsEnabled) {
            $timer.Stop()
            $btnPauseLog.Content = "Resume Log"
            $txtStatus.Text = "Log paused."
        }
        else {
            $timer.Start()
            $btnPauseLog.Content = "Pause Log"
            $txtStatus.Text = "Log resumed."
        }
    })

    # -----------------------------
    # Log Search
    # -----------------------------
    $btnSearchLog.Add_Click({
        $query = $txtSearchLog.Text

        if ([string]::IsNullOrWhiteSpace($query)) {
            $txtStatus.Text = "Enter text to search."
            return
        }

        $text = $txtLog.Text
        $index = $text.IndexOf($query, [System.StringComparison]::OrdinalIgnoreCase)

        if ($index -ge 0) {
            $txtLog.Select($index, $query.Length)
            $txtLog.ScrollToLine($txtLog.GetLineIndexFromCharacterIndex($index))
            $txtStatus.Text = "Found '$query'."
        }
        else {
            $txtStatus.Text = "Search text not found."
        }
    })

    # -----------------------------
    # Auto Scroll Toggle
    # -----------------------------
    $chkAutoScroll.Add_Checked({
        $txtStatus.Text = "Auto-scroll enabled."
    })

    $chkAutoScroll.Add_Unchecked({
        $txtStatus.Text = "Auto-scroll disabled."
    })

    $window.Add_Closed({
        $timer.Stop()
    })
    function Update-SymlinkInfo {
        $info = Get-VSCodeSymlinkInfo

        $txtActiveVersion.Text  = "Active Version: $($info.ActiveVersion)"
        $txtSymlinkTarget.Text  = "Symlink Target: $($info.TargetPath)"
        $txtSymlinkValid.Text   = "Symlink Status: " + ($info.IsValid ? "Valid" : "Broken")
        $txtLastUpdate.Text     = "Last Update: $($info.LastUpdateResult)"
        $txtFallbackReason.Text = "Fallback Reason: $($info.LastFallbackReason)"
    }

    # Helper: refresh version list
    function Update-VersionList {
        $dgVersions.ItemsSource = Get-VSCodeVersions
    }

    # Show window
    $window.ShowDialog() | Out-Null
}

Start-VSCodeUpdaterGUI
