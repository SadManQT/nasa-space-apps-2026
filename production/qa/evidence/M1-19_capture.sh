#!/usr/bin/env bash
# Run outside the sandbox when macOS prevents window registration there.
# Produces M1-19_*.png and the probe/log in this directory, using isolated saves.
set -euo pipefail
cd "$(dirname "$0")/../../.."
evidence="production/qa/evidence"
log="$evidence/M1-19_capture.log"
python3 production/tools/heavy.py /Applications/Godot.app/Contents/MacOS/Godot \
  --path game --windowed --resolution 1280x720 --position 50,50 --always-on-top \
  --script res://tools/capture_chapter1_outcomes.gd >"$log" 2>&1
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|FAIL ' "$log"; then
  cat "$log"
  exit 1
fi
grep -F 'M1-19 OUTCOME CAPTURE RESULT: PASS (0 failures)' "$log"
for name in golden bloom alo_lost mission_stopped replay_shift{1..7} debrief \
  debrief_water_sources data_card questions questions_observed large_text compact_large_text; do
  test -s "$evidence/M1-19_$name.png"
done
