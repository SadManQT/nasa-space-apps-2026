"""Bounded frozen-source Windows cold/warm import diagnostic. Never edits the source checkout."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import tempfile
import time


def sha(path):
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def dump(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8", newline="\n")


def git(root, *args):
    return subprocess.check_output(["git", *args], cwd=root)


def frozen_inputs(root, revision):
    rows = git(root, "ls-tree", "-r", "-z", "--format=%(objectname) %(path)", revision, "--", "game").split(b"\0")
    rows = [row.decode().split(" ", 1) for row in rows if row]
    blob_data = subprocess.run(["git", "cat-file", "--batch"], cwd=root, input=("\n".join(row[0] for row in rows) + "\n").encode(), capture_output=True, check=True).stdout
    common = Path(git(root, "rev-parse", "--git-common-dir").decode().strip())
    if not common.is_absolute():
        common = (root / common).resolve()
    cursor = 0
    result = []
    for oid, name in rows:
        end = blob_data.index(b"\n", cursor)
        header = blob_data[cursor:end].decode().split()
        if header[1] != "blob":
            raise RuntimeError("Expected a source blob: " + name)
        size = int(header[2])
        raw = blob_data[end + 1:end + 1 + size]
        cursor = end + 2 + size
        row = {"path": name, "git_blob": oid}
        if raw.startswith(b"version https://git-lfs.github.com/spec/v1\n"):
            payload = re.search(rb"oid sha256:([0-9a-f]{64})", raw).group(1).decode()
            length = int(re.search(rb"size ([0-9]+)", raw).group(1))
            source = common / "lfs" / "objects" / payload[:2] / payload[2:4] / payload
            if not source.is_file():
                raise RuntimeError("Missing local LFS payload for " + name)
            row.update(sha256=payload, bytes=length, lfs_source=source)
        else:
            row.update(sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw), raw=raw)
        result.append(row)
    return result


def materialize(folder, inputs):
    for row in inputs:
        target = folder / row["path"]
        target.parent.mkdir(parents=True, exist_ok=True)
        if "raw" in row:
            target.write_bytes(row["raw"])
        else:
            with row["lfs_source"].open("rb") as source, target.open("wb") as destination:
                digest = hashlib.sha256()
                for chunk in iter(lambda: source.read(1024 * 1024), b""):
                    destination.write(chunk)
                    digest.update(chunk)
            if digest.hexdigest() != row["sha256"]:
                raise RuntimeError("LFS payload failed verification: " + row["path"])
    if (folder / "game/.godot").exists():
        raise RuntimeError("Cold project unexpectedly contains an import cache")


def cache_state(folder):
    cache = folder / "game/.godot"
    files = list(cache.rglob("*")) if cache.exists() else []
    result = {"exists": cache.exists(), "file_count": sum(p.is_file() for p in files)}
    for rel in ["global_script_class_cache.cfg", "uid_cache.bin", "editor/filesystem_cache10"]:
        p = cache / rel
        if p.is_file():
            result[rel] = {"bytes": p.stat().st_size, "sha256": sha(p)}
    return result


def diagnostics(path):
    cleaned = re.sub(r"\x1b\[[0-9;]*m", "", path.read_text(encoding="utf-8", errors="replace"))
    imported = re.findall(r"reimport \| ([^\r\n]+)", cleaned)
    return {"file": str(path), "sha256": sha(path), "engine_errors": [line for line in cleaned.splitlines() if re.match(r"^\s*ERROR:", line)], "script_errors": [line for line in cleaned.splitlines() if re.search(r"SCRIPT ERROR|Parse Error|Failed to load script|Could not find type", line)], "warning_count": sum("WARNING:" in line for line in cleaned.splitlines()), "last_printed_reimport": imported[-1] if imported else None, "suite_summary": re.findall(r"[0-9]+/[0-9]+ suites passed", cleaned), "setup_failure": "FAIL setup:" in cleaned, "native_crash_signature": bool(re.search(r"Segmentation fault|signal 11|exit 139", cleaned, re.I))}


def invoke(folder, name, command, cwd, env, timeout):
    start = time.time()
    monotonic_start = time.monotonic()
    log_path = folder / (name + ".txt")
    record_path = folder / (name + ".json")
    logs = folder / (name + "_logs")
    if log_path.exists() or record_path.exists() or logs.exists():
        raise FileExistsError("Refusing to overwrite prior invocation evidence: " + name)
    env = env.copy()
    if "runner" in name:
        logs.mkdir()
        env["TEST_LOG_DIR"] = str(logs.resolve())
    timed_out = False
    termination = {"needed": False}
    with log_path.open("wb") as log:
        process = subprocess.Popen(command, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT)
        pid = process.pid
        try:
            raw_exit = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            termination = {"needed": True, "tree_kill_confirmed": False}
            try:
                if os.name == "nt":
                    killed = subprocess.run(["taskkill", "/PID", str(pid), "/T", "/F"], capture_output=True, timeout=10)
                    termination["taskkill_exit"] = killed.returncode
                    termination["tree_kill_confirmed"] = killed.returncode == 0
                else:
                    process.kill()
                raw_exit = process.wait(timeout=10)
                termination["parent_exit_confirmed"] = True
            except subprocess.TimeoutExpired:
                raw_exit = process.poll()
                termination["parent_exit_confirmed"] = raw_exit is not None
                termination["bounded_termination_timed_out"] = True
    outer = diagnostics(log_path)
    # The mandatory runner redirects setup/suite diagnostics into TEST_LOG_DIR.
    # Audit those authoritative raw logs instead of mistaking its short summary for clean setup.
    raw_logs = sorted(logs.glob("*.log")) if logs.exists() else []
    audited = [diagnostics(path) for path in raw_logs] if raw_logs else [outer]
    errors = [line for row in audited for line in row["engine_errors"]]
    scripts = [line for row in audited for line in row["script_errors"]]
    imported = [row["last_printed_reimport"] for row in audited if row["last_printed_reimport"]]
    result = {"command": command, "pid": pid, "start_utc_epoch": start, "duration_seconds": round(time.monotonic() - monotonic_start, 3), "timed_out": timed_out, "termination": termination, "raw_exit_code": raw_exit, "unsigned_exit_hex": hex(raw_exit & 0xffffffff) if raw_exit is not None else None, "effective_exit_code": 124 if timed_out else raw_exit, "log_sha256": sha(log_path), "test_log_dir": env.get("TEST_LOG_DIR"), "isolated_env": {key: env.get(key) for key in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]}, "script_error_lines": scripts, "generic_error_lines": errors, "generic_error_count": len(errors), "warning_count": sum(row["warning_count"] for row in audited), "last_printed_reimport": imported[-1] if imported else None, "suite_summary": outer["suite_summary"], "setup_failure": outer["setup_failure"], "native_crash_signature": (raw_exit in [-1073741819, 3221225477, 139, -11] or any(row["native_crash_signature"] for row in [outer, *audited])), "audited_logs": audited}
    dump(record_path, result)
    print(name, "exit", result["effective_exit_code"], "seconds", result["duration_seconds"], flush=True)
    if timed_out:
        raise RuntimeError("Diagnostic timeout: no further runs or cleanup; retain scratch and inspect termination record")
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--scratch-root", type=Path, required=True)
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    root = args.source_root.resolve()
    output = (args.output or Path(__file__).resolve().parent).resolve()
    output.mkdir(parents=True, exist_ok=True)
    for name in ["source_manifest.json", "repro_state.json", "native_first", "runner_first"]:
        if (output / name).exists():
            raise FileExistsError("Refusing to overwrite an earlier diagnostic; use --output: " + name)
    revision = git(root, "rev-parse", args.revision).decode().strip()
    tree = git(root, "rev-parse", revision + ":game").decode().strip()
    inputs = frozen_inputs(root, revision)
    total_bytes = sum(row["bytes"] for row in inputs)
    args.scratch_root.mkdir(parents=True, exist_ok=True)
    scratch = args.scratch_root.resolve()
    if shutil.disk_usage(scratch).free < total_bytes + 2 * 1024**3:
        raise RuntimeError("Insufficient scratch space for one frozen game copy")
    run_root = Path(tempfile.mkdtemp(prefix="lla-m185-", dir=scratch)).resolve()
    if not run_root.is_relative_to(scratch):
        raise RuntimeError("Scratch root escaped")
    hardware_command = ["powershell.exe", "-NoProfile", "-Command", "$ErrorActionPreference='Stop'; [pscustomobject]@{cpu=@(Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors);gpu=@(Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion);os=(Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,TotalVisibleMemorySize)} | ConvertTo-Json -Depth 4"]
    hardware = subprocess.run(hardware_command, capture_output=True, text=True, timeout=30)
    hardware_data = json.loads(hardware.stdout.lstrip("\ufeff")) if hardware.returncode == 0 else {"collection_error": hardware.stderr}
    source_manifest = [{k: row[k] for k in ["path", "git_blob", "sha256", "bytes"]} for row in inputs]
    dump(output / "source_manifest.json", source_manifest)
    metadata = {"revision": revision, "collector_sha256": sha(Path(__file__).resolve()), "game_tree": tree, "source_files": len(inputs), "source_bytes": total_bytes, "lfs_files": sum("lfs_source" in row for row in inputs), "source_manifest_sha256": sha(output / "source_manifest.json"), "godot_executable": str(args.godot.resolve()), "godot_sha256": sha(args.godot), "platform": platform.platform(), "hardware": hardware_data, "scratch_root": str(run_root), "scope": "Fresh project import cache and isolated appdata; OS filesystem cache is not evicted. Copies contain the frozen game tree, not user saves or production staging files.", "pairs": []}
    dump(output / "repro_state.json", metadata)
    for pair in ["native_first", "runner_first"]:
        folder = run_root / ("project_" + pair)
        evidence = output / pair
        evidence.mkdir(exist_ok=True)
        if shutil.disk_usage(scratch).free < total_bytes + 2 * 1024**3:
            raise RuntimeError("Insufficient remaining space; retain earlier evidence and scratch")
        print("Materializing", pair, len(inputs), "files", total_bytes, "bytes", flush=True)
        materialize(folder, inputs)
        env = os.environ.copy()
        for name, subdir in [("APPDATA", "roaming"), ("LOCALAPPDATA", "local"), ("TEMP", "tmp"), ("TMP", "tmp")]:
            p = folder / "isolated_user" / subdir
            p.mkdir(parents=True, exist_ok=True)
            env[name] = str(p)
        env["GODOT"] = str(args.godot.resolve())
        before = cache_state(folder)
        dump(evidence / "before.json", before)
        editor = [str(args.godot.resolve()), "--headless", "--path", ".", "--editor", "--quit"]
        runner = ["C:/Program Files/Git/bin/bash.exe", "tools/run_tests.sh", "hint_player"]
        runs = []
        if pair == "native_first":
            runs.append(invoke(evidence, "cold_editor", editor, folder / "game", env, args.timeout))
            dump(evidence / "after_cold.json", cache_state(folder))
            runs.append(invoke(evidence, "warm_editor", editor, folder / "game", env, args.timeout))
            runs.append(invoke(evidence, "warm_runner", runner, folder / "game", env, args.timeout))
        else:
            runs.append(invoke(evidence, "cold_runner", runner, folder / "game", env, args.timeout))
            dump(evidence / "after_cold.json", cache_state(folder))
            runs.append(invoke(evidence, "warm_runner", runner, folder / "game", env, args.timeout))
        after = cache_state(folder)
        changed = []
        for row in inputs:
            if row["path"].endswith(".import"):
                p = folder / row["path"]
                digest = sha(p)
                if digest != row["sha256"]:
                    changed.append({"path": row["path"], "before_sha256": row["sha256"], "after_sha256": digest})
        dump(evidence / "changed_sidecars.json", changed)
        crashed = any(row["effective_exit_code"] != 0 or row["script_error_lines"] or row["generic_error_count"] for row in runs)
        metadata["pairs"].append({"name": pair, "before_cache": before, "after_cache": after, "runs": runs, "changed_sidecars": len(changed), "failed_project_retained": crashed})
        dump(output / "repro_state.json", metadata)
        if not crashed:
            # Only remove this exact generated copy, under the verified session root.
            target = folder.resolve()
            if target.parent != run_root or not target.name.startswith("project_") or not target.is_relative_to(scratch):
                raise RuntimeError("Refusing unsafe cleanup")
            shutil.rmtree(target)
    metadata["collection_complete"] = True
    metadata["crash_reproduced"] = any(row["native_crash_signature"] for pair in metadata["pairs"] for row in pair["runs"])
    metadata["all_runs_successful"] = all(row["effective_exit_code"] == 0 and not row["script_error_lines"] and not row["generic_error_count"] for pair in metadata["pairs"] for row in pair["runs"])
    dump(output / "repro_state.json", metadata)
    print(json.dumps({k: metadata[k] for k in ["collection_complete", "crash_reproduced", "all_runs_successful"]}), flush=True)


if __name__ == "__main__":
    main()
