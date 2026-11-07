#!/usr/bin/env bash
# M3-5R windowed capture: every Chapter 5 room in its scene state with the cast placed, plus frame timings.
# Runs from Sadman's Claude session, the night shift or a desktop shell (not inside the Codex sandbox).
# godot_gated invokes heavy.py once per Godot process. If the window does not draw (macOS reports it covered),
# bring Godot to the front: osascript -e 'tell application "Godot" to activate'.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
"$GODOT" --headless --path game --import > /dev/null 2>&1 || true
"$GODOT" --path game --windowed --resolution 1600x900 --position 40,40 --script res://tools/test_chapter5_rooms.gd -- --capture > production/qa/evidence/M3-5R_capture.txt 2>&1 || true
# Printed results are required: Godot can exit zero after a GDScript load failure.
if ! grep -q 'CHAPTER 5 ROOMS RESULT: PASS' production/qa/evidence/M3-5R_capture.txt || grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' production/qa/evidence/M3-5R_capture.txt; then
  grep -E 'SCRIPT ERROR|Parse Error|^FAIL |RESULT' production/qa/evidence/M3-5R_capture.txt | head -40
  exit 1
fi
for shot in S01_pad_camera S01_relief_locker S01_player \
    S02_spare_crate S02_inventory_board S02_atmosphere_panel S02_second_gauge S02_watch_and_sleeve \
    S03_records S03_sleeve S04_archive_images S04_records_in_order S05_shared_seating S05_margin_note S05_revised_caption \
    S06_records_desk S06_kai_note S06_mei_question S07_impact_monitor S07_night_observation \
    S08_maintenance_console S08_garden_spur S08_mug_at_the_watch S09_bounded_report S09_evidence_table \
    S10_signed_page S10_rao_live S11_composer S11_mug_beside_four \
    S12_cotton_in_taras_bay S12_noor_text S12_vault_ledger S12_founder_ledger S12_player; do
  test -s "production/qa/evidence/M3-5R_${shot}.png"
done
cat production/qa/evidence/M3-5R_runtime.txt
