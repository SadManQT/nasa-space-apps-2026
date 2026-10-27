#!/usr/bin/env python3
"""Build production/ASSET_REGISTRY.csv: one row per asset, made or planned, so people and AI
tools can find any asset, its source, its game path and its verification status in one place.

  python3 production/tools/build_registry.py

Sources: production/manifest/{characters,tripo_props_batch1,reuse_props,planned_assets}.csv,
the files in game/assets/, production/review/asset_verification.md (automated gate) and
production/review/visual_review.md. An asset is "verified" only when it passes both.
"""
import csv, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
M = ROOT / "production/manifest"
CAT = {"CH": "characters", "PL": "plants", "PR": "props", "VH": "vehicles", "EN": "environment"}

verdict = {}
report = ROOT / "production/review/asset_verification.md"
if report.exists():
    for m in re.finditer(r"^\| (\w+) \| (✅ PASS|❌ FAIL|⬜[^|]*)", report.read_text(), re.M):
        verdict[m.group(1)] = "pass" if "PASS" in m.group(2) else "fail" if "FAIL" in m.group(2) else ""

visual = {}
review = ROOT / "production/review/visual_review.md"
if review.exists():
    for m in re.finditer(r"^\| (\w+) \| ([^|]+)\|", review.read_text(), re.M):
        # first table only: the second-opinion tables further down reuse asset names
        visual.setdefault(m.group(1), "fix" if "FIX" in m.group(2) else "pass" if "PASS" in m.group(2) else "")

rows = []
for manifest in ("characters", "tripo_props_batch1", "reuse_props"):
    for r in csv.DictReader(open(M / f"{manifest}.csv")):
        n = r["name"]
        cat = CAT.get(n[:2], "misc")
        glb = ROOT / f"game/assets/{cat}/{n}/{n}.glb"
        status = ("failed check" if verdict.get(n) == "fail" else "needs fix (visual)" if visual.get(n) == "fix"
                  else "verified" if verdict.get(n) == "pass" and visual.get(n) == "pass"
                  else "awaiting visual review" if verdict.get(n) == "pass"
                  else "in game, unchecked" if glb.exists() else "in progress")
        rows.append([n, cat, status, f"game/assets/{cat}/{n}/{n}.glb" if glb.exists() else "",
                     r["concept_or_source"], f'{r["size_flag"][2:]} {r["size_m"]} m, {r["tris"]} tris, {r["tex"]} px',
                     f"manifest/{manifest}.csv", r.get("notes", "")])
for r in csv.DictReader(open(M / "planned_assets.csv")):
    rows.append([r["name"], r["category"], "planned", "", r["method"], "", "manifest/planned_assets.csv",
                 f'first used {r["first_scenes"]}; {r["notes"]}'])

out = ROOT / "production/ASSET_REGISTRY.csv"
with open(out, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["name", "category", "status", "game_path", "source", "spec", "defined_in", "notes"])
    w.writerows(sorted(rows, key=lambda r: (r[1], r[0])))
counts = {}
for r in rows:
    counts[r[2]] = counts.get(r[2], 0) + 1
print(f"{out.relative_to(ROOT)}: {len(rows)} assets", counts)
