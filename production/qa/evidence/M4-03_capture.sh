#!/usr/bin/env bash
# M4-03: capture the real cutscene player closing CS-18 on the D13 dedication, window on top.
# Writes M4-03_dedication_opt02_7.5s.png, M4-03_dedication_opt02_8.5s.png and
# M4-03_dedication_opt01_7.5s.png here, and the probe log M4-03_capture_output.txt.
# godot_gated already waits through heavy.py (do not double-lock it). No credits or network.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$ROOT"
GODOT=${GODOT:-/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence"
exec > >(tee "$OUT/M4-03_capture_output.txt") 2>&1

"$GODOT" --headless --path "$ROOT/game" --editor --quit >/dev/null 2>&1 || true
log=$(mktemp "${TMPDIR:-/tmp}/m403_capture.XXXXXX")
trap 'rm -f "$log"' EXIT
"$GODOT" --path "$ROOT/game" --windowed --resolution 1280x720 --script res://tools/capture_m4_03.gd >"$log" 2>&1 || true
grep -E '^M4-03|SCRIPT ERROR|Parse Error|Failed to load script' "$log" || true
if grep -qE 'SCRIPT ERROR|Parse Error|Failed to load script' "$log" || ! grep -q 'M4-03 CAPTURE RESULT: PASS' "$log"; then
  echo "M4-03 capture FAILED"
  exit 1
fi
echo "M4-03 capture complete"
