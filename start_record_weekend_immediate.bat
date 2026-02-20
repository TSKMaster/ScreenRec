@echo off
chcp 65001 >nul
setlocal

set "SCRIPT_DIR=%~dp0"

for /f %%i in ('powershell -NoProfile -Command "(Get-Date).DayOfWeek.value__"') do set "DOW=%%i"

REM Sunday=0, Saturday=6
if not "%DOW%"=="0" if not "%DOW%"=="6" (
  echo [INFO] Weekday login detected. Weekend task skipped.
  exit /b 0
)

echo [INFO] Weekend login detected. Starting record.bat immediately...
call "%SCRIPT_DIR%record.bat"
exit /b %ERRORLEVEL%
