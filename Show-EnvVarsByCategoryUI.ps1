<#  
  Filename: Show-EnvVarsByCategoryUI.ps1  
  Description:  
    This script launches a Windows Forms GUI to display all environment variables  
    categorized by the Windows version or context in which they were introduced. It  
    organizes variables into tabs based on their classification (e.g., MS-DOS, Win7+,  
    64-bit edition, etc.). Each tab contains a DataGridView with two columns:  
      • "Name": auto-sized to the minimum width needed to fit its content.  
      • "Value": fills the remaining horizontal space, with text wrapping and  
        row heights automatically adjusted to accommodate long entries.  
    Users can navigate between tabs using standard shortcuts (Ctrl+Tab, Ctrl+Shift+Tab,  
    Ctrl+PageUp, Ctrl+PageDown). Selecting a row in the grid populates a read-only  
    description panel at the bottom, showing:  
      • The variable name  
      • Its current value  
      • A detailed human-readable description explaining the variable's purpose  
        and typical usage.  
    This script provides an interactive way to explore environment settings,  
    understand their origins, and view explanatory context without resorting to  
    command-line output.  
#>

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
    'COMSPEC'    = 'The path to the command interpreter (cmd.exe), used when launching command prompts and batch scripts.'
    'Path'       = 'A semicolon-separated list of directories where executables are searched when you run commands without absolute paths.'
    'PROMPT'     = 'Defines the appearance of the command prompt (default: $P$G shows current drive and path).'
    'TEMP'       = 'Directory for temporary files used by applications and Windows services.'
    'TMP'        = 'Synonym for TEMP; also specifies the location for temporary files.'
    'ProgramFiles' = 'Default directory for installing 64-bit applications on the system.'
    'windir'     = 'The root folder where Windows is installed.'
    'COMPUTERNAME' = 'The network name of this computer.'
    'HOMEDRIVE'  = 'Drive letter of the user''s home directory.'
    'HOMEPATH'   = 'Path of the user''s home directory relative to HOMEDRIVE.'
    'OS'         = 'The operating system family (typically Windows_NT).'
    'SystemDrive'= 'Drive on which the OS is installed.'
    'SystemRoot' = 'Windows system folder (e.g., C:\WINDOWS).'
    'USERDOMAIN' = 'Domain or workgroup of the current user account.'
    'USERDOMAIN_ROAMINGPROFILE' = 'Roaming profile domain for the user.'
    'USERNAME'   = 'Name of the user currently logged on.'
    'USERPROFILE'= 'Root directory of the user profile.'
    'PATHEXT'    = 'List of file extensions that Windows considers executable.'
    'ALLUSERSPROFILE' = 'Directory for application data available to all users.'
    'APPDATA'    = 'Roaming application data folder for the current user.'
    'CommonProgramFiles' = 'Folder for shared program files (e.g., libraries).'
    'SESSIONNAME' = 'Console or RDP session type.'
    'LOGONSERVER'= 'Domain controller that authenticated this logon.'
    'NUMBER_OF_PROCESSORS' = 'Number of logical processors on the system.'
    'ProgramData' = 'Directory for application data shared by all users.'
    'LOCALAPPDATA' = 'Local (non-roaming) application data folder.'
    'PUBLIC'     = 'Public user profile folder accessible by all users.'
    'PSModulePath' = 'Paths where PowerShell modules are installed.'
    'CommonProgramFiles(x86)' = 'Shared files for 32-bit apps on 64-bit Windows.'
    'CommonProgramW6432'      = 'Shared files for 64-bit apps.'
    'ProgramFiles(x86)'       = 'Default install directory for 32-bit programs on 64-bit Windows.'
    'ProgramW6432'            = 'Default install directory for 64-bit programs.'
}

# 2. Gather environment variables
$envVars = Get-ChildItem Env: | ForEach-Object {
    [PSCustomObject]@{
        Name     = $_.Name
        Value    = $_.Value
        Category = if ($classification.Contains($_.Name)) { $classification[$_.Name] } else { 'Other' }
    }
}

# 3. Determine ordered categories
$categories = [System.Collections.ArrayList]::new()
$classification.Values | ForEach-Object {
    if (-not $categories.Contains($_)) { $categories.Add($_) | Out-Null }
}
if (-not $categories.Contains('Other')) { $categories.Add('Other') | Out-Null }

# 4. Build the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Environment Variables by Category'
$form.Size = New-Object System.Drawing.Size(900,650)
$form.StartPosition = 'CenterScreen'
$form.KeyPreview = $true

# SplitContainer for grid vs. description
$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = 'Fill'
$split.Orientation = 'Horizontal'
$split.SplitterDistance = 450
$form.Controls.Add($split)

# TabControl in top panel
$tab = New-Object System.Windows.Forms.TabControl
$tab.Dock = 'Fill'
$split.Panel1.Controls.Add($tab)

# Description TextBox in bottom panel
$descBox = New-Object System.Windows.Forms.TextBox
$descBox.Multiline = $true
$descBox.ReadOnly = $true
$descBox.WordWrap = $true
$descBox.ScrollBars = 'Vertical'
$descBox.Dock = 'Fill'
$split.Panel2.Controls.Add($descBox)

# 5. Populate tabs with DataGridView
foreach ($cat in $categories) {
    $page = New-Object System.Windows.Forms.TabPage $cat
    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Dock = 'Fill'
    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    $grid.DefaultCellStyle.WrapMode = [System.Windows.Forms.DataGridViewTriState]::True
    $grid.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells
    $grid.AutoGenerateColumns = $false

    # Name column
    $colName = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colName.Name = 'Name'
    $colName.HeaderText = 'Name'
    $colName.DataPropertyName = 'Name'
    $colName.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells

    # Value column
    $colValue = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colValue.Name = 'Value'
    $colValue.HeaderText = 'Value'
    $colValue.DataPropertyName = 'Value'
    $colValue.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill

    $grid.Columns.AddRange($colName, $colValue)

    # Bind data via DataTable
    $dt = New-Object System.Data.DataTable
    $dt.Columns.Add('Name') | Out-Null
    $dt.Columns.Add('Value') | Out-Null
    $envVars | Where-Object { $_.Category -eq $cat } | ForEach-Object {
        $r = $dt.NewRow()
        $r['Name'] = $_.Name
        $r['Value'] = $_.Value
        $dt.Rows.Add($r)
    }
    $grid.DataSource = $dt

    # Selection change event for description
    $grid.Add_SelectionChanged({
        param($sender, $e)
        $r = $sender.CurrentRow
        if ($r) {
            $n = $r.Cells['Name'].Value
            $v = $r.Cells['Value'].Value
            $d = if ($descriptions.ContainsKey($n)) { $descriptions[$n] } else { 'No description available.' }
            $descBox.Text = "Variable: $n`r`nValue: $v`r`nDescription: $d"
        }
    })

    $page.Controls.Add($grid)
    $tab.TabPages.Add($page)
}

# 6. Keyboard shortcuts for tab navigation with immediate focus
$form.Add_KeyDown({
    param($s, $e)
    if ($e.Control -and -not $e.Shift -and $e.KeyCode -eq 'Tab') {
        $tab.SelectedIndex = ($tab.SelectedIndex + 1) % $tab.TabCount
        $tab.Focus()
        $e.Handled = $true
    }
    elseif ($e.Control -and $e.Shift -and $e.KeyCode -eq 'Tab') {
        $i = $tab.SelectedIndex - 1
        if ($i -lt 0) { $i = $tab.TabCount - 1 }
        $tab.SelectedIndex = $i
        $tab.Focus()
        $e.Handled = $true
    }
    elseif ($e.Control -and $e.KeyCode -eq 'PageDown') {
        $tab.SelectedIndex = ($tab.SelectedIndex + 1) % $tab.TabCount
        $tab.Focus()
        $e.Handled = $true
    }
    elseif ($e.Control -and $e.KeyCode -eq 'PageUp') {
        $i = $tab.SelectedIndex - 1
        if ($i -lt 0) { $i = $tab.TabCount - 1 }
        $tab.SelectedIndex = $i
        $tab.Focus()
        $e.Handled = $true
    }
})

# 7. Auto-size columns after form is shown
$form.Add_Shown({
    foreach ($page in $tab.TabPages) {
        $grid = $page.Controls[0]
        if ($grid.ColumnCount -ge 2) {
            $grid.Columns[0].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
            $grid.Columns[1].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
        }
    }
})

# Show the form
[void]$form.ShowDialog()
