#!/bin/sh
# Keep an AI coding CLI working on the board through usage limits.
#
#   production/tools/auto_continue.sh claude          # Claude Code: resumes the latest session with "continue"
#   production/tools/auto_continue.sh codex           # Codex CLI:   codex exec resume --last "continue"
#   MAX_ROUNDS=30 production/tools/auto_continue.sh claude
#
# Each round sends "continue" (the board protocol in production/plan/GO_NEXT.md: claim a chunk, do it, push).
# When a round stops on a usage limit, it reads the reset time the tool printed ("resets 9:40pm",
# "try again at 10:43 PM"), sleeps until two minutes after it, and sends "continue" again.
# It stops when the board has nothing ready for the lane, or after MAX_ROUNDS. Run it in its own terminal,
# not while the same session is open in an editor. Logs: production/session-logs/auto_continue_<tool>.log.
set -u
TOOL=${1:-claude}
MAX_ROUNDS=${MAX_ROUNDS:-20}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
mkdir -p production/session-logs
LOG=production/session-logs/auto_continue_$TOOL.log
LANE=$TOOL

run_round() {
  case $TOOL in
    claude) claude -c -p "continue" --permission-mode "${CLAUDE_PERMISSION_MODE:-auto}" ;;
    codex)  codex exec resume --last "continue" < /dev/null ;;
    *) echo "unknown tool $TOOL (use claude or codex)"; exit 2 ;;
  esac
}

# seconds until the reset time printed in $1 (+120 s); 1800 if a limit is reported without a time; 0 if no limit
wait_seconds() {
  python3 - "$1" <<'EOF'
import re, sys, datetime as dt
out = sys.argv[1]
if not re.search(r"(usage limit|hit your .*limit|rate limit|quota)", out, re.I):
    print(0); sys.exit()
m = re.search(r"(?:resets|try again at)\s+(\d{1,2})(?::(\d{2}))?\s*([ap]\.?m\.?)", out, re.I)
if not m:
    print(1800); sys.exit()
h, mi, ap = int(m.group(1)), int(m.group(2) or 0), m.group(3).lower()[0]
h = h % 12 + (12 if ap == "p" else 0)
now = dt.datetime.now()
t = now.replace(hour=h, minute=mi, second=0, microsecond=0)
if t <= now:
    t += dt.timedelta(days=1)
print(int((t - now).total_seconds()) + 120)
EOF
}

round=1
while [ "$round" -le "$MAX_ROUNDS" ]; do
  if python3 production/plan/board.py next --tool "$LANE" 2>&1 | grep -q "Nothing is ready"; then
    echo "$(date '+%F %T') nothing ready for $LANE: stopping" | tee -a "$LOG"; exit 0
  fi
  echo "$(date '+%F %T') round $round: continue ($TOOL)" | tee -a "$LOG"
  OUT=$(run_round 2>&1)
  printf '%s\n' "$OUT" | tail -40 >> "$LOG"
  WAIT=$(wait_seconds "$OUT")
  if [ "$WAIT" -gt 0 ]; then
    echo "$(date '+%F %T') usage limit: sleeping $((WAIT / 60)) min" | tee -a "$LOG"
    sleep "$WAIT"
  fi
  round=$((round + 1))
done
echo "$(date '+%F %T') reached MAX_ROUNDS=$MAX_ROUNDS" | tee -a "$LOG"
