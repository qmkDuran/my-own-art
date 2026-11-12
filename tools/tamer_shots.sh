#!/usr/bin/env bash
# Review stills of the creature-trainer demo: tools/tamer_shots.sh OUT_DIR [shot ...]  (needs xvfb-run)
# Shots: hall station transition meadow riverbank forest ruins channel effects burn catch large trainer route evolution
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
OUT="$1"; shift
SHOTS=("$@")
[ ${#SHOTS[@]} -eq 0 ] && SHOTS=(hall station transition meadow riverbank forest ruins channel effects burn catch large trainer route evolution)
mkdir -p "$OUT"
for s in "${SHOTS[@]}"; do
  timeout 300 xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --rendering-driver opengl3 --resolution 1920x1080 \
    --path game -- --tamer-shots --out="$OUT" --only="$s" 2>&1 | grep -E "SCRIPT ERROR|SHOT" -A2 | sed "s/^/$s: /"
done
