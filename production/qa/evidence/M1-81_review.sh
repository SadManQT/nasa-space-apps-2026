#!/usr/bin/env bash
# Re-run the denied Jetski review with explicit, session-only read permissions.
# Run on the host through M1-81_capture.sh: the CLI needs its existing profile.
# No shared settings, credentials or permission-bypass flag are changed.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
evidence_dir="$repo_root/production/qa/evidence"
settings_file="${M1_81_REVIEW_SETTINGS:-$evidence_dir/M1-81_settings.json}"
result_file="$evidence_dir/M1-81_review_output.txt"
runner=/Users/sadmansakib/.local/bin/gocode-run

if [[ -n "${CODEX_SANDBOX:-}" ]]; then
  echo "M1-81: run this review on the host; the CLI profile is outside the sandbox." >&2
  exit 2
fi
[[ -x "$runner" ]] || { echo "M1-81: gocode-run is unavailable." >&2; exit 2; }
python3 -m json.tool "$settings_file" >/dev/null

prompt_file="$(mktemp "$evidence_dir/M1-81_review_prompt.XXXXXX")"
trap 'rm -f "$prompt_file"' EXIT
cat >"$prompt_file" <<'PROMPT'
You are the independent senior reviewer re-running the previously denied M1-81
review. Work read-only in /Users/sadmansakib/nasa-space-apps-2026/.night/nslot1.
Do not modify any file, run game tests, or take another board task.

Use your file-reading tool to read AGENTS.md and PRODUCTION_HANDBOOK.md sections
2-4 and 10. Read production/plan/GO_NEXT.md, and use
python3 production/plan/board.py show M1-81 to obtain the acceptance criteria.
Inspect git status and git diff and the task's new evidence scripts/settings.
Read production/qa/evidence/M1-55_test_results.txt, M1-55_qa.md and M1-29_qa.md.
Read M1-81_host_test_results.txt and M1-81_fix_test_results.txt in that directory.
The --settings file allows read_file access to these project files and the CLI's
internal brain directory, including its home/.gemini alias.
Do not read unrelated personal files or load unrelated skills or memory.

Check that the handbook accurately records Ramim's delivered but incomplete UI
work at source 66aed53, its historical Windows 53/54 gate, Atik's outstanding
M1-68, and Tara's current-reference qualification. A later macOS 54/54 result
does not complete the Windows task. Only M1-81's board state may change.
Check the AI log, evidence and board entry are truthful. This task changes no
player-facing content, canon, numbers, scene joins or assets.
Run python3 production/plan/board.py check.

Begin with exactly VERDICT: PASS or VERDICT: FIX. For FIX, list concrete defects
with file:line. After a successful actual file-tool read of AGENTS.md and the
handbook, also include the line M1-81 READ_FILE: PASS.
PROMPT

# gocode-run passes AGY_SETTINGS to agy --settings for the existing buet account.
# Preserve a non-zero CLI status and require substantive review output as well.
if AGY_SETTINGS="$settings_file" EFFORT=xhigh \
  "$runner" buet "$prompt_file" gemini-4-argon-high >"$result_file" 2>&1; then
  cat "$result_file"
else
  result_code=$?
  cat "$result_file"
  exit "$result_code"
fi
if ! grep -qx 'VERDICT: PASS' "$result_file" \
  || ! grep -qx 'M1-81 READ_FILE: PASS' "$result_file" \
  || grep -qiE '^jetski: no output produced|^VERDICT: FIX' "$result_file"; then
  echo "M1-81: review or file permission verification failed." >&2
  exit 1
fi
