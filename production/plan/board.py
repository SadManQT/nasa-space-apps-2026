#!/usr/bin/env python3
"""Team task board for Last Light Academy: one JSON source of truth, the "go next" commands
and the HTML view. Standard library only; run from anywhere in the repo.

  python3 production/plan/board.py take --tool codex --count 5 --by "Atik/codex"   # "continue": claim a chunk
  python3 production/plan/board.py mine --by "Atik/codex"     # your claimed tasks, in work order
  python3 production/plan/board.py stale --days 2             # claims nobody has touched for 2+ days
  python3 production/plan/board.py next --tool codex          # the next task for your AI
  python3 production/plan/board.py show T-020                 # one task in full
  python3 production/plan/board.py claim T-020 --by "Atik/codex"
  python3 production/plan/board.py done T-020 --evidence "run_tests.sh 25/25; production/qa/evidence/t020.png"
  python3 production/plan/board.py block T-020 --reason "needs the user's approval of the kit sheet"
  python3 production/plan/board.py release T-020              # give a claimed task back
  python3 production/plan/board.py list [--status todo] [--tool claude] [--milestone M1]
  python3 production/plan/board.py check                      # validate the board and self-test

Every change rewrites tasks.json and BOARD.html; commit and push both at once (see GO_NEXT.md).
"""
import argparse
import datetime
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
TASKS = HERE / "tasks.json"
BOARD = HERE / "BOARD.html"
TEMPLATE = HERE / "board_template.html"
STATUSES = ("todo", "in_progress", "blocked", "done")
TOOLS = ("claude", "codex", "antigravity", "gemini", "muse", "human", "any")
PRIORITY = {"P0": 0, "P1": 1, "P2": 2}


def today():
    return datetime.date.today().isoformat()


def load():
    return json.loads(TASKS.read_text(encoding="utf-8"))


def save(data):
    data.pop("updated", None)  # a board-wide stamp would make every concurrent save conflict in git
    problems = validate(data)
    if problems:
        sys.exit("board not saved:\n  " + "\n  ".join(problems))
    TASKS.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    BOARD.write_text(render(data), encoding="utf-8")


def by_id(data):
    return {t["id"]: t for t in data["tasks"]}


def ready(task, tasks):
    return task["status"] == "todo" and all(tasks[d]["status"] == "done" for d in task["deps"])


def allowed(data, task, by):
    """A task's `reserved_for`, or its lane in data['reserved_lanes'], limits it to that person."""
    owner = task.get("reserved_for") or data.get("reserved_lanes", {}).get(task["tool"])
    return not owner or (by or "").lower().startswith(owner.lower())


def next_tasks(data, tool=None, by=None):
    """Ready tasks in work order: milestone, then priority, then board order.
    With a tool, only that tool's tasks and 'any' tasks; without one, every non-human task.
    With `by`, lanes reserved for someone else are left out."""
    tasks = by_id(data)
    order = {m["id"]: i for i, m in enumerate(data["milestones"])}
    fits = (lambda t: t["tool"] in (tool, "any")) if tool else (lambda t: t["tool"] != "human")
    pool = [(order[t["milestone"]], PRIORITY[t["priority"]], i, t)
            for i, t in enumerate(data["tasks"])
            if fits(t) and ready(t, tasks) and (by is None or allowed(data, t, by))]
    return [t for *_, t in sorted(pool, key=lambda x: x[:3])]


def validate(data):
    problems, tasks = [], {}
    milestones = {m["id"] for m in data["milestones"]}
    for t in data["tasks"]:
        if t["id"] in tasks:
            problems.append(f"duplicate id {t['id']}")
        tasks[t["id"]] = t
        for field, allowed in (("status", STATUSES), ("tool", TOOLS), ("priority", PRIORITY),
                               ("milestone", milestones)):
            if t[field] not in allowed:
                problems.append(f"{t['id']}: bad {field} {t[field]!r}")
        if not t["prompt"].strip():
            problems.append(f"{t['id']}: empty prompt")
    for t in data["tasks"]:
        problems += [f"{t['id']}: unknown dep {d}" for d in t["deps"] if d not in tasks]
    for r in data.get("requirements", []):
        problems += [f"requirement {r['id']}: unknown task {tid}" for tid in r["tasks"] if tid not in tasks]
    seen, done = set(), set()

    def visit(tid, path):
        if tid in done or tid not in tasks:
            return
        if tid in seen:
            problems.append("dependency cycle: " + " -> ".join(path + [tid]))
            return
        seen.add(tid)
        for d in tasks[tid]["deps"]:
            visit(d, path + [tid])
        done.add(tid)

    for tid in tasks:
        visit(tid, [])
    return problems


def describe(t, tasks):
    deps = ", ".join(f"{d} ({tasks[d]['status']})" for d in t["deps"]) or "none"
    lines = [f"{t['id']}  [{t['milestone']} {t['priority']} {t['tool']}]  {t['title']}",
             f"status: {t['status']}" + (f"  owner: {t['owner']}" if t.get("owner") else ""),
             f"depends on: {deps}"]
    if t.get("paths"):
        lines.append("owns paths: " + ", ".join(t["paths"]))
    if t.get("refs"):
        lines.append("read first: " + ", ".join(t["refs"]))
    if t.get("note"):
        lines.append("note: " + t["note"])
    return "\n".join(lines) + "\n\nPROMPT\n" + t["prompt"]


def render(data):
    view = dict(data, updated=max(t.get("updated", "") for t in data["tasks"]))
    # One field per line, like tasks.json, so two teammates' saves merge in git like the JSON does.
    payload = json.dumps(view, indent=1, ensure_ascii=False).replace("</", "<\\/")
    return TEMPLATE.read_text(encoding="utf-8").replace("/*BOARD_DATA*/null", payload)


def set_status(data, tid, status, **fields):
    tasks = by_id(data)
    if tid not in tasks:
        sys.exit(f"no task {tid}")
    t = tasks[tid]
    if status == "in_progress" and not ready(t, tasks):
        sys.exit(f"{tid} is not ready (status {t['status']}; deps must all be done)")
    if status == "in_progress" and not allowed(data, t, fields.get("owner")):
        sys.exit(f"{tid} is reserved for {t.get('reserved_for') or data['reserved_lanes'][t['tool']]} "
                 "(their tools and their area). Take another task.")
    t.update(status=status, updated=today(), **fields)
    save(data)
    print(f"{tid} -> {status}. Now commit and push production/plan/ (see GO_NEXT.md).")


def self_test():
    data = {"milestones": [{"id": "A"}, {"id": "B"}], "tasks": [
        {"id": "x", "milestone": "B", "priority": "P0", "tool": "codex", "status": "todo", "deps": [], "prompt": "p"},
        {"id": "y", "milestone": "A", "priority": "P1", "tool": "any", "status": "todo", "deps": [], "prompt": "p"},
        {"id": "z", "milestone": "A", "priority": "P0", "tool": "codex", "status": "todo", "deps": ["w"], "prompt": "p"},
        {"id": "w", "milestone": "A", "priority": "P2", "tool": "human", "status": "todo", "deps": [], "prompt": "p"},
    ]}
    assert [t["id"] for t in next_tasks(data, "codex")] == ["y", "x"], "milestone order, deps gate z"
    assert [t["id"] for t in next_tasks(data, "human")] == ["y", "w"]
    assert "w" not in [t["id"] for t in next_tasks(data)], "humans' tasks never go to an AI"
    data["tasks"][3]["status"] = "done"
    assert [t["id"] for t in next_tasks(data, "codex")] == ["z", "y", "x"], "z unlocks, P0 first"
    data["reserved_lanes"] = {"codex": "Sadman"}
    assert [t["id"] for t in next_tasks(data, None, "Atik/gemini")] == ["y"], "reserved lane hidden from others"
    assert [t["id"] for t in next_tasks(data, None, "Sadman/claude")] == ["z", "y", "x"], "owner still sees it"
    data["tasks"][3]["deps"] = ["z"]
    assert any("cycle" in p for p in validate(data))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("next"); p.add_argument("--tool", choices=TOOLS); p.add_argument("--all", action="store_true"); p.add_argument("--by")
    p = sub.add_parser("take"); p.add_argument("--tool", choices=TOOLS); p.add_argument("--count", type=int, default=5)
    p.add_argument("--by", required=True)
    p = sub.add_parser("mine"); p.add_argument("--by", required=True)
    p = sub.add_parser("stale"); p.add_argument("--days", type=int, default=2)
    p = sub.add_parser("show"); p.add_argument("id")
    p = sub.add_parser("claim"); p.add_argument("id"); p.add_argument("--by", required=True)
    p = sub.add_parser("done"); p.add_argument("id"); p.add_argument("--evidence", required=True)
    p = sub.add_parser("block"); p.add_argument("id"); p.add_argument("--reason", required=True)
    p = sub.add_parser("release"); p.add_argument("id")
    p = sub.add_parser("list")
    p.add_argument("--status", choices=STATUSES); p.add_argument("--tool", choices=TOOLS); p.add_argument("--milestone")
    sub.add_parser("check"); sub.add_parser("html")
    a = ap.parse_args()

    if a.cmd == "check":
        self_test()
        problems = validate(load())
        print("\n".join(problems) or "board OK")
        sys.exit(1 if problems else 0)
    data = load()
    tasks = by_id(data)
    if a.cmd == "next":
        mine = [t for t in data["tasks"] if t["status"] == "in_progress" and (not a.tool or t["tool"] in (a.tool, "any"))]
        if mine:
            print("Already in progress (finish or release these first if one is yours): "
                  + ", ".join(f"{t['id']} by {t.get('owner') or '?'}" for t in mine) + "\n")
        found = next_tasks(data, a.tool, a.by)
        if not found:
            sys.exit("Nothing is ready for this tool. Try `next` without --tool, or check blocked tasks with `list --status blocked`.")
        if a.all:
            print("\n".join(f"{t['id']}  [{t['milestone']} {t['priority']} {t['tool']}]  {t['title']}" for t in found))
        else:
            print(describe(found[0], tasks))
            print(f"\nClaim it: python3 production/plan/board.py claim {found[0]['id']} --by \"<your name>/<your AI>\"")
    elif a.cmd == "take":
        chunk = next_tasks(data, a.tool, a.by)[:a.count]
        if not chunk:
            sys.exit("Nothing is ready for this tool. Try without --tool, or `list --status blocked`.")
        for t in chunk:
            t.update(status="in_progress", owner=a.by, updated=today())
        save(data)
        print(f"Claimed {len(chunk)} for {a.by}: " + ", ".join(t["id"] for t in chunk)
              + "\nPush the claim now, then work through them in this order (board.py show <id> for each prompt):")
        print("\n".join(f"  {t['id']}  [{t['milestone']} {t['priority']} {t['tool']}]  {t['title']}" for t in chunk))
    elif a.cmd == "mine":
        own = [t for t in data["tasks"] if t["status"] == "in_progress" and t.get("owner") == a.by]
        print("\n".join(f"{t['id']}  [{t['milestone']} {t['priority']} {t['tool']}]  {t['title']}" for t in own)
              or f"No tasks in progress for {a.by}.")
    elif a.cmd == "stale":
        cutoff = (datetime.date.today() - datetime.timedelta(days=a.days)).isoformat()
        old = [t for t in data["tasks"] if t["status"] == "in_progress" and t.get("updated", "") < cutoff]
        print("\n".join(f"{t['id']}  claimed by {t.get('owner') or '?'} on {t.get('updated', '?')}  {t['title']}" for t in old)
              or f"No claims older than {a.days} days.")
    elif a.cmd == "show":
        print(describe(tasks[a.id], tasks) if a.id in tasks else f"no task {a.id}")
    elif a.cmd == "claim":
        set_status(data, a.id, "in_progress", owner=a.by)
    elif a.cmd == "done":
        set_status(data, a.id, "done", evidence=a.evidence)
    elif a.cmd == "block":
        set_status(data, a.id, "blocked", blocker=a.reason)
    elif a.cmd == "release":
        set_status(data, a.id, "todo", owner="")
    elif a.cmd == "list":
        for t in data["tasks"]:
            if all(v is None or t[k] == v for k, v in (("status", a.status), ("tool", a.tool), ("milestone", a.milestone))):
                print(f"{t['id']}  {t['status']:<11} [{t['milestone']} {t['priority']} {t['tool']}]  {t['title']}")
    elif a.cmd == "html":
        save(data)
        print(f"wrote {BOARD.relative_to(HERE.parent.parent)}")


if __name__ == "__main__":
    main()
