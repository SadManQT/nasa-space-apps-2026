#!/usr/bin/env bash
# M1-84 windowed capture: the S02 roll-call lamp blink (requested), the S03 drawer blink, the four mugs before and
# after CH01-MUGS-NAMED, and both Care Round photo frames on two dates. Runs from a desktop shell or the night-shift
# Claude session (not inside the Codex sandbox). godot_gated invokes heavy.py once per Godot process.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
"$GODOT" --headless --path game --import > /dev/null 2>&1 || true
"$GODOT" --path game --windowed --resolution 1600x900 --position 40,40 --script res://tools/test_ch01_room_hooks.gd -- --capture > production/qa/evidence/M1-84_capture.txt 2>&1 || true
# Printed results are required: Godot can exit zero after a GDScript load failure.
if ! grep -q 'CH01 ROOM HOOKS RESULT: PASS' production/qa/evidence/M1-84_capture.txt || grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' production/qa/evidence/M1-84_capture.txt; then
  grep -E 'SCRIPT ERROR|Parse Error|^FAIL |RESULT' production/qa/evidence/M1-84_capture.txt | head -40
  exit 1
fi
for shot in S02_lamp_dark S02_lamp_blink S02_roll_call_wide_dark S03_drawer_dark S03_drawer_blink S12_mugs_nameless S12_mugs_named \
    care_alo_0412 care_tara_0412 care_alo_0416 care_tara_0416; do
  test -s "production/qa/evidence/M1-84_${shot}.png"
done
grep RESULT production/qa/evidence/M1-84_capture.txt
