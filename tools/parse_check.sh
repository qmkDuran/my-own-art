#!/usr/bin/env bash
# Fails fast when any GDScript file does not parse (a broken script would otherwise leave a test run hanging).
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
"$GODOT" --headless --path game --import >/dev/null 2>&1
errors=$(timeout 120 "$GODOT" --headless --path game --quit-after 2 2>&1 | grep -E "Parse Error|Compile Error" | head -10)
if [ -n "$errors" ]; then echo "$errors"; echo "PARSE FAIL"; exit 1; fi
echo "PARSE PASS"
