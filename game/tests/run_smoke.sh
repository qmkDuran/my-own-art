#!/usr/bin/env bash
# Runs the headless smoke test and fails on any script error (ignores Godot's benign exit-time leak notices).
set -u
GODOT="${GODOT:-$(dirname "$0")/../../../godot/Godot_v4.7.2-stable_linux.x86_64}"
cd "$(dirname "$0")/.."
out=$(timeout 300 "$GODOT" --headless --fixed-fps 60 --path . -- --smoke 2>&1)
echo "$out" | grep -E "SMOKE|SCRIPT ERROR|^ERROR" | grep -v "resources still in use"
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then echo "SMOKE FAIL: script errors"; exit 1; fi
echo "$out" | grep -q "SMOKE PASS"
