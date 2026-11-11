#!/usr/bin/env bash
# Review screenshots: tools/shoot.sh OUT_DIR [shot ...]  (all shots when none named). Needs xvfb-run.
# Writes OUT_DIR/<shot>.png (native 320x180) and OUT_DIR/<shot>_2x.png / _4x.png for review.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
OUT="$1"; shift
SHOTS=("$@")
[ ${#SHOTS[@]} -eq 0 ] && SHOTS=($(grep -oE "^func _shot_[a-z_]+" game/tests/shots.gd | sed 's/func _shot_//'))
mkdir -p "$OUT"
"$GODOT" --headless --path game --import >/dev/null 2>&1
for s in "${SHOTS[@]}"; do
  timeout 120 xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --rendering-driver opengl3 --resolution 1280x720 \
    --path game -- --shots --only="$s" --out="$OUT" 2>&1 | grep -E "SCRIPT ERROR|Parse Error" -A3 | sed "s/^/$s: /"
  python3 -I -c "
from PIL import Image; import sys
im=Image.open(sys.argv[1]); 
for k in (2,4): im.resize((im.width*k,im.height*k),Image.NEAREST).save(sys.argv[1][:-4]+f'_{k}x.png')" "$OUT/$s.png" 2>/dev/null
done
