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
import html
import json
import pathlib
import sys
import fnmatch

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
    problems = validate(data) + (merge_risks(data) if data.get("implementation_batch", {}).get("active") else [])
    if problems:
        sys.exit("board not saved:\n  " + "\n  ".join(problems))
    TASKS.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    BOARD.write_text(render(data), encoding="utf-8")


def by_id(data):
    return {t["id"]: t for t in data["tasks"]}


def ready(task, tasks):
    return task["status"] == "todo" and all(tasks[d]["status"] == "done" for d in task["deps"])


def batch_owner(data, tid):
    batch = data.get("implementation_batch", {})
    if batch.get("active"):
        return next((member for member, ids in batch.get("assignments", {}).items() if tid in ids), None)
    return None


def batch_phase(data, task):
    batch = data.get("implementation_batch", {})
    if not batch.get("active"):
        return "legacy"
    if batch_owner(data, task["id"]):
        return "implementation"
    if task["id"] in batch.get("deferred_ids", []):
        return "deferred"
    if task["id"] in batch.get("acceptance_ids", []):
        return "acceptance"
    return "history" if task["status"] == "done" else "unplanned"


def selectable(data, task):
    return batch_phase(data, task) in ("legacy", "implementation")


def person(identity):
    return (identity or "").split("/", 1)[0].strip().lower()


def allowed(data, task, by):
    """A task's `reserved_for`, or its lane in data['reserved_lanes'], limits it to that person."""
    if not selectable(data, task):
        return False
    owner = batch_owner(data, task["id"]) or task.get("reserved_for") or data.get("reserved_lanes", {}).get(task["tool"])
    return not owner or person(by) == owner.lower()


def next_tasks(data, tool=None, by=None):
    """Ready tasks in batch order, or milestone/priority/board order without a batch.
    With a tool, only that tool's tasks and 'any' tasks; without one, every non-human task.
    With `by`, lanes reserved for someone else are left out."""
    tasks = by_id(data)
    order = {m["id"]: i for i, m in enumerate(data["milestones"])}
    fits = (lambda t: t["tool"] in (tool, "any")) if tool else (lambda t: t["tool"] != "human")
    pool = [(order[t["milestone"]], PRIORITY[t["priority"]], i, t)
            for i, t in enumerate(data["tasks"])
            if selectable(data, t) and fits(t) and ready(t, tasks) and (by is None or allowed(data, t, by))]
    batch = data.get("implementation_batch", {})
    if batch.get("active"):
        ranked = {tid: i for i, tid in enumerate(tid for member in batch.get("priority_order", batch["assignments"]) for tid in batch["assignments"][member])}
        pool.sort(key=lambda row: ranked[row[-1]["id"]])
    else:
        pool.sort(key=lambda row: row[:3])
    return [t for *_, t in pool]


def member_ids(data):
    return {m["id"].lower() for m in data.get("members", [])}


def _specific(paths, shared):
    """Paths narrow enough to clash on: not a shared append-only file, not a whole top folder."""
    return [p for p in paths if p not in shared and p.rstrip("/").count("/") >= 2]


def merge_risks(data):
    """Open tasks of two different members that own overlapping paths would edit the same files: a merge risk."""
    if data.get("implementation_batch", {}).get("active"):
        locks, risks = {}, []
        for task in data["tasks"]:
            for path in task.get("edit_files", []):
                key = path.lower()
                if key in locks and locks[key] != task["id"]:
                    risks.append(f"file lock conflict: {task['id']} and {locks[key]} both reserve {path}")
                locks[key] = task["id"]
        return risks
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


def file_problems(task, paths):
    scopes = task.get("paths", []) + task.get("integration_paths", [])
    problems = []
    for path in paths:
        if not isinstance(path, str) or not path or "\\" in path or ":" in path or path.startswith("/") or any(c in path for c in "*?[]") or any(ord(c) < 32 for c in path) or any(p in ("", ".", "..", ".git") for p in path.split("/")):
            problems.append("file locks require clean repository-relative file paths")
            continue
        if (HERE.parent.parent / path).is_dir():
            problems.append("file locks require exact files, not directories")
            continue
        if not any(path.startswith(s) if s.endswith("/") else fnmatch.fnmatchcase(path, s) for s in scopes):
            problems.append(f"{task['id']}: {path} is outside the task's paths/integration_paths")
    return problems


def reserve_files(data, tid, by, paths):
    task = by_id(data).get(tid)
    if task is None or not allowed(data, task, by) or task["status"] != "in_progress" or person(task.get("owner")) != person(by):
        return ["only the current member of a claimed active task may reserve its files"]
    if not paths:
        return ["specify the exact files to reserve"]
    problems = file_problems(task, paths)
    if problems:
        return problems
    wanted = {p.lower() for p in paths}
    for other in data["tasks"]:
        if other["id"] != tid and wanted.intersection(p.lower() for p in other.get("edit_files", [])):
            return [f"file reserved by {other['id']} ({other.get('owner', '?')}); save/hand off first or use another ready task"]
    task["edit_files"] = list(dict.fromkeys(task.get("edit_files", []) + paths))
    return []


def team(data):
    """Effort per member against the target share (effort defaults to 2 points)."""
    pool = [t for t in data["tasks"] if selectable(data, t)]
    rows, total = [], sum(t.get("effort", 2) for t in pool if t["status"] != "done" and t.get("reserved_for"))
    for m in data.get("members", []):
        mine = [t for t in pool if (t.get("reserved_for") or "").lower() == m["id"].lower()]
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
        for field, values in (("status", STATUSES), ("tool", TOOLS), ("priority", PRIORITY),
                               ("milestone", milestones)):
            if t[field] not in values:
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
    batch = data.get("implementation_batch", {})
    if batch.get("active"):
        assigned = {}
        for member, ids in batch.get("assignments", {}).items():
            if member not in members:
                problems.append(f"batch member {member} is not in members")
            for tid in ids:
                if tid in assigned:
                    problems.append(f"batch task {tid} appears more than once")
                assigned[tid] = member
                if tid not in tasks:
                    problems.append(f"batch references unknown task {tid}")
                elif tasks[tid].get("reserved_for") != member:
                    problems.append(f"{tid}: batch assigns {member}, reserved_for must match")
        categorized = set(assigned)
        for phase in ("deferred_ids", "acceptance_ids"):
            for tid in batch.get(phase, []):
                if tid not in tasks or tid in categorized:
                    problems.append(f"batch {phase}: unknown or repeated task {tid}")
                categorized.add(tid)
        for task in tasks.values():
            if task.get("edit_files"):
                if not selectable(data, task) or task["status"] != "in_progress" or not allowed(data, task, task.get("owner")):
                    problems.append(f"{task['id']}: file locks require its active claimed owner")
                problems += file_problems(task, task["edit_files"])
    return problems


def describe(t, tasks, data=None):
    deps = ", ".join(f"{d} ({tasks[d]['status']})" for d in t["deps"]) or "none"
    lines = [f"{t['id']}  [{t['milestone']} {t['priority']} {t['tool']}]  {t['title']}",
             f"status: {t['status']}" + (f"  owner: {t['owner']}" if t.get("owner") else "")
             + (f"  assigned to: {t['reserved_for']}" if t.get("reserved_for") else "") + f"  effort: {t.get('effort', 2)}",
             f"depends on: {deps}"]
    if data and data.get("implementation_batch", {}).get("active"):
        lines.append("batch phase: " + batch_phase(data, t))
    if t.get("paths"):
        lines.append("owns paths: " + ", ".join(t["paths"]))
    if t.get("integration_paths"):
        lines.append("task-scoped integration paths (reserve exact files first): " + ", ".join(t["integration_paths"]))
    if t.get("edit_files"):
        lines.append("reserved files: " + ", ".join(t["edit_files"]))
    if t.get("refs"):
        lines.append("read first: " + ", ".join(t["refs"]))
    if t.get("note"):
        lines.append("note: " + t["note"])
    if t.get("blocker"):
        lines.append("blocker: " + t["blocker"])
    return "\n".join(lines) + "\n\nPROMPT\n" + t["prompt"]


TEAM_CSS = """.grid.team { grid-template-columns: repeat(auto-fit, minmax(min(340px, 100%), 1fr)); align-items: start; }
.team .panel, .task .meta { overflow-wrap: anywhere; }
.team details { margin-top: 10px; }
.team summary { cursor: pointer; color: var(--accent); font-weight: 600; }
.team ul { margin: 6px 0 0; padding-left: 18px; }
.team li { margin: 6px 0; }
.team .counts { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
.filters select { max-width: 100%; }
"""
DEADLINES_ANCHOR = '<div class="grid" id="deadlines"></div>'


def _short(text, n=180):
    text = " ".join(str(text or "").split())
    return text if len(text) <= n else text[:n - 1] + "…"


def team_html(data):
    """BOARD.html's Team section: per member what is being worked on, what is next (take's order), blocked, to do, done."""
    e, ids = html.escape, member_ids(data)
    who = lambda t: (t.get("reserved_for") or "").lower() if (t.get("reserved_for") or "").lower() in ids else None
    groups = [(m["id"].lower(), m) for m in data.get("members", [])]
    groups.append((None, {"name": "Unassigned / earlier work", "role": "Done before the team split, or by someone not on the member list"}))
    chip = lambda text, cls="": f'<span class="chip {cls}">{e(text)}</span>'

    def li(t, extra=""):
        return f'<li><a class="id" href="#{e(t["id"])}">{e(t["id"])}</a> {e(t.get("title", ""))} {chip(t["tool"])} {chip(t["priority"])}{extra}</li>'

    def part(label, items, open_=True):
        if not items:
            return ""
        return f'<details{" open" if open_ else ""}><summary>{label} ({len(items)})</summary><ul>\n' + "\n".join(items) + "\n</ul></details>"

    cards = []
    for mid, m in groups:
        all_mine = [t for t in data["tasks"] if who(t) == mid]
        mine = [t for t in all_mine if selectable(data, t)]
        if mid is None and not all_mine:
            continue
        own = {t["id"] for t in mine}
        st = {s: [t for t in mine if t["status"] == s] for s in STATUSES}
        nxt = [t for t in next_tasks(data, None, mid) if t["id"] in own][:5]  # the chunk `take` would claim
        nxt += [t for t in next_tasks(data, "human", mid) if t["id"] in own and t["tool"] == "human"]  # done by hand, never taken by an AI
        pct = round(100 * len(st["done"]) / max(len(mine), 1))
        head = (f'<b>{e(m.get("name") or mid)}</b>' + (f' <span class="id">{e(mid)}</span>' if mid else "")
                + f'<div class="meta">{e(m.get("role", ""))}' + (f' · {m["share"]}% share' if "share" in m else "") + "</div>"
                + '<div class="counts">' + "".join(chip(f'{len(st[s])} {s.replace("_", " ")}', "s-" + s)
                                                  for s in ("done", "in_progress", "blocked", "todo")) + "</div>"
                + f'<div class="bar"><i style="width:{pct}%"></i></div>')
        body = [
            part("Working now", [li(t, f'<div class="meta">claimed by {e(t.get("owner") or "?")} on {e(t.get("updated", "?"))}</div>')
                                 for t in st["in_progress"]]),
            part("Next up today", [li(t) for t in nxt]),
            part("Blocked", [li(t, f'<div class="meta">{e(_short(t.get("blocker") or t.get("note") or t.get("evidence")))}</div>')
                             for t in st["blocked"]]),
            part("To do", [li(t) for t in st["todo"] if t not in nxt], open_=False),
            part("Done", [li(t, f'<div class="meta">{e(_short(t.get("evidence"), 140))}</div>') for t in st["done"]], open_=False),
            part("Deferred: video, submission and manual QA", [li(t) for t in all_mine if batch_phase(data, t) == "deferred"], open_=False),
            part("Source delivered: acceptance only", [li(t) for t in all_mine if batch_phase(data, t) == "acceptance"], open_=False),
            part("Earlier completed work", [li(t) for t in all_mine if batch_phase(data, t) == "history"], open_=False),
            part("Unplanned: requires explicit batch assignment", [li(t) for t in all_mine if batch_phase(data, t) == "unplanned"], open_=False),
        ]
        cards.append(f'<div class="panel" data-member="{e(mid or "")}">' + head + "\n" + "\n".join(b for b in body if b) + "\n</div>")
    return ('<h2 id="team">Team</h2>\n<p class="sub">Who is doing what. Next up lists assigned ready tasks; claim one exact ID. '
            "Deferred and acceptance work stays visible separately.</p>\n"
            '<div class="grid team">\n' + "\n".join(cards) + "\n</div>")


def render(data):
    view = dict(data, updated=max(t.get("updated", "") for t in data["tasks"]))
    view["tasks"] = [dict(t, batch_phase=batch_phase(data, t)) for t in data["tasks"]]
    # One field per line, like tasks.json, so two teammates' saves merge in git like the JSON does.
    payload = json.dumps(view, indent=1, ensure_ascii=False).replace("</", "<\\/")
    page = TEMPLATE.read_text(encoding="utf-8").replace("/*BOARD_DATA*/null", payload)
    page = page.replace("</style>", TEAM_CSS + "</style>", 1)  # payload has no "</", so these hit the template only
    return page.replace(DEADLINES_ANCHOR, DEADLINES_ANCHOR + "\n\n  " + team_html(data), 1)


def set_status(data, tid, status, by=None, **fields):
    tasks = by_id(data)
    if tid not in tasks:
        sys.exit(f"no task {tid}")
    t = tasks[tid]
    if data.get("implementation_batch", {}).get("active") and status != "in_progress":
        if not by:
            sys.exit("status changes in the active batch require --by Name/AI")
        acceptance_closure = batch_phase(data, t) == "acceptance" and status == "done" and person(by) == (t.get("reserved_for") or "").lower()
        if not acceptance_closure and not allowed(data, t, by):
            sys.exit(f"{tid}: only its assigned member may change this task's active status; deferred work stays deferred")
        if t.get("edit_files") and person(t.get("owner")) != person(by):
            sys.exit("only the current owner may clear this task's file reservations")
    if status == "in_progress" and not selectable(data, t):
        sys.exit(f"{tid} is outside the active implementation batch ({batch_phase(data, t)}); do not claim deferred work")
    if status == "in_progress" and not ready(t, tasks):
        sys.exit(f"{tid} is not ready (status {t['status']}; deps must all be done)")
    if status == "in_progress" and not allowed(data, t, fields.get("owner")):
        sys.exit(f"{tid} is reserved for {t.get('reserved_for') or data['reserved_lanes'][t['tool']]} "
                 "(their tools and their area). Take another task.")
    t.update(status=status, updated=today(), **fields)
    if status != "in_progress":
        t.pop("edit_files", None)
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
    data["tasks"][0].update(status="in_progress", owner="Ramim/codex", reserved_for="Ramim")
    ramim = render(data).split('data-member="ramim"')[1].split("data-member=")[0]
    assert "Working now" in ramim and 'href="#x"' in ramim, "Team section lists an in-progress task under its member"


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
    p = sub.add_parser("lock", help="reserve exact files before editing a claimed task")
    p.add_argument("id"); p.add_argument("--by", required=True); p.add_argument("--files", required=True)
    p = sub.add_parser("unlock", help="release your task's files after saving and pushing its work")
    p.add_argument("id"); p.add_argument("--by", required=True)
    p = sub.add_parser("done"); p.add_argument("id"); p.add_argument("--evidence", required=True); p.add_argument("--by")
    p = sub.add_parser("block"); p.add_argument("id"); p.add_argument("--reason", required=True); p.add_argument("--by")
    p = sub.add_parser("release"); p.add_argument("id"); p.add_argument("--by")
    p = sub.add_parser("list")
    p.add_argument("--status", choices=STATUSES); p.add_argument("--tool", choices=TOOLS); p.add_argument("--milestone")
    p.add_argument("--member", help="only tasks assigned to this member (reserved_for)")
    p.add_argument("--phase", choices=("implementation", "deferred", "acceptance", "history", "unplanned", "legacy"))
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
    if data.get("implementation_batch", {}).get("active") and a.cmd in ("take", "next"):
        sys.exit("The active batch uses exact task IDs, not general take/next. Use list --member NAME --phase implementation, then show/claim an assigned ID.")
    if a.cmd == "next":
        mine = [t for t in data["tasks"] if selectable(data, t) and t["status"] == "in_progress" and (not a.by or allowed(data, t, a.by)) and (not a.tool or t["tool"] in (a.tool, "any"))]
        if mine:
            print("Already in progress (finish or release these first if one is yours): "
                  + ", ".join(f"{t['id']} by {t.get('owner') or '?'}" for t in mine) + "\n")
        found = next_tasks(data, a.tool, a.by)
        if not found:
            sys.exit("Nothing is ready for this tool. Try `next` without --tool, or check blocked tasks with `list --status blocked`.")
        if a.all:
            print("\n".join(f"{t['id']}  [{t['milestone']} {t['priority']} {t['tool']}]  {t['title']}" for t in found))
        else:
            print(describe(found[0], tasks, data))
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
        own = [t for t in data["tasks"] if selectable(data, t) and t["status"] == "in_progress" and person(t.get("owner")) == person(a.by) and allowed(data, t, a.by)]
        print("\n".join(f"{t['id']}  [{t['milestone']} {t['priority']} {t['tool']}]  {t['title']}" for t in own)
              or f"No tasks in progress for {a.by}.")
    elif a.cmd == "stale":
        cutoff = (datetime.date.today() - datetime.timedelta(days=a.days)).isoformat()
        old = [t for t in data["tasks"] if t["status"] == "in_progress" and t.get("updated", "") < cutoff]
        print("\n".join(f"{t['id']}  claimed by {t.get('owner') or '?'} on {t.get('updated', '?')}  {t['title']}" for t in old)
              or f"No claims older than {a.days} days.")
    elif a.cmd == "show":
        print(describe(tasks[a.id], tasks, data) if a.id in tasks else f"no task {a.id}")
    elif a.cmd == "claim":
        set_status(data, a.id, "in_progress", owner=a.by)
    elif a.cmd == "lock":
        problems = reserve_files(data, a.id, a.by, [p.strip() for p in a.files.split(",") if p.strip()])
        if problems:
            sys.exit("files not reserved:\n  " + "\n  ".join(problems))
        save(data)
        print(f"Reserved files for {a.id}. Push this reservation before editing; preserve reservations from rejected-push merges.")
    elif a.cmd == "unlock":
        task = tasks.get(a.id)
        if task is None or not allowed(data, task, a.by) or person(task.get("owner")) != person(a.by):
            sys.exit("only the task's current member may release its file reservations")
        task.pop("edit_files", None)
        save(data)
        print(f"Released files for {a.id}; push the board update.")
    elif a.cmd == "done":
        set_status(data, a.id, "done", by=a.by, evidence=a.evidence)
    elif a.cmd == "block":
        set_status(data, a.id, "blocked", by=a.by, blocker=a.reason)
    elif a.cmd == "release":
        set_status(data, a.id, "todo", by=a.by, owner="")
    elif a.cmd == "list":
        for t in data["tasks"]:
            if all(v is None or t[k] == v for k, v in (("status", a.status), ("tool", a.tool), ("milestone", a.milestone))) \
                    and (a.member is None or (t.get("reserved_for") or "").lower() == a.member.lower()) \
                    and (a.phase is None or batch_phase(data, t) == a.phase):
                print(f"{t['id']}  {t['status']:<11} [{t['milestone']} {t['priority']} {t['tool']}] [{batch_phase(data, t)}]  {t['title']}")
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
