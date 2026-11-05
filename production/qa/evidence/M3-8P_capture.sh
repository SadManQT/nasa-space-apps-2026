#!/usr/bin/env bash
# M3-8P: windowed screenshots of the Chapter 8 puzzle panel (P-15 Two Teams, One Road and
# P-16 The Link and the Living Garden) in the real campaign HUD: team boards, the held shortcut,
# the repeater procedure card, the home loop thirst forecast, both antenna dials, the ALO42
# near match, the five sunrise checks at 150% text and the dedication, plus the campaign
# completing from the player's own decisions. Run from the repository root after run_tests.sh
# has imported assets:  production/qa/evidence/M3-8P_capture.sh
# Writes production/qa/evidence/M3-8P_*.png and M3-8P_capture_probe.txt.
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence"
fail=0
"$GODOT" --path "$ROOT/game" --windowed --resolution 1280x720 --script res://tools/capture_chapter8_puzzles.gd >"$OUT/M3-8P_capture.log" 2>&1
grep -q "M3-8P CHAPTER 8 PUZZLE CAPTURE RESULT: PASS" "$OUT/M3-8P_capture.log" || { echo "M3-8P: windowed capture failed"; tail -20 "$OUT/M3-8P_capture.log"; fail=1; }
[ "$fail" -eq 0 ] && echo "M3-8P capture: PASS" && rm -f "$OUT/M3-8P_capture.log"
exit "$fail"
