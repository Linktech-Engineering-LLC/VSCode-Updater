<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-02
    Modified: 2026-07-05
    File: Start-VSCodeUpdaterGUI
    Version: 1.1.0
    Description: WPF GUI host for VSCode-Updater. Uses unified output helpers, Safe Mode,
                 and async command execution with a simple view-model.
#>

# Import module + helpers
Remove-Module VSCode-Updater -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\VSCode-Updater.psd1" -Force

. "$PSScriptRoot\..\Private\OutputHelpers.ps1"
. "$PSScriptRoot\..\Private\Write-VSCodeUpdaterLog.ps1"
. "$PSScriptRoot\..\Private\Get-SelectedVersionName.ps1"

# Simple view-model for GUI state
$script:vm = [pscustomobject]@{
    SafeMode          = $true
    AutoScrollEnabled = $true
    GuiInitialized    = $false
}

# Lightweight Task Viewer writer
function Write-TaskViewerLine {
    param(
        [string]$Text,
        [string]$Color = "White"
    )

    $window.Dispatcher.Invoke({
        # Cap at 200 lines
        $lines = $txtTaskViewer.Document.Blocks.Count
        if ($lines -gt 200) {
            $txtTaskViewer.Document.Blocks.Clear()
        }

        $run = New-Object System.Windows.Documents.Run
        $run.Text = $Text + "`n"
        $run.Foreground = $Color

        $para = New-Object System.Windows.Documents.Paragraph
        $para.Inlines.Add($run)

        $txtTaskViewer.Document.Blocks.Add($para)
        $txtTaskViewer.ScrollToEnd()
    })
}

function Show-DashboardInTerminal {
    $info = Get-VSCodeDashboard

    Write-TerminalLine "=== Dashboard ===" "LightGray"

    if ($info) {
        Write-TerminalLine "Installed Versions: $($info.InstalledVersions)" "White"
        Write-TerminalLine "Version Count: $($info.VersionCount)" "White"
        Write-TerminalLine "Active Version: $($info.ActiveVersion)" "Green"
        Write-TerminalLine "Cache Path:    $($info.CachePath)" "Yellow"
        Write-TerminalLine "LastUpdateLog: $($info.LastUpdateLog)" "White"
    }
    else {
        Write-TerminalLine "Dashboard: No information available." "Red"
    }

    Write-TerminalLine "=================" "LightGray"
}

function Show-VSCodeSymlinkInfo {
    $info = Get-VSCodeSymlinkInfo

    Write-TerminalLine "=== VSCode Symlink Info ===" "LightGray"

    if ($info) {
        Write-TerminalLine "Active Version: $($info.ActiveVersion)" "LightGreen"
        Write-TerminalLine "Target Path:    $($info.TargetPath)" "White"
        Write-TerminalLine "Valid:          $($info.IsValid)" "LightBlue"
        Write-TerminalLine "Last Update:    $($info.LastUpdateResult)" "Yellow"
        Write-TerminalLine "Fallback Reason:$($info.LastFallbackReason)" "Red"
    }
    else {
        Write-TerminalLine "No symlink information found." "Red"
    }

    Write-TerminalLine "=============================" "LightGray"
}

function Confirm-SetupAppRunning {
    $proc = Get-Process -Name "SetupApp" -ErrorAction SilentlyContinue

    if (-not $proc) {
        Write-TaskViewerLine "SetupApp missing — restarting..." "Yellow"

        try {
            Start-Process "C:\Path\To\SetupApp.exe"
            Write-TaskViewerLine "SetupApp restarted successfully." "LightGreen"
        }
        catch {
            Write-TaskViewerLine "Failed to restart SetupApp: $_" "Red"
        }
    }
}

function Update-TaskViewerStatus {
    $proc = Get-Process -Name "SetupApp" -ErrorAction SilentlyContinue

    $window.Dispatcher.Invoke({
        $txtTaskViewer.Document.Blocks.Clear()
    })

    if ($proc) {
        Write-TaskViewerLine "SetupApp: Running (PID $($proc.Id))" "LightGreen"
        Write-TaskViewerLine ("CPU Time: {0:N2} sec" -f $proc.CPU) "White"
        Write-TaskViewerLine ("Memory: {0:N2} MB" -f ($proc.WorkingSet64 / 1MB)) "White"

        if ($proc.WorkingSet64 -gt 50MB) {
            Write-TaskViewerLine "Status: Busy" "Yellow"
        }
        else {
            Write-TaskViewerLine "Status: Idle" "LightBlue"
        }
    }
    else {
        Write-TaskViewerLine "SetupApp: Not running" "Red"
    }

    Write-TaskViewerLine ("Last check: {0}" -f (Get-Date -Format "HH:mm:ss")) "Gray"
}

function Update-SymlinkInfo {
    $info = Get-VSCodeSymlinkInfo

    $txtActiveVersion.Text  = "Active Version: $($info.ActiveVersion)"
    $txtSymlinkTarget.Text  = "Symlink Target: $($info.TargetPath)"
    $txtSymlinkValid.Text   = "Symlink Status: " + ($info.IsValid ? "Valid" : "Broken")
    $txtLastUpdate.Text     = "Last Update: $($info.LastUpdateResult)"
    $txtFallbackReason.Text = "Fallback Reason: $($info.LastFallbackReason)"
}

function Start-VSCodeUpdaterGUI {

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    $script:SafeMode = $true   # default ON

    $xamlPath = Join-Path $PSScriptRoot "VSCodeUpdaterGUI.xaml"
    $xamlPath = (Resolve-Path $xamlPath).Path

    if (-not (Test-Path $xamlPath)) {
        throw "GUI XAML file not found: $xamlPath"
    }

    $xaml   = Get-Content $xamlPath -Raw
    $utf8   = New-Object System.Text.UTF8Encoding
    $bytes  = $utf8.GetBytes($xaml)
    $stream = New-Object System.IO.MemoryStream
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Position = 0

    $reader        = [System.Xml.XmlReader]::Create($stream)
    $global:window = [Windows.Markup.XamlReader]::Load($reader)

    $dgVersions          = $window.FindName("DgVersions")
    $script:btnUpdate    = $window.FindName("BtnUpdate")
    $script:btnRollback  = $window.FindName("BtnRollback")
    $script:btnSwitch    = $window.FindName("BtnSwitch")
    $script:txtStatus    = $window.FindName("TxtStatus")
    $script:txtLog       = $window.FindName("TxtLog")
    $global:txtCommandOutput = $window.FindName("TxtCommandOutput")
    $script:txtActiveVersion  = $window.FindName("TxtActiveVersion")
    $script:txtSymlinkTarget  = $window.FindName("TxtSymlinkTarget")
    $script:txtSymlinkValid   = $window.FindName("TxtSymlinkValid")
    $script:txtLastUpdate     = $window.FindName("TxtLastUpdate")
    $script:txtFallbackReason = $window.FindName("TxtFallbackReason")
    $script:btnValidateSymlink = $window.FindName("BtnValidateSymlink")
    $script:btnSafeMode        = $window.FindName("BtnSafeMode")
    $script:btnDashboard       = $window.FindName("BtnDashboard")
    $script:btnPauseLog        = $window.FindName("BtnPauseLog")
    $script:btnSearchLog       = $window.FindName("BtnSearchLog")
    $script:chkAutoScroll      = $window.FindName("ChkAutoScroll")
    $script:txtSearchLog       = $window.FindName("TxtSearchLog")
    $script:txtTaskViewer      = $window.FindName("TxtTaskViewer")
    $script:btnRestartSetup    = $window.FindName("BtnRestartSetup")
    $script:chkSafeMode        = $window.FindName("ChkSafeMode")

    $chkSafeMode.IsChecked       = $true
    $chkAutoScroll.IsChecked     = $true
    $script:vm.AutoScrollEnabled = $true

    $txtTaskViewer.Document = New-Object System.Windows.Documents.FlowDocument

    $info = Get-VSCodeSymlinkInfo
    $window.Resources["ActiveVersionName"] = $info.ActiveVersion

    Update-SymlinkInfo

    # Log tailing
    $logRoot = "C:\Logs"
    $logFile = Join-Path $logRoot "Update-Code.log"

    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(2)
    $timer.Add_Tick({
        if (Test-Path $logFile) {
            try {
                $txtLog.Text = (Get-Content $logFile -Tail 200) -join "`r`n"

                if ($chkAutoScroll.IsChecked) {
                    $txtLog.ScrollToEnd()
                }
            }
            catch { }
        }
    })
    $timer.Start()

    $taskTimer = New-Object Windows.Threading.DispatcherTimer
    $taskTimer.Interval = [TimeSpan]::FromSeconds(5)
    $taskTimer.Add_Tick({ Update-TaskViewerStatus })
    $taskTimer.Start()

    # Version list
    $dgVersions.ItemsSource = Get-VSCodeVersions

    $window.Add_Loaded({
        $script:vm.GuiInitialized = $true

        $active = $info.ActiveVersion
        foreach ($row in $dgVersions.Items) {
            if ($row.Name -eq $active) {
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

    # Async helpers
    function Start-UpdateJob {
        $job = Start-Job -ScriptBlock {
            Update-VSCode
        }

        Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
            if ($job.State -eq 'Completed') {
                $result = Receive-Job $job
                $window.Dispatcher.Invoke({
                    $txtStatus.Text = "Update completed: $result"
                    Show-VSCodeSymlinkInfo
                })
                Unregister-Event -SourceIdentifier $event.SourceIdentifier
                Remove-Job $job
            }
        } | Out-Null
    }

    function Start-RollbackJob {
        $job = Start-Job -ScriptBlock {
            Invoke-VSCodeRollback
        }

        Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
            if ($job.State -eq 'Completed') {
                $result = Receive-Job $job
                $window.Dispatcher.Invoke({
                    $txtStatus.Text = "Rollback completed: $result"
                    Show-VSCodeSymlinkInfo
                    $dgVersions.ItemsSource = Get-VSCodeVersions
                })
                Unregister-Event -SourceIdentifier $event.SourceIdentifier
                Remove-Job $job
            }
        } | Out-Null
    }

    function Start-SwitchJob {
        param($selected)

        $job = Start-Job -ScriptBlock {
            Switch-VSCodeVersion -VersionName $using:selected.Name
        }

        Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
            if ($job.State -eq 'Completed') {
                $result = Receive-Job $job
                $window.Dispatcher.Invoke({
                    $txtStatus.Text = "Switched to: $result"
                    Show-VSCodeSymlinkInfo
                    $dgVersions.ItemsSource = Get-VSCodeVersions
                })
                Unregister-Event -SourceIdentifier $event.SourceIdentifier
                Remove-Job $job
            }
        } | Out-Null
    }

    # Events
    $btnUpdate.Add_Click({
        if ($script:SafeMode) {
            _out "SAFE MODE — Update blocked." "Yellow"
            $txtStatus.Text = "Update blocked (Safe Mode)."
            return
        }

        Start-UpdateJob
    })

    $btnRollback.Add_Click({
        if ($script:SafeMode) {
            _out "SAFE MODE — Rollback blocked." "Yellow"
            $txtStatus.Text = "Rollback blocked (Safe Mode)."
            return
        }

        Start-RollbackJob
    })

    $btnSwitch.Add_Click({
        if ($script:SafeMode) {
            _out "SAFE MODE — Switch blocked." "Yellow"
            $txtStatus.Text = "Switch blocked (Safe Mode)."
            return
        }

        $selected = $dgVersions.SelectedItem
        if ($selected) {
            Start-SwitchJob -selected $selected
        }
        else {
            $txtStatus.Text = "Select a version before switching."
        }
    })

    $btnValidateSymlink.Add_Click({
        try {
            $result = Test-VSCodeSymlink
            $txtStatus.Text = "Symlink validation: $result"
            Update-SymlinkInfo
            Show-VSCodeSymlinkInfo
        }
        catch {
            $txtStatus.Text = "Symlink validation failed: $_"
        }
    })

    $btnSafeMode.Add_Click({
        Start-VSCodeSafeMode
    })

    $chkSafeMode.Add_Checked({
        Set-VSCodeSafeMode -Enabled $true
        $txtStatus.Text = "Safe Mode enabled."
    })

    $chkSafeMode.Add_Unchecked({
        Set-VSCodeSafeMode -Enabled $false
        $txtStatus.Text = "Safe Mode disabled."
    })

    $btnDashboard.Add_Click({
        Show-DashboardInTerminal
    })

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

    $btnSearchLog.Add_Click({
        $query = $txtSearchLog.Text

        if ([string]::IsNullOrWhiteSpace($query)) {
            $txtStatus.Text = "Enter text to search."
            return
        }

        $text  = $txtLog.Text
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

    $btnRestartSetup.Add_Click({
        Confirm-SetupAppRunning
    })

    $dgVersions.Add_SelectionChanged({
        $selected = $dgVersions.SelectedItem
        if (-not $selected) { return }

        if ($selected.IsValid) {
            $script:btnSwitch.Content = "Switch Version"
        }
        else {
            $script:btnSwitch.Content = "Delete Version"
        }

        Write-TerminalLine "Selected Version: $($selected.Version)" "LightBlue"
        Write-VSCodeUpdaterLog "Selected Version: $($selected.Version)"
    })

    $chkAutoScroll.Add_Checked({
        $script:vm.AutoScrollEnabled = $true
        $txtStatus.Text = "Auto-scroll enabled."
    })

    $chkAutoScroll.Add_Unchecked({
        $script:vm.AutoScrollEnabled = $false
        $txtStatus.Text = "Auto-scroll disabled."
    })

    $window.Add_Closed({
        $timer.Stop()
        $taskTimer.Stop()
    })

    $window.ShowDialog() | Out-Null
}

Start-VSCodeUpdaterGUI
