#!/usr/bin/env bash
# M3-94: windowed screenshots of the three approved lines in the campaign HUD caption bar
# (Amara "Forty-two." in EX-CH03-S10; Rao and Noor on the restored Earth link in EX-CH08-S10),
# plus the headless caption-order probe. Run from the repository root after run_tests.sh has
# imported assets:  production/qa/evidence/M3-94_capture.sh
# Writes production/qa/evidence/M3-94_ch03_s10_amara_forty_two.png, M3-94_ch08_s10_rao_channel_open.png,
# M3-94_ch08_s10_noor_reply.png, M3-94_capture_probes.json and M3-94_catalog_probe.txt.
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence"
fail=0
"$GODOT" --headless --path "$ROOT/game" --script res://tools/probe_m3_94_lines.gd >"$OUT/M3-94_probe.log" 2>&1
grep -q "M3-94 PROBE RESULT: PASS" "$OUT/M3-94_probe.log" || { echo "M3-94: caption probe failed"; fail=1; }
"$GODOT" --path "$ROOT/game" --windowed --resolution 1280x720 --script res://tools/capture_m3_94_lines.gd >"$OUT/M3-94_capture.log" 2>&1
grep -q "M3-94 CAPTURE RESULT: PASS" "$OUT/M3-94_capture.log" || { echo "M3-94: windowed capture failed"; tail -20 "$OUT/M3-94_capture.log"; fail=1; }
rm -f "$OUT/M3-94_probe.log"
[ "$fail" -eq 0 ] && echo "M3-94 capture: PASS" && rm -f "$OUT/M3-94_capture.log"
exit "$fail"
