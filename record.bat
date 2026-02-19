@echo off
chcp 65001 >nul
setlocal

set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%config.bat" call "%SCRIPT_DIR%config.bat"

if not defined OUTDIR set "OUTDIR=C:\rec"
if not defined FFMPEG_EXE set "FFMPEG_EXE=%SCRIPT_DIR%ffmpeg\bin\ffmpeg.exe"
if not defined VIDEO_FRAMERATE set "VIDEO_FRAMERATE=15"
if not defined DRAW_MOUSE set "DRAW_MOUSE=0"
if not defined SEGMENT_SECONDS set "SEGMENT_SECONDS=60"
if not defined X264_PRESET set "X264_PRESET=veryfast"
if not defined VIDEO_CRF set "VIDEO_CRF=27"
if not defined AUDIO_FILTER set "AUDIO_FILTER=acompressor=threshold=-20dB:ratio=3:attack=20:release=200,volume=3"
if not defined AUDIO_BITRATE set "AUDIO_BITRATE=96k"
if not defined MIN_FREE_GB set "MIN_FREE_GB=5"
if not defined PAUSE_ON_EXIT set "PAUSE_ON_EXIT=1"

set "FFMPEG_CMD="
if exist "%FFMPEG_EXE%" (
  set "FFMPEG_CMD=%FFMPEG_EXE%"
) else (
  where ffmpeg >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] ffmpeg not found: "%FFMPEG_EXE%" and not in PATH.
    echo Put ffmpeg.exe in ffmpeg\bin\ or install ffmpeg.
    if "%PAUSE_ON_EXIT%"=="1" pause
    exit /b 1
  )
  set "FFMPEG_CMD=ffmpeg"
)

set "PC=%COMPUTERNAME%"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "D=%%i"
set "DAYDIR=%OUTDIR%\%D%"
if not exist "%DAYDIR%" mkdir "%DAYDIR%"

set "LOGDIR=%OUTDIR%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
if not defined RECORD_SESSION_LOG set "RECORD_SESSION_LOG=%LOGDIR%\record_session.log"

for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -Format ''yyyy-MM-dd HH:mm:ss''"') do set "START_TS=%%i"
for /f %%i in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set "START_EPOCH=%%i"

set "FREE_GB="
for /f %%i in ('powershell -NoProfile -Command "$p='%OUTDIR%'; try { $root=[System.IO.Path]::GetPathRoot($p); if (-not $root) { '' } else { $id=($root -replace '\\\\$',''); $d=Get-CimInstance Win32_LogicalDisk -Filter ('DeviceID=''''+$id+'''''); if($d){ [int]([math]::Floor($d.FreeSpace/1GB)) } } } catch { '' }"') do set "FREE_GB=%%i"

if defined FREE_GB (
  if %FREE_GB% LSS %MIN_FREE_GB% (
    echo [ERROR] Low disk space: %FREE_GB% GB free, required at least %MIN_FREE_GB% GB.
    echo [%START_TS%] START_BLOCKED reason=LOW_DISK free_gb=%FREE_GB% min_free_gb=%MIN_FREE_GB% outdir=%OUTDIR%>>"%RECORD_SESSION_LOG%"
    if "%PAUSE_ON_EXIT%"=="1" pause
    exit /b 2
  )
) else (
  echo [WARN] Could not determine free disk space for OUTDIR.
)

echo.
echo ==== Screen recording started ====
echo PC: %PC%
echo Output: %DAYDIR%
if defined AUDIO_DEVICE (
  echo Audio: %AUDIO_DEVICE%
) else (
  echo Audio: disabled ^(set AUDIO_DEVICE in config.bat to enable^)
)
echo Press Ctrl+C to stop recording
echo.

echo [%START_TS%] START pc=%PC% outdir=%DAYDIR% fps=%VIDEO_FRAMERATE% draw_mouse=%DRAW_MOUSE%>>"%RECORD_SESSION_LOG%"

if defined AUDIO_DEVICE (
  "%FFMPEG_CMD%" -hide_banner -loglevel info ^
    -f gdigrab -framerate %VIDEO_FRAMERATE% -draw_mouse %DRAW_MOUSE% -i desktop ^
    -f dshow -i audio="%AUDIO_DEVICE%" ^
    -c:v libx264 -preset %X264_PRESET% -crf %VIDEO_CRF% -pix_fmt yuv420p ^
    -af "%AUDIO_FILTER%" ^
    -c:a aac -b:a %AUDIO_BITRATE% ^
    -f segment -segment_time %SEGMENT_SECONDS% -reset_timestamps 1 -strftime 1 ^
    "%DAYDIR%\%PC%_%%Y-%%m-%%d_%%H-%%M-%%S.mkv"
) else (
  "%FFMPEG_CMD%" -hide_banner -loglevel info ^
    -f gdigrab -framerate %VIDEO_FRAMERATE% -draw_mouse %DRAW_MOUSE% -i desktop ^
    -c:v libx264 -preset %X264_PRESET% -crf %VIDEO_CRF% -pix_fmt yuv420p ^
    -an ^
    -f segment -segment_time %SEGMENT_SECONDS% -reset_timestamps 1 -strftime 1 ^
    "%DAYDIR%\%PC%_%%Y-%%m-%%d_%%H-%%M-%%S.mkv"
)
set "FFMPEG_RC=%ERRORLEVEL%"

for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -Format ''yyyy-MM-dd HH:mm:ss''"') do set "END_TS=%%i"
for /f %%i in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set "END_EPOCH=%%i"

set /a DURATION_SEC=0
if defined START_EPOCH if defined END_EPOCH set /a DURATION_SEC=END_EPOCH-START_EPOCH

if "%FFMPEG_RC%"=="0" (
  echo [%END_TS%] STOP_OK duration_sec=%DURATION_SEC% rc=%FFMPEG_RC%>>"%RECORD_SESSION_LOG%"
) else (
  echo [ERROR] ffmpeg stopped with code %FFMPEG_RC%.
  echo [%END_TS%] STOP_ERROR duration_sec=%DURATION_SEC% rc=%FFMPEG_RC%>>"%RECORD_SESSION_LOG%"
)

echo.
echo ==== Recording stopped ====
if "%PAUSE_ON_EXIT%"=="1" pause

endlocal & exit /b %FFMPEG_RC%
