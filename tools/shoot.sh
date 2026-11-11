#!/usr/bin/env bash
# Review screenshots, each in the zone its scene is staged in: tools/shoot.sh OUT_DIR [shot ...]
# With no shot names, takes all of them. Needs xvfb-run. Output: OUT_DIR/<name>_1920x1080.png
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
OUT="$1"; shift
declare -A ZONE=([light]=glasswood [dark]=glasswood [skills]=glasswood [passives]=glasswood [inventory]=glasswood
  [character]=glasswood [boss]=glasswood [overview]=glasswood [title]=glasswood [tallow]=tallow [forge]=tallow
  [quests]=tallow [filter]=tallow [stash]=tallow [road]=ember_road [eclipse]=ember_road [noon]=ember_road
  [keystones]=ember_road [eclipse_tree]=ember_road [hollow]=moth_hollow [matron]=moth_hollow [river]=riverbank
  [falls]=falls [marsh]=saltmarsh [bellwright]=belfry [hollins]=hollins [town]=tuesday [mayor]=tuesday)
SHOTS=("$@")
[ ${#SHOTS[@]} -eq 0 ] && SHOTS=("${!ZONE[@]}")
mkdir -p "$OUT"
for s in "${SHOTS[@]}"; do
  timeout 300 xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --rendering-driver opengl3 --resolution 1920x1080 \
    --path game -- --shots --only="$s" --zone="${ZONE[$s]}" --out="$OUT" 2>&1 | grep -E "SCRIPT ERROR|is dead in this shot|woke elsewhere" -A2 | sed "s/^/$s: /"
done
