@echo off
chcp 65001 >nul
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%config.bat" call "%SCRIPT_DIR%config.bat"

if not defined OUTDIR set "OUTDIR=C:\rec"
if not defined REMOTE_BASE set "REMOTE_BASE=nas:records"
if not defined FFMPEG_EXE set "FFMPEG_EXE=%SCRIPT_DIR%ffmpeg\ffmpeg.exe"
if not defined RCLONE_EXE set "RCLONE_EXE=%SCRIPT_DIR%Rclone\rclone.exe"
if not defined RCLONE_CONFIG set "RCLONE_CONFIG=%SCRIPT_DIR%Rclone\rclone.conf"

set /a FAILS=0
set /a PASSES=0
set "HAS_FFMPEG=0"
set "HAS_RCLONE=0"
set "FFMPEG_CMD="
set "RCLONE_CMD="

echo.
echo ==== ScreenRec setup check ====
echo Script dir: %SCRIPT_DIR%
echo OUTDIR: %OUTDIR%
echo REMOTE_BASE: %REMOTE_BASE%
echo.

call :check_ffmpeg
call :check_rclone

call :check_outdir
call :check_remote
call :check_audio

echo.
echo ==== Summary ====
echo Passed: %PASSES%
echo Failed: %FAILS%
if %FAILS% GTR 0 (
  echo Result: FAILED
  exit /b 1
) else (
  echo Result: OK
  exit /b 0
)

:check_cmd
where %~1 >nul 2>&1
if errorlevel 1 (
  echo [FAIL] %~1 not found in PATH
  set /a FAILS+=1
  set "%~2=0"
) else (
  echo [ OK ] %~1 found
  set /a PASSES+=1
  set "%~2=1"
)
exit /b 0

:check_ffmpeg
if exist "%FFMPEG_EXE%" (
  set "FFMPEG_CMD=%FFMPEG_EXE%"
  set "HAS_FFMPEG=1"
  echo [ OK ] ffmpeg found: %FFMPEG_EXE%
  set /a PASSES+=1
) else (
  where ffmpeg >nul 2>&1
  if errorlevel 1 (
    echo [FAIL] ffmpeg not found: "%FFMPEG_EXE%" and not in PATH
    set /a FAILS+=1
    set "HAS_FFMPEG=0"
  ) else (
    set "FFMPEG_CMD=ffmpeg"
    set "HAS_FFMPEG=1"
    echo [ OK ] ffmpeg found in PATH
    set /a PASSES+=1
  )
)
exit /b 0

:check_rclone
if exist "%RCLONE_EXE%" (
  set "RCLONE_CMD=%RCLONE_EXE%"
  set "HAS_RCLONE=1"
  echo [ OK ] rclone found: %RCLONE_EXE%
  set /a PASSES+=1
) else (
  where rclone >nul 2>&1
  if errorlevel 1 (
    echo [FAIL] rclone not found: "%RCLONE_EXE%" and not in PATH
    set /a FAILS+=1
    set "HAS_RCLONE=0"
  ) else (
    set "RCLONE_CMD=rclone"
    set "HAS_RCLONE=1"
    echo [ OK ] rclone found in PATH
    set /a PASSES+=1
  )
)
exit /b 0

:check_outdir
if not exist "%OUTDIR%" mkdir "%OUTDIR%" >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Cannot create/access OUTDIR: %OUTDIR%
  set /a FAILS+=1
  exit /b 0
)

set "LOCAL_TEST=%OUTDIR%\.setup_check_write_test.tmp"
>"%LOCAL_TEST%" echo test >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Cannot write to OUTDIR: %OUTDIR%
  set /a FAILS+=1
  exit /b 0
)
del /f /q "%LOCAL_TEST%" >nul 2>&1
echo [ OK ] Local output folder is writable
set /a PASSES+=1
exit /b 0

:check_remote
if not "%HAS_RCLONE%"=="1" (
  echo [SKIP] Remote check skipped because rclone is missing
  exit /b 0
)

for /f "tokens=1 delims=:" %%R in ("%REMOTE_BASE%") do set "REMOTE_NAME=%%R"
if "%REMOTE_NAME%"=="" (
  echo [FAIL] REMOTE_BASE looks invalid: %REMOTE_BASE%
  set /a FAILS+=1
  exit /b 0
)

if exist "%RCLONE_CONFIG%" (
  "%RCLONE_CMD%" --config "%RCLONE_CONFIG%" listremotes | findstr /I /C:"%REMOTE_NAME%:" >nul
) else (
  "%RCLONE_CMD%" listremotes | findstr /I /C:"%REMOTE_NAME%:" >nul
)
if errorlevel 1 (
  echo [FAIL] rclone remote not configured: %REMOTE_NAME%
  set /a FAILS+=1
  exit /b 0
)

for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%T"
set "REMOTE_TEST=%REMOTE_BASE%/.__setup_check_%COMPUTERNAME%_%TS%"

if exist "%RCLONE_CONFIG%" (
  "%RCLONE_CMD%" --config "%RCLONE_CONFIG%" mkdir "%REMOTE_TEST%" --retries 1 --low-level-retries 1 >nul 2>&1
) else (
  "%RCLONE_CMD%" mkdir "%REMOTE_TEST%" --retries 1 --low-level-retries 1 >nul 2>&1
)
if errorlevel 1 (
  echo [FAIL] Cannot create folder on remote: %REMOTE_BASE%
  set /a FAILS+=1
  exit /b 0
)

if exist "%RCLONE_CONFIG%" (
  "%RCLONE_CMD%" --config "%RCLONE_CONFIG%" rmdir "%REMOTE_TEST%" --retries 1 --low-level-retries 1 >nul 2>&1
) else (
  "%RCLONE_CMD%" rmdir "%REMOTE_TEST%" --retries 1 --low-level-retries 1 >nul 2>&1
)
if errorlevel 1 (
  echo [FAIL] Created remote test folder but could not remove it: %REMOTE_TEST%
  set /a FAILS+=1
  exit /b 0
)

echo [ OK ] Remote access is working
set /a PASSES+=1
exit /b 0

:check_audio
if not "%HAS_FFMPEG%"=="1" (
  echo [SKIP] Audio check skipped because ffmpeg is missing
  exit /b 0
)

if not defined AUDIO_DEVICE (
  echo [ OK ] AUDIO_DEVICE is empty, recording will be video-only
  set /a PASSES+=1
  exit /b 0
)

"%FFMPEG_CMD%" -hide_banner -list_devices true -f dshow -i dummy 2>&1 | findstr /I /C:"%AUDIO_DEVICE%" >nul
if errorlevel 1 (
  echo [FAIL] AUDIO_DEVICE not found by ffmpeg: %AUDIO_DEVICE%
  echo        Run list_audio_devices.bat and update config.bat
  set /a FAILS+=1
  exit /b 0
)

echo [ OK ] AUDIO_DEVICE found by ffmpeg
set /a PASSES+=1
exit /b 0
