#!/usr/bin/env python3
"""Compose the five M3-8A Chapter 8 approval sheets and the one-page approval sheet (system Python: Pillow, numpy, SciPy).

    python3 production/concept/chapter8_v1/compose_ch08.py

Reads the Cycles renders in production/models/chapter8/render/ (build_summit.py, build_road.py, build_rooftop.py,
build_pieces.py), production/models/chapter8/data/road.json (road_data.py), summit_layout.json, the character takes in
characters/, and writes into this folder:
  M3-8A_EN_MalapertSummit_sheet.png, M3-8A_EN_RelayRoad_sheet.png, M3-8A_EN_NoorRooftop_sheet.png,
  M3-8A_CH_Noor_sheet.png, M3-8A_CH_Rao_sheet.png and 00_Approval_Sheet.png (all five on one page).
The rooftop's painted grade is the approved EN_EarthDesk treatment (Kuwahara brush filter, production/concept/earth_desk/).
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps
from scipy import ndimage

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
R = ROOT / "production/models/chapter8/render"
DATA = ROOT / "production/models/chapter8/data"
REF = ROOT / "production/models/chapter8/ref"
CH = HERE / "characters"
sys.path.insert(0, str(ROOT / "production/concept/earth_desk"))
from compose_earth_desk import kuwahara  # noqa: E402

FONT = "/System/Library/Fonts/Helvetica.ttc"
NAVY, ORANGE, WHITE, PAPER, GOLD, INK, MUTE = (31, 42, 68), (242, 107, 33), (236, 238, 240), (246, 246, 244), (242, 194, 48), (40, 44, 52), (96, 100, 110)
W = 2200


def font(size, bold=False):
    return ImageFont.truetype(FONT, size, index=1 if bold else 0)


def title(d, text, sub, sub2=None):
    d.rectangle([0, 0, W, 112 if sub2 else 92], fill=NAVY)
    d.text((28, 14), text, fill=WHITE, font=font(34, True))
    d.text((28, 58), sub, fill=(200, 206, 220), font=font(18))
    if sub2:
        d.text((28, 82), sub2, fill=(200, 206, 220), font=font(18))
    return 112 if sub2 else 92


def fit(im, w, h):
    im = im.convert("RGB")
    im = ImageOps.contain(im, (w, h), Image.LANCZOS)
    return im


def cover(im, w, h):
    return ImageOps.fit(im.convert("RGB"), (w, h), Image.LANCZOS)


def panel(sheet, d, im, x, y, w, h, caption, sub=None, mode="cover", bg=(20, 22, 26)):
    d.rectangle([x, y, x + w, y + h], fill=bg)
    pic = cover(im, w, h) if mode == "cover" else fit(im, w, h)
    sheet.paste(pic, (x + (w - pic.width) // 2, y + (h - pic.height) // 2))
    d.text((x, y + h + 6), caption, fill=NAVY, font=font(17, True))
    if sub:
        for k, line in enumerate(sub if isinstance(sub, list) else [sub]):
            d.text((x, y + h + 29 + 18 * k), line, fill=MUTE, font=font(14))


def wrap(d, text, x, y, width_px, size=15, color=INK, bold=False, gap=4):
    f = font(size, bold)
    words, line, yy = text.split(), "", y
    for w_ in words:
        t = (line + " " + w_).strip()
        if d.textlength(t, font=f) > width_px and line:
            d.text((x, yy), line, fill=color, font=f)
            yy += size + gap
            line = w_
        else:
            line = t
    if line:
        d.text((x, yy), line, fill=color, font=f)
        yy += size + gap
    return yy


def arrow(d, x0, y0, ang_deg, length, color, label, f=None):
    a = math.radians(ang_deg)
    x1, y1 = x0 + length * math.sin(a), y0 - length * math.cos(a)
    d.line([x0, y0, x1, y1], fill=color, width=4)
    for s in (-1, 1):
        b = a + math.pi + s * 0.45
        d.line([x1, y1, x1 + 14 * math.sin(b), y1 - 14 * math.cos(b)], fill=color, width=4)
    d.text((x1 + 6, y1 - 10), label, fill=color, font=f or font(15, True))


# ------------------------------------------------------------------ EN_MalapertSummit

def summit_plan(lay, width=760):
    sc = 22  # px per metre
    x0, x1, y0, y1 = lay["pad_bounds"]
    mx, top = (width - (x1 - x0) * sc) / 2, 70
    H = int(top + (y1 - y0) * sc + 330)
    img = Image.new("RGB", (width, H), PAPER)
    d = ImageDraw.Draw(img)

    def P(x, y):
        return mx + (x - x0) * sc, top + (y1 - y) * sc
    d.text((10, 8), "Plan on the 1 m grid (x local east, y local north, origin = the summit LOLA pixel)", fill=NAVY, font=font(16, True))
    d.text((10, 30), "30 x 20 m pad cut level 0.3 m under the crown and filled outward; 5 m grid lines", fill=MUTE, font=font(13))
    d.rectangle([*P(x0, y1), *P(x1, y0)], fill=(226, 228, 230), outline=(150, 152, 156), width=2)
    for gx in range(int(x0), int(x1) + 1):
        c = (205, 207, 210) if gx % 5 else (180, 182, 186)
        d.line([*P(gx, y0), *P(gx, y1)], fill=c, width=1)
    for gy in range(int(y0), int(y1) + 1):
        c = (205, 207, 210) if gy % 5 else (180, 182, 186)
        d.line([*P(x0, gy), *P(x1, gy)], fill=c, width=1)

    def rect(cx, cy, w, h, fill, label, dy=0):
        a, b = P(cx - w / 2, cy + h / 2), P(cx + w / 2, cy - h / 2)
        d.rectangle([*a, *b], fill=fill, outline=NAVY, width=2)
        if label:
            f = font(13, True)
            tw = d.textlength(label, font=f)
            lx, ly = (a[0] + b[0]) / 2 - tw / 2, (a[1] + b[1]) / 2 - 8 + dy
            d.rectangle([lx - 3, ly - 1, lx + tw + 3, ly + 16], fill=WHITE)
            d.text((lx, ly), label, fill=NAVY, font=f)
    rect(-5.0, 5.5, 4.0, 4.0, (60, 76, 110), "relay deck")
    rect(-4.0, 1.4, 0.7, 1.4, (250, 250, 250), "")
    d.text((P(-4.0, 1.4)[0] - 120, P(-4.0, 1.4)[1] - 6), "housing", fill=NAVY, font=font(13, True))
    rect(-3.3, 0.2, 0.35, 0.35, ORANGE, "")
    d.text((P(-3.3, 0.2)[0] - 20, P(-3.3, 0.2)[1] + 28), "isolator", fill=NAVY, font=font(13, True))
    rect(-1.8, 2.8, 0.6, 1.0, (120, 200, 140), "")
    d.text((P(-1.8, 2.8)[0] + 30, P(-1.8, 2.8)[1] - 30), "L/E pedestal", fill=NAVY, font=font(13, True))
    rect(-11.5, 5.0, 2.2, 0.4, (40, 50, 90), "")
    rect(-11.5, 3.7, 0.8, 0.5, (250, 250, 250), "")
    d.text((P(-13.6, 7.2)[0], P(-13.6, 7.2)[1]), "solar mast + battery", fill=NAVY, font=font(13, True))
    rect(7.6, -1.0, 6.0, 4.6, (238, 238, 238), "rover (VH_Rover)")
    rect(3.2, 0.4, 0.3, 0.3, (250, 250, 250), "")
    d.text((P(3.4, 0.6)[0] + 4, P(3.4, 0.6)[1] - 16), "umbilical", fill=NAVY, font=font(13, True))
    rect(6.0, 9.6, 3.0, 0.2, ORANGE, "")
    d.text((P(7.8, 9.9)[0], P(7.8, 9.9)[1] - 6), "Earth viewpoint", fill=NAVY, font=font(13, True))
    for (ax, ay) in lay["pieces"][8]["at"]:
        cx, cy = P(ax, ay)
        d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=GOLD, outline=NAVY, width=2)
    d.line([*P(-8.5, -0.5), *P(-0.5, -0.5)], fill=GOLD, width=3)
    d.text((P(-8.4, -1.2)[0], P(-8.4, -1.2)[1]), "tether anchors and line", fill=(150, 110, 10), font=font(12, True))
    for (a, b) in (((-11.5, 3.5), (-11.5, 0.2)), ((-11.5, 0.2), (-3.5, 0.2)), ((-1.8, 2.2), (-1.8, 0.6)), ((-1.8, 0.6), (3.0, 0.6))):
        d.line([*P(*a), *P(*b)], fill=(70, 70, 80), width=3)
    for k, (name, (ax, ay)) in enumerate(lay["anchors"].items(), 1):
        cx, cy = P(ax, ay)
        d.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=NAVY)
        d.text((cx - 4 if k < 10 else cx - 8, cy - 8), str(k), fill=WHITE, font=font(13, True))
    # compass rose under the plan: true local azimuths of north, Earth, the Sun and the local antenna's aim at R3
    rx, ry = width - 150, top + (y1 - y0) * sc + 150
    d.ellipse([rx - 92, ry - 92, rx + 92, ry + 92], outline=(180, 182, 186), width=2)
    arrow(d, rx, ry, 0, 70, NAVY, "N")
    arrow(d, rx, ry, 358.7, 88, (40, 110, 200), "")
    arrow(d, rx, ry, 18.1, 88, (210, 140, 0), "")
    arrow(d, rx, ry, 216.7, 80, (120, 60, 160), "")
    d.text((rx - 140, ry - 128), "Earth 358.7 / -2.3", fill=(40, 110, 200), font=font(13, True))
    d.text((rx + 16, ry - 112), "Sun 18.1 / +2.3", fill=(210, 140, 0), font=font(13, True))
    d.text((rx - 150, ry + 96), "local antenna to R3 216.7 / -4.8", fill=(120, 60, 160), font=font(13, True))
    ex, ey = P(12.0, -10.0)
    d.text((ex - 120, ey + 8), "road entry (LOC-11, south-west)", fill=NAVY, font=font(13, True))
    yk = top + (y1 - y0) * sc + 70
    d.text((10, yk), "Anchors", fill=NAVY, font=font(15, True))
    for k, name in enumerate(lay["anchors"], 1):
        d.text((10, yk + 24 + (k - 1) * 20), f"{k}  {name.replace('_', ' ')}", fill=INK, font=font(14))
    yk += 24 + 7 * 20 - 4 * 20
    yk += 24 + 4 * 20 + 14
    d.text((10, yk), "Connections", fill=NAVY, font=font(15, True))
    d.text((10, yk + 22), "south-west entry: LOC-11 relay road", fill=INK, font=font(14))
    d.text((10, yk + 40), "(final approach up to 15 deg on the 80 m grid)", fill=INK, font=font(14))
    return img


def summit_sheet():
    lay = json.loads((HERE / "summit_layout.json").read_text())
    pieces = [("summit_relay_deck", "Legacy relay deck (2034)", ["4 x 4 m truss deck at 1.2 m, orange rails, ladder", "2.0 m Earth dish on an az-el positioner"]),
              ("summit_housing", "Controller housing", ["0.7 x 1.4 x 1.6 m, service door east", "controller bay, test point, 3 status lamps"]),
              ("summit_isolator", "Power isolator", ["rotary handle, lock-out hasp and tag", "post-mounted, between battery and housing"]),
              ("summit_pedestal", "L/E tuner + checksum pedestal", ["local leg L, Earth leg E with obstruction", "ALO42 terminal; words are live UI"]),
              ("summit_solar", "Solar mast and battery", ["2.2 x 3.6 m vertical wing tracks the", "circling polar Sun; battery at its foot"]),
              ("summit_ground", "Anchor, marker, umbilical", ["tether anchor 0.7 m, perimeter marker 0.5 m", "umbilical post 1.0 m to the rover"]),
              ("summit_viewpoint", "Earth viewpoint rail", ["3 m low rail and standing plate", "at the north edge of the pad"])]
    H = 3150
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    y = title(d, "EN_MalapertSummit: LOC-12 Malapert relay summit (M3-8A, approved 7 Nov 2026)",
              "Blender 5.2 Cycles on the real Moon: LOLA PGDA Site23 5 m summit tile + authored sub-5 m craters, malapert_vista 40 m to the horizon, lunar curvature.",
              "Sun and Earth are the JPL Horizons rows of EX-CH08-S10 (9 Apr 2047). No AI image generation, no credits. Photoreal environment; the cel-shaded cast is added at runtime.")
    y += 20
    panel(sheet, d, Image.open(R / "summit_A_toward_earth.png"), 20, y, 1400, 788, "Across the pad toward Earth (S06-S08): the dish aims 2.3 deg below level at a 3 % crescent Earth just above the summit skyline",
          ["The Sun (2.3 deg high, 20 deg right of Earth, out of frame) rakes the pad: 2 m objects throw 50 m shadows. Black sky, no stars over the sunlit ground, no haze. Housing dark (S06 -> S07 bridge)."])
    sheet.paste(summit_plan(lay, 740), (1440, y))
    y += 788 + 80
    w3 = (W - 80) // 3
    panel(sheet, d, Image.open(R / "summit_B_overview.png"), 20, y, w3, 400, "Overview from the north-east (Sun behind the camera)", ["rover parked west-facing, cabin window on the housing; perimeter markers every 5 m"])
    panel(sheet, d, Image.open(R / "summit_C_housing.png"), 40 + w3, y, w3, 400, "S07: housing open, power isolated and tagged", ["door braced open on its north hinge, controller on rails, test point, rover flood as fill"])
    panel(sheet, d, Image.open(R / "summit_D_earth_200mm.png"), 60 + 2 * w3, y, w3, 400, "Earth from the viewpoint, 200 mm (true 1.9 deg size)", ["phase from the dated Sun: 19.9 deg from Earth, so a thin crescent lit on the Sun's side"])
    y += 400 + 80
    pw = (W - 40 - 6 * 16) // 7
    for k, (name, head, lines) in enumerate(pieces):
        x = 20 + k * (pw + 16)
        panel(sheet, d, Image.open(R / f"piece_{name}.png"), x, y, pw, pw, head, lines, mode="cover", bg=(110, 110, 112))
    y += pw + 80
    d.text((20, y), "Scenes served and the bridges this set builds", fill=NAVY, font=font(18, True))
    yy = y + 28
    for line in lay["scenes"]:
        d.text((30, yy), "- " + line, fill=INK, font=font(15)); yy += 21
    yy = wrap(d, "Bridges (doc 24 2.9): S06 -> S07 the dark relay housing beyond the rover window (lamps off); S07 -> S08 the pedestal wakes with two unverified channels (amber, live UI); S08 -> S09 both legs locked (green); clue 22's relay data panel is the pedestal's checksum screen. The return departure time and the transmit button are rover-cabin UI.", 30, yy + 6, W - 80)
    yy = wrap(d, "Canon checks: English only and no words baked into any surface (status, tuner and checksum readouts are a live Screen slot); no logos, flags or agency marks on the hardware; ART_BIBLE 2: black sky, one hard low Sun, near-black shadows, no fog, haze or dust plumes, Earth at its true 1.9 deg and dated phase. Science: the dish boresight, the local antenna's 216.7 / -4.8 deg aim at R3 and the Earth clearance come from the LOLA horizon and the M3-7A route simulator, not from art direction.", 30, yy + 8, W - 80, color=MUTE)
    sheet = sheet.crop((0, 0, W, yy + 20))
    sheet.save(HERE / "M3-8A_EN_MalapertSummit_sheet.png", optimize=True)
    return sheet


# ------------------------------------------------------------------ EN_RelayRoad

def route_map(w, h):
    road = json.loads((DATA / "road.json").read_text())
    meta = json.loads((ROOT / "game/assets/environment/terrain/lola/relay_road/heightmap_80m.json").read_text())
    raw = np.fromfile(ROOT / "game/assets/environment/terrain/lola/relay_road/heightmap_80m.r16", dtype="<u2").reshape(meta["rows"], meta["columns"])
    hgt = meta["z_min_m"] + raw.astype(np.float64) * (meta["z_max_m"] - meta["z_min_m"]) / 65535.0
    gy, gx = np.gradient(hgt, 80.0)
    az, alt = math.radians(315), math.radians(35)
    nx, ny, nz = -gx, gy, np.ones_like(gx)
    nrm = np.sqrt(nx * nx + ny * ny + nz * nz)
    shade = (nx * math.sin(az) * math.cos(alt) + ny * math.cos(az) * math.cos(alt) + nz * math.sin(alt)) / nrm
    shade = np.clip(shade, 0, 1)
    elev = (hgt - hgt.min()) / (hgt.max() - hgt.min())
    rgb = np.stack([shade * 0.75 + elev * 0.25] * 3, axis=-1)
    img = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))
    # rotate so the corridor runs left (Aurora) to right (summit): the map's +y (toward 0 E) becomes +x
    img = img.rotate(-90, expand=True)
    sx = img.width / meta["rows"]
    scale = min(w / img.width, h / img.height)
    img = img.resize((int(img.width * scale), int(img.height * scale)), Image.LANCZOS)
    canvas = Image.new("RGB", (w, h), (24, 26, 30))
    ox, oy = (w - img.width) // 2, (h - img.height) // 2
    canvas.paste(img, (ox, oy))
    d = ImageDraw.Draw(canvas)
    mpp = meta["metres_per_pixel"]

    def M(x, y):
        col = (x - meta["origin_x_m"]) / mpp
        row = (meta["origin_y_m"] - y) / mpp
        # rotate -90 (clockwise): new_x = (rows - 1 - row), new_y = col
        return ox + (meta["rows"] - 1 - row) * scale, oy + col * scale
    pts = [M(x, y) for x, y in road["road_xy"]]
    d.line(pts, fill=(242, 194, 48), width=4)
    for k, p in enumerate(road["pads"], 1):
        cx, cy = M(p["x"], p["y"])
        d.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=ORANGE, outline=WHITE, width=2)
        d.text((cx - 10, cy + 12), f"R{k}", fill=WHITE, font=font(16, True))
        d.text((cx - 30, cy + 32), f"{p['game_km']:.0f} km", fill=(220, 220, 220), font=font(13))
    for s in road["segments"]:
        cx, cy = M(s["x"], s["y"])
        d.rectangle([cx - 11, cy - 34, cx + 11, cy - 12], fill=(40, 110, 200), outline=WHITE)
        d.text((cx - 5, cy - 33), s["id"], fill=WHITE, font=font(16, True))
    for l in road["laybys"]:
        cx, cy = M(l["x"], l["y"])
        d.rectangle([cx - 7, cy - 7, cx + 7, cy + 7], fill=(120, 200, 140), outline=WHITE)
        d.text((cx + 10, cy - 24), l["id"], fill=(160, 230, 170), font=font(14, True))
    for name, (x, y) in (("Aurora", road["aurora"]), ("Malapert summit", road["summit"])):
        cx, cy = M(x, y)
        d.polygon([(cx, cy - 12), (cx + 11, cy + 8), (cx - 11, cy + 8)], fill=WHITE)
        tw = d.textlength(name, font=font(16, True))
        d.text((min(cx - 30, w - tw - 10), cy + 14), name, fill=WHITE, font=font(16, True))
    d.text((12, 10), "Computed relay road on the LOLA 80 m corridor (198 km on this grid, slope-limited; game distance 120 km, canon)", fill=WHITE, font=font(15, True))
    d.text((12, h - 26), "yellow: road  |  orange: repeaters R1-R3 (M3-7A, four clear hops)  |  blue: playable segments A-E  |  green: rest laybys", fill=(220, 220, 220), font=font(14))
    return canvas


def segment_strip(w, h):
    road = json.loads((DATA / "road.json").read_text())
    img = Image.new("RGB", (w, h), PAPER)
    d = ImageDraw.Draw(img)
    d.text((10, 6), "Five short playable segments (about 700 m), cruise compressed by labelled time cards", fill=NAVY, font=font(16, True))
    total = sum(s["length_m"] for s in road["segments"])
    x, y0 = 10, 40
    usable = w - 20
    for s in road["segments"]:
        sw = int(usable * s["length_m"] / total) - 6
        d.rectangle([x, y0, x + sw, y0 + 40], fill=(40, 110, 200))
        d.text((x + 8, y0 + 9), f"{s['id']}  {s['length_m']} m", fill=WHITE, font=font(15, True))
        yy = wrap(d, s["name"], x, y0 + 48, sw, 14, NAVY, True, 2)
        yy = wrap(d, f"{s['scene']}, {s['game_km']:.0f} km", x, yy + 2, sw, 12, MUTE, False, 2)
        yy += 4
        line = ""
        for w_ in s["what"].split():
            t = (line + " " + w_).strip()
            if d.textlength(t, font=font(12)) > sw and line:
                d.text((x, yy), line, fill=INK, font=font(12)); yy += 15; line = w_
            else:
                line = t
        d.text((x, yy), line, fill=INK, font=font(12))
        x += sw + 6
    d.text((10, h - 44), "Return (EX-CH08-S11): segments D, C and A again with new timestamps and the repeaters lit.", fill=INK, font=font(13))
    d.text((10, h - 24), "Laybys L1 and L2 sit on the cruise between segments; each is a graded pull-out with a supply cache.", fill=INK, font=font(13))
    return img


def road_sheet():
    pieces = [("road_repeater", "Repeater (R1-R3)", ["3 m mast on ballasted tripod, ring lamp,", "two panel antennas, battery bay at the foot"]),
              ("road_guide_light", "Guide light", ["0.7 m post, amber lamp", "every 18 m along spurs and the road edge"]),
              ("road_slope_sign", "Slope warning", ["pictogram only: a vehicle on a steep", "slope, orange on navy; no words"]),
              ("road_turnback", "Turnback barrier", ["4 m striped bar between bollards", "closes the unsupported bypass"]),
              ("road_cache", "Layby supply cache", ["rack with two latched crates", "cabin supplies at L1 and L2"])]
    H = 3000
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    y = title(d, "EN_RelayRoad: LOC-11 Aurora to Malapert relay road (M3-8A, approved 7 Nov 2026)",
              "Blender 5.2 Cycles at repeater R2, the marker-two service pad, in the dark of EX-CH08-S04 (8 Apr 2047 10:00 UTC: the Sun 0.06 deg below the horizon at azimuth 53).",
              "Ground: LOLA LDEM_80S_40MPP round the pad + authored sub-40 m craters, the 80 m corridor to the horizon, lunar curvature. No AI image generation, no credits.")
    y += 20
    panel(sheet, d, Image.open(R / "road_A_marker_two.png").crop((150, 120, 1650, 964)), 20, y, 1260, 709, "S04: the marker-two pad worked under the rover's lights; the repeater dark, its bay open",
          ["Light comes only from the rover, the guide lights and suit lamps: the terrain is in the shadow of its own horizon. Faint stars at the top: no sunlit surface is in this frame (ART_BIBLE 2 rule 12, 7 Nov 2026)."])
    sheet.paste(route_map(880, 709), (1300, y))
    d.text((1300, y + 715), "The road, the pads and the hops are the M3-7A route simulator's (fabrication bench, CH07-S11), so CH07's model and CH08's road agree", fill=MUTE, font=font(14))
    y += 709 + 80
    w2 = 700
    panel(sheet, d, Image.open(R / "road_B_battery_bay.png"), 20, y, w2, 394, "Battery bay: old module out, replacement set down", ["isolate before the battery (S04 'Power isolated before the battery.')"])
    panel(sheet, d, Image.open(R / "road_C_marker_lit.png").crop((0, 120, 1400, 908)), 40 + w2, y, w2, 394, "After the swap: beacon and both link lamps lit", ["'Test both neighbours. Then continue.' The rover leaves down the spur"])
    sheet.paste(segment_strip(W - 80 - 2 * w2, 394 + 60), (60 + 2 * w2, y))
    y += 394 + 80
    pw = (W - 40 - 4 * 20) // 5
    for k, (name, head, lines) in enumerate(pieces):
        panel(sheet, d, Image.open(R / f"piece_{name}.png"), 20 + k * (pw + 20), y, pw, int(pw * 0.8), head, lines, bg=(110, 110, 112))
    y += int(pw * 0.8) + 80
    d.text((20, y), "Scenes served and the bridges this set builds", fill=NAVY, font=font(18, True))
    yy = y + 28
    for line in ["EX-CH08-S02 route console (rover cabin UI over this map)", "EX-CH08-S03 Markers in the Dark: segments A and B", "EX-CH08-S04 The Small Light That Carries a Voice: segment C (EVA) and D", "EX-CH08-S06 summit approach: segment E", "EX-CH08-S11 The Same Road Home: D, C, A in reverse"]:
        d.text((30, yy), "- " + line, fill=INK, font=font(15)); yy += 21
    yy = wrap(d, "Bridges (doc 24 2.9): S02 -> S03 cruise begins on the surveyed road (segment A opens on R1); S03 -> S04 brake set at the marker-two pad (segment B ends on the pad); S04 -> S05 a time card holds the field position at the 100 km approach. The pads sit 1.5-2.5 km off the road on high ground, as the simulator chose them for line of sight; each segment includes its spur.", 30, yy + 6, W - 80)
    yy = wrap(d, "Canon checks: no words on any sign (pictograms only; distances and names are live UI), no logos; Moon rules: black sky, no fog, haze or dust plumes, hard shadows; the scene is lit as the dated row says (dark). Distances: the computed road is 198 km on the 80 m grid; the game keeps 120 km each way (P-15, M1-34 decision) and the sheet labels both. The 10 m walkable patch under segment C is M1-87 (it needs LDEM_83S tiles that are not cached yet).", 30, yy + 8, W - 80, color=MUTE)
    sheet = sheet.crop((0, 0, W, yy + 20))
    sheet.save(HERE / "M3-8A_EN_RelayRoad_sheet.png", optimize=True)
    return sheet


# ------------------------------------------------------------------ EN_NoorRooftop

def painted(img):
    rgb = np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0
    rgb = kuwahara(rgb, 4)
    lum = rgb.mean(axis=2, keepdims=True)
    bright = rgb * np.clip((lum - 0.6) / 0.3, 0, 1)
    glow = np.stack([ndimage.gaussian_filter(bright[..., c], 10) for c in range(3)], axis=2)
    rgb = rgb + 0.3 * glow
    rgb = rgb * np.array([1.03, 1.0, 0.95], dtype=np.float32)  # warm morning
    h, w = lum.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    r2 = ((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2
    rgb = rgb * (1.0 - 0.18 * np.clip(r2 / 2.0, 0, 1))[..., None]
    return Image.fromarray((np.clip(rgb, 0, 1) * 255 + 0.5).astype(np.uint8))


def cutout(path):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(np.int16)
    white = (a.min(axis=2) > 236)
    lab, n = ndimage.label(white)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border))
    alpha = (~bg).astype(np.uint8) * 255
    alpha = ndimage.binary_erosion(alpha > 0, iterations=1).astype(np.uint8) * 255
    rgba = np.dstack([np.asarray(im), alpha])
    out = Image.fromarray(rgba, "RGBA")
    return out.crop(out.getbbox())


def rooftop_plan(w, h):
    img = Image.new("RGB", (w, h), PAPER)
    d = ImageDraw.Draw(img)
    sc = min((w - 40) / 8.0, (h - 120) / 10.0)
    ox, oy = (w - 8 * sc) / 2, 60

    def P(x, y):
        return ox + (x + 4) * sc, oy + (5 - y) * sc
    d.text((10, 8), "Plan: 8 x 10 m roof, 1.0 m parapet (x east, y north)", fill=NAVY, font=font(16, True))
    d.rectangle([*P(-4, 5), *P(4, -5)], fill=(214, 212, 206), outline=NAVY, width=4)

    def R_(x0, y0, x1, y1, fill, label):
        d.rectangle([*P(x0, y1), *P(x1, y0)], fill=fill, outline=NAVY, width=2)
        if label:
            cx, cy = (P(x0, y0)[0] + P(x1, y1)[0]) / 2, (P(x0, y0)[1] + P(x1, y1)[1]) / 2
            tw = d.textlength(label, font=font(13, True))
            d.text((cx - tw / 2, cy - 8), label, fill=NAVY, font=font(13, True))
    R_(-3.9, 1.9, -1.3, 4.9, (236, 230, 216), "")
    d.text((P(-3.8, 3.4)[0], P(-3.8, 3.4)[1]), "stair room", fill=NAVY, font=font(13, True))
    d.ellipse([*P(-3.0, 4.5), *P(-2.2, 3.7)], fill=(20, 20, 22))
    d.text((P(-3.8, 2.6)[0], P(-3.8, 2.6)[1]), "black tank on its roof", fill=NAVY, font=font(12, True))
    R_(-2.7, 1.8, -1.7, 1.95, (46, 108, 154), "")
    R_(1.0, -4.6, 3.7, -1.8, (200, 205, 210), "")
    d.text((P(1.1, -1.95)[0], P(1.1, -1.95)[1]), "tin shade", fill=NAVY, font=font(13, True))
    R_(2.05, -3.6, 2.95, -3.0, (122, 85, 52), "")
    d.text((P(2.0, -3.7)[0], P(2.0, -3.7)[1] + 2), "table: radio, tablet", fill=NAVY, font=font(12, True))
    for (x, y) in [(3.55, 1.0), (3.55, 1.9), (3.55, 2.8), (3.55, 3.7), (2.6, 4.55), (1.7, 4.55), (0.8, 4.55), (3.55, -0.2), (-0.6, -4.55), (-1.6, -4.55), (-3.55, 1.2)]:
        cx, cy = P(x, y)
        d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=GOLD, outline=(140, 90, 20))
    for (x, y) in [(3.55, -1.2), (-3.55, -1.0), (-3.55, 0.1), (-3.55, -2.2), (-0.2, 4.55), (-3.55, -3.4), (0.3, -4.55), (-1.0, -4.55), (3.4, -4.4)]:
        cx, cy = P(x, y)
        d.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(70, 130, 60), outline=(30, 70, 30))
    d.line([*P(-1.3, 3.8), *P(2.8, 3.8)], fill=(150, 60, 70), width=3)
    d.text((P(-1.0, 3.6)[0], P(-1.0, 3.6)[1]), "clothesline", fill=(150, 60, 70), font=font(12, True))
    nx, ny = P(2.2, -1.1)
    d.ellipse([nx - 12, ny - 12, nx + 12, ny + 12], fill=(108, 150, 110), outline=NAVY, width=2)
    d.text((nx - 150, ny - 8), "Noor (call position)", fill=NAVY, font=font(13, True))
    cx, cy = P(3.35, -1.1)
    d.polygon([(cx, cy), (cx + 16, cy - 9), (cx + 16, cy + 9)], fill=ORANGE)
    d.text((cx - 70, cy + 12), "screen camera", fill=ORANGE, font=font(12, True))
    yk = oy + 10 * sc + 16
    d.text((10, yk), "gold: mustard in flower (PL_Tara_Bloom)  green: leafy pots, bougainvillea", fill=INK, font=font(13))
    d.text((10, yk + 18), "east: a 14 m road, so the morning view opens over the city", fill=INK, font=font(13))
    return img


def rooftop_sheet():
    H = 2700
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    y = title(d, "EN_NoorRooftop: Noor's rooftop in Dhaka, Bangladesh (Earth screen scene, M3-8A, approved 7 Nov 2026)",
              "Blender 5.2 Cycles, procedural; the EN_EarthDesk method: a 3D room rendered once and shown behind the caller on Aurora's Earth screen, with the approved painted grade.",
              "S10 = 9 Apr 2047 08:15 Dhaka (Sun 34 deg up in the east); S12 = 10 Apr 12:00 (Sun 74 deg). No signs or writing anywhere; no Moon in her sky. No AI image generation, no credits.")
    y += 20
    panel(sheet, d, Image.open(R / "rooftop_A_morning_wide.png"), 20, y, 1300, 731, "Over Noor's shoulder to the city at 08:15 (CS-15-B's direction)",
          ["parapet of mustard in flower, the tin shade over her table with the radio handset and tablet; Earth's air: a light morning haze is correct here"])
    sheet.paste(rooftop_plan(840, 731 + 60), (1340, y))
    y += 731 + 80
    b = Image.open(R / "rooftop_B_backdrop_S10.png")
    c = Image.open(R / "rooftop_C_backdrop_S12.png")
    bp, cp = painted(b), painted(c)
    mock = bp.copy().convert("RGBA")
    noor = cutout(CH / "noor_34_take2.png")
    nh = int(mock.height * 0.98)
    noor = noor.resize((int(noor.width * nh / noor.height), nh), Image.LANCZOS)
    mock.alpha_composite(noor, (int(mock.width * 0.5 - noor.width / 2), int(mock.height * 0.30)))
    w4 = (W - 100) // 4
    hh = int(w4 * 9 / 16)
    panel(sheet, d, b, 20, y, w4, hh, "S10 backdrop, plain render", ["camera where Aurora sees her; f/4, 1.3 m focus"])
    panel(sheet, d, bp, 40 + w4, y, w4, hh, "S10 backdrop, painted grade (live)", ["the EN_EarthDesk grade, warmed for morning"])
    panel(sheet, d, cp, 60 + 2 * w4, y, w4, hh, "S12 backdrop at noon, painted", ["'Show me the cotton by the window.'"])
    panel(sheet, d, mock.convert("RGB"), 80 + 3 * w4, y, w4, hh, "Mock-up: cel-shaded Noor in front", ["her CH_Noor three-quarter take over the S10 backdrop"])
    y += hh + 80
    panel(sheet, d, Image.open(R / "rooftop_D_overview.png"), 20, y, 1000, 562, "The roof from above the stair room", ["stair room with the black water tank on its roof, clothesline, pots along the parapet, neighbours with tanks, no lettering"])
    refs = [Image.open(REF / "cs15_rooftop_back.png"), Image.open(REF / "cs15_noor_face.png")]
    rw = (W - 1060 - 20) // 2
    panel(sheet, d, refs[0], 1040, y, rw, int(rw * 9 / 16), "Reference: CS-15-B (accepted)", ["matched: mustard on the parapet, morning, the black tank"])
    panel(sheet, d, refs[1], 1060 + rw, y, rw, int(rw * 9 / 16), "Reference: CS-15 close shot", ["her radio handset; no Moon in the sky"])
    y += 562 + 70
    yy = wrap(d, "Scenes served: EX-CH08-S10 (Hello, Aurora: her first live words over the restored relay, CS-15 and the in-engine call) and EX-CH08-S12 (Noor watches the shutter open through the restored screen). Bridges: S09 -> S10 the transmit button invites a human voice: the S10 call opens on this backdrop with the EARTH LINK - LIVE caption; S12's line 'Show me the cotton by the window.' plays over the noon variant.", 30, y, W - 80)
    yy = wrap(d, "Canon checks: Earth, Bangladesh; English only and no script of any kind on any surface (no signs, no shop boards, no posters); plants are real field mustard (four-petal flowers, no faces) and ordinary leafy pot plants; modest practical home, not a set. The asset list's 'at night' is superseded by doc 24 7.5 (morning, accepted CS-15-B).", 30, yy + 8, W - 80, color=MUTE)
    sheet = sheet.crop((0, 0, W, yy + 20))
    sheet.save(HERE / "M3-8A_EN_NoorRooftop_sheet.png", optimize=True)
    return sheet


# ------------------------------------------------------------------ characters

def character_sheet(name, sheet_img, three_q, refs, head, sub, sub2, notes, out):
    H = 2200
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    y = title(d, head, sub, sub2) + 20
    sw = 1500
    sh = int(sheet_img.height * sw / sheet_img.width)
    d.rectangle([20, y, 20 + sw, y + sh], fill=WHITE)
    sheet.paste(sheet_img.resize((sw, sh), Image.LANCZOS), (20, y))
    labels = notes["views"]
    for k, lab in enumerate(labels):
        d.text((20 + k * sw // 4 + 16, y + sh + 6), lab, fill=NAVY, font=font(16, True))
    tq_w = W - 60 - sw
    tq = fit(crop_figure(three_q.convert("RGB")), tq_w, sh + 120)
    d.rectangle([40 + sw, y, 40 + sw + tq_w, y + sh + 120], fill=WHITE)
    sheet.paste(tq, (40 + sw + (tq_w - tq.width) // 2, y))
    d.text((40 + sw, y + sh + 126), "Three-quarter view", fill=NAVY, font=font(16, True))
    y += sh + 160
    rw = 520
    for k, (img, cap, s) in enumerate(refs):
        panel(sheet, d, img, 20 + k * (rw + 20), y, rw, int(rw * 9 / 16), cap, s)
    tx = 20 + len(refs) * (rw + 20)
    yy = y
    d.text((tx, yy), "Design", fill=NAVY, font=font(18, True)); yy += 28
    for line in notes["design"]:
        yy = wrap(d, "- " + line, tx, yy, W - tx - 30, 15) + 4
    y = max(y + int(rw * 9 / 16) + 70, yy + 10)
    yy = wrap(d, notes["checks"], 30, y, W - 80, 15, MUTE)
    sheet = sheet.crop((0, 0, W, yy + 20))
    sheet.save(HERE / out, optimize=True)
    return sheet


def figure_spans(im, n=4):
    """Column spans of the n figures on a white turnaround sheet (split on empty columns, like split_turnaround.py)."""
    a = np.asarray(im.convert("L"))
    occ = (a < 235).sum(axis=0) > 2
    spans, start = [], None
    for x, v in enumerate(occ):
        if v and start is None:
            start = x
        if not v and start is not None:
            spans.append((start, x)); start = None
    if start is not None:
        spans.append((start, len(occ)))
    spans = sorted(spans, key=lambda s: s[1] - s[0], reverse=True)[:n]
    return sorted(spans)


def crop_figure(im, pad=24):
    a = np.asarray(im.convert("L"))
    ys, xs = np.nonzero(a < 235)
    return im.crop((max(0, xs.min() - pad), max(0, ys.min() - pad), min(im.width, xs.max() + pad), min(im.height, ys.max() + pad)))


def noor_sheet():
    s = Image.open(CH / "noor_sheet_take1.png").convert("RGB")
    spans = figure_spans(s)
    (l0, l1), (r0, r1) = spans[1], spans[3]
    left = s.crop((l0, 0, l1, s.height))
    fixed = s.copy()
    ImageDraw.Draw(fixed).rectangle([r0 - 4, 0, r1 + 4, s.height], fill=(255, 255, 255))
    cx = (r0 + r1) // 2
    fixed.paste(ImageOps.mirror(left), (cx - left.width // 2, 0))  # both side views of the take faced left; her outfit is symmetric
    return character_sheet(
        "Noor", fixed, Image.open(CH / "noor_34_take2.png"),
        [(Image.open(ROOT / "game/assets/ui/portraits/CH_Noor_present_portrait.png"), "Installed present-day portrait", ["the face, hair and clothes followed here"]),
         (Image.open(REF / "cs15_rooftop_back.png"), "CS-15-B (accepted)", ["grey low bun, green kameez, pale dupatta"])],
        "CH_Noor: Dr Noor Rahman, present day (M3-8A, approved 7 Nov 2026)",
        "Tripo CLI image, gemini_3_pro_image_preview, image-to-image from the installed portrait; the three-quarter view from the sheet. Balance 810 before and after (no credit charged).",
        "Cel-shaded like the v8 cast; adult Bangladeshi botanist about sixty; Earth only (rooftop call CH08-S10, S12). Nothing is built from this yet; no 3D credit spent.",
        {"views": ["Front", "Left side", "Back", "Right side (mirrored left)"],
         "design": ["1.55 m, slim, upright; warm medium-brown skin, kind lined face; grey hair with darker streaks in a low bun at the nape; reading glasses pushed up on her head.",
                    "Sage-green cotton kameez to below the knee, three-quarter sleeves; loose pale green salwar gathered at the ankle; pale sage dupatta over both shoulders; flat brown leather sandals.",
                    "The fourth view is the second view mirrored: two takes drew both side views facing left (the edit attempt changed nothing); her outfit is symmetric, so the mirror is exact for Tripo's right input.",
                    "A-pose with the arms clear of the dupatta, five fingers on every hand (checked at 3x).",
                    "The 2034 archive portrait (younger, Expedition Zero coverall) stays a portrait; no 2034 body is proposed."],
         "checks": "Checks done: no script, letters or logos anywhere; hands counted (5 fingers each, both takes); modest clothing as in the installed portrait and CS-15; no NASA or agency marks (she wears none). Age: the installed portrait and CS-15 show her about sixty, which this sheet keeps."},
        "M3-8A_CH_Noor_sheet.png")


def rao_sheet():
    s = Image.open(CH / "rao_sheet_take1.png").convert("RGB")
    return character_sheet(
        "Rao", s, Image.open(CH / "rao_34_take1.png"),
        [(Image.open(ROOT / "game/assets/ui/portraits/CH_Rao_screen.png"), "Installed screen portrait (CH_Rao_screen.png)", ["face, hair, headset and polo followed here"]),
         (Image.open(ROOT / "game/assets/ui/screens/EN_EarthDesk.png"), "EN_EarthDesk backdrop (approved 6 Nov)", ["his room; decision 5 there: a cut-out Rao"])],
        "CH_Rao: Rao, Earth flight controller (M3-8A, approved 7 Nov 2026)",
        "Tripo CLI image, gemini_3_pro_image_preview, image-to-image from the installed screen portrait; the three-quarter view from the sheet. Balance 810 before and after (no credit charged).",
        "Cel-shaded like the v8 cast; adult; Earth only, always (the Earth desk on Aurora's screen). Nothing is built from this yet; no 3D credit spent.",
        {"views": ["Front", "Right side", "Back", "Left side"],
         "design": ["1.78 m, average slim build; warm brown skin, short neat black hair, clean-shaven, friendly calm face as in the portrait.",
                    "Light grey short-sleeved polo (three-button placket), charcoal-navy chinos, dark brown belt, dark grey lace-up shoes, steel watch on the left wrist.",
                    "Black over-ear headset with the boom microphone on his left side, as in the portrait; part of the body mesh.",
                    "This take runs front, RIGHT, back, LEFT (the watch and microphone side show which); Tripo's left/right inputs are swapped accordingly.",
                    "A-pose, five fingers on every hand (checked at 3x)."],
         "checks": "Checks done: no letters, badges, lanyard text or logos (no NASA mark: he works for the expedition's mission control, never an agency badge); hands counted; the face matches the installed portrait so the Earth-screen cut-out and any 3D shot read as one man."},
        "M3-8A_CH_Rao_sheet.png")


def approval(sheets):
    order = ["M3-8A_EN_MalapertSummit_sheet.png", "M3-8A_EN_RelayRoad_sheet.png", "M3-8A_EN_NoorRooftop_sheet.png", "M3-8A_CH_Noor_sheet.png", "M3-8A_CH_Rao_sheet.png"]
    ims = [Image.open(HERE / n).convert("RGB") for n in order]
    tw = 1600
    ims = [im.resize((tw, int(im.height * tw / im.width)), Image.LANCZOS) for im in ims]
    head = 110
    H = head + sum(im.height + 24 for im in ims)
    page = Image.new("RGB", (tw, H), (226, 228, 232))
    d = ImageDraw.Draw(page)
    d.rectangle([0, 0, tw, head], fill=NAVY)
    d.text((24, 14), "M3-8A Chapter 8 (The Lighthouse): five assets, approved 7 Nov 2026", fill=WHITE, font=font(32, True))
    d.text((24, 58), "Sadman in chat: \"Approve all\" (decisions 1-11), \"Fix CS-15\" (board M4-05), \"Faint stars there\" (ART_BIBLE 2 rule 12), \"2D portraits only\".", fill=(200, 206, 220), font=font(17))
    d.text((24, 80), "Built 7 Nov: game/assets/environment/EN_MalapertSummit and EN_RelayRoad, the rooftop screens and Noor's cut-out (README.md). No credits spent.", fill=(200, 206, 220), font=font(17))
    y = head + 12
    for im in ims:
        page.paste(im, (0, y))
        y += im.height + 24
    page.save(HERE / "00_Approval_Sheet.png", optimize=True)
    print("approval page", page.size)


def contact():
    """production/review/M3-8A_chapter8_contact.png: every exported piece (LOD0 studio still of the GLB itself), the Godot
    LOD lineup, the Godot summit, housing and road captures and the two rooftop screens (phase 2 review)."""
    prev = ROOT / "production/models/chapter8/preview"
    ev = ROOT / "production/qa/evidence"
    cat = json.loads((ROOT / "game/assets/environment/EN_MalapertSummit/malapert_summit.json").read_text())["pieces"] + \
        json.loads((ROOT / "game/assets/environment/EN_RelayRoad/relay_road.json").read_text())["pieces"]
    cell = 262
    H = 112 + 2 * (cell + 70) + 3 * 470 + 40
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    title(d, "M3-8A review contact sheet: the sixteen Chapter 8 pieces as exported, and in Godot",
          "Top: Blender Cycles studio stills of each LOD0 GLB (kit PBR textures by uri). Below: Godot 4.7 captures from game/tools/test_chapter8_assets.gd --evidence.",
          "Gate: production/review/asset_verification.md (32 GLBs). Verdicts: production/review/visual_review.md (M3-8A section).")
    y = 132
    for k, e in enumerate(cat):
        x = 20 + (k % 8) * (cell + 9)
        yy = y + (k // 8) * (cell + 70)
        panel(sheet, d, Image.open(prev / f"{e['id']}.png"), x, yy, cell, cell, e["id"].replace("EN_MalapertSummit_", "Summit ").replace("EN_RelayRoad_", "Road "),
              [f"{e['triangles'][0]} / {e['triangles'][1]} tris, {e['size_m'][1]} m high", f"{len(e.get('sockets', {}))} sockets, {len(e.get('moving_nodes', {}))} moving"], bg=(110, 110, 112))
    y += 2 * (cell + 70) + 10
    panel(sheet, d, Image.open(ev / "M3-8A_godot_lods.png"), 20, y, W - 40, 420, "Godot: game LOD (front) and Compatibility LOD (back) of every piece", None)
    y += 470
    w2 = (W - 60) // 2
    panel(sheet, d, Image.open(ev / "M3-8A_godot_summit.png"), 20, y, w2, 420, "Godot: the summit layout from malapert_summit.json under the dated Sun", None)
    panel(sheet, d, Image.open(ev / "M3-8A_godot_housing.png"), 40 + w2, y, w2, 420, "Godot: housing door on its hinge, amber status lamps, live pedestal screens", None)
    y += 470
    panel(sheet, d, Image.open(ev / "M3-8A_godot_road.png"), 20, y, w2, 420, "Godot: the marker-two pad at night (VH_Rover_Lit eva_stop, guide lights, lit beacon)", None)
    panel(sheet, d, Image.open(ev / "M3-8A_godot_rooftop_screen.png"), 40 + w2, y, w2, 420, "Godot: EN_NoorRooftop with CH_Noor_live (S10)", None)
    out = ROOT / "production/review/M3-8A_chapter8_contact.png"
    sheet.crop((0, 0, W, y + 470)).save(out, optimize=True)
    print("contact", out.relative_to(ROOT))


def main():
    which = sys.argv[1:] or ["summit", "road", "rooftop", "noor", "rao", "approval"]
    if "contact" in which: contact()
    if "summit" in which: summit_sheet()
    if "road" in which: road_sheet()
    if "rooftop" in which: rooftop_sheet()
    if "noor" in which: noor_sheet()
    if "rao" in which: rao_sheet()
    if "approval" in which: approval(None)


if __name__ == "__main__":
    main()
