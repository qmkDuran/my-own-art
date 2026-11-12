#!/usr/bin/env bash
# The creature-trainer balance run: tools/tamer_balance.sh LABEL [SHARDS] [TIERS] [ROUNDS]
# Plays every ordered pair of species in every arena at each tier (bot vs AI, headless, SHARDS processes in
# parallel, default 4), saves the rows to out/balance_LABEL.jsonl and writes the tables into TAMER_NOTES.md under
# the LABEL markers (tools/balance_report.py).
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64}"
LABEL="$1"; N="${2:-4}"; TIERS="${3:-normal,hard}"; ROUNDS="${4:-1}"
mkdir -p out
for k in $(seq 0 $((N - 1))); do
  timeout 3600 "$GODOT" --headless --fixed-fps 30 --path game -- --tamer-balance --shard="$k/$N" --tiers="$TIERS" --rounds="$ROUNDS" \
    > "out/balance_${LABEL}_$k.log" 2>&1 &
done
wait
cat out/balance_${LABEL}_*.log | grep "^BALANCE_ROW " | sed 's/^BALANCE_ROW //' > "out/balance_${LABEL}.jsonl"
grep -h "SCRIPT ERROR" out/balance_${LABEL}_*.log | head -5
python3 -I tools/balance_report.py "out/balance_${LABEL}.jsonl" "$LABEL" TAMER_NOTES.md
