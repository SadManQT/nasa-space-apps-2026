#!/usr/bin/env bash
# M1-91 windowed capture: the dark Chapter 4 exteriors on the real LOLA terrain through Atik's TerrainStream (turned into
# a segment's frame), each under its scene's own dated (dark) JPL Horizons Sun with M3-106's stand-in for the far crater
# rim (board M3-110 brings it into TerrainStream) and no evidence light: LOC-09 at the B3 beacon corner (EX-CH04-S04) and
# at the last bend (S05), and the LOC-10 vault shelf (S06, and S07 with the tethered carrier and the probe; S08 plays on
# S07's staging, which the headless suite checks). They are lit only by the rooms' work lights (the staged rover's
# EVA-stop headlights, roof floods and cabin glow; Kai's hand light at the shelf) and the suited crew's helmet lamps.
# For each renderer (Forward+, then Compatibility): ground views (from the player's eye, then aimed at whatever is still
# unmeasured) with their lamps-off twins, a strip of the approach views after the suited player walks to each approach,
# and for S04, S05 and S06 a wide view and a strip of the lamps. The rear cargo mount is walked to and measured with
# the suited crew's helmet lamps on; work-area targets are measured without them. Every target and prop is measured (brightness,
# gain over lamps off, clipped share of its window and of the view). godot_gated invokes heavy.py once per Godot process.
set -euo pipefail
cd "$(dirname "$0")/../../.."
mkdir -p production/qa/evidence
# The ground views a shot needs vary with the staging, so earlier shots go first.
rm -f production/qa/evidence/M1-91_fplus_*.png production/qa/evidence/M1-91_compat_*.png
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
# This sandbox also cannot write the native macOS cache/user-data fixtures used by two existing suites.
# Run the complete required suite in the same outside-sandbox session; require an actual N/N printed result.
tests=production/qa/evidence/M1-91_tests.txt
if ! GODOT="$GODOT" game/tools/run_tests.sh > "$tests" 2>&1; then
  # Wall-clock performance checks can fail on a busy Mac. Retain that run and retry before treating it as a failure.
  if grep -q '^FAIL tools/test_performance_runtime.gd' "$tests"; then
    cp "$tests" production/qa/evidence/M1-91_tests_timing_first.txt
    if ! GODOT="$GODOT" game/tools/run_tests.sh > "$tests" 2>&1; then
      tail -25 "$tests"
      exit 1
    fi
  else
    tail -25 "$tests"
    exit 1
  fi
fi
python3 - "$tests" <<'PY'
import re
import sys
from pathlib import Path
line = Path(sys.argv[1]).read_text().strip().splitlines()[-1]
match = re.fullmatch(r"(\d+)/(\d+) suites passed", line)
if not match or match[1] != match[2] or int(match[2]) == 0:
    raise SystemExit("Full suite did not print N/N suites passed: " + line)
print(line)
PY
setup=production/qa/evidence/M1-91_capture_setup.txt
"$GODOT" --headless --path game --editor --quit > "$setup" 2>&1
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|Could not find type' "$setup"; then
  cat "$setup"
  exit 1
fi
for renderer in forward_plus gl_compatibility; do
  out=production/qa/evidence/M1-91_capture_${renderer}.txt
  if ! "$GODOT" --path game --windowed --resolution 1600x900 --position 40,40 --rendering-method "$renderer" \
    --script res://tools/test_terrain_work_lights.gd -- --capture > "$out" 2>&1; then
    tail -40 "$out"
    exit 1
  fi
  # Printed results are required: Godot can exit zero after a GDScript load failure.
  if ! grep -q 'TERRAIN WORK LIGHTS RESULT: PASS' "$out" || grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|Could not find type|^FAIL ' "$out"; then
    grep -E 'SCRIPT ERROR|Parse Error|^FAIL |RESULT' "$out" | head -40
    exit 1
  fi
done
for r in fplus compat; do
  for place in LOC09_B3_CH04S04 LOC09_CH04S05 LOC10_CH04S06 LOC10_CH04S07; do
    for view in ground ground_lamps_off approaches; do
      test -s "production/qa/evidence/M1-91_${r}_${place}_${view}.png"
    done
  done
  for place in LOC09_B3_CH04S04 LOC09_CH04S05 LOC10_CH04S06; do
    for view in wide lamps; do
      test -s "production/qa/evidence/M1-91_${r}_${place}_${view}.png"
    done
  done
done
grep -h 'TERRAIN WORK LIGHTS RESULT:' production/qa/evidence/M1-91_capture_forward_plus.txt \
  production/qa/evidence/M1-91_capture_gl_compatibility.txt | tee production/qa/evidence/M1-91_capture_output.txt
