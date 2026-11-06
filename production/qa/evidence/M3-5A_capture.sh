#!/usr/bin/env bash
# M3-5A: captures the Chapter 5 asset evidence (a window is needed for the Godot screenshots).
# Produces production/qa/evidence/M3-5A_godot_cotton_stages.png, _cotton_stress.png, _bridge_sleeve.png,
# _bridge_records.png, _bridge_tape.png, _impact_candidate.png, _impact_paired_reference.png and
# _impact_artifact_rejection.png, and writes the suite's result line to M3-5A_capture_output.txt.
# Run from anywhere:  production/qa/evidence/M3-5A_capture.sh
# GODOT defaults to production/tools/godot_gated, which already waits for a heavy-process slot (heavy.py); the
# watchdog below counts that wait too, so CAPTURE_TIMEOUT (seconds, default 1200) leaves room for a busy queue.
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence/M3-5A_capture_output.txt"
SHOTS="cotton_stages cotton_stress bridge_sleeve bridge_records bridge_tape impact_candidate impact_paired_reference impact_artifact_rejection"
for name in $SHOTS; do rm -f "$ROOT/production/qa/evidence/M3-5A_godot_$name.png"; done
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
LOG=$(mktemp)
"$GODOT" --path "$ROOT/game" --resolution 1600x1000 --script res://tools/test_ch05_assets.gd -- --evidence >"$LOG" 2>&1 &
pid=$!
# macOS has no `timeout`: give the windowed run CAPTURE_TIMEOUT seconds (queue wait included), then stop it
LIMIT=${CAPTURE_TIMEOUT:-1200}
for _ in $(seq "$LIMIT"); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
kill -0 "$pid" 2>/dev/null && { kill "$pid"; echo "TIMEOUT after $LIMIT s" >>"$LOG"; }
wait "$pid" 2>/dev/null
grep -E "CH05 ASSETS RESULT|FAIL|SCRIPT ERROR|Parse Error|TIMEOUT" "$LOG" | tee "$OUT"
rm -f "$LOG"
grep -q "CH05 ASSETS RESULT: PASS" "$OUT" || exit 1
for name in $SHOTS; do
  test -s "$ROOT/production/qa/evidence/M3-5A_godot_$name.png" || { echo "missing M3-5A_godot_$name.png" | tee -a "$OUT"; exit 1; }
done
echo "M3-5A capture: 8 screenshots written" | tee -a "$OUT"
