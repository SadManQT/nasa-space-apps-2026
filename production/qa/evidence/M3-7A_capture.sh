#!/usr/bin/env bash
# M3-7A: captures the Chapter 7 shelter and uplink props and EN_Fabrication in Godot (a window is needed).
# Produces production/qa/evidence/M3-7A_godot_safe_room.png, _shelter_markers.png, _telemetry.png, _seed_case.png,
# _diagnostic.png, _uplink.png, _uplink_exterior.png, _fabrication.png, _route_relief.png, _lod0.png, _lod1.png and
# prints the suite's result line.
# Run from anywhere:  production/qa/evidence/M3-7A_capture.sh
# GODOT defaults to production/tools/godot_gated, which already waits for a heavy-process slot (heavy.py), so the
# windowed run is not wrapped in heavy.py a second time.
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence/M3-7A_capture_output.txt"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --resolution 1600x1000 --script res://tools/test_chapter7_assets.gd -- --evidence 2>&1 \
  | grep -E "CHAPTER7 ASSETS RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "CHAPTER7 ASSETS RESULT: PASS" "$OUT" || exit 1
for name in safe_room shelter_markers telemetry seed_case diagnostic uplink uplink_exterior fabrication route_relief lod0 lod1; do
  test -s "$ROOT/production/qa/evidence/M3-7A_godot_$name.png" || { echo "missing M3-7A_godot_$name.png"; exit 1; }
done
