<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-04
    Modified: 2026-07-04
    File: OutputHelpers.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function _out {
    param([string]$msg, [string]$color = "White")

    Write-Log $msg

    if ($global:txtCommandOutput -and $global:window) {
        Write-TerminalLine $msg $color
    }
    else {
        Write-Host $msg
    }
}

function Write-TerminalLine {
    param(
        [string]$Text,
        [string]$Color = "White"
    )

    # CLI fallback if GUI not ready
    if (-not $global:window -or -not $global:txtCommandOutput) {
        Write-Host $Text
        return
    }

    $global:window.Dispatcher.Invoke({
        if (-not $txtCommandOutput.Document) {
            $txtCommandOutput.Document = New-Object System.Windows.Documents.FlowDocument
        }

        $paragraph = New-Object System.Windows.Documents.Paragraph
        $paragraph.Margin = [System.Windows.Thickness]::new(0)

        $run = New-Object System.Windows.Documents.Run
        $run.Text = $Text

        # Safe color conversion
        try {
            $brush = [System.Windows.Media.Brushes]::$Color
            $run.Foreground = $brush
        }
        catch {
            $run.Foreground = [System.Windows.Media.Brushes]::White
        }

        $paragraph.Inlines.Add($run)

        $txtCommandOutput.Document.Blocks.Add($paragraph)
        $txtCommandOutput.CaretPosition = $txtCommandOutput.Document.ContentEnd
        $txtCommandOutput.ScrollToEnd()
        $txtCommandOutput.UpdateLayout()
    })
}
