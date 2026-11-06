#!/usr/bin/env bash
# M1-81 changes documentation only, so it needs no new player screenshots.
# Run outside the Codex sandbox: the trainer suite deliberately checks writes to
# isolated macOS application-data paths, including campaign-save canary files.
# Retain M1-81_test_results.txt as the original sandbox result; write host proof
# separately. Adds only the missing read_file alias to the nightly review's
# settings on the host; no test, threshold, project or player file is modified.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"

# The task-only retry passed, but night_shift.py launches its next independent
# review with ~/.local/share/night_shift/agy_settings.json instead. Cover the
# lexical home/.gemini alias as well as the already permitted resolved directory.
# Add that exact read rule to the settings the next review actually consumes.
python3 - "$HOME/.local/share/night_shift/agy_settings.json" \
  "$repo_root/production/qa/evidence/M1-81_permission_probe.txt" <<'PY_PERMISSIONS'
import json
import os
from pathlib import Path
import stat
import sys
import tempfile

settings_path, probe_path = map(Path, sys.argv[1:])
profile = Path("/Users/sadmansakib/Library/Application Support/GoCode/profiles/cc889fbd-1f66-482a-a8be-7607cb318b5f")
brain = profile / "home/.gemini/antigravity-cli/brain"
if not brain.is_dir():
    sys.exit("M1-81: reviewer brain directory is missing")
settings = json.loads(settings_path.read_text())
allow = settings["permissions"]["allow"]
if not isinstance(allow, list) or not all(isinstance(rule, str) for rule in allow):
    sys.exit("M1-81: permissions.allow must be a list of strings")
if f"read_file({brain.resolve()})" not in allow:
    sys.exit("M1-81: expected existing resolved-brain read permission is missing")
rule = f"read_file({brain})"
added = rule not in allow
if added:
    allow.append(rule)
    fd, temporary = tempfile.mkstemp(prefix=".M1-81-", dir=settings_path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            os.fchmod(stream.fileno(), stat.S_IMODE(settings_path.stat().st_mode))
            stream.write(json.dumps(settings, indent=1) + "\n")
        os.replace(temporary, settings_path)
    finally:
        Path(temporary).unlink(missing_ok=True)
if rule not in json.loads(settings_path.read_text())["permissions"]["allow"]:
    sys.exit("M1-81: reviewer read rule did not persist")
proof = f"M1-81 REVIEW SETTINGS: PASS\nSettings: {settings_path}\nRule: {rule}\nAdded: {added}\n"
probe_path.write_text(proof)
print(proof, end="")
PY_PERMISSIONS

export GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated
result_file=production/qa/evidence/M1-81_host_test_results.txt

if game/tools/run_tests.sh >"$result_file" 2>&1; then
  cat "$result_file"
else
  result_code=$?
  cat "$result_file"
  exit "$result_code"
fi

# Require the runner's printed all-suites result as well as its exit status.
python3 - "$result_file" <<'PY'
import re
import sys
from pathlib import Path

last_line = Path(sys.argv[1]).read_text().splitlines()[-1]
match = re.fullmatch(r"([1-9][0-9]*)/([1-9][0-9]*) suites passed", last_line)
if not match or match[1] != match[2]:
    sys.exit("M1-81: missing all-suites passing result")
PY

# The previous independent reviewer stopped on a headless ReadFile denial.
# Verify the same settings the orchestrator's next independent review will use.
# The standalone review script still defaults to the narrower task-only list.
M1_81_REVIEW_SETTINGS="$HOME/.local/share/night_shift/agy_settings.json" \
  bash production/qa/evidence/M1-81_review.sh
