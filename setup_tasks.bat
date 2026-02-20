@echo off
chcp 65001 >nul
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
set "TASK_RECORD_WEEKDAY=ScreenRec_Record_Weekdays_AfterTime"
set "TASK_RECORD_WEEKEND=ScreenRec_Record_Weekends_Immediate"
set "TASK_UPLOAD=ScreenRec_Upload_Loop"

REM Legacy task name from previous setup
set "TASK_RECORD_OLD=ScreenRec_Record_OnLogon_AfterTime"

for /f "delims=" %%U in ('whoami') do set "RUN_AS=%%U"

set "VBS_RECORD_WEEKDAY=%SCRIPT_DIR%run_record_hidden.vbs"
set "VBS_RECORD_WEEKEND=%SCRIPT_DIR%run_record_weekend_hidden.vbs"
set "VBS_UPLOAD=%SCRIPT_DIR%run_upload_hidden.vbs"

if not exist "%VBS_RECORD_WEEKDAY%" (
  echo [ERROR] File not found: %VBS_RECORD_WEEKDAY%
  exit /b 1
)

if not exist "%VBS_RECORD_WEEKEND%" (
  echo [ERROR] File not found: %VBS_RECORD_WEEKEND%
  exit /b 1
)

if not exist "%VBS_UPLOAD%" (
  echo [ERROR] File not found: %VBS_UPLOAD%
  exit /b 1
)

REM Clean up legacy single-record task if present
schtasks /Delete /TN "%TASK_RECORD_OLD%" /F >nul 2>&1

echo Creating task: %TASK_RECORD_WEEKDAY%
schtasks /Create /TN "%TASK_RECORD_WEEKDAY%" /TR "wscript.exe \"%VBS_RECORD_WEEKDAY%\"" /SC ONLOGON /RU "%RUN_AS%" /RL LIMITED /IT /F >nul
if errorlevel 1 (
  echo [ERROR] Failed to create %TASK_RECORD_WEEKDAY%
  exit /b 1
)

echo Creating task: %TASK_RECORD_WEEKEND%
schtasks /Create /TN "%TASK_RECORD_WEEKEND%" /TR "wscript.exe \"%VBS_RECORD_WEEKEND%\"" /SC ONLOGON /RU "%RUN_AS%" /RL LIMITED /IT /F >nul
if errorlevel 1 (
  echo [ERROR] Failed to create %TASK_RECORD_WEEKEND%
  exit /b 1
)

echo Creating task: %TASK_UPLOAD%
schtasks /Create /TN "%TASK_UPLOAD%" /TR "wscript.exe \"%VBS_UPLOAD%\"" /SC ONLOGON /RU "%RUN_AS%" /RL LIMITED /IT /F >nul
if errorlevel 1 (
  echo [ERROR] Failed to create %TASK_UPLOAD%
  exit /b 1
)

echo.
echo [OK] Tasks created/updated.
echo - %TASK_RECORD_WEEKDAY% ^(weekday logon; starts after START_AFTER_HHMM^)
echo - %TASK_RECORD_WEEKEND% ^(weekend logon; starts immediately^)
echo - %TASK_UPLOAD%
echo.
echo Time threshold is set in config.bat:
echo   START_AFTER_HHMM=1700

echo To check tasks:
echo   schtasks /Query /TN "%TASK_RECORD_WEEKDAY%" /V /FO LIST
echo   schtasks /Query /TN "%TASK_RECORD_WEEKEND%" /V /FO LIST
echo   schtasks /Query /TN "%TASK_UPLOAD%" /V /FO LIST

endlocal
