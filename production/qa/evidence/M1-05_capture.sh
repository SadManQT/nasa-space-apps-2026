#!/usr/bin/env bash
# M1-05: re-captures the habitat kit evidence outside a sandbox (a window is needed for the Godot screenshots).
# Produces production/qa/evidence/M1-05_godot_kit_lod0.png, _kit_lod1.png, _room.png, _room_open.png, _corridor.png
# and prints the suite's result line. Run from anywhere:  production/qa/evidence/M1-05_capture.sh
# GODOT defaults to production/tools/godot_gated, which already waits for a heavy-process slot (heavy.py), so the
# windowed run is not wrapped in heavy.py a second time.
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence/M1-05_capture_output.txt"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --resolution 1600x1000 --script res://tools/test_habitat_kit.gd -- --evidence 2>&1 \
  | grep -E "HABITAT KIT RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "HABITAT KIT RESULT: PASS" "$OUT" || exit 1
for name in kit_lod0 kit_lod1 room room_open corridor; do
  test -s "$ROOT/production/qa/evidence/M1-05_godot_$name.png" || { echo "missing M1-05_godot_$name.png"; exit 1; }
done
