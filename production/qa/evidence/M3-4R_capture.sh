#!/usr/bin/env bash
# M3-4R: captures the Chapter 4 base-room evidence in Godot (a window is needed): EX-CH04-S01 and S10 in the garden
# (the October count beside the May prediction with the D2/D4/D6 echoes, the limits card, the rover checklist; vault V12
# open in the dry glovebox with the lid inscription, the manifest with N.'s cotton note, everyone home) and S11 and S12
# in the Commons (the Earth desk with Ferreira's empty chair, the saved inscription and claims, the relief flight, the
# fifth locker, the days in between). Writes production/qa/evidence/M3-4R_*.png and prints the result line. Run from
# anywhere:
#   production/qa/evidence/M3-4R_capture.sh
# GODOT defaults to production/tools/godot_gated, which waits for a heavy-process slot (heavy.py).
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT=$(mktemp)
"$GODOT" --headless --path "$ROOT/game" --editor --quit >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --script res://tools/test_chapter4_rooms.gd -- --capture --only=M3-4R 2>&1 \
  | grep -E "CHAPTER 4 ROOMS CAPTURE RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "CHAPTER 4 ROOMS CAPTURE RESULT: PASS" "$OUT" || { rm -f "$OUT"; exit 1; }
rm -f "$OUT"
ls "$ROOT"/production/qa/evidence/M3-4R_*.png | wc -l
