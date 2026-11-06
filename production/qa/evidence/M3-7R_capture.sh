#!/usr/bin/env bash
# M3-7R windowed capture: every Chapter 7 room in its scene state with the cast placed, plus frame timings.
# Runs from the night-shift Claude session or a desktop shell (not inside the Codex sandbox).
# godot_gated invokes heavy.py once per Godot process.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
"$GODOT" --headless --path game --import > /dev/null 2>&1 || true
"$GODOT" --path game --windowed --resolution 1600x900 --position 40,40 --script res://tools/test_chapter7_rooms.gd -- --capture > production/qa/evidence/M3-7R_capture.txt 2>&1 || true
# Printed results are required: Godot can exit zero after a GDScript load failure.
if ! grep -q 'CHAPTER 7 ROOMS RESULT: PASS' production/qa/evidence/M3-7R_capture.txt || grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' production/qa/evidence/M3-7R_capture.txt; then
  grep -E 'SCRIPT ERROR|Parse Error|^FAIL |RESULT' production/qa/evidence/M3-7R_capture.txt | head -40
  exit 1
fi
for shot in S01_mission_table S01_shared_warning S01_earth_desk S02_safe_room S02_shelter_diagram S02_roll_call_board \
    S03_five_markers S03_planning_table S04_water_wall S04_seed_case S05_player S06_first_wave S06_hatch_agrees \
    S07_last_log S07_archive_close S08_peak S09_no_answer S09_diagnostic S10_care_desk S10_fault_label \
    S11_fabrication_bench S11_route_simulator S11_kai_note S12_departure_boards S12_rover_loadout S12_chair_off_the_head; do
  test -s "production/qa/evidence/M3-7R_${shot}.png"
done
cat production/qa/evidence/M3-7R_runtime.txt
