@echo off
chcp 65001 >nul
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
set "TASK_RECORD=ScreenRec_Record_OnLogon_AfterTime"
set "TASK_UPLOAD=ScreenRec_Upload_Loop"

for /f "delims=" %%U in ('whoami') do set "RUN_AS=%%U"

set "VBS_RECORD=%SCRIPT_DIR%run_record_hidden.vbs"
set "VBS_UPLOAD=%SCRIPT_DIR%run_upload_hidden.vbs"

if not exist "%VBS_RECORD%" (
  echo [ERROR] File not found: %VBS_RECORD%
  exit /b 1
)

if not exist "%VBS_UPLOAD%" (
  echo [ERROR] File not found: %VBS_UPLOAD%
  exit /b 1
)

echo Creating task: %TASK_RECORD%
schtasks /Create /TN "%TASK_RECORD%" /TR "wscript.exe \"%VBS_RECORD%\"" /SC ONLOGON /RU "%RUN_AS%" /RL LIMITED /IT /F >nul
if errorlevel 1 (
  echo [ERROR] Failed to create %TASK_RECORD%
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
echo - %TASK_RECORD%
echo - %TASK_UPLOAD%
echo.
echo Time threshold is set in config.bat:
echo   START_AFTER_HHMM=1700

echo To check tasks:
echo   schtasks /Query /TN "%TASK_RECORD%" /V /FO LIST
echo   schtasks /Query /TN "%TASK_UPLOAD%" /V /FO LIST

endlocal
