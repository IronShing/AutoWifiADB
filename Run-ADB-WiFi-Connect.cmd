@echo off
setlocal
REM Launch the PowerShell script from the user's Downloads\platform-tools folder.

set "SCRIPT=%USERPROFILE%\Downloads\platform-tools\adb_wifi_connect.ps1"

if not exist "%SCRIPT%" (
  echo [!] Could not find "%SCRIPT%"
  echo     Make sure adb_wifi_connect.ps1 is in Downloads\platform-tools
  pause
  exit /b 1
)

REM Pass any extra arguments through to the PowerShell script (e.g., -Serial SERIAL)
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
echo.
pause
