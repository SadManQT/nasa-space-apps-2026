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
                         land=lambda *a: (True, "")):
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

print("night_shift self-check: PASS")
