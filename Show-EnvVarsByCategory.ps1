<#
  Filename: Show-EnvVarsByCategory.ps1
  Description: Display environment variables categorized by the Windows version in which they were introduced.
#>

# ----------------------------------------
# 1. Classification mapping
# ----------------------------------------
$classification = @{
    # MS-DOS era
    'COMSPEC'    = 'MS-DOS'
    'Path'       = 'MS-DOS'
    'PROMPT'     = 'MS-DOS'
    'TEMP'       = 'MS-DOS'
    'TMP'        = 'MS-DOS'

    # Windows 3.x / 95 era
    'ProgramFiles' = 'Windows 3.x/95'
    'windir'       = 'Windows 3.x/95'

    # Windows NT 3.x+
    'COMPUTERNAME'                = 'Windows NT 3.x+'
    'HOMEDRIVE'                   = 'Windows NT 3.x+'
    'HOMEPATH'                    = 'Windows NT 3.x+'
    'OS'                          = 'Windows NT 3.x+'
    'SystemDrive'                 = 'Windows NT 3.x+'
    'SystemRoot'                  = 'Windows NT 3.x+'
    'USERDOMAIN'                  = 'Windows NT 3.x+'
    'USERDOMAIN_ROAMINGPROFILE'   = 'Windows NT 3.x+'
    'USERNAME'                    = 'Windows NT 3.x+'
    'USERPROFILE'                 = 'Windows NT 3.x+'

    # Windows NT 4.0+
    'PATHEXT' = 'Windows NT 4.0+'

    # Windows 2000+
    'ALLUSERSPROFILE'    = 'Windows 2000+'
    'APPDATA'            = 'Windows 2000+'
    'CommonProgramFiles' = 'Windows 2000+'
    'SESSIONNAME'        = 'Windows 2000+'
    'LOGONSERVER'        = 'Windows 2000+'
    'NUMBER_OF_PROCESSORS' = 'Windows 2000+'

    # Windows Vista+
    'ProgramData'   = 'Windows Vista+'
    'LOCALAPPDATA'  = 'Windows Vista+'
    'PUBLIC'        = 'Windows Vista+'

    # Windows 7+
    'PSModulePath' = 'Windows 7+'

    # 64-bit editions
    'CommonProgramFiles(x86)' = '64-bit edition'
    'CommonProgramW6432'      = '64-bit edition'
    'ProgramFiles(x86)'       = '64-bit edition'
    'ProgramW6432'            = '64-bit edition'
}

# ----------------------------------------
# 2. Retrieve and annotate environment variables
# ----------------------------------------
$envVars = Get-ChildItem Env: | ForEach-Object {
    [PSCustomObject]@{
        Name     = $_.Name
        Value    = $_.Value
        Category = if ($classification.ContainsKey($_.Name)) {
                       $classification[$_.Name]
                   } else {
                       'Other'
                   }
    }
}

# ----------------------------------------
# 3. Display logic
# ----------------------------------------
if (Get-Command Out-GridView -ErrorAction SilentlyContinue) {
    # GUI mode: sort by Category & Name, then show in grid
    $envVars |
        Sort-Object Category,Name |
        Out-GridView -Title 'Environment Variables by Category (sorted)'
}
else {
    # Console fallback: TUI-like grouped tables
    $envVars |
        Group-Object -Property Category |
        ForEach-Object {
            Write-Host "`n=== $($_.Name) ===" -ForegroundColor Yellow
            $_.Group | Format-Table Name,Value -AutoSize
        }
}
