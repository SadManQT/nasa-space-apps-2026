#!/usr/bin/env bash
# M3-8R windowed capture: every Chapter 8 room in its scene state with the cast placed (the relay road at night, the
# Malapert summit under the dated Sun with the 3 % crescent Earth, the Commons and the garden), from the rooms'
# review views. Runs from the night-shift Claude session or a desktop shell (not inside the Codex sandbox).
# godot_gated invokes heavy.py once per Godot process.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
"$GODOT" --headless --path game --import > /dev/null 2>&1 || true
"$GODOT" --path game --windowed --resolution 1600x900 --position 40,40 --script res://tools/test_chapter8_rooms.gd -- --capture > production/qa/evidence/M3-8R_capture.txt 2>&1 || true
# Printed results are required: Godot can exit zero after a GDScript load failure.
if ! grep -q 'CHAPTER 8 ROOMS RESULT: PASS' production/qa/evidence/M3-8R_capture.txt || grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' production/qa/evidence/M3-8R_capture.txt; then
  grep -E 'SCRIPT ERROR|Parse Error|^FAIL |RESULT' production/qa/evidence/M3-8R_capture.txt | head -40
  exit 1
fi
for shot in S02_cab_road_start S03_cab_dark_marker S03_road_bypass S04_battery_swap S04_pad_wide S05_home_panel \
    S05_guide_light S06_packet_board S06_summit_cab_view S07_housing S07_summit_overview S08_pedestal S08_toward_earth \
    S08_earth_close S09_checksum S10_summit_cab S10_call_table S12_home_panel S12_photo_board S12_first_light; do
  test -s "production/qa/evidence/M3-8R_${shot}.png"
done
cat production/qa/evidence/M3-8R_runtime.txt
