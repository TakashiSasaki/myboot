<#  
  Filename: Show-EnvVarsByCategoryUI.ps1  
  Description:  
    This script launches a Windows Forms GUI to display all environment variables  
    categorized by the Windows version or context in which they were introduced. It  
    organizes variables into tabs based on their classification (e.g., MS-DOS, Win7+,  
    64-bit edition, etc.). Each tab contains a DataGridView with two columns:  
      • "Name": auto-sized to the minimum width needed to fit its content, with user-specific variables highlighted.  
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
    'USERNAME' = 'Name of the user currently logged on, varies per account.'
    'USERPROFILE' = 'Root directory of the user profile (e.g., C:\Users\takas), unique per user.'
    'HOMEDRIVE' = 'Drive letter of the user''s home directory (combines with HOMEPATH). Varies per user.'
    'HOMEPATH' = 'Path of the user''s home directory relative to HOMEDRIVE. Varies per user.'
    'APPDATA' = 'Roaming application data folder for the current user (e.g., C:\Users\takas\AppData\Roaming). Varies per user.'
    'LOCALAPPDATA' = 'Local (non-roaming) application data folder (e.g., C:\Users\takas\AppData\Local). Varies per user.'
    'TEMP' = 'Directory for temporary files under the user''s profile. Varies per user.'
    'TMP' = 'Synonym for TEMP; also specifies temporary files location. Varies per user.'
    'Path' = 'Includes system and user-specific entries. Final value differs per user.'
    'PSModulePath' = 'Paths for PowerShell modules, includes user''s Documents\PowerShell\Modules. Varies per user.'
    'OneDrive' = 'Path to the user''s OneDrive directory, varies per user.'
    'OneDriveCommercial' = 'Path to the user''s business OneDrive directory, varies per user.'
    'OneDriveConsumer' = 'Path to the user''s personal OneDrive directory, varies per user.'
    'VSCODE_GIT_ASKPASS_MAIN' = 'Path to VS Code''s Git askpass script for the user.'
    'VSCODE_GIT_ASKPASS_NODE' = 'Node executable path used by VS Code for Git operations, user-specific.'
    'VSCODE_GIT_ASKPASS_EXTRA_ARGS' = 'Additional arguments for VS Code''s Git askpass, user-specific.'
    'ChocolateyLastPathUpdate' = 'Timestamp when Chocolatey last updated the user''s PATH, unique per user.'
    # Add other descriptions as needed...
}
# Define user-specific variables for highlighting
$userSpecific = $descriptions.Keys

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

    # Highlight user-specific Name cells
    $grid.Add_CellFormatting({ param($sender,$e)
        if ($e.ColumnIndex -eq $sender.Columns['Name'].Index) {
            $val = $sender.Rows[$e.RowIndex].Cells[$e.ColumnIndex].Value
            if ($userSpecific -contains $val) {
                $e.CellStyle.BackColor = [System.Drawing.Color]::LightYellow
            }
        }
    })

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
    $grid.Add_SelectionChanged({ param($sender, $e)
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
    } elseif ($e.Control -and $e.Shift -and $e.KeyCode -eq 'Tab') {
        $i = $tab.SelectedIndex - 1; if ($i -lt 0) { $i = $tab.TabCount - 1 }
        $tab.SelectedIndex = $i
        $tab.Focus()
        $e.Handled = $true
    } elseif ($e.Control -and $e.KeyCode -eq 'PageDown') {
        $tab.SelectedIndex = ($tab.SelectedIndex + 1) % $tab.TabCount
        $tab.Focus()
        $e.Handled = $true
    } elseif ($e.Control -and $e.KeyCode -eq 'PageUp') {
        $i = $tab.SelectedIndex - 1; if ($i -lt 0) { $i = $tab.TabCount - 1 }
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
