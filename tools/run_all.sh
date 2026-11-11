#!/usr/bin/env bash
# Every check for Monster Tamer: art (palette, sizes), code lint, map rules, UI layout at several screen
# shapes, and the headless smoke test (new game, timing battle, befriending, trainer win, healing, save/load).
# Exit 1 if any fails.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
status=0
python3 -I tools/check_art.py | tail -3 || status=1
python3 -I tools/check_art.py >/dev/null || status=1
python3 -I tools/check_code.py | grep -v "CODE note" | tail -15
python3 -I tools/check_code.py >/dev/null || status=1
"$GODOT" --headless --path game --import >/dev/null 2>&1
for mode in maps ui smoke; do
  out=$(timeout 600 "$GODOT" --headless --path game -- --$mode 2>&1)
  echo "$out" | grep -E "^(MAPS|UI|SMOKE) (PASS|FAIL)|problem|SMOKE FAIL|SCRIPT ERROR" | head -20
  echo "$out" | grep -qE "SCRIPT ERROR|Parse Error" && { echo "$mode: script errors"; status=1; }
  echo "$out" | grep -qE "^(MAPS|UI|SMOKE) PASS" || status=1
done
[ $status -eq 0 ] && echo "ALL CHECKS PASS" || echo "SOME CHECKS FAILED"
exit $status
