#!/usr/bin/env bash
# M3-105: captures the LOC-08 garage evidence in Godot (a window is needed for the screenshots): every garage scene
# (CH04-S02, S03, S09, CH05-S01, CH07-S12, CH08-S11), the dock panel SEALED and EQUALISING with its time card, and the
# garage on the LOLA Aurora ridge under the dated EX-CH04-S02 Sun. Writes production/qa/evidence/M3-105_*.png and
# prints the suite's result line. Run from anywhere:
#   production/qa/evidence/M3-105_capture.sh
# GODOT defaults to production/tools/godot_gated, which waits for a heavy-process slot (heavy.py).
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT=$(mktemp)
"$GODOT" --headless --path "$ROOT/game" --editor --quit >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --script res://tools/test_chapter4_rooms.gd -- --capture --only=M3-105 2>&1 \
  | grep -E "CHAPTER 4 ROOMS CAPTURE RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "CHAPTER 4 ROOMS CAPTURE RESULT: PASS" "$OUT" || { rm -f "$OUT"; exit 1; }
rm -f "$OUT"
ls "$ROOT"/production/qa/evidence/M3-105_*.png | wc -l
