# OGREF 動画変換ツール

ブラウザで再生できない動画（HEVC/H.265 の `.mov`、ProRes、その他コーデック）を、
**再生可能な H.264 / AAC の `.mp4`** に一括変換するためのスクリプトです。

変換結果は OGREF の「**軽量版フォルダ**」に置いて使います。元の動画はそのまま残せます。
OGREF 側で `clip.mov` に対して同名の `clip.mp4` を軽量版フォルダから自動で探して再生します
（サブフォルダ構成も保持されます）。

## 事前準備
[ffmpeg](https://ffmpeg.org/download.html) をインストールし、PATH を通してください。
- 確認: コマンドプロンプト/ターミナルで `ffmpeg -version` が表示されればOK

## Windows: `OGREF_convert.bat`
2通りの使い方があります。

- **(A) ドラッグ＆ドロップ（おすすめ）**
  変換したいフォルダを `OGREF_convert.bat` の上にドラッグ＆ドロップ。
  → 同じ場所に `<フォルダ名>_low` が作られ、そこへ変換結果が出力されます。

- **(B) パス指定**
  `OGREF_convert.bat` をテキストエディタで開き、先頭の
  `SRC`（変換元）と `DST`（出力先）を書き換えてダブルクリック実行。

オプション（バッチ先頭で調整可）:
- `CRF` … 画質（小さいほど高画質・大容量。既定 23）
- `SCALE` … 軽量化で解像度を下げる（例 `set "SCALE=-vf scale=-2:720"`）
- `EXTS` … 変換対象の拡張子

## macOS / Linux: `ogref_convert.sh`
```bash
chmod +x ogref_convert.sh
./ogref_convert.sh "/path/to/動画"            # → /path/to/動画_low に出力
./ogref_convert.sh "/path/to/動画" "/out/dir" # 出力先を指定
```

## 変換後
OGREF の「💾 ローカル」→「軽量版フォルダを選択」で、出力された `_low` フォルダを接続してください。
HEVC などで再生できなかったタイルが、変換した mp4 で再生できるようになります。
