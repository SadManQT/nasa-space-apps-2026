#!/usr/bin/env bash
# Run outside the Codex sandbox. godot_gated runs each Godot process through heavy.py.
# Capture this checkout's materials and garden, then retake the original M3-3R review shots.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
EVIDENCE=production/qa/evidence

require_pass() {
  local log="$1" result="$2"
  if ! grep -Fq "$result" "$log" || grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|^ERROR:|^FAIL ' "$log"; then
    cat "$log"
    exit 1
  fi
}

"$GODOT" --headless --path game --editor --quit > "$EVIDENCE/M3-108_import.txt" 2>&1
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|^ERROR:' "$EVIDENCE/M3-108_import.txt"; then
  cat "$EVIDENCE/M3-108_import.txt"
  exit 1
fi
"$GODOT" --headless --path game --script res://tools/test_ch03_assets.gd > "$EVIDENCE/M3-108_ch03_assets.txt" 2>&1
# test_ch03_assets.gd prints one expected "ERROR: HelmetRoles: unknown role" (its unknown-role check), so only its result line counts
grep -Fq 'CH03 ASSETS RESULT: PASS' "$EVIDENCE/M3-108_ch03_assets.txt" && ! grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' "$EVIDENCE/M3-108_ch03_assets.txt" || { cat "$EVIDENCE/M3-108_ch03_assets.txt"; exit 1; }
"$GODOT" --headless --path game --script res://tools/capture_m3108_petal.gd -- --probe-only > "$EVIDENCE/M3-108_materials_output.txt" 2>&1
require_pass "$EVIDENCE/M3-108_materials_output.txt" 'M3-108 MATERIAL PROBE RESULT: PASS'

# macOS throttles covered windows. Keep this single capture on top of other apps.
"$GODOT" --path game --windowed --always-on-top --resolution 1600x900 --position 200,120 \
  --script res://tools/capture_m3108_petal.gd > "$EVIDENCE/M3-108_capture.txt" 2>&1
require_pass "$EVIDENCE/M3-108_capture.txt" 'M3-108 PETAL CAPTURE RESULT: PASS'
for shot in S11_review_view S11_review_view_zoom S11_petal_closeup S12_board_petal_and_tara S10_bench_sleeve; do
  test -s "$EVIDENCE/M3-108_${shot}.png"
done

bash "$EVIDENCE/M3-3R_capture.sh" > "$EVIDENCE/M3-108_m3-3r_rerun.txt" 2>&1
require_pass "$EVIDENCE/M3-3R_capture.txt" 'CHAPTER 3 ROOMS RESULT: PASS'
for shot in S11_petal_on_board S12_lineage_board; do
  test -s "$EVIDENCE/M3-3R_${shot}.png"
done
cat "$EVIDENCE/M3-108_probe.txt"
cat "$EVIDENCE/M3-108_m3-3r_rerun.txt"
