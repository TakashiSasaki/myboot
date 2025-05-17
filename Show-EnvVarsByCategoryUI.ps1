<#
  Filename: Show-EnvVarsByCategoryUI.ps1
  Description: Display environment variables in a tabbed GUI grouped by the Windows version category in which they were introduced,
               with Name column auto-sized to its minimum width, Value column filling remaining space, wrapping long text in Value,
               and keyboard shortcuts (Ctrl+Tab, Ctrl+Shift+Tab, Ctrl+PageUp, Ctrl+PageDown) for tab switching.
#>

# Load Windows Forms and Drawing assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ----------------------------------------
# 1. Classification mapping
# ----------------------------------------
$classification = [ordered]@{
    'COMSPEC'    = 'MS-DOS'; 'Path' = 'MS-DOS'; 'PROMPT' = 'MS-DOS'; 'TEMP' = 'MS-DOS'; 'TMP' = 'MS-DOS';
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

# ----------------------------------------
# 2. Retrieve environment variables
# ----------------------------------------
$envVars = Get-ChildItem Env: | ForEach-Object {
    [PSCustomObject]@{
        Name     = $_.Name
        Value    = $_.Value
        Category = if ($classification.Contains($_.Name)) { $classification[$_.Name] } else { 'Other' }
    }
}

# ----------------------------------------
# 3. Prepare ordered categories list
# ----------------------------------------
$categories = [System.Collections.ArrayList]::new()
foreach ($cat in $classification.Values) {
    if (-not $categories.Contains($cat)) { $categories.Add($cat) | Out-Null }
}
if (-not $categories.Contains('Other')) { $categories.Add('Other') | Out-Null }

# ----------------------------------------
# 4. Build form and TabControl
# ----------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Environment Variables by Category'
$form.Size = New-Object System.Drawing.Size(900, 600)
$form.StartPosition = 'CenterScreen'
$form.KeyPreview = $true

$tab = New-Object System.Windows.Forms.TabControl
$tab.Dock = 'Fill'
$form.Controls.Add($tab)

foreach ($cat in $categories) {
    $page = New-Object System.Windows.Forms.TabPage $cat
    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Dock = 'Fill'
    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    # Wrap and autosize rows
    $grid.DefaultCellStyle.WrapMode = [System.Windows.Forms.DataGridViewTriState]::True
    $grid.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells

    # Build DataTable
    $table = New-Object System.Data.DataTable
    $table.Columns.Add('Name', [string])  | Out-Null
    $table.Columns.Add('Value', [string]) | Out-Null
    foreach ($item in $envVars | Where-Object { $_.Category -eq $cat }) {
        $row = $table.NewRow()
        $row['Name']  = $item.Name
        $row['Value'] = $item.Value
        $table.Rows.Add($row)
    }

    $grid.DataSource = $table
    $page.Controls.Add($grid)
    $tab.TabPages.Add($page)
}

# ----------------------------------------
# 5. Keyboard shortcuts for tab switching
# ----------------------------------------
$form.Add_KeyDown({ param($s,$e)
    if ($e.Control -and -not $e.Shift -and $e.KeyCode -eq 'Tab') {
        $tab.SelectedIndex = ($tab.SelectedIndex + 1) % $tab.TabCount
        $tab.Focus()
        $e.Handled = $true
    } elseif ($e.Control -and $e.Shift -and $e.KeyCode -eq 'Tab') {
        $idx = $tab.SelectedIndex - 1; if ($idx -lt 0) { $idx = $tab.TabCount - 1 }
        $tab.SelectedIndex = $idx; $tab.Focus(); $e.Handled = $true
    } elseif ($e.Control -and $e.KeyCode -eq 'PageDown') {
        $tab.SelectedIndex = ($tab.SelectedIndex + 1) % $tab.TabCount
        $tab.Focus(); $e.Handled = $true
    } elseif ($e.Control -and $e.KeyCode -eq 'PageUp') {
        $idx = $tab.SelectedIndex - 1; if ($idx -lt 0) { $idx = $tab.TabCount - 1 }
        $tab.SelectedIndex = $idx; $tab.Focus(); $e.Handled = $true
    }
})

# ----------------------------------------
# 6. Adjust column sizing after form is shown
# ----------------------------------------
$form.Add_Shown({
    foreach ($page in $tab.TabPages) {
        $grid = $page.Controls | Where-Object { $_ -is [System.Windows.Forms.DataGridView] }
        if ($grid.ColumnCount -ge 2) {
            $grid.Columns[0].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
            $grid.Columns[1].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
        }
    }
})

# Show form
[void]$form.ShowDialog()