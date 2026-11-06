#!/usr/bin/env bash
# M3-3A: captures the Chapter 3 asset evidence outside a sandbox (a window is needed for the Godot screenshots).
# Produces production/qa/evidence/M3-3A_annex_pieces.png, _annex_corridor.png, _annex_hatch_open.png, _annex_cold.png,
# _helmet_roles.png, _descendants.png, _descendants_closeup.png, _pressed_petal.png and prints the suite's result line. Run from anywhere:
#   production/qa/evidence/M3-3A_capture.sh
# GODOT defaults to production/tools/godot_gated, which already waits for a heavy-process slot (heavy.py), so the
# windowed run is not wrapped in heavy.py a second time.
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence/M3-3A_capture_output.txt"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --resolution 1600x1000 --script res://tools/test_ch03_assets.gd -- --evidence 2>&1 \
  | grep -E "CH03 ASSETS RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "CH03 ASSETS RESULT: PASS" "$OUT" || exit 1
for name in annex_pieces annex_corridor annex_hatch_open annex_cold helmet_roles descendants descendants_closeup pressed_petal; do
  test -s "$ROOT/production/qa/evidence/M3-3A_$name.png" || { echo "missing M3-3A_$name.png"; exit 1; }
done
