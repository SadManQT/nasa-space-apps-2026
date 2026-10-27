#!/bin/sh
# Turnaround views -> rigged, game-ready character GLB (Tripo web plan via the CLI).
#
#   tools/make_character.sh <Name> <height_m>      e.g.  tools/make_character.sh Amara 1.68
#
# Expects concept/turnarounds/<name lowercase>/views/{front,back,left,right}.png.
# Writes models/raw/CH_<Name>/ (git-ignored) and models/final/CH_<Name>/CH_<Name>.glb + previews.
# Cost on Tripo: ~55 credits (model) + ~20 (rig); checks and exports are free.
# Resumable: task, project and rig IDs are saved in models/raw/CH_<Name>/ and paid steps are
# never repeated on a re-run. The CLI's active profile is global; this script waits whenever it
# is not $TRIPO_PROFILE_WANT (default "default") so another account's login cannot misroute a job.
set -eu
NAME=$1; HEIGHT=$2
LOW=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
WANT=${TRIPO_PROFILE_WANT:-default}
T=~/.npm-global/bin/tripo
cd "$(dirname "$0")/.."
V=concept/turnarounds/$LOW/views
RAW=models/raw/CH_$NAME; FIN=models/final/CH_$NAME
mkdir -p "$RAW" "$FIN/preview"
LOG=$RAW/pipeline.log
say() { echo "[$(date +%H:%M:%S)] $NAME: $*" | tee -a "$LOG"; }
guard() {  # block until the active Tripo profile is the one we want
  while [ "$($T config show 2>/dev/null | awk '/current_profile/ {print $2}')" != "$WANT" ]; do
    say "active Tripo profile is not '$WANT'; waiting"; sleep 20
  done
}

if [ ! -s "$RAW/project_id" ]; then
  guard; say "generate multiview"
  $T generate multiview "$V/front.png" "$V/back.png" "$V/left.png" "$V/right.png" \
    --model-version v3.1-20260211 --geometry-quality detailed --texture-quality detailed \
    --pbr --visibility private --timeout 20m -o "$RAW/CH_${NAME}_raw.glb" >"$RAW/generate.log" 2>&1
  cat "$RAW/generate.log" >>"$LOG"
  grep -o 'Task created: [0-9a-f-]*' "$RAW/generate.log" | awk '{print $3}' >"$RAW/task_id"
  guard
  $T project list --size 20 --output-format json 2>/dev/null | python3 -I -c "
import json,sys
t=open(sys.argv[1]).read().strip()
print(next(p['project_id'] for p in json.load(sys.stdin)['projects'] if p['operator']['operator_id']==t))" "$RAW/task_id" >"$RAW/project_id"
fi
PROJECT=$(cat "$RAW/project_id"); say "project $PROJECT"

if [ ! -s "$RAW/rig_op" ]; then
  # rig.log existing means a (paid) rig was already submitted: never resubmit automatically.
  [ -e "$RAW/rig.log" ] && { say "rig.log exists but rig_op is empty: put the rig operator ID in $RAW/rig_op"; exit 1; }
  guard; $T process rig "$PROJECT" --check --model-version v1.0-20240301 >"$RAW/rigcheck.log" 2>&1
  cat "$RAW/rigcheck.log" >>"$LOG"
  grep -q 'Riggable: true' "$RAW/rigcheck.log" || { say "NOT riggable, stopping"; exit 1; }
  guard; say "rig (submit)"
  $T process rig "$PROJECT" --model-version v1.0-20240301 --rig-type biped --submit-only >"$RAW/rig.log" 2>&1 || true
  cat "$RAW/rig.log" >>"$LOG"
  grep -Eo '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' "$RAW/rig.log" | grep -v "$PROJECT" | head -1 >"$RAW/rig_op"
  [ -s "$RAW/rig_op" ] || { say "could not read the rig operator ID from rig.log"; exit 1; }
fi
RIG_OP=$(cat "$RAW/rig_op"); say "rig op $RIG_OP"
guard; $T project wait "$RIG_OP" --timeout 30m >>"$LOG" 2>&1

if [ ! -s "$RAW/CH_${NAME}_rigged.glb" ]; then
  # Export from the rig operation with the skeleton; the rig command's own download has none.
  guard; say "export rig with skeleton"
  $T export "$PROJECT" --operator-id "$RIG_OP" --with-animation --format glb \
    -o "$RAW/CH_${NAME}_rigged.glb" --timeout 10m >>"$LOG" 2>&1
fi

say "blender clean-up"
blender -b -P tools/blender_cleanup.py -- "$RAW/CH_${NAME}_rigged.glb" "$FIN/CH_$NAME.glb" \
  --tris 50000 --height "$HEIGHT" --yaw -90 --rigged 2>&1 | grep -E 'CLEANUP|DROP' | tee -a "$LOG"
blender -b -P tools/render_preview.py -- "$FIN/CH_$NAME.glb" "$FIN/preview/final" --res 640 2>&1 | grep STATS | tee -a "$LOG"
blender -b -P tools/pose_test.py -- "$FIN/CH_$NAME.glb" "$RAW/posed.glb" >/dev/null 2>&1
blender -b -P tools/render_preview.py -- "$RAW/posed.glb" "$FIN/preview/posetest" --res 640 >/dev/null 2>&1
guard; say "done; $($T account balance 2>/dev/null | head -1)"
