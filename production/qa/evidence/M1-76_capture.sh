#!/usr/bin/env bash
# Run outside the sandbox in a logged-in desktop session. Uses isolated saves and
# the shared heavy.py gate via godot_gated; the two renderers run sequentially.
set -euo pipefail
cd "$(dirname "$0")/../../.."
evidence="$PWD/production/qa/evidence"
godot=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
# Revalidate on-disk evidence without launching a desktop window.
if [[ "${1:-}" == --verify-only ]]; then
  exec python3 "$evidence/M1-76_verify.py"
fi
[[ "$#" -eq 0 ]] || { echo "Usage: $0 [--verify-only]" >&2; exit 2; }
if [[ -n "${CODEX_SANDBOX:-}" ]]; then
  echo "M1-76: run GPU capture outside the sandbox; --verify-only can validate saved evidence here." >&2
  exit 3
fi
# Fail before replacing evidence if the recount dependencies are unavailable.
python3 -c 'import PIL, numpy'
export M1_76_CAPTURE_RUN_BY="${M1_76_CAPTURE_RUN_BY:-M1-76_capture.sh desktop runner (OS user: $(id -un))}"
# A failed/partial rerun must not leave the previous run labelled as current PASS.
python3 - <<'PY'
import json
from pathlib import Path
path = Path('production/qa/evidence/M1-76_verification.json')
summary = json.loads(path.read_text())
summary['windowed_verification'] = {'status': 'capture_in_progress'}
for key in ('capture_provenance', 'saved_png_shadow_crosscheck'):
    summary.pop(key, None)
summary['visual_review'] = {'status': 'pending', 'reason': 'A new GPU capture is in progress.'}
path.write_text(json.dumps(summary, indent=2) + '\n')
PY
capture_pid=""
trap 'if [[ -n "$capture_pid" ]]; then kill -KILL "$capture_pid" 2>/dev/null || true; wait "$capture_pid" 2>/dev/null || true; fi' EXIT
for renderer in forward_plus gl_compatibility; do
  log="$evidence/M1-76_${renderer}_capture.txt"
  engine_log="$evidence/M1-76_${renderer}_engine.log"
  rm -f "$evidence/M1-76_${renderer}_probe.json"
  for view in opening shadows character_shadows_off furniture_shadows_off; do
    rm -f "$evidence/M1-76_${renderer}_${view}.png"
  done
  "$godot" --path game --windowed --resolution 1280x720 \
    --rendering-method "$renderer" --log-file "$engine_log" \
    --script ../production/qa/evidence/M1-76_capture.gd -- \
    "--expect-renderer=$renderer" >"$log" 2>&1 &
  capture_pid=$!
  for ((second=0; second<300; second++)); do
    kill -0 "$capture_pid" 2>/dev/null || break
    sleep 1
  done
  if kill -0 "$capture_pid" 2>/dev/null; then
    echo "M1-76 $renderer timed out after 300 seconds" | tee -a "$log"
    exit 1
  fi
  capture_rc=0
  wait "$capture_pid" || capture_rc=$?
  capture_pid=""
  cat "$log"
  [[ "$capture_rc" -eq 0 ]] || exit "$capture_rc"
  # The result marker is mandatory: Godot may return zero on a script parse error.
  grep -Eq '^M1-76 CAPTURE RESULT: PASS \([0-9]+ checks, 0 failures\)$' "$log"
  if grep -Eiq 'SCRIPT ERROR|Parse Error|Failed to load script|dual.?paraboloid.*(unsupported|not supported)|must.*[Cc]ube|[Cc]ube.*required' "$log" "$engine_log"; then
    echo "M1-76 $renderer: script or unsupported-shadow error" >&2
    exit 1
  fi
done
python3 "$evidence/M1-76_verify.py"
