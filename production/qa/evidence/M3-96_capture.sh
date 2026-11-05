#!/usr/bin/env bash
# M3-96 evidence capture (Tara's lifecycle in code). Nothing in this task draws a new
# screen: the only player-visible change is one P-06 ledger note line, which the
# headless probe prints verbatim. Run from the checkout root:
#   bash production/qa/evidence/M3-96_capture.sh
# Produces production/qa/evidence/M3-96_tara_lifecycle.txt (dated Tara records, the
# working-stock and founder ledgers before and after, the HUD note lines) and
# M3-96_run_tests.txt (the full suite output; its last line must read N/N suites passed).
set -u
cd "$(dirname "$0")/../../.." || exit 2
GODOT="${GODOT:-/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated}"
[ -x "$GODOT" ] || GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path game --script res://tools/probe_m3_96_tara.gd 2>&1 | tee production/qa/evidence/M3-96_probe_stdout.txt
grep -q "M3-96 PROBE RESULT: PASS" production/qa/evidence/M3-96_tara_lifecycle.txt || { echo "probe did not pass"; exit 1; }
rm -f production/qa/evidence/M3-96_probe_stdout.txt
GODOT="$GODOT" game/tools/run_tests.sh > production/qa/evidence/M3-96_run_tests.txt 2>&1
tail -1 production/qa/evidence/M3-96_run_tests.txt
