#!/usr/bin/env python3
"""Compose the M3-2A Chapter 2 approval sheets and the review contact sheet from the Cycles previews that
production/tools/build_chapter2_assets.py renders (no image generation, no credits).

    python3 production/tools/chapter2_sheets.py

Reads production/models/chapter2/preview/*.png and game/assets/environment/EN_Airlock/airlock.json, writes
  production/concept/chapter2_v1/M3-2A_EN_Airlock_sheet.png     the vestibule (three Cycles views, a measured plan drawn
                                                                 from airlock.json) and its five pieces with sizes
  production/concept/chapter2_v1/M3-2A_PR_PaperBee_sheet.png    the origami bee: three-quarter, front, side, back, top, icon
  production/concept/chapter2_v1/M3-2A_PR_SeedTray_sheet.png    the clean seed tray: three-quarter, top, side
  production/review/M3-2A_chapter2_contact.png                  every piece LOD0 beside LOD1, the props and the room views
and publishes the bee's transparent render as the UI diagram icon game/assets/ui/diagrams/PR_PaperBee.png (labelled by
the S02 pollination diagram at runtime; no words in the image).
"""
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
PREVIEW = ROOT / "production/models/chapter2/preview"
CATALOG = ROOT / "game/assets/environment/EN_Airlock/airlock.json"
CONCEPT = ROOT / "production/concept/chapter2_v1"
REVIEW = ROOT / "production/review"
ICON = ROOT / "game/assets/ui/diagrams/PR_PaperBee.png"
FONT = "/System/Library/Fonts/Helvetica.ttc"
NAVY, ORANGE, WHITE, GREY, PAPER, GOLD = (31, 42, 68), (242, 107, 33), (236, 238, 240), (120, 124, 130), (246, 246, 244), (242, 194, 48)


def font(size, bold=False):
    return ImageFont.truetype(FONT, size, index=1 if bold else 0)


def tile(path, size):
    im = Image.open(path).convert("RGB")
    im.thumbnail((size, size))
    return im


def fit(path, w, h):
    im = Image.open(path).convert("RGB")
    im.thumbnail((w, h))
    return im


def title_bar(draw, width, text, sub):
    draw.rectangle([0, 0, width, 92], fill=NAVY)
    draw.text((28, 16), text, fill=WHITE, font=font(34, True))
    draw.text((28, 58), sub, fill=(200, 206, 220), font=font(18))


def labelled(sheet, draw, im, x, y, heading, lines, size):
    sheet.paste(im, (x + (size - im.width) // 2, y + (size - im.height) // 2))
    draw.rectangle([x, y, x + size, y + size], outline=(190, 192, 196), width=1)
    draw.text((x, y + size + 6), heading, fill=NAVY, font=font(16, True))
    for k, line in enumerate(lines):
        draw.text((x, y + size + 28 + 17 * k), line, fill=(60, 64, 72), font=font(13))


SHORT = {"inner_door": "inner door", "inner_hatch": "inner hatch", "outer_hatch": "outer hatch", "vestibule_panel": "panel",
         "chamber_panel": "panel", "pass_through": "pass-through", "glove_ports": "glove ports", "bench": "bench"}


def plan(catalog, scale=84, width=820):
    """Top-down plan of the vestibule from the placements, drawn at its final size so every label is legible: wall
    pieces as bars on their grid lines, furniture as footprints, short role labels nudged into the room, anchors as
    numbered dots with a key below. Godot x runs right, Godot z runs up the page."""
    import math
    layout = catalog["vestibule"]
    W, D = layout["bounds_m"]
    margin_x, top = (width - W * scale) / 2, 84  # x = 8.8 (the exterior step anchor, outside the outer hatch) stays on the page
    anchors = list(layout["anchors"].items())
    key_rows = math.ceil(len(anchors) / 3)
    img = Image.new("RGB", (width, int(top + D * scale + 60 + 18 * key_rows + 150)), PAPER)
    d = ImageDraw.Draw(img)
    kit = {p["id"]: p for p in json.loads((ROOT / "game/assets/environment/kit/kit.json").read_text())["pieces"]}
    mine = {p["id"]: p for p in catalog["pieces"]}
    tabs = {c["name"].lower(): c["role_colour"] for c in catalog["cadets"]}

    def to_px(x, z):
        return margin_x + x * scale, top + (D - z) * scale

    for gx in range(int(W) + 1):
        d.line([*to_px(gx, 0), *to_px(gx, D)], fill=(218, 218, 214), width=1)
        d.text((to_px(gx, 0)[0] - 3, to_px(gx, 0)[1] + 26), str(gx), fill=GREY, font=font(11))
    for gz in range(int(D) + 1):
        d.line([*to_px(0, gz), *to_px(W, gz)], fill=(218, 218, 214), width=1)
        d.text((to_px(0, gz)[0] - 34, to_px(0, gz)[1] - 6), str(gz), fill=GREY, font=font(11))
    # pressure zones under everything
    for zone, tint in (("vestibule", (232, 238, 246)), ("chamber", (246, 236, 228))):
        zx, zz = layout["zones"][zone]["x"], layout["zones"][zone]["z"]
        d.rectangle([*to_px(zx[0], zz[1]), *to_px(zx[1], zz[0])], fill=tint)
    colours = {"EN_Kit_DoorFrame": ORANGE, "EN_Kit_Hatch": ORANGE, "EN_Airlock_GlovePort": (46, 139, 192), "EN_Airlock_PassThrough": (46, 139, 192),
               "EN_Airlock_InterlockPanel": (142, 92, 194), "EN_Airlock_SuitLocker": (76, 175, 80), "EN_Airlock_Bench": (76, 175, 80)}
    labels = []
    for pl in layout["placements"]:
        pid, (x, _, z), yaw = pl["piece"], pl["position"], pl["yaw"]
        if pid in ("EN_Kit_FloorTile", "EN_Kit_CeilingTile"):
            continue
        entry = kit.get(pid) or mine.get(pid)
        fw, fd = entry["footprint_m"]
        if pid == "EN_Kit_Wall_Corner":
            fw, fd = 0.65, 0.15
        centred = pid in ("EN_Airlock_SuitLocker", "EN_Airlock_Bench", "EN_Kit_LightStrip")
        lz0, lz1 = (-fd / 2, fd / 2) if centred else (0.0, fd)
        if pid == "EN_Airlock_PassThrough":
            lz0, lz1 = -0.42, 0.15
        a = math.radians(yaw)
        pts = [to_px(x + lx * math.cos(a) + lz * math.sin(a), z - lx * math.sin(a) + lz * math.cos(a))
               for lx, lz in [(-fw / 2, lz0), (fw / 2, lz0), (fw / 2, lz1), (-fw / 2, lz1)]]
        role = pl.get("role", "")
        if pid == "EN_Kit_LightStrip":
            d.polygon(pts, fill=(255, 226, 150), outline=(190, 160, 90))
            continue
        colour = tabs.get(role.replace("locker_", ""), colours.get(pid, (90, 94, 100))) if role.startswith("locker_") else colours.get(pid, (90, 94, 100))
        d.polygon(pts, fill=colour, outline=(40, 44, 50))
        if role:
            # nudge the label 0.45 m into the room along the piece's facing (-Z local) so wall labels clear the walls
            nx, nz = -math.sin(a), -math.cos(a)
            depth = 0.0 if centred else 0.45
            text = role.replace("locker_", "").capitalize() if role.startswith("locker_") else SHORT.get(role, role.replace("_", " "))
            labels.append((to_px(x + nx * depth, z + nz * depth), text))
    # every label steps aside (down, up, then sideways) until it clears the anchor dots and the labels already placed
    taken = []
    for _, (x, _, z) in anchors:
        px, py = to_px(x, z)
        taken.append((px - 10, py - 10, px + 10, py + 10))

    def free_spot(cx, cy, half_w):
        for dx, dy in ((0, 0), (0, 20), (0, -20), (0, 40), (0, -40), (44, 0), (-44, 0), (44, 20), (-44, 20), (44, -20), (-44, -20)):
            box = (cx + dx - half_w, cy + dy - 9, cx + dx + half_w, cy + dy + 9)
            if all(box[2] < t[0] or box[0] > t[2] or box[3] < t[1] or box[1] > t[3] for t in taken):
                taken.append(box)
                return cx + dx, cy + dy
        return cx, cy

    for (cx, cy), text in labels:
        tw = d.textlength(text, font=font(12, True))
        cx, cy = free_spot(cx, cy, tw / 2 + 4)
        d.rectangle([cx - tw / 2 - 4, cy - 9, cx + tw / 2 + 4, cy + 9], fill=(255, 255, 255), outline=(170, 172, 176))
        d.text((cx - tw / 2, cy - 7), text, fill=(30, 30, 30), font=font(12, True))
    for zone in ("vestibule", "chamber"):
        zx = layout["zones"][zone]["x"]
        label = f"{zone} ({layout['zones'][zone]['pressure']})"
        tw = d.textlength(label, font=font(12))
        cx, cy = free_spot(to_px((zx[0] + zx[1]) / 2, 0)[0], to_px(0, D / 2)[1], tw / 2 + 2)
        d.text((cx - tw / 2, cy - 7), label, fill=(150, 156, 166), font=font(12))
    for k, (name, (x, _, z)) in enumerate(anchors):
        px, py = to_px(x, z)
        d.ellipse([px - 8, py - 8, px + 8, py + 8], fill=NAVY, outline=WHITE)
        num = str(k + 1)
        d.text((px - d.textlength(num, font=font(10, True)) / 2, py - 6), num, fill=WHITE, font=font(10, True))
    d.text((14, 12), "Plan on the 1 m grid (Godot x right, z up): 8 x 4 m, partition x = 5, chamber x 5.3 to 8", fill=NAVY, font=font(15, True))
    d.text((14, 36), "orange doors and hatches, blue sealed garden interfaces, purple interlock panels, green furniture (locker tabs in role colours), yellow light strips", fill=(90, 94, 100), font=font(11))
    y = top + D * scale + 40
    d.text((14, y), "Anchors", fill=NAVY, font=font(13, True))
    for k, (name, _) in enumerate(anchors):
        col, row = k % 3, k // 3
        d.text((14 + col * 270, y + 20 + 18 * row), f"{k + 1}  {name.replace('_', ' ')}", fill=(50, 54, 60), font=font(12))
    y += 30 + 18 * key_rows
    d.text((14, y), "Connections", fill=NAVY, font=font(13, True))
    for k, (key, value) in enumerate(layout["connections"].items()):
        d.text((14 + (k % 2) * 400, y + 20 + 18 * (k // 2)), f"{key.replace('_', ' ')}: {value}", fill=(50, 54, 60), font=font(12))
    return img


def airlock_sheet(catalog):
    width = 2200
    sheet = Image.new("RGB", (width, 2000), PAPER)
    d = ImageDraw.Draw(sheet)
    title_bar(d, width, "EN_Airlock: LOC-05 airlock and sealed transfer vestibule (M3-2A, for approval)",
              "Blender 5.2 Cycles renders of the published build (no AI image generation, no credits). Photoreal environment per the 5 Nov realism lock; the cel-shaded cast is composited at runtime (grey figure = 1.75 m scale).")
    cut = fit(PREVIEW / "EN_Airlock_room_cutaway.png", 1320, 780)
    sheet.paste(cut, (28, 112))
    d.text((28, 112 + cut.height + 6), "Cutaway with the garden wall removed: suit lockers (role tabs) and bench against the near wall, inner door to the commons, partition with the inner hatch and interlock panel, 3 m chamber with the outer hatch", fill=(60, 64, 72), font=font(13))
    pl = plan(catalog)
    sheet.paste(pl, (1372, 112))
    y2 = 112 + max(cut.height, pl.height) + 40
    cham = fit(PREVIEW / "EN_Airlock_room_chamber.png", 1060, 620)
    gard = fit(PREVIEW / "EN_Airlock_room_garden_wall.png", 1060, 620)
    sheet.paste(cham, (28, y2))
    sheet.paste(gard, (28 + cham.width + 24, y2))
    d.text((28, y2 + cham.height + 6), "Chamber through the open inner hatch: outer hatch to the surface and the chamber's own panel", fill=(60, 64, 72), font=font(13))
    d.text((28 + cham.width + 24, y2 + gard.height + 6), "Garden-side wall from the vestibule: glove-port window, pass-through chamber, handrails and quilted panels", fill=(60, 64, 72), font=font(13))
    y3 = y2 + max(cham.height, gard.height) + 44
    tris = {p["id"]: p["triangles"][0] for p in catalog["pieces"]}
    pieces = [("EN_Airlock_SuitLocker", "EVA suit locker", [f"0.6 x 0.55 x 2.2 m, {tris['EN_Airlock_SuitLocker']} tris", "RoleTab slot per cadet; blank plate"]),
              ("EN_Airlock_Bench", "Suit-up bench", [f"1.6 x 0.45 x 0.45 m, {tris['EN_Airlock_Bench']} tris", "brushed steel seat, orange boot rail"]),
              ("EN_Airlock_GlovePort", "Glove-port wall module", ["1 m wall, window at 1.75 m", f"pair of ports at 1.19 m, {tris['EN_Airlock_GlovePort']} tris"]),
              ("EN_Airlock_PassThrough", "Sealed carrier pass-through", [f"1 m two-sided wall, {tris['EN_Airlock_PassThrough']} tris", "0.50 x 0.44 m chamber, lids A/B"]),
              ("EN_Airlock_PassThrough_open", "Pass-through, room lid open", ["LidA swings 100 deg into the room", "LidB locked while A is open"]),
              ("EN_Airlock_InterlockPanel", "Pressure interlock panel", [f"1 m wall, {tris['EN_Airlock_InterlockPanel']} tris; Screen slot", "gauges, 3 lamps, wheel, lever"]),
              ("EN_Airlock_InterlockPanel_open", "Panel, cycle lever pulled", ["CycleLever child, -70 deg about X", "words are live UI, never baked"])]
    size = 290
    for k, (stem, heading, lines) in enumerate(pieces):
        name = stem.replace("_open", "_LOD0_open") if stem.endswith("_open") else stem + "_LOD0"
        labelled(sheet, d, tile(PREVIEW / f"{name}.png", size), 28 + k * (size + 18), y3, heading, lines, size)
    d.text((28, 2000 - 36), "Canon checks: English only, no text baked into any surface (panel words are a live Screen slot), no logos or NASA marks, the room is pressurised (Moon rules apply behind the outer hatch), 1 m grid and kit conventions of the approved M1-04 sheets.", fill=GREY, font=font(13))
    return sheet


def bee_sheet(catalog):
    width = 2060
    sheet = Image.new("RGB", (width, 1250), PAPER)
    d = ImageDraw.Draw(sheet)
    title_bar(d, width, "PR_PaperBee: Rafi's origami bee (M3-2A, for approval)",
              "Folded from one duo sheet, gold face and navy reverse, white wings; no face, no eyes, no text. About 9 cm long. EX-CH02-S02 'I brought the bee.'; S07 its folded wing brushes the recorder.")
    main = fit(PREVIEW / "PR_PaperBee_LOD0.png", 760, 760)
    sheet.paste(main, (28, 112))
    d.text((28, 112 + main.height + 6), "Three-quarter view. Pleated abdomen with alternating gold and navy bands, pointed head, kite wings, six strip legs, two antennae.", fill=(60, 64, 72), font=font(13))
    views = [("front", "Front (head towards -Z)"), ("side", "Side"), ("back", "Back"), ("top", "Top")]
    size = 400
    for k, (v, heading) in enumerate(views):
        x = 820 + (k % 2) * (size + 20)
        y = 112 + (k // 2) * (size + 70)
        labelled(sheet, d, tile(PREVIEW / f"PR_PaperBee_LOD0_{v}.png", size), x, y, heading, [], size)
    icon = Image.open(PREVIEW / "PR_PaperBee_icon.png").convert("RGBA")
    icon.thumbnail((300, 300))
    panel = Image.new("RGBA", (340, 340), (255, 255, 255, 255))
    panel.paste(icon, ((340 - icon.width) // 2, (340 - icon.height) // 2), icon)
    sheet.paste(panel.convert("RGB"), (1680, 112))
    d.rectangle([1680, 112, 2020, 452], outline=(190, 192, 196))
    d.text((1680, 458), "UI diagram icon (transparent)", fill=NAVY, font=font(16, True))
    for k, line in enumerate(["game/assets/ui/diagrams/PR_PaperBee.png", "labelled by the S02 pollination", "diagram at runtime; no words", "in the image"]):
        d.text((1680, 480 + 17 * k), line, fill=(60, 64, 72), font=font(13))
    bee = next(p for p in catalog["props"] if p["id"] == "PR_PaperBee")
    dims = " x ".join(f"{v:.3f}" for v in bee["size_m"])
    spec = [f"Size {dims} m (longest {max(bee['size_m']):.3f}), {bee['triangles']} triangles, 256 px paper sets embedded in the GLB (small prop budget: up to 5k triangles, 1K textures).",
            "Sockets: Socket_Grip on the thorax (held), Socket_Rest at the base (placed); the folded, held and placed states share the one mesh.",
            "States in play: on the bench beside the protocol (S02); left as a reminder (S02 -> S03 bridge); beside the finished record (S07), its wing brushing the",
            "horticulture recorder and lifting the sticker corner (S07 -> S08 bridge: the equipment number is on the recorder's label, never on the bee).",
            "It never replaces the sealed reciprocal pollen-transfer procedure (PR_PollinationKit: the carrier and brushes A/B through the airlock pass-through)."]
    for k, line in enumerate(spec):
        d.text((28, 1080 + 22 * k), line, fill=(60, 64, 72), font=font(14))
    return sheet


def tray_sheet(catalog):
    width = 1800
    sheet = Image.new("RGB", (width, 760), PAPER)
    d = ImageDraw.Draw(sheet)
    title_bar(d, width, "PR_SeedTray: Kai's clean seed tray (M3-2A, for approval)",
              "The CH02 S06 -> S07 bridge object ('Kai brings a clean seed tray'); 0.50 m like PL_ZeroSeedlingTray so the Chapter 3 descendants (PL_Descendants, 12 positions) can sit in it.")
    size = 520
    tray = next(p for p in catalog["props"] if p["id"] == "PR_SeedTray")
    dims = " x ".join(f"{v:.3g}" for v in tray["size_m"])
    for k, (v, heading, lines) in enumerate([("", "Three-quarter", [f"{dims} m over the tabs, {tray['triangles']} triangles"]),
                                             ("_top", "Top: 4 x 3 empty cells", ["cells 9 x 8 cm with a draft, 4.5 cm deep"]),
                                             ("_side", "Side", ["off-white plastic, navy rim, orange grip tabs"])]):
        labelled(sheet, d, tile(PREVIEW / f"PR_SeedTray_LOD0{v}.png", size), 28 + k * (size + 40), 112, heading, lines, size)
    return sheet


def contact(catalog):
    pieces = [p["id"] for p in catalog["pieces"]]
    size = 300
    cols = 4
    rows_pieces = len(pieces)
    width = 28 + cols * (size + 18) + 28
    height = 112 + rows_pieces * (size + 60) + 2 * (size + 60) + 420
    sheet = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(sheet)
    title_bar(d, width, "M3-2A Chapter 2 assets: review contact sheet", "LOD0 (game, with collision) beside LOD1 (Compatibility) for every airlock piece; the two props; the three vestibule views")
    y = 112
    for pid in pieces:
        entry = next(p for p in catalog["pieces"] if p["id"] == pid)
        views = [(f"{pid}_LOD0", f"{pid} LOD0", [f"{entry['triangles'][0]} tris, {entry['size_m']} m"]), (f"{pid}_LOD1", "LOD1", [f"{entry['triangles'][1]} tris, 512 px"])]
        for extra, heading in ((f"{pid}_LOD0_open", "LOD0 moving part open"), (f"{pid}_LOD0_far", "LOD0 far side")):
            if (PREVIEW / f"{extra}.png").exists():
                views.append((extra, heading, []))
        for k, (stem, heading, lines) in enumerate(views):
            labelled(sheet, d, tile(PREVIEW / f"{stem}.png", size), 28 + k * (size + 18), y, heading, lines, size)
        y += size + 60
    for pid in ("PR_PaperBee", "PR_SeedTray"):
        entry = next(p for p in catalog["props"] if p["id"] == pid)
        views = [(f"{pid}_LOD0", f"{pid}", [f"{entry['triangles']} tris, {entry['size_m']} m"]), (f"{pid}_LOD0_front", "front", []), (f"{pid}_LOD0_side", "side", []), (f"{pid}_LOD0_top", "top", [])]
        for k, (stem, heading, lines) in enumerate(views):
            labelled(sheet, d, tile(PREVIEW / f"{stem}.png", size), 28 + k * (size + 18), y, heading, lines, size)
        y += size + 60
    for k, (stem, heading) in enumerate((("EN_Airlock_room_cutaway", "vestibule cutaway"), ("EN_Airlock_room_chamber", "chamber"), ("EN_Airlock_room_garden_wall", "garden wall"))):
        im = fit(PREVIEW / f"{stem}.png", 400, 300)
        sheet.paste(im, (28 + k * 424, y))
        d.text((28 + k * 424, y + im.height + 6), heading, fill=NAVY, font=font(14, True))
    return sheet


def main():
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    CONCEPT.mkdir(parents=True, exist_ok=True)
    airlock_sheet(catalog).save(CONCEPT / "M3-2A_EN_Airlock_sheet.png")
    bee_sheet(catalog).save(CONCEPT / "M3-2A_PR_PaperBee_sheet.png")
    tray_sheet(catalog).save(CONCEPT / "M3-2A_PR_SeedTray_sheet.png")
    contact(catalog).save(REVIEW / "M3-2A_chapter2_contact.png")
    ICON.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(PREVIEW / "PR_PaperBee_icon.png", ICON)
    print("sheets written:", CONCEPT, REVIEW / "M3-2A_chapter2_contact.png", "and", ICON.relative_to(ROOT))


if __name__ == "__main__":
    main()
