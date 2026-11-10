"""Resumable M1-53 desktop acceptance. Exit 0: ten passes; 3: partial; 1: failed.

Never marks the board done. Validates retained evidence before resuming.
"""

import argparse
from collections import Counter
import csv
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import signal
import struct
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
EVENTS = ("title_build", "new_campaign", "garden_enter", "garden_rebuild", "full_cast_enter")
SAMPLES = {"title", "hub_walk", "hub_panels", "garden_walk", "garden_panels",
           "full_cast_walk", "full_cast_panels"} | {f"video_CS-{i:02d}" for i in range(1, 19)}
ERRORS = ("SCRIPT ERROR", "Parse Error", "Failed to load script")
SUCCESS = "10/10 consecutive windowed probes passed; zero stalls; all screenshots and CSV/JSON retained."
WINDOW = ["--rendering-method", "forward_plus", "--rendering-driver", "metal",
          "--resolution", "1280x720", "--always-on-top"]


def require(condition, message):
    """Reject inconsistent evidence; an engine exit alone never implies PASS."""
    if not condition:
        raise ValueError(message)


def valid_log(path, marker):
    """Require a completion marker and no script errors in a retained log."""
    text = path.read_text(errors="replace")
    require(marker in text and not any(error in text for error in ERRORS), f"Invalid log: {path.name}")


def valid_png(path):
    """Require a PNG header and a 16:9 viewport of at least 1280 by 720 (the game applies the
    player's display setting, 1920 by 1080 by default, once a campaign starts)."""
    data = path.read_bytes()
    require(len(data) > 1000 and data[:8] == b"\x89PNG\r\n\x1a\n", f"Invalid screenshot: {path.name}")
    width, height = struct.unpack(">II", data[16:24])
    require(width >= 1280 and height >= 720 and width * 9 == height * 16, f"Invalid screenshot size {width}x{height}: {path.name}")


def validate_forced(evidence):
    """Validate the held-job regressions (real semaphore-held workers recover before release)."""
    valid_log(evidence / "M1-53_forced_stall.log", "LOADING WATCHDOG RESULT: PASS")
    valid_log(evidence / "M1-53_forced_geometry.log", "ASSET GEOMETRY RECOVERY RESULT: PASS")


def validate_probe(evidence, index):
    """Validate a full rendered probe: transitions, samples and raw frames."""
    name = f"M1-53_run_{index:02d}"
    for suffix in (".log", "_engine.log"):
        valid_log(evidence / f"{name}{suffix}", "PERF RESULT: PASS (rendered samples recorded)")
    data = json.loads((evidence / f"{name}.json").read_text())
    metadata = data["metadata"]
    require(data["cpu_only"] is False and metadata["cpu_only"] is False and
            metadata["display"] == "macOS" and metadata["driver"] == "metal" and
            metadata["renderer"] == "forward_plus" and metadata["window"] == "(1280, 720)" and
            metadata["seconds"] == 20, f"{name}: expected full 20-second windowed Metal probe")
    require(data.get("preparation_recoveries") == [], f"{name}: unexpected/missing recovery metadata")
    events = {item["event"]: item for item in data["events"]}
    for event in EVENTS:
        duration = events.get(event, {}).get("duration_ms", float("inf"))
        require(math.isfinite(duration) and 0 <= duration <= 90000, f"{name}: missing/stalled {event}")
        valid_png(evidence / f"{name}_{event}.png")
    summaries = {item["sample"]: item for item in data["summaries"]}
    require(SAMPLES <= summaries.keys(), f"{name}: incomplete walking/panel/film samples")
    counts, durations = Counter(), {}
    with (evidence / f"{name}.csv").open(newline="") as stream:
        for row in csv.DictReader(stream):
            sample = row["sample"]
            elapsed, frame = float(row["elapsed_ms"]), float(row["frame_ms"])
            require(math.isfinite(elapsed) and math.isfinite(frame) and frame > 0,
                    f"{name}: invalid frame data")
            counts[sample] += 1
            durations[sample] = max(durations.get(sample, 0), elapsed)
    for sample in SAMPLES:
        require(counts[sample] == summaries[sample]["frames_or_calls"] and durations.get(sample, 0) >= 19000,
                f"{name}: incomplete CSV sample {sample}")
    paths = [evidence / f"{name}{suffix}" for suffix in (".json", ".csv", ".log", "_engine.log")]
    paths += [evidence / f"{name}_{event}.png" for event in EVENTS]
    return {"run": index, "full_cast_enter": events["full_cast_enter"], "recoveries": [],
            "artifacts_sha256": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}}


def source_hash():
    """Prevent resuming a series after its runtime or probe changes."""
    digest = hashlib.sha256()
    paths = [ROOT / "game/project.godot"]
    for directory in ("scripts", "scenes", "resources", "shaders"):
        paths += [p for p in (ROOT / "game" / directory).rglob("*") if p.is_file()]
    paths += list((ROOT / "game/tools").glob("*.gd"))
    for path in sorted(paths):
        digest.update(str(path.relative_to(ROOT)).encode() + b"\0")
        digest.update(path.read_bytes())
    return digest.hexdigest()


def write_json(path, data):
    """Publish a checkpoint atomically; outer timeouts cannot truncate prior passes."""
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(data, indent=2) + "\n")
    temporary.replace(path)


def run_engine(evidence, name, flags, marker, timeout=900, progress_timeout=90):
    """Run one engine, terminating it on timeout or supervisor interruption."""
    log = evidence / f"{name}.log"
    command = [os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot"),
               "--path", "game", "--log-file", str(evidence / f"{name}_engine.log"), *flags]
    start = last_progress = time.monotonic()
    last_size = 0
    with log.open("w") as output:
        process = subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT, cwd=ROOT)
        try:
            while process.poll() is None:
                now, size = time.monotonic(), log.stat().st_size
                if size != last_size:
                    last_progress, last_size = now, size
                if now - start > timeout or now - last_progress > progress_timeout:
                    raise RuntimeError(f"{name}: STALL (total {now-start:.1f}s; silent {now-last_progress:.1f}s)")
                time.sleep(0.5)
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
    require(process.returncode == 0, f"{name}: engine exit {process.returncode}; see {log.name}")
    valid_log(log, marker)
    return round(time.monotonic() - start, 1)


def main():
    """Resume a bounded batch or audit retained evidence; report partial runs explicitly."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--max-runs", type=int, default=2, help="new probes this batch; 0 = all remaining without outer time limit")
    parser.add_argument("--verify-only", action="store_true", help="validate retained files without launching Godot")
    args = parser.parse_args()
    require(args.max_runs >= 0, "--max-runs must be nonnegative")
    evidence = ROOT / "production/qa/evidence"
    progress = evidence / "M1-53_capture_progress.json"
    summary = evidence / "M1-53_capture_summary.txt"
    # Lock the stable launcher file, without a disposable repository artifact.
    with (evidence / "M1-53_capture.sh").open() as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        fingerprint = source_hash()
        state = json.loads(progress.read_text()) if progress.exists() else {
            "source_sha256": fingerprint, "runs": [], "forced_stall": False}
        require(state["source_sha256"] == fingerprint, "Runtime changed: archive this evidence series before starting a new one")
        require(not state.get("failure"), "Series contains a failed probe; archive it and start a new consecutive series")

        def record(message):
            print(message, flush=True)
            with summary.open("a") as stream:
                stream.write(message + "\n")

        def checkpoint():
            state["complete"] = len(state["runs"]) == 10 and state["forced_stall"] and not state.get("failure")
            write_json(progress, state)
            complete_path = evidence / "M1-53_ten_runs.json"
            if state["complete"]:
                write_json(complete_path, state["runs"])
            else:
                complete_path.unlink(missing_ok=True)

        def interrupted(signum, _frame):
            raise InterruptedError(f"Capture interrupted by signal {signum}; completed probes retained")

        signal.signal(signal.SIGTERM, interrupted)
        signal.signal(signal.SIGINT, interrupted)
        try:
            # Revalidate retained evidence before launching anything new.
            if (evidence / "M1-53_forced_stall.log").exists():
                validate_forced(evidence)
                state["forced_stall"] = True
            else:
                require(not state["forced_stall"], "Previously validated forced-stall evidence is missing")
            verified = []
            for index in range(1, 11):
                if not (evidence / f"M1-53_run_{index:02d}.json").exists():
                    require(index > len(state["runs"]), f"Previously validated run {index:02d} evidence is missing")
                    require(not any(evidence.glob(f"M1-53_run_{index:02d}*.log")),
                            f"Run {index:02d} interrupted without complete evidence; a fresh series is required")
                    require(not any((evidence / f"M1-53_run_{later:02d}.json").exists() for later in range(index + 1, 11)),
                            "Gaps in consecutive probe sequence")
                    break
                result = validate_probe(evidence, index)
                previous = next((r for r in state["runs"] if r["run"] == index), None)
                require(previous is None or previous["artifacts_sha256"] == result["artifacts_sha256"],
                        f"Run {index:02d} evidence changed since validation")
                verified.append(result)
                record(f"M1-53_run_{index:02d}: PASS (retained artifacts revalidated; no new engine run claimed).")
            state["runs"] = verified
            checkpoint()
            record(f"AUDIT: forced-stall {'PASS' if state['forced_stall'] else 'absent'}; {len(verified)}/10 complete rendered probes validated (logs, JSON, CSV, PNGs).")
            if not args.verify_only and not state["complete"]:
                run_engine(evidence, "M1-53_import", ["--headless", "--editor", "--quit"], "Godot Engine", 300, 300)
                if not state["forced_stall"]:
                    run_engine(evidence, "M1-53_forced_stall", ["--headless", "--script", "res://tools/test_loading.gd"],
                        "LOADING WATCHDOG RESULT: PASS", 600, 300)
                    run_engine(evidence, "M1-53_forced_geometry", ["--headless", "--script", "res://tools/test_asset_geometry_recovery.gd"],
                        "ASSET GEOMETRY RECOVERY RESULT: PASS", 600, 300)
                    validate_forced(evidence)
                    state["forced_stall"] = True
                    checkpoint()
                remaining = 10 - len(verified)
                for _ in range(min(args.max_runs or remaining, remaining)):
                    index = len(state["runs"]) + 1
                    name = f"M1-53_run_{index:02d}"
                    prefix = evidence / name
                    state["running"] = name
                    checkpoint()
                    elapsed = run_engine(evidence, name, WINDOW + ["--script", "res://tools/perf_probe.gd", "--", "--perf-probe",
                        "--perf-output=" + str(prefix), "--perf-capture-prefix=" + str(prefix)], "PERF RESULT: PASS")
                    state["runs"].append(validate_probe(evidence, index))
                    state.pop("running", None)
                    checkpoint()
                    record(f"{name}: PASS ({elapsed}s); checkpoint saved immediately.")
            if state["complete"]:
                record(SUCCESS)
                return 0
            record(f"INCOMPLETE: {len(state['runs'])}/10 windowed probes passed; M1-53 remains in_progress. Resume this script for the next batch.")
            return 3
        except Exception as error:
            state["failure"] = str(error)
            checkpoint()
            record(f"FAIL: {error}; retained passes are diagnostic evidence, not ten-run acceptance.")
            return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError) as error:
        print(f"FAIL: {error}", flush=True)
        raise SystemExit(1)
