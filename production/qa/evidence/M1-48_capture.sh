#!/usr/bin/env bash
# M1-48 journal evidence. Run outside the sandbox from a logged-in macOS desktop (the night-shift
# runner does this); uses isolated saves and never touches the player's checkpoint.
# A Godot exit code alone is never accepted as capture/probe success: the printed RESULT line and
# the PNG/probe checks below are.
set -euo pipefail
cd "$(dirname "$0")/../../.."
GODOT="${GODOT:-/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated}"
evidence="$PWD/production/qa/evidence"
output="$evidence/M1-48_capture_output.txt"
screens=(s03_now s03_evidence s03_garden s03_decisions s12_now s12_evidence s12_garden s12_decisions resume_pause resume_continue journal_150_now journal_150_evidence)

[[ -x "$GODOT" ]] || { echo "Godot launcher not found: $GODOT" >&2; exit 2; }
# Remove only this capture's outputs so a failed run cannot pass on stale proof.
for screen in "${screens[@]}"; do rm -f "$evidence/M1-48_${screen}.png"; done
rm -f "$evidence/M1-48_probes.json"

# Import assets first so the windowed run never stalls on a cold cache.
"$GODOT" --headless --path game --editor --quit >/dev/null 2>&1 || true

"$GODOT" --path game --windowed --resolution 1280x720 \
  --rendering-method forward_plus --rendering-driver metal \
  --log-file "$evidence/M1-48_capture_engine.log" \
  --script res://tools/capture_journal_m148.gd >"$output" 2>&1 &
capture_pid=$!
trap 'kill -KILL "$capture_pid" 2>/dev/null || true; wait "$capture_pid" 2>/dev/null || true' EXIT
for ((second=0; second<420; second++)); do
  kill -0 "$capture_pid" 2>/dev/null || break
  sleep 1
done
if kill -0 "$capture_pid" 2>/dev/null; then
  echo "Capture timed out after 420 seconds." >>"$output"
  cat "$output"
  exit 1
fi
capture_rc=0
wait "$capture_pid" || capture_rc=$?
trap - EXIT
if [[ "$capture_rc" -ne 0 ]]; then
  echo "JOURNAL CAPTURE RESULT: FAIL (windowed Godot exited $capture_rc)" >>"$output"
fi
cat "$output"
[[ "$capture_rc" -eq 0 ]] || exit "$capture_rc"
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script' "$output"; then exit 1; fi
grep -q '^JOURNAL CAPTURE RESULT: PASS (0 failures)$' "$output"

python3 -I - <<'PY'
import json
import struct
from pathlib import Path

evidence = Path('production/qa/evidence')
screens = ['s03_now', 's03_evidence', 's03_garden', 's03_decisions', 's12_now', 's12_evidence', 's12_garden',
           's12_decisions', 'resume_pause', 'resume_continue', 'journal_150_now', 'journal_150_evidence']
for label in screens:
    path = evidence / f'M1-48_{label}.png'
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n' and len(data) > 1024, path
    assert struct.unpack('>II', data[16:24]) == (1280, 720), path
probes = json.loads((evidence / 'M1-48_probes.json').read_text())
assert probes and all(probes.values()), {k: v for k, v in probes.items() if not v}
print(f'M1-48 evidence verified: {len(screens)} screenshots, {len(probes)} passing probes')
PY
