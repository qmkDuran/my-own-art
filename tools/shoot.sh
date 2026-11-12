#!/usr/bin/env bash
# Review stills: tools/shoot.sh OUT_DIR [shot ...]. With no shot names, takes all of them. Needs xvfb-run.
# Stills only, never video. Output: OUT_DIR/<shot>.png
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
OUT="$1"; shift
SHOTS=("$@")
[ ${#SHOTS[@]} -eq 0 ] && SHOTS=(overview third_person lock_on spit_tree hiding searching ridge_fight hud_closeup start_screen mind_overlay)
mkdir -p "$OUT"
"$GODOT" --headless --path game --import >/dev/null 2>&1
for s in "${SHOTS[@]}"; do
  timeout 300 xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 \
    --path game -- --shots --only="$s" --out="$OUT" 2>&1 | grep -E "SCRIPT ERROR|SHOT|ERROR" -A2 | sed "s/^/$s: /"
done
