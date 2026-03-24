@echo off
set SCRIPT_DIR=%~dp0

powershell ^
  -NoProfile ^
  -ExecutionPolicy Bypass ^
  -File "%SCRIPT_DIR%request-sample.ps1"

pause