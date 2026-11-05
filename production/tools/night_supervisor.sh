#!/bin/sh
# Keep the night-shift workers alive until HOURS pass or production/session-logs/STOP_ALL exists.
# A worker that exits (task finished after a STOP_NIGHT_<prefix>, board empty, crash) is restarted on the
# current code ten minutes later at most. Each worker writes .night/<prefix>.pid while it runs.
#   HOURS=10 nohup caffeinate -dimsu sh production/tools/night_supervisor.sh > production/session-logs/night_supervisor.out 2>&1 &
cd "$(dirname "$0")/../.." || exit 1
END=$(( $(date +%s) + ${HOURS:-10} * 3600 ))
while [ "$(date +%s)" -lt "$END" ] && [ ! -f production/session-logs/STOP_ALL ]; do
  for spec in "nslot|" "gslot|LANES_ONLY=antigravity,gemini,any,claude PREFER=buet" "mslot|" "cslot|PREFER=claude2"; do
    pfx=${spec%%|*}; extra=${spec#*|}
    pidf=.night/$pfx.pid
    if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then continue; fi
    left=$(( (END - $(date +%s)) / 3600 ))
    [ "$left" -lt 1 ] && continue
    echo "$(date '+%F %T') starting $pfx ($left h left)"
    env SLOTS=1 SLOT_PREFIX="$pfx" SUMMARY="night_summary_$pfx.md" HOURS="$left" $extra \
      python3 production/tools/night_shift.py >> "production/session-logs/night_shift_$pfx.out" 2>&1 &
    sleep 60
  done
  sleep 600
done
echo "$(date '+%F %T') supervisor ends"
