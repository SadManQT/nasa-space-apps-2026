#!/usr/bin/env bash
# M1-37 Class mode evidence. Run outside any sandbox from a logged-in macOS desktop (the
# night-shift runner does this); uses isolated saves and never touches the player's checkpoint.
# A Godot exit code alone is never accepted as capture success: the printed RESULT line and the
# PNG checks below are. Also encodes a scripted 2-minute walkthrough of one Class shift
# (M1-37_class_shift_walkthrough.mp4) from 2 fps frames; the four-person recording is a human task.
set -euo pipefail
cd "$(dirname "$0")/../../.."
GODOT="${GODOT:-/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated}"
HEAVY="${HEAVY:-/Users/sadmansakib/nasa-space-apps-2026/production/tools/heavy.py}"
evidence="$PWD/production/qa/evidence"
output="$evidence/M1-37_capture_output.txt"
frames="$(mktemp -d "${TMPDIR:-/tmp}/m137_frames.XXXXXX")"
screens=(title_briefing_class4 title_briefing_class2 hud_crew_notes_button handoff_cover_kai handoff_reveal_kai handoff_cover_amara table_class_private_notes table_class_preview team_plan_waiting team_plan_two_signed team_plan_all_signed hud_after_lock_in settings_crew_mode handoff_large_text solo_confirmation)

[[ -x "$GODOT" ]] || { echo "Godot launcher not found: $GODOT" >&2; exit 2; }
for screen in "${screens[@]}"; do rm -f "$evidence/M1-37_${screen}.png"; done
rm -f "$evidence/M1-37_capture_probe.txt" "$evidence/M1-37_class_shift_walkthrough.mp4"

# Import assets and refresh the class cache first so the windowed run never stalls on a cold cache.
"$GODOT" --headless --path game --editor --quit >/dev/null 2>&1 || true

"$GODOT" --path game --windowed --resolution 1280x720 \
  --rendering-method forward_plus --rendering-driver metal \
  --log-file "$evidence/M1-37_capture_engine.log" \
  --script res://tools/capture_class_mode_m137.gd -- "--frames-dir=$frames" >"$output" 2>&1 &
capture_pid=$!
trap 'kill -KILL "$capture_pid" 2>/dev/null || true; wait "$capture_pid" 2>/dev/null || true; rm -rf "$frames"' EXIT
for ((second=0; second<600; second++)); do
  kill -0 "$capture_pid" 2>/dev/null || break
  sleep 1
done
if kill -0 "$capture_pid" 2>/dev/null; then
  echo "Capture timed out after 600 seconds." >>"$output"
  cat "$output"
  exit 1
fi
capture_rc=0
wait "$capture_pid" || capture_rc=$?
if [[ "$capture_rc" -ne 0 ]]; then
  echo "M1-37 CLASS MODE CAPTURE RESULT: FAIL (windowed Godot exited $capture_rc)" >>"$output"
fi
cat "$output"
[[ "$capture_rc" -eq 0 ]] || exit "$capture_rc"
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script' "$output"; then exit 1; fi
grep -q '^M1-37 CLASS MODE CAPTURE RESULT: PASS (0 failures)$' "$output"

python3 -I - <<'PY'
import struct
from pathlib import Path
evidence = Path('production/qa/evidence')
screens = ['title_briefing_class4', 'title_briefing_class2', 'hud_crew_notes_button', 'handoff_cover_kai', 'handoff_reveal_kai',
           'handoff_cover_amara', 'table_class_private_notes', 'table_class_preview', 'team_plan_waiting', 'team_plan_two_signed',
           'team_plan_all_signed', 'hud_after_lock_in', 'settings_crew_mode', 'handoff_large_text', 'solo_confirmation']
for label in screens:
    path = evidence / f'M1-37_{label}.png'
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n' and len(data) > 1024, path
    assert struct.unpack('>II', data[16:24]) == (1280, 720), path
probe = (evidence / 'M1-37_capture_probe.txt').read_text()
assert probe.strip().endswith('RESULT PASS (0 failures)'), probe[-200:]
print('M1-37 screenshots and probe verified')
PY

# Scripted walkthrough video: 2 fps frames shown at 24 fps output (each frame holds 0.5 s).
count=$(ls "$frames" | wc -l | tr -d ' ')
if [[ "$count" -gt 0 ]] && command -v ffmpeg >/dev/null; then
  python3 "$HEAVY" ffmpeg -y -loglevel error -framerate 2 -i "$frames/frame_%04d.png" \
    -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -r 24 -vf "scale=1280:720" \
    -movflags +faststart "$evidence/M1-37_class_shift_walkthrough.mp4"
  duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$evidence/M1-37_class_shift_walkthrough.mp4")
  echo "walkthrough: $count frames, ${duration}s" | tee -a "$output"
else
  echo "walkthrough: no frames or no ffmpeg; video skipped" | tee -a "$output"
fi
