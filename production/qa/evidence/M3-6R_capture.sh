#!/usr/bin/env bash
# M3-6R windowed capture: every Chapter 6 room in its scene state with the cast placed, plus frame timings.
# Runs from the night-shift Claude session or a desktop shell (not inside the Codex sandbox).
# godot_gated invokes heavy.py once per Godot process.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
"$GODOT" --headless --path game --import > /dev/null 2>&1 || true
"$GODOT" --path game --windowed --resolution 1600x900 --position 40,40 --script res://tools/test_chapter6_rooms.gd -- --capture > production/qa/evidence/M3-6R_capture.txt 2>&1 || true
# Printed results are required: Godot can exit zero after a GDScript load failure.
if ! grep -q 'CHAPTER 6 ROOMS RESULT: PASS' production/qa/evidence/M3-6R_capture.txt || grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' production/qa/evidence/M3-6R_capture.txt; then
  grep -E 'SCRIPT ERROR|Parse Error|^FAIL |RESULT' production/qa/evidence/M3-6R_capture.txt | head -40
  exit 1
fi
for shot in S01_power_room S01_player S01_marker_tape S01_hand_light_locker S02_personal_log S03_allocation_board S04_floods_and_guide S05_test_panel \
    S06_mission_table S06_eclipse_desk S07_red_ring S09_message_log S10_f2_dark S10_f2_fault_close S10_guide_light S10_player_lamp S10_lamp_on_kai \
    S11_debrief_board S11_camera_restored S12_monitoring_calendar S12_cotton CH07_pinned_note; do
  test -s "production/qa/evidence/M3-6R_${shot}.png"
done
cat production/qa/evidence/M3-6R_runtime.txt
