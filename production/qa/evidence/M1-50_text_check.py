#!/usr/bin/env python3
"""M1-50 acceptance check for the Chapter 1 narrative text pack.

Run from the repository root:
    python3 -I production/qa/evidence/M1-50_text_check.py            # checks; prints every entry id
    python3 -I production/qa/evidence/M1-50_text_check.py --review   # also writes M1-50_text_for_review.md

Checks journal_text.json and story_echoes.json against the canon sources named by the board task:
story-data.json scene ids, the campaign catalog's choice and option ids, the Chapter 1 gate catalog's
target ids, the verbatim doc 24 sentences, the banned words and the two-sentence limit.
Exit code 1 if any check fails.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path.cwd()
CONTENT = ROOT / "game/resources/campaign/content"
JOURNAL = CONTENT / "journal_text.json"
ECHOES = CONTENT / "story_echoes.json"
STORY = ROOT / "full-game-story/story-data.json"
CATALOG = CONTENT / "campaign_catalog.json"
GATES = ROOT / "game/scripts/missions/chapter1_gate_catalog.gd"
REVIEW = ROOT / "production/qa/evidence/M1-50_text_for_review.md"

# Doc 24 text the pack must carry word for word.
LID_INSCRIPTION = "Seed 1: outer chamber. Seed 2: inside, for comparison. Water at"
FEEDBACK = "The wall is still shielding the next exposure. Drain after it resolves."
ALO_LOST = "Alo did not survive the night in this attempt. Your checkpoint keeps her alive at the start of shift 5."

BANNED = ["Noor", "Rahman", "Ferreira was"]
# Words that would imply endorsement or leak later chapters into Chapter 1 text.
NEVER_IN_CH01 = ["NASA", "Rao", "Expedition Zero", "2034", "Bangladesh", "Commander", "pollinat", "pollen", "Last Light"]
# First Chapter 1 scene in which each name or fact is on screen (story-data prose and lines).
FIRST_SCENE = {"Mei": 1, "Kai": 1, "Amara": 1, "Rafi": 1, "Ferreira": 1, "ALO": 3, "Alo": 3, "N.": 3,
               "Tara": 4, "mustard": 12, "bloom": 12, "flower": 12, "recording": 12, "friend": 12}
TABS = {"now", "evidence", "garden", "decisions", "science", "people"}
STATUSES = {"UNKNOWN", "OBSERVED", "VERIFIED", "LINKED", "ARCHIVED", "INFERRED"}
LABELS = {"Simulated", "Fiction", "Computed-pending"}
CORE = ["id", "tab", "type", "status", "title", "body", "scene_id", "source", "evidence_label", "links", "gate_flag"]

failures: list[str] = []


def fail(message: str) -> None:
    failures.append(message)


def sentences(text: str) -> int:
    """Counts sentences, treating the initial "N." and placeholders as words."""
    masked = re.sub(r"\{[^}]*\}", "X", text).replace("N.'s", "Ns").replace("N.", "N")
    parts = [p for p in re.split(r"(?<=[.!?])\s+", masked.strip()) if p]
    return len(parts)


def scene_number(scene_id: str) -> int:
    return int(scene_id.rsplit("S", 1)[1]) if scene_id.startswith("EX-CH01-S") else 99


def fk_grade(text: str) -> float:
    """Flesch-Kincaid grade level; a rough readability guide, not a gate."""
    words = re.findall(r"[A-Za-z']+", re.sub(r"\{[^}]*\}", "", text))
    if not words:
        return 0.0
    syllables = sum(max(1, len(re.findall(r"[aeiouy]+", w.lower())) - (1 if w.lower().endswith("e") and len(w) > 3 else 0)) for w in words)
    return 0.39 * len(words) / max(1, sentences(text)) + 11.8 * syllables / len(words) - 15.59


def all_text(entry: dict) -> list[str]:
    texts = [entry.get("title", ""), entry.get("body", ""), entry.get("body_template", ""),
             entry.get("objective_text", ""), entry.get("completed_text", ""), entry.get("text", "")]
    for slot in entry.get("placeholders", {}).values():
        texts.extend(slot.values())
    return [t for t in texts if t]


# ---------------------------------------------------------------- load sources
journal = json.loads(JOURNAL.read_text())
echoes = json.loads(ECHOES.read_text())
story = json.loads(STORY.read_text())
catalog = json.loads(CATALOG.read_text())
story_scenes = {s["id"]: s for c in story["chapters"] for s in c["scenes"]}
catalog_scenes = {s["id"]: s for s in catalog["scenes"]}
choice_options = {s["choice"]["id"]: {o["id"] for o in s["choice"]["options"]}
                  for s in catalog["scenes"] if isinstance(s.get("choice"), dict) and s["choice"].get("id")}
gate_source = GATES.read_text()
targets: dict[str, set] = {}
current = ""
for line in gate_source.splitlines():
    m = re.match(r'\s*"(EX-CH01-S\d\d)":\s*$', line)
    if m:
        current = m.group(1)
    m = re.search(r'_(?:p01_|p02_)?target\("([a-z0-9_]+)"', line)
    if m and current:
        targets.setdefault(current, set()).add(m.group(1))
all_targets = {(s, t) for s, ts in targets.items() for t in ts}

entries = journal["entries"]
ids = [e["id"] for e in entries]
by_id = {e["id"]: e for e in entries}

# ---------------------------------------------------------------- journal_text checks
if len(ids) != len(set(ids)):
    fail("journal: duplicate entry ids")
for e in entries:
    eid = e["id"]
    for key in CORE:
        if key not in e:
            fail(f"{eid}: missing {key}")
    if e["scene_id"] not in story_scenes:
        fail(f"{eid}: scene_id {e['scene_id']} not in story-data.json")
    if e["tab"] not in TABS:
        fail(f"{eid}: tab {e['tab']}")
    if e["status"] not in STATUSES:
        fail(f"{eid}: status {e['status']}")
    if e["evidence_label"] not in LABELS:
        fail(f"{eid}: evidence_label {e['evidence_label']}")
    for link in e["links"]:
        if link not in by_id:
            fail(f"{eid}: link {link} does not resolve")
    texts = all_text(e)
    for text in texts:
        for word in BANNED + NEVER_IN_CH01:
            if word in text:
                fail(f"{eid}: contains '{word}'")
        if re.search(r"[ঀ-৿]", text):
            fail(f"{eid}: Bangla script")
    for text in [e["body"], e.get("body_template", "")] + [v for slot in e.get("placeholders", {}).values() for v in slot.values()]:
        if text and sentences(text) > 2:
            fail(f"{eid}: more than two sentences: {text}")
    n = scene_number(e["scene_id"])
    if e.get("trigger", {}).get("on") != "template":
        joined = " ".join(texts)
        for word, first in FIRST_SCENE.items():
            if n < first and re.search(r"(?<![A-Za-z])" + re.escape(word), joined):
                fail(f"{eid}: '{word}' appears in S{n:02d} text before S{first:02d}")
    trig = e.get("trigger")
    if not isinstance(trig, dict) or not trig.get("on"):
        fail(f"{eid}: no trigger")
    elif trig["on"] == "target" and (trig["scene_id"], trig["target_id"]) not in all_targets:
        fail(f"{eid}: trigger target {trig['scene_id']}/{trig['target_id']} not in chapter1_gate_catalog.gd")
    elif trig["on"] == "choice_confirmed" and trig["option_id"] not in choice_options.get(trig["choice_id"], set()):
        fail(f"{eid}: choice {trig['choice_id']}/{trig['option_id']} not in campaign_catalog.json")
    if e.get("surface") not in {"journal", "p02_preview", "chapter_debrief", "resume_card", "growth_record"}:
        fail(f"{eid}: surface {e.get('surface')}")

# One entry per gate-catalog target, a concept card and a Now entry per scene, every choice option.
covered = {(e["scene_id"], e["target_id"]) for e in entries if e.get("target_id")}
for missing in sorted(all_targets - covered):
    fail(f"journal: no entry for target {missing[0]}/{missing[1]}")
for scene_id, scene in story_scenes.items():
    if not scene_id.startswith("EX-CH01-"):
        continue
    concept = by_id.get(f"J-CH01-{scene_id[-3:]}-CONCEPT")
    if not concept:
        fail(f"journal: no concept card for {scene_id}")
    elif concept.get("learning") != scene["learning"]:
        fail(f"{concept['id']}: learning block differs from story-data.json")
    now = by_id.get(f"J-CH01-{scene_id[-3:]}-NOW")
    if not now or now["title"] != scene["title"]:
        fail(f"journal: Now entry for {scene_id} missing or not titled with the canon scene title")
    choice = catalog_scenes[scene_id]["choice"]
    for option in choice["options"]:
        if not any(e.get("option_id") == option["id"] and e["type"] == "decision" for e in entries):
            fail(f"journal: no decision entry for {option['id']}")

lid = by_id["J-CH01-S03-LID"]
if journal["drawer_lid_note"]["inscription"] != LID_INSCRIPTION:
    fail("drawer lid inscription differs from doc 24 section 4 clue 2")
if by_id[journal["chapter1_feedback"]]["body"] != FEEDBACK:
    fail("Chapter 1 feedback sentence differs from doc 24 section 2.10")
if by_id[journal["alo_lost_debrief"]]["body"] != ALO_LOST:
    fail("Alo Lost text differs from doc 24 section 2.10")
for eid in journal["growth_record_templates"] + journal["resume_templates"] + by_id[journal["alo_lost_debrief"]]["panels"]:
    if eid not in by_id:
        fail(f"journal: index id {eid} does not resolve")
if len(journal["resume_templates"]) != 6:
    fail("resume card must have six line templates (doc 24 section 6.6)")

# ---------------------------------------------------------------- story_echoes checks
rows = echoes["entries"]
row_ids = [r["id"] for r in rows]
if len(row_ids) != len(set(row_ids)):
    fail("echoes: duplicate ids")
if {d["id"] for d in echoes["decisions"]} != {"D1", "D2"}:
    fail("echoes: decisions must be exactly D1 and D2")
nested = [r for opts in echoes["choices"].values() for rs in opts.values() for r in rs] + \
         [r for rs in echoes["moments"].values() for r in rs]
if sorted(json.dumps(r, sort_keys=True) for r in nested) != sorted(json.dumps(r, sort_keys=True) for r in rows):
    fail("echoes: choices/moments maps and entries list differ")
for d in echoes["decisions"]:
    if d["choice_id"] not in choice_options:
        fail(f"{d['id']}: unknown choice {d['choice_id']}")
    for oid, opt in d["options"].items():
        if oid not in choice_options.get(d["choice_id"], set()):
            fail(f"{d['id']}: unknown option {oid}")
        for echo_id in opt["echo_ids"]:
            if echo_id not in row_ids:
                fail(f"{d['id']}: echo {echo_id} not listed")
for r in rows:
    if r["scene_id"] not in story_scenes:
        fail(f"{r['id']}: scene_id {r['scene_id']} not in story-data.json")
    if r["kind"] not in {"object", "journal", "photo", "staging"}:
        fail(f"{r['id']}: kind {r['kind']}")
    if r["choice_id"] and r["option_id"] not in choice_options.get(r["choice_id"], set()):
        fail(f"{r['id']}: unknown option {r['option_id']}")
    if list(story_scenes).index(r["scene_id"]) <= list(story_scenes).index(r["source_scene_id"]):
        fail(f"{r['id']}: echo is not after its source scene")
    for text in (r["text"], r.get("body", ""), r.get("title", "")):
        for word in BANNED + ["NASA"]:
            if word in text:
                fail(f"{r['id']}: contains '{word}'")
        if re.search(r"[ঀ-৿]", text):
            fail(f"{r['id']}: Bangla script")
    if sentences(r["text"]) > 2:
        fail(f"{r['id']}: more than two sentences")

# ---------------------------------------------------------------- report
print("M1-50 text check: journal_text.json and story_echoes.json")
print(f"journal entries: {len(entries)}  echo rows: {len(rows)}  gate-catalog targets: {len(all_targets)}")
by_type: dict[str, int] = {}
for e in entries:
    by_type[e["type"]] = by_type.get(e["type"], 0) + 1
print("entries by type: " + ", ".join(f"{k} {v}" for k, v in sorted(by_type.items())))
print()
print("journal entry ids (id | scene_id in story-data.json | trigger):")
for e in entries:
    trig = e["trigger"]
    detail = trig.get("target_id") or trig.get("option_id") or trig.get("moment_id") or trig.get("stage") or trig.get("outcome") or trig.get("rule") or trig.get("scene_id") or ""
    print(f"  {e['id']} | {e['scene_id']} {'ok' if e['scene_id'] in story_scenes else 'MISSING'} | {trig['on']} {detail}".rstrip())
print()
print("echo ids (id | source -> scene | kind):")
for r in rows:
    print(f"  {r['id']} | {r['source_scene_id']} -> {r['scene_id']} {'ok' if r['scene_id'] in story_scenes else 'MISSING'} | {r['kind']}")
print()
hard = sorted(((fk_grade(e["body"]), e["id"]) for e in entries if e["body"] and not e["body"].startswith("{")), reverse=True)
grades = [g for g, _ in hard]
print(f"readability (Flesch-Kincaid grade, guide only): mean {sum(grades) / len(grades):.1f}; hardest five: " +
      ", ".join(f"{i} {g:.1f}" for g, i in hard[:5]))
print(f"banned words {BANNED} in any body: {'none' if not any('contains' in f for f in failures) else 'FOUND'}")
print()
if failures:
    print(f"FAIL: {len(failures)} problem(s)")
    for f in failures:
        print("  - " + f)
else:
    print("PASS: every check passed")

if "--review" in sys.argv:
    tab_order = ["now", "evidence", "garden", "decisions", "people", "science"]
    lines = ["# M1-50 — Chapter 1 journal text for Sadman to read", "",
             "Generated by `production/qa/evidence/M1-50_text_check.py --review` from "
             "`game/resources/campaign/content/journal_text.json` and `story_echoes.json`. "
             "All of it is new written world text (`TEXT`, doc 24); nothing here is spoken.", ""]
    for surface, heading in [("journal", None), ("p02_preview", "P-02 preview feedback"), ("chapter_debrief", "Alo Lost debrief"),
                             ("resume_card", "Resume card line templates"), ("growth_record", "Growth Record templates")]:
        group = [e for e in entries if e["surface"] == surface]
        if surface == "journal":
            for tab in tab_order:
                rows_tab = [e for e in group if e["tab"] == tab]
                if not rows_tab:
                    continue
                lines += [f"## {tab.capitalize()} tab ({len(rows_tab)})", ""]
                for e in rows_tab:
                    lines.append(f"- **{e['title']}** ({e['scene_id']}, {e['type']}, {e['status']}) — {e['body']}")
                    if e.get("completed_text"):
                        lines.append(f"  - Done: {e['completed_text']}")
                lines.append("")
        else:
            lines += [f"## {heading} ({len(group)})", ""]
            for e in group:
                lines.append(f"- **{e['title']}** — {e['body']}")
                if e.get("body_template"):
                    lines.append(f"  - Template: {e['body_template']}")
                for slot, words in e.get("placeholders", {}).items():
                    for key, text in words.items():
                        lines.append(f"  - `{slot}` = {key}: {text}")
            lines.append("")
    lines += ["## Drawer-lid inscription (pencil, inside the lid)", "", f"> {journal['drawer_lid_note']['inscription']}", ""]
    lines += [f"## Story echoes ({len(rows)})", ""]
    for r in rows:
        lines.append(f"- **{r['title']}** ({r.get('choice_id') or r.get('moment_id')} {r.get('option_id', '')} → {r['scene_id']}, {r['kind']}) — {r['text']}")
    REVIEW.write_text("\n".join(lines) + "\n")
    print(f"wrote {REVIEW.relative_to(ROOT)}")

sys.exit(1 if failures else 0)
