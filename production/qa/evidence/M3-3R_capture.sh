#!/usr/bin/env bash
# M3-3R windowed capture: every Chapter 3 room in its scene state with the cast placed (the annex warm bay and the
# cold annex below it included), plus frame timings.
# Runs from the night-shift Claude session or a desktop shell (not inside the Codex sandbox).
# godot_gated invokes heavy.py once per Godot process. If the window does not draw because it sits behind other
# windows, this brings Godot to the front.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
"$GODOT" --headless --path game --import > /dev/null 2>&1 || true
(sleep 6; osascript -e 'tell application "Godot" to activate' > /dev/null 2>&1 || true) &
"$GODOT" --path game --windowed --resolution 1600x900 --position 40,40 --script res://tools/test_chapter3_rooms.gd -- --capture > production/qa/evidence/M3-3R_capture.txt 2>&1 || true
# Printed results are required: Godot can exit zero after a GDScript load failure.
if ! grep -q 'CHAPTER 3 ROOMS RESULT: PASS' production/qa/evidence/M3-3R_capture.txt || grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' production/qa/evidence/M3-3R_capture.txt; then
  grep -E 'SCRIPT ERROR|Parse Error|^FAIL |RESULT' production/qa/evidence/M3-3R_capture.txt | head -40
  exit 1
fi
for shot in S01_red_warning S01_diagnostic_board S01_independent_gauge S02_three_taps S02_garden_spur_tap \
    S03_isolation_preview S03_repair_diagram S03_ferreira_earth_link S04_clamp_and_boundary S05_five_checks \
    S05_warning_cleared S05_gauge_on_its_hook S06_nr_hatch S06_camera_feed S06_ferreira_earth_link S06_safety_drawing \
    S07_suited_descent S07_cold_side S07_frozen_trays S07_growth_chart S07_warm_side_station S07_player_eva \
    S08_evidence_table S08_map_is_a_plan S09_maturity S09_drydown S10_forty_two S10_vigil_photos S10_alo_nameplate \
    S11_twelve_positions S11_reserve_sealed S11_petal_on_board S12_tara_farewell S12_lineage_board \
    S12_days_in_between S12_survey_board S12_october_rack; do
  test -s "production/qa/evidence/M3-3R_${shot}.png"
done
cat production/qa/evidence/M3-3R_runtime.txt
