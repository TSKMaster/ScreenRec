@echo off
chcp 65001 >nul
setlocal

set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%config.bat" call "%SCRIPT_DIR%config.bat"

for /f %%i in ('powershell -NoProfile -Command "(Get-Date).DayOfWeek.value__"') do set "DOW=%%i"

REM Sunday=0, Monday=1, ... Friday=5, Saturday=6
if "%DOW%"=="0" (
  echo [INFO] Weekend login detected. Weekday task skipped.
  exit /b 0
)
if "%DOW%"=="6" (
  echo [INFO] Weekend login detected. Weekday task skipped.
  exit /b 0
)

if not defined START_AFTER_HHMM set "START_AFTER_HHMM=1700"

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format HHmm"') do set "NOW_HHMM=%%i"

echo [INFO] Current time: %NOW_HHMM%
echo [INFO] Start threshold: %START_AFTER_HHMM%

if %NOW_HHMM% LSS %START_AFTER_HHMM% (
  echo [INFO] Too early. record.bat will not start.
  exit /b 0
)

echo [INFO] Time check passed. Starting record.bat...
call "%SCRIPT_DIR%record.bat"
exit /b %ERRORLEVEL%
