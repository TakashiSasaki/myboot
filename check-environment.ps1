<#  
  Filename: check-environment.ps1  
  Description:  
    Detect and display Windows OS version (Win10/Win11),  
    PowerShell version, and current user's Desktop directory path (using Windows API)  
#>

# Get operating system information
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# Parse version into a [Version] object
$version = [version]$os.Version

# Determine OS name
if ($version.Major -eq 10) {
    if ($version.Build -lt 22000) {
        $osName = 'Windows 10'
    } else {
        $osName = 'Windows 11'
    }
}
elseif ($version.Major -gt 10) {
    $osName = 'Windows 11 or later'
}
else {
    $osName = "Unknown Windows Version ($($os.Version))"
}

Write-Host "Detected OS Version: $osName" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan

# Get Desktop path using Windows API via .NET
$desktopPath = [Environment]::GetFolderPath('Desktop')
Write-Host "User Desktop Directory: $desktopPath" -ForegroundColor Cyan
