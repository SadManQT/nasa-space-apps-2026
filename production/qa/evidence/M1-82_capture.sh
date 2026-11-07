#!/usr/bin/env bash
# M1-82 windowed capture: LOC-06, LOC-09 and LOC-10 on the real LOLA terrain through the TerrainStream with
# their dated Sun rig (wide and ground views) and the dated Earth on LOC-06 (its rendered size is measured). Runs from a desktop shell or the night-shift
# Claude session (not inside the Codex sandbox). godot_gated invokes heavy.py once per Godot process.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
"$GODOT" --headless --path game --import > /dev/null 2>&1 || true
"$GODOT" --path game --windowed --resolution 1600x900 --position 40,40 --script res://tools/test_exterior_terrain.gd -- --capture > production/qa/evidence/M1-82_capture.txt 2>&1 || true
# Printed results are required: Godot can exit zero after a GDScript load failure.
if ! grep -q 'EXTERIOR TERRAIN RESULT: PASS' production/qa/evidence/M1-82_capture.txt || grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' production/qa/evidence/M1-82_capture.txt; then
  grep -E 'SCRIPT ERROR|Parse Error|^FAIL |RESULT' production/qa/evidence/M1-82_capture.txt | head -40
  exit 1
fi
for shot in LOC06_CH04S09_wide LOC06_CH04S09_ground LOC06_CH04S09_ground_toward_earth LOC06_CH04S09_earth_close \
    LOC09_CH04S05_wide LOC09_CH04S05_ground LOC10_CH04S06_wide LOC10_CH04S06_ground; do
  test -s "production/qa/evidence/M1-82_${shot}.png"
done
grep RESULT production/qa/evidence/M1-82_capture.txt
