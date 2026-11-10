"""Audit complete mandatory runner logs without reclassifying its pass/fail result."""
from pathlib import Path
import hashlib
import json
import re
import sys
import subprocess

base = Path(__file__).resolve().parent / (sys.argv[1] if len(sys.argv) > 1 else "regression")
metadata = json.loads((base / "run.json").read_text(encoding="utf-8"))
assert any(row["name"] == "full" for row in metadata["runs"]), "Full runner still active; do not audit partial evidence"
rows = []
for path in sorted(base.glob("*/logs/*.log")):
    raw = path.read_bytes()
    text = re.sub(r"\x1b\[[0-9;]*m", "", raw.decode("utf-8", errors="replace"))
    rows.append({"file": path.relative_to(base).as_posix(), "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest(), "engine_errors": [line for line in text.splitlines() if re.match(r"^\s*ERROR:", line)], "script_errors": [line for line in text.splitlines() if re.search(r"SCRIPT ERROR|Parse Error|Could not find type|Failed to load script", line)], "warning_count": text.count("WARNING:"), "result_lines": [line for line in text.splitlines() if re.search(r"RESULT|REGRESSIONS|PASS \(|^FAIL ", line)]})
summary = (base / "full/runner.txt").read_text(encoding="utf-8", errors="replace")
markers = re.findall(r"^[0-9]+/[0-9]+ suites passed$", summary, re.M)
reported = re.findall(r"^(?:ok   |FAIL )tools/(test_[^ ]+\.gd) ::", summary, re.M)
frozen_files = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", metadata["game_tree"], "tools"], cwd=Path(__file__).resolve().parents[4], text=True).splitlines()
expected = sorted(Path(name).name for name in frozen_files if name.startswith("tools/test_") and name.endswith(".gd"))
full = next(row for row in metadata["runs"] if row["name"] == "full")
report = {"source_game_tree": metadata["game_tree"], "full_exit_code": full["exit_code"], "full_timed_out": full["timed_out"], "full_summary_present": bool(markers), "expected_suite_count": len(expected), "reported_suite_count": len(reported), "unreported_suite_names": [name for name in expected if name not in reported], "scope": "Complete setup and suite logs; printed mandatory runner result retained separately from generic engine diagnostics.", "runner_summary": markers[-1] if markers else None, "failed_suites": [line for line in summary.splitlines() if line.startswith("FAIL tools/")], "engine_error_count": sum(len(row["engine_errors"]) for row in rows), "script_error_count": sum(len(row["script_errors"]) for row in rows), "logs": rows}
(base / "log_audit.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: report[key] for key in ["runner_summary", "failed_suites", "engine_error_count", "script_error_count"]}))
