#!/usr/bin/env python3
"""Visual-review sheets: for every finished asset, its concept beside its front and 3/4 renders
(and, for characters, the pose test that shows whether skinning survived).

  python3 -I production/tools/contact_sheet.py

Writes production/review/contact_<category>.png (one row per asset). Concepts come from the
manifests; reused assets have no concept, so their cell is left blank.
"""
import csv
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
P = ROOT / "production"
CAT = {"CH": "characters", "PL": "plants", "PR": "props", "VH": "vehicles", "EN": "environment"}
S = 300


def concept_of(row):
    src = row["concept_or_source"]
    if src.endswith(".glb"):
        return None
    p = P / src
    return p / "front.png" if p.is_dir() else p


rows = {}
for m in ("characters", "tripo_props_batch1", "reuse_props"):
    for r in csv.DictReader(open(P / f"manifest/{m}.csv")):
        rows[r["name"]] = r

by_cat = {}
for name in sorted(rows):
    prev = P / f"models/final/{name}/preview"
    if (prev / "final_34.png").exists():
        by_cat.setdefault(CAT.get(name[:2], "misc"), []).append(name)

for cat, names in by_cat.items():
    sheet = Image.new("RGB", (S * 4, len(names) * (S + 22)), (38, 38, 38))
    d = ImageDraw.Draw(sheet)
    for i, name in enumerate(names):
        y = i * (S + 22)
        r = rows[name]
        d.text((6, y + 4), f"{name}   ({r['size_flag'][2:]} {r['size_m']} m, {r['tris']} tris, {r['tex']} px)", fill=(255, 255, 255))
        cells = [concept_of(r), P / f"models/final/{name}/preview/final_front.png", P / f"models/final/{name}/preview/final_34.png",
                 P / f"models/final/{name}/preview/posetest_34.png"  # characters: pose test
                 if name.startswith("CH_") else P / f"models/final/{name}/preview/final_top34.png"]  # others: from above
        for j, f in enumerate(cells):
            if f and f.exists():
                im = Image.open(f).convert("RGB")
                im.thumbnail((S, S))
                sheet.paste(im, (j * S + (S - im.width) // 2, y + 22 + (S - im.height) // 2))
    out = P / f"review/contact_{cat}.png"
    sheet.save(out)
    print(out.relative_to(ROOT), len(names), "assets")
