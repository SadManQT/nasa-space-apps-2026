#!/usr/bin/env bash
# M3-106: captures the Chapter 4 exterior evidence in Godot (a window is needed): each LOC-09 beacon corner (B1, B2
# sunlit; B3 in terrain shadow), the last bend's sample station (EX-CH04-S05) and the LOC-10 vault shelf (S06, S07) on
# the LOLA terrain under each segment's own dated JPL Horizons Sun, the crew suited, the rover's lamps on. Writes
# production/qa/evidence/M3-106_*.png and prints the suite's result line. Run from anywhere:
#   production/qa/evidence/M3-106_capture.sh
# GODOT defaults to production/tools/godot_gated, which waits for a heavy-process slot (heavy.py).
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT=$(mktemp)
"$GODOT" --headless --path "$ROOT/game" --editor --quit >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --script res://tools/test_chapter4_rooms.gd -- --capture --only=M3-106 2>&1 \
  | grep -E "CHAPTER 4 ROOMS CAPTURE RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "CHAPTER 4 ROOMS CAPTURE RESULT: PASS" "$OUT" || { rm -f "$OUT"; exit 1; }
rm -f "$OUT"
ls "$ROOT"/production/qa/evidence/M3-106_*.png | wc -l
