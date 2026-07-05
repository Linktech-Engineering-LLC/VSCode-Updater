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
# NOW import the module
Remove-Module VSCode-Updater -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\VSCode-Updater.psd1" -Force
# Load output helpers (this defines _out)
. "$PSScriptRoot\..\Private\OutputHelpers.ps1"
. "$PSScriptRoot\..\Private\Write-Log.ps1"


function Clear-Terminal {
    $window.Dispatcher.Invoke({
        $txtCommandOutput.Document.Blocks.Clear()
    })
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
function Invoke-StreamingCommand {
    param([string]$Command)

    Clear-Terminal
    Write-TerminalLine "Running: $Command" "LightBlue"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoLogo -NoProfile -Command $Command"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    # Hook stdout
    $proc.add_OutputDataReceived({
        if ($_.Data) {
            Write-TerminalLine $_.Data "White"
        }
    })

    # Hook stderr
    $proc.add_ErrorDataReceived({
        if ($_.Data) {
            Write-TerminalLine $_.Data "Red"
        }
    })

    $proc.Start()
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    # Optional: wait for completion without blocking UI
    Start-Job -ScriptBlock {
        $proc.WaitForExit()
        $window.Dispatcher.Invoke({
            Write-TerminalLine "Process exited with code $($proc.ExitCode)" "LightGray"
        })
    }
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

function Start-VSCodeUpdaterGUI {
    
    # Load WPF assemblies
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    $script:SafeMode = $false

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
    $global:window = [Windows.Markup.XamlReader]::Load($reader)

    $dgVersions = $window.FindName("DgVersions")

    # Bind controls
    $script:btnUpdate   = $window.FindName("BtnUpdate")
    $script:btnRollback = $window.FindName("BtnRollback")
    $script:btnSwitch   = $window.FindName("BtnSwitch")
    $script:txtStatus   = $window.FindName("TxtStatus")
    $script:txtLog      = $window.FindName("TxtLog")
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
    $script:txtTaskViewer      = $window.FindName("TxtTaskViewer")   # if present
    $script:btnRestartSetup = $window.FindName("BtnRestartSetup")
    $script:chkSafeMode = $window.FindName("ChkSafeMode")
    # Default Safe Mode state on load
    $script:SafeMode = $true
    $chkSafeMode.IsChecked = $true
    
    $txtTaskViewer.Document = New-Object System.Windows.Documents.FlowDocument

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

                if ($chkAutoScroll.IsChecked) {
                    $txtLog.ScrollToEnd()
                }
            }
            catch {
                # Ignore transient file locks
            }
        }
    })
    $timer.Start()
    $taskTimer = New-Object Windows.Threading.DispatcherTimer
    $taskTimer.Interval = [TimeSpan]::FromSeconds(5)
    $taskTimer.Add_Tick({ Update-TaskViewerStatus })
    $taskTimer.Start()

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
    })

    $btnRestartSetup.Add_Click({
        Confirm-SetupAppRunning
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
            Show-VSCodeSymlinkInfo
        }
        catch {
            $txtStatus.Text = "Symlink validation failed: $_"
        }
    })

    # -----------------------------
    # Start Safe Mode
    # -----------------------------
    $btnSafeMode.Add_Click({
        Start-VSCodeSafeMode
    })
    $chkSafeMode.Add_Checked({
        $script:SafeMode = $true
        _out "SAFE MODE ENABLED" "Yellow"
    })

    $chkSafeMode.Add_Unchecked({
        $script:SafeMode = $false
        _out "SAFE MODE DISABLED" "Yellow"
    })

    # -----------------------------
    # Open Dashboard
    # -----------------------------
    $btnDashboard.Add_Click({
        Show-DashboardInTerminal
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
        $taskTimer.Stop()
    })
    $window.Add_Loaded({
        if ($chkSafeMode.IsChecked) {
            _out "SAFE MODE ENABLED" "Yellow"
        }
    })

    # Show window
    $window.ShowDialog() | Out-Null
}
function Update-TaskViewer {
    param([string]$Text)

    $window.Dispatcher.Invoke({
        $txtTaskViewer.AppendText("$Text`n")
        $txtTaskViewer.ScrollToEnd()
    })
}
function Update-TaskViewerStatus {
    $proc = Get-Process -Name "SetupApp" -ErrorAction SilentlyContinue

    # Clear previous output
    $window.Dispatcher.Invoke({
        $txtTaskViewer.Document.Blocks.Clear()
    })

    if ($proc) {
        Write-TaskViewerLine "SetupApp: Running (PID $($proc.Id))" "LightGreen"

        # CPU is cumulative; WorkingSet64 is live memory
        Write-TaskViewerLine ("CPU Time: {0:N2} sec" -f $proc.CPU) "White"
        Write-TaskViewerLine ("Memory: {0:N2} MB" -f ($proc.WorkingSet64 / 1MB)) "White"

        # Status classification
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
function Update-Terminal {
    param([string]$Text)

    $txtCommandOutput.AppendText($Text + "`n")
    $txtCommandOutput.CaretPosition = $txtCommandOutput.Document.ContentEnd
    $txtCommandOutput.ScrollToEnd()
}
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
function Write-Colored {
    param(
        [string]$Text,
        [string]$Color = "White"
    )

    $run = New-Object System.Windows.Documents.Run
    $run.Text = $Text + "`n"
    $run.Foreground = $Color

    $txtCommandOutput.Document.Blocks.Add($run)
    $txtCommandOutput.CaretPosition = $txtCommandOutput.Document.ContentEnd
    $txtCommandOutput.ScrollToEnd()
}
function Write-TaskViewerLine {
    param(
        [string]$Text,
        [string]$Color = "White"
    )

    $window.Dispatcher.Invoke({
        $paragraph = New-Object System.Windows.Documents.Paragraph
        $run = New-Object System.Windows.Documents.Run

        $run.Text = $Text
        $run.Foreground = $Color

        $paragraph.Inlines.Add($run)
        $txtTaskViewer.Document.Blocks.Add($paragraph)
        $txtTaskViewer.ScrollToEnd()
    })
}

Start-VSCodeUpdaterGUI
