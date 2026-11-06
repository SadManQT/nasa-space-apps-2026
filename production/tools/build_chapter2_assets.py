"""Build the Chapter 2 (Be the Bee) assets with Blender alone (board M3-2A): no generation service, no credits.

    python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 \
        --python production/tools/build_chapter2_assets.py [-- --no-render | --only ID,ID | --cpu | --room-only]

--only re-renders the previews of the listed pieces without touching the published files; --room-only renders
only the assembled vestibule views; --cpu avoids the Metal path.

What it builds (deterministic, seed 20261105; the design reference is the LOC-05 brief in
game-design/09_WORLD_AND_LEVEL_DESIGN.md and the approved habitat kit sheets of M1-04):

  EN_Airlock (environment, kit extension) -> game/assets/environment/EN_Airlock/
    EN_Airlock_SuitLocker     0.6 x 0.55 x 2.2 m open-front EVA suit locker; material slot "RoleTab" for the cadet colour
    EN_Airlock_Bench          1.6 x 0.45 x 0.45 m brushed-steel suit-up bench
    EN_Airlock_GlovePort      1 m wall module: pressure window and a pair of glove ports (sleeves on the far side)
    EN_Airlock_PassThrough    1 m two-sided wall module with the sealed carrier pass-through chamber; children LidA / LidB
    EN_Airlock_InterlockPanel 1 m wall module: "Screen" slot (live SEALED / EQUALISING / SAFE TO OPEN text), two
                              pressure gauges, three state lamps (LampSealed / LampEqualising / LampSafe materials),
                              equalisation wheel, pump grille; child CycleLever
    Each as <id>_LOD0.glb (collision nodes) and <id>_LOD1.glb (Compatibility LOD), on the kit's conventions
    (metres, +Y up, wall faces on z = 0 facing -Z, pivot at the base centre). The pieces tile the kit's PBR sets and
    reference them by uri in ../kit/textures (nothing is stored twice). airlock.json is the catalogue plus the 8 x 4 m
    double-interlock vestibule layout that game/assets/environment/EN_Airlock/en_airlock.gd assembles.

  PR_PaperBee  -> game/assets/props/PR_PaperBee/PR_PaperBee.glb   origami bee folded from gold/navy duo paper,
                  about 9 cm long; sockets Socket_Grip and Socket_Rest; textures embedded (small prop)
  PR_SeedTray  -> game/assets/props/PR_SeedTray/PR_SeedTray.glb   clean empty 12-cell seed tray, 0.50 m longest
                  (the CH02 S06 -> S07 bridge object; the base of the CH03 descendant tray)

  production/manifest/chapter2_assets.csv       gate specs for production/tools/verify_gate.py
  production/models/chapter2/preview/*.png      Cycles previews for production/tools/chapter2_sheets.py

Canon kept: English only and no text baked anywhere (the panel words are a live UI slot), no logos, nothing implies
NASA, the plants are not in this set, the airlock is a pressurised room (the Moon rules of ART_BIBLE.md section 2 apply
to the exterior behind the outer hatch).
"""
import csv
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_habitat_kit as hk  # noqa: E402  (Builder, materials, export and preview helpers of the M1-05 kit)
from glb_external_textures import externalise  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
KIT = ROOT / "game/assets/environment/kit"
OUT_ENV = ROOT / "game/assets/environment/EN_Airlock"
OUT_PROPS = ROOT / "game/assets/props"
STAGE = ROOT / "production/models/chapter2"
SEED = 20261105
TASK = "M3-2A"
SOURCE_ENV = "tools/build_chapter2_assets.py (seed 20261105): LOC-05 brief (09_WORLD_AND_LEVEL_DESIGN) on the approved M1-04 kit conventions"
SOURCE_PROP = "tools/build_chapter2_assets.py (seed 20261105): procedural Blender geometry, STORY_FULL EX-CH02-S02/S07"
WALL_H, WALL_D, RAIL = hk.WALL_H, hk.WALL_D, hk.RAIL
LOD_DISTANCE_M = hk.LOD_DISTANCE_M
RENDER = "--no-render" not in sys.argv
ONLY = sys.argv[sys.argv.index("--only") + 1].split(",") if "--only" in sys.argv else []
ROOM_ONLY = "--room-only" in sys.argv
hk.CPU_RENDER = "--cpu" in sys.argv
Builder = hk.Builder
COL = hk.COL_SUFFIXES

# ----------------------------------------------------------------------------------------------- textures and materials

def load_kit_images():
    """The kit's published texture sets, loaded from disk under their kit names so the exporter keeps the names and
    the GLBs can reference the one shared copy. Returns {lod: {key: {base, normal, orm, tile}}} like hk.make_textures."""
    catalogue = json.loads((KIT / "kit.json").read_text(encoding="utf-8"))
    tiles = {m["id"].replace("M_Kit_", ""): float(m["tile_m"]) for m in catalogue["materials"]}
    images = {0: {}, 1: {}}
    for lod, folder, suffix in ((0, KIT / "textures", ""), (1, KIT / "textures" / "lod1", "_LOD1")):
        for key in hk.MATERIAL_KEYS:
            shared = "Paint" if key.startswith("Paint") else key
            maps = {}
            for kind, stem, srgb in (("base", f"T_Kit_{key}_BaseColor", True), ("normal", f"T_Kit_{shared}_Normal", False), ("orm", f"T_Kit_{shared}_ORM", False)):
                name = stem + suffix
                image = bpy.data.images.get(name)
                if image is None:
                    image = bpy.data.images.load(str(folder / (name + ".png")), check_existing=True)
                    image.name = name
                    image.colorspace_settings.name = "sRGB" if srgb else "Non-Color"
                maps[kind] = image
            images[lod][key] = dict(maps, tile=tiles[key])
    return images


def airlock_materials(images):
    """The kit's material table per LOD plus the airlock's own plain slots (role tab, three state lamps)."""
    mats = hk.make_materials(images)
    for lod, table in mats.items():
        suffix = "" if lod == 0 else "_LOD1"
        table["RoleTab"] = (hk.pbr_material("RoleTab" + suffix, None, 0.45, (0.52, 0.54, 0.57)), 1.0)
        table["LampSealed"] = (hk.pbr_material("LampSealed" + suffix, None, 0.25, (0.55, 0.06, 0.04), emission=((1.0, 0.10, 0.06), 1.5)), 1.0)
        table["LampEqualising"] = (hk.pbr_material("LampEqualising" + suffix, None, 0.25, (0.60, 0.38, 0.05), emission=((1.0, 0.62, 0.10), 0.8)), 1.0)
        table["LampSafe"] = (hk.pbr_material("LampSafe" + suffix, None, 0.25, (0.08, 0.45, 0.14), emission=((0.20, 1.0, 0.35), 0.6)), 1.0)
    return mats


def surface_family(rng, name, size, fibre, rough, tile, directory):
    """One height field per surface family (paper, plastic): the normal map and ORM every tint of it shares."""
    height = hk.fractal(rng, size, 6, size / 3, 1.4) * fibre
    orm = np.ones((size, size, 3), dtype=np.float32)
    orm[:, :, 1] = np.clip(rough + 0.06 * height, 0, 1)
    orm[:, :, 2] = 0.0
    return dict(height=height, tile=tile,
                normal=hk.save_image(f"T_{name}_Normal", hk.normal_map(height * 0.0004, tile), directory, srgb=False),
                orm=hk.save_image(f"T_{name}_ORM", orm, directory, srgb=False))


def tinted_set(family, name, tint, directory):
    """A tinted base colour over the family's grain: 256 px is 0.2 mm per pixel on a 5 cm paper tile."""
    shade = 1.0 + 0.5 * hk.half(family["height"]) if family["height"].shape[0] > 256 else 1.0 + 0.5 * family["height"]
    base = np.clip(np.array(tint)[None, None, :] * shade[:, :, None], 0, 1)
    return dict(base=hk.save_image(f"T_{name}_BaseColor", base, directory), normal=family["normal"], orm=family["orm"], tile=family["tile"])


def prop_materials():
    """Paper (duo gold/navy and plain white) and tray plastic; 256 px sets embedded in the prop GLBs (textures stay
    embedded for props, handbook section 6), one normal map and ORM per family."""
    rng = np.random.default_rng(SEED + 7)
    directory = STAGE / "textures"
    directory.mkdir(parents=True, exist_ok=True)
    paper = surface_family(rng, "Paper", 256, 0.10, 0.86, 0.05, directory)
    plastic = surface_family(rng, "Plastic", 256, 0.04, 0.45, 0.10, directory)
    sets = {
        "PaperGold": tinted_set(paper, "PaperGold", (0.95, 0.76, 0.19), directory),
        "PaperNavy": tinted_set(paper, "PaperNavy", (0.12, 0.165, 0.27), directory),
        "PaperWhite": tinted_set(paper, "PaperWhite", (0.93, 0.93, 0.92), directory),
        "PlasticWhite": tinted_set(plastic, "PlasticWhite", (0.90, 0.91, 0.92), directory),
        "PlasticNavy": tinted_set(plastic, "PlasticNavy", (0.12, 0.165, 0.27), directory),
        "PlasticOrange": tinted_set(plastic, "PlasticOrange", (0.95, 0.42, 0.13), directory),
    }
    return {key: (hk.pbr_material("M_" + key, maps), maps["tile"]) for key, maps in sets.items()}

# ----------------------------------------------------------------------------------------------- airlock pieces

LOCKER_W, LOCKER_D, LOCKER_H = 0.60, 0.55, 2.20


def piece_suit_locker(b, lod):
    """Open-front EVA suit locker: steel hanger rail, helmet shelf, boot tray, backpack brackets, retaining bar with an
    orange latch, a blank name plate and the role-colour tab (material slot RoleTab, recoloured per cadet at runtime)."""
    w, d, h, t = LOCKER_W, LOCKER_D, LOCKER_H, 0.03
    segs = 12 if lod == 0 else 6
    b.box((0, h / 2, d / 2 - t / 2), (w, h, t), "PaintGrey")
    for sx in (-1, 1):
        b.box((sx * (w / 2 - t / 2), h / 2, 0), (t, h, d), "PaintGrey")
    b.box((0, h - t / 2, 0), (w - 2 * t, t, d), "PaintGrey")
    b.box((0, 0.05, 0), (w - 2 * t, 0.10, d), "PaintNavy")
    b.box((0, (h + 0.10 - t) / 2, d / 2 - t - 0.005), (w - 2 * t, h - 0.10 - t, 0.01), "PaintWhite")
    for sx in (-1, 1):
        b.box((sx * (w / 2 - t - 0.025), (h + 0.10 - t) / 2, -d / 2 + 0.02), (0.05, h - 0.10 - t, 0.04), "PaintGrey")
    b.box((0, h - t - 0.06, -d / 2 + 0.02), (w - 2 * t, 0.12, 0.04), "PaintGrey")
    b.box((0, h - t - 0.06, -d / 2 - 0.003), (0.18, 0.05, 0.006), "PaintWhite")
    b.box((0, 0.17, -d / 2 + 0.015), (w - 2 * t, 0.14, 0.03), "PaintNavy")
    b.box((0, 1.86, 0.06), (w - 2 * t - 0.02, 0.02, d - 0.18), "Steel")
    b.cylinder((-w / 2 + t + 0.02, 1.78, 0.0), (w / 2 - t - 0.02, 1.78, 0.0), 0.012, "Steel", segs=segs)
    b.box((0, 0.11, 0.05), (w - 2 * t - 0.04, 0.02, d - 0.15), "PaintNavy")
    b.box((0, 0.145, -0.17), (w - 2 * t - 0.04, 0.05, 0.02), "PaintNavy")
    for sx in (-1, 1):
        b.box((sx * 0.15, 1.15, d / 2 - t - 0.04), (0.04, 0.30, 0.06), "Steel")
    b.cylinder((-w / 2 + t + 0.03, 1.0, -d / 2 + 0.05), (w / 2 - t - 0.03, 1.0, -d / 2 + 0.05), 0.012, "Steel", segs=segs)
    b.box((w / 2 - t - 0.07, 1.0, -d / 2 + 0.05), (0.06, 0.05, 0.04), "PaintOrange")
    b.box((-w / 2 + t + 0.025, 1.75, -d / 2 - 0.005), (0.04, 0.40, 0.01), "RoleTab")
    if lod == 0:
        for k in range(6):
            b.box((0, 0.45 + k * 0.08, d / 2 - t - 0.012), (w - 2 * t - 0.08, 0.012, 0.004), "PaintDark")
        for sx in (-1, 1):
            b.torus((sx * 0.18, 1.86 + 0.03, 0.06), (0, 1, 0), 0.025, 0.005, "Steel", segs=12, rings=6)
    return [("SuitLocker_Col-convcolonly", (0, h / 2, 0), (w, h, d))]


BENCH_L, BENCH_D, BENCH_H = 1.60, 0.45, 0.45
SEAT_GRAIN = 4.0  # the kit's steel tile (0.25 m) is sized for rails; on a 1.6 m flat seat it reads as coarse fur up close


def piece_bench(b, lod):
    """Suit-up bench: brushed steel seat on two navy pedestals, a cross rail, an orange boot rail, tie-down rings.
    The seat's UVs repeat the kit's steel SEAT_GRAIN times as often, so the brushing reads at a real (sub-cm) scale."""
    L, D, H, t = BENCH_L, BENCH_D, BENCH_H, 0.04
    segs = 12 if lod == 0 else 6
    first = len(b.uvs)
    b.box((0, H - t / 2, 0), (L, t, D - 0.05), "Steel")
    b.uvs[first:] = [[(u * SEAT_GRAIN, v * SEAT_GRAIN) for u, v in face] for face in b.uvs[first:]]
    for sx in (-1, 1):
        b.box((sx * (L / 2 - 0.06), (H - t) / 2, 0), (0.08, H - t, D - 0.08), "PaintNavy")
    b.cylinder((-L / 2 + 0.1, 0.20, 0), (L / 2 - 0.1, 0.20, 0), 0.018, "Steel", segs=segs)
    b.cylinder((-L / 2 + 0.1, 0.09, -D / 2 + 0.03), (L / 2 - 0.1, 0.09, -D / 2 + 0.03), 0.015, "PaintOrange", segs=segs)
    if lod == 0:
        for k in range(4):
            x = -L / 2 + 0.2 + k * (L - 0.4) / 3
            b.box((x, H - t - 0.02, 0), (0.03, 0.04, D - 0.12), "PaintGrey")
        for sx in (-1, 1):
            b.torus((sx * (L / 2 - 0.06), 0.06, -D / 2 + 0.04), (0, 0, 1), 0.03, 0.006, "Steel", segs=12, rings=6)
    return [("Bench_Col-convcolonly", (0, H / 2, 0), (L, H, D))]


def window_frame(b, w, h, cy, lip, lod):
    """The kit window's navy pressure frame, pane and bolts (piece_wall_window), reused by the glove-port module."""
    n_arc = 6 if lod == 0 else 2
    inner, outer = hk.rounded_rect(w, h, 0.10, n_arc), hk.rounded_rect(w + 2 * lip, h + 2 * lip, 0.18, n_arc)
    b.ring_prism([(x, cy + y, -0.05) for x, y in inner], [(x, cy + y, -0.05) for x, y in outer], (0, 0, 0.12), "PaintNavy", (0, 0, -1), centre=(0, cy, -0.05), smooth_inner=True)
    pane = [(x * 0.98, cy + y * 0.98, 0.03) for x, y in inner]
    base = b.add_verts(pane)
    b.add_face([base + i for i in range(len(pane))], [(x, y) for x, y, _ in pane], "Glass", False, outward=(0, 0, -1))
    if lod == 0:
        for x, y in hk.rounded_rect(w + lip, h + lip, 0.14, 3):
            b.cylinder((x, cy + y, -0.05), (x, cy + y, -0.056), 0.009, "Steel", segs=8)


PORT_Y, PORT_X, PORT_R = 1.19, 0.22, 0.135


def piece_glove_port(b, lod):
    """Wall module with the pressure window at 1.75 m and a pair of glove ports at 1.19 m into the sealed plant
    chamber on its far side; the sleeves hang on the far side so they read through the window."""
    hk.wall_frame(b, 1.0)
    w, h, cy, lip = 0.56, 0.42, 1.75, 0.08
    band_y0, band_y1 = 0.92, cy - h / 2 - lip
    segs = 24 if lod == 0 else 10
    hk.quilt_region(b, -0.46, 0.33, 0.92, band_y0 - 0.33, lod)
    hk.quilt_region(b, -0.46, cy + h / 2 + lip, 0.92, WALL_H - RAIL - (cy + h / 2 + lip), lod)
    b.box((0, (band_y0 + band_y1) / 2, 0.03), (0.92, band_y1 - band_y0, 0.04), "PaintNavy")
    side = (0.92 - w - 2 * lip) / 2
    for sx in (-1, 1):
        b.box((sx * (w / 2 + lip + side / 2), cy, 0.03), (side, h + 2 * lip, 0.02), "PaintGrey")
    window_frame(b, w, h, cy, lip, lod)
    for sx in (-1, 1):
        cx = sx * PORT_X
        circle = lambda rad, z: [(cx + rad * math.cos(a), PORT_Y + rad * math.sin(a), z) for a in (2 * math.pi * i / segs for i in range(segs))]
        b.ring_prism(circle(PORT_R - 0.045, -0.035), circle(PORT_R, -0.035), (0, 0, 0.045), "PaintGrey", (0, 0, -1), centre=(cx, PORT_Y, -0.035), smooth_inner=True)
        b.torus((cx, PORT_Y, -0.035), (0, 0, 1), PORT_R - 0.02, 0.012, "Steel", segs=segs, rings=6)
        b.cylinder((cx, PORT_Y, -0.03), (cx, PORT_Y, 0.01), PORT_R - 0.047, "PaintDark", segs=segs)
        b.cylinder((cx, PORT_Y, WALL_D), (cx, PORT_Y, WALL_D + 0.42), PORT_R - 0.045, "PaintDark", segs=segs, radius1=0.05)
        b.box((cx, PORT_Y - 0.03, WALL_D + 0.50), (0.11, 0.05, 0.16), "PaintDark")
        if lod == 0:
            for k in range(8):
                a = 2 * math.pi * (k + 0.5) / 8
                p = Vector((cx + (PORT_R - 0.012) * math.cos(a), PORT_Y + (PORT_R - 0.012) * math.sin(a), -0.035))
                b.cylinder(p, p + Vector((0, 0, -0.007)), 0.008, "Steel", segs=8)
    if lod == 0:
        for sx in (-1, 1):
            b.box((sx * 0.30, 0.98, 0.008), (0.10, 0.02, 0.004), "PaintOrange")
    return [("GlovePort_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D))]


PT_W, PT_H, PT_Y0, PT_DEPTH = 0.50, 0.44, 1.00, 0.42  # chamber opening, sill height, how far the chamber stands into the room


def piece_pass_through(b, lod):
    """Two-sided 1 m bulkhead with the sealed carrier pass-through: a white-lined chamber through the wall, a lid on
    each side (children LidA room side, LidB far side; only one opens at a time), gauge and equalisation lever."""
    x0, x1, y0, y1 = -PT_W / 2, PT_W / 2, PT_Y0, PT_Y0 + PT_H
    body_z0 = 0.04  # the body sits behind the front rails, as in hk.wall_frame
    hole = [(x0, y0, body_z0), (x1, y0, body_z0), (x1, y1, body_z0), (x0, y1, body_z0)]
    rect = [(-0.5, 0, body_z0), (0.5, 0, body_z0), (0.5, WALL_H, body_z0), (-0.5, WALL_H, body_z0)]
    b.ring_prism(hole, rect, (0, 0, WALL_D - body_z0), "PaintGrey", (0, 0, -1), centre=(0, (y0 + y1) / 2, body_z0))
    for zz in (0.025, WALL_D + 0.025):  # rails and skirting on both finished faces
        b.box((0, 0.15, zz + 0.005), (0.92, 0.30, 0.06), "PaintNavy")
        b.box((0, 0.315, zz), (0.92, 0.03, 0.04), "PaintGrey")
        b.box((0, WALL_H - RAIL / 2, zz), (0.92, RAIL, 0.05), "PaintGrey")
        for sx in (-1, 1):
            b.box((sx * (0.5 - RAIL / 2), WALL_H / 2, zz), (RAIL, WALL_H, 0.05), "PaintGrey")
    # the quilt sits 2 mm proud of the body face so the flat LOD1 quilt cannot z-fight with it
    hk.quilt_region(b, -0.46, 0.33, 0.92, 0.95 - 0.33, lod, z=body_z0 - 0.002)
    hk.quilt_region(b, -0.46, 1.52, 0.92, WALL_H - RAIL - 1.52, lod, z=body_z0 - 0.002)
    for sx in (-1, 1):
        b.box((sx * 0.40, 1.235, 0.03), (0.12, 0.57, 0.02), "PaintGrey")
    # chamber box standing into the room: shell, front frame, white liner through the wall
    bw, bh, cy = PT_W + 0.10, PT_H + 0.10, (y0 + y1) / 2
    b.box((0, cy, -PT_DEPTH / 2), (bw, bh, PT_DEPTH), "PaintGrey", skip=((0, 0, -1), (0, 0, 1)))
    front_in = [(x0, y0, -PT_DEPTH), (x1, y0, -PT_DEPTH), (x1, y1, -PT_DEPTH), (x0, y1, -PT_DEPTH)]
    front_out = [(-bw / 2, cy - bh / 2, -PT_DEPTH), (bw / 2, cy - bh / 2, -PT_DEPTH), (bw / 2, cy + bh / 2, -PT_DEPTH), (-bw / 2, cy + bh / 2, -PT_DEPTH)]
    b.ring_prism(front_in, front_out, (0, 0, 0.03), "PaintGrey", (0, 0, -1), centre=(0, cy, -PT_DEPTH))
    liner = 0.012
    b.quad([(x0 + liner, y0 + liner, -PT_DEPTH + 0.03), (x1 - liner, y0 + liner, -PT_DEPTH + 0.03), (x1 - liner, y0 + liner, WALL_D), (x0 + liner, y0 + liner, WALL_D)], "PaintWhite", outward=(0, 1, 0))
    b.quad([(x0 + liner, y1 - liner, -PT_DEPTH + 0.03), (x1 - liner, y1 - liner, -PT_DEPTH + 0.03), (x1 - liner, y1 - liner, WALL_D), (x0 + liner, y1 - liner, WALL_D)], "PaintWhite", outward=(0, -1, 0))
    for sx, xx in ((1, x0 + liner), (-1, x1 - liner)):
        b.quad([(xx, y0 + liner, -PT_DEPTH + 0.03), (xx, y1 - liner, -PT_DEPTH + 0.03), (xx, y1 - liner, WALL_D), (xx, y0 + liner, WALL_D)], "PaintWhite", outward=(sx, 0, 0))
    b.box((0, y0 + liner + 0.004, (-PT_DEPTH + 0.03 + WALL_D) / 2), (PT_W - 2 * liner - 0.02, 0.008, PT_DEPTH - 0.03 + WALL_D - 0.02), "Steel")
    # navy seal frames around both openings, gauge, equalisation lever and the state lamp on the chamber front
    n_arc = 4 if lod == 0 else 2
    for zz, direction in ((-PT_DEPTH, -1), (WALL_D, 1)):
        inner = [(x, cy + y, zz) for x, y in hk.rounded_rect(PT_W + 0.02, PT_H + 0.02, 0.04, n_arc)]
        outer = [(x, cy + y, zz) for x, y in hk.rounded_rect(PT_W + 0.08, PT_H + 0.08, 0.07, n_arc)]
        b.ring_prism(inner, outer, (0, 0, direction * 0.012), "PaintNavy", (0, 0, direction), centre=(0, cy, zz))
    segs = 20 if lod == 0 else 8
    b.cylinder((bw / 2 - 0.09, cy + bh / 2 + 0.07, -0.18), (bw / 2 - 0.09, cy + bh / 2 + 0.03, -0.18), 0.05, "PaintDark", segs=segs)
    b.torus((bw / 2 - 0.09, cy + bh / 2 + 0.07, -0.18), (0, 1, 0), 0.05, 0.006, "Steel", segs=segs, rings=6)
    b.cylinder((-bw / 2 + 0.10, cy + bh / 2, -0.20), (-bw / 2 + 0.10, cy + bh / 2 + 0.05, -0.20), 0.016, "Steel", segs=12 if lod == 0 else 6)
    b.cylinder((-bw / 2 + 0.10, cy + bh / 2 + 0.05, -0.20), (-bw / 2 + 0.10, cy + bh / 2 + 0.05, -0.33), 0.012, "PaintOrange", segs=12 if lod == 0 else 6)
    b.cylinder((bw / 2 - 0.05, cy - bh / 2 - 0.03, -PT_DEPTH + 0.01), (bw / 2 - 0.05, cy - bh / 2 - 0.03, -PT_DEPTH - 0.012), 0.016, "LampSafe", segs=12 if lod == 0 else 6)
    hk.handle(b, (-0.43, 1.75, 0.01), 0.5, lod)
    return [("PassThroughWall_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D)),
            ("PassThroughChamber_Col-convcolonly", (0, cy, -PT_DEPTH / 2), (bw, bh, PT_DEPTH))]


def pass_through_lid(direction):
    """A lid around its hinge pivot: hinged at one side, it covers the opening with a glass port, a navy seal and
    an orange latch; direction -1 is the room-side lid (LidA), +1 the far-side lid (LidB)."""
    def build(b, lod):
        sign = -direction  # LidA extends +X from a left hinge, LidB extends -X from a right hinge
        cx = sign * (PT_W / 2 + 0.03)
        zc = direction * 0.02
        b.box((cx, 0, zc), (PT_W + 0.06, PT_H + 0.06, 0.035), "PaintGrey")
        segs = 20 if lod == 0 else 8
        b.cylinder((cx, 0, zc), (cx, 0, zc + direction * 0.03), 0.12, "PaintNavy", segs=segs)
        b.cylinder((cx, 0, zc + direction * 0.03), (cx, 0, zc + direction * 0.031), 0.095, "Glass", segs=segs)
        b.box((cx + sign * (PT_W / 2 - 0.05), -0.02, zc + direction * 0.04), (0.05, 0.10, 0.045), "PaintOrange")
        for yy in (-PT_H / 2 + 0.06, PT_H / 2 - 0.06):
            b.cylinder((0, yy - 0.04, zc), (0, yy + 0.04, zc), 0.022, "Steel", segs=12 if lod == 0 else 6)
        if lod == 0:
            for k in range(8):
                a = 2 * math.pi * (k + 0.5) / 8
                p = Vector((cx + 0.145 * math.cos(a), 0.145 * math.sin(a), zc + direction * 0.018))
                b.cylinder(p, p + Vector((0, 0, direction * 0.006)), 0.007, "Steel", segs=8)
        return [(f"Lid{'A' if direction < 0 else 'B'}_Col-convcolonly", (cx, 0, zc), (PT_W + 0.06, PT_H + 0.06, 0.07))]
    return build


LEVER_X, LEVER_Y = 0.27, 0.88


def piece_interlock_panel(b, lod):
    """The airlock pressure interlock: Screen slot for the live state words, two analogue pressure gauges, three state
    lamps, the equalisation wheel, a pump grille and the cycle lever pivot (child CycleLever)."""
    hk.wall_frame(b, 1.0)
    bay_w, bay_h, bay_y0, depth = 0.74, 1.34, 0.62, 0.11
    segs = 24 if lod == 0 else 10
    hk.quilt_region(b, -0.46, bay_y0 + bay_h + 0.03, 0.92, WALL_H - RAIL - (bay_y0 + bay_h + 0.03), lod)
    b.box((0, (0.33 + bay_y0) / 2, 0.02), (0.92, bay_y0 - 0.33, 0.02), "PaintGrey")
    b.box((0, bay_y0 + bay_h + 0.015, 0.02), (0.92, 0.03, 0.02), "PaintGrey")
    side_w = (0.92 - bay_w) / 2
    for sx in (-1, 1):
        b.box((sx * (bay_w / 2 + side_w / 2), bay_y0 + bay_h / 2, 0.02), (side_w, bay_h, 0.02), "PaintGrey")
    b.recess(-bay_w / 2, bay_w / 2, bay_y0, bay_y0 + bay_h, 0.01, 0.01 + depth, "PaintGrey")
    b.box((0, bay_y0 + bay_h / 2, 0.075), (bay_w - 0.06, bay_h - 0.06, 0.06), "PaintNavy")
    b.box((0, 1.70, 0.04425), (0.52, 0.32, 0.0015), "PaintDark")
    b.quad([(-0.25, 1.55, 0.043), (0.25, 1.55, 0.043), (0.25, 1.85, 0.043), (-0.25, 1.85, 0.043)], "Screen", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 0, -1))
    for sx in (-1, 1):
        gx = sx * 0.17
        b.cylinder((gx, 1.33, 0.045), (gx, 1.33, 0.030), 0.075, "PaintDark", segs=segs)
        b.torus((gx, 1.33, 0.030), (0, 0, 1), 0.075, 0.007, "Steel", segs=segs, rings=6)
        if lod == 0:
            b.box((gx + sx * 0.022, 1.345, 0.028), (0.05, 0.004, 0.003), "PaintOrange")
            b.cylinder((gx, 1.33, 0.030), (gx, 1.33, 0.026), 0.006, "Steel", segs=8)
    for x, key in ((-0.18, "LampSealed"), (0.0, "LampEqualising"), (0.18, "LampSafe")):
        b.cylinder((x, 1.10, 0.045), (x, 1.10, 0.025), 0.028, "Steel", segs=16 if lod == 0 else 8)
        b.cylinder((x, 1.10, 0.025), (x, 1.10, 0.018), 0.021, key, segs=16 if lod == 0 else 8)
    b.cylinder((LEVER_X, LEVER_Y, 0.045), (LEVER_X, LEVER_Y, -0.01), 0.035, "Steel", segs=16 if lod == 0 else 8)
    wc = (-0.18, 0.90, -0.02)
    b.cylinder((-0.18, 0.90, 0.045), (-0.18, 0.90, -0.02), 0.02, "Steel", segs=12 if lod == 0 else 6)
    b.torus(wc, (0, 0, 1), 0.09, 0.012, "PaintOrange", segs=20 if lod == 0 else 8, rings=6)
    if lod == 0:
        for k in range(3):
            a = 2 * math.pi * k / 3 + math.pi / 2
            b.cylinder(wc, (wc[0] + 0.09 * math.cos(a), wc[1] + 0.09 * math.sin(a), wc[2]), 0.008, "Steel", segs=8)
    b.box((0, 0.72, 0.03), (0.60, 0.14, 0.03), "PaintGrey")
    if lod == 0:
        for k in range(9):
            b.box((-0.24 + k * 0.06, 0.72, 0.012), (0.03, 0.10, 0.006), "PaintDark")
    for sx in (-1, 1):
        hk.handle(b, (sx * 0.43, 1.45, 0.01), 0.5, lod)
    return [("InterlockPanel_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D))]


def cycle_lever(b, lod):
    """The door-cycle lever around its pivot on the panel: a steel arm standing up from the boss with an orange grip;
    the room owner rotates the child about X (-70 degrees pulls it out of the wall and down)."""
    segs = 12 if lod == 0 else 6
    b.cylinder((0, 0, 0), (0, 0, -0.05), 0.014, "Steel", segs=segs)
    b.cylinder((0, 0, -0.05), (0, 0.22, -0.05), 0.011, "Steel", segs=segs)
    b.box((0, 0.24, -0.05), (0.045, 0.08, 0.045), "PaintOrange")
    return []

# ----------------------------------------------------------------------------------------------- props

def hexagon(cz, cy, r):
    return [(r * math.cos(a), cy + 0.8 * r * math.sin(a), cz) for a in (math.pi / 6 + k * math.pi / 3 for k in range(6))]


def band(b, ring0, ring1, key):
    """Faceted band of quads between two rings (crease-sharp, no smoothing), faces turned away from the axis."""
    base0, base1 = b.add_verts(ring0), b.add_verts(ring1)
    n = len(ring0)
    centre = (sum((Vector(p) for p in ring0), Vector()) + sum((Vector(p) for p in ring1), Vector())) / (2 * n)
    for i in range(n):
        j = (i + 1) % n
        pts = [ring0[i], ring0[j], ring1[j], ring1[i]]
        b.add_face([base0 + i, base0 + j, base1 + j, base1 + i], hk.planar_uv(pts, b.tile(key)), key, False, outward=(Vector(pts[0]) + Vector(pts[2])) / 2 - centre)


def cap(b, ring, key, outward):
    base = b.add_verts(ring)
    b.add_face([base + i for i in range(len(ring))], hk.planar_uv(ring, b.tile(key)), key, False, outward=outward)


def piece_paper_bee(b, lod):
    """Origami bee folded from one duo sheet (gold face, navy reverse): pleated abdomen with alternating bands, thorax,
    pointed head, two kite wings, six strip legs and two antennae. Head towards -Z, resting on its legs (y = 0)."""
    cy = 0.017
    rings = [hexagon(z, cy, r) for z, r in ((0.0, 0.0135), (0.009, 0.0145), (0.018, 0.0135), (0.027, 0.0110), (0.035, 0.0075), (0.043, 0.0028))]
    for k in range(len(rings) - 1):
        band(b, rings[k], rings[k + 1], "PaperGold" if k % 2 == 0 else "PaperNavy")
    cap(b, rings[-1], "PaperNavy", (0, 0, 1))
    thorax0, thorax1 = hexagon(-0.013, cy + 0.002, 0.0155), rings[0]
    band(b, thorax0, thorax1, "PaperGold")
    head0, head1 = hexagon(-0.016, cy + 0.001, 0.0110), hexagon(-0.031, cy - 0.001, 0.0070)
    band(b, thorax0, head0, "PaperGold")
    band(b, head0, head1, "PaperGold")
    tip = (0.0, cy - 0.002, -0.046)
    base = b.add_verts(head1)
    t = b.add_verts([tip])
    for i in range(6):
        j = (i + 1) % 6
        pts = [head1[i], head1[j], tip]
        b.add_face([base + i, base + j, t], hk.planar_uv(pts, b.tile("PaperNavy")), "PaperNavy", False, outward=(Vector(head1[i]) + Vector(head1[j])) / 2 - Vector((0, cy, -0.031)))
    for sx in (-1, 1):
        # each wing is one folded flap: the root panel lies on the thorax's upper facet (from the dorsal ridge to the
        # shoulder crease), the kite panel opens from the crease, so the wing is visibly attached at every angle
        ridge_a, ridge_b = (sx * 0.0015, 0.0313, -0.010), (sx * 0.0015, 0.0279, 0.002)
        crease_a, crease_b = (sx * 0.0132, 0.0253, -0.010), (sx * 0.0121, 0.0232, 0.002)
        b.quad([ridge_a, crease_a, crease_b, ridge_b], "PaperWhite", outward=(sx, 2, 0))
        front, wing_tip, back = (sx * 0.025, 0.0272, -0.013), (sx * 0.041, 0.0298, 0.009), (sx * 0.025, 0.0262, 0.019)
        b.quad([crease_a, front, wing_tip, crease_b], "PaperWhite", outward=(0, 1, 0))
        b.quad([crease_b, wing_tip, back], "PaperWhite", outward=(0, 1, 0))
        # antennae: thin rolled-paper rods rooted inside the head, so nothing on the head reads as an eye
        b.cylinder((sx * 0.0022, 0.0236, -0.021), (sx * 0.012, 0.0365, -0.043), 0.0006, "PaperNavy", segs=4)
        for zz in (-0.010, -0.002, 0.006):
            b.quad([(sx * 0.009, 0.009, zz - 0.002), (sx * 0.009, 0.009, zz + 0.002), (sx * 0.021, 0.0, zz + 0.008), (sx * 0.021, 0.0, zz + 0.004)], "PaperNavy", outward=(sx, 0.4, 0))
    return []


TRAY_L, TRAY_W, TRAY_H, TRAY_LIP, TRAY_TAB = 0.44, 0.30, 0.055, 0.012, 0.018


def piece_seed_tray(b, lod):
    """Clean, empty 12-cell (4 x 3) seed tray in off-white plastic with a navy rim and two orange grip tabs; 0.50 m
    over the tabs so it matches the 2034 seedling tray and can carry the Chapter 3 descendants."""
    L, W, H = TRAY_L, TRAY_W, TRAY_H
    cols, rows, px, pz, cw, cd, depth, draft = 4, 3, 0.11, 0.10, 0.090, 0.080, 0.045, 0.012
    xs = [-(cols - 1) / 2 * px + i * px for i in range(cols)]
    zs = [-(rows - 1) / 2 * pz + j * pz for j in range(rows)]
    z_edges = [-W / 2] + [e for cz in zs for e in (cz - cd / 2, cz + cd / 2)] + [W / 2]
    for k in range(len(z_edges) - 1):
        za, zb = z_edges[k], z_edges[k + 1]
        if k % 2 == 1:  # a band of cells: top surface between them
            x_edges = [-L / 2] + [e for cx in xs for e in (cx - cw / 2, cx + cw / 2)] + [L / 2]
            for m in range(0, len(x_edges) - 1, 2):
                xa, xb = x_edges[m], x_edges[m + 1]
                b.quad([(xa, H, za), (xb, H, za), (xb, H, zb), (xa, H, zb)], "PlasticWhite", outward=(0, 1, 0))
        else:
            b.quad([(-L / 2, H, za), (L / 2, H, za), (L / 2, H, zb), (-L / 2, H, zb)], "PlasticWhite", outward=(0, 1, 0))
    yb = H - depth
    for cx in xs:
        for cz in zs:
            top = [(cx - cw / 2, H, cz - cd / 2), (cx + cw / 2, H, cz - cd / 2), (cx + cw / 2, H, cz + cd / 2), (cx - cw / 2, H, cz + cd / 2)]
            bot = [(cx - cw / 2 + draft, yb, cz - cd / 2 + draft), (cx + cw / 2 - draft, yb, cz - cd / 2 + draft), (cx + cw / 2 - draft, yb, cz + cd / 2 - draft), (cx - cw / 2 + draft, yb, cz + cd / 2 - draft)]
            for i in range(4):
                j = (i + 1) % 4
                pts = [top[i], top[j], bot[j], bot[i]]
                mid = (Vector(pts[0]) + Vector(pts[2])) / 2
                b.quad(pts, "PlasticWhite", outward=Vector((cx, yb + depth / 2, cz)) - mid)
            b.quad(bot, "PlasticWhite", outward=(0, 1, 0))
    inset = 0.008
    top_rect = [(-L / 2, H, -W / 2), (L / 2, H, -W / 2), (L / 2, H, W / 2), (-L / 2, H, W / 2)]
    bot_rect = [(-L / 2 + inset, 0, -W / 2 + inset), (L / 2 - inset, 0, -W / 2 + inset), (L / 2 - inset, 0, W / 2 - inset), (-L / 2 + inset, 0, W / 2 - inset)]
    for i in range(4):
        j = (i + 1) % 4
        pts = [top_rect[i], top_rect[j], bot_rect[j], bot_rect[i]]
        mid = (Vector(pts[0]) + Vector(pts[2])) / 2
        b.quad(pts, "PlasticWhite", outward=mid - Vector((0, H / 2, 0)))
    b.quad(bot_rect, "PlasticWhite", outward=(0, -1, 0))
    lip_out = [(-L / 2 - TRAY_LIP, H, -W / 2 - TRAY_LIP), (L / 2 + TRAY_LIP, H, -W / 2 - TRAY_LIP), (L / 2 + TRAY_LIP, H, W / 2 + TRAY_LIP), (-L / 2 - TRAY_LIP, H, W / 2 + TRAY_LIP)]
    b.ring_prism(top_rect, lip_out, (0, -0.014, 0), "PlasticNavy", (0, 1, 0), centre=(0, H, 0))
    for sx in (-1, 1):
        b.box((sx * (L / 2 + TRAY_LIP + TRAY_TAB / 2), H - 0.006, 0), (TRAY_TAB, 0.010, 0.12), "PlasticOrange")
    return []

# ----------------------------------------------------------------------------------------------- specs

ENV_PIECES = [
    dict(id="EN_Airlock_SuitLocker", display="EVA suit locker", kind="standing", flag="--height", size=LOCKER_H, footprint=(LOCKER_W, LOCKER_D), mount_y=0.0, build=piece_suit_locker,
         notes="0.6 x 0.55 x 2.2 m open-front locker: hanger rail 1.78 m, helmet shelf 1.86 m, boot tray, backpack brackets, retaining bar with orange latch; blank name plate; material slot RoleTab (0.04 x 0.40 m strip) takes the cadet's role colour; stands against a wall, open front faces -Z"),
    dict(id="EN_Airlock_Bench", display="Suit-up bench", kind="standing", flag="--longest", size=BENCH_L, footprint=(BENCH_L, BENCH_D), mount_y=0.0, build=piece_bench,
         notes="1.6 x 0.45 x 0.45 m brushed steel seat on navy pedestals, cross rail, orange boot rail, tie-down rings; seat at 0.45 m"),
    dict(id="EN_Airlock_GlovePort", display="Glove-port wall module", kind="wall", flag="--height", size=WALL_H, footprint=(1.0, 0.15), mount_y=0.0, build=piece_glove_port,
         notes="1 m wall: pressure window 0.56 x 0.42 m at 1.75 m, two glove ports (0.27 m flanges at x +-0.22, 1.19 m) with sleeves on the far side; the sealed plant chamber lies behind it"),
    dict(id="EN_Airlock_PassThrough", display="Sealed carrier pass-through", kind="wall", flag="--height", size=WALL_H, footprint=(1.0, 0.57), mount_y=0.0, build=piece_pass_through,
         notes="1 m two-sided bulkhead: 0.50 x 0.44 m chamber at 1.00-1.44 m through the wall, standing 0.42 m into the room; LidA (room side, hinge on the left) and LidB (far side, hinge on the right) open +Y 100 deg; gauge, orange equalisation lever, LampSafe lamp",
         children=[("LidA", (-(PT_W / 2 + 0.03), (PT_Y0 + PT_H / 2), -PT_DEPTH - 0.02), pass_through_lid(-1)),
                   ("LidB", ((PT_W / 2 + 0.03), (PT_Y0 + PT_H / 2), WALL_D + 0.02), pass_through_lid(1))]),
    dict(id="EN_Airlock_InterlockPanel", display="Pressure interlock panel", kind="wall", flag="--height", size=WALL_H, footprint=(1.0, 0.15), mount_y=0.0, build=piece_interlock_panel,
         notes="1 m wall: recessed navy console 0.74 x 1.34 m; Screen slot 0.5 x 0.3 m at 1.70 m for the live words SEALED / EQUALISING / SAFE TO OPEN; gauges at 1.33 m; lamps at 1.10 m (LampSealed red, LampEqualising amber, LampSafe green); orange equalisation wheel; pump grille; child CycleLever on the boss at (0.27, 0.88)",
         children=[("CycleLever", (LEVER_X, LEVER_Y, -0.01), cycle_lever)]),
]
PROP_PIECES = [
    dict(id="PR_PaperBee", display="Paper bee (origami)", kind="prop", flag="--longest", budget=5000, tex=256, build=piece_paper_bee,
         notes="Rafi's origami bee, EX-CH02-S02 bench and S07 record: duo paper, gold face and navy reverse, white wings; no face drawn; sockets Socket_Grip (thorax) and Socket_Rest (base); states folded / held / placed are the same mesh"),
    dict(id="PR_SeedTray", display="Clean seed tray (12 cells)", kind="prop", flag="--longest", budget=5000, tex=256, build=piece_seed_tray,
         notes="Kai's clean seed tray, EX-CH02-S06 -> S07 bridge object: 4 x 3 empty cells, off-white, navy rim, orange tabs; 0.50 m like PL_ZeroSeedlingTray so PL_Descendants (CH03) can sit in it"),
]

# ----------------------------------------------------------------------------------------------- assembly

def build_piece(spec, lod, table):
    """(root, objects) for one piece at one LOD, authored in Godot's frame; children are pivoted empties with their
    own mesh (and collision at LOD0), like the kit's door and hatch leaves."""
    root = hk.make_empty(spec["id"] + f"_LOD{lod}")
    b = Builder(table)
    cols = spec["build"](b, lod)
    body = b.to_object(spec["id"] + f"_Mesh_LOD{lod}")
    body.parent = root
    objs = [body] + (hk.collision_objects(cols, body, table) if lod == 0 else [])
    for name, pivot, fn in spec.get("children", []):
        taken = bpy.data.objects.get(name)
        if taken is not None:  # the other LOD's child keeps the exported name only until this one is exported
            taken.name = name + "_prev"
        child = hk.make_empty(name, pivot, root)
        cb = Builder(table)
        ccols = fn(cb, lod)
        cmesh = cb.to_object(name + f"_Mesh_LOD{lod}")
        cmesh.parent = child
        objs += [child, cmesh] + (hk.collision_objects(ccols, cmesh, table) if lod == 0 else [])
    for name, where in spec.get("sockets", {}).items():
        objs.append(hk.make_empty(name, where, root))
    return root, objs


def export_env(root, objs, path):
    """Export a kit-extension GLB and point its images at the kit's shared texture files (no copies written)."""
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_animations=False, export_cameras=False, export_lights=False,
                              export_extras=False, export_image_format="AUTO", export_texcoords=True, export_normals=True)
    externalise(path, "../kit/textures/lod1" if path.stem.endswith("_LOD1") else "../kit/textures", write_files=False)


def export_prop(root, objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_animations=False, export_cameras=False, export_lights=False,
                              export_extras=False, export_image_format="AUTO", export_texcoords=True, export_normals=True)


def write_scene_import(glb, embedded_handling):
    """Godot import settings: kit-extension GLBs must load the shared textures as already imported (handling 1, see
    build_habitat_kit.write_scene_imports); prop GLBs keep the project default (embedded Basis Universal)."""
    import_file = glb.with_name(glb.name + ".import")
    if import_file.exists():
        lines = import_file.read_text(encoding="utf-8").splitlines()
        lines = [f"gltf/embedded_image_handling={embedded_handling}" if line.startswith("gltf/embedded_image_handling=") else line for line in lines]
        import_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    else:
        params = hk.SCENE_IMPORT_PARAMS.replace("gltf/embedded_image_handling=1", f"gltf/embedded_image_handling={embedded_handling}")
        import_file.write_text('[remap]\n\nimporter="scene"\nimporter_version=1\ntype="PackedScene"\n\n[deps]\n\n'
                               'source_file="res://' + glb.relative_to(ROOT / "game").as_posix() + '"\n\n[params]\n\n' + params, encoding="utf-8")

# ----------------------------------------------------------------------------------------------- the vestibule layout

CADETS = [("Kai", "#F26B21"), ("Amara", "#20B8C9"), ("Mei", "#4CAF50"), ("Rafi", "#8E5CC2"), ("Ferreira", "#B8A06A")]


def vestibule_layout():
    """The 8 x 4 m double-interlock vestibule (LOC-05) on the kit grid: suit-up vestibule x 0..5 with the inner door to
    the commons (LOC-01), the garden-side wall with the glove ports and the pass-through (the sealed connection to
    LOC-03), the partition with the inner hatch and interlock panel at x = 5, the 3 m airlock chamber x 5.3..8 with the
    outer hatch to the surface (LOC-06) and its own panel. Walls follow the kit README's yaw rules."""
    p = []

    def place(piece, x, z, yaw=0.0, role=""):
        p.append(dict(piece=piece, position=[x, 0.0, z], yaw=yaw, role=role))

    for x in range(8):
        for z in range(4):
            place("EN_Kit_FloorTile", x + 0.5, z + 0.5)
            place("EN_Kit_CeilingTile", x + 0.5, z + 0.5)
    # far wall (z = 4): the garden-side wall, yaw 0
    place("EN_Kit_Wall_Corner", 0, 4, -90)
    place("EN_Kit_Wall_Straight", 1, 4, 0)
    place("EN_Airlock_GlovePort", 2, 4, 0, "glove_ports")
    place("EN_Airlock_PassThrough", 3, 4, 0, "pass_through")
    place("EN_Kit_Wall_Straight", 4, 4, 0)
    for x in (5, 6, 7):
        place("EN_Kit_Wall_Straight", x, 4, 0)
    place("EN_Kit_Wall_Corner", 8, 4, 0)
    # +x end wall: the outer hatch to the surface and the chamber's panel
    place("EN_Kit_Hatch", 8, 1.5, 90, "outer_hatch")
    place("EN_Airlock_InterlockPanel", 8, 3, 90, "chamber_panel")
    place("EN_Kit_Wall_Corner", 8, 0, 90)
    # near wall (z = 0), yaw 180: lockers and the bench stand against it in the vestibule
    for x in range(1, 8):
        place("EN_Kit_Wall_Straight", x, 0, 180)
    place("EN_Kit_Wall_Corner", 0, 0, 180)
    # -x end wall: the inner door to the commons
    place("EN_Kit_DoorFrame", 0, 2, -90, "inner_door")
    # partition at x = 5: vestibule face (yaw 90) with the inner hatch and panel; chamber face (yaw -90) behind it
    place("EN_Airlock_InterlockPanel", 5, 0.5, 90, "vestibule_panel")
    place("EN_Kit_Hatch", 5, 2, 90, "inner_hatch")
    place("EN_Kit_Wall_Straight", 5, 3.5, 90)
    place("EN_Kit_Wall_Straight", 5.3, 0.5, -90)
    place("EN_Kit_Wall_Straight", 5.3, 3.5, -90)
    # lights: strips under the ceiling
    for x, z in ((1.5, 1), (1.5, 3), (3.5, 1), (3.5, 3), (6.5, 1), (6.5, 3)):
        place("EN_Kit_LightStrip", x, z)
    # furniture in the vestibule: five lockers (0.6 m) and the bench along the near wall, backs to the wall (yaw 180)
    for k, (name, colour) in enumerate(CADETS):
        p.append(dict(piece="EN_Airlock_SuitLocker", position=[0.5 + 0.6 * k, 0.0, LOCKER_D / 2 + 0.02], yaw=180, role=f"locker_{name.lower()}", role_tab=colour))
    place("EN_Airlock_Bench", 4.1, BENCH_D / 2 + 0.02, 180, "bench")
    anchors = dict(player=[2.5, 0.0, 2.6], companion_checklist=[1.5, 0.0, 2.2], companion_tools=[3.2, 0.0, 3.0],
                   suit_check=[1.7, 0.0, 1.2], bench=[4.1, 0.0, 0.9], pass_through=[3.0, 0.0, 3.1], glove_ports=[2.0, 0.0, 3.2],
                   vestibule_panel=[4.3, 0.0, 0.5], inner_hatch=[4.3, 0.0, 2.0], chamber=[6.6, 0.0, 2.0], chamber_panel=[7.3, 0.0, 3.0],
                   outer_hatch=[7.3, 0.0, 1.5], exterior_step=[8.8, 0.0, 1.5], viewpoint=[1.2, 1.6, 0.8])
    return dict(bounds_m=[8.0, 4.0], ceiling_m=WALL_H, zones=dict(vestibule=dict(x=[0.0, 5.0], z=[0.0, 4.0], pressure="habitat"),
                                                              chamber=dict(x=[5.3, 8.0], z=[0.0, 4.0], pressure="cycled")),
                connections={"inner_door": "LOC-01", "pass_through": "LOC-03 (sealed carrier transfer)", "glove_ports": "LOC-03 (Alo chamber)", "outer_hatch": "LOC-06"},
                placements=p, anchors=anchors)

# ----------------------------------------------------------------------------------------------- previews

def render_pieces(built, camera):
    for spec in ENV_PIECES + PROP_PIECES:
        if ONLY and spec["id"] not in ONLY:
            continue
        lods = (0, 1) if spec["kind"] != "prop" else (0,)
        for lod in lods:
            root, objs = built[(spec["id"], lod)]
            hk.set_visible([root] + objs, True)
            hk.set_visible([o for o in objs if o.name.endswith(COL)], False)
            views = {"": (0.7, 1.0, 0.55)}  # Blender frame after the bake: the finished face (Godot -Z) points to +Y
            if spec["kind"] == "prop":
                views = {"": (0.7, 1.0, 0.55), "_front": (0, 1, 0.25), "_side": (1, 0, 0.25), "_back": (0, -1, 0.25), "_top": (0.0001, 0.0001, 1)}
            elif spec["id"] == "EN_Airlock_PassThrough":
                views["_far"] = (-0.7, -1.0, 0.55)
            for suffix, direction in views.items():
                hk.render_piece(camera, objs, STAGE / "preview" / f"{spec['id']}_LOD{lod}{suffix}.png", direction, pad=1.15 if spec["kind"] == "prop" else 1.25)
            if lod == 0 and spec.get("children"):
                movers = [o for o in objs if o.type == "EMPTY" and o.name.startswith(("LidA", "CycleLever"))]  # LOD0's child may carry the _prev suffix
                for o in movers:
                    o.rotation_euler = (0, 0, math.radians(100)) if o.name.startswith("LidA") else (math.radians(-70), 0, 0)  # Blender Z = Godot Y
                hk.render_piece(camera, objs, STAGE / "preview" / f"{spec['id']}_LOD0_open.png", (0.7, 1.0, 0.55), pad=1.25)
                for o in movers:
                    o.rotation_euler = (0, 0, 0)
            hk.set_visible([root] + objs, False)
    if "PR_PaperBee" in [s["id"] for s in PROP_PIECES] and (not ONLY or "PR_PaperBee" in ONLY):
        render_bee_icon(built[("PR_PaperBee", 0)], camera)


def render_bee_icon(bee, camera):
    """The bee on a transparent background for the Chapter 2 pollination diagram (labelled by the UI at runtime)."""
    root, objs = bee
    scene = bpy.context.scene
    hk.set_visible([root] + objs, True)
    floor = bpy.data.objects.get("PreviewFloor")
    floor.hide_render = True
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = 512
    hk.render_piece(camera, objs, STAGE / "preview" / "PR_PaperBee_icon.png", (0.7, 0.9, 0.6), pad=1.1)
    scene.render.film_transparent = False
    scene.render.resolution_x = scene.render.resolution_y = 720
    floor.hide_render = False
    hk.set_visible([root] + objs, False)


KIT_BUILT = {}
ENV_MATS = {}


def kit_object(piece_id):
    """The kit piece built once in-process from the kit's own generators (Blender 5.2's bundled glTF importer fails
    under --factory-startup, and the generators are the source anyway); returns the hidden template root."""
    if piece_id not in KIT_BUILT:
        spec = next(s for s in hk.PIECES if s["id"] == piece_id)
        root, objs = hk.build_piece(spec, 0, ENV_MATS[0])
        bpy.context.view_layer.update()
        hk.bake_blender_space(objs)
        hk.set_visible([root] + objs, False)
        KIT_BUILT[piece_id] = [root]
    return KIT_BUILT[piece_id]


def duplicate_tree(roots, parent):
    out = []
    mapping = {}

    def dup(o, new_parent):
        c = o.copy()
        if o.data is not None:
            c.data = o.data
        c.parent = new_parent
        c.matrix_parent_inverse = o.matrix_parent_inverse.copy()
        bpy.context.scene.collection.objects.link(c)
        c.hide_render = any(suffix in o.name for suffix in COL)
        c.hide_viewport = False
        mapping[o] = c
        out.append(c)
        for ch in o.children:
            dup(ch, c)
    for r in roots:
        dup(r, parent)
    return out


def render_room(built, camera, catalogue_entries):
    """Two Cycles views of the assembled vestibule from the published layout: a cutaway over the near wall and the
    chamber seen from the inner hatch. A 1.75 m grey figure stands at the player anchor for scale."""
    layout = vestibule_layout()
    mounts = {e["id"]: e["mount_y"] for e in json.loads((KIT / "kit.json").read_text(encoding="utf-8"))["pieces"]}
    mounts.update({e["id"]: e["mount_y"] for e in catalogue_entries})
    room = hk.make_empty("Vestibule")
    objs = []
    skip_for_cutaway = []
    by_role = {}
    for pl in layout["placements"]:
        piece, (x, y, z), yaw = pl["piece"], pl["position"], pl["yaw"]
        if piece == "EN_Kit_CeilingTile":
            continue
        if piece.startswith("EN_Kit_"):
            roots = kit_object(piece)
            holder = hk.make_empty(piece + "_inst", parent=room)
            copies = duplicate_tree(roots, holder)
        else:
            root, pobjs = built[(piece, 0)]
            holder = hk.make_empty(piece + "_inst", parent=room)
            copies = duplicate_tree([root], holder)
            if pl.get("role_tab"):
                colour = pl["role_tab"].lstrip("#")
                rgb = tuple(int(colour[i:i + 2], 16) / 255 for i in (0, 2, 4))
                mat = hk.pbr_material("RoleTab_" + pl["role"], None, 0.45, tuple(c ** 2.2 for c in rgb))
                for c in copies:
                    if c.type == "MESH":
                        c.data = c.data.copy()
                        for i, m in enumerate(c.data.materials):
                            if m is not None and m.name.startswith("RoleTab"):
                                c.data.materials[i] = mat
        holder.location = (x, -z, y + mounts.get(piece, 0.0))
        holder.rotation_euler = (0, 0, math.radians(yaw))
        if piece == "EN_Kit_LightStrip":
            holder.location.z = y + mounts[piece]
            bpy.ops.object.light_add(type="AREA", location=(x, -z, 2.50))
            lamp = bpy.context.object
            lamp.data.energy = 60 if x < 5 else 45
            lamp.data.size = 0.9
            lamp.data.color = (1.0, 0.86, 0.72) if x < 5 else (1.0, 0.92, 0.85)
            lamp.parent = room
            objs.append(lamp)
        if z == 4 and piece in ("EN_Kit_Wall_Straight", "EN_Kit_Wall_Corner", "EN_Airlock_GlovePort", "EN_Airlock_PassThrough") and yaw in (0, -90):
            skip_for_cutaway.append(holder)  # the garden wall comes off for the cutaway; the garden-wall view shows it from inside
        if pl.get("role"):
            by_role[pl["role"]] = copies
        objs += copies + [holder]
    # scale figure at the player anchor
    px, py, pz = layout["anchors"]["player"]
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=1.45, location=(px, -pz, 0.725 + 0.0))
    body = bpy.context.object
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.11, location=(px, -pz, 1.62))
    head = bpy.context.object
    grey = bpy.data.materials.new("ScaleFigure")
    grey.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.35, 0.36, 0.38, 1)
    for o in (body, head):
        o.data.materials.append(grey)
        o.parent = room
        objs.append(o)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1400, 820
    camera.data.type = "PERSP"
    camera.data.lens = 24
    for h in skip_for_cutaway:
        for o in [h] + list(h.children_recursive):
            o.hide_render = True
    camera.location = (3.6, -12.0, 4.8)  # Blender frame: -Y is the garden side of the room (Godot +Z), looking back at the lockers
    camera.rotation_euler = (Vector((4.0, -1.6, 0.8)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = str(STAGE / "preview" / "EN_Airlock_room_cutaway.png")
    bpy.ops.render.render(write_still=True)
    for h in skip_for_cutaway:
        for o in [h] + list(h.children_recursive):
            o.hide_render = any(suffix in o.name for suffix in COL)
    for o in by_role.get("inner_hatch", []):  # open the inner hatch so the chamber view looks through it
        if o.type == "EMPTY" and o.name.startswith("HatchLeaf"):
            o.rotation_euler.z += math.radians(100)
    camera.location = (4.2, -2.0, 1.55)
    camera.rotation_euler = (Vector((7.6, -1.8, 1.25)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 20
    scene.render.filepath = str(STAGE / "preview" / "EN_Airlock_room_chamber.png")
    bpy.ops.render.render(write_still=True)
    camera.location = (0.9, -0.9, 1.5)
    camera.rotation_euler = (Vector((2.8, -4.0, 1.3)) - camera.location).to_track_quat("-Z", "Y").to_euler()  # towards the garden wall (Godot z = 4)
    camera.data.lens = 18
    scene.render.filepath = str(STAGE / "preview" / "EN_Airlock_room_garden_wall.png")
    bpy.ops.render.render(write_still=True)
    camera.data.type = "ORTHO"
    scene.render.resolution_x = scene.render.resolution_y = 720
    hk.set_visible(objs + [room], False)

# ----------------------------------------------------------------------------------------------- main

def main():
    (STAGE / "preview").mkdir(parents=True, exist_ok=True)
    OUT_ENV.mkdir(parents=True, exist_ok=True)
    publish = not ONLY and not ROOM_ONLY
    if publish:
        for old in OUT_ENV.glob("*.glb"):
            old.unlink()
    global ENV_MATS
    env_mats = airlock_materials(load_kit_images())
    ENV_MATS = env_mats
    prop_mats = prop_materials()
    rows, catalogue, built = [], [], {}
    for spec in ENV_PIECES:
        entry = dict(id=spec["id"], display=spec["display"], notes=spec["notes"], kind=spec["kind"], footprint_m=list(spec["footprint"]),
                     mount_y=spec["mount_y"], lods=[], triangles=[], lod_distance_m=LOD_DISTANCE_M, collision=True)
        for lod in (0, 1):
            root, objs = build_piece(spec, lod, env_mats[lod])
            bpy.context.view_layer.update()
            lo, hi = hk.bounds(objs)
            tris = hk.triangles(objs)
            assert abs(lo.y) < 0.005, f"{spec['id']} LOD{lod} lowest point {lo.y:.4f} is not on the floor"
            measured = (hi.y - lo.y) if spec["flag"] == "--height" else max(hi - lo)
            assert abs(measured - spec["size"]) <= 0.02 * spec["size"], f"{spec['id']} LOD{lod} measures {measured:.3f}, spec {spec['size']}"
            assert tris <= 8000, f"{spec['id']} LOD{lod} has {tris} triangles, over the art bible's 8k"
            name = spec["id"] + f"_LOD{lod}"
            path = OUT_ENV / (name + ".glb")
            hk.bake_blender_space(objs)
            bpy.context.view_layer.update()
            if publish:
                export_env(root, objs, path)
                write_scene_import(path, 1)
            rows.append(dict(name=name, concept_or_source=SOURCE_ENV, size_flag=spec["flag"], size_m=spec["size"], tris=tris,
                             tex=1024 if lod == 0 else 512, game_path=path.relative_to(ROOT).as_posix(), art_status="sheet_pending_m3-2a",
                             notes=f"{TASK} {spec['display']}; " + ("game LOD with collision" if lod == 0 else "Compatibility LOD, no collision")))
            entry["lods"].append("res://assets/environment/EN_Airlock/" + name + ".glb")
            entry["triangles"].append(tris)
            if lod == 0:
                entry["size_m"] = [round(v, 3) for v in (hi - lo)]
                entry["bounds_min_m"] = [round(v, 3) for v in lo]
            built[(spec["id"], lod)] = (root, objs)
            print(f"CH2 {name}: {tris} tris, size {[round(v, 3) for v in (hi - lo)]}" + (f", {path.stat().st_size // 1024} KB" if publish else ""))
        if spec["id"] == "EN_Airlock_SuitLocker":
            entry["sockets"] = dict(role_tab_material="RoleTab", hanger_rail=[0, 1.78, 0], helmet_shelf=[0, 1.86, 0.06], boot_tray=[0, 0.12, 0.05], name_plate=[0, LOCKER_H - 0.09, -LOCKER_D / 2 - 0.006])
        if spec["id"] == "EN_Airlock_Bench":
            entry["sockets"] = dict(seat_y=BENCH_H, seats=[[-0.45, BENCH_H, 0], [0.45, BENCH_H, 0]])
        if spec["id"] == "EN_Airlock_GlovePort":
            entry["sockets"] = dict(window_centre=[0, 1.75, 0], window_size=[0.56, 0.42], ports=[[-PORT_X, PORT_Y, 0], [PORT_X, PORT_Y, 0]], port_clear_diameter=round(2 * (PORT_R - 0.045), 3))
        if spec["id"] == "EN_Airlock_PassThrough":
            entry["sockets"] = dict(opening_centre=[0, PT_Y0 + PT_H / 2, 0], opening_size=[PT_W, PT_H], carrier_socket=[0, PT_Y0 + 0.03, (-PT_DEPTH + 0.03 + WALL_D) / 2],
                                    lids=dict(LidA=dict(side="room", hinge=[-(PT_W / 2 + 0.03), PT_Y0 + PT_H / 2, -PT_DEPTH - 0.02], open_rotation_deg_y=100),
                                              LidB=dict(side="far", hinge=[(PT_W / 2 + 0.03), PT_Y0 + PT_H / 2, WALL_D + 0.02], open_rotation_deg_y=100)),
                                    lamp_material="LampSafe", far_face_z=WALL_D)
        if spec["id"] == "EN_Airlock_InterlockPanel":
            entry["sockets"] = dict(screen_material="Screen", screen_centre=[0, 1.70, 0.043], screen_size=[0.5, 0.3],
                                    lamps=dict(SEALED="LampSealed", EQUALISING="LampEqualising", **{"SAFE TO OPEN": "LampSafe"}),
                                    lever_node="CycleLever", lever_pivot=[LEVER_X, LEVER_Y, -0.01], lever_pull_rotation_deg_x=-70, gauges=[[-0.17, 1.33, 0.03], [0.17, 1.33, 0.03]])
        catalogue.append(entry)
    prop_entries = []
    for spec in PROP_PIECES:
        spec = dict(spec, sockets=dict(Socket_Grip=(0, 0.031, -0.006), Socket_Rest=(0, 0, 0)) if spec["id"] == "PR_PaperBee" else {})
        root, objs = build_piece(spec, 0, prop_mats)
        bpy.context.view_layer.update()
        lo, hi = hk.bounds(objs)
        tris = hk.triangles(objs)
        size = round(max(hi - lo), 3)
        assert abs(lo.y) < 0.002, f"{spec['id']} lowest point {lo.y:.4f} is not on the floor"
        assert tris <= spec["budget"], f"{spec['id']} has {tris} triangles, over {spec['budget']}"
        folder = OUT_PROPS / spec["id"]
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / (spec["id"] + ".glb")
        hk.bake_blender_space(objs)
        bpy.context.view_layer.update()
        if publish:
            export_prop(root, objs, path)
        rows.append(dict(name=spec["id"], concept_or_source=SOURCE_PROP, size_flag=spec["flag"], size_m=size, tris=tris, tex=spec["tex"],
                         game_path=path.relative_to(ROOT).as_posix(), art_status="sheet_pending_m3-2a", notes=f"{TASK} {spec['display']}; {spec['notes']}"))
        prop_entries.append(dict(id=spec["id"], display=spec["display"], notes=spec["notes"], path="res://" + path.relative_to(ROOT / "game").as_posix(),
                                 triangles=tris, size_m=[round(v, 3) for v in (hi - lo)], sockets={k: list(v) for k, v in spec["sockets"].items()}))
        built[(spec["id"], 0)] = (root, objs)
        print(f"CH2 {spec['id']}: {tris} tris, size {[round(v, 3) for v in (hi - lo)]}" + (f", {path.stat().st_size // 1024} KB" if publish else ""))
    if publish:
        with (ROOT / "production/manifest/chapter2_assets.csv").open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
        (OUT_ENV / "airlock.json").write_text(json.dumps(dict(
            task=TASK, seed=SEED, design_reference=["game-design/09_WORLD_AND_LEVEL_DESIGN.md LOC-05", "production/concept/environment_v1 (M1-04 approved kit sheets)",
                                                    "production/concept/chapter2_v1 (M3-2A sheets, awaiting approval)"],
            conventions=dict(units="metres", up="+Y", front="-Z (Godot forward); wall faces lie on z=0 and face -Z, bodies extend to +z; standing pieces face -Z with their pivot at the base centre",
                             grid_m=1.0, wall_height_m=WALL_H, lod_distance_m=LOD_DISTANCE_M,
                             textures="the kit's PBR sets, referenced by uri in ../kit/textures (stored once, shared with every kit piece)"),
            pieces=catalogue, props=prop_entries,
            interlock=dict(states=["SEALED", "EQUALISING", "SAFE TO OPEN"], equalise_seconds=12.0, sides=["habitat", "surface"], start_side="habitat",
                           hatches=dict(inner="inner_hatch", outer="outer_hatch"), panels=["vestibule_panel", "chamber_panel"],
                           pump_sfx="res://assets/audio/sfx/SFX_AIRLOCK_CYCLE.ogg",
                           rule="one hatch open at a time; a hatch opens only when the chamber matches its side; the pump runs only while EQUALISING",
                           time_compression="a real chamber takes minutes to pump down or repressurise; equalise_seconds is the compressed on-screen cycle, and the room owner shows a labelled time card for the rest (LOC-05 exit behaviour), never an invisible jump"),
            pass_through=dict(piece="EN_Airlock_PassThrough", lids=["LidA", "LidB"], rule="one lid open at a time; the carrier socket is inside the chamber"),
            cadets=[dict(name=n, role_colour=c) for n, c in CADETS],
            vestibule=vestibule_layout()), indent=1), encoding="utf-8")
    if RENDER or ROOM_ONLY:
        camera, rig = hk.setup_render()
        bpy.context.scene.cycles.samples = 64
        hk.set_visible(bpy.context.scene.objects, False)
        hk.set_visible(rig, True)
        if not ROOM_ONLY:
            render_pieces(built, camera)
        if ROOM_ONLY or not ONLY:
            render_room(built, camera, catalogue)
    print(f"CHAPTER2_BUILD_PASS: {len(ENV_PIECES)} airlock pieces, {len(PROP_PIECES)} props, {len(rows)} manifest rows")


if __name__ == "__main__":
    main()
