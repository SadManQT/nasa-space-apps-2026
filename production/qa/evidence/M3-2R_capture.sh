#!/usr/bin/env bash
# Windowed Chapter 2 evidence (M3-2R), run by the night-shift host outside the sandbox: the 25 views below and four
# frame-time probes, window kept on top. The room checks themselves are the headless suite (run_tests.sh), so the
# windowed pass only renders and stays short.
# godot_gated queues for the machine-wide two-slot gate (heavy.py). The 7 Nov run timed out because its watchdog also
# counted that queue time; here each Godot's own limits start when its banner appears, a capture that prints no new
# progress line for CAPTURE_STALL seconds is sampled (stack saved to M3-2R_capture_stack.txt) and retried once, and the
# whole script stays inside night_shift.py's 2,400-second limit so its own trap can still stop Godot. The stall itself
# was macOS reporting the window covered (another capture window, the lock screen): Godot then stops drawing and never
# emits frame_post_draw. The test now renders those frames itself and skips frame timings the window could not draw.
set -euo pipefail
cd "$(dirname "$0")/../../.."
GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
EVIDENCE=production/qa/evidence
BUDGET=${CAPTURE_BUDGET:-2280}     # whole script, queue time included
RUN_LIMIT=${CAPTURE_TIMEOUT:-600}  # one Godot process, from its start
STALL=${CAPTURE_STALL:-150}        # capture only: longest gap between two progress lines
shots=(
  S01_earth_console_tara S01_paired_identity_cards S01_player
  S02_botanical_bench S02_practice_model_close
  S03_airlock_vestibule S03_route_and_kai_line S03_player
  S04_alo_glove_ports S04_carrier_microscope S05_care_and_route_record
  S06_seven_dates_prediction S06_seed_tray_bench S07_mission_table S07_bee_and_recorder
  S08_recorder_bench S08_evidence_board S09_reconstruction
  S10_playback_transcripts S10_inference_board S11_evidence_package S11_cup_reply_pending
  S12_brace_zone S12_red_warning CH03_S01_same_warning
)
mkdir -p "$EVIDENCE"
for shot in "${shots[@]}"; do
  rm -f "$EVIDENCE/M3-2R_${shot}.png"
done
rm -f "$EVIDENCE/M3-2R_runtime.txt" "$EVIDENCE/M3-2R_capture_stack.txt"

running=""
trap '[ -n "$running" ] && kill "$running" 2>/dev/null || true' EXIT

# run_gated LOG WATCH ARGS...: one gated Godot with ARGS, output in LOG. Returns Godot's exit code, or 124 when it ran
# past RUN_LIMIT, stalled (WATCH=1: no new "M3-2R progress" line for STALL seconds) or the script ran out of BUDGET.
run_gated() {
  local log=$1 watch=$2
  shift 2
  : >"$log"
  "$GODOT" "$@" >"$log" 2>&1 &
  running=$!
  local started=0 seen=0 last=$SECONDS lines status=0
  while kill -0 "$running" 2>/dev/null; do
    if (( started == 0 )) && grep -q '^Godot Engine' "$log"; then
      started=$SECONDS
      last=$SECONDS
    fi
    if (( started > 0 && watch == 1 )); then
      lines=$(grep -c '^M3-2R progress' "$log" || true)
      if (( lines != seen )); then
        seen=$lines
        last=$SECONDS
      fi
    fi
    if (( SECONDS >= BUDGET )) || (( started > 0 && SECONDS - started >= RUN_LIMIT )) \
      || (( watch == 1 && started > 0 && SECONDS - last >= STALL )); then
      echo "M3-2R: Godot stopped after $(( started > 0 ? SECONDS - started : 0 )) s of run time ($SECONDS s with queue)" >&2
      { echo "== $(date '+%F %T') $log"; sample "$running" 3 2>&1 || true; } >>"$EVIDENCE/M3-2R_capture_stack.txt"
      kill "$running" 2>/dev/null || true
      wait "$running" 2>/dev/null || true
      running=""
      return 124
    fi
    sleep 1
  done
  wait "$running" || status=$?
  running=""
  return "$status"
}

import_status=0
run_gated "$EVIDENCE/M3-2R_import.txt" 0 --headless --path game --editor --quit || import_status=$?
if (( import_status != 0 )) || grep -Eq 'SCRIPT ERROR|Parse Error' "$EVIDENCE/M3-2R_import.txt"; then
  echo "M3-2R: import refresh failed (exit $import_status)" >&2
  cat "$EVIDENCE/M3-2R_import.txt"
  exit 1
fi

for attempt in 1 2; do
  capture_status=0
  run_gated "$EVIDENCE/M3-2R_capture.txt" 1 --path game --windowed --resolution 1600x900 --position 40,40 \
    --script res://tools/test_chapter2_rooms.gd -- --capture || capture_status=$?
  (( capture_status == 124 )) || break
  echo "M3-2R: capture attempt $attempt stopped; $(grep '^M3-2R progress' "$EVIDENCE/M3-2R_capture.txt" | tail -1)" >&2
done
# Godot can exit zero on parse errors: require the printed result and fresh images too.
if (( capture_status != 0 )) || ! grep -q '^CHAPTER 2 ROOMS CAPTURE RESULT: PASS' "$EVIDENCE/M3-2R_capture.txt" \
  || grep -Eq 'SCRIPT ERROR|Parse Error|^FAIL ' "$EVIDENCE/M3-2R_capture.txt"; then
  echo "M3-2R capture failed (exit $capture_status)" >&2
  grep -v '^ROOT ' "$EVIDENCE/M3-2R_capture.txt"
  exit 1
fi
for shot in "${shots[@]}"; do
  test -s "$EVIDENCE/M3-2R_${shot}.png" || { echo "missing M3-2R_${shot}.png" >&2; exit 1; }
done
cat "$EVIDENCE/M3-2R_runtime.txt"
