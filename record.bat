@echo off
chcp 65001 >nul
setlocal

set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%config.bat" call "%SCRIPT_DIR%config.bat"

if not defined OUTDIR set "OUTDIR=C:\rec"
if not defined FFMPEG_EXE set "FFMPEG_EXE=%SCRIPT_DIR%ffmpeg\ffmpeg.exe"
if not defined VIDEO_FRAMERATE set "VIDEO_FRAMERATE=15"
if not defined DRAW_MOUSE set "DRAW_MOUSE=0"
if not defined SEGMENT_SECONDS set "SEGMENT_SECONDS=60"
if not defined X264_PRESET set "X264_PRESET=veryfast"
if not defined VIDEO_CRF set "VIDEO_CRF=27"
if not defined AUDIO_FILTER set "AUDIO_FILTER=acompressor=threshold=-20dB:ratio=3:attack=20:release=200,volume=3"
if not defined AUDIO_BITRATE set "AUDIO_BITRATE=96k"
if not defined PAUSE_ON_EXIT set "PAUSE_ON_EXIT=1"

set "FFMPEG_CMD="
if exist "%FFMPEG_EXE%" (
  set "FFMPEG_CMD=%FFMPEG_EXE%"
) else (
  where ffmpeg >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] ffmpeg not found: "%FFMPEG_EXE%" and not in PATH.
    echo Put ffmpeg.exe in ffmpeg\ or install ffmpeg.
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

echo.
echo ==== Recording stopped ====
if "%PAUSE_ON_EXIT%"=="1" pause

endlocal
