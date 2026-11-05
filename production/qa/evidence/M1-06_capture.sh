#!/usr/bin/env bash
# Windowed capture (runs from the night-shift Claude session or a desktop shell; not inside the Codex
# sandbox). godot_gated invokes heavy.py once per Godot process.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
GODOT="$GODOT" game/tools/run_tests.sh > production/qa/evidence/M1-06_tests.txt 2>&1
tail -n 1 production/qa/evidence/M1-06_tests.txt
# The runner requires a passing printed result from every suite; it imports first.
"$GODOT" --path game --windowed --resolution 1600x900 --position 40,40 --script res://tools/test_habitat_rooms.gd -- --capture > production/qa/evidence/M1-06_capture.txt 2>&1
# Printed results are required: Godot can exit zero after a GDScript load failure.
grep -q 'HABITAT ROOMS RESULT: PASS' production/qa/evidence/M1-06_capture.txt
if grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' production/qa/evidence/M1-06_capture.txt; then
  cat production/qa/evidence/M1-06_capture.txt
  exit 1
fi
for room in 01 02 03 04; do
  test -s "production/qa/evidence/M1-06_LOC-${room}_overview.png"
  test -s "production/qa/evidence/M1-06_LOC-${room}_player.png"
done
test -s production/qa/evidence/M1-06_LOC-03_chamber.png
test -s production/qa/evidence/M1-06_LOC-03_chamber_closed.png
test -s production/qa/evidence/M1-06_LOC-03_alo.png
test -s production/qa/evidence/M1-06_LOC-04_hatch.png
test -s production/qa/evidence/M1-06_campaign.png
cat production/qa/evidence/M1-06_runtime.txt
