"""Run required focused and full gates sequentially on the synchronized tree."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import time

root = Path(__file__).resolve().parents[4]
output = root / "production/qa/evidence/M1-122/regression_post_sync"
output.mkdir(exist_ok=False)
profile = root / ".codex/task-tmp/garden-regression-post-sync"
profile.mkdir(parents=True, exist_ok=False)
env = os.environ.copy()
for key, suffix in [("APPDATA", "roaming"), ("LOCALAPPDATA", "local"), ("TEMP", "tmp"), ("TMP", "tmp"), ("TMPDIR", "tmp")]:
    folder = profile / suffix
    folder.mkdir(exist_ok=True)
    env[key] = folder.as_posix()
env["GODOT"] = "D:/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
metadata = {"source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(), "game_tree": subprocess.check_output(["git", "rev-parse", "HEAD:game"], cwd=root, text=True).strip(), "local_game_diff": subprocess.check_output(["git", "diff", "--", "game"], cwd=root, text=True), "isolated_env": {key: env[key] for key in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP", "TMPDIR", "GODOT"]}, "runs": []}
for name, suffix in [("garden", ["garden"]), ("habitat_rooms", ["habitat_rooms"]), ("full", [])]:
    folder = output / name
    folder.mkdir()
    env["TEST_LOG_DIR"] = (folder / "logs").as_posix()
    command = ["C:/Program Files/Git/bin/bash.exe", "game/tools/run_tests.sh", *suffix]
    start = time.time()
    mono = time.monotonic()
    (output / "run.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print("Starting", name, start, flush=True)
    with (folder / "runner.txt").open("wb") as stream:
        process = subprocess.Popen(command, cwd=root, env=env, stdout=stream, stderr=subprocess.STDOUT)
        try:
            rc = process.wait(timeout=2400)
            timed = False
        except subprocess.TimeoutExpired:
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], capture_output=True, timeout=10)
            process.wait(timeout=10)
            rc = 124
            timed = True
    record = {"name": name, "command": command, "pid": process.pid, "start_utc_epoch": start, "duration_seconds": round(time.monotonic() - mono, 3), "exit_code": rc, "timed_out": timed, "runner_sha256": hashlib.sha256((folder / "runner.txt").read_bytes()).hexdigest(), "test_log_dir": env["TEST_LOG_DIR"]}
    metadata["runs"].append(record)
    (output / "run.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(record), flush=True)
    print((folder / "runner.txt").read_text(encoding="utf-8", errors="replace")[-5500:], flush=True)
    if timed or (rc and name != "full"):
        raise SystemExit(rc or 1)
