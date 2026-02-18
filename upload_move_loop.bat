@echo off
chcp 65001 >nul
setlocal

set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%config.bat" call "%SCRIPT_DIR%config.bat"
if not defined UPLOAD_INTERVAL_SEC set "UPLOAD_INTERVAL_SEC=120"

:loop
call "%SCRIPT_DIR%upload_move_once.bat"
if errorlevel 1 echo [WARN] Upload attempt failed; retrying in %UPLOAD_INTERVAL_SEC%s

timeout /t %UPLOAD_INTERVAL_SEC% /nobreak >nul
goto loop
