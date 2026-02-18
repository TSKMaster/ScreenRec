@echo off
chcp 65001 >nul
setlocal

set "SCRIPT_DIR=%~dp0"
set "FFMPEG_DIR=%SCRIPT_DIR%ffmpeg"
set "FFMPEG_EXE=%FFMPEG_DIR%\ffmpeg.exe"

if exist "%FFMPEG_EXE%" (
  echo [ OK ] ffmpeg already exists: %FFMPEG_EXE%
  exit /b 0
)

where winget >nul 2>&1
if errorlevel 1 (
  echo [ERROR] winget not found.
  echo Install ffmpeg manually or put ffmpeg.exe into ffmpeg\
  exit /b 1
)

echo Installing ffmpeg via winget...
winget install --id Gyan.FFmpeg --exact --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
  echo [ERROR] winget install failed.
  exit /b 1
)

where ffmpeg >nul 2>&1
if errorlevel 1 (
  echo [ERROR] ffmpeg was installed but not found in PATH yet.
  echo Reopen terminal and rerun setup_check.bat
  exit /b 1
)

if not exist "%FFMPEG_DIR%" mkdir "%FFMPEG_DIR%"
for /f "delims=" %%P in ('where ffmpeg') do (
  copy /y "%%P" "%FFMPEG_EXE%" >nul
  goto copied
)

:copied
if exist "%FFMPEG_EXE%" (
  echo [ OK ] Copied ffmpeg.exe to: %FFMPEG_EXE%
  echo Run setup_check.bat
  exit /b 0
)

echo [WARN] ffmpeg is installed in PATH, but copy to project folder was not completed.
echo You can still use project with PATH ffmpeg.
exit /b 0
