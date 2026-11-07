#!/usr/bin/env bash
# M3-4A: captures the Chapter 4 asset evidence in Godot (a window is needed for the screenshots).
# Produces production/qa/evidence/M3-4A_godot_bay.png, _exterior.png, _ready.png, _dock.png, _porch.png,
# _coldtrap_pieces.png and _vault_set.png and prints the suite's result line. Run from anywhere:
#   production/qa/evidence/M3-4A_capture.sh
# GODOT defaults to production/tools/godot_gated, which waits for a heavy-process slot (heavy.py).
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence/M3-4A_capture_output.txt"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --resolution 1600x1000 --script res://tools/test_ch04_assets.gd -- --evidence 2>&1 \
  | grep -E "CH04_ASSETS RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "CH04_ASSETS RESULT: PASS" "$OUT" || exit 1
for name in bay exterior ready dock porch coldtrap_pieces vault_set; do
  test -s "$ROOT/production/qa/evidence/M3-4A_godot_$name.png" || { echo "missing M3-4A_godot_$name.png"; exit 1; }
done
