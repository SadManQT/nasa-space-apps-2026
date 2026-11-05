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
ns.asleep["fable"] = time.time() + 3600  # Fable is at its limit
with mock.patch.multiple(ns, run_agent=first_call, log=lambda m: None, resume_parked=lambda s, t: "", changes=lambda s: "",
                         worker_prompt=lambda *a: "", task_info=lambda s, t: {"priority": "P1", "title": "Assemble the Chapter 1 rooms from the kit", "status": "todo"}):
    ns.do_task(Path("/nowhere"), "M1-06", "codex")
    assert calls[0] == ("claude2", "xhigh"), calls  # Fable's work continues on Opus 5.5 at extra-high effort

print("night_shift self-check: PASS")
