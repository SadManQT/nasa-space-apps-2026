#!/usr/bin/env bash
# M3-6A: re-captures the Chapter 6 eclipse power props evidence (a window is needed for the Godot screenshots).
# Produces production/qa/evidence/M3-6A_props_lod0.png, _props_lod1.png, _power_room.png, _panel_f2_tripped.png,
# _panel_f2_isolated.png, _board_plan.png, _s04_floods_on.png, _s04_guide_only.png, _monitor_ring.png,
# _monitor_screen_ring.png, _monitor_screen_ingress.png, _monitor_screen_no_signal.png and _camera_exterior.png,
# and prints the suite's result line. Run from anywhere:  production/qa/evidence/M3-6A_capture.sh
# GODOT defaults to production/tools/godot_gated, which already waits for a heavy-process slot (heavy.py).
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence/M3-6A_capture_output.txt"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --resolution 1600x1000 --script res://tools/test_eclipse_props.gd -- --evidence 2>&1 \
  | grep -E "ECLIPSE PROPS RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "ECLIPSE PROPS RESULT: PASS" "$OUT" || exit 1
for name in props_lod0 props_lod1 power_room panel_f2_tripped panel_f2_isolated board_plan s04_floods_on s04_guide_only \
            monitor_ring monitor_screen_ring monitor_screen_ingress monitor_screen_no_signal camera_exterior; do
  test -s "$ROOT/production/qa/evidence/M3-6A_$name.png" || { echo "missing M3-6A_$name.png"; exit 1; }
done
