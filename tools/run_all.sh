#!/usr/bin/env bash
# Every check for the cozy night town: the clean-code lint, a parse check of every script, the headless smoke test
# of the real town and the collision/clipping suite. With --long it also runs the slow suites (a 3-minute walk
# sweep, the balance bot, the stability run, and the rendered performance and brightness probes).
# Prints ALL CHECKS PASS or SOME CHECKS FAILED and exits 1 on any failure. Never commit on a failure.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
status=0
python3 -I tools/check_code.py | grep -v "CODE note" | tail -25
python3 -I tools/check_code.py >/dev/null || status=1
tools/parse_check.sh || exit 1
out=$(timeout 600 "$GODOT" --headless --fixed-fps 60 --path game -- --smoke 2>&1)
echo "$out" | grep -E "^SMOKE (FAIL|PASS)|SCRIPT ERROR|Parse Error" | head -20
echo "$out" | grep -qE "SCRIPT ERROR|Parse Error" && { echo "smoke: script errors"; status=1; }
echo "$out" | grep -qE "^SMOKE PASS" || status=1
LONG=""
[ "${1:-}" = "--long" ] && LONG="--long"
out=$(timeout 900 "$GODOT" --headless --fixed-fps 60 --path game -- --collision $LONG 2>&1)
echo "$out" | grep -E "^COLLISION (FAIL|PASS)|SCRIPT ERROR" | head -20
echo "$out" | grep -qE "SCRIPT ERROR" && { echo "collision: script errors"; status=1; }
echo "$out" | grep -qE "^COLLISION PASS" || status=1
if [ -n "$LONG" ]; then
  out=$(timeout 3000 "$GODOT" --headless --fixed-fps 30 --path game -- --balance --nights=4 2>&1)
  echo "$out" | grep -E "^BALANCE (summary|note|FAIL|PASS)|SCRIPT ERROR" | head -20
  echo "$out" | grep -qE "^BALANCE PASS" || status=1
  out=$(timeout 1200 "$GODOT" --headless --fixed-fps 30 --path game -- --balance --stability 2>&1)
  echo "$out" | grep -E "^BALANCE (stability|FAIL|PASS)|SCRIPT ERROR" | sed 's/^BALANCE/STABILITY/' | head -10
  echo "$out" | grep -qE "^BALANCE PASS" || status=1
  out=$(timeout 900 xvfb-run -a -s "-screen 0 1600x900x24" "$GODOT" --rendering-driver vulkan --audio-driver Dummy \
    --resolution 1600x900 --path game -- --perf 2>&1)
  echo "$out" | grep -E "^PERF" | head -10
  echo "$out" | grep -qE "^PERF PASS" || status=1
  stills=$(mktemp -d)
  tools/shoot.sh "$stills" square street canal_bridge alley overlook rain defence contrast_on contrast_off >/dev/null
  python3 -I tools/readability.py "$stills" || status=1
fi
[ $status -eq 0 ] && echo "ALL CHECKS PASS" || echo "SOME CHECKS FAILED"
exit $status
