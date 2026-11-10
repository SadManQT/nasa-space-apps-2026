#!/usr/bin/env bash
# Runs every headless suite in game/tools (test_*.gd), one at a time, and exits non-zero if any
# suite did not print a passing result line.
# Godot exits 0 when a --script fails to parse, so the printed result line is the only reliable
# signal. The class_name cache is refreshed first because a stale game/.godot cache (gitignored,
# e.g. after pulling scripts added on another machine) makes new suites fail to load.
#   game/tools/run_tests.sh              # all suites
#   game/tools/run_tests.sh campaign     # only suites whose file name contains "campaign"
#   SUITE_TIMEOUT=600 game/tools/run_tests.sh     # per-suite limit in seconds (default 300; a hang fails the suite)
#   PLAYER_TEXT_TIMEOUT=1500 game/tools/run_tests.sh  # override only the full-campaign text walk's process guard
#   UPGRADE_PROFILE_TIMEOUT=10800 game/tools/run_tests.sh  # bounded guard for all 128 complete campaign profiles
#   GODOT=/path/to/godot game/tools/run_tests.sh   # other machines (Windows: Godot_v4.7.2-stable_win64_console.exe)
#   TEST_LOG_DIR=/absolute/path game/tools/run_tests.sh  # retain complete setup and suite logs
set -u
cd "$(dirname "$0")/.." || exit 2
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
[ -x "$GODOT" ] || GODOT="$(command -v godot || command -v godot4 || true)"
[ -n "$GODOT" ] || { echo "Godot 4.7 not found; set GODOT=/path/to/godot"; exit 2; }
if [ -n "${TEST_LOG_DIR:-}" ]; then
  mkdir -p "$TEST_LOG_DIR" || { echo "Cannot create TEST_LOG_DIR: $TEST_LOG_DIR"; exit 2; }
fi

# Setup is mandatory: a crash must not let stale imports produce a green run.
setup_log=$(mktemp) || exit 2
"$GODOT" --headless --path . --editor --quit >"$setup_log" 2>&1
setup_rc=$?
if [ -n "${TEST_LOG_DIR:-}" ]; then
  cp "$setup_log" "$TEST_LOG_DIR/setup.log" || { rm -f "$setup_log"; exit 2; }
fi
if [ "$setup_rc" -ne 0 ] || grep -qE 'SCRIPT ERROR|Parse Error|Could not find type|Failed to load script' "$setup_log"; then
  echo "FAIL setup: Godot class-cache/import refresh failed (exit $setup_rc); no suites were run."
  cat "$setup_log"
  rm -f "$setup_log"
  [ "$setup_rc" -ne 0 ] && exit "$setup_rc"
  exit 1
fi
rm -f "$setup_log"

failed=0; count=0

# Only stop this runner's child and its batch engines. A stuck teardown
# must not make a known failed suite block the rest of the gate indefinitely.
stop_test_process() {
  local test_pid="$1"
  local grace_step
  case "$OSTYPE" in
    msys*|cygwin*)
      local win_pid
      win_pid=$(ps -p "$test_pid" | awk 'NR == 2 {print $4}')
      if [[ "$win_pid" =~ ^[0-9]+$ ]]; then
        MSYS_NO_PATHCONV=1 taskkill.exe /PID "$win_pid" /T /F >/dev/null 2>&1 || true
      fi ;;
    *) pkill -KILL -P "$test_pid" 2>/dev/null || true ;;
  esac
  kill "$test_pid" 2>/dev/null || true
  for grace_step in 1 2 3; do
    kill -0 "$test_pid" 2>/dev/null || break
    sleep 1
  done
  if kill -0 "$test_pid" 2>/dev/null; then kill -KILL "$test_pid" 2>/dev/null || true; fi
  wait "$test_pid" 2>/dev/null
}

for t in tools/test_*${1:-}*.gd; do
  count=$((count + 1))
  tmp=$(mktemp)
  flags=(--headless --path .)
  [[ "$t" == tools/test_player_controller.gd ]] && flags+=(--fixed-fps 60)
  suite_limit="${SUITE_TIMEOUT:-300}"
  [[ "$t" == tools/test_player_text.gd ]] && suite_limit="${PLAYER_TEXT_TIMEOUT:-$suite_limit}"
  [[ "$t" == tools/test_upgrade_profiles.gd ]] && suite_limit="${UPGRADE_PROFILE_TIMEOUT:-10800}"
  fatal_script=0
  "$GODOT" "${flags[@]}" --script "res://$t" >"$tmp" 2>&1 & pid=$!
  for _ in $(seq "$suite_limit"); do
    kill -0 "$pid" 2>/dev/null || break
    if grep -qE 'SCRIPT ERROR|Parse Error|Could not find type|Failed to load script' "$tmp"; then
      fatal_script=1
      break
    fi
    sleep 1
  done
  if [ "$fatal_script" -eq 1 ]; then
    stop_test_process "$pid"; child_rc=$?; rc=1
    echo "STOPPED after fatal script diagnostic (process exit $child_rc)" >>"$tmp"
  elif kill -0 "$pid" 2>/dev/null; then
    stop_test_process "$pid"; child_rc=$?; rc=124
    echo "TIMEOUT after ${suite_limit}s (process exit $child_rc)" >>"$tmp"
  else wait "$pid"; rc=$?; fi
  if [ -n "${TEST_LOG_DIR:-}" ]; then
    cp "$tmp" "$TEST_LOG_DIR/$(basename "$t").log" || { rm -f "$tmp"; exit 2; }
  fi
  out=$(cat "$tmp"); rm -f "$tmp"
  line=$(grep -E 'RESULT|REGRESSIONS:|^(PASS|FAIL) ' <<<"$out" | tail -1)
  if [ "$rc" -ne 0 ] || grep -qE 'SCRIPT ERROR|Parse Error|Could not find type|Failed to load script' <<<"$out" \
     || ! grep -qE ': PASS|^PASS |, 0 failures' <<<"$line"; then
    [ "$rc" -ne 0 ] && line="exit $rc :: $line"
    echo "FAIL $t :: ${line:-no result line}"
    grep -E 'SCRIPT ERROR|Parse Error|Could not find type|Failed to load script|FAIL' <<<"$out" | head -5 | sed 's/^/       /'
    failed=$((failed + 1))
  else
    echo "ok   $t :: $line"
  fi
done
echo "$((count - failed))/$count suites passed"
[ "$failed" -eq 0 ]
