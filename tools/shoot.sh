#!/usr/bin/env bash
# Review stills: tools/shoot.sh OUT_DIR [shot ...]. Town shots (tests/shots.gd) or combat stages
# (tests/combat_shots.gd, run at a fixed 30 fps; a stage may save several stills). With no names, the town set.
# Needs xvfb-run and a Vulkan driver (lavapipe works). Stills only, never video. Output: OUT_DIR/<name>.png
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
OUT="$1"; shift
SHOTS=("$@")
[ ${#SHOTS[@]} -eq 0 ] && SHOTS=(square street canal_bridge alley overlook rain player_closeup townsfolk)
mkdir -p "$OUT"
"$GODOT" --headless --path game --import >/dev/null 2>&1
COMBAT=" overview primary heavy bomb ward swarm elite_break boss_telegraph super busy contrast "
for s in "${SHOTS[@]}"; do
  mode=(--shots); fps=()
  [[ "$COMBAT" == *" $s "* ]] && { mode=(--combat-shots); fps=(--fixed-fps 30); }
  timeout 900 xvfb-run -a -s "-screen 0 1600x900x24" "$GODOT" --rendering-driver vulkan --audio-driver Dummy \
    --resolution 1600x900 "${fps[@]}" --path game -- "${mode[@]}" --only="$s" --out="$OUT" 2>&1 | grep -E "SCRIPT ERROR|SHOT|ERROR" -A2 | grep -v "ERR_CANT_OPEN\|status < 0" | sed "s/^/$s: /"
done
