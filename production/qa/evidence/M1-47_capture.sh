#!/usr/bin/env bash
# Run outside the sandbox from a logged-in macOS desktop; uses isolated saves.
# A Godot exit code alone is never accepted as capture/probe success.
set -euo pipefail
cd "$(dirname "$0")/../../.."
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
evidence="$PWD/production/qa/evidence"
output="$evidence/M1-47_capture.txt"
screens=(preview recorded large_text large_text_confirm)

[[ -x "$GODOT" ]] || { echo "Godot executable not found: $GODOT" >&2; exit 2; }
# Remove only this capture's outputs so a failed run cannot pass on stale proof.
for screen in "${screens[@]}"; do rm -f "$evidence/M1-47_${screen}.png"; done
rm -f "$evidence/M1-47_probes.json"

"$GODOT" --path game --windowed --resolution 1280x720 \
  --rendering-method forward_plus --rendering-driver metal \
  --log-file "$evidence/M1-47_capture_engine.log" \
  --script res://tools/capture_story_log.gd >"$output" 2>&1 &
capture_pid=$!
trap 'kill -KILL "$capture_pid" 2>/dev/null || true; wait "$capture_pid" 2>/dev/null || true' EXIT
for ((second=0; second<240; second++)); do
  kill -0 "$capture_pid" 2>/dev/null || break
  sleep 1
done
if kill -0 "$capture_pid" 2>/dev/null; then
  echo "Capture timed out after 240 seconds." >>"$output"
  cat "$output"
  exit 1
fi
capture_rc=0
wait "$capture_pid" || capture_rc=$?
trap - EXIT
if [[ "$capture_rc" -ne 0 ]]; then
  echo "STORY LOG CAPTURE RESULT: FAIL (windowed Godot exited $capture_rc)" >>"$output"
fi
cat "$output"
[[ "$capture_rc" -eq 0 ]] || exit "$capture_rc"
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script' "$output"; then exit 1; fi
grep -q '^STORY LOG CAPTURE RESULT: PASS (0 failures)$' "$output"

python3 - <<'PY'
import json
import struct
from pathlib import Path

evidence = Path('production/qa/evidence')
for label in ('preview', 'recorded', 'large_text', 'large_text_confirm'):
    path = evidence / f'M1-47_{label}.png'
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n' and len(data) > 1024, path
    assert struct.unpack('>II', data[16:24]) == (1280, 720), path
probes = json.loads((evidence / 'M1-47_probes.json').read_text())
assert probes and all(probes.values()), probes
print(f'M1-47 evidence verified: 4 screenshots, {len(probes)} passing probes')
PY
