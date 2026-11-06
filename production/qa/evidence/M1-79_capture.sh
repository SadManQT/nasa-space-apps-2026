#!/usr/bin/env bash
# M1-79: windowed captures of the commons name plate (a window is needed; run outside a sandbox). Produces, in
# production/qa/evidence/:
#   M1-79_player.png           gameplay FollowCamera at the commons_player anchor, EX-CH01-S01, Rao on the Earth screen
#   M1-79_player_sign_x2.png   the same frame around the screen and sign, 2x nearest-neighbour (real pixel size)
#   M1-79_anchor_eye.png       a standing eye (1.6 m) at the commons_player anchor, 65 degree lens
#   M1-79_display_wall.png     close view: the cable tray now clears the Earth screen; the plate beside it
#   M1-79_ch06_player.png      gameplay view in EX-CH06-S09 (eclipse desk, monitor, message log, pin board, 35 % light)
#   M1-79_ch07_pin_board.png   EX-CH07-S01: the kept ring frame and Noor's note on the pin board, under the plate
#   M1-79_capture_output.txt   the probe's SIGN PROBE lines (on-screen size and rendered letter cover per frame)
# GODOT defaults to production/tools/godot_gated (waits for a heavy-process slot), so nothing here is wrapped twice.
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
EV="$ROOT/production/qa/evidence"
OUT="$EV/M1-79_capture_output.txt"
: > "$OUT"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --windowed --resolution 1600x900 --script res://tools/probe_commons_sign.gd 2>&1 \
  | grep -E "SIGN PROBE|FAIL|SCRIPT ERROR|Parse Error" | tee -a "$OUT"
grep -q "SIGN PROBE RESULT: PASS" "$OUT" || { echo "missing: SIGN PROBE RESULT: PASS" | tee -a "$OUT"; exit 1; }
for name in player player_sign_x2 anchor_eye display_wall ch06_player ch07_pin_board; do
  test -s "$EV/M1-79_$name.png" || { echo "missing M1-79_$name.png" | tee -a "$OUT"; exit 1; }
done
echo "M1-79 CAPTURE RESULT: PASS" | tee -a "$OUT"
