#!/usr/bin/env python3
"""Compose the M3-4A Chapter 4 approval sheets from the Cycles previews of production/tools/build_ch04_assets.py and the
LOLA survey of production/tools/coldtrap_survey.py (no image generation, no credits).

    python3 production/tools/ch04_sheets.py

Writes production/concept/chapter4_v1/:
  M3-4A_EN_Garage_sheet.png     LOC-08: exterior, bay and ready-room views, cutaway, measured plan and section, pieces
  M3-4A_EN_ColdTrap_sheet.png   LOC-09/LOC-10: map of the real road with the computed beacon chain and the dated light,
                                road profile, the three views, the vault-shelf plan, pieces and the vault set
  00_Approval_Sheet.png         both assets and the numbered decisions on one page
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_terrain as mt  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
PREVIEW = ROOT / "production/models/ch04/preview"
STAGE = ROOT / "production/models/ch04"
OUT = ROOT / "production/concept/chapter4_v1"
FONT = "/System/Library/Fonts/Helvetica.ttc"
NAVY, ORANGE, WHITE, PAPER, GOLD = (31, 42, 68), (242, 107, 33), (236, 238, 240), (246, 246, 244), (242, 194, 48)
INK, SOFT = (40, 44, 52), (96, 100, 108)
ROLE = dict(Kai=(242, 107, 33), Amara=(32, 184, 201), Mei=(76, 175, 80), Rafi=(142, 92, 194), Ferreira=(184, 160, 106))


def font(size, bold=False):
    return ImageFont.truetype(FONT, size, index=1 if bold else 0)


def fit(path, w, h):
    im = Image.open(path).convert("RGB")
    im.thumbnail((w, h), Image.LANCZOS)
    return im


def cover(path, w, h):
    """Scale to cover w x h and centre-crop."""
    im = Image.open(path).convert("RGB")
    s = max(w / im.width, h / im.height)
    im = im.resize((max(w, round(im.width * s)), max(h, round(im.height * s))), Image.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


def wrap(draw, text, width, fnt):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=fnt) <= width:
            cur = t
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def text_block(draw, x, y, width, text, size=15, fill=INK, bold=False, gap=4):
    f = font(size, bold)
    for para in text.split("\n"):
        for line in wrap(draw, para, width, f):
            draw.text((x, y), line, fill=fill, font=f)
            y += size + gap
    return y


def title_bar(draw, width, text, sub, h=96):
    draw.rectangle([0, 0, width, h], fill=NAVY)
    draw.text((28, 14), text, fill=WHITE, font=font(34, True))
    draw.text((28, 60), sub, fill=(200, 206, 220), font=font(17))


def panel(sheet, draw, im, x, y, caption, size=15):
    sheet.paste(im, (x, y))
    draw.rectangle([x, y, x + im.width, y + im.height], outline=(190, 192, 196))
    return text_block(draw, x, y + im.height + 6, im.width, caption, size=size, fill=(60, 64, 72)) + 8


def tile(sheet, draw, name, x, y, size, heading, lines):
    p = PREVIEW / f"{name}.png"
    im = fit(p, size, size) if p.exists() else Image.new("RGB", (size, size), (200, 200, 200))
    sheet.paste(im, (x + (size - im.width) // 2, y + (size - im.height) // 2))
    draw.rectangle([x, y, x + size, y + size], outline=(190, 192, 196))
    draw.text((x, y + size + 5), heading, fill=NAVY, font=font(15, True))
    for k, line in enumerate(lines):
        draw.text((x, y + size + 25 + 16 * k), line, fill=(60, 64, 72), font=font(13))

# ----------------------------------------------------------------------------------------------- garage drawings

def garage_plan(layout, scale=66, width=1000):
    """Top-down plan of LOC-08 from garage_layout.json (Godot x right, z down the page from the ready room's back
    wall): ready room, pressure wall pieces, the vacuum bay with the porch, the rover's body and wheel track, the
    docking tunnel, numbered anchors, dimensions."""
    W, D = layout["bounds_m"]
    mx, top = (width - W * scale) / 2, 92
    h = int(top + D * scale + 260)
    img = Image.new("RGB", (width, h), PAPER)
    d = ImageDraw.Draw(img)

    def P(x, z):
        return (mx + x * scale, top + z * scale)

    def rect(x0, z0, x1, z1, fill=None, outline=None, w=1):
        d.rectangle([*P(x0, z0), *P(x1, z1)], fill=fill, outline=outline, width=w)
    d.text((mx, 14), "Plan on the 1 m grid: 12 x 9 m (Godot x right, z down the page)", fill=NAVY, font=font(19, True))
    d.text((mx, 40), "blue: pressurised ready room, deck +1.40 m   sand: vacuum rover bay, floor 0.00, clear 5.60 m", fill=SOFT, font=font(14))
    d.text((mx, 58), "orange: doors, hatch, dock   purple: cargo lock   green: furniture   grey: EVA porch +1.40 m", fill=SOFT, font=font(14))
    zb = 3.15
    rect(0, 0, W, 3.0, fill=(226, 234, 246))
    rect(0, zb, W, D, fill=(244, 236, 222))
    rect(0, zb, layout["section"]["porch_x"], D, fill=(214, 216, 220))
    for k in range(int((D - zb) / 0.25)):
        z = zb + k * 0.25
        d.line([P(0.05, z), P(layout["section"]["porch_x"] - 0.05, z)], fill=(196, 198, 202))
    for x in range(int(W) + 1):
        d.line([P(x, 0), P(x, D)], fill=(222, 222, 220))
    for z in range(int(D) + 1):
        d.line([P(0, z), P(W, z)], fill=(222, 222, 220))
    rect(0, 3.0, W, zb, fill=(70, 76, 88))
    rect(-0.15, -0.15, W + 0.15, 0.0, fill=(70, 76, 88))
    rect(-0.15, -0.15, 0.0, D + 0.1, fill=(70, 76, 88))
    rect(W, -0.15, W + 0.15, zb, fill=(70, 76, 88))
    rect(0, D, W, D + 0.12, fill=(110, 116, 128))
    door = layout["section"]["door"][0]
    zc = zb + (D - zb) / 2
    rect(W, zb, W + 0.15, zc - door / 2, fill=(110, 116, 128))
    rect(W, zc + door / 2, W + 0.15, D + 0.12, fill=(110, 116, 128))
    d.line([P(W + 0.07, zc - door / 2), P(W + 0.07, zc + door / 2)], fill=ORANGE, width=4)
    rv = layout["rover"]
    cx, cz = rv["centre"][0], rv["centre"][2]
    rect(cx - 3.0, cz - 2.33, cx + 3.0, cz + 2.33, outline=(150, 150, 150))
    for wx in (cx - 2.4, cx, cx + 2.4):
        for wz in (cz - 2.0, cz + 2.0):
            rect(wx - 0.6, wz - 0.33, wx + 0.6, wz + 0.33, fill=(170, 170, 172))
    d.rounded_rectangle([*P(cx - 2.95, cz - 1.42), *P(cx + 2.95, cz + 1.42)], radius=int(0.9 * scale), fill=(250, 250, 250), outline=(120, 120, 124), width=2)
    d.polygon([P(cx + 2.3, cz - 0.4), P(cx + 2.8, cz), P(cx + 2.3, cz + 0.4)], fill=(150, 150, 154))
    d.text(P(cx - 1.4, cz - 0.15), "VH_Rover 6.0 x 4.66 m", fill=INK, font=font(14, True))
    hx = rv["hatch"][0]
    rect(hx - 0.45, zb, hx + 0.45, rv["hatch"][2], fill=ORANGE)
    rect(1.64, 2.66, 2.36, 3.45, fill=(142, 92, 194))
    for x0, x1 in ((2.65, 4.35), (4.65, 6.35), (9.65, 11.35), (6.72, 7.28)):
        d.line([P(x0, 3.07), P(x1, 3.07)], fill=(120, 190, 230), width=5)
    rect(0.6, 2.86, 1.4, 3.0, fill=(142, 92, 194))
    furniture = [(7.6, 0.17, 9.4, 0.89, "console"), (9.4, 0.17, 10.6, 0.77, "relief locker"), (11.23, 0.5, 11.83, 2.5, "rack")]
    for x0, z0, x1, z1, label in furniture:
        rect(x0, z0, x1, z1, fill=(76, 175, 80), outline=(40, 120, 50))
    d.text(P(7.65, 0.95), "handover console", fill=INK, font=font(12))
    d.text(P(9.45, 0.82), "relief locker", fill=INK, font=font(12))
    d.text(P(10.0, 2.62), "cargo rack + ledger", fill=INK, font=font(12))
    for x0, x1, label in ((3.5, 5.5, "route board"), (5.5, 6.5, "dep. A"), (6.5, 7.5, "dep. B"), (10.5, 11.5, "pad cam")):
        rect(x0 + 0.04, -0.12, x1 - 0.04, 0.0, fill=(32, 120, 200))
        d.text(P(x0 + 0.08, 0.06), label, fill=(32, 90, 160), font=font(12))
    rect(1.9, -0.15, 3.1, 0.0, fill=ORANGE)
    d.text(P(1.75, 0.06), "inner door", fill=(180, 80, 20), font=font(12))
    d.text(P(0.08, 2.45), "suit seals", fill=(110, 60, 160), font=font(12))
    d.text(P(1.55, 3.55), "cargo lock", fill=(110, 60, 160), font=font(12))
    d.text(P(hx - 0.55, 2.55), "docking port", fill=(180, 80, 20), font=font(12))
    d.text(P(0.15, 8.55), "EVA porch +1.40", fill=INK, font=font(13, True))
    d.text(P(W - 2.6, D - 0.55), "rover door 5.55 m", fill=(180, 80, 20), font=font(12))
    d.text(P(0.15, 0.62), "ready room 12 x 3 m, habitat air", fill=(60, 80, 120), font=font(14, True))
    d.text(P(5.2, 8.35), "rover bay (vacuum)", fill=(140, 110, 70), font=font(15, True))
    anchors = list(layout["anchors"].items())
    for k, (name, (x, y, z)) in enumerate(anchors, 1):
        px, py = P(x, z)
        d.ellipse([px - 9, py - 9, px + 9, py + 9], fill=NAVY)
        d.text((px, py), str(k), fill=WHITE, font=font(11, True), anchor="mm")
    y = top + D * scale + 18
    d.line([P(0, D + 0.25)[0], y, P(W, D + 0.25)[0], y], fill=INK, width=2)
    d.text(((P(0, 0)[0] + P(W, 0)[0]) / 2, y + 4), "12.00 m", fill=INK, font=font(13, True), anchor="mt")
    xr = P(W, 0)[0] + 26
    d.line([xr, P(0, 0)[1], xr, P(0, D)[1]], fill=INK, width=2)
    d.text((xr + 4, (P(0, 0)[1] + P(0, D)[1]) / 2), "9.00 m", fill=INK, font=font(13, True))
    y += 30
    d.text((mx, y), "Anchors", fill=NAVY, font=font(15, True))
    y += 22
    for k, (name, _) in enumerate(anchors, 1):
        col, row = (k - 1) % 3, (k - 1) // 3
        d.text((mx + col * 300, y + row * 18), f"{k}  {name.replace('_', ' ')}", fill=INK, font=font(13))
    return img


def garage_section(sec, scale=56, width=1000, height=600):
    """Section across the bay at the docking port (looking along +x): bay floor, ready-room deck on its plinth, the
    rover's hatch level with the dock, the vacuum bay's height, the regolith berm."""
    img = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(img)
    ox, oy = 190, height - 52

    def P(z, y):
        return (ox + z * scale, oy - y * scale)
    d.text((24, 14), "Section at the docking port (z across the bay, heights from the bay floor)", fill=NAVY, font=font(19, True))
    deck, ready, bay = sec["deck_y"], sec["ready_height"], sec["bay_height"]
    d.polygon([P(-0.6, bay), P(-0.6, bay + 1.0), P(9.6, bay + 1.0), P(9.6, bay)], fill=(170, 166, 160))
    d.text(P(3.6, bay + 0.75), "regolith berm 1 m (35 deg sides)", fill=INK, font=font(13))
    d.rectangle([*P(-0.15, deck), *P(3.15, 0)], fill=(120, 118, 116))
    d.text(P(0.3, deck * 0.55), "sintered plinth", fill=WHITE, font=font(13))
    d.rectangle([*P(0, deck + ready), *P(3.0, deck)], fill=(226, 234, 246), outline=(90, 110, 150), width=2)
    d.text(P(0.25, deck + ready * 0.55), "ready room", fill=(60, 80, 120), font=font(15, True))
    d.text(P(0.25, deck + ready * 0.55 - 0.32), "habitat air, 2.60 m", fill=(60, 80, 120), font=font(13))
    d.rectangle([*P(3.0, deck + ready), *P(3.15, 0)], fill=(70, 76, 88))
    d.rectangle([*P(3.15, bay), *P(9.0, 0)], outline=(150, 130, 100), width=2)
    d.line([P(3.15, bay), P(9.0, bay)], fill=(120, 120, 124), width=4)
    d.text(P(6.6, bay - 0.35), "vacuum bay, clear 5.60 m", fill=(140, 110, 70), font=font(15, True))
    sill = deck + sec["dock_sill"]
    tl = sec["tunnel_l"]
    d.rectangle([*P(3.15, sill + sec["dock_h"]), *P(3.15 + tl, sill)], fill=(242, 160, 110), outline=ORANGE, width=2)
    d.text(P(3.2, sill + sec["dock_h"] + 0.35), "docking tunnel", fill=(180, 80, 20), font=font(13, True))
    zc = 3.15 + tl + 1.42
    d.ellipse([*P(zc - 1.42, 3.95), *P(zc + 1.42, 1.45)], fill=(250, 250, 250), outline=(120, 120, 124), width=2)
    for wz in (zc - 2.0, zc + 2.0):
        d.ellipse([*P(wz - 0.33, 1.25), *P(wz + 0.33, 0.0)], fill=(170, 170, 172), outline=(120, 120, 124))
    d.line([P(zc - 1.4, 1.45), P(zc - 2.0, 0.65)], fill=(120, 120, 124), width=3)
    d.line([P(zc + 1.4, 1.45), P(zc + 2.0, 0.65)], fill=(120, 120, 124), width=3)
    d.text(P(zc - 0.75, 2.75), "VH_Rover", fill=INK, font=font(14, True))
    hz0, hz1 = sec["rover_hatch_m"]
    d.line([P(zc - 1.42, hz0), P(zc - 1.42, hz1)], fill=ORANGE, width=6)
    for yv, label in ((0.0, "0.00 bay floor"), (deck, f"+{deck:.2f} deck"), (sill, f"+{sill:.2f} hatch sill"), (deck + ready, f"+{deck + ready:.2f} ceiling"), (bay, f"+{bay:.2f} roof")):
        d.line([P(-0.6, yv), P(-0.25, yv)], fill=INK, width=2)
        d.text((P(-0.62, yv)[0] - 6, P(0, yv)[1]), label, fill=INK, font=font(12), anchor="rm")
    d.line([P(0, -0.35), P(9.0, -0.35)], fill=INK, width=1)
    for zv, label in ((0, "0"), (3.0, "3.00"), (3.15 + tl, f"{3.15 + tl:.2f}"), (9.0, "9.00")):
        d.line([P(zv, -0.25), P(zv, -0.45)], fill=INK, width=2)
        d.text(P(zv, -0.5), label, fill=INK, font=font(12), anchor="mt")
    notes = ("The rover's side hatches sit 1.85-2.96 m up (measured on VH_Rover), so the ready-room deck stands 1.40 m "
             "above the bay floor like a loading dock: the 0.90 x 1.15 m dock hatch meets the cabin sill with a 0.45 m step. "
             "The EVA porch at the rover's rear is at the same height for the two suitports and the cargo lock.")
    text_block(d, 24, 44, width - 48, notes, size=13, fill=SOFT)
    return img

# ----------------------------------------------------------------------------------------------- cold-trap drawings

def coldtrap_map(survey, width=2140, height=640):
    """The real road from Aurora to the cold trap on the 20 m LOLA grid, hillshaded with the dated Sun of EX-CH04-S04
    (21 Oct 2046 08:00 UTC, JPL Horizons) and hard cast shadows: what is lit and what is dark at that hour; the
    permanently shadowed region from LPSR_80S_20MPP_ADJ; the road, the three 100 m segments, the computed beacon chain
    (chords) and the vault shelf."""
    pts = np.array(survey["road_cells_20m"])
    sites = mt.load_sites()["sites"]
    a, c = sites["aurora"], sites["cold_trap"]
    x0, x1 = min(pts[:, 0].min(), c["x_m"]) - 700, max(pts[:, 0].max(), c["x_m"]) + 700
    y0, y1 = min(pts[:, 1].min(), c["y_m"]) - 700, max(pts[:, 1].max(), c["y_m"]) + 700
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    big = 26000.0
    h, geo = mt.window_m("pgda90_20mpp", cx, cy, big)
    h = mt.fill_nan(h)
    mpp = geo["mpp"]
    row = next(r for r in json.loads((mt.GAME_LOLA / "sun_positions.json").read_text())["scene_lighting"] if r["scene"] == "EX-CH04-S04")
    sv = mt.sun_vector_map(cx, cy, row["sun_az_deg"], row["sun_el_deg"])
    hc = mt.curved(h, mpp, geo["center_col"], geo["center_row"])
    shade = mt.hillshade(hc, mpp, sv, shadows=True)
    psr, _ = mt.window_m("pgda90_20mpp_psr", cx, cy, big)
    psr = np.nan_to_num(psr) > 0.5
    c0 = int((x0 - geo["origin_x_m"]) / mpp)
    c1 = int((x1 - geo["origin_x_m"]) / mpp)
    r0 = int((geo["origin_y_m"] - y1) / mpp)
    r1 = int((geo["origin_y_m"] - y0) / mpp)
    sh = shade[r0:r1, c0:c1]
    hs = mt.hillshade_45(h[r0:r1, c0:c1], mpp)
    ps = psr[r0:r1, c0:c1]
    base = 0.22 + 0.30 * hs
    lit = np.clip(base * 0.30 + sh * 1.9, 0, 1)
    rgb = np.stack([lit, lit, lit * 1.02], axis=-1)
    rgb[ps] = rgb[ps] * np.array([0.55, 0.62, 0.95]) + np.array([0.02, 0.04, 0.16])
    img = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))
    sx = (width - 40) / img.width
    sy = (height - 120) / img.height
    s = min(sx, sy)
    img = img.resize((int(img.width * s), int(img.height * s)), Image.LANCZOS)
    canvas = Image.new("RGB", (width, height), PAPER)
    ox, oy = (width - img.width) // 2, 92
    canvas.paste(img, (ox, oy))
    d = ImageDraw.Draw(canvas)

    def P(x, y):
        return (ox + (x - x0) / mpp * s, oy + (y1 - y) / mpp * s)
    d.text((20, 12), "LOC-09 road on the real terrain: NASA LRO LOLA 20 m (PGDA 90), lit by the JPL Horizons Sun of EX-CH04-S04", fill=NAVY, font=font(20, True))
    d.text((20, 40), f"21 Oct 2046 08:00 UTC, Sun az {row['sun_az_deg']:.1f} deg, el {row['sun_el_deg']:.2f} deg, hard cast shadows (Computed). Blue: permanently shadowed region "
                     "(LPSR_80S_20MPP_ADJ). Orange: the 8.56 km slope-limited road (max 11.9 deg).", fill=SOFT, font=font(14))
    d.text((20, 60), "White chords: the beacon chain Aurora mast (10 m) -> B1 -> B2 -> B3 -> vault shelf, every chord clear of the curved terrain "
                     "(5 m beacon masts; weakest link 1.7 m). Thick bars: the three 100 m playable segments.", fill=SOFT, font=font(14))
    line = [P(q[0], q[1]) for q in pts]
    d.line(line, fill=ORANGE, width=4)
    nodes = [(a["x_m"], a["y_m"], "Aurora")] + [(b["x_m"], b["y_m"], b["id"]) for b in survey["beacons"]] + [(c["x_m"], c["y_m"], "vault shelf")]
    for (xa, ya, _), (xb, yb, _) in zip(nodes, nodes[1:]):
        d.line([P(xa, ya), P(xb, yb)], fill=WHITE, width=2)
    for b in survey["beacons"]:
        seg = [P(q[0], q[1]) for q in pts if b["segment"]["from_m"] - 1 <= q[3] <= b["segment"]["to_m"] + 1]
        if len(seg) > 1:
            d.line(seg, fill=(255, 220, 120), width=10)
    for x, y, label in nodes:
        px, py = P(x, y)
        r = 9
        fill = (60, 220, 110) if label.startswith("B") else (GOLD if label == "Aurora" else (120, 170, 255))
        d.ellipse([px - r, py - r, px + r, py + r], fill=fill, outline=NAVY, width=2)
        d.text((px + 12, py - 26), label, fill=WHITE, font=font(16, True), stroke_width=3, stroke_fill=NAVY)
    m = survey["m182_loc09_corner"]
    px, py = P(m["x_m"], m["y_m"])
    d.rectangle([px - 6, py - 6, px + 6, py + 6], outline=WHITE, width=2)
    d.text((px + 10, py + 6), "M1-82 LOC-09 point", fill=WHITE, font=font(13), stroke_width=2, stroke_fill=NAVY)
    for b in survey["beacons"]:
        px, py = P(b["x_m"], b["y_m"])
        d.text((px + 12, py - 6), f"{b['road_distance_m'] / 1000:.2f} km, {b['light']['sun_state']}", fill=WHITE, font=font(13), stroke_width=2, stroke_fill=NAVY)
    km = 1000 / mpp * s
    bx, by = ox + 20, oy + img.height - 30
    d.rectangle([bx, by, bx + km, by + 8], fill=WHITE, outline=NAVY)
    d.text((bx + km + 8, by - 4), "1 km", fill=WHITE, font=font(14, True), stroke_width=2, stroke_fill=NAVY)
    nv = np.array([cx, cy]) / math.hypot(cx, cy)
    ax0 = (ox + img.width - 60, oy + 70)
    d.line([ax0, (ax0[0] + nv[0] * 40, ax0[1] - nv[1] * 40)], fill=WHITE, width=3)
    d.text((ax0[0] + nv[0] * 52, ax0[1] - nv[1] * 52), "local N", fill=WHITE, font=font(13, True), anchor="mm", stroke_width=2, stroke_fill=NAVY)
    return canvas


def road_profile(survey, width=2140, height=380):
    pts = np.array(survey["road_cells_20m"])
    img = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(img)
    l, r, t, b = 90, width - 30, 60, height - 50
    dmax = pts[-1, 3]
    hmin, hmax = pts[:, 2].min() - 20, pts[:, 2].max() + 20

    def P(dd, hh):
        return (l + (dd / dmax) * (r - l), b - (hh - hmin) / (hmax - hmin) * (b - t))
    d.text((20, 12), "Road profile (Computed from LOLA): 8.56 km, 802 m descent, steepest 11.9 deg under the rover's 15 deg limit; canon keeps the "
                     "game's P-07 numbers (route B, 12 km, 30 + 30 of 100 units)", fill=NAVY, font=font(17, True))
    for b_ in survey["beacons"]:
        x0, x1 = P(b_["segment"]["from_m"], 0)[0], P(b_["segment"]["to_m"], 0)[0]
        lit = b_["light"]["sun_state"] == "lit"
        d.rectangle([x0 - 4, t, x1 + 4, b], fill=(255, 236, 170) if lit else (190, 196, 214))
        d.text(((x0 + x1) / 2, t - 4), f"{b_['id']} segment ({b_['light']['sun_state']})", fill=INK, font=font(13, True), anchor="mb")
    d.line([P(q[3], q[2]) for q in pts], fill=ORANGE, width=3)
    for b_ in survey["beacons"]:
        px, py = P(b_["road_distance_m"], b_["height_m"])
        d.line([px, py, px, py - 5 / (hmax - hmin) * (b - t) - 12], fill=(40, 160, 80), width=3)
        d.ellipse([px - 6, py - 6, px + 6, py + 6], fill=(60, 220, 110), outline=NAVY)
        d.text((px + 8, py + (6 if b_["id"] != "B2" else 26)), f"{b_['id']} {b_['road_distance_m'] / 1000:.2f} km, {b_['height_m']:.0f} m", fill=INK, font=font(12))
    for hh in range(int(hmin // 100 + 1) * 100, int(hmax), 100):
        y = P(0, hh)[1]
        d.line([l - 6, y, r, y], fill=(222, 222, 220))
        d.text((l - 10, y), f"{hh} m", fill=SOFT, font=font(12), anchor="rm")
    for k in range(0, int(dmax / 1000) + 1):
        x = P(k * 1000, hmin)[0]
        d.text((x, b + 8), f"{k} km", fill=SOFT, font=font(12), anchor="mt")
    end = pts[-1]
    px, py = P(end[3], end[2])
    d.text((px - 6, py - 20), "road ends at the PSR edge; the shelf is 510 m on, 50 m lower", fill=INK, font=font(12), anchor="rb")
    return img


def shelf_plan(width=1065, height=599, scale=28):
    """LOC-10 staging on the 20 x 15 m shelf (the renders use the same positions), labels on leader lines."""
    img = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(img)
    cx, cy = 404, 268

    def P(x, y):
        return (cx + x * scale, cy - y * scale)
    d.text((20, 12), "LOC-10 vault shelf, 20 x 15 m on the permanently shadowed floor (metres; same staging as the render)", fill=NAVY, font=font(16, True))
    d.rectangle([*P(-10, 7.5), *P(10, -7.5)], fill=(214, 218, 230), outline=(100, 110, 140), width=2)
    for k in range(-10, 11, 5):
        d.line([P(k, 7.5), P(k, -7.5)], fill=(196, 200, 212))
        d.text((P(k, -7.5)[0], P(k, -7.5)[1] + 4), f"{k}", fill=SOFT, font=font(11), anchor="mt")
    for k in range(-5, 6, 5):
        d.line([P(-10, k), P(10, k)], fill=(196, 200, 212))
    d.line([P(-1.6, 0.9), P(-1.0, -0.3)], fill=ORANGE, width=3)
    items = [((0.3, 0.5), (0.6, 0.39), (250, 250, 250), "vault V12 (as deposited)", (3.6, -2.6)),
             ((-1.0, -0.5), (0.86, 0.58), (190, 190, 196), "recovery carrier, tethered", (-9.6, -3.4)),
             ((1.6, 1.4), (0.22, 0.22), (220, 170, 40), "2034 marker + archival tag", (3.6, 4.6)),
             ((-1.6, 0.9), (0.22, 0.22), ORANGE, "tether anchor 1", (-9.6, 3.2)),
             ((2.4, -0.6), (0.22, 0.22), ORANGE, "tether anchor 2", (5.0, -0.8)),
             ((0.75, 0.15), (0.45, 0.08), (32, 42, 68), "thermal probe", (3.6, -4.6))]
    for (x, y), (w, h), col, label, (lx, ly) in items:
        d.rectangle([*P(x - w / 2, y + h / 2), *P(x + w / 2, y - h / 2)], fill=col, outline=NAVY)
        d.line([P(x, y), P(lx, ly)], fill=(120, 124, 132), width=1)
        d.text((P(lx, ly)[0] + 4, P(lx, ly)[1]), label, fill=INK, font=font(13, True), anchor="lm")
    for (x, y), name, (lx, ly) in (((-1.9, 0.2), "Kai, manipulates", (-9.6, 0.9)), ((2.6, 1.9), "Rafi, assists", (5.6, 2.2))):
        px, py = P(x, y)
        d.ellipse([px - 9, py - 9, px + 9, py + 9], fill=WHITE, outline=NAVY, width=2)
        d.line([P(x, y), P(lx, ly)], fill=(120, 124, 132), width=1)
        d.text((P(lx, ly)[0] + 4, P(lx, ly)[1]), name, fill=INK, font=font(13), anchor="lm")
    rx, ry = P(-11.6, -8.8)
    d.polygon([(rx - 26, ry + 6), (rx + 22, ry - 22), (rx + 34, ry - 2), (rx - 14, ry + 26)], outline=(120, 120, 124), width=2)
    d.line([P(-11.0, -8.3), P(-4.0, -4.4)], fill=(255, 190, 60), width=2)
    d.text((rx + 40, ry + 6), "rover 15 m back, lights on the shelf", fill=INK, font=font(12))
    text_block(d, 712, 52, width - 730,
               "Real 10 m LOLA cells under the shelf fit a 3.7 deg slope with 2.1 m relief: graded flat, blended over 6 m. "
               "No cavern, no maze. Two suited cadets in the field, two at home. The 2034 crew's boot prints and tracks are still crisp "
               "(no wind, no rain). Only a thin dust film on the case's identification window. Permanent shadow: the S06 horizon is "
               "9.9 deg above a 1.6 deg Sun, so the light is the headlights and helmet lamps. The 2034 marker is unfaded: no UV in a PSR.",
               size=13, fill=INK)
    return img


# ----------------------------------------------------------------------------------------------- sheets

GARAGE_TILES = [
    ("EN_Garage_DockingPort", "Docking port", ["2 m wall; hatch 0.90 x 1.15 m", "sill 0.45 m; vestibule panel"]),
    ("EN_Garage_DockingPort_open", "  hatch open", ["HatchLeaf +100 deg", "SEALED / EQUALISING / SAFE"]),
    ("EN_Garage_DockingPort_bay", "  bay side", ["telescoping tunnel 1.10 m", "child DockCollar, seal ring"]),
    ("EN_Garage_BayWindow", "Bay window", ["2 m wall; 1.70 x 1.00 m", "sill 1.0 m, two panes"]),
    ("EN_Garage_CargoLock", "Dry cargo lock", ["1 m wall; 0.72 x 0.56 m", "LampDry, LampSafe, Screen"]),
    ("EN_Garage_CargoLock_open", "  inner door open", ["InnerDoor (room)", "one door at a time"]),
    ("EN_Garage_CargoLock_bay", "  porch side", ["OuterDoor hinged on top", "chest height on the porch"]),
    ("EN_Garage_SuitSealPanel", "Suit seal station", ["2 suitports + dock seal", "3 gauges, 3 lamps, Screen"]),
    ("EN_Garage_RouteBoard", "Route board", ["1.80 x 0.95 m Screen", "3 blank route cards A/B/C"]),
    ("EN_Garage_DepartureBoard", "Departure board", ["0.74 x 1.20 m Screen", "two side by side"]),
    ("EN_Garage_HandoverConsole", "Handover console", ["1.80 x 0.72 m, desk 0.95 m", "map / slope card / pad cam"]),
    ("EN_Garage_CargoRack", "Cargo rack + ledger", ["2.0 x 0.6 x 2.2 m, sealed bins", "ledger tablet = Screen2"]),
    ("EN_Garage_ReliefLocker", "Relief locker", ["1.2 x 0.6 x 2.2 m", "blank label plate"]),
    ("EN_Garage_ReliefLocker_open", "  doors open", ["DoorL / DoorR 110 deg", "relief cargo shelves"]),
    ("EN_Garage_BayFrame", "Bay module (vacuum)", ["2 x 5.85 x 5.6 m, x6", "portal, shield, flood, floor"]),
    ("EN_Garage_BayDoor", "Rover door", ["opening 5.55 x 4.90 m", "not a pressure door"]),
    ("EN_Garage_BayDoor_open", "  door open", ["DoorPanel coils into the drum", ""]),
    ("EN_Garage_BayEndWall", "Bay end wall", ["5.85 x 5.60 m", "ribbed shield"]),
    ("EN_Garage_EVAPorch", "EVA porch", ["3.30 x 5.85 m at +1.40 m", "rail, suitport gate, stair"]),
    ("EN_Garage_Umbilical", "Charge umbilical", ["0.36 x 1.70 m post", "power + coolant"]),
]
COLD_TILES = [
    ("EN_ColdTrap_BeaconMast", "Beacon on 5 m mast", ["PR_SurveyBeacon head", "guyed, 2 retro bands"]),
    ("EN_ColdTrap_ReturnMarker", "Return marker", ["2.0 m, 3 retro bands", "stiff flag (no cloth)"]),
    ("EN_ColdTrap_SlopeSign", "Slope sign", ["face 0.55 x 0.40 m", "value is live text"]),
    ("EN_ColdTrap_ReferencePlate", "Dry reference plate", ["0.40 m at 0.30 m", "the scanner's dry ref."]),
    ("EN_ColdTrap_SampleStake", "Sample stake", ["0.60 m, stiff tag", "3 per station"]),
    ("EN_ColdTrap_TetherAnchor", "Tether anchor", ["helical, D-ring", "two on the shelf"]),
    ("EN_ColdTrap_SurveyMarker2034", "2034 marker + tag", ["1.5 m; archival tag", "blank, live text"]),
    ("PR_VaultCase_Open_closed", "Vault V12, closed", ["0.60 x 0.39 x 0.27 m", "ID window, probe socket"]),
    ("PR_VaultCase_Open", "  open: 12 wells", ["capped tubes, blank tabs", "opened only in the glovebox"]),
    ("PR_VaultCase_Open_lid", "  lid underside", ["Label_Lid: clue 15 slot", "inscription is live text"]),
    ("PR_VaultProbe", "Thermal probe", ["0.45 m wand, Screen", "S07 handling band"]),
    ("PR_VaultCarrier", "Recovery carrier", ["cradle + MLI sleeve", "2 lift points, tether eye"]),
    ("PR_RoverCargoMount", "Rover cargo mount", ["latch flag + lock pin", "S08: shows vs locked"]),
]


def garage_sheet(layout):
    W = 2200
    H = 3080
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    title_bar(d, W, "EN_Garage: LOC-08 rover garage and landing apron (M3-4A, for approval)",
              "Blender 5.2 Cycles renders of the procedural build (no AI image generation, no credits). Photoreal environment (5 Nov realism lock); "
              "figures are 1.75 m scale stand-ins for the cel-shaded cast.")
    x, y = 24, 116
    ext = cover(PREVIEW / "EN_Garage_view_exterior.png", 1150, 647)
    plan = garage_plan(layout, scale=62, width=1000)
    plan.thumbnail((1000, 900))
    yb = panel(sheet, d, ext, x, y, "The garage under its 1 m regolith berm on the edge of Aurora's courtyard: the rover rolls out of the 5.55 m door onto "
               "the apron and the marked path (return markers). Sun: JPL Horizons row EX-CH04-S02, 21 Oct 2046 06:00 UTC, az 59.8 deg, el 1.8 deg; "
               "black sky, hard shadows, flat ground lit at grazing light. The marked path joins Aurora's courtyard 80 m away.")
    sheet.paste(plan, (x + 1150 + 26, y))
    y = max(yb, y + plan.height) + 10
    a = cover(PREVIEW / "EN_Garage_view_bay.png", 1065, 599)
    b = cover(PREVIEW / "EN_Garage_view_ready.png", 1065, 599)
    y1 = panel(sheet, d, a, x, y, "Into the vacuum bay through the open door: the rover docked at the ready room's tunnel, LED floods (5,000 K), the "
               "warm ready-room windows, the EVA porch at the rover's rear; low sunlight rakes in across the floor.")
    y2 = panel(sheet, d, b, x + 1065 + 22, y, "The ready room (habitat air, 3,500 K): route board and the two departure boards on the left, the "
               "windows and the open docking hatch on the right, Amara's handover console, the relief locker and the cargo rack at the end.")
    y = max(y1, y2)
    c = cover(PREVIEW / "EN_Garage_view_cutaway.png", 1065, 599)
    sec = garage_section(layout["section"], width=1065, height=599)
    y1 = panel(sheet, d, c, x, y, "Cutaway (roof, door wall and berm removed; neutral light): the docked rover, the porch and stair, the cargo lock, "
               "the ready room's consoles and boards.")
    sheet.paste(sec, (x + 1065 + 22, y))
    d.rectangle([x + 1065 + 22, y, x + 2130 + 22, y + sec.height], outline=(190, 192, 196))
    y = max(y1, y + sec.height + 12) + 6
    d.text((x, y), "Pieces (new; the ready room's walls, floor, ceiling, door and lights are the approved M1-05 kit)", fill=NAVY, font=font(19, True))
    y += 32
    size = 196
    for k, (name, heading, lines) in enumerate(GARAGE_TILES):
        col, row = k % 10, k // 10
        tile(sheet, d, name, x + col * (size + 17), y + row * (size + 70), size, heading, lines)
    y += 2 * (size + 70) + 10
    colw = 690
    blocks = [
        ("Scenes and story objects it serves",
         "EX-CH04-S02 rover seal, scanner, closed carrier and the independent consumables manifest (cargo rack ledger), two field + two home "
         "ledgers (departure boards), Ferreira's assignment on the Earth link (console); bridge S02 -> S03: the docking hatch closes on two field "
         "and two home. S03 route cards A/B/C (route board, rover display). S09 return: the dock re-mates, the sealed vault in its sleeve comes in "
         "through the dry cargo lock to the dry glovebox (bridge S09 -> S10). S12 relief locker and flight notice; CH04 -> CH05 the landing-pad "
         "camera (Screen3, pad 500 m away, CH05-S01). CH07-S12 and CH08-S01 the two destination boards; CH08-S01 'three in the rover, two outside "
         "its sealed cabin'; CH08-S11 the return. The handbook moves the departure boards here from the Commons."),
        ("States (layout never changes)",
         "Docking hatch closed / open; dock collar retracted / extended (rover docked); vestibule words SEALED / EQUALISING / SAFE TO OPEN "
         "(live Screen, pump only while cycling, labelled time card for the rest). Cargo lock: both doors shut / inner open / outer open, never "
         "both; LampDry while the dry-nitrogen fill runs. Rover door closed / open (panel in the drum). Bay: floods on or off, rover docked or "
         "away. Relief locker shut / open. Screens: route map and beacon chain, slope card, pad camera, roster boards, ledger; all words drawn at "
         "runtime. Day / dark outside follows the dated Sun rows."),
        ("Canon and science checks",
         "English only and no text baked into any surface (every word is a live Screen or Label slot; plates are blank). No logos, flags or NASA "
         "marks on the building. No plants in this set. Moon rules (ART_BIBLE 2): black sky, no fog, haze or dust plumes, hard shadows, one low "
         "Sun from JPL Horizons, no light beams in the vacuum bay, tracks stay crisp; the pressurised ready room holds people, the bay holds "
         "people only in suits. Earth is above the horizon at S02 (az 130) but outside every frame here (screens first, doc 24 C4). No sound "
         "sources outside: the pump hum is in the ready room."),
    ]
    for k, (head, body) in enumerate(blocks):
        bx = x + k * (colw + 30)
        d.text((bx, y), head, fill=NAVY, font=font(17, True))
        text_block(d, bx, y + 26, colw, body, size=14, fill=INK)
    return sheet


def coldtrap_sheet(survey):
    W = 2200
    H = 3540
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    title_bar(d, W, "EN_ColdTrap: LOC-09 surveyed ridge road and LOC-10 vault shelf (M3-4A, for approval)",
              "Blender 5.2 Cycles on the real LOLA terrain (5 m Aurora ridge, 10 m cold trap, 40 m vista; curved Moon), Sun from JPL Horizons; "
              "no AI image generation, no credits. Figures: 1.75 m suited stand-ins.")
    x, y = 24, 116
    m = coldtrap_map(survey, width=2152, height=900)
    sheet.paste(m, (x, y))
    y += m.height + 14
    a = cover(PREVIEW / "EN_ColdTrap_view_B2_high.png", 1065, 599)
    b = cover(PREVIEW / "EN_ColdTrap_view_B3.png", 1065, 599)
    y1 = panel(sheet, d, a, x, y, "Segment B2 (1.88 km) from above, sunlit at EX-CH04-S04 (08:00 UTC, Sun az 82.2 deg, el 1.6 deg): the road's rover "
               "ruts, the beacon on its 5 m mast before the blind corner, return marker and slope sign, the rover; long hard shadows, the lit "
               "massif beyond, black sky.")
    y2 = panel(sheet, d, b, x + 1065 + 22, y, "Segment B3 (5.24 km) at the same hour: the terrain horizon (5.4 deg) hides the Sun, so only the rover's "
               "headlights and the helmet lamps light the beacon corner, while distant slopes above the shadow line stay sunlit. No beams in "
               "vacuum; the retro bands flash back.")
    y = max(y1, y2)
    c = cover(PREVIEW / "EN_ColdTrap_view_shelf.png", 1065, 599)
    y1 = panel(sheet, d, c, x, y, "LOC-10 vault shelf in permanent shadow (EX-CH04-S06 to S08): vault V12 where it was deposited, the recovery carrier "
               "tethered beside it, the probe, the 2034 marker; helmet lamps and the rover's lights from 15 m back; the sunlit rim far above.")
    sp = shelf_plan(width=1065, height=599)
    sheet.paste(sp, (x + 1065 + 22, y))
    d.rectangle([x + 1065 + 22, y, x + 2130 + 22, y + sp.height], outline=(190, 192, 196))
    y = max(y1, y + sp.height + 12) + 4
    prof = road_profile(survey, width=2152, height=360)
    sheet.paste(prof, (x, y))
    y += prof.height + 14
    d.text((x, y), "Pieces and the vault set (new; PR_SurveyBeacon, PR_IceScanner, PR_SampleHolder, PR_Glovebox and VH_Rover are installed and reused)", fill=NAVY, font=font(19, True))
    y += 32
    size = 196
    for k, (name, heading, lines) in enumerate(COLD_TILES):
        col, row = k % 10, k // 10
        tile(sheet, d, name, x + col * (size + 17), y + row * (size + 70), size, heading, lines)
    y += 2 * (size + 70) + 10
    colw = 690
    blocks = [
        ("Scenes and story objects it serves",
         "S04 three beacons before the blind corners, each tested (the chain is real line of sight here); return markers; slope signs. S05 the dry "
         "reference plate (dry reference 2, threshold 12, samples 2/18/19 stay UI values), three sample stakes, PR_IceScanner, PR_SampleHolder. "
         "S06 the manufactured corner: vault V12 with its identification window and probe socket, the 2034 marker and archival tag, two tether "
         "anchors, the carrier tethered beside it (bridge S06 -> S07). S07 probe, sleeve, cradle; the lid stays shut (S07 -> S08). S08 the sleeved "
         "case lifted in the carrier onto PR_RoverCargoMount: latch flag (shows closed) and lock pin (tests locked) are two results. S09 the same "
         "chain back. S10-S11 (glovebox): the open state with 12 wells and Label_Lid, clue 15's inscription, drawn live."),
        ("Computed survey (production/models/ch04/coldtrap_survey.json)",
         f"Road 8.56 km on the 20 m grid, steepest 11.9 deg, 802 m down to the PSR edge. Beacons on 5 m masts: B1 1.02 km (lit), B2 1.88 km (lit), "
         f"B3 5.24 km (dark), each before the first cell its predecessor cannot see; Aurora's mast to B1 6.1 m clear, B1-B2 1.7 m, B2-B3 2.7 m, "
         f"B3-shelf 3.5 m; Aurora cannot see the shelf directly (220 m below the chord). With the 1.8 m tripod the same road needs five "
         f"beacons. The relay chain covers 73 % of the road (cruise gaps are fine: S04 tests each corner). The third beacon has one window, road "
         f"5.22-5.30 km; M1-82's LOC-09 point (7.82 km) sees the shelf but not B2."),
        ("Canon and science checks",
         "Black sky, no stars at these exposures, no fog, haze, wind or dust plumes; ruts and boot prints crisp, dust moves only where touched. "
         "One Sun from JPL Horizons rows, hard shadows; the PSR floor is never sunlit; Earth is below the terrain for S04-S08 and never shown. "
         "No light beams in vacuum; retroreflectors brighten only beside the light source. No airborne sound. Lunar gravity: tethers sag, nothing "
         "floats. No frost on the case in vacuum. English only, nothing written on any surface: tags, signs and the lid are blank Label slots; "
         "nothing names Noor before CH05. No NASA logos. No plants here."),
    ]
    for k, (head, body) in enumerate(blocks):
        bx = x + k * (colw + 30)
        d.text((bx, y), head, fill=NAVY, font=font(17, True))
        text_block(d, bx, y + 26, colw, body, size=14, fill=INK)
    return sheet


DECISIONS = [
    "Garage section: a loading-dock garage. Pressurised ready room on a 1.40 m plinth, vacuum rover bay; the rover docks its side hatch to a "
    "telescoping tunnel, so a trip vents only the 1 m3 tunnel, not a 330 m3 hangar.",
    "Ready room joins the habitat by a pressurised kit corridor (inner door); the rover door's marked path joins the courtyard (LOC-06) as canon "
    "says. Alternative: no corridor, crew walk suited from LOC-05.",
    "Site and look: 80 m from Aurora at az 150, rover door facing az 100, under a 1 m regolith berm with sintered wing walls; the 500 m pad is "
    "seen only on the pad camera.",
    "Suits stay on the rover's two rear suitports, reached from the EVA porch (+1.40 m); the suit-seal station checks both and the dock seal. "
    "People enter the bay only suited.",
    "The vault comes home sealed in its sleeve through a dry-nitrogen cargo lock (never humid cabin air: a 40 K case would frost), then to the "
    "dry glovebox (S09 to S10).",
    "Relief locker holds the 8-12 Dec relief cargo; Ferreira's own locker stays the airlock's fifth suit locker (gold tab, built).",
    "Two portrait departure boards side by side; a three-screen handover console (map with the beacon chain, slope card, pad camera). "
    "All words live.",
    "LOC-09 = three 100 m segments at the computed corners B1 1.02 km and B2 1.88 km (sunlit) and B3 5.24 km (dark); M3-4R moves LOC-09's "
    "M1-82 point (7.82 km) or keeps it as a viewpoint.",
    "Beacons stand on 5 m telescoping masts: then the real road needs exactly canon's three. On the installed 1.8 m tripod it needs five.",
    "Vault shelf on the M1-82 LOC-10 site, graded flat; no stars drawn; old boot prints and tracks crisp; the 2034 marker unfaded (no UV in a "
    "PSR); light = headlights and helmet lamps.",
    "Vault set: rebuild PR_VaultCase procedurally as one hinged asset in the installed look (closed / open, 12 wells, Label_Lid, probe socket) "
    "plus probe, carrier and rover cargo mount.",
    "Build method: both assets fully procedural in Blender (like the airlock and the annex); no Tripo or Meshy credits in phase 2.",
]


def approval_sheet(layout, survey):
    W, H = 2400, 3200
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    title_bar(d, W, "Chapter 4 'Into the Cold Trap' environments for approval: EN_Garage and EN_ColdTrap (M3-4A)",
              "Blender 5.2 Cycles renders of procedural builds on the real LOLA terrain with JPL Horizons Sun rows. No AI image generation, "
              "no Tripo or Meshy credits. Full sheets and details: production/concept/chapter4_v1/README.md")
    x, y = 24, 118
    cw = 1164
    d.text((x, y), "EN_Garage (LOC-08): loading-dock garage under a regolith berm", fill=NAVY, font=font(22, True))
    d.text((x + cw + 24, y), "EN_ColdTrap (LOC-09 road, LOC-10 vault shelf) on real terrain", fill=NAVY, font=font(22, True))
    y += 36
    tiles_l = [("EN_Garage_view_exterior", "Departure (S02 Sun, az 59.8, el 1.8): the rover leaves the 5.55 m door."),
               ("EN_Garage_view_bay", "Vacuum bay: rover docked to the ready room's tunnel, EVA porch behind."),
               ("EN_Garage_view_ready", "Ready room: route board, two departure boards, dock hatch, windows.")]
    tiles_r = [("EN_ColdTrap_view_B2_high", "Segment B2 (1.88 km), sunlit at S04: ruts, beacon on 5 m mast, rover."),
               ("EN_ColdTrap_view_B3", "Segment B3 (5.24 km) in terrain shadow: headlights only, far slopes lit."),
               ("EN_ColdTrap_view_shelf", "Vault shelf (PSR): V12, carrier, probe, 2034 marker; helmet lamps.")]
    for k, ((ln, lc), (rn, rc)) in enumerate(zip(tiles_l, tiles_r)):
        hh = 655 if k == 0 else 470
        a = cover(PREVIEW / f"{ln}.png", cw, hh)
        b = cover(PREVIEW / f"{rn}.png", cw, hh)
        sheet.paste(a, (x, y))
        sheet.paste(b, (x + cw + 24, y))
        d.text((x + 8, y + hh - 30), lc, fill=WHITE, font=font(16, True), stroke_width=3, stroke_fill=(10, 12, 16))
        d.text((x + cw + 32, y + hh - 30), rc, fill=WHITE, font=font(16, True), stroke_width=3, stroke_fill=(10, 12, 16))
        y += hh + 10
    # the measured drawings: garage plan and section, the cold-trap map with the beacon chain and the dated light
    plan = garage_plan(layout, scale=62, width=1000)
    plan = plan.crop((0, 0, plan.width, int(92 + layout["bounds_m"][1] * 62 + 60)))
    plan.thumbnail((560, 520), Image.LANCZOS)
    sec = garage_section(layout["section"], width=1065, height=599)
    sec.thumbnail((cw - plan.width - 12, 520), Image.LANCZOS)
    sheet.paste(plan, (x, y))
    sheet.paste(sec, (x + plan.width + 12, y))
    m = coldtrap_map(survey, width=2152, height=900)
    m.thumbnail((cw, 520), Image.LANCZOS)
    sheet.paste(m, (x + cw + 24, y))
    for bx, im in ((x, plan), (x + plan.width + 12, sec), (x + cw + 24, m)):
        d.rectangle([bx, y, bx + im.width, y + im.height], outline=(190, 192, 196))
    y += max(plan.height, sec.height, m.height) + 16
    d.text((x, y), "Decisions to approve (numbered as in the README; reply e.g. 'approve all' or 'approve all except 3, 9')", fill=NAVY, font=font(21, True))
    y += 34
    colw = (W - 48 - 30) // 2
    yc = [y, y]
    for k, text in enumerate(DECISIONS, 1):
        c = 0 if k <= 6 else 1
        f = font(15)
        lines = wrap(d, text, colw - 40, f)
        d.ellipse([x + c * (colw + 30), yc[c] + 1, x + c * (colw + 30) + 26, yc[c] + 27], fill=NAVY)
        d.text((x + c * (colw + 30) + 13, yc[c] + 14), str(k), fill=WHITE, font=font(14, True), anchor="mm")
        for line in lines:
            d.text((x + c * (colw + 30) + 36, yc[c] + 4), line, fill=INK, font=f)
            yc[c] += 20
        yc[c] += 8
    y = max(yc) + 6
    d.line([x, y, W - 24, y], fill=(200, 200, 204), width=1)
    text_block(d, x, y + 10, W - 48, "Canon and science: English only, no text baked anywhere (screens and plates are live slots), no NASA logos, no plants in this "
               "set; black sky, no fog, haze, wind or dust plumes, hard shadows, one low Sun from JPL Horizons, no light beams in vacuum, Earth not "
               "shown (below the terrain for S04-S08), no airborne sound. Terrain: NASA LRO LOLA (PGDA product 90 and Site01), JPL Horizons; NASA "
               "does not endorse this game. Credits spent: 0.", size=15, fill=SOFT)
    return sheet.crop((0, 0, W, min(H, y + 110)))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    layout = json.loads((STAGE / "garage_layout.json").read_text())
    survey = json.loads((STAGE / "coldtrap_survey.json").read_text())
    garage_sheet(layout).save(OUT / "M3-4A_EN_Garage_sheet.png", optimize=True)
    coldtrap_sheet(survey).save(OUT / "M3-4A_EN_ColdTrap_sheet.png", optimize=True)
    approval_sheet(layout, survey).save(OUT / "00_Approval_Sheet.png", optimize=True)
    print("CH04_SHEETS", sorted(p.name for p in OUT.glob("*.png")))


if __name__ == "__main__":
    main()
