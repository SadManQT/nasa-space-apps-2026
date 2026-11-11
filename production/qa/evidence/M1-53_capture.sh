#!/usr/bin/env bash
# M1-53 desktop acceptance: resume two probes per invocation (about 17 minutes).
# --max-runs 0 runs all remaining probes; use without the night time limit.
# --verify-only validates retained evidence without opening Godot.
# Exit 3 means valid partial evidence; exit 0 means all ten probes passed.
set -euo pipefail
cd "$(dirname "$0")/../../.."
export GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
exec python3 game/tools/m1_53_acceptance.py "$@"
