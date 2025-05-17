<#  
  Filename: check-environment.ps1  
  Description: Detect and display whether this machine is running Windows 10 or Windows 11, and show PowerShell version  
#>

# Get operating system information
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# Parse version into a [Version] object
$version = [version]$os.Version

# Determine OS name
if ($version.Major -eq 10) {
    # Windows 10 up through build 21999; Windows 11 starts at build 22000
    if ($version.Build -lt 22000) {
        $osName = 'Windows 10'
    } else {
        $osName = 'Windows 11'
    }
}
elseif ($version.Major -gt 10) {
    # Future major versions—treat as Windows 11 or later
    $osName = 'Windows 11 or later'
}
else {
    $osName = "Unknown Windows Version ($($os.Version))"
}

# Output OS version result
Write-Host "Detected OS Version: $osName" -ForegroundColor Cyan

# Output PowerShell version
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
