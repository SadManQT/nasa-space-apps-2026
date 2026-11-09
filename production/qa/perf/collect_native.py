#!/usr/bin/env python3
"""Retain native loading/input results, including process exit after a PASS marker.

Runs existing production fixtures; never clears caches or changes project settings.
Use a new output directory for each attempt. Native input uses the existing QA
adapter so screenshots and input traces cannot overwrite earlier evidence.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import time

ROOT = Path(__file__).resolve().parents[3]
INPUT = ROOT / "production/qa/playtests/first_impressions/retest_2026-11-09/capture_dry_zero.gd"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--case", choices=["input", "perf"], required=True)
    parser.add_argument("--renderer", choices=["forward_plus", "gl_compatibility"], default="forward_plus")
    parser.add_argument("--driver", help="Metal on macOS, Vulkan on the original Windows host")
    parser.add_argument("--timeout", type=float, default=180)
    parser.add_argument("--sample-after", type=float, help="macOS stack sample after this many seconds")
    parser.add_argument("--seconds", type=float, default=20, help="Existing perf-probe sample duration")
    parser.add_argument("--always-on-top", action="store_true")
    args = parser.parse_args()
    if args.timeout <= 0 or args.seconds <= 0 or (args.sample_after is not None and args.sample_after <= 0):
        parser.error("Durations must be positive")
    godot = args.godot.expanduser().resolve()
    if not godot.is_file():
        parser.error("Provide an existing Godot executable")
    destination = args.output.expanduser().resolve()
    try:
        destination.mkdir(parents=True, exist_ok=False)
    except FileExistsError:
        parser.error("Choose a new evidence directory; prior attempts are preserved")
    command = [str(godot), "--path", str(ROOT / "game"), "--rendering-method", args.renderer,
               "--resolution", "1280x720", "--log-file", str(destination / "engine.log")]
    if args.driver:
        command += ["--rendering-driver", args.driver]
    if args.always_on_top:
        command += ["--always-on-top"]
    if args.case == "input":
        command += ["--script", str(INPUT), "--", "--capture"]
        marker = "CAMPAIGN INTERACTION INPUT RESULT: PASS"
    else:
        command += ["--script", "res://tools/perf_probe.gd", "--", "--perf-probe",
                    "--perf-seconds=" + str(args.seconds), "--perf-output=" + str(destination / "probe")]
        marker = "PERF RESULT: PASS"
    sources = ["game/project.godot", "game/scripts/asset_geometry.gd",
               "game/scripts/campaign/chapter1_campaign.gd", "game/scripts/loading/load_preparation.gd",
               "game/scripts/loading/resource_job.gd", "game/scripts/loading/preparation_watchdog.gd",
               "game/scripts/player/player_controller.gd", "game/tools/test_campaign_interaction_input.gd",
               "game/tools/support/isolated_storage.gd", "game/tools/perf_probe.gd",
               str(INPUT.relative_to(ROOT))]
    def hashes():
        return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
                for name in sources if (ROOT / name).is_file()}
    metadata = {"command": command, "case": args.case, "os": platform.platform(),
                "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                "source_sha256": hashes(), "start_epoch": time.time(),
                "cache_policy": "Existing caches retained; fixture isolates test saves and first-use user directories.",
                "timeout_seconds": args.timeout}
    manifest = destination / "run.json"
    manifest.write_text(json.dumps(metadata, indent=2) + "\n")
    started = time.monotonic()
    result_seen = None
    timed_out = False
    sampled = False
    log_path = destination / "stdout.log"
    with log_path.open("w") as stream:
        process = subprocess.Popen(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT,
                                   env={**os.environ, "TEST_LOG_DIR": str(destination)})
        while process.poll() is None:
            elapsed = time.monotonic() - started
            if result_seen is None and marker in log_path.read_text(errors="replace"):
                result_seen = elapsed
            if args.sample_after and elapsed >= args.sample_after and not sampled:
                sampled = True
                if platform.system() == "Darwin":
                    result = subprocess.run(["sample", str(process.pid), "3", "-file", str(destination / "process_sample.txt")],
                                            capture_output=True, text=True, timeout=15)
                    metadata["sample"] = {"exit_code": result.returncode, "stdout": result.stdout, "stderr": result.stderr}
            if elapsed >= args.timeout:
                timed_out = True
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                break
            time.sleep(0.1)
    duration = time.monotonic() - started
    log = log_path.read_text(errors="replace")
    markers = [line for line in log.splitlines() if "RESULT:" in line]
    source_unchanged = hashes() == metadata["source_sha256"]
    passed = not timed_out and process.returncode == 0 and marker in log and source_unchanged
    if args.case == "input":
        passed = passed and (destination / "input_trace.json").is_file() and len(list(destination.glob("*.png"))) == 5
    else:
        passed = passed and (destination / "probe.json").is_file() and (destination / "probe.csv").is_file()
    passed = passed and not any(message in log for message in ["SCRIPT ERROR", "Parse Error", "Failed to load script"])
    artifacts = {p.name: {"bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
                 for p in destination.iterdir() if p.is_file() and p != manifest}
    metadata.update({"elapsed_seconds": duration, "exit_code": 124 if timed_out else process.returncode,
                     "raw_returncode": process.returncode, "timed_out": timed_out, "markers": markers,
                     "result_first_observed_seconds": result_seen, "source_unchanged": source_unchanged,
                     "artifacts": artifacts, "capture_checks_passed": passed})
    manifest.write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"{'PASS' if passed else 'FAIL'} {args.case}: exit {metadata['exit_code']}, {duration:.3f}s; {manifest}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
