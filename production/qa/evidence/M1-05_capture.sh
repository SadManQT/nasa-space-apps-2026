#!/usr/bin/env bash
# M1-05: re-captures the habitat kit evidence outside a sandbox (a window is needed for the Godot screenshots).
# Produces production/qa/evidence/M1-05_godot_kit_lod0.png, _kit_lod1.png, _room.png, _room_open.png, _corridor.png
# and prints the suite's result line. Run from the repository root:  production/qa/evidence/M1-05_capture.sh
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
python3 "$ROOT/production/tools/heavy.py" "$GODOT" --path "$ROOT/game" --resolution 1600x1000 \
  --script res://tools/test_habitat_kit.gd -- --evidence 2>&1 | grep -E "HABITAT KIT RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$ROOT/production/qa/evidence/M1-05_capture_output.txt"
grep -q "HABITAT KIT RESULT: PASS" "$ROOT/production/qa/evidence/M1-05_capture_output.txt"
