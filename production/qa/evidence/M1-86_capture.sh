#!/usr/bin/env bash
# M1-86 changes documentation only; there are no changed game screens to capture.
# Run this verification probe from the night-shift controller outside the Codex
# sandbox. The trainer suite creates isolated cache/canary directories in macOS
# application data, outside this worktree's writable sandbox roots. Its sandbox
# retry still failed storage and title-focus assertions; this script must verify
# the unrestricted result rather than assume every assertion is permission-only.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../.." || exit 2

export GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
full_log=production/qa/evidence/M1-86_tests_outside_sandbox.txt

# The official runner requires printed passing results, detects parse errors,
# and serializes suites. godot_gated supplies the machine-wide heavy-process gate.
game/tools/run_tests.sh 2>&1 | tee "$full_log"
full_status=$?

# A busy machine can fail wall-clock checks. Keep the full result unchanged and
# retain a focused retry for review; a retry never turns a failed full run green.
if grep -q '^FAIL tools/test_performance_runtime.gd' "$full_log"; then
  game/tools/run_tests.sh performance_runtime 2>&1 | tee production/qa/evidence/M1-86_performance_retry_outside_sandbox.txt
fi

exit "$full_status"
