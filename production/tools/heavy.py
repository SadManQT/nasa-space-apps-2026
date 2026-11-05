"""Run a heavy command (Godot, Blender render, ffmpeg encode) only when fewer than two run on this Mac.

    python3 production/tools/heavy.py blender -b scene.blend -a
    production/tools/godot_gated --headless --path game ...      (night-shift workers get this as $GODOT)

Waits for one of two lock files in <main checkout>/.night/ (shared by every night-shift worktree), then replaces
itself with the command (same process id, so callers can still wait for or kill it); the command keeps the lock
until it exits. Twelve parallel renders once froze the Mac and five workers' Godot imports crashed VS Code; two is
the ceiling.
"""
import fcntl, os, subprocess, sys, time
from pathlib import Path

# the main checkout, found from this script's own folder (works from worktrees and from any working directory)
root = Path(subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"], cwd=Path(__file__).resolve().parent,
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
os.set_inheritable(held.fileno(), True)  # the lock stays with the command after exec
try:
    os.execvp(sys.argv[1], sys.argv[1:])
except OSError as e:
    sys.exit(f"heavy.py: cannot run {sys.argv[1]}: {e}")
