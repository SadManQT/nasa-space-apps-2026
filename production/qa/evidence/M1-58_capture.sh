#!/usr/bin/env bash
# Run outside the sandbox on Sadman's logged-in desktop. Isolated save data;
# the gated executable invokes production/tools/heavy.py for every capture.
set -euo pipefail
cd "$(dirname "$0")/../../.."
GODOT="/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated"
evidence="$PWD/production/qa/evidence"
output="$evidence/M1-58_capture.txt"
screens=(briefing carrying bunk_slots paused partial_report empty_report assisted_select full_report large_text_briefing large_text_assisted)
for screen in "${screens[@]}"; do rm -f "$evidence/M1-58_${screen}.png"; done
rm -f "$evidence/M1-58_capture_probes.json"
"$GODOT" --path game --windowed --resolution 1280x720 \
  --rendering-method forward_plus --rendering-driver metal \
  --log-file "$evidence/M1-58_capture_engine.log" \
  --script res://tools/capture_payload.gd >"$output" 2>&1 &
capture_pid=$!
trap 'kill "$capture_pid" 2>/dev/null || true; wait "$capture_pid" 2>/dev/null || true' EXIT
for ((second=0; second<240; second++)); do
  kill -0 "$capture_pid" 2>/dev/null || break
  sleep 1
done
if kill -0 "$capture_pid" 2>/dev/null; then
  echo 'PAYLOAD CAPTURE RESULT: FAIL (240-second timeout)' >>"$output"
  cat "$output"
  exit 1
fi
capture_rc=0
wait "$capture_pid" || capture_rc=$?
trap - EXIT
cat "$output"
[[ "$capture_rc" -eq 0 ]] || exit "$capture_rc"
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|String formatting error' "$output"; then exit 1; fi
grep -q '^PAYLOAD CAPTURE RESULT: PASS (0 failures)$' "$output"
python3 - <<'PY'
import json
import struct
from pathlib import Path
evidence = Path('production/qa/evidence')
screens = 'briefing carrying bunk_slots paused partial_report empty_report assisted_select full_report large_text_briefing large_text_assisted'.split()
for screen in screens:
    path = evidence / f'M1-58_{screen}.png'
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n' and len(data) > 1024, path
    assert struct.unpack('>II', data[16:24]) == (1280, 720), path
probes = json.loads((evidence / 'M1-58_capture_probes.json').read_text())
assert probes and all(probes.values()), probes
print(f'M1-58 evidence verified: {len(screens)} screenshots, {len(probes)} passing probes')
PY
