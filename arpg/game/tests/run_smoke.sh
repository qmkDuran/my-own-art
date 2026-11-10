#!/usr/bin/env bash
# Headless smoke test for the ARPG prototype; fails on script errors.
set -u
GODOT="${GODOT:-$(dirname "$0")/../../../../godot/Godot_v4.7.2-stable_linux.x86_64}"
cd "$(dirname "$0")/.."
out=$(timeout 300 "$GODOT" --headless --fixed-fps 60 --path . -- --smoke 2>&1)
echo "$out" | grep -E "SMOKE|SCRIPT ERROR|^ERROR|Parse Error" | grep -v "resources still in use"
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then echo "SMOKE FAIL: script errors"; exit 1; fi
echo "$out" | grep -q "SMOKE PASS"
