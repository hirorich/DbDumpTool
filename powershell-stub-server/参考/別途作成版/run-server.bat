@echo off
set SCRIPT_DIR=%~dp0

powershell ^
  -NoProfile ^
  -ExecutionPolicy Bypass ^
  -File "%SCRIPT_DIR%stub-server.ps1"

pause