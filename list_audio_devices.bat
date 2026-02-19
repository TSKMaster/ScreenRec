@echo off
chcp 65001 >nul

setlocal
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%config.bat" call "%SCRIPT_DIR%config.bat"
if not defined FFMPEG_EXE set "FFMPEG_EXE=%SCRIPT_DIR%ffmpeg\bin\ffmpeg.exe"

set "FFMPEG_CMD="
if exist "%FFMPEG_EXE%" (
  set "FFMPEG_CMD=%FFMPEG_EXE%"
) else (
  where ffmpeg >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] ffmpeg not found: "%FFMPEG_EXE%" and not in PATH.
    exit /b 1
  )
  set "FFMPEG_CMD=ffmpeg"
)

echo.
echo FFmpeg DirectShow devices ^(full list^):
echo -------------------------------------
"%FFMPEG_CMD%" -hide_banner -list_devices true -f dshow -i dummy 2>&1
echo -------------------------------------
echo.
echo Use one of the audio values in config.bat:
echo set "AUDIO_DEVICE=Device Friendly Name"
echo or better ^(stable ASCII^):
echo set "AUDIO_DEVICE=@device_cm_{...}\wave_{...}"
endlocal
