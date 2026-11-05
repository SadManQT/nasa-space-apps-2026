#!/bin/sh
# Wake the attending session when the night shift needs attention. Exits (printing why) when a task fails or is
# blocked, a worker logs an error, the supervisor is gone, the Mac is overloaded, or MAX_MIN minutes pass (heartbeat).
#   MAX_MIN=120 sh production/tools/night_watch.sh
cd "$(dirname "$0")/../.." || exit 1
LOG=production/session-logs/night_shift.log
from=$(($(wc -l < "$LOG") + 1)); t0=$(date +%s); hot=0
report() {
  echo "== $1 ($(date '+%F %T'))"
  tail -n +"$from" "$LOG" | grep -E -- "-> |error:|hit a usage limit|changed nothing" | cut -c1-240
  echo "-- running: $(ls .night/claims 2>/dev/null | tr '\n' ' ')"
  echo "-- load: $(sysctl -n vm.loadavg) swap: $(sysctl -n vm.swapusage | awk '{print $6}') disk free: $(df -h / | awk 'NR==2{print $4}')"
  exit 0
}
while :; do
  sleep 60
  new=$(tail -n +"$from" "$LOG")
  echo "$new" | grep -qE -- "-> (failed|blocked)|\] error:" && report "attention: a task failed, was blocked or errored"
  pgrep -f night_supervisor.sh > /dev/null || report "attention: the supervisor is not running"
  load=$(sysctl -n vm.loadavg | awk '{print int($2)}')
  if [ "$load" -gt 20 ]; then hot=$((hot + 1)); else hot=0; fi
  [ "$hot" -ge 5 ] && report "attention: load above 20 for five minutes"
  [ $(( $(date +%s) - t0 )) -ge $(( ${MAX_MIN:-120} * 60 )) ] && report "heartbeat"
done
