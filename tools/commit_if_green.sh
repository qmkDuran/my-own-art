#!/usr/bin/env bash
# Run every check; commit and push only when they all pass. Usage: tools/commit_if_green.sh "message"
set -u
cd "$(dirname "$0")/.."
bash tools/run_all.sh > /tmp/lanternfall_checks.log 2>&1
tail -8 /tmp/lanternfall_checks.log
grep -q "^ALL CHECKS PASS" /tmp/lanternfall_checks.log || { echo "NOT COMMITTED: checks failed"; exit 1; }
git add -A
git commit -qm "$1

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01YABBJVPWvaqtn34m5VQVCp"
for d in 2 4 8 16; do git push -u origin lanternfall -q && break || sleep $d; done
git log --oneline -1
