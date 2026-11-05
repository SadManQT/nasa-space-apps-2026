"""Run a heavy command (Blender render, ffmpeg encode, windowed Godot capture) when fewer than two run on this Mac.

    python3 production/tools/heavy.py blender -b scene.blend -a

Waits for one of two lock files in <repo>/.night/ (shared by every night-shift worktree), runs the command, and
exits with its exit code. Twelve parallel renders once froze the Mac; two is the agreed ceiling.
"""
import fcntl, subprocess, sys, time
from pathlib import Path

# the main checkout, also when run from a worktree under .night/
root = Path(subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
                           capture_output=True, text=True, check=True).stdout.strip()).parent
locks = [root / ".night" / f"heavy{i}.lock" for i in range(2)]
held = None
while held is None:
    for p in locks:
        f = open(p, "a" if not p.exists() else "r")  # read-only if it exists: sandboxed workers cannot write there
        try:
            fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
            held = f
            break
        except BlockingIOError:
            f.close()
    else:
        time.sleep(1)
sys.exit(subprocess.run(sys.argv[1:]).returncode)
