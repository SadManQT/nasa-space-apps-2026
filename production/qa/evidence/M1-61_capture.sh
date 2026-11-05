#!/usr/bin/env bash
# Run from a logged-in desktop outside the Codex sandbox. Isolated saves; no player data changes.
# godot_gated invokes production/tools/heavy.py for the shared two-process gate.
set -euo pipefail
cd "$(dirname "$0")/../../.."
evidence="$PWD/production/qa/evidence"
godot=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
screens=(walking dialogue walking_large_text dialogue_large_text)
for screen in "${screens[@]}"; do rm -f "$evidence/M1-61_${screen}.png"; done
rm -f "$evidence/M1-61_probes.json"
"$godot" --path game --windowed --resolution 1280x720 \
  --rendering-method forward_plus --rendering-driver metal \
  --log-file "$evidence/M1-61_capture_engine.log" \
  --script res://tools/test_sound_captions.gd -- --capture \
  >"$evidence/M1-61_capture.txt" 2>&1 &
capture_pid=$!
trap 'kill -KILL "$capture_pid" 2>/dev/null || true; wait "$capture_pid" 2>/dev/null || true' EXIT
for ((second=0; second<240; second++)); do
  kill -0 "$capture_pid" 2>/dev/null || break
  sleep 1
done
if kill -0 "$capture_pid" 2>/dev/null; then
  echo 'M1-61 capture timed out after 240 seconds.' >>"$evidence/M1-61_capture.txt"
  cat "$evidence/M1-61_capture.txt"
  exit 1
fi
capture_rc=0
wait "$capture_pid" || capture_rc=$?
trap - EXIT
cat "$evidence/M1-61_capture.txt"
[[ "$capture_rc" -eq 0 ]] || exit "$capture_rc"
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script' "$evidence/M1-61_capture.txt"; then exit 1; fi
grep -Eq '^SOUND CAPTIONS RESULT: PASS \([0-9]+ checks, 0 failures\)$' "$evidence/M1-61_capture.txt"
python3 - <<'PY'
import json
import struct
from pathlib import Path

evidence = Path('production/qa/evidence')
for label in ('walking', 'dialogue', 'walking_large_text', 'dialogue_large_text'):
    path = evidence / f'M1-61_{label}.png'
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n' and len(data) > 1024, path
    assert struct.unpack('>II', data[16:24]) == (1280, 720), path
probes = json.loads((evidence / 'M1-61_probes.json').read_text())
assert probes and all(probes.values()), probes
print(f'M1-61 evidence verified: 4 screenshots, {len(probes)} passing probes')
PY
