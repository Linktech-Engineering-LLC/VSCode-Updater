Describe 'Get-SelectedVersionName' {
    It 'returns the selected version name from the DataGrid' {
        $grid = [pscustomobject]@{ SelectedItem = [pscustomobject]@{ Name = 'VSCode-1.92.0' } }

        $result = Get-SelectedVersionName -DataGrid $grid

        $result | Should -Be 'VSCode-1.92.0'
    }

    It 'returns null when nothing is selected' {
        $grid = [pscustomobject]@{ SelectedItem = $null }

        $result = Get-SelectedVersionName -DataGrid $grid

        $result | Should -BeNullOrEmpty
    }
}
