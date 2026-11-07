#!/usr/bin/env bash
# M3-8A: captures the Chapter 8 summit and road pieces, VH_Rover's lights and the Dhaka rooftop screen in Godot
# (a window is needed). Produces production/qa/evidence/M3-8A_godot_summit.png, _housing.png, _lods.png, _road.png,
# _rooftop_screen.png, _rooftop_noon.png and prints the suite's result line.
# Run from anywhere:  production/qa/evidence/M3-8A_capture.sh
# GODOT defaults to production/tools/godot_gated, which already waits for a heavy-process slot (heavy.py).
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence/M3-8A_capture_output.txt"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --resolution 1600x900 --script res://tools/test_chapter8_assets.gd -- --evidence 2>&1 \
  | grep -E "CHAPTER8 ASSETS RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "CHAPTER8 ASSETS RESULT: PASS" "$OUT" || exit 1
for name in summit housing lods road rooftop_screen rooftop_noon; do
  test -s "$ROOT/production/qa/evidence/M3-8A_godot_$name.png" || { echo "missing M3-8A_godot_$name.png"; exit 1; }
done
