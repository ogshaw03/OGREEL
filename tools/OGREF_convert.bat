@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
REM ============================================================
REM  OGREF video converter : HEVC/etc .mov -> playable H.264 .mp4
REM
REM  How to use:
REM   (A) Drag and drop a FOLDER onto this .bat
REM        -> creates "<folder>_low" next to it and outputs there
REM   (B) Edit SRC / DST below, then double-click
REM
REM  After converting, in OGREF: "Local" -> "Select low-res folder"
REM  and connect the output (_low) folder. The .mov tiles play as mp4.
REM
REM  Requires ffmpeg (https://ffmpeg.org , add to PATH).
REM  (Japanese instructions: see tools/README.md)
REM ============================================================

REM ===== Settings (for method B) =====
set "SRC=D:\Reference\video"
set "DST=D:\Reference\video_low"
REM Quality (CRF): lower = better/larger (18-28, default 23)
set "CRF=23"
REM To downscale (optional), e.g.  set "SCALE=-vf scale=-2:720"   (empty = keep size)
set "SCALE="
REM Target extensions (space separated)
set "EXTS=mov mkv avi wmv flv m4v"
REM ===================================

REM (A) If a folder was dropped, use it (preferred; works with non-ASCII paths)
if not "%~1"=="" (
  if exist "%~1\" (
    set "SRC=%~1"
    set "DST=%~1_low"
  )
)

echo Source: "%SRC%"
echo Output: "%DST%"
echo.

where ffmpeg >nul 2>nul
if errorlevel 1 (
  echo [ERROR] ffmpeg not found. Install from https://ffmpeg.org and add it to PATH.
  pause
  exit /b 1
)

if not exist "%SRC%\" (
  echo [ERROR] Source folder does not exist: "%SRC%"
  pause
  exit /b 1
)

if not exist "%DST%" mkdir "%DST%"

set /a CNT=0
set /a SKIP=0
set /a FAIL=0

for %%E in (%EXTS%) do (
  for /r "%SRC%" %%F in (*.%%E) do (
    set "DIR=%%~dpF"
    set "REL=!DIR:%SRC%=!"
    set "OUTDIR=%DST%!REL!"
    if not exist "!OUTDIR!" mkdir "!OUTDIR!"
    set "OUT=!OUTDIR!%%~nF.mp4"
    if exist "!OUT!" (
      echo [skip] %%~nxF
      set /a SKIP+=1
    ) else (
      echo [conv] %%F
      ffmpeg -hide_banner -loglevel error -y -i "%%F" -c:v libx264 -crf %CRF% -preset fast %SCALE% -c:a aac -movflags +faststart "!OUT!"
      if errorlevel 1 (
        echo    [FAIL] %%F
        set /a FAIL+=1
      ) else (
        set /a CNT+=1
      )
    )
  )
)

echo.
echo ============================================================
echo  Done.  converted !CNT!  skipped !SKIP!  failed !FAIL!
echo  Output: "%DST%"
echo  In OGREF: Local -^> Select low-res folder -^> connect the folder above.
echo ============================================================
pause
endlocal
