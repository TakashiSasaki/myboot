:: Filename: RunEnvironmentCheck.bat
@echo off
REM ─────────────────────────────────────────
REM  Double-click to download & run check script
REM ─────────────────────────────────────────

set SCRIPT_URL=https://raw.githubusercontent.com/TakashiSasaki/myboot/refs/heads/master/check-environment.ps1

REM PowerShell でリモートスクリプトを取得・実行
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { iwr -UseBasicParsing '%SCRIPT_URL%' | iex } `
   catch { Write-Host 'Failed to download or run the check script.' -ForegroundColor Red; pause }"
