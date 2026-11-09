#!/usr/bin/env python3
"""Run the real loading suite in fresh processes, retaining complete diagnostics.

Requires Python 3, Bash (Git Bash on Windows), and an existing Godot executable.
Does not delete import caches, modify game settings, or run concurrent engines.
"""
import argparse
import hashlib
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[3]


def output(command, *, timeout=30):
    try:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                errors="replace", timeout=timeout)
        return {"command": command, "exit_code": result.returncode,
                "stdout": result.stdout.strip(), "stderr": result.stderr.strip()}
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"command": command, "error": str(error)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--bash", type=Path, help="Bash executable; on Windows select Git Bash, not WSL.")
    parser.add_argument("--output", required=True, type=Path,
                        help="New evidence directory; existing directories are refused.")
    parser.add_argument("--runs", type=int, choices=[1, 2, 3], default=2)
    parser.add_argument("--hardware-note", default="", help="CPU/GPU/RAM and other workloads, if known")
    args = parser.parse_args()
    godot = args.godot.expanduser().resolve()
    bash = args.bash.expanduser().resolve().as_posix() if args.bash else shutil.which("bash")
    if not godot.is_file() or not bash:
        parser.error("Provide an existing Godot executable and install Bash (Git Bash on Windows).")
    if not Path(bash).is_file():
        parser.error("Provide an existing Bash executable.")
    if platform.system() == "Windows" and "windows/system32" in bash.replace("\\", "/").lower():
        parser.error("Select Git Bash with --bash; WSL Bash cannot run this Windows engine.")
    destination = args.output.expanduser().resolve()
    try:
        destination.mkdir(parents=True, exist_ok=False)
    except FileExistsError:
        parser.error("Choose a new output directory to preserve previous evidence.")
    metadata = {
        "utc": datetime.now(timezone.utc).isoformat(),
        "os": platform.platform(), "cpu": platform.processor(),
        "architecture": platform.machine(), "logical_cpus": os.cpu_count(),
        "python": platform.python_version(), "hardware_note": args.hardware_note,
        "git": output(["git", "rev-parse", "HEAD"]),
        "game_tree": output(["git", "rev-parse", "HEAD:game"]),
        "retain_stage_trace": os.environ.get("LLA_RETAIN_LOAD_TRACE") == "1",
        "working_changes": output(["git", "status", "--short"]),
        "engine": output([godot.as_posix(), "--version"]),
        "cache_policy": "Existing import/OS caches retained. Each run is a fresh Godot process; no cold-cache claim.",
        "runs": [],
    }
    if platform.system() == "Windows":
        metadata["hardware"] = output([
            "powershell", "-NoProfile", "-Command",
            "@{cpu=(Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name); "
            "gpu=(Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name); "
            "ram_bytes=(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory} | ConvertTo-Json",
        ])
    manifest = destination / "manifest.json"
    failed = False
    for index in range(1, args.runs + 1):
        run_dir = destination / f"run-{index}"
        run_dir.mkdir()
        env = {**os.environ, "GODOT": godot.as_posix(), "TEST_LOG_DIR": run_dir.as_posix()}
        command = [bash, "game/tools/run_tests.sh", "performance_runtime"]
        print(f"Run {index}/{args.runs}; full diagnostics: {run_dir}", flush=True)
        start = time.monotonic()
        try:
            with (run_dir / "runner.txt").open("w", encoding="utf-8") as log:
                result = subprocess.run(command, cwd=ROOT, env=env, stdout=log,
                                        stderr=subprocess.STDOUT)
            code = result.returncode
        except OSError as error:
            (run_dir / "runner.txt").write_text(str(error), encoding="utf-8")
            code = 2
        run = {"index": index, "command": command,
               "exit_code": code, "seconds": time.monotonic() - start}
        if metadata["retain_stage_trace"]:
            trace = run_dir / "loading_trace.json"
            try:
                raw = trace.read_bytes()
                run["stage_trace"] = {"path": trace.relative_to(destination).as_posix(),
                                      "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}
            except OSError as error:
                run["stage_trace"] = {"error": f"missing/unreadable retained stage trace: {error}"}
                failed = True
        metadata["runs"].append(run)
        manifest.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
        failed |= code != 0
        print((run_dir / "runner.txt").read_text(encoding="utf-8", errors="replace"), end="", flush=True)
    print(f"Evidence: {destination}; thresholds and suite assertions unchanged.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
