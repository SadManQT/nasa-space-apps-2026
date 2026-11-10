"""Sequential native campaign evidence; run only after mandatory regression completes."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import time

root = Path(__file__).resolve().parents[4]
completed = json.loads((root / "production/qa/evidence/M1-122/regression_post_sync/run.json").read_text(encoding="utf-8"))
assert any(row["name"] == "full" for row in completed["runs"]), "Full runner is still active"
continuation = root / "production/qa/evidence/M1-122/regression_post_sync/continuation/state.json"
assert continuation.exists() and json.loads(continuation.read_text(encoding="utf-8"))["complete"], "Continuation diagnostics are still active"
assert subprocess.check_output(["git", "rev-parse", "HEAD:game"], cwd=root, text=True).strip() == completed["game_tree"], "Capture source differs from the completed full gate"
engine = "D:/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
profile = root / ".codex/task-tmp/garden-native-post-sync"
profile.mkdir(parents=True, exist_ok=False)
env = os.environ.copy()
for key, suffix in [("APPDATA", "roaming"), ("LOCALAPPDATA", "local"), ("TEMP", "tmp"), ("TMP", "tmp"), ("TMPDIR", "tmp")]:
    folder = profile / suffix
    folder.mkdir(exist_ok=True)
    env[key] = folder.as_posix()
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
source = ["game/resources/campaign/rooms/LOC-03.json", "game/tools/test_garden_collision.gd", "game/tools/test_garden_movement.gd", "game/scripts/player/player_controller.gd", "game/scripts/campaign/chapter1_campaign.gd", "game/project.godot", "game/assets/environment/kit/textures/T_Kit_Steel_Normal.png.import"]
fixed_room = (root / "game/resources/campaign/rooms/LOC-03.json").read_bytes()
base_revision = subprocess.check_output(["git", "rev-parse", "7f5bbb33"], cwd=root, text=True).strip()
try:
    for task, test, count, expected, baseline in [("M1-122", "garden_collision", 20, 1, True), ("M1-122", "garden_collision", 20, 1, False), ("M1-123", "garden_movement", 62, 8, False)]:
        output = root / "production/qa/evidence" / task / ("before_native_post_sync" if baseline else "native_post_sync")
        if baseline:
            (root / "game/resources/campaign/rooms/LOC-03.json").write_bytes(subprocess.check_output(["git", "show", base_revision + ":game/resources/campaign/rooms/LOC-03.json"], cwd=root))
        if not baseline:
            (root / "game/resources/campaign/rooms/LOC-03.json").write_bytes(fixed_room)
        output.mkdir(exist_ok=False)
        env["TEST_LOG_DIR"] = str(output)
        command = [engine, "--path", str(root / "game"), "--rendering-method", "gl_compatibility", "--fixed-fps", "60", "--script", "res://tools/test_" + test + ".gd", "--", "--capture"]
        start = time.time()
        mono = time.monotonic()
        metadata = {"source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(), "game_tree": subprocess.check_output(["git", "rev-parse", "HEAD:game"], cwd=root, text=True).strip(), "command": command, "start_utc_epoch": start, "source_sha256": {name: sha(root / name) for name in source}, "local_game_diff": subprocess.check_output(["git", "diff", "--", "game"], cwd=root, text=True)}
        with (output / "capture.txt").open("wb") as stream:
            process = subprocess.Popen(command, cwd=root, env=env, stdout=stream, stderr=subprocess.STDOUT)
            try:
                rc = process.wait(timeout=180)
                timed_out = False
            except subprocess.TimeoutExpired:
                subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], capture_output=True, timeout=10)
                process.wait(timeout=10)
                rc = 124
                timed_out = True
        end = time.time()
        after_hashes = {name: sha(root / name) for name in source}
        raw = (output / "capture.txt").read_text(encoding="utf-8", errors="replace")
        text = re.sub(r"\x1b\[[0-9;]*m", "", raw)
        markers = re.findall(r"GARDEN (?:COLLISION|MOVEMENT) RESULT:.*", text)
        captures = [{"file": path.name, "sha256": sha(path), "mtime_epoch": path.stat().st_mtime} for path in sorted(output.glob("*.png"))]
        expected_failures = 3 if baseline else 0
        expected_marker = ("FAIL" if baseline else "PASS") + " (" + str(count) + " checks, " + str(expected_failures) + " failures)"
        passed = rc == (1 if baseline else 0) and not re.search(r"SCRIPT ERROR|^ERROR:", text, re.M) and any(expected_marker in line for line in markers) and len(captures) == expected and all(start <= row["mtime_epoch"] <= end for row in captures) and after_hashes == metadata["source_sha256"]
        metadata.update(end_utc_epoch=end, source_sha256_after=after_hashes, source_inputs_unchanged=after_hashes == metadata["source_sha256"], baseline_original_geometry=baseline, baseline_revision=base_revision if baseline else None, expected_failures=expected_failures, exit_code=rc, timed_out=timed_out, duration_seconds=round(time.monotonic() - mono, 3), markers=markers, captures=captures, capture_checks_passed=passed, warning_count=text.count("WARNING:"))
        (output / "run.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
        print(task, rc, markers, "PNGs", len(captures), "verified", passed, flush=True)
        if not passed:
            raise SystemExit(1)
finally:
    (root / "game/resources/campaign/rooms/LOC-03.json").write_bytes(fixed_room)
