#!/usr/bin/env python3
"""M1-22: turn anonymous playtest logs into the metrics the board asks for.

    python3 production/qa/playtests/learner_kit/summarise.py <folder with session_*.jsonl> [...]

Logs come from the game launched with --playtest (see FACILITATOR.md); the
default folder on Windows is %APPDATA%/Godot/app_userdata/Last Light Academy/playtest,
on macOS ~/Library/Application Support/Godot/app_userdata/Last Light Academy/playtest.
Prints one row per session and a Markdown table to paste into the report.
"""
import json, sys
from pathlib import Path


def summarise(path: Path) -> dict:
    events = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    first_done = next((e["t_play"] for e in events if e["event"] == "action" and e.get("accepted") and e.get("done")), None)
    tries = {"P-01": 0, "P-02": 0, "later": 0}
    for e in events:
        if e["event"] == "try":
            tries[e.get("puzzle") if e.get("puzzle") in ("P-01", "P-02") else "later"] += 1
    refused = sum(1 for e in events if e["event"] == "action" and not e.get("accepted"))
    hints = sum(1 for e in events if e["event"] == "hint")
    scenes = [e["scene"] for e in events if e["event"] == "scene"]
    ending = next((e.get("ending", "") for e in reversed(events) if e["event"] == "ending"), "")
    last = max((e["t_play"] for e in events if e.get("t_play", -1) >= 0), default=0)
    stuck = []  # scenes where a refused action came before any accepted one: likely confusion points
    seen_ok = set()
    for e in events:
        if e["event"] == "action":
            if e.get("accepted"):
                seen_ok.add(e.get("scene"))
            elif e.get("scene") not in seen_ok and e.get("scene") not in stuck:
                stuck.append(e.get("scene"))
    return {"session": path.stem, "minutes_played": round(last / 60, 1), "first_objective_s": first_done, "p01_tries": tries["P-01"], "p02_tries": tries["P-02"], "later_tries": tries["later"], "refused_actions": refused, "hints": hints, "scenes_reached": len(set(scenes)), "furthest_scene": scenes[-1] if scenes else "", "ending": ending, "early_confusion": ", ".join(s for s in stuck if s)}


def main() -> None:
    files = [f for arg in sys.argv[1:] for f in (sorted(Path(arg).glob("session_*.jsonl")) if Path(arg).is_dir() else [Path(arg)])]
    if not files:
        sys.exit(__doc__)
    rows = [summarise(f) for f in files]
    keys = list(rows[0])
    print("| " + " | ".join(keys) + " |")
    print("|" + "---|" * len(keys))
    for row in rows:
        print("| " + " | ".join(str(row[k]) for k in keys) + " |")


if __name__ == "__main__":
    main()
