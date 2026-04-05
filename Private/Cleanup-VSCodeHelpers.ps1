function Cleanup-VSCodeHelpers {
    Write-Log "[CLEANUP] Checking for VS Code and installer helper processes"

    $targets = @(
        "Code",
        "CodeHelper",
        "CodeHelperCP",
        "CodeHelperRenderer",
        "CodeHelperWebView",
        "CodeHelperGPU",
        "CodeSetup",
        "Setup",
        "Uninstall",
        "VSCodeSetup",
        "VSCodeSetup.tmp"
    )

    foreach ($t in $targets) {
        $procs = Get-Process -Name $t -ErrorAction SilentlyContinue
        if ($procs) {
            Write-Log "[CLEANUP] Terminating $t PIDs: $($procs.Id -join ', ')"
            $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    }
}
