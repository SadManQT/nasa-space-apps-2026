#!/usr/bin/env bash
# M1-34: in-game captures of the LOLA terrain tiles (Godot 4.7, windowed, Forward+) and the
# side-by-side review sheets. Run from any directory; needs the tiles already built by
# production/tools/build_terrain_tiles.py. Outputs:
#   production/qa/evidence/M1-34_<region>_{topdown,ground,vista}.png
#   production/qa/evidence/M1-34_capture_output.txt
#   production/review/M1-34_<region>_lola_vs_game.png
# GODOT may be the Godot binary (then it runs through production/tools/heavy.py, the two-at-a-time
# gate) or production/tools/godot_gated, which already holds the gate.
set -euo pipefail
cd "$(dirname "$0")/../../.."
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
case "$GODOT" in
  *godot_gated) run=("$GODOT") ;;
  *) run=(python3 production/tools/heavy.py "$GODOT") ;;
esac
out="production/qa/evidence/M1-34_capture_output.txt"
"${run[@]}" --headless --path game --editor --quit >/dev/null 2>&1 || true
"${run[@]}" --path game --windowed --resolution 1600x900 --position 60,60 \
  --script res://tools/capture_terrain_m134.gd >"$out" 2>&1 || true
grep -E 'TERRAIN CAPTURE RESULT|capture |FAIL' "$out" || true
grep -q 'TERRAIN CAPTURE RESULT: PASS' "$out"
python3 production/tools/make_terrain.py review
