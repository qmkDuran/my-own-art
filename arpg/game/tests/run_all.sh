#!/usr/bin/env bash
# All checks for the ARPG: verses, style (palette/outline/scale), and the headless smoke test. Exit 1 on any failure.
set -u
cd "$(dirname "$0")/../.."
python3 -I tools/check_verses.py | tail -1 && python3 -I tools/check_palette.py | tail -1 && bash game/tests/run_smoke.sh
