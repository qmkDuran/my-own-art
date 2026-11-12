#!/usr/bin/env bash
# Review stills of the trainer prototype: tools/tamer_shots.sh OUT_DIR [shot ...]  (needs xvfb-run)
# Shots: meeting route battle_start slow_aim stagger rival sync victory info shiny swap camp camp_panel sanctuary hud (camp_panel follows camp in one run).
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
OUT="$1"; shift
SHOTS=("$@")
[ ${#SHOTS[@]} -eq 0 ] && SHOTS=(meeting route battle_start slow_aim stagger rival sync victory info shiny swap camp sanctuary hud)
mkdir -p "$OUT"
for s in "${SHOTS[@]}"; do
  only="$s"
  [ "$s" = "camp" ] && only=""                     # camp and its panel are taken in one run, in order
  args=(--tamer-shots --out="$OUT")
  [ -n "$only" ] && args+=(--only="$only")
  [ "$s" = "camp" ] && args+=(--only=camp_both)
  timeout 300 xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --rendering-driver opengl3 --resolution 1920x1080 \
    --path game -- "${args[@]}" 2>&1 | grep -E "SCRIPT ERROR|SHOT" -A2 | sed "s/^/$s: /"
done
