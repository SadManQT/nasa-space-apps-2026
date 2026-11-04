#!/usr/bin/env bash
# Run outside the sandbox if macOS refuses window registration there.
# Captures the production source-card UI without loading or changing any save.
set -euo pipefail
cd "$(dirname "$0")/../../.."
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
evidence="production/qa/evidence"
# Keep import diagnostics temporary and retain only one capture transcript.
import_log=$(mktemp)
trap 'rm -f "$import_log"' EXIT
capture_output="$evidence/M1-44_capture_output.txt"
"$GODOT" --headless --path game --editor --quit >"$import_log" 2>&1
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script' "$import_log"; then
  cat "$import_log"
  exit 1
fi
"$GODOT" --path game --windowed --resolution 1280x720 --position 80,80 \
  --script res://tools/capture_science_cards.gd >"$capture_output" 2>&1
cat "$capture_output"
grep -q 'SCIENCE CARD CAPTURE RESULT: PASS (0 failures)' "$capture_output"
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script' "$capture_output"; then
  exit 1
fi
for name in sky_card storm_card plants_card sky_card_large_text; do
  test -s "$evidence/M1-44_$name.png"
done
