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

    if ($global:txtCommandOutput) {
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

    $global:window.Dispatcher.Invoke({
        if (-not $txtCommandOutput.Document) {
            $txtCommandOutput.Document = New-Object System.Windows.Documents.FlowDocument
        }

        $paragraph = New-Object System.Windows.Documents.Paragraph
        $paragraph.Margin = [System.Windows.Thickness]::new(0)

        $run = New-Object System.Windows.Documents.Run
        $run.Text = $Text
        $run.Foreground = $Color

        $paragraph.Inlines.Add($run)

        # ⭐ Add new lines at the top instead of the bottom
        $txtCommandOutput.Document.Blocks.InsertBefore(
            $txtCommandOutput.Document.Blocks.FirstBlock,
            $paragraph
        )

        # ⭐ Keep the caret at the start so the newest line is visible
        $txtCommandOutput.CaretPosition = $txtCommandOutput.Document.ContentStart
        $txtCommandOutput.ScrollToHome()
        $txtCommandOutput.UpdateLayout()
    })
}
