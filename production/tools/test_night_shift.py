#!/usr/bin/env python3
"""Self-check for night_shift.py: usage limits defer a task (never block it), and a clean checkout never overwrites parked work.

    python3 production/tools/test_night_shift.py
"""
import sys, time
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).parent))
import night_shift as ns


def limited(account, *_):
    ns.asleep[account] = time.time() + 3600
    return False, "You've hit your usage limit · resets 5pm"


with mock.patch.multiple(ns, run_agent=limited, log=lambda m: None, resume_parked=lambda s, t: "", changes=lambda s: "",
                         worker_prompt=lambda *a: "", task_info=lambda s, t: {"priority": "P1", "title": "x", "status": "todo"}):
    outcome, _ = ns.do_task(Path("/nowhere"), "M9-01", "claude")
    assert outcome == "deferred", outcome  # was "failed" with an empty reason, which blocked the task (5 Nov)

calls = []
with mock.patch.multiple(ns, sh=lambda args, *a, **k: calls.append(args) or (0, ""), changes=lambda s: "", prepare=lambda s: None,
                         land=lambda *a: (True, ""), task_info=lambda s, t: {"status": "in_progress"}):
    ns.park(Path("/nowhere"), "M9-01", "limit", block=False)
    assert not any("push" in c for c in calls), calls  # a clean checkout force-pushed main over night/M1-19 and night/M3-99
    ns.park(Path("/nowhere"), "M9-01", "failed")
    assert any("block" in c for c in calls), calls

calls = []
def first_call(account, prompt, cwd, effort):
    calls.append((account, effort))
    return limited(account)
ns.asleep.clear()
with mock.patch.multiple(ns, run_agent=first_call, log=lambda m: None, resume_parked=lambda s, t: "", changes=lambda s: "",
                         worker_prompt=lambda *a: "", task_info=lambda s, t: {"priority": "P1", "title": "Assemble the Chapter 1 rooms from the kit", "status": "todo"}):
    ns.do_task(Path("/nowhere"), "M1-06", "codex")
    assert calls[0] == ("claude2", "xhigh"), calls  # 3D work goes to Claude: Opus 5.5 at extra-high effort
assert not any("fable" in accounts for accounts in ns.LANES.values()), ns.LANES  # Opus 5.5 for all tasks (5 Nov 23:40)

# a task claimed by hand in a day session is never picked by the night shift (6 Nov: nslot1 resumed M1-34 while Sadman/claude landed it)
import json as _json, tempfile
with tempfile.TemporaryDirectory() as tmp:
    slot = Path(tmp); (slot / "production/plan").mkdir(parents=True)
    (slot / "production/plan/tasks.json").write_text(_json.dumps({"tasks": [
        {"id": "M9-01", "status": "in_progress", "owner": "Sadman/claude", "deps": [], "paths": []},
        {"id": "M9-02", "status": "todo", "owner": "", "deps": [], "paths": []}]}))
    listing = "M9-01  [M9 P0 claude]  x\nM9-02  [M9 P0 claude]  y\n"
    with mock.patch.multiple(ns, sh=lambda *a, **k: (0, listing), free=lambda a: a, overlaps=lambda s, t: False, CLAIMS=slot / "claims"):
        ns.taken.clear(); (slot / "claims").mkdir()
        assert ns.pick(slot)[0] == "M9-02", "a hand-claimed task must be skipped"

# a task that is already done is never blocked by a late park
calls = []
with mock.patch.multiple(ns, sh=lambda args, *a, **k: calls.append(args) or (0, ""), changes=lambda s: "", prepare=lambda s: None,
                         land=lambda *a: (True, ""), task_info=lambda s, t: {"status": "done"}):
    ns.park(Path("/nowhere"), "M9-03", "failed")
    assert not any("block" in c for c in calls), calls

# a reviewer at its usage limit defers the task; it is not a failed review (6 Nov: three "failed" reviews blocked M1-76)
ns.asleep.clear()
def worker_then_limited_reviewer(account, prompt, cwd, effort):
    return limited(account) if prompt == "review" else (True, "done")
with mock.patch.multiple(ns, run_agent=worker_then_limited_reviewer, log=lambda m: None, resume_parked=lambda s, t: "",
                         changes=lambda s: "", worker_prompt=lambda *a: "work", review_prompt=lambda *a: "review",
                         run_capture=lambda s, t: None, tests_pass=lambda s: (True, ""),
                         task_info=lambda s, t: {"priority": "P1", "title": "x", "status": "done"}):
    outcome, note = ns.do_task(Path("/nowhere"), "M9-04", "codex")
    assert outcome == "deferred", (outcome, note)

# a weekly limit sleeps until the named day, not 30 minutes
import datetime as _dt
wait = ns.limit_wait("You've hit your weekly limit · resets Nov 10 at 5pm (Asia/Dhaka)")
target = _dt.datetime(_dt.datetime.now().year, 11, 10, 17, 0)
if target < _dt.datetime.now() - _dt.timedelta(days=180):
    target = target.replace(year=target.year + 1)
assert abs(wait - max((target - _dt.datetime.now()).total_seconds(), 0) - 120) < 5, wait
assert ns.limit_wait("You've hit your usage limit · resets 5pm") <= 86400 + 120

# a task claimed by a day session is never blocked by a night park (7 Nov: M3-5R)
calls = []
with mock.patch.multiple(ns, sh=lambda args, *a, **k: calls.append(args) or (0, ""), changes=lambda s: "", prepare=lambda s: None,
                         land=lambda *a: (True, ""), task_info=lambda s, t: {"status": "in_progress", "owner": "Sadman/claude"}):
    ns.park(Path("/nowhere"), "M9-05", "day-session claim")
    assert not any("block" in c for c in calls), calls
calls = []
with mock.patch.multiple(ns, sh=lambda args, *a, **k: calls.append(args) or (0, ""), changes=lambda s: "", prepare=lambda s: None,
                         land=lambda *a: (True, ""), task_info=lambda s, t: {"status": "in_progress", "owner": "Sadman/night-claude2"}):
    ns.park(Path("/nowhere"), "M9-06", "failed")
    assert any("block" in c for c in calls), calls  # its own failed night claim still blocks

# Claude only (Sadman, 7 Nov): every lane and every reviewer is a Claude account, and supervisor preferences cannot bring
# back Codex or Gemini
assert all(set(a) <= {"claude2", "claude3"} for a in ns.LANES.values()), ns.LANES
assert all(set(a) <= {"claude2", "claude3"} for a in ns.REVIEWER.values()), ns.REVIEWER
assert all(ns.ACCOUNTS[a]["engine"] == "claude" and "claude-opus-5-5" in ns.ACCOUNTS[a]["cmd"] for a in ns.CLAUDE)

# the reviewer is the other Claude account when it is free
seen = []
ns.asleep.clear()
def record(account, prompt, cwd, effort):
    seen.append((account, prompt))
    return True, "VERDICT: PASS" if prompt == "review" else "done"
with mock.patch.multiple(ns, run_agent=record, log=lambda m: None, resume_parked=lambda s, t: "", changes=lambda s: "",
                         worker_prompt=lambda *a: "work", review_prompt=lambda *a: "review", run_capture=lambda s, t: None,
                         tests_pass=lambda s: (True, ""), task_info=lambda s, t: {"priority": "P1", "title": "x", "status": "done"}):
    outcome, _ = ns.do_task(Path("/nowhere"), "M9-07", "claude")
    assert outcome == "done" and seen[0][0] != seen[-1][0] and seen[-1][1] == "review", seen

# at most MAX_CLAUDE Claude workers hold a seat at once
import fcntl as _fcntl
with tempfile.TemporaryDirectory() as tmp, mock.patch.multiple(ns, NIGHT=Path(tmp), MAX_CLAUDE=1):
    seat = ns.claude_seat()
    probe = open(Path(tmp) / "claude0.lock", "a")
    try:
        _fcntl.flock(probe, _fcntl.LOCK_EX | _fcntl.LOCK_NB)
        raise AssertionError("a second Claude worker got a seat while the only one was taken")
    except BlockingIOError:
        pass
    seat.close()
    _fcntl.flock(probe, _fcntl.LOCK_EX | _fcntl.LOCK_NB)  # free again once the worker exits
    probe.close()

print("night_shift self-check: PASS")
