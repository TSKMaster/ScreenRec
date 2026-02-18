@echo off
chcp 65001 >nul
setlocal

set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%config.bat" call "%SCRIPT_DIR%config.bat"

if not defined OUTDIR set "OUTDIR=C:\rec"
if not defined REMOTE_BASE set "REMOTE_BASE=nas:records"
if not defined UPLOAD_MIN_AGE set "UPLOAD_MIN_AGE=3m"
if not defined RCLONE_TRANSFERS set "RCLONE_TRANSFERS=4"
if not defined RCLONE_CHECKERS set "RCLONE_CHECKERS=4"
if not defined RCLONE_RETRIES set "RCLONE_RETRIES=10"
if not defined RCLONE_LOW_LEVEL_RETRIES set "RCLONE_LOW_LEVEL_RETRIES=10"
if not defined CLEAN_EMPTY_DIRS set "CLEAN_EMPTY_DIRS=1"
if not defined RCLONE_EXE set "RCLONE_EXE=%SCRIPT_DIR%Rclone\rclone.exe"
if not defined RCLONE_CONFIG set "RCLONE_CONFIG=%SCRIPT_DIR%Rclone\rclone.conf"

set "RCLONE_CMD="
if exist "%RCLONE_EXE%" (
  set "RCLONE_CMD=%RCLONE_EXE%"
) else (
  where rclone >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] rclone not found: "%RCLONE_EXE%" and not in PATH.
    exit /b 1
  )
  set "RCLONE_CMD=rclone"
)

set "SRCDIR=%OUTDIR%"
set "PC=%COMPUTERNAME%"
set "REMOTE=%REMOTE_BASE%/%PC%"
set "LOGDIR=%OUTDIR%\logs"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "D=%%i"
set "LOGFILE=%LOGDIR%\rclone_move_%D%.log"

if exist "%RCLONE_CONFIG%" (
  "%RCLONE_CMD%" --config "%RCLONE_CONFIG%" mkdir "%REMOTE%" >nul 2>&1
  "%RCLONE_CMD%" --config "%RCLONE_CONFIG%" move "%SRCDIR%" "%REMOTE%" ^
    --min-age %UPLOAD_MIN_AGE% ^
    --include "*/**.mkv" ^
    --exclude "logs/**" ^
    --retries %RCLONE_RETRIES% --low-level-retries %RCLONE_LOW_LEVEL_RETRIES% ^
    --transfers %RCLONE_TRANSFERS% --checkers %RCLONE_CHECKERS% ^
    --log-file "%LOGFILE%" --log-level INFO
) else (
  "%RCLONE_CMD%" mkdir "%REMOTE%" >nul 2>&1
  "%RCLONE_CMD%" move "%SRCDIR%" "%REMOTE%" ^
    --min-age %UPLOAD_MIN_AGE% ^
    --include "*/**.mkv" ^
    --exclude "logs/**" ^
    --retries %RCLONE_RETRIES% --low-level-retries %RCLONE_LOW_LEVEL_RETRIES% ^
    --transfers %RCLONE_TRANSFERS% --checkers %RCLONE_CHECKERS% ^
    --log-file "%LOGFILE%" --log-level INFO
)

if errorlevel 1 (
  echo [WARN] rclone move finished with errors. See log: %LOGFILE%
  exit /b 1
)

if "%CLEAN_EMPTY_DIRS%"=="1" (
  powershell -NoProfile -Command ^
    "$src='%SRCDIR%'; $logs='%LOGDIR%';" ^
    "Get-ChildItem -Path $src -Directory -Recurse |" ^
    "Sort-Object FullName -Descending |" ^
    "Where-Object { $_.FullName -ne $logs } |" ^
    "ForEach-Object {" ^
    "  if (-not (Get-ChildItem -LiteralPath $_.FullName -Force | Select-Object -First 1)) {" ^
    "    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue" ^
    "  }" ^
    "}"
)

endlocal
