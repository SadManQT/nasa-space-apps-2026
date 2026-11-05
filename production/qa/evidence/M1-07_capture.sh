#!/usr/bin/env bash
# M1-07: windowed captures (a window is needed; run outside a sandbox). Produces, in production/qa/evidence/:
#   M1-07_ui_kit_sheet_100.png, M1-07_ui_kit_sheet_150.png   the UI kit at 100 % and 150 % text
#       (and the approval copy production/concept/ui_kit/UI_Kit_sheet_v1.png)
#   M1-07_earth_desk_{rao,ferreira,recording,wide}.png        EN_EarthDesk behind the callers on the station screen
#   M1-07_garden_{alo_cutaway,tara,wide}_{seed,cotyledon,true_leaf,bud}.png   the seedlings in LOC-03
#   M1-07_hud_what_now.png, M1-07_hud_toast_and_strip.png     the clean HUD drawing the kit's SVG icons
#       (taken with the M1-54 capture, which also refreshes the M1-54_*.png shots to the current HUD)
# Order matters: Ferreira's portrait is re-rendered in its own Godot process and re-imported, and the Earth-desk
# grade is rebuilt from production/concept/earth_desk/EN_EarthDesk_render.png and re-imported, BEFORE the shots run
# in a fresh process. A Godot session that rewrites a texture keeps showing the old import (the first M1-07 shots
# showed the old opaque navy portrait for this reason).
# GODOT defaults to production/tools/godot_gated (waits for a heavy-process slot), so nothing here is wrapped twice.
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
EV="$ROOT/production/qa/evidence"
OUT="$EV/M1-07_capture_output.txt"
: > "$OUT"
import() { "$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true; }
run() {  # run <result line> <godot args...>; the printed result line is the only trusted signal
  local want=$1; shift
  "$GODOT" --path "$ROOT/game" --windowed "$@" 2>&1 | grep -E "RESULT|FAIL|SCRIPT ERROR|Parse Error|evidence|PROBE|SHEET" | tee -a "$OUT"
  grep -q "$want" "$OUT" || { echo "missing: $want" | tee -a "$OUT"; exit 1; }
}
import
run "EARTH SCREEN PROBE RESULT: PASS" --resolution 1376x768 --script res://tools/probe_earth_screen.gd -- --portrait
python3 "$ROOT/production/concept/earth_desk/compose_earth_desk.py" | tee -a "$OUT"
import
sed -i '' '/EARTH SCREEN PROBE RESULT: PASS/d' "$OUT"
run "EARTH SCREEN PROBE RESULT: PASS" --resolution 1280x720 --script res://tools/probe_earth_screen.gd -- --shots
run "UI KIT SHEET RESULT: PASS" --resolution 1600x1000 --script res://tools/probe_ui_kit_sheet.gd -- --out "$EV"
run "PLANT SEEDLINGS RESULT: PASS" --resolution 1600x900 --script res://tools/test_plant_seedlings.gd -- --evidence
run "M1-54 CAPTURE RESULT: PASS" --resolution 1280x720 --script res://tools/capture_hud_m154.gd
cp "$EV/M1-54_what_now.png" "$EV/M1-07_hud_what_now.png"
cp "$EV/M1-54_toast_and_strip.png" "$EV/M1-07_hud_toast_and_strip.png"
for name in ui_kit_sheet_100 ui_kit_sheet_150 earth_desk_rao earth_desk_ferreira earth_desk_recording earth_desk_wide \
            garden_alo_cutaway_seed garden_alo_cutaway_cotyledon garden_alo_cutaway_true_leaf garden_tara_true_leaf garden_wide_true_leaf \
            hud_what_now hud_toast_and_strip; do
  test -s "$EV/M1-07_$name.png" || { echo "missing M1-07_$name.png" | tee -a "$OUT"; exit 1; }
done
echo "M1-07 CAPTURE RESULT: PASS" | tee -a "$OUT"
