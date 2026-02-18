@echo off
REM Copy this file to config.bat and adjust values for your environment.

REM Local storage root for recording segments.
set OUTDIR=C:\rec

REM NAS remote configured in rclone (same for all PCs).
set REMOTE_BASE=nas:records

REM Upload policy.
set UPLOAD_MIN_AGE=3m
set UPLOAD_INTERVAL_SEC=120
set START_AFTER_HHMM=1700
set CLEAN_EMPTY_DIRS=1
set LOG_RETENTION_DAYS=14

REM Video encoding.
set VIDEO_FRAMERATE=15
set DRAW_MOUSE=1
set SEGMENT_SECONDS=60
set X264_PRESET=veryfast
set VIDEO_CRF=27
set MIN_FREE_GB=5

REM Audio capture.
REM Leave AUDIO_DEVICE empty to record video only.
REM Example:
REM set AUDIO_DEVICE=Stereo Mix (Realtek(R) Audio)
set AUDIO_DEVICE=
set AUDIO_FILTER=acompressor=threshold=-20dB:ratio=3:attack=20:release=200,volume=3
set AUDIO_BITRATE=96k

REM rclone tuning.
set RCLONE_TRANSFERS=4
set RCLONE_CHECKERS=4
set RCLONE_RETRIES=10
set RCLONE_LOW_LEVEL_RETRIES=10

REM Set to 1 to keep pause at the end of record.bat.
set PAUSE_ON_EXIT=1
