@echo off
REM ─────────────────────────────────────────
REM   RunEnvironmentCheck.bat
REM   Downloads and runs check-environment.ps1 via PowerShell
REM ─────────────────────────────────────────

set "SCRIPT_URL=https://raw.githubusercontent.com/TakashiSasaki/myboot/refs/heads/master/check-environment.ps1

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Invoke-WebRequest -UseBasicParsing '%SCRIPT_URL%' | Invoke-Expression } catch { Write-Host 'Failed to download or run the check script.' -ForegroundColor Red; Pause }"
