#!/usr/bin/env bash
# M3-2A: re-captures the Chapter 2 asset evidence outside a sandbox (a window is needed for the Godot screenshots).
# Produces production/qa/evidence/M3-2A_godot_vestibule.png, _pass_through.png, _panel_safe.png, _panel_equalising.png,
# _panel_sealed.png, _chamber.png, _props.png, _paper_bee.png and prints the suite's result line. Run from anywhere:
#   production/qa/evidence/M3-2A_capture.sh
# GODOT defaults to production/tools/godot_gated, which already waits for a heavy-process slot (heavy.py).
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence/M3-2A_capture_output.txt"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --resolution 1600x1000 --script res://tools/test_en_airlock.gd -- --evidence 2>&1 \
  | grep -E "EN_AIRLOCK RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "EN_AIRLOCK RESULT: PASS" "$OUT" || exit 1
for name in vestibule pass_through panel_safe panel_equalising panel_sealed chamber props paper_bee; do
  test -s "$ROOT/production/qa/evidence/M3-2A_godot_$name.png" || { echo "missing M3-2A_godot_$name.png"; exit 1; }
done
