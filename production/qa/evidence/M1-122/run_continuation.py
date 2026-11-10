"""Finish unreported diagnostics; never present separate invocations as one full-gate pass."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import time

root = Path(__file__).resolve().parents[4]
base = root / "production/qa/evidence/M1-122/regression_post_sync"
audit = json.loads((base / "log_audit.json").read_text())
assert audit["full_timed_out"] and not audit["full_summary_present"]
output = base / "continuation"
output.mkdir(exist_ok=False)
profile = root / ".codex/task-tmp/garden-continuation"
profile.mkdir(parents=True, exist_ok=False)
env = os.environ.copy()
for key, suffix in [("APPDATA", "roaming"), ("LOCALAPPDATA", "local"), ("TEMP", "tmp"), ("TMP", "tmp"), ("TMPDIR", "tmp")]:
    folder = profile / suffix
    folder.mkdir(exist_ok=True)
    env[key] = folder.as_posix()
env["GODOT"] = "D:/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
metadata = {"game_tree": subprocess.check_output(["git", "rev-parse", "HEAD:game"], cwd=root, text=True).strip(), "target_unreported_suites": audit["unreported_suite_names"], "scope": "Separate focused mandatory-runner invocations, not a complete continuous full-gate pass. Some substring filters may also recheck previously reported suites; all results retained.", "runs": [], "complete": False}
assert metadata["game_tree"] == audit["source_game_tree"]
covered = set()
for name in metadata["target_unreported_suites"]:
    if name in covered:
        continue
    suffix = name[5:-3]
    folder = output / suffix
    folder.mkdir()
    env["TEST_LOG_DIR"] = (folder / "logs").as_posix()
    command = ["C:/Program Files/Git/bin/bash.exe", "game/tools/run_tests.sh", suffix]
    (output / "state.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    start = time.time()
    mono = time.monotonic()
    print("Starting missing-suite diagnostic", name, flush=True)
    with (folder / "runner.txt").open("wb") as stream:
        process = subprocess.Popen(command, cwd=root, env=env, stdout=stream, stderr=subprocess.STDOUT)
        try:
            rc = process.wait(timeout=900)
            timed = False
        except subprocess.TimeoutExpired:
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], capture_output=True, timeout=10)
            process.wait(timeout=10)
            rc = 124
            timed = True
    text = (folder / "runner.txt").read_text(encoding="utf-8", errors="replace")
    reported = re.findall(r"^(?:ok   |FAIL )tools/(test_[^ ]+\.gd) ::", text, re.M)
    covered.update(reported)
    metadata["runs"].append({"target": name, "command": command, "start_utc_epoch": start, "duration_seconds": round(time.monotonic() - mono, 3), "exit_code": rc, "timed_out": timed, "reported_suites": reported, "failed_lines": [line for line in text.splitlines() if line.startswith("FAIL tools/")], "runner_sha256": hashlib.sha256((folder / "runner.txt").read_bytes()).hexdigest()})
    metadata["still_unreported_suites"] = [value for value in metadata["target_unreported_suites"] if value not in covered]
    (output / "state.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(name, rc, text[-700:], flush=True)
    if timed:
        raise SystemExit(124)
metadata["complete"] = not metadata["still_unreported_suites"]
(output / "state.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
print("CONTINUATION COMPLETE", metadata["complete"], flush=True)
