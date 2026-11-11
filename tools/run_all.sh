#!/usr/bin/env bash
# Every check for LANTERNFALL: art (palette, sizes, feet), code (clean-code lint), zone layout rules over many
# seeds, UI layout at every 16:9/16:10 size, the headless smoke test, and an Act 1 replay. Exit 1 if any fails.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
status=0
python3 -I tools/check_art.py | tail -1 || status=1
python3 -I tools/check_code.py | grep -v "CODE note" | tail -15 || status=1
python3 -I tools/check_code.py >/dev/null || status=1
python3 -I tools/check_art.py >/dev/null || status=1
"$GODOT" --headless --path game --import >/dev/null 2>&1
for mode in layout ui smoke; do
  out=$(timeout 900 "$GODOT" --headless --path game -- --$mode 2>&1)
  echo "$out" | grep -E "^(LAYOUT|UI|SMOKE) (PASS|FAIL)|SMOKE FAIL:|UI problem|SCRIPT ERROR" | head -20
  echo "$out" | grep -qE "SCRIPT ERROR|Parse Error" && { echo "$mode: script errors"; status=1; }
  echo "$out" | grep -qE "^(LAYOUT|UI|SMOKE) PASS" || status=1
done
# Act 1 end to end from the title screen (the bot plays every main-quest step)
out=$(timeout 900 "$GODOT" --headless --fixed-fps 60 --path game -- --replay 2>&1)
echo "$out" | grep -E "^REPLAY (PASS|FAIL)|STUCK|SCRIPT ERROR" | head -10
echo "$out" | grep -qE "^REPLAY PASS" || status=1
[ $status -eq 0 ] && echo "ALL CHECKS PASS" || echo "SOME CHECKS FAILED"
exit $status
