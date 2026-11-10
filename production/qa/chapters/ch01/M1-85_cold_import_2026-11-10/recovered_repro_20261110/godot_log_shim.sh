#!/usr/bin/env bash
set -u
set -o pipefail
log_dir=$(cygpath -u "$TEST_LOG_DIR") || exit 125
real=$(cygpath -u "$LLA_REAL_GODOT") || exit 125
phase=unknown
for arg in "$@"; do
  case "$arg" in
    --editor) phase=setup ;;
    res://tools/test_*.gd) phase=${arg##*/} ;;
  esac
done
case "$phase" in setup|test_hint_player.gd) ;; *) echo 'Unexpected diagnostic invocation' >&2; exit 125 ;; esac
log="$log_dir/$phase.log"
[[ -d "$log_dir" && ! -e "$log" ]] || exit 125
printf '%s\0' "$@" > "$log_dir/$phase.args0" || exit 125
"$real" "$@" 2>&1 | tee -- "$log"
statuses=("${PIPESTATUS[@]}")
printf '%s\n' "${statuses[0]}" > "$log_dir/$phase.exit.txt" || exit 125
[[ "${statuses[1]}" -eq 0 ]] || exit 125
exit "${statuses[0]}"
