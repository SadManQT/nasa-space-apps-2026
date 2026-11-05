#!/usr/bin/env python3
"""Compose the M3-7A review sheets from the Cycles previews build_chapter7_assets.py renders.

    python3 production/tools/chapter7_contact.py

Reads production/models/chapter7/preview/*.png and game/assets/props/chapter7_assets.json, writes
  production/qa/evidence/M3-7A_contact.png   every asset at the game LOD with id, size, triangles, scenes and notes
  production/qa/evidence/M3-7A_states.png    the story states: markers seated, case open (15 + 15), seed macro,
                                             wall plates face-on, the bench worktop, the relief from above
  production/qa/evidence/M3-7A_lods.png      LOD0 above LOD1 (Compatibility) for every asset
(production/review/ belongs to the science and QA reviewer, so the sheets sit with the task's other evidence.)
"""
import json
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
PREVIEW = ROOT / "production/models/chapter7/preview"
CATALOG = ROOT / "game/assets/props/chapter7_assets.json"
REVIEW = ROOT / "production/qa/evidence"
FONT = "/System/Library/Fonts/Helvetica.ttc"
NAVY, ORANGE, WHITE, GREY = (31, 42, 68), (242, 107, 33), (236, 238, 240), (120, 124, 130)


def font(size):
    return ImageFont.truetype(FONT, size)


def tile(path, w, h=None):
    h = h or w
    im = Image.open(path).convert("RGB")
    im.thumbnail((w, h))
    canvas = Image.new("RGB", (w, h), (158, 160, 165))
    canvas.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    return canvas


def header(draw, width, text, sub):
    draw.rectangle((0, 0, width, 64), fill=NAVY)
    draw.text((20, 12), text, font=font(26), fill=WHITE)
    draw.text((20, 42), sub, font=font(15), fill=(200, 205, 215))


def badge(draw, x, y, n):
    draw.ellipse((x + 8, y + 8, x + 44, y + 44), fill=ORANGE, outline=NAVY, width=2)
    draw.text((x + 26 - draw.textlength(n, font=font(22)) / 2, y + 13), n, font=font(22), fill=WHITE)


def contact(assets):
    cell, pad, cap = 420, 16, 126
    cols = 3
    rows = (len(assets) + cols - 1) // cols
    width = cols * (cell + pad) + pad
    height = 64 + rows * (cell + cap + pad) + pad + 40
    sheet = Image.new("RGB", (width, height), WHITE)
    draw = ImageDraw.Draw(sheet)
    header(draw, width, "LAST LIGHT ACADEMY  |  Chapter 7 storm shelter and uplink props, EN_Fabrication (M3-7A)",
           "Blender 5.2 Cycles previews of the game LOD, neutral studio light. Kit materials (M1-04/M1-05); no text or logos baked; screens are live-UI slots.")
    for i, a in enumerate(assets):
        x = pad + (i % cols) * (cell + pad)
        y = 64 + pad + (i // cols) * (cell + cap + pad)
        sheet.paste(tile(PREVIEW / f"{a['id']}_LOD0.png", cell), (x, y))
        draw.rectangle((x, y, x + cell, y + cell), outline=GREY, width=1)
        badge(draw, x, y, str(i + 1))
        s = a["size_m"]
        draw.text((x, y + cell + 6), a["id"], font=font(19), fill=NAVY)
        draw.text((x, y + cell + 30), f"{a['display']}  |  {s[0]:.2f} x {s[1]:.2f} x {s[2]:.2f} m", font=font(14), fill=(60, 64, 72))
        draw.text((x, y + cell + 50), f"LOD0 {a['triangles'][0]} tris, LOD1 {a['triangles'][1]}  |  {a['mount']} y {a['mount_y']:.2f}  |  front {a['front']}  |  {', '.join(s_.replace('EX-', '') for s_ in a['scenes'][:3])}", font=font(13), fill=(60, 64, 72))
        for k, line in enumerate(textwrap.wrap(a["notes"], 66)[:3]):
            draw.text((x, y + cell + 70 + 15 * k), line, font=font(12), fill=GREY)
    draw.text((pad, height - 32), "Gate: production/review/asset_verification.md. Godot captures: production/qa/evidence/M3-7A_godot_*.png. Science data of the relief: chapter7_assets.json route_simulator.", font=font(13), fill=GREY)
    out = REVIEW / "M3-7A_contact.png"
    sheet.save(out)
    print("wrote", out.relative_to(ROOT), sheet.size)


STATES = [
    ("PR_ShelterDiagram_placed.png", "S02: five role-colour markers seated on the plan (Kai, Amara, Mei, Rafi, Ferreira); hatch side kept clear"),
    ("PR_SeedCase_open.png", "S04: the founder case open: two compartments, latch released, inner seal lids up"),
    ("PR_SeedCase_compartment_top.png", "One compartment from above: 3 x 5 = 15 vials"),
    ("PR_SeedCase_seed_macro.png", "Macro: one seed (about 2 mm) in each clear vial, nothing more"),
    ("PR_ValveDiagram_front.png", "S04: reservoir, six water units, pump, supply and return valves, return-time selector"),
    ("PR_TelemetryDisplay_front.png", "S06: systems and garden screens with the six ledger lamps E A H C R Z"),
    ("PR_NetworkDiagnostic_front.png", "S09: local network / feedthrough / dish mimic, three test buttons, isolation key, data card"),
    ("EN_Fabrication_Bench_worktop.png", "S11: battery cradle, echo test unit, connector tray, checklist"),
    ("EN_Fabrication_RouteSimulator_relief.png", "S11: the LOLA relief, the computed road, the pins on R1-R3"),
]


def states():
    cell, pad, cap = 420, 16, 46
    cols = 3
    rows = (len(STATES) + cols - 1) // cols + 1
    width = cols * (cell + pad) + pad
    height = 64 + (rows - 1) * (cell + cap + pad) + 520 * width // 1440 + cap + 2 * pad + 40
    sheet = Image.new("RGB", (width, height), WHITE)
    draw = ImageDraw.Draw(sheet)
    header(draw, width, "Chapter 7 assets  |  story states (M3-7A)",
           "The states each scene needs, posed with the same nodes chapter7_assets.gd drives in Godot.")
    for i, (name, caption) in enumerate(STATES):
        x = pad + (i % cols) * (cell + pad)
        y = 64 + pad + (i // cols) * (cell + cap + pad)
        sheet.paste(tile(PREVIEW / name, cell), (x, y))
        draw.rectangle((x, y, x + cell, y + cell), outline=GREY, width=1)
        for k, line in enumerate(textwrap.wrap(caption, 62)[:2]):
            draw.text((x, y + cell + 6 + 18 * k), line, font=font(14), fill=NAVY)
    y = 64 + pad + (len(STATES) + cols - 1) // cols * (cell + cap + pad)
    wide = width - 2 * pad
    sheet.paste(tile(PREVIEW / "EN_Fabrication_RouteSimulator_top.png", wide, 520 * wide // 1440), (pad, y))
    draw.text((pad, y + 520 * wide // 1440 + 6), "The relief from above: NASA LRO LOLA 80 m heights, 1:90,000, vertical exaggeration 2. Aurora left, the Malapert summit right, the computed surveyed road in orange, pins on the three pads.", font=font(14), fill=NAVY)
    out = REVIEW / "M3-7A_states.png"
    sheet.save(out)
    print("wrote", out.relative_to(ROOT), sheet.size)


def lods(assets):
    cell, pad = 300, 16
    cols = len(assets)
    width = cols * (cell + pad) + pad
    height = 64 + 2 * cell + 4 + 56 + 2 * pad
    sheet = Image.new("RGB", (width, height), WHITE)
    draw = ImageDraw.Draw(sheet)
    header(draw, width, "Chapter 7 assets  |  LOD0 (top) against LOD1 Compatibility (bottom)",
           "LOD1 drops small details and segments and uses the kit's 512 px textures (the relief 1024 px); the switch distance is per asset in chapter7_assets.json.")
    for i, a in enumerate(assets):
        x = pad + i * (cell + pad)
        y = 64 + pad
        sheet.paste(tile(PREVIEW / f"{a['id']}_LOD0.png", cell), (x, y))
        sheet.paste(tile(PREVIEW / f"{a['id']}_LOD1.png", cell), (x, y + cell + 4))
        draw.text((x, y + 2 * cell + 10), a["id"].replace("EN_Fabrication_", "Fab ").replace("PR_", ""), font=font(16), fill=NAVY)
        draw.text((x, y + 2 * cell + 32), f"{a['triangles'][0]} / {a['triangles'][1]} tris, switch {a['lod_distance_m']:.0f} m", font=font(13), fill=(60, 64, 72))
    out = REVIEW / "M3-7A_lods.png"
    sheet.save(out)
    print("wrote", out.relative_to(ROOT), sheet.size)


def main():
    assets = json.loads(CATALOG.read_text(encoding="utf-8"))["assets"]
    contact(assets)
    states()
    lods(assets)


if __name__ == "__main__":
    main()
