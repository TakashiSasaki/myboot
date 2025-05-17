<#
  Filename: Show-EnvVarsByCategoryUI.ps1
  Description:
    Display environment variables grouped by introduction category in a tabbed GUI,
    wrap long values, auto-size Name column, fill Value column, keyboard shortcuts for tab navigation,
    and a bottom description panel for the selected variable. This version fixes layout so grids render properly.
#>

# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Classification mapping
$classification = [ordered]@{
    'COMSPEC'    = 'MS-DOS'; 'Path'  = 'MS-DOS'; 'PROMPT' = 'MS-DOS'; 'TEMP'  = 'MS-DOS'; 'TMP' = 'MS-DOS';
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

# 2. Retrieve variables
$envVars = Get-ChildItem Env: | ForEach-Object {
    [PSCustomObject]@{
        Name     = $_.Name
        Value    = $_.Value
        Category = if ($classification.Contains($_.Name)) { $classification[$_.Name] } else { 'Other' }
    }
}

# 3. Ordered category list
$categories = [System.Collections.ArrayList]::new()
$classification.Values | ForEach-Object { if (-not $categories.Contains($_)) { $categories.Add($_) | Out-Null } }
if (-not $categories.Contains('Other')) { $categories.Add('Other') | Out-Null }

# 4. Create Form & SplitContainer
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Environment Variables by Category'
$form.Size = New-Object System.Drawing.Size(900,650)
$form.StartPosition = 'CenterScreen'
$form.KeyPreview = $true

$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = 'Fill'
$split.Orientation = 'Horizontal'
$split.SplitterDistance = 450
$form.Controls.Add($split)

# TabControl in top panel
$tab = New-Object System.Windows.Forms.TabControl
$tab.Dock = 'Fill'
$split.Panel1.Controls.Add($tab)

# Description box in bottom panel
$descBox = New-Object System.Windows.Forms.TextBox
$descBox.Multiline = $true; $descBox.ReadOnly = $true; $descBox.WordWrap = $true; $descBox.ScrollBars = 'Vertical'; $descBox.Dock = 'Fill'
$split.Panel2.Controls.Add($descBox)

# 5. Populate tabs

foreach ($cat in $categories) {
    $page = New-Object System.Windows.Forms.TabPage $cat
    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Dock = 'Fill'; $grid.ReadOnly = $true; $grid.AllowUserToAddRows = $false
    $grid.DefaultCellStyle.WrapMode = [System.Windows.Forms.DataGridViewTriState]::True
    $grid.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells
    $grid.AutoGenerateColumns = $false
    # Define columns
    $colName = [System.Windows.Forms.DataGridViewTextBoxColumn]::new()
    $colName.Name = 'Name'; $colName.HeaderText = 'Name'; $colName.DataPropertyName = 'Name'
    $colName.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
    $colValue= [System.Windows.Forms.DataGridViewTextBoxColumn]::new()
    $colValue.Name='Value'; $colValue.HeaderText='Value'; $colValue.DataPropertyName='Value'
    $colValue.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
    $grid.Columns.AddRange($colName, $colValue)
    # Bind via DataTable
    $dt = New-Object System.Data.DataTable
    $dt.Columns.Add('Name')|Out-Null; $dt.Columns.Add('Value')|Out-Null
    $envVars | Where-Object { $_.Category -eq $cat } | ForEach-Object {
        $r = $dt.NewRow(); $r['Name']=$_.Name; $r['Value']=$_.Value; $dt.Rows.Add($r)
    }
    $grid.DataSource = $dt
    # Selection event
    $grid.Add_SelectionChanged({
        $r = $grid.CurrentRow
        if ($r) { $descBox.Text = "Variable '$($r.Cells['Name'].Value)' = $($r.Cells['Value'].Value)" }
    })
    # Add to tab
    $page.Controls.Add($grid)
    $tab.TabPages.Add($page)
    
}

# 6. Keyboard shortcuts
$form.Add_KeyDown({param($s,$e)
    if ($e.Control -and -not $e.Shift -and $e.KeyCode -eq 'Tab') {
        $tab.SelectedIndex = ($tab.SelectedIndex + 1) % $tab.TabCount; $e.Handled = $true
    } elseif ($e.Control -and $e.Shift -and $e.KeyCode -eq 'Tab') {
        $i=$tab.SelectedIndex-1; if($i -lt 0){$i=$tab.TabCount-1}; $tab.SelectedIndex=$i; $e.Handled=$true
    } elseif ($e.Control -and $e.KeyCode -eq 'PageDown') {
        $tab.SelectedIndex = ($tab.SelectedIndex + 1) % $tab.TabCount; $e.Handled=$true
    } elseif ($e.Control -and $e.KeyCode -eq 'PageUp') {
        $i=$tab.SelectedIndex-1; if($i -lt 0){$i=$tab.TabCount-1}; $tab.SelectedIndex=$i; $e.Handled=$true
    }
})

# 7. Column autosize after show
$form.Add_Shown({foreach($p in $tab.TabPages){$g=$p.Controls[0];if($g.ColumnCount -ge 2){$g.Columns[0].AutoSizeMode=[System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells; $g.Columns[1].AutoSizeMode=[System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill}}})

# Show
[void]$form.ShowDialog()
