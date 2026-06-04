#!/usr/bin/env bash
# OGREF 用 動画一括変換（HEVC等の.mov → 再生可能なH.264 .mp4）
# 使い方:
#   ./ogref_convert.sh "/path/to/動画"             # → /path/to/動画_low に出力
#   ./ogref_convert.sh "/path/to/動画" "/out/dir"  # 出力先を指定
# 変換後、OGREFの「💾 ローカル」→「軽量版フォルダを選択」で出力先を接続してください。
set -u

CRF="${CRF:-23}"          # 画質（小さいほど高画質・大容量）
SCALE="${SCALE:-}"        # 例: SCALE="-vf scale=-2:720"
EXTS=(mov mkv avi wmv flv m4v)

SRC="${1:-}"
if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
  echo "使い方: $0 <変換元フォルダ> [出力先フォルダ]"
  exit 1
fi
SRC="${SRC%/}"
DST="${2:-${SRC}_low}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "[エラー] ffmpeg が見つかりません。https://ffmpeg.org からインストールしてください。"
  exit 1
fi

echo "変換元: $SRC"
echo "出力先: $DST"
mkdir -p "$DST"

cnt=0; skip=0; fail=0
find_args=()
for e in "${EXTS[@]}"; do find_args+=( -iname "*.${e}" -o ); done
unset 'find_args[${#find_args[@]}-1]'   # 末尾の -o を削除

while IFS= read -r -d '' f; do
  rel="${f#$SRC/}"                 # 相対パス
  reldir="$(dirname "$rel")"
  outdir="$DST/$reldir"
  base="$(basename "${f%.*}")"
  out="$outdir/$base.mp4"
  mkdir -p "$outdir"
  if [ -f "$out" ]; then
    echo "[skip ] $rel は変換済み"; skip=$((skip+1)); continue
  fi
  echo "[変換 ] $rel"
  if ffmpeg -hide_banner -loglevel error -y -i "$f" -c:v libx264 -crf "$CRF" -preset fast $SCALE -c:a aac -movflags +faststart "$out"; then
    cnt=$((cnt+1))
  else
    echo "   [失敗] $f"; fail=$((fail+1))
  fi
done < <(find "$SRC" -type f \( "${find_args[@]}" \) -print0)

echo
echo "完了: 変換 $cnt 件 / スキップ $skip 件 / 失敗 $fail 件"
echo "出力先: $DST"
echo "OGREFの「💾 ローカル」→「軽量版フォルダを選択」で上記を接続してください。"
