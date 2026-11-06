#!/usr/bin/env bash
# Runs every headless suite in game/tools (test_*.gd), one at a time, and exits non-zero if any
# suite did not print a passing result line.
# Godot exits 0 when a --script fails to parse, so the printed result line is the only reliable
# signal. The class_name cache is refreshed first because a stale game/.godot cache (gitignored,
# e.g. after pulling scripts added on another machine) makes new suites fail to load.
#   game/tools/run_tests.sh              # all suites
#   game/tools/run_tests.sh campaign     # only suites whose file name contains "campaign"
#   SUITE_TIMEOUT=600 game/tools/run_tests.sh     # per-suite limit in seconds (default 300; a hang fails the suite)
#   GODOT=/path/to/godot game/tools/run_tests.sh   # other machines (Windows: Godot_v4.7.2-stable_win64_console.exe)
set -u
cd "$(dirname "$0")/.." || exit 2
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
[ -x "$GODOT" ] || GODOT="$(command -v godot || command -v godot4 || true)"
[ -n "$GODOT" ] || { echo "Godot 4.7 not found; set GODOT=/path/to/godot"; exit 2; }

"$GODOT" --headless --path . --editor --quit >/dev/null 2>&1

failed=0; count=0
for t in tools/test_*${1:-}*.gd; do
  # Exercise the production room rig under both explicit renderer selections.
  # This is headless configuration coverage; GPU evidence uses M1-76_capture.sh.
  renderers=(default)
  [[ "$t" == tools/test_room_presentation.gd ]] && renderers=(forward_plus gl_compatibility)
  for renderer in "${renderers[@]}"; do
    count=$((count + 1))
    tmp=$(mktemp)
    flags=(--headless --path .)
    label="$t"
    if [[ "$renderer" != default ]]; then
      flags+=(--rendering-method "$renderer")
      label="$t [$renderer]"
    fi
    [[ "$t" == tools/test_player_controller.gd ]] && flags+=(--fixed-fps 60)
    suite_command=("$GODOT" "${flags[@]}" --script "res://$t")
    [[ "$renderer" != default ]] && suite_command+=(-- "--expect-renderer=$renderer")
    "${suite_command[@]}" >"$tmp" 2>&1 & pid=$!
    for _ in $(seq "${SUITE_TIMEOUT:-300}"); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
    if kill -0 "$pid" 2>/dev/null; then kill "$pid"; wait "$pid" 2>/dev/null; rc=124; echo "TIMEOUT after ${SUITE_TIMEOUT:-300}s" >>"$tmp"
    else wait "$pid"; rc=$?; fi
    out=$(cat "$tmp"); rm -f "$tmp"
    line=$(grep -E 'RESULT|REGRESSIONS:|^(PASS|FAIL) ' <<<"$out" | tail -1)
    if [ "$rc" -ne 0 ] || grep -qE 'SCRIPT ERROR|Parse Error|Could not find type|Failed to load script' <<<"$out" \
       || ! grep -qE ': PASS|^PASS |, 0 failures' <<<"$line"; then
      [ "$rc" -ne 0 ] && line="exit $rc :: $line"
      echo "FAIL $label :: ${line:-no result line}"
      grep -E 'SCRIPT ERROR|Parse Error|Could not find type|Failed to load script|FAIL' <<<"$out" | head -5 | sed 's/^/       /'
      failed=$((failed + 1))
    else
      echo "ok   $label :: $line"
    fi
  done
done
echo "$((count - failed))/$count suites passed"
[ "$failed" -eq 0 ]
