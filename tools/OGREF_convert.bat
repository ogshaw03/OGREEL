@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
REM ============================================================
REM  OGREF 用 動画一括変換バッチ（HEVC等の.mov → 再生可能なH.264 .mp4）
REM
REM  使い方は2通り:
REM   (A) このバッチに「変換したいフォルダ」をドラッグ＆ドロップする
REM        → 同じ場所に「<フォルダ名>_low」を作り、そこへ変換結果を出力
REM   (B) 下の「設定」のSRC/DSTを書き換えてダブルクリック実行
REM
REM  変換後、OGREFの「💾 ローカル」→「軽量版フォルダを選択」で
REM  出力先フォルダ(_low)を接続すると、.movのタイルがmp4で再生されます。
REM
REM  ※ ffmpeg が必要です（https://ffmpeg.org でDLしPATHを通す）
REM ============================================================

REM ===== 設定（B方式のとき編集） =====
set "SRC=D:\Reference\動画"
set "DST=D:\Reference\動画_low"
REM 画質(CRF): 小さいほど高画質・大容量（18〜28、既定23）
set "CRF=23"
REM 軽量化で解像度を下げる場合の例:  set "SCALE=-vf scale=-2:720"  （下げないなら空のまま）
set "SCALE="
REM 変換対象の拡張子（スペース区切り）
set "EXTS=mov mkv avi wmv flv m4v"
REM ====================================

REM (A) フォルダをドラッグ＆ドロップした場合はそれを優先
if not "%~1"=="" (
  if exist "%~1\" (
    set "SRC=%~1"
    set "DST=%~1_low"
  )
)

echo 変換元: "%SRC%"
echo 出力先: "%DST%"
echo.

where ffmpeg >nul 2>nul
if errorlevel 1 (
  echo [エラー] ffmpeg が見つかりません。
  echo   https://ffmpeg.org/download.html からダウンロードし、PATHを通してください。
  pause
  exit /b 1
)

if not exist "%SRC%\" (
  echo [エラー] 変換元フォルダが存在しません: "%SRC%"
  pause
  exit /b 1
)

if not exist "%DST%" mkdir "%DST%"

set /a CNT=0
set /a SKIP=0
set /a FAIL=0

for %%E in (%EXTS%) do (
  for /r "%SRC%" %%F in (*.%%E) do (
    REM 元ファイルのフォルダ部分から SRC を取り除いて相対パスを得る
    set "DIR=%%~dpF"
    set "REL=!DIR:%SRC%=!"
    set "OUTDIR=%DST%!REL!"
    if not exist "!OUTDIR!" mkdir "!OUTDIR!"
    set "OUT=!OUTDIR!%%~nF.mp4"
    if exist "!OUT!" (
      echo [skip ] %%~nxF は変換済み
      set /a SKIP+=1
    ) else (
      echo [変換 ] %%F
      ffmpeg -hide_banner -loglevel error -y -i "%%F" -c:v libx264 -crf %CRF% -preset fast %SCALE% -c:a aac -movflags +faststart "!OUT!"
      if errorlevel 1 (
        echo    [失敗] %%F
        set /a FAIL+=1
      ) else (
        set /a CNT+=1
      )
    )
  )
)

echo.
echo ============================================================
echo  完了:  変換 !CNT! 件 / スキップ !SKIP! 件 / 失敗 !FAIL! 件
echo  出力先: "%DST%"
echo  OGREFの「💾 ローカル」→「軽量版フォルダを選択」で上記を接続してください。
echo ============================================================
pause
endlocal
