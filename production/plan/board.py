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
  python3 production/plan/board.py check                      # validate the board, merge risks and self-test
  python3 production/plan/board.py team                       # each member's share of the work (MASTER_PLAN.md §7)
  python3 production/plan/board.py take --by "Ramim/codex"    # continue(ramim): claim Ramim's next ready tasks
  python3 production/plan/board.py rename-member member4 tanvir --name "Abu Sayem Mohammed Tanvir"
  python3 production/plan/board.py add --milestone M1 --for atik --title "..." --prompt "..." --paths game/scripts/eva/ --by "Ramim/codex"

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


def member_ids(data):
    return {m["id"].lower() for m in data.get("members", [])}


def _specific(paths, shared):
    """Paths narrow enough to clash on: not a shared append-only file, not a whole top folder."""
    return [p for p in paths if p not in shared and p.rstrip("/").count("/") >= 2]


def merge_risks(data):
    """Open tasks of two different members that own overlapping paths would edit the same files: a merge risk."""
    shared = set(data.get("shared_paths", []))
    open_tasks = [t for t in data["tasks"] if t["status"] != "done" and t.get("reserved_for")]
    risks = []
    for i, a in enumerate(open_tasks):
        for b in open_tasks[i + 1:]:
            if a["reserved_for"].lower() == b["reserved_for"].lower():
                continue
            hit = [(x, y) for x in _specific(a.get("paths", []), shared) for y in _specific(b.get("paths", []), shared)
                   if x.startswith(y) or y.startswith(x)]
            if hit:
                risks.append(f"merge risk: {a['id']} ({a['reserved_for']}) and {b['id']} ({b['reserved_for']}) both own {hit[0][0]}")
    return risks


def team(data):
    """Effort per member against the target share (effort defaults to 2 points)."""
    rows, total = [], sum(t.get("effort", 2) for t in data["tasks"] if t["status"] != "done" and t.get("reserved_for"))
    for m in data.get("members", []):
        mine = [t for t in data["tasks"] if (t.get("reserved_for") or "").lower() == m["id"].lower()]
        left = sum(t.get("effort", 2) for t in mine if t["status"] != "done")
        done = sum(t.get("effort", 2) for t in mine if t["status"] == "done")
        rows.append(f"{m['id']:<9} {m.get('role', ''):<44} target {m['share']:>3}%  open {left:>4} pts = {100 * left / max(total, 1):5.1f}%  "
                    f"({sum(t['status'] != 'done' for t in mine)} tasks)  done {done} pts  card: {m.get('card', '-')}")
    return rows


def next_id(data, milestone):
    """The next free numeric id in a milestone: M1-66, M4-01..."""
    nums = [int(t["id"].split("-", 1)[1]) for t in data["tasks"]
            if t["id"].startswith(milestone + "-") and t["id"].split("-", 1)[1].isdigit()]
    return f"{milestone}-{max(nums, default=0) + 1:02d}"


def validate(data):
    problems, tasks = [], {}
    milestones = {m["id"] for m in data["milestones"]}
    members = member_ids(data)
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
        if members and t["status"] != "done" and t.get("reserved_for") and t["reserved_for"].lower() not in members:
            problems.append(f"{t['id']}: reserved_for {t['reserved_for']!r} is not in members")
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
             f"status: {t['status']}" + (f"  owner: {t['owner']}" if t.get("owner") else "")
             + (f"  assigned to: {t['reserved_for']}" if t.get("reserved_for") else "") + f"  effort: {t.get('effort', 2)}",
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
    data["tasks"][3]["deps"] = []
    data["members"] = [{"id": "ramim", "share": 60}, {"id": "atik", "share": 40}]
    data["tasks"][0].update(reserved_for="ramim", paths=["game/scripts/ui/hud.gd"])
    data["tasks"][1].update(reserved_for="atik", paths=["game/scripts/ui/"])
    assert merge_risks(data), "two members owning overlapping paths is a merge risk"
    data["tasks"][1]["paths"] = ["game/scripts/eva/"]
    assert not merge_risks(data)
    assert [t["id"] for t in next_tasks(data, None, "Atik/codex")] == ["y"], "continue(atik): Ramim's x and Sadman's lane (z) stay hidden"
    assert [t["id"] for t in next_tasks(data, None, "Ramim/claude")] == ["x"], "continue(ramim) sees only Ramim's task"
    data["tasks"][2]["reserved_for"] = "nobody"
    assert any("not in members" in p for p in validate(data))
    assert next_id(data, "A") == "A-01" and next_id({"tasks": [{"id": "M1-65"}, {"id": "M1-2A"}]}, "M1") == "M1-66"


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
    p.add_argument("--member", help="only tasks assigned to this member (reserved_for)")
    sub.add_parser("check"); sub.add_parser("html"); sub.add_parser("team")
    p = sub.add_parser("add", help="file a task for a member (cross-folder requests, QA findings)")
    p.add_argument("--milestone", required=True); p.add_argument("--for", dest="member", required=True)
    p.add_argument("--title", required=True); p.add_argument("--prompt", required=True)
    p.add_argument("--priority", default="P1", choices=PRIORITY); p.add_argument("--tool", default="any", choices=TOOLS)
    p.add_argument("--paths", default=""); p.add_argument("--deps", default=""); p.add_argument("--effort", type=int, default=2)
    p.add_argument("--by", default="")
    p = sub.add_parser("rename-member"); p.add_argument("old"); p.add_argument("new"); p.add_argument("--name", default="")
    a = ap.parse_args()

    if a.cmd == "check":
        self_test()
        problems = validate(load()) + merge_risks(load())
        print("\n".join(problems) or "board OK")
        sys.exit(1 if problems else 0)
    if a.cmd == "team":
        print("\n".join(team(load())))
        return
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
            if all(v is None or t[k] == v for k, v in (("status", a.status), ("tool", a.tool), ("milestone", a.milestone))) \
                    and (a.member is None or (t.get("reserved_for") or "").lower() == a.member.lower()):
                print(f"{t['id']}  {t['status']:<11} [{t['milestone']} {t['priority']} {t['tool']}]  {t['title']}")
    elif a.cmd == "add":
        if data.get("members") and a.member.lower() not in member_ids(data):
            sys.exit(f"no member {a.member}; members: {', '.join(sorted(member_ids(data)))}")
        tid = next_id(data, a.milestone)
        split = lambda v: [x.strip() for x in v.split(",") if x.strip()]
        data["tasks"].append({"id": tid, "milestone": a.milestone, "priority": a.priority, "tool": a.tool, "title": a.title,
                              "status": "todo", "owner": "", "deps": split(a.deps), "paths": split(a.paths), "refs": [],
                              "note": f"Filed by {a.by or 'a teammate'} on {today()}.", "evidence": "", "updated": today(),
                              "prompt": a.prompt, "reserved_for": a.member.lower(), "effort": a.effort})
        save(data)
        print(f"{tid} added for {a.member.lower()}. Commit and push production/plan/.")
    elif a.cmd == "rename-member":
        member = next((m for m in data.get("members", []) if m["id"].lower() == a.old.lower()), None)
        if member is None:
            sys.exit(f"no member {a.old}")
        member["id"] = a.new.lower()
        if a.name:
            member["name"] = a.name
        for t in data["tasks"]:
            if (t.get("reserved_for") or "").lower() == a.old.lower():
                t["reserved_for"] = a.new.lower()
        save(data)
        print(f"{a.old} is now {a.new.lower()}. Commit and push production/plan/.")
    elif a.cmd == "html":
        save(data)
        print(f"wrote {BOARD.relative_to(HERE.parent.parent)}")


if __name__ == "__main__":
    main()
