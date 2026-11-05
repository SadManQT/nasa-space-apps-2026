#!/usr/bin/env python3
"""Night shift: work the team board unattended, with an independent review before anything lands on main.

    caffeinate -dimsu python3 production/tools/night_shift.py            # runs until the board is empty or STOP
    SLOTS=1 HOURS=10 python3 production/tools/night_shift.py
    touch production/session-logs/STOP_NIGHT                              # stop after the current tasks

Each slot is a git worktree under .night/ (game assets only, via LFS include). Per task:
  1. a worker on the lane's best free account does exactly that board task (GO_NEXT "go next"), never commits;
  2. the script runs game/tools/run_tests.sh itself;
  3. a reviewer on a different engine checks the diff against the task's acceptance criteria (PASS / FIX);
  4. up to two fix rounds; PASS + green tests -> commit as sadmanqt and push to main;
     otherwise the work goes to branch night/<task> and the task is blocked with the reason, for the morning.
Usage limits: the account sleeps until the reset time it printed; the lane's next account takes over.
Accounts come from GoCode's saved profiles through ~/.local/bin/gocode-run (approved by Sadman, 5 Nov 2026).
Log: production/session-logs/night_shift.log (local). Morning summary: production/session-logs/night_summary.md.
"""
import collections, datetime as dt, fcntl, json, os, re, subprocess, sys, threading, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NIGHT = ROOT / ".night"
LOGDIR = ROOT / "production/session-logs"
GODOT = "/Applications/Godot.app/Contents/MacOS/Godot"
GOCODE_RUN = str(Path.home() / ".local/bin/gocode-run")
AGY_SETTINGS = str(Path.home() / ".local/share/night_shift/agy_settings.json")
SLOTS = int(os.environ.get("SLOTS", "2"))
LANES_ONLY = [l for l in os.environ.get("LANES_ONLY", "").split(",") if l]  # e.g. antigravity,gemini,any
SLOT_PREFIX = os.environ.get("SLOT_PREFIX", "slot")
SUMMARY = os.environ.get("SUMMARY", "night_summary.md")
PREFER = os.environ.get("PREFER", "")  # account tried first in every lane, e.g. buet for a Gemini-first shift
STOP = LOGDIR / ("STOP_NIGHT" if SLOT_PREFIX == "slot" else f"STOP_NIGHT_{SLOT_PREFIX}")
CLAIMS = NIGHT / "claims"  # one directory per task: an atomic lock shared by every running night shift
DEADLINE = time.time() + float(os.environ.get("HOURS", "12")) * 3600
WORKER_TIMEOUT = 4 * 3600
GIT_ID = ["-c", "user.name=sadmanqt", "-c", "user.email=2405167@ugrad.cse.buet.ac.bd"]

# account -> how to run a prompt (prompt file path substituted for {p}); review runs read-only
ACCOUNTS = {
    "codex":       {"engine": "codex",  "cmd": [GOCODE_RUN, "codex", "{p}", "gpt-6.1-sol"]},
    "codex-main":  {"engine": "codex",  "cmd": ["sh", "-c", 'codex exec -s workspace-write -m gpt-6.1-sol -c model_reasoning_effort="$EFFORT" < "$0"', "{p}"]},
    "claude2":     {"engine": "claude", "cmd": [GOCODE_RUN, "claude2", "{p}", "claude-opus-5-5"]},
    "fable":       {"engine": "claude", "cmd": [GOCODE_RUN, "claude2", "{p}", "claude-fable-5-1"]},
    # second Claude subscription (lamppost); Opus only: Fable there needs paid usage credits
    "claude3":     {"engine": "claude", "cmd": [GOCODE_RUN, "claude3", "{p}", "claude-opus-5-5"]},
    "buet":        {"engine": "gemini", "cmd": [GOCODE_RUN, "buet", "{p}", "gemini-4-argon-high"]},
}
LANES = {  # board lane -> accounts in order of preference (Sadman, 5 Nov: Claude takes most work, Fable first)
    "codex": ["codex", "codex-main", "fable", "claude3"],
    "claude": ["fable", "claude2", "claude3"],
    "antigravity": ["buet", "fable", "claude3"],
    "gemini": ["buet", "fable", "claude3"],
    "muse": ["fable", "claude2", "claude3"],
    "any": ["fable", "claude3", "claude2", "codex", "buet"],
}
REVIEWER = {"codex": ["claude3", "claude2", "buet"], "claude": ["codex", "codex-main", "buet", "claude3"], "gemini": ["codex", "claude3", "claude2"]}
# Fable 5.1 leads the photoreal environment, 3D assets and room builds (5 Nov decision)
FABLE_HINTS = re.compile(r"habitat kit|environment|main scene|terrain|exterior|interior|photoreal|LOLA|\b3D\b|Blender|\bassets\b|rooms and locations|M1-03|M1-05|M1-06", re.I)

asleep: dict[str, float] = {}       # account -> epoch when usable again
taken: set[str] = set()             # task ids picked this run
results: list[dict] = []
lock = threading.Lock()


def log(msg):
    line = f"{dt.datetime.now():%Y-%m-%d %H:%M:%S} {msg}"
    print(line, flush=True)
    with lock, open(LOGDIR / "night_shift.log", "a") as f:
        f.write(line + "\n")


def sh(args, cwd, timeout=None, env=None, check=False):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout, env=env)
    if check and p.returncode:
        raise RuntimeError(f"{' '.join(args[:4])}: {p.stderr[-800:]}")
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def limit_wait(out: str) -> float:
    """Seconds until the account's reset, 0 if the output shows no usage limit."""
    if not re.search(r"usage limit|hit your .{0,20}limit|quota (reached|exceeded)|rate.?limit|RESOURCE_EXHAUSTED", out, re.I):
        return 0
    m = re.search(r"[Rr]esets in (\d+)h(\d+)m", out)
    if m:
        return int(m[1]) * 3600 + int(m[2]) * 60 + 120
    m = re.search(r"(?:resets|try again at)\s+(\d{1,2})(?::(\d{2}))?\s*([ap])\.?m", out, re.I)
    if not m:
        return 1800
    h = int(m[1]) % 12 + (12 if m[3].lower() == "p" else 0)
    now = dt.datetime.now()
    t = now.replace(hour=h, minute=int(m[2] or 0), second=0, microsecond=0)
    if t <= now:
        t += dt.timedelta(days=1)
    return (t - now).total_seconds() + 120


def free(accounts):
    now = time.time()
    return [a for a in accounts if asleep.get(a, 0) <= now]


def run_agent(account, prompt, cwd, effort="high"):
    """Run a prompt on an account. Returns (ok, output); puts the account to sleep on a usage limit."""
    pf = Path(cwd) / ".night_prompt.md"
    pf.write_text(prompt)
    cmd = [c.replace("{p}", str(pf)) for c in ACCOUNTS[account]["cmd"]]
    env = {**os.environ, "EFFORT": effort, "AGY_SETTINGS": AGY_SETTINGS, "GODOT": GODOT}
    env.pop("CLAUDECODE", None)
    try:
        _, out = sh(cmd, cwd, timeout=WORKER_TIMEOUT, env=env)
    except subprocess.TimeoutExpired:
        return False, "worker timed out"
    finally:
        pf.unlink(missing_ok=True)
    tr = LOGDIR / "transcripts"
    tr.mkdir(exist_ok=True)
    (tr / f"{time.strftime('%m%d_%H%M%S')}_{Path(cwd).name}_{account}.txt").write_text(out[-30000:])
    wait = limit_wait(out[-3000:])
    if wait:
        asleep[account] = time.time() + wait
        log(f"{account} hit a usage limit; sleeping {wait / 3600:.1f} h")
        return False, out
    return True, out


def task_info(slot, tid):
    data = json.loads((slot / "production/plan/tasks.json").read_text())
    return next(t for t in data["tasks"] if t["id"] == tid)


def prepare(slot: Path):
    """Fresh detached checkout of origin/main with game assets; keeps the .godot import cache."""
    env = {**os.environ, "GIT_LFS_SKIP_SMUDGE": "1"}
    sh(["git", "fetch", "-q", "origin"], ROOT, check=True)
    if not slot.exists():
        sh(["git", "worktree", "add", "--detach", str(slot), "origin/main"], ROOT, env=env, check=True)
    else:
        sh(["git", "reset", "-q", "--hard"], slot)
        sh(["git", "clean", "-fdq", "-e", "game/.godot"], slot)
        sh(["git", "rebase", "--abort"], slot)
        sh(["git", "checkout", "-q", "--detach", "origin/main"], slot, env=env, check=True)
    sh(["git", "lfs", "pull", "--include", "game/**"], slot, check=True)


def worker_prompt(tid, slot, by, fix=""):
    p = f"""You are working unattended overnight for Sadman on Last Light Academy. Your checkout is {slot} (a git worktree of the
project's repository; work only here). Do board task {tid} — exactly this one task — at senior, AAA production quality.
1. Claim it: python3 production/plan/board.py claim {tid} --by "{by}"  (do not commit or push: the night-shift script commits after review).
2. Read AGENTS.md, production/plan/GO_NEXT.md, `python3 production/plan/board.py show {tid}`, every read-first file, and the
   PRODUCTION_HANDBOOK.md sections you need (§3 locked decisions are binding, e.g. 5 Nov: photoreal environment, cel-shaded cast).
   Canon: story text word for word, numbers from game-design/08_PUZZLE_DESIGNS.md, every scene connected to the next as listed
   in game-design/24_NARRATIVE_REVISION.md §2.9 (build the joins your task touches), English only (no Bangla script), no NASA logos,
   plants have no faces, Moon science rules in production/ART_BIBLE.md §2, scientifically accurate missions.
3. If the task needs something you cannot do unattended (Sadman's approval of canon or of 2D concept sheets, buying anything,
   spending credits the task says need approval, a human action), do not fake it: python3 production/plan/board.py block {tid}
   --reason "<what is needed and who can unblock it>" and stop.
4. Do the work. Reuse existing services; gameplay values in data files; doc comments on public functions; at most one
   Godot/ffmpeg/Blender process at a time, and run every Blender render, ffmpeg encode or windowed Godot capture as
   `python3 production/tools/heavy.py <command...>` (it waits so that no more than two run on this Mac); never a bare
   Godot exit code as a test result.
5. Verify: GODOT={GODOT} game/tools/run_tests.sh must print "N/N suites passed". Anything a player sees needs screenshots in
   production/qa/evidence/{tid}_*.png (run the game windowed or a scripted capture with the window on top).
6. Record: one row in production/AI_PROMPT_LOG.md (tool = your engine and model, "night shift"), a dated line in
   PRODUCTION_HANDBOOK.md §10 if project status changed, then python3 production/plan/board.py done {tid} --evidence "<proof>".
7. Never run git commit, push, reset, checkout, rebase, stash or clean.
8. If your sandbox cannot open a window (windowed Godot exits 134/SIGABRT in _RegisterApplication), do NOT block the task
   for screenshots or windowed measurements: write production/qa/evidence/{tid}_capture.sh — a bash script that produces
   every needed screenshot/probe output into production/qa/evidence/ ({GODOT} --path game ...) — and say so; the night-shift
   script runs it outside the sandbox before testing and review. Only block for things a script cannot do.
9. game/tools/test_performance_runtime.gd has wall-clock checks that can fail when the machine is busy; rerun before
   concluding a timing failure is real.
Finish with: what changed, the last line of run_tests.sh, evidence files, anything Sadman must check."""
    if fix:
        p += f"\n\nTHIS IS A FIX ROUND for work already in this checkout (see `git status` and `git diff`). Fix exactly these problems, re-verify, keep the task's board entry correct:\n{fix}"
    return p


def review_prompt(tid, slot):
    return f"""You are an independent senior reviewer. In {slot}, review the uncommitted work for board task {tid}
(`git status`, `git diff`, new files; the task: `python3 production/plan/board.py show {tid}`; rules: AGENTS.md and
PRODUCTION_HANDBOOK.md §3). Do not modify any file. Check: every acceptance point is really met (not claimed), correctness,
canon (story text, 08 numbers, English only, no NASA logos, plants without faces), the scene joins in
game-design/24_NARRATIVE_REVISION.md §2.9 that the task touches (no scene left disconnected), Moon/biology science accuracy,
code quality and tests that would catch regressions, evidence files exist, AI_PROMPT_LOG row and board entry are honest.
Reply with exactly one line "VERDICT: PASS" or "VERDICT: FIX", then for FIX a numbered list of concrete defects with file:line."""


def tests_pass(slot):
    """Full suite, one run at a time across every night shift (timing checks hate load); one retry for flakes."""
    CLAIMS.mkdir(parents=True, exist_ok=True)
    out = ""
    for attempt in range(2):
        with open(NIGHT / "tests.lock", "w") as lk:
            fcntl.flock(lk, fcntl.LOCK_EX)
            try:
                _, out = sh(["game/tools/run_tests.sh"], slot, timeout=3600, env={**os.environ, "GODOT": GODOT})
            except subprocess.TimeoutExpired:
                out = "run_tests.sh timed out"
        last = [l for l in out.splitlines() if "suites passed" in l]
        if last and re.search(r"(\d+)/\1 suites passed", last[-1]):
            return True, "\n".join(out.splitlines()[-25:])
    return False, "\n".join(out.splitlines()[-25:])


def run_capture(slot, tid):
    """Run the worker's capture script outside the sandbox (screenshots, windowed probes)."""
    cap = slot / f"production/qa/evidence/{tid}_capture.sh"
    if cap.exists():
        log(f"[{slot.name}] running {cap.name} outside the sandbox")
        try:
            _, out = sh(["bash", str(cap)], slot, timeout=2400, env={**os.environ, "GODOT": GODOT})
        except subprocess.TimeoutExpired:
            out = "capture script timed out"
        (slot / f"production/qa/evidence/{tid}_capture_output.txt").write_text(out[-20000:])


MERGE_TASKS = """
import json, subprocess, sys
tid = sys.argv[1]
up = json.loads(subprocess.check_output(["git", "show", ":2:production/plan/tasks.json"]))
mine = json.loads(subprocess.check_output(["git", "show", ":3:production/plan/tasks.json"]))
ids = {t["id"]: i for i, t in enumerate(up["tasks"])}
for t in mine["tasks"]:  # this task's update and tasks the worker added; everyone else's state stays upstream's
    if t["id"] == tid and t["id"] in ids:
        up["tasks"][ids[t["id"]]] = t
    elif t["id"] not in ids:
        up["tasks"].append(t)
open("production/plan/tasks.json", "w").write(json.dumps(up, indent=1, ensure_ascii=False) + "\\n")
"""


def resolve_conflicts(slot, tid):
    """GO_NEXT rule for board conflicts: keep everyone's board state plus this task's; union-merge append-only docs."""
    _, out = sh(["git", "diff", "--name-only", "--diff-filter=U"], slot)
    for f in out.split():
        if f == "production/plan/BOARD.html":
            continue
        if f == "production/plan/tasks.json":
            rc, err = sh(["python3", "-c", MERGE_TASKS, tid], slot)
        elif f.endswith(".md"):
            _, base = sh(["git", "show", f":1:{f}"], slot)
            _, ours = sh(["git", "show", f":2:{f}"], slot)
            _, theirs = sh(["git", "show", f":3:{f}"], slot)
            tmp = slot / ".night_merge"
            tmp.mkdir(exist_ok=True)
            for name, text in (("base", base), ("ours", ours), ("theirs", theirs)):
                (tmp / name).write_text(text)
            sh(["git", "merge-file", "--union", str(tmp / "ours"), str(tmp / "base"), str(tmp / "theirs")], slot)
            (slot / f).write_text((tmp / "ours").read_text())
            rc = 0
        else:
            return False  # a real content conflict: leave it for a human
        if rc:
            return False
    sh(["python3", "production/plan/board.py", "html"], slot)
    sh(["git", "add", "-A", "--", "production/plan", *[f for f in out.split()]], slot)
    rc, _ = sh(["git", "-c", "core.editor=true", "rebase", "--continue"], slot, env={**os.environ, "GIT_EDITOR": "true"})
    return rc == 0


def land(slot, tid, title, status):
    """Commit the slot's changes and push them to main (rebase first)."""
    sh(["git", "checkout", "-q", "-B", f"night/{slot.name}"], slot)
    sh(["git", "add", "-A"], slot)
    kind = "chore(board)" if status == "blocked" else "feat"
    msg = f"{kind}: {title}" if status != "blocked" else f"chore(board): block {tid}"
    rc, out = sh(["git", *GIT_ID, "commit", "-q", "-m", msg, "-m", f"Task: {tid} (night shift: tests passed and independent review PASS)" if status == "done" else f"Task: {tid}"], slot)
    if rc:
        return False, out
    for _ in range(3):
        rc, out = sh(["git", "pull", "-q", "--rebase", "origin", "main"], slot)
        if rc and not resolve_conflicts(slot, tid):
            sh(["git", "rebase", "--abort"], slot)
            return False, "rebase conflict: " + out[-500:]
        rc, out = sh(["git", "push", "-q", "origin", "HEAD:main"], slot)
        if not rc:
            return True, ""
    return False, out


def park(slot, tid, reason):
    """Keep unfinished work on a branch for the morning and block the task on main."""
    br = f"night/{tid}"
    sh(["git", "checkout", "-q", "-B", br], slot)
    sh(["git", "add", "-A"], slot)
    sh(["git", *GIT_ID, "commit", "-q", "-m", f"wip: {tid} (night shift, not landed)", "-m", reason[:1500]], slot)
    sh(["git", "push", "-q", "-f", "origin", br], slot)
    prepare(slot)
    sh(["python3", "production/plan/board.py", "block", tid, "--reason", f"Night shift parked the work on branch {br}: {reason[:400]}"], slot)
    land(slot, tid, "", "blocked")


def overlaps(slot, tid):
    """True if tid owns a path that a task running in any night shift also owns (they would conflict on landing)."""
    # ponytail: check-then-mkdir across processes can race; the loser parks on a landing conflict
    data = {t["id"]: t for t in json.loads((slot / "production/plan/tasks.json").read_text())["tasks"]}
    mine = data[tid].get("paths", [])
    for other in os.listdir(CLAIMS):
        theirs = data.get(other, {}).get("paths", [])
        if any(a.startswith(b) or b.startswith(a) for a in mine for b in theirs):
            return True
    return False


def waiting_on(tasks):
    """For each task, how many unfinished tasks wait on it, directly or through other tasks."""
    deps = {t["id"]: t.get("deps", []) for t in tasks}
    count = collections.Counter()
    for t in tasks:
        if t["status"] == "done":
            continue
        seen, todo = set(), list(deps[t["id"]])
        while todo:
            d = todo.pop()
            if d not in seen:
                seen.add(d)
                todo += deps.get(d, [])
        count.update(seen)
    return count


def pick(slot):
    """The ready task that unblocks the most other work (lane order breaks ties), locked for this slot."""
    cands = []
    for lane, accounts in LANES.items():
        if LANES_ONLY and lane not in LANES_ONLY:
            continue
        if not free(accounts):
            continue
        _, out = sh(["python3", "production/plan/board.py", "next", "--tool", lane, "--all"], slot)
        cands += [(m[1], lane) for m in (re.match(r"^(M\d-[\w-]+)\s+\[", ln) for ln in out.splitlines()) if m]
    waits = waiting_on(json.loads((slot / "production/plan/tasks.json").read_text())["tasks"])
    for tid, lane in sorted(cands, key=lambda c: -waits[c[0]]):
        with lock:
            if tid in taken or overlaps(slot, tid):
                continue
            try:
                (CLAIMS / tid).mkdir(parents=True)
            except FileExistsError:  # another night shift has it
                continue
            taken.add(tid)
        return tid, lane
    return None, None


def resume_parked(slot, tid):
    """Bring back work parked on night/<tid> (main's board files kept). Returns a note for the worker, or ''."""
    br = f"origin/night/{tid}"
    if sh(["git", "rev-parse", "-q", "--verify", br], slot)[0]:
        return ""
    sh(["git", "merge", "--squash", br], slot)
    sh(["git", "checkout", "HEAD", "--", "production/plan/tasks.json", "production/plan/BOARD.html"], slot)
    if sh(["git", "diff", "--name-only", "--diff-filter=U"], slot)[1].strip():
        prepare(slot)
        return f"An earlier attempt is parked on {br} but no longer merges cleanly: read `git diff origin/main...{br}` and port what is still right."
    sh(["git", "reset", "-q"], slot)
    if not sh(["git", "status", "--porcelain"], slot)[1].strip():
        return ""  # the parked branch held only a board claim
    return f"This checkout already holds the earlier attempt parked on {br} (uncommitted). Check it, finish the task and fix what stopped it:"


def changes(slot):
    """Fingerprint of the work in the checkout, board files excluded."""
    return sh(["git", "status", "--porcelain", "-uall", "--", ".", ":!production/plan"], slot)[1] + sh(["git", "diff", "--", ".", ":!production/plan"], slot)[1]


def do_task(slot, tid, lane):
    info = task_info(slot, tid)
    effort = "xhigh" if info.get("priority") == "P0" else "high"
    accounts = LANES[lane][:]
    if PREFER in ACCOUNTS:
        accounts = [PREFER] + [a for a in accounts if a != PREFER]
    if FABLE_HINTS.search(f"{tid} {info.get('title', '')}"):
        accounts.insert(0, "fable")
    fix, worker = resume_parked(slot, tid), None
    if fix:
        fix += "\n" + str(info.get("blocker", ""))[:1500]
        log(f"[{slot.name}] {tid} resumes the parked work on night/{tid}")
    for round_ in range(3):  # first pass + two fix rounds
        cands = free(accounts)
        if not cands:
            return "deferred", "all accounts for this lane are at their usage limit"
        worker = cands[0]
        log(f"[{slot.name}] {tid} round {round_ + 1} on {worker} (effort {effort})")
        before = changes(slot)
        eff = "xhigh" if ACCOUNTS[worker]["engine"] == "codex" else effort  # Codex always extra-high (Sadman, 5 Nov)
        ok, out = run_agent(worker, worker_prompt(tid, slot, f"Sadman/night-{worker}", fix), slot, eff)
        if not ok and limit_wait(out[-3000:]):
            continue  # same round again on the lane's next account
        status = task_info(slot, tid).get("status")
        if status not in ("done", "blocked") and changes(slot) == before:
            # ponytail: a silent quota/permission failure looks like this; 2 h rest, no smarter diagnosis
            asleep[worker] = time.time() + 7200
            log(f"[{slot.name}] {worker} changed nothing on {tid}; resting it 2 h")
            continue
        if status == "blocked":
            t = task_info(slot, tid)
            return "blocked", t.get("blocker") or t.get("note") or "blocked by the worker"
        run_capture(slot, tid)
        green, tail = tests_pass(slot)
        if not green:
            fix = f"run_tests.sh is not green:\n{tail}"
            continue
        if status != "done":
            fix = "The task is not marked done on the board: finish it (or block it with a real reason)."
            continue
        engine = ACCOUNTS[worker]["engine"]
        reviewers = free(REVIEWER[engine])
        if not reviewers:
            return "deferred", "no reviewer account available"
        _, verdict = run_agent(reviewers[0], review_prompt(tid, slot), slot, "high")
        if re.search(r"VERDICT:\s*PASS", verdict):
            return "done", f"worker {worker}, reviewer {reviewers[0]}"
        fix = verdict[-4000:]
    return "failed", fix[-1500:]


def slot_loop(n):
    slot = NIGHT / f"{SLOT_PREFIX}{n}"
    while time.time() < DEADLINE and not STOP.exists():
        try:
            prepare(slot)  # noqa: one fresh checkout per task
            tid, lane = pick(slot)
            if not tid:
                wake = min(asleep.values(), default=0)
                if wake > time.time():
                    log(f"[{SLOT_PREFIX}{n}] every lane with ready work is limited; sleeping {(wake - time.time()) / 60:.0f} min")
                    time.sleep(min(wake - time.time() + 5, 3600))
                    continue
                log(f"[{SLOT_PREFIX}{n}] nothing ready on the board; slot stops")
                return
            title = task_info(slot, tid).get("title", tid)
            outcome, note = do_task(slot, tid, lane)
            if outcome == "blocked":  # keep any partial work off main; land only the block and its reason
                park(slot, tid, note)
            elif outcome == "done":
                ok, err = land(slot, tid, title, outcome)
                if not ok:
                    outcome, note = "failed", f"could not land: {err}"
                    park(slot, tid, note)
            elif outcome == "failed":
                park(slot, tid, note)
            with lock:  # the claim is only a run-time lock; the board status stops a retry
                taken.discard(tid)
                (CLAIMS / tid).rmdir()
            if outcome == "deferred":
                time.sleep(300)
            log(f"[{SLOT_PREFIX}{n}] {tid} -> {outcome}: {note[:300]}")
            with lock:
                results.append({"task": tid, "title": title, "outcome": outcome, "note": note[:600], "at": f"{dt.datetime.now():%H:%M}"})
                write_summary()
        except Exception as e:  # keep the night going; the next loop starts from a fresh checkout
            log(f"[{SLOT_PREFIX}{n}] error: {e}")
            time.sleep(120)


def write_summary():
    rows = "\n".join(f"| {r['at']} | {r['task']} | {r['outcome']} | {r['title']} | {r['note'].replace('|', '/').replace(chr(10), ' ')[:200]} |" for r in results)
    (LOGDIR / SUMMARY).write_text(
        "# Night shift summary\n\nLanded on main = done (tests green + independent review PASS). Parked work is on branches night/<task>.\n\n"
        "| Time | Task | Outcome | Title | Note |\n|---|---|---|---|---|\n" + rows + "\n")


if __name__ == "__main__":
    LOGDIR.mkdir(parents=True, exist_ok=True)
    NIGHT.mkdir(exist_ok=True)
    for i in range(2):  # heavy.py's slots; created here because sandboxed workers cannot create files outside their checkout
        (NIGHT / f"heavy{i}.lock").touch()
    STOP.unlink(missing_ok=True)
    pidfile = NIGHT / f"{SLOT_PREFIX}.pid"
    pidfile.write_text(str(os.getpid()))
    log(f"night shift starts: {SLOTS} {SLOT_PREFIX} slot(s), lanes {LANES_ONLY or 'all'}, until {dt.datetime.fromtimestamp(DEADLINE):%H:%M}")
    threads = [threading.Thread(target=slot_loop, args=(i + 1,), daemon=True) for i in range(SLOTS)]
    for i, t in enumerate(threads):
        t.start()
        time.sleep(60 * i)  # stagger the first checkouts
    for t in threads:
        t.join()
    pidfile.unlink(missing_ok=True)
    log("night shift ends")
