<#
  Filename: Show-EnvVarsByCategoryUI.ps1
  Description:
    Display environment variables grouped by introduction category in a tabbed GUI
    with wrapped values, autosized Name column, Value column fill, keyboard shortcuts,
    and a bottom description panel.
#>

# Load assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Classification and descriptions
$classification = [ordered]@{
    'COMSPEC' = 'MS-DOS'; 'Path' = 'MS-DOS'; 'PROMPT' = 'MS-DOS'; 'TEMP' = 'MS-DOS'; 'TMP' = 'MS-DOS';
    'ProgramFiles' = 'Windows 3.x/95'; 'windir' = 'Windows 3.x/95';
    'COMPUTERNAME' = 'Windows NT 3.x+'; 'HOMEDRIVE' = 'Windows NT 3.x+'; 'HOMEPATH' = 'Windows NT 3.x+';
    'OS' = 'Windows NT 3.x+'; 'SystemDrive' = 'Windows NT 3.x+'; 'SystemRoot' = 'Windows NT 3.x+';
    'USERDOMAIN' = 'Windows NT 3.x+'; 'USERDOMAIN_ROAMINGPROFILE' = 'Windows NT 3.x+'; 'USERNAME' = 'Windows NT 3.x+';
    'USERPROFILE' = 'Windows NT 3.x+'; 'PATHEXT' = 'Windows NT 4.0+';
    'ALLUSERSPROFILE' = 'Windows 2000+'; 'APPDATA' = 'Windows 2000+'; 'CommonProgramFiles' = 'Windows 2000+';
    'SESSIONNAME' = 'Windows 2000+'; 'LOGONSERVER' = 'Windows 2000+'; 'NUMBER_OF_PROCESSORS' = 'Windows 2000+';
    'ProgramData' = 'Windows Vista+'; 'LOCALAPPDATA' = 'Windows Vista+'; 'PUBLIC' = 'Windows Vista+';
    'PSModulePath' = 'Windows 7+';
    'CommonProgramFiles(x86)' = '64-bit edition'; 'CommonProgramW6432' = '64-bit edition';
    'ProgramFiles(x86)' = '64-bit edition'; 'ProgramW6432' = '64-bit edition';
}
$descriptions = @{
    'COMSPEC' = 'The path to the command interpreter (cmd.exe).';
    'Path' = 'Directories to search for executables.';
    'PROMPT' = 'Command prompt format.';
    'TEMP' = 'Temporary files folder.';
    'TMP' = 'Temporary files folder.';
    'ProgramFiles' = 'Default 64-bit program install dir.';
    'windir' = 'Windows installation dir.';
    'COMPUTERNAME' = 'This PC name.';
    'HOMEDRIVE' = 'User home drive letter.';
    'HOMEPATH' = 'User home path.';
    'OS' = 'Operating system name.';
    'SystemDrive' = 'System installation drive.';
    'SystemRoot' = 'Windows system folder.';
    'USERDOMAIN' = 'User domain name.';
    'USERDOMAIN_ROAMINGPROFILE' = 'Roaming profile domain.';
    'USERNAME' = 'Current user name.';
    'USERPROFILE' = 'User profile folder.';
    'PATHEXT' = 'Executable file extensions.';
    'ALLUSERSPROFILE' = 'All Users profile folder.';
    'APPDATA' = 'Roaming app data folder.';
    'CommonProgramFiles' = 'Common files folder.';
    'SESSIONNAME' = 'Console or RDP session.';
    'LOGONSERVER' = 'Authenticating domain controller.';
    'NUMBER_OF_PROCESSORS' = 'CPU cores count.';
    'ProgramData' = 'All Users program data folder.';
    'LOCALAPPDATA' = 'Local app data folder.';
    'PUBLIC' = 'Public user folder.';
    'PSModulePath' = 'PowerShell module directories.';
    'CommonProgramFiles(x86)' = '32-bit apps on 64-bit.';
    'CommonProgramW6432' = '64-bit apps folder.';
    'ProgramFiles(x86)' = '32-bit program install dir.';
    'ProgramW6432' = '64-bit program install dir.';
}

# 2. Gather variables
$envVars = Get-ChildItem Env: | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.Name; Value = $_.Value;
        Category = if ($classification.Contains($_.Name)) { $classification[$_.Name] } else { 'Other' }
    }
}
# 3. Category order
$categories = [System.Collections.ArrayList]::new()
$classification.Values | ForEach-Object { if (!$categories.Contains($_)) { $categories.Add($_) | Out-Null } }
if (!$categories.Contains('Other')) { $categories.Add('Other') | Out-Null }

# 4. Form and panels
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Environment Variables by Category'
$form.Size = New-Object System.Drawing.Size(900,650)
$form.StartPosition = 'CenterScreen'
$form.KeyPreview = $true
$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = 'Fill'; $split.Orientation = 'Horizontal'; $split.SplitterDistance = 450
$form.Controls.Add($split)

# TabControl
$tab = New-Object System.Windows.Forms.TabControl
$tab.Dock = 'Fill'
$split.Panel1.Controls.Add($tab)
# Description box
$descBox = New-Object System.Windows.Forms.TextBox
$descBox.Multiline = $true; $descBox.ReadOnly = $true; $descBox.WordWrap = $true
$descBox.ScrollBars = 'Vertical'; $descBox.Dock = 'Fill'
$split.Panel2.Controls.Add($descBox)

# 5. Populate tabs
foreach ($cat in $categories) {
    $page = New-Object System.Windows.Forms.TabPage $cat
    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Dock = 'Fill'; $grid.ReadOnly = $true; $grid.AllowUserToAddRows = $false
    $grid.DefaultCellStyle.WrapMode = [System.Windows.Forms.DataGridViewTriState]::True
    $grid.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells
    $grid.AutoGenerateColumns = $false
    # Columns
    $colN = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colN.Name='Name'; $colN.HeaderText='Name'; $colN.DataPropertyName='Name'; $colN.AutoSizeMode=[System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
    $colV = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colV.Name='Value'; $colV.HeaderText='Value'; $colV.DataPropertyName='Value'; $colV.AutoSizeMode=[System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
    $grid.Columns.AddRange($colN,$colV)
    # Bind via DataTable
    $dt = New-Object System.Data.DataTable
    $dt.Columns.Add('Name')|Out-Null; $dt.Columns.Add('Value')|Out-Null
    $envVars | Where-Object { $_.Category -eq $cat } | ForEach-Object {
        $r = $dt.NewRow(); $r['Name']=$_.Name; $r['Value']=$_.Value; $dt.Rows.Add($r)
    }
    $grid.DataSource = $dt
    # Selection changed updates desc
    $grid.Add_SelectionChanged({ param($s,$e)
        $r = $s.CurrentRow
        if ($r) {
            $n = $r.Cells['Name'].Value; $v = $r.Cells['Value'].Value
            $d = if ($descriptions.ContainsKey($n)) { $descriptions[$n] } else { 'No description available.' }
            $descBox.Text = "Variable: $n`r`nValue: $v`r`nDescription: $d"
        }
    })
    $page.Controls.Add($grid)
    $tab.TabPages.Add($page)
}

# 6. Shortcut keys
$form.Add_KeyDown({ param($s,$e)
    if ($e.Control -and !$e.Shift -and $e.KeyCode -eq 'Tab') { $tab.SelectedIndex=($tab.SelectedIndex+1)%$tab.TabCount; $e.Handled=$true }
    elseif ($e.Control -and $e.Shift -and $e.KeyCode -eq 'Tab') { $i=$tab.SelectedIndex-1; if ($i -lt 0){$i=$tab.TabCount-1}; $tab.SelectedIndex=$i; $e.Handled=$true }
    elseif ($e.Control -and $e.KeyCode -eq 'PageDown') { $tab.SelectedIndex=($tab.SelectedIndex+1)%$tab.TabCount; $e.Handled=$true }
    elseif ($e.Control -and $e.KeyCode -eq 'PageUp') { $i=$tab.SelectedIndex-1; if ($i -lt 0) {$i=$tab.TabCount-1}; $tab.SelectedIndex=$i; $e.Handled=$true }
})

# 7. Autosize on show
$form.Add_Shown({ foreach($p in $tab.TabPages){ $g=$p.Controls[0]; if($g.ColumnCount -ge 2){ $g.Columns[0].AutoSizeMode=[System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells; $g.Columns[1].AutoSizeMode=[System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill } } })

# Show form
[void]$form.ShowDialog()
