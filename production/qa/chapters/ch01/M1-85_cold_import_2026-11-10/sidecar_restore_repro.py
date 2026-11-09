"""Follow the historical warm-cache / restored tracked-sidecar condition in an isolated copy."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile


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
    output = (args.output or Path(__file__).resolve().parent / "sidecar_restore").resolve()
    if output.exists():
        raise FileExistsError("Refusing to overwrite the earlier sidecar diagnostic")
    output.mkdir(parents=True)
    collector = Path(__file__).with_name("cold_import_repro.py")
    api = runpy.run_path(str(collector))
    sha, dump, git = api["sha"], api["dump"], api["git"]
    revision = git(root, "rev-parse", args.revision).decode().strip()
    inputs = api["frozen_inputs"](root, revision)
    cache = root / "game/.godot"
    if not (cache / "imported").is_dir():
        raise RuntimeError("A warm source import cache is required; no source cache was changed")
    scratch = args.scratch_root.resolve()
    scratch.mkdir(parents=True, exist_ok=True)
    needed = sum(row["bytes"] for row in inputs) + sum(p.stat().st_size for p in (cache / "imported").rglob("*") if p.is_file())
    if shutil.disk_usage(scratch).free < needed + 2 * 1024**3:
        raise RuntimeError("Insufficient space for isolated warm cache comparison")
    folder = Path(tempfile.mkdtemp(prefix="lla-m185-sidecar-", dir=scratch)).resolve()
    if folder.parent != scratch or not folder.name.startswith("lla-m185-sidecar-"):
        raise RuntimeError("Unexpected scratch target")
    api["materialize"](folder, inputs)
    copied = folder / "game/.godot"
    copied.mkdir()
    # Only reproducible import/class/UID cache. No editor preferences,
    # export credentials, user saves or other appdata are copied.
    shutil.copytree(cache / "imported", copied / "imported")
    selected = []
    for name in [".gdignore", "global_script_class_cache.cfg", "uid_cache.bin"]:
        source = cache / name
        if source.is_file():
            shutil.copy2(source, copied / name)
            selected.append(name)
    for source in (cache / "editor").glob("filesystem_cache*"):
        (copied / "editor").mkdir(exist_ok=True)
        shutil.copy2(source, copied / "editor" / source.name)
        selected.append("editor/" + source.name)
    cache_manifest = []
    for target in sorted(copied.rglob("*")):
        if not target.is_file():
            continue
        rel = target.relative_to(copied)
        source_hash = sha(cache / rel)
        if sha(target) != source_hash:
            raise RuntimeError("Source import cache changed while being copied")
        cache_manifest.append({"file": rel.as_posix(), "bytes": target.stat().st_size, "sha256": source_hash})
    dump(output / "cache_input_manifest.json", cache_manifest)
    overlaid = []
    for row in inputs:
        if row["path"].endswith(".import"):
            source = root / row["path"]
            target = folder / row["path"]
            target.write_bytes(source.read_bytes())
            overlaid.append({"path": row["path"], "local_sha256": sha(source), "git_blob": row["git_blob"]})
    dump(output / "control_sidecars.json", overlaid)
    env = os.environ.copy()
    for name, subdir in [("APPDATA", "roaming"), ("LOCALAPPDATA", "local"), ("TEMP", "tmp"), ("TMP", "tmp")]:
        target = folder / "isolated_user" / subdir
        target.mkdir(parents=True, exist_ok=True)
        env[name] = str(target)
    env["GODOT"] = str(args.godot.resolve())
    command = ["C:/Program Files/Git/bin/bash.exe", "tools/run_tests.sh", "hint_player"]
    metadata = {"revision": revision, "game_tree": git(root, "rev-parse", revision + ":game").decode().strip(), "script_sha256": sha(Path(__file__).resolve()), "collector_sha256": sha(collector), "scratch_root": str(folder), "copied_cache": ["imported/", *selected], "source_cache_state": api["cache_state"](root), "before_cache": api["cache_state"](folder), "source_files": len(inputs), "local_metadata_overlays": len(overlaid), "cache_input_manifest_sha256": sha(output / "cache_input_manifest.json"), "cache_input_files": len(cache_manifest), "scope": "Copied warm import cache, not a cold OS cache. Current generated sidecars are used for control; only tracked sidecars are then restored through Git checkout filters. No source checkout file is written.", "runs": []}
    dump(output / "state.json", metadata)
    metadata["runs"].append(api["invoke"](output, "warm_control_runner", command, folder / "game", env, args.timeout))
    control = metadata["runs"][0]
    clean_control = control["effective_exit_code"] == 0 and not control["script_error_lines"] and not control["generic_error_count"] and control["suite_summary"] == ["1/1 suites passed"]
    metadata["comparison_valid"] = clean_control
    dump(output / "state.json", metadata)
    if not clean_control:
        raise RuntimeError("Warm control was not clean; retain scratch and do not attribute changes to metadata restoration")
    # Before-hashes below are post-control generated metadata.
    changed = []
    for row in inputs:
        if row["path"].endswith(".import"):
            target = folder / row["path"]
            before = target.read_bytes()
            tracked = git(root, "cat-file", "--filters", revision + ":" + row["path"])
            if before != tracked:
                changed.append({"path": row["path"], "before_sha256": hashlib.sha256(before).hexdigest(), "restored_sha256": hashlib.sha256(tracked).hexdigest(), "normalized_text_changed": before.replace(b"\r\n", b"\n") != tracked.replace(b"\r\n", b"\n")})
            target.write_bytes(tracked)
    dump(output / "restored_sidecars.json", changed)
    metadata["restored_sidecars"] = len(changed)
    metadata["non_crlf_text_changes"] = sum(row["normalized_text_changed"] for row in changed)
    metadata["cache_before_restored_import"] = api["cache_state"](folder)
    dump(output / "state.json", metadata)
    metadata["runs"].append(api["invoke"](output, "restored_sidecars_runner", command, folder / "game", env, args.timeout))
    dump(output / "state.json", metadata)
    metadata["runs"].append(api["invoke"](output, "unchanged_retry_runner", command, folder / "game", env, args.timeout))
    metadata["collection_complete"] = True
    metadata["crash_reproduced"] = any(row["native_crash_signature"] for row in metadata["runs"])
    metadata["all_runs_successful"] = all(row["effective_exit_code"] == 0 and not row["script_error_lines"] and not row["generic_error_count"] for row in metadata["runs"])
    dump(output / "state.json", metadata)
    print(json.dumps({key: metadata[key] for key in ["collection_complete", "crash_reproduced", "all_runs_successful", "non_crlf_text_changes"]}), flush=True)
    if metadata["all_runs_successful"]:
        target = folder.resolve()
        if target.parent != scratch or not target.name.startswith("lla-m185-sidecar-"):
            raise RuntimeError("Refusing unsafe scratch cleanup")
        shutil.rmtree(target)


if __name__ == "__main__":
    main()
