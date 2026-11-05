"""Build the Chapter 7 (The Great Storm) shelter and uplink props and EN_Fabrication with Blender alone (board M3-7A):
no generation service, no credits.

    python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 \
        --python production/tools/build_chapter7_assets.py [-- --no-render | --only ID,ID | --cpu]

--only re-renders the previews of the listed assets without touching the published files; --cpu avoids the Metal path.

What it builds (deterministic, seed 20261106), from PRODUCTION_HANDBOOK.md section 8.4 (CH07) and 8.3 (EN_Fabrication),
STORY_FULL EX-CH07-S02..S11, game-design/08_PUZZLE_DESIGNS.md P-13/P-14, 22 section 9.1-9.4 and 09 LOC-04:

  props (game/assets/props/<id>/<id>.glb = game LOD with collision, <id>_LOD1.glb = Compatibility LOD)
    PR_ShelterDiagram    wall board: the Safe Room plan with five seat positions and five magnetic seat markers in
                         the role colours (SeatMarker_Kai .. _Ferreira), parked on a steel strip until placed (S02)
    PR_SeedCase          the founder-reserve case: two latched compartments of 15 vials, one seed in each (15 + 15 = 30,
                         S04), hinged Lid, Latch, CompartmentLid_A/_B with seal lamps, a sealed-telemetry window (S06)
                         and two side grips; replaces the Tripo model, whose vials held many seeds each
    PR_ValveDiagram      wall plate: garden reservoir, the six-unit water wall (WaterCell_1..6 show W), supply and
                         return valves with lamps, the return-time selector (S04: "Name the valve, then touch it.")
    PR_TelemetryDisplay  wall unit: two live screens (ship systems, garden local telemetry) and six ledger lamps (S06)
    PR_ArchivePlayer     the Safe Room's local archive player: speaker, screen, transport keys, archive card (S07)
    PR_UplinkFeedthrough the damaged external Earth-uplink feedthrough (A-43, S09): the Tripo mesh of 27 Oct re-exported
                         with collision, a hidden DiagnosedTag lockout tag and a Compatibility LOD
    PR_NetworkDiagnostic wall panel: local network / dish path / external feedthrough branches, three test buttons
                         and lamps, isolation key, live screen and the DataCard that carries the saved relay-bypass
                         diagram to S10 (doc 24 section 2.9 join CH07 S09 -> S10)
  EN_Fabrication (game/assets/environment/EN_Fabrication/<id>_LOD0.glb / _LOD1.glb, kit conventions), CH07-S11
    EN_Fabrication_Bench          local fabrication bench: controller cradle (for PR_RelayController), the spare
                                  battery in its cradle, connector tray with three matching plugs and one wrong one,
                                  echo test unit, isolation checklist, vise, tool board, task light
    EN_Fabrication_RouteSimulator the surveyed-route simulator: a relief of the real LOLA corridor from Aurora to the
                                  Malapert summit (1:90,000, vertical exaggeration 2), the computed surveyed road inlaid,
                                  end markers, three repeater pins and pads computed by route_simulator_data.py, screen

  game/assets/props/chapter7_assets.json   catalogue: files, sizes, mount heights, sockets, moving parts, states,
                                           route-simulator data; game/assets/props/chapter7_assets.gd reads it
  production/manifest/chapter7_assets.csv  gate specs for production/tools/verify_gate.py
  production/models/chapter7/preview/      Cycles previews for production/tools/chapter7_contact.py

Every piece tiles the approved habitat kit's PBR sets (M1-04/M1-05) and references them by uri in
game/assets/environment/kit/textures (nothing stored twice); only the relief's own maps live in
EN_Fabrication/textures. Canon kept: English only and no text baked anywhere (every word is a live "Screen" slot or a
Label3D the room adds), no logos, no plants in this set, radiation never visible, role colours from ART_BIBLE section 3.
"""
import csv
import json
import math
import os
import subprocess
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_habitat_kit as hk  # noqa: E402  (Builder, materials, axis bake, preview rig of the M1-05 kit)
import route_simulator_data as rsd  # noqa: E402  (LOLA line-of-sight data for the route simulator)
from glb_external_textures import EXTENSIONS, _read_glb, _remap_buffer_views, _write_glb  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
KIT = ROOT / "game/assets/environment/kit"
PROPS = ROOT / "game/assets/props"
FAB = ROOT / "game/assets/environment/EN_Fabrication"
STAGE = ROOT / "production/models/chapter7"
SEED = 20261106
TASK = "M3-7A"
SOURCE = "tools/build_chapter7_assets.py (seed 20261106): procedural Blender geometry on the approved M1-04/M1-05 kit materials"
FEEDTHROUGH_COMMIT = "ca01433"  # the Tripo export of 27 Oct (concept/props/uplink_feedthrough/uplink_feedthrough_v1.png)
FEEDTHROUGH_PATH = "game/assets/props/PR_UplinkFeedthrough/PR_UplinkFeedthrough.glb"
RENDER = "--no-render" not in sys.argv
ONLY = sys.argv[sys.argv.index("--only") + 1].split(",") if "--only" in sys.argv else []
hk.CPU_RENDER = "--cpu" in sys.argv
Builder = hk.Builder
COL = hk.COL_SUFFIXES
ROLES = [("Kai", "#F26B21"), ("Amara", "#20B8C9"), ("Mei", "#4CAF50"), ("Rafi", "#8E5CC2"), ("Ferreira", "#B8A06A")]
SEEDS_PER_COMPARTMENT = 15  # STORY_FULL EX-CH07-S04 / 08 P-13: founder reserve 15 + 15 = 30
WATER_UNITS = 6             # 08 P-13: six shared water units (W cap 6)
LEDGER = ["E", "A", "H", "C", "R", "Z"]  # 08 P-02 contract letters: energy, air, Alo/plant health, crops, rations, exposure


def srgb(hexcode):
    """'#RRGGBB' -> linear RGB tuple for Blender colour sockets."""
    c = [int(hexcode[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c)


# ----------------------------------------------------------------------------------------------- materials

def load_kit_images():
    """The kit's published texture sets, loaded under their kit names so the GLBs can reference the one shared copy.
    Returns {lod: {key: {base, normal, orm, tile}}} like hk.make_textures."""
    catalogue = json.loads((KIT / "kit.json").read_text(encoding="utf-8"))
    tiles = {m["id"].replace("M_Kit_", ""): float(m["tile_m"]) for m in catalogue["materials"]}
    images = {0: {}, 1: {}}
    for lod, folder, suffix in ((0, KIT / "textures", ""), (1, KIT / "textures" / "lod1", "_LOD1")):
        for key in hk.MATERIAL_KEYS:
            shared = "Paint" if key.startswith("Paint") else key
            maps = {}
            for kind, stem, colour in (("base", f"T_Kit_{key}_BaseColor", True), ("normal", f"T_Kit_{shared}_Normal", False), ("orm", f"T_Kit_{shared}_ORM", False)):
                name = stem + suffix
                image = bpy.data.images.get(name)
                if image is None:
                    image = bpy.data.images.load(str(folder / (name + ".png")), check_existing=True)
                    image.name = name
                    image.colorspace_settings.name = "sRGB" if colour else "Non-Color"
                maps[kind] = image
            images[lod][key] = dict(maps, tile=tiles[key])
    return images


SCREENS = ["Screen_Roster", "Screen_Case", "Screen_Return", "Screen_Systems", "Screen_Garden", "Screen_Archive",
           "Screen_Diag", "Screen_Echo", "Screen_Checklist", "Screen_Route"]
LAMPS = ["Lamp_SealA", "Lamp_SealB", "Lamp_Supply", "Lamp_Return", "Lamp_Stored", "Lamp_Local", "Lamp_Dish",
         "Lamp_Feed", "Lamp_Isolated", "Lamp_Echo", "Lamp_Battery"] + [f"Lamp_{k}" for k in LEDGER]


def chapter7_materials(images, relief_maps):
    """Kit table per LOD (hk.make_materials) plus this set's plain slots: role colours, live screens, state lamps,
    clear plastics, foam, seeds, rubber, ESD mat, task light, the water-cell fill and the relief resin."""
    mats = hk.make_materials(images)
    for lod, table in mats.items():
        sfx = "" if lod == 0 else "_LOD1"
        plain = lambda name, colour, rough, **kw: (hk.pbr_material(name + sfx, None, rough, colour, **kw), 1.0)  # noqa: E731
        for role, hexcode in ROLES:
            table[f"Role_{role}"] = plain(f"Role_{role}", srgb(hexcode), 0.42)
        for name in SCREENS:  # a live UI slot: the room assigns a ViewportTexture; the checklist is paper until drawn on
            paper = name == "Screen_Checklist"
            table[name] = plain(name, (0.86, 0.86, 0.84) if paper else (0.02, 0.025, 0.03), 0.9 if paper else 0.12)
        for name in LAMPS:   # unlit at rest; chapter7_assets.gd sets idle / pass / fail / warn per state
            table[name] = plain(name, (0.20, 0.21, 0.22), 0.25, emission=((0.30, 0.32, 0.34), 0.15))
        table["M_Clear"] = plain("M_Clear", (0.86, 0.90, 0.95), 0.04, alpha=0.18)
        table["M_Foam"] = plain("M_Foam", (0.055, 0.058, 0.062), 0.96)
        table["M_Seed"] = plain("M_Seed", srgb("#4A2A1C"), 0.45)
        table["M_Rubber"] = plain("M_Rubber", (0.025, 0.025, 0.028), 0.88)
        table["M_ESDMat"] = plain("M_ESDMat", srgb("#2F4A57"), 0.82)
        table["M_TaskLight"] = plain("M_TaskLight", (1.0, 0.88, 0.76), 0.6, emission=((1.0, 0.86, 0.70), 3.0))
        table["WaterFill"] = plain("WaterFill", srgb("#2E8BC0"), 0.2, emission=(srgb("#2E8BC0"), 0.6))
        table["M_Gold"] = plain("M_Gold", srgb("#B8A06A"), 0.35)
        table["M_Garden"] = plain("M_Garden", srgb("#4CAF50"), 0.45)
        # untextured tag parts: the Tripo feedthrough embeds its own maps, so its GLB must not also reference kit files
        table["M_TagOrange"] = plain("M_TagOrange", srgb("#F26B21"), 0.55)
        table["M_TagWhite"] = plain("M_TagWhite", (0.86, 0.87, 0.88), 0.6)
        table["M_TieSteel"] = plain("M_TieSteel", (0.62, 0.63, 0.65), 0.35)
        relief = relief_maps[lod]
        table["M_Resin"] = (hk.pbr_material("M_Resin" + sfx, relief), 1.0)
    return mats


# ----------------------------------------------------------------------------------------------- geometry helpers

def prism(b, outline, axis, a0, a1, key, smooth_sides=False, caps=(True, True)):
    """Solid prism: a 2D outline (u, v) extruded along an axis from a0 to a1. axis 'y': (u, v) = (x, z);
    'z': (u, v) = (x, y); 'x': (u, v) = (z, y). Faces are oriented by the Builder's outward rule."""
    def p(u, v, w):
        return {"x": (w, v, u), "y": (u, w, v), "z": (u, v, w)}[axis]
    lo, hi = [p(u, v, a0) for u, v in outline], [p(u, v, a1) for u, v in outline]
    ax = Vector(p(0, 0, 1)) * (1 if a1 > a0 else -1)
    centre = sum((Vector(q) for q in lo), Vector()) / len(lo)
    t = b.tile(key)
    if caps[1]:
        b.quad(hi, key, outward=ax)
    if caps[0]:
        b.quad(lo, key, outward=-ax)
    n = len(outline)
    run = 0.0
    for i in range(n):
        j = (i + 1) % n
        q = [Vector(lo[i]), Vector(lo[j]), Vector(hi[j]), Vector(hi[i])]
        seg = (q[1] - q[0]).length
        uvs = [(run / t, 0), ((run + seg) / t, 0), ((run + seg) / t, abs(a1 - a0) / t), (run / t, abs(a1 - a0) / t)]
        run += seg
        mid = (q[0] + q[1]) / 2
        out = mid - centre
        out -= ax * out.dot(ax)
        b.quad([tuple(v) for v in q], key, uvs=uvs, smooth=smooth_sides, outward=out)


def rbox(b, centre, size, r, key, axis="y", arc=4):
    """Box with rounded vertical (axis) edges: a rounded-rectangle prism."""
    cx, cy, cz = centre
    sx, sy, sz = size
    if axis == "y":
        pts = [(x + cx, z + cz) for x, z in hk.rounded_rect(sx, sz, r, arc)]
        prism(b, pts, "y", cy - sy / 2, cy + sy / 2, key)
    elif axis == "z":
        pts = [(x + cx, y + cy) for x, y in hk.rounded_rect(sx, sy, r, arc)]
        prism(b, pts, "z", cz - sz / 2, cz + sz / 2, key)
    else:
        pts = [(z + cz, y + cy) for z, y in hk.rounded_rect(sz, sy, r, arc)]
        prism(b, pts, "x", cx - sx / 2, cx + sx / 2, key)


def sphere(b, centre, r, key, segs=8, rings=6):
    c = Vector(centre)
    t = b.tile(key)
    rows = []
    for j in range(1, rings):
        phi = math.pi * j / rings
        rows.append(b.add_verts([c + Vector((r * math.sin(phi) * math.cos(2 * math.pi * i / segs), r * math.cos(phi), r * math.sin(phi) * math.sin(2 * math.pi * i / segs))) for i in range(segs)]))
    top, bottom = b.add_verts([c + Vector((0, r, 0))]), b.add_verts([c - Vector((0, r, 0))])
    for i in range(segs):
        k = (i + 1) % segs
        b.add_face([top, rows[0] + i, rows[0] + k], [(0, 0), (r / t, 0), (0, r / t)], key, True, outward=b.verts[rows[0] + i] - c)
        b.add_face([bottom, rows[-1] + k, rows[-1] + i], [(0, 0), (r / t, 0), (0, r / t)], key, True, outward=b.verts[rows[-1] + i] - c)
        for j in range(len(rows) - 1):
            idx = [rows[j] + i, rows[j] + k, rows[j + 1] + k, rows[j + 1] + i]
            mid = sum((b.verts[q] for q in idx), Vector()) / 4
            b.add_face(idx, [(0, 0), (r / t, 0), (r / t, r / t), (0, r / t)], key, True, outward=mid - c)


def strip(b, p0, p1, width, z, key, proud=0.0015):
    """A raised printed line on a plate face (the face lies at z, plates face -Z): a thin box between two points."""
    a, c = Vector((p0[0], p0[1], 0)), Vector((p1[0], p1[1], 0))
    d = c - a
    if d.length < 1e-6:
        return
    n = Vector((-d.y, d.x, 0)).normalized() * width / 2
    pts = [a - n, c - n, c + n, a + n]
    outline = [(q.x, q.y) for q in pts]
    prism(b, outline, "z", z, z - proud, key)


def ring_line(b, centre, R, width, z, key, segs=24, proud=0.0015, arc=(0.0, 360.0)):
    """A raised circle (or arc) of a printed diagram on a plate face."""
    a0, a1 = math.radians(arc[0]), math.radians(arc[1])
    n = max(2, int(segs * (a1 - a0) / (2 * math.pi)))
    pts = [(centre[0] + R * math.cos(a0 + (a1 - a0) * i / n), centre[1] + R * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]
    for p, q in zip(pts, pts[1:]):
        strip(b, p, q, width, z, key, proud)


def disc(b, centre, r, z0, z1, key, segs=16):
    """A round button / lamp / boss standing off a plate face: a cylinder along Z."""
    b.cylinder((centre[0], centre[1], z0), (centre[0], centre[1], z1), r, key, segs=segs)


def ribbon(b, pts, width, height, key):
    """A raised strip along a 3D polyline lying on a surface (the road inlay): top face plus two side walls."""
    pts = [Vector(p) for p in pts]
    left, right = [], []
    for i, p in enumerate(pts):
        a = pts[max(0, i - 1)]
        c = pts[min(len(pts) - 1, i + 1)]
        d = Vector((c.x - a.x, 0, c.z - a.z))
        if d.length < 1e-9:
            d = Vector((1, 0, 0))
        n = Vector((-d.z, 0, d.x)).normalized() * width / 2
        left.append(p + n)
        right.append(p - n)
    up = Vector((0, height, 0))
    run = 0.0
    t = b.tile(key)
    for i in range(len(pts) - 1):
        seg = (pts[i + 1] - pts[i]).length
        u0, u1 = run / t, (run + seg) / t
        run += seg
        b.quad([tuple(left[i] + up), tuple(left[i + 1] + up), tuple(right[i + 1] + up), tuple(right[i] + up)], key, uvs=[(u0, 0), (u1, 0), (u1, width / t), (u0, width / t)], outward=(0, 1, 0))
        for side, sgn in ((left, 1), (right, -1)):
            out = (side[i] + side[i + 1]) / 2 - (pts[i] + pts[i + 1]) / 2
            b.quad([tuple(side[i] - up * 2), tuple(side[i + 1] - up * 2), tuple(side[i + 1] + up), tuple(side[i] + up)], key, uvs=[(u0, 0), (u1, 0), (u1, height / t), (u0, height / t)], outward=out)


def bumper_corners(b, half_x, half_z, y0, y1, key, size=0.05, r=0.016, grow=0.004):
    """Navy corner guards wrapping the four vertical edges of a case between y0 and y1 (the approved seed-case look)."""
    for sx in (-1, 1):
        for sz in (-1, 1):
            cx, cz = sx * (half_x - size / 2 + grow), sz * (half_z - size / 2 + grow)
            rbox(b, (cx, (y0 + y1) / 2, cz), (size, y1 - y0, size), r, key)


def grain(b, factor, start=0):
    """Repeat the kit's paint and steel grain `factor` times as often on a small object's faces (from face `start`):
    the kit's 0.5 m paint tile reads as coarse plaster on a 0.3 m case. Live screens keep their 0..1 UVs."""
    textured = set(hk.MATERIAL_KEYS)
    for f in range(start, len(b.uvs)):
        if b.keys[b.mats[f]] in textured:
            b.uvs[f] = [(u * factor, v * factor) for u, v in b.uvs[f]]


# ----------------------------------------------------------------------------------------------- asset context

class Ctx:
    """What one asset build function writes into: the body Builder, child parts on their own pivots, collision boxes
    (game LOD only) and sockets (game LOD only)."""

    def __init__(self, table, lod):
        self.table, self.lod = table, lod
        self.body = Builder(table)
        self.children = []   # (name, pivot, Builder)
        self.cols = []       # (name, centre, size)
        self.sockets = []    # (name, position)

    def seg(self, hi, lo=None):
        return hi if self.lod == 0 else (lo if lo is not None else max(4, hi // 2))

    def child(self, name, pivot):
        b = Builder(self.table)
        self.children.append((name, tuple(pivot), b))
        return b

    def col(self, name, centre, size):
        self.cols.append((name + "_Col-convcolonly", tuple(centre), tuple(size)))

    def socket(self, name, pos):
        self.sockets.append((name, tuple(round(v, 4) for v in pos)))


# ----------------------------------------------------------------------------------------------- PR_ShelterDiagram

SD_W, SD_H, SD_T = 0.80, 0.66, 0.022
SD_FACE = -SD_T - 0.004               # the white enamel face
SD_PLAN = (0.0, 0.335)                # centre of the 8 x 6 m Safe Room plan on the board
SD_M = 0.065                          # board metres per room metre (8 m -> 0.52 m)
# five seats in an arc on the protected interior side of the central latch, the hatch side kept clear for egress
SD_SEATS = [(SD_PLAN[0] + 0.005 + 0.125 * math.cos(math.radians(a)), SD_PLAN[1] + 0.125 * math.sin(math.radians(a))) for a in (68, 34, 0, -34, -68)]
SD_PARK = [(-0.26 + 0.13 * k, 0.062) for k in range(5)]


def seat_marker(b, ctx, role):
    """A magnetic seat marker (axis along -Z off the board): white puck, role-colour cap, steel knob. Pivot = magnet face."""
    s = ctx.seg(20, 10)
    b.cylinder((0, 0, 0), (0, 0, -0.010), 0.020, "PaintWhite", segs=s)
    b.cylinder((0, 0, -0.010), (0, 0, -0.0145), 0.0172, f"Role_{role}", segs=s)
    b.cylinder((0, 0, -0.0145), (0, 0, -0.024), 0.0055, "Steel", segs=ctx.seg(10, 6))
    if ctx.lod == 0:
        b.torus((0, 0, -0.010), (0, 0, 1), 0.0186, 0.0016, "PaintWhite", segs=s, rings=4)
    grain(b, 4.0)


def prop_shelter_diagram(ctx):
    b, lod = ctx.body, ctx.lod
    prism(b, [(x, y + SD_H / 2) for x, y in hk.rounded_rect(SD_W, SD_H, 0.03, 4 if lod == 0 else 2)], "z", 0.0, -SD_T, "PaintNavy")
    b.box((0, 0.335, -SD_T - 0.002), (0.74, 0.46, 0.004), "PaintWhite")                    # enamel face y 0.105..0.565
    b.box((0, 0.062, -SD_T - 0.0015), (0.70, 0.050, 0.003), "Steel")                       # magnetic parking strip
    b.box((0, 0.610, -SD_T - 0.003), (0.54, 0.066, 0.006), "PaintDark")                     # status strip bezel
    b.quad([(0.26, 0.585, -SD_T - 0.0062), (-0.26, 0.585, -SD_T - 0.0062), (-0.26, 0.635, -SD_T - 0.0062), (0.26, 0.635, -SD_T - 0.0062)],
           "Screen_Roster", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 0, -1))
    z = SD_FACE
    w = 0.005
    hx, hy = 4.0 * SD_M, 3.0 * SD_M
    cx, cy = SD_PLAN
    for p, q in (((cx - hx, cy - hy), (cx + hx, cy - hy)), ((cx + hx, cy - hy), (cx + hx, cy + hy)),
                 ((cx + hx, cy + hy), (cx - hx, cy + hy)), ((cx - hx, cy + hy), (cx - hx, cy - hy))):
        strip(b, p, q, w, z, "PaintNavy")
    # hatch to the commons on the -x short wall (the viewer's right, since plates face -Z), drawn as an orange door bar
    strip(b, (cx - hx, cy - 0.045), (cx - hx, cy + 0.045), 0.011, z - 0.0015, "PaintOrange")
    ring_line(b, (cx - hx, cy), 0.045, 0.003, z, "PaintOrange", segs=ctx.seg(16, 8), arc=(-90, 90))
    # perimeter water-wall panels inside the far, near and +x walls (blue), in panel lengths with joints
    inset = 0.012
    for y in (cy - hy + inset, cy + hy - inset):
        x = cx - hx + 0.06
        while x + 0.07 <= cx + hx - inset:
            strip(b, (x, y), (x + 0.07, y), 0.008, z, "PaintBlue")
            x += 0.082
    y = cy - hy + 0.03
    while y + 0.07 <= cy + hy - 0.03:
        strip(b, (cx + hx - inset, y), (cx + hx - inset, y + 0.07), 0.008, z, "PaintBlue")
        y += 0.082
    # four indexed bundle slots (crate rails) along the +x wall, inside the water panels
    for k in range(4):
        yy = cy - 0.105 + 0.07 * k
        b.box((cx + hx - 0.045, yy, z - 0.0008), (0.034, 0.05, 0.0016), "PaintGrey")
    # the central protected seed latch
    b.box((cx + 0.005, cy, z - 0.0009), (0.028, 0.028, 0.0018), "M_Gold")
    disc(b, (cx + 0.005, cy), 0.006, z - 0.0018, z - 0.0036, "PaintNavy", segs=ctx.seg(12, 6))
    # five seat positions around the latch, facing it; each ring carries a socket where its marker snaps
    for k, (sx, sy) in enumerate(SD_SEATS):
        ring_line(b, (sx, sy), 0.026, 0.004, z, "PaintNavy", segs=ctx.seg(24, 10))
        ctx.socket(f"Seat_{k + 1}", (sx, sy, z))
    for k, (px, py) in enumerate(SD_PARK):
        ctx.socket(f"Park_{k + 1}", (px, py, -SD_T - 0.003))
    if lod == 0:
        for sx in (-1, 1):  # four mounting screws
            for sy in (0.03, SD_H - 0.03):
                disc(b, (sx * (SD_W / 2 - 0.03), sy), 0.006, -SD_T, -SD_T - 0.003, "Steel", segs=10)
    for k, (role, _) in enumerate(ROLES):
        seat_marker(ctx.child(f"SeatMarker_{role}", (SD_PARK[k][0], SD_PARK[k][1], -SD_T - 0.003)), ctx, role)
    ctx.col("ShelterDiagram", (0, SD_H / 2, -0.02), (SD_W, SD_H, 0.04))


# ----------------------------------------------------------------------------------------------- PR_SeedCase

SC_W, SC_D = 0.310, 0.250
SC_TOP, SC_LID = 0.118, 0.150
SC_VIAL_R, SC_VIAL_Y0, SC_VIAL_Y1 = 0.0060, 0.068, 0.100


def seed_wells(cx):
    """The 15 vial positions of one compartment: 3 across by 5 deep."""
    return [(cx + (i - 1) * 0.036, (j - 2) * 0.040) for j in range(5) for i in range(3)]


def prop_seed_case(ctx):
    b, lod = ctx.body, ctx.lod
    arc = 5 if lod == 0 else 2
    hx, hz = SC_W / 2, SC_D / 2
    # body: base slab, white walls (ring between the outer outline and the opening), navy rim band
    prism(b, hk.rounded_rect(SC_W, SC_D, 0.03, arc), "y", 0.008, 0.020, "PaintWhite")
    outer = hk.rounded_rect(SC_W, SC_D, 0.03, arc)
    inner = hk.rounded_rect(SC_W - 0.024, SC_D - 0.024, 0.018, arc)
    b.ring_prism([(x, 0.020, z) for x, z in inner], [(x, 0.020, z) for x, z in outer], (0, SC_TOP - 0.006 - 0.020, 0), "PaintWhite", front_normal=(0, -1, 0), centre=(0, 0.020, 0))
    outer_rim = hk.rounded_rect(SC_W + 0.006, SC_D + 0.006, 0.033, arc)
    b.ring_prism([(x, SC_TOP - 0.006, z) for x, z in inner], [(x, SC_TOP - 0.006, z) for x, z in outer_rim], (0, 0.006, 0), "PaintNavy", front_normal=(0, -1, 0), centre=(0, SC_TOP - 0.006, 0))
    bumper_corners(b, hx, hz, 0.004, 0.055, "PaintNavy")
    bumper_corners(b, hx, hz, 0.080, SC_TOP - 0.006, "PaintNavy", size=0.045)
    for sx in (-1, 1):  # skid rails and rubber feet
        b.box((sx * 0.10, 0.006, 0), (0.03, 0.012, SC_D - 0.05), "PaintNavy")
        for sz in (-1, 1):
            b.box((sx * 0.10, 0.003, sz * 0.09), (0.034, 0.006, 0.03), "M_Rubber")
    # interior: divider, two foam beds, 15 vials each with exactly one seed (Brassica rapa, about 2 mm)
    b.box((0, 0.062, 0), (0.006, 0.084, SC_D - 0.024), "PaintWhite")
    for comp, cx in (("A", -0.073), ("B", 0.073)):
        b.box((cx, 0.044, 0), (0.134, 0.048, 0.222), "M_Foam")
        for k, (x, z) in enumerate(seed_wells(cx)):
            b.cylinder((x, SC_VIAL_Y0, z), (x, SC_VIAL_Y1, z), SC_VIAL_R, "M_Clear", segs=ctx.seg(12, 6))
            b.cylinder((x, SC_VIAL_Y1, z), (x, SC_VIAL_Y1 + 0.007, z), SC_VIAL_R + 0.0008, "PaintWhite", segs=ctx.seg(12, 6))
            if lod == 0:
                b.torus((x, SC_VIAL_Y0 + 0.0008, z), (0, 1, 0), SC_VIAL_R + 0.0008, 0.0016, "M_Foam", segs=12, rings=4)
                sphere(b, (x + 0.0012, SC_VIAL_Y0 + 0.0012, z - 0.001), 0.0010, "M_Seed", segs=8, rings=5)
            else:
                b.box((x, SC_VIAL_Y0 + 0.001, z), (0.002, 0.002, 0.002), "M_Seed")
            ctx.socket(f"Well_{comp}_{k + 1:02d}", (x, SC_VIAL_Y1 + 0.007, z))
        # inner seal lid of the compartment, hinged at the back, with its seal lamp at the front
        lb = ctx.child(f"CompartmentLid_{comp}", (cx, 0.1085, 0.111))
        frame_o = [(x, z - 0.111) for x, z in hk.rounded_rect(0.130, 0.222, 0.008, arc)]
        frame_i = [(x, z - 0.111) for x, z in hk.rounded_rect(0.110, 0.200, 0.004, arc)]
        lb.ring_prism([(x, 0, z) for x, z in frame_i], [(x, 0, z) for x, z in frame_o], (0, 0.004, 0), "PaintNavy", front_normal=(0, -1, 0), centre=(0, 0, -0.111))
        lb.box((0, 0.002, -0.111), (0.110, 0.0016, 0.200), "M_Clear")
        lb.cylinder((0, 0.004, -0.214), (0, 0.009, -0.214), 0.007, "PaintOrange", segs=ctx.seg(12, 6))
        lb.box((0, 0.009, -0.214), (0.012, 0.003, 0.003), "PaintOrange")
        lb.cylinder((0.050, 0.004, -0.214), (0.050, 0.0065, -0.214), 0.0032, f"Lamp_Seal{comp}", segs=ctx.seg(10, 6))
    # front sealed-telemetry window (S06: the case is checked through its sensor record, not opened)
    b.box((0.078, 0.064, -hz - 0.002), (0.074, 0.034, 0.004), "PaintDark")
    b.quad([(0.112, 0.050, -hz - 0.0042), (0.044, 0.050, -hz - 0.0042), (0.044, 0.078, -hz - 0.0042), (0.112, 0.078, -hz - 0.0042)],
           "Screen_Case", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 0, -1))
    # latch keeper on the body and the hinge knuckles at the back
    b.box((0, SC_TOP - 0.010, -hz - 0.004), (0.030, 0.010, 0.008), "Steel")
    for x in (-0.09, 0.09):
        b.cylinder((x - 0.025, SC_TOP, hz + 0.004), (x + 0.025, SC_TOP, hz + 0.004), 0.005, "Steel", segs=ctx.seg(10, 6))
    # two side grips for the two-handed carry (S04: "Mei carries the protected case to the shelter with both hands")
    for sx, name in ((-1, "Grip_R"), (1, "Grip_L")):
        x0, x1 = sx * hx, sx * (hx + 0.0145)
        for z in (-0.055, 0.055):
            b.cylinder((x0, 0.082, z), (x1, 0.082, z), 0.006, "PaintNavy", segs=ctx.seg(10, 6))
        b.cylinder((x1, 0.082, -0.06), (x1, 0.082, 0.06), 0.0062, "PaintNavy", segs=ctx.seg(12, 6))
        ctx.socket(name, (x1, 0.082, 0))
    # the main lid on its back hinge
    lid = ctx.child("Lid", (0, SC_TOP, hz + 0.004))
    off = -(hz + 0.004)
    prism(lid, [(x, z + off) for x, z in hk.rounded_rect(SC_W, SC_D, 0.03, arc)], "y", 0.006, SC_LID - SC_TOP, "PaintWhite")
    lid.ring_prism([(x, 0, z + off) for x, z in hk.rounded_rect(SC_W - 0.02, SC_D - 0.02, 0.022, arc)],
                   [(x, 0, z + off) for x, z in hk.rounded_rect(SC_W + 0.006, SC_D + 0.006, 0.033, arc)], (0, 0.006, 0), "PaintNavy", front_normal=(0, -1, 0), centre=(0, 0, off))
    prism(lid, [(x, z + off) for x, z in hk.rounded_rect(0.23, 0.16, 0.02, arc)], "y", SC_LID - SC_TOP, SC_LID - SC_TOP + 0.003, "PaintWhite")
    for x in (-0.135, 0.135):
        lid.box((x, SC_LID - SC_TOP + 0.002, off), (0.012, 0.004, 0.17), "PaintNavy")
    lid.box((0, 0.006, off - hz - 0.004), (0.036, 0.008, 0.008), "Steel")   # the hook the latch pulls on
    # the draw latch: orange lever hinged on the body front, lying flat against it when closed
    lt = ctx.child("Latch", (0, 0.088, -hz - 0.006))
    lt.box((0, 0.020, -0.004), (0.044, 0.044, 0.008), "PaintOrange")
    lt.box((0, 0.040, -0.0005), (0.034, 0.006, 0.006), "Steel")
    lt.cylinder((-0.024, 0, -0.003), (0.024, 0, -0.003), 0.004, "Steel", segs=ctx.seg(10, 6))
    ctx.socket("Rest", (0, 0, 0))
    for bb in [b] + [cb for _, _, cb in ctx.children]:
        grain(bb, 3.0)
    ctx.col("SeedCase", (0, SC_LID / 2, 0), (SC_W, SC_LID, SC_D))


# ----------------------------------------------------------------------------------------------- PR_ValveDiagram

VD_W, VD_H, VD_T = 0.72, 0.54, 0.020
VD_FACE = -VD_T - 0.004
VD_CELLS = [(0.040 + k * 0.048, 0.215, 0.040, 0.205) for k in range(WATER_UNITS)]  # x0, y0, w, h of each wall unit
VD_SUPPLY, VD_RETURN = (-0.080, 0.468), (-0.080, 0.158)


def valve_symbol(b, centre, z, ctx, lamp):
    """Two-way valve symbol: two navy triangles tip to tip, stem and handwheel, plus its lamp."""
    x, y = centre
    for sx in (-1, 1):
        prism(b, [(x, y), (x + sx * 0.018, y + 0.012), (x + sx * 0.018, y - 0.012)], "z", z, z - 0.0025, "PaintNavy")
    strip(b, (x, y), (x, y + 0.026), 0.003, z, "PaintNavy")
    ring_line(b, (x, y + 0.032), 0.008, 0.003, z, "PaintNavy", segs=ctx.seg(16, 8))
    disc(b, (x + 0.032, y + 0.016), 0.0055, z, z - 0.006, lamp, segs=ctx.seg(12, 6))
    b.torus((x + 0.032, y + 0.016, z - 0.0015), (0, 0, 1), 0.0062, 0.0014, "Steel", segs=ctx.seg(12, 6), rings=4)


def prop_valve_diagram(ctx):
    b, lod = ctx.body, ctx.lod
    prism(b, [(x, y + VD_H / 2) for x, y in hk.rounded_rect(VD_W, VD_H, 0.03, 4 if lod == 0 else 2)], "z", 0.0, -VD_T, "PaintNavy")
    b.box((0, 0.315, -VD_T - 0.002), (0.66, 0.40, 0.004), "PaintWhite")        # face y 0.115..0.515
    z = VD_FACE
    # garden reservoir with its green garden band
    rx0, rx1, ry0, ry1 = -0.300, -0.180, 0.200, 0.440
    for p, q in (((rx0, ry0), (rx1, ry0)), ((rx1, ry0), (rx1, ry1)), ((rx1, ry1), (rx0, ry1)), ((rx0, ry1), (rx0, ry0))):
        strip(b, p, q, 0.005, z, "PaintNavy")
    b.box(((rx0 + rx1) / 2, ry1 - 0.016, z - 0.0008), (rx1 - rx0 - 0.012, 0.016, 0.0016), "M_Garden")
    # the six water-wall units: navy frames; their fills are children so the room can show W
    for k, (x0, y0, cw, ch) in enumerate(VD_CELLS):
        for p, q in (((x0, y0), (x0 + cw, y0)), ((x0 + cw, y0), (x0 + cw, y0 + ch)), ((x0 + cw, y0 + ch), (x0, y0 + ch)), ((x0, y0 + ch), (x0, y0))):
            strip(b, p, q, 0.004, z, "PaintNavy")
        fill = ctx.child(f"WaterCell_{k + 1}", (x0 + cw / 2, y0 + ch / 2, z))
        fill.box((0, 0, -0.0007), (cw - 0.010, ch - 0.010, 0.0014), "WaterFill")
        ctx.socket(f"Point_Cell_{k + 1}", (x0 + cw / 2, y0 + ch / 2, z))
    # supply line: reservoir top -> pump -> supply valve -> manifold over the cells, with a drop into each unit
    top = VD_SUPPLY[1]
    strip(b, (-0.24, ry1), (-0.24, top), 0.006, z, "PaintBlue")
    strip(b, (-0.24, top), (VD_CELLS[-1][0] + 0.02, top), 0.006, z, "PaintBlue")
    for x0, y0, cw, ch in VD_CELLS:
        strip(b, (x0 + cw / 2, top), (x0 + cw / 2, y0 + ch), 0.004, z, "PaintBlue")
    ring_line(b, (-0.155, top), 0.014, 0.003, z - 0.0015, "PaintNavy", segs=ctx.seg(20, 8))    # pump
    prism(b, [(-0.162, top - 0.008), (-0.162, top + 0.008), (-0.146, top)], "z", z - 0.0015, z - 0.0035, "PaintNavy")
    # return line: under the cells -> return valve -> reservoir bottom
    bot = VD_RETURN[1]
    for x0, y0, cw, ch in VD_CELLS:
        strip(b, (x0 + cw / 2, y0), (x0 + cw / 2, bot), 0.004, z, "PaintBlue")
    strip(b, (VD_CELLS[-1][0] + 0.02, bot), (-0.24, bot), 0.006, z, "PaintBlue")
    strip(b, (-0.24, bot), (-0.24, ry0), 0.006, z, "PaintBlue")
    valve_symbol(b, VD_SUPPLY, z - 0.0015, ctx, "Lamp_Supply")
    valve_symbol(b, VD_RETURN, z - 0.0015, ctx, "Lamp_Return")
    ctx.socket("Point_Supply", (VD_SUPPLY[0], VD_SUPPLY[1], z))
    ctx.socket("Point_Return", (VD_RETURN[0], VD_RETURN[1], z))
    ctx.socket("Point_Garden", ((rx0 + rx1) / 2, (ry0 + ry1) / 2, z))
    # the return-time panel on the navy frame: two-position selector (early / after the exposure sample) and a screen
    b.box((0.10, 0.060, -VD_T - 0.003), (0.40, 0.086, 0.006), "PaintDark")
    b.quad([(0.29, 0.024, -VD_T - 0.0062), (-0.09, 0.024, -VD_T - 0.0062), (-0.09, 0.096, -VD_T - 0.0062), (0.29, 0.096, -VD_T - 0.0062)],
           "Screen_Return", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 0, -1))
    sel = (-0.245, 0.060)
    disc(b, sel, 0.030, -VD_T, -VD_T - 0.003, "PaintDark", segs=ctx.seg(24, 10))
    for a in (-35, 35):
        ang = math.radians(90 + a)
        b.box((sel[0] + 0.026 * math.cos(ang), sel[1] + 0.026 * math.sin(ang), -VD_T - 0.004), (0.004, 0.004, 0.003), "PaintWhite")
    knob = ctx.child("ReturnSelector", (sel[0], sel[1], -VD_T - 0.003))
    knob.cylinder((0, 0, 0), (0, 0, -0.016), 0.017, "PaintOrange", segs=ctx.seg(20, 8))
    knob.box((0, 0.010, -0.017), (0.006, 0.020, 0.004), "PaintWhite")
    ctx.socket("Point_Selector", (sel[0], sel[1], -VD_T - 0.02))
    if lod == 0:
        for sx in (-1, 1):
            for sy in (0.03, VD_H - 0.03):
                disc(b, (sx * (VD_W / 2 - 0.03), sy), 0.006, -VD_T, -VD_T - 0.003, "Steel", segs=10)
    ctx.col("ValveDiagram", (0, VD_H / 2, -0.02), (VD_W, VD_H, 0.04))


# ----------------------------------------------------------------------------------------------- PR_TelemetryDisplay

TD_W, TD_H, TD_D = 0.96, 0.52, 0.085


def prop_telemetry_display(ctx):
    b, lod = ctx.body, ctx.lod
    prism(b, [(x, y + TD_H / 2) for x, y in hk.rounded_rect(TD_W, TD_H, 0.03, 4 if lod == 0 else 2)], "z", 0.0, -TD_D, "PaintNavy")
    zf = -TD_D
    for sx, name in ((1, "Screen_Systems"), (-1, "Screen_Garden")):   # +x is the viewer's left
        cx = sx * 0.228
        b.box((cx, 0.305, zf - 0.003), (0.420, 0.280, 0.006), "PaintDark")
        b.quad([(cx + 0.196, 0.180, zf - 0.0062), (cx - 0.196, 0.180, zf - 0.0062), (cx - 0.196, 0.430, zf - 0.0062), (cx + 0.196, 0.430, zf - 0.0062)],
               name, [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 0, -1))
    # ledger lamp column between the screens: E, A, H, C, R, Z top to bottom
    b.box((0, 0.305, zf - 0.002), (0.034, 0.30, 0.004), "PaintDark")
    for k, letter in enumerate(LEDGER):
        y = 0.430 - k * 0.050
        disc(b, (0, y), 0.0075, zf - 0.004, zf - 0.010, f"Lamp_{letter}", segs=ctx.seg(12, 6))
        b.torus((0, y, zf - 0.005), (0, 0, 1), 0.0088, 0.0018, "Steel", segs=ctx.seg(12, 6), rings=4)
        ctx.socket(f"Point_{letter}", (0, y, zf - 0.01))
    # keys and speaker along the bottom
    for k in range(5):
        x = 0.36 - k * 0.055
        b.box((x, 0.085, zf - 0.006), (0.040, 0.028, 0.012), "PaintGrey")
    b.box((-0.03, 0.085, zf - 0.007), (0.040, 0.028, 0.014), "PaintOrange")
    b.box((-0.25, 0.085, zf - 0.002), (0.34, 0.07, 0.004), "PaintDark")
    if lod == 0:
        for k in range(6):
            b.box((-0.25, 0.060 + k * 0.010, zf - 0.006), (0.32, 0.004, 0.006), "Steel")
    for sx in (-1, 1):
        hk.handle(b, (sx * 0.462, 0.27, zf), 0.30, lod, stand=0.04, radius=0.011)
    ctx.socket("Screen_Systems_Centre", (0.228, 0.305, zf - 0.007))
    ctx.socket("Screen_Garden_Centre", (-0.228, 0.305, zf - 0.007))
    ctx.col("TelemetryDisplay", (0, TD_H / 2, -TD_D / 2 - 0.02), (TD_W, TD_H, TD_D + 0.04))


# ----------------------------------------------------------------------------------------------- PR_ArchivePlayer

AP_W, AP_D, AP_H = 0.300, 0.200, 0.115


def prop_archive_player(ctx):
    b, lod = ctx.body, ctx.lod
    arc = 5 if lod == 0 else 2
    hx, hz = AP_W / 2, AP_D / 2
    prism(b, hk.rounded_rect(AP_W, AP_D, 0.02, arc), "y", 0.008, AP_H, "PaintGrey")
    bumper_corners(b, hx, hz, 0.004, 0.040, "PaintNavy", size=0.04, r=0.012, grow=0.003)
    bumper_corners(b, hx, hz, 0.085, AP_H + 0.003, "PaintNavy", size=0.04, r=0.012, grow=0.003)
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.cylinder((sx * 0.11, 0.0, sz * 0.07), (sx * 0.11, 0.008, sz * 0.07), 0.012, "M_Rubber", segs=ctx.seg(12, 6))
    zf = -hz
    # speaker grille (left as the listener sees it, +x)
    b.box((0.068, 0.060, zf - 0.001), (0.120, 0.070, 0.002), "PaintDark")
    if lod == 0:
        for k in range(7):
            b.box((0.068, 0.031 + k * 0.0097, zf - 0.0035), (0.112, 0.0035, 0.004), "Steel")
    ctx.socket("Speaker", (0.068, 0.060, zf - 0.01))
    # screen, stored-locally lamp, transport keys with raised icons, volume knob (right, -x)
    b.box((-0.062, 0.082, zf - 0.002), (0.112, 0.048, 0.004), "PaintDark")
    b.quad([(-0.010, 0.062, zf - 0.0042), (-0.114, 0.062, zf - 0.0042), (-0.114, 0.102, zf - 0.0042), (-0.010, 0.102, zf - 0.0042)],
           "Screen_Archive", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 0, -1))
    disc(b, (-0.131, 0.090), 0.0045, zf, zf - 0.004, "Lamp_Stored", segs=ctx.seg(10, 6))
    keys = [(-0.022, "play"), (-0.054, "pause"), (-0.086, "stop")]
    for x, icon in keys:
        b.box((x, 0.034, zf - 0.005), (0.024, 0.022, 0.010), "PaintNavy")
        zi = zf - 0.010
        if icon == "play":   # the triangle points to the viewer's right (-x)
            prism(b, [(x + 0.004, 0.028), (x + 0.004, 0.040), (x - 0.006, 0.034)], "z", zi, zi - 0.0015, "PaintWhite")
        elif icon == "pause":
            for dx in (-0.003, 0.003):
                b.box((x + dx, 0.034, zi - 0.0007), (0.0032, 0.011, 0.0015), "PaintWhite")
        else:
            b.box((x, 0.034, zi - 0.0007), (0.010, 0.010, 0.0015), "PaintWhite")
        ctx.socket(f"Key_{icon.capitalize()}", (x, 0.034, zi))
    b.cylinder((-0.124, 0.034, zf), (-0.124, 0.034, zf - 0.014), 0.011, "PaintDark", segs=ctx.seg(16, 8))
    b.box((-0.124, 0.040, zf - 0.0145), (0.002, 0.008, 0.002), "PaintOrange")
    # the archive card slot on top and its card, standing half out (it holds the stored recordings, nothing live)
    b.box((0.085, AP_H + 0.002, 0.040), (0.066, 0.004, 0.012), "PaintDark")
    card = ctx.child("ArchiveCard", (0.085, AP_H, 0.040))
    card.box((0, 0.020, 0), (0.054, 0.040, 0.004), "PaintNavy")
    card.box((0, 0.038, -0.0021), (0.054, 0.004, 0.0002), "PaintOrange")
    # folding carry handle, folded flat on the lid
    for x in (-0.115, 0.115):
        b.box((x, AP_H + 0.006, 0.045), (0.016, 0.012, 0.020), "PaintNavy")
        b.cylinder((x, AP_H + 0.008, 0.045), (x, AP_H + 0.008, -0.035), 0.0055, "Steel", segs=ctx.seg(10, 6))
    b.cylinder((-0.115, AP_H + 0.008, -0.035), (0.115, AP_H + 0.008, -0.035), 0.0065, "Steel", segs=ctx.seg(12, 6))
    for bb in [b] + [cb for _, _, cb in ctx.children]:
        grain(bb, 3.0)
    ctx.col("ArchivePlayer", (0, (AP_H + 0.015) / 2, 0), (AP_W, AP_H + 0.015, AP_D))


# ----------------------------------------------------------------------------------------------- PR_NetworkDiagnostic

ND_W, ND_H, ND_D = 0.84, 0.66, 0.100


def prop_network_diagnostic(ctx):
    b, lod = ctx.body, ctx.lod
    prism(b, [(x, y + ND_H / 2) for x, y in hk.rounded_rect(ND_W, ND_H, 0.03, 4 if lod == 0 else 2)], "z", 0.0, -ND_D, "PaintNavy")
    zf = -ND_D
    b.box((0, 0.47, zf - 0.002), (0.72, 0.30, 0.004), "PaintWhite")          # mimic face y 0.32..0.62
    z = zf - 0.004
    # habitat boundary: a dashed grey line; inside is the viewer's left (+x), outside the right (-x)
    bx = -0.08
    y = 0.335
    while y < 0.605:
        strip(b, (bx, y), (bx, min(y + 0.02, 0.605)), 0.005, z, "PaintDark")
        y += 0.032
    core = (0.25, 0.47)
    b.box((core[0], core[1], z - 0.001), (0.050, 0.050, 0.002), "PaintNavy")
    b.box((core[0], core[1], z - 0.0022), (0.026, 0.026, 0.0006), "PaintWhite")
    # local network branch: down to a bus with three nodes (rooms, garden, Safe Room), all inside the habitat
    strip(b, (core[0], core[1] - 0.025), (core[0], 0.38), 0.005, z, "PaintNavy")
    strip(b, (core[0] + 0.03, 0.38), (-0.02, 0.38), 0.005, z, "PaintNavy")
    for x in (0.16, 0.07, -0.02):
        ring_line(b, (x, 0.38), 0.012, 0.004, z - 0.0015, "PaintNavy", segs=ctx.seg(16, 8))
    # external branch: core -> feedthrough on the boundary -> Earth dish outside
    strip(b, (core[0] - 0.025, core[1] + 0.05), (bx, core[1] + 0.05), 0.005, z, "PaintNavy")
    strip(b, (core[0] - 0.025, core[1] + 0.02), (core[0] - 0.025, core[1] + 0.05), 0.005, z, "PaintNavy")
    b.box((bx, core[1] + 0.05, z - 0.0012), (0.030, 0.030, 0.0024), "PaintOrange")
    dish = (-0.25, core[1] + 0.05)
    strip(b, (bx, dish[1]), (dish[0] + 0.02, dish[1]), 0.005, z, "PaintNavy")
    ring_line(b, (dish[0], dish[1] + 0.012), 0.026, 0.005, z - 0.0015, "PaintNavy", segs=ctx.seg(20, 8), arc=(200, 340))
    strip(b, (dish[0], dish[1] - 0.010), (dish[0], dish[1] - 0.04), 0.004, z, "PaintNavy")
    strip(b, (dish[0] - 0.018, dish[1] - 0.04), (dish[0] + 0.018, dish[1] - 0.04), 0.004, z, "PaintNavy")
    ring_line(b, (-0.31, 0.59), 0.013, 0.003, z - 0.0015, "PaintBlue", segs=ctx.seg(16, 8))   # Earth glyph, up and away
    for name, (x, y) in (("Lamp_Local", (0.07, 0.345)), ("Lamp_Feed", (bx, core[1] + 0.09)), ("Lamp_Dish", (dish[0] + 0.05, dish[1] + 0.045))):
        disc(b, (x, y), 0.0075, z, z - 0.008, name, segs=ctx.seg(12, 6))
        b.torus((x, y, z - 0.002), (0, 0, 1), 0.0088, 0.0018, "Steel", segs=ctx.seg(12, 6), rings=4)
        ctx.socket("Point_" + name[5:], (x, y, z - 0.01))
    # lower controls: screen, three guarded test buttons, isolation key and its lamp, data-card slot
    b.box((0.21, 0.19, zf - 0.003), (0.36, 0.20, 0.006), "PaintDark")
    b.quad([(0.380, 0.100, zf - 0.0062), (0.040, 0.100, zf - 0.0062), (0.040, 0.280, zf - 0.0062), (0.380, 0.280, zf - 0.0062)],
           "Screen_Diag", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 0, -1))
    for k, branch in enumerate(("Local", "Dish", "Feed")):
        x = -0.04 - k * 0.095
        b.torus((x, 0.235, zf - 0.006), (0, 0, 1), 0.024, 0.004, "Steel", segs=ctx.seg(20, 8), rings=6 if lod == 0 else 4)
        b.cylinder((x, 0.235, zf), (x, 0.235, zf - 0.006), 0.028, "PaintGrey", segs=ctx.seg(20, 8))
        b.box((x, 0.190, zf - 0.0015), (0.050, 0.016, 0.003), "Steel")        # blank tag plate (live label above it)
        btn = ctx.child(f"TestButton_{branch}", (x, 0.235, zf - 0.006))
        btn.cylinder((0, 0, 0), (0, 0, -0.012), 0.015, "PaintOrange", segs=ctx.seg(16, 8))
        ctx.socket(f"Point_Test{branch}", (x, 0.235, zf - 0.02))
    key = (-0.33, 0.235)
    b.cylinder((key[0], key[1], zf), (key[0], key[1], zf - 0.010), 0.022, "Steel", segs=ctx.seg(20, 8))
    disc(b, (key[0], 0.285), 0.0065, zf, zf - 0.006, "Lamp_Isolated", segs=ctx.seg(12, 6))
    kb = ctx.child("IsolationKey", (key[0], key[1], zf - 0.010))
    kb.box((0, 0, -0.008), (0.006, 0.026, 0.016), "PaintDark")
    kb.cylinder((0, 0, 0), (0, 0, -0.004), 0.012, "PaintDark", segs=ctx.seg(16, 8))
    ctx.socket("Point_Isolation", (key[0], key[1], zf - 0.03))
    slot = (-0.19, 0.085)
    b.box((slot[0], slot[1], zf - 0.003), (0.080, 0.018, 0.006), "PaintDark")
    card = ctx.child("DataCard", (slot[0], slot[1], zf - 0.006))
    card.box((0, 0, -0.015), (0.054, 0.0024, 0.030), "PaintNavy")
    card.box((0, 0.0013, -0.028), (0.054, 0.0002, 0.004), "PaintOrange")
    ctx.socket("Point_DataCard", (slot[0], slot[1], zf - 0.03))
    b.box((-ND_W / 2 + 0.012, ND_H / 2, zf - 0.002), (0.010, ND_H - 0.08, 0.004), "Steel")       # door hinge strip
    b.box((ND_W / 2 - 0.03, 0.33, zf - 0.006), (0.020, 0.080, 0.012), "PaintOrange")           # door latch
    ctx.col("NetworkDiagnostic", (0, ND_H / 2, -ND_D / 2 - 0.01), (ND_W, ND_H, ND_D + 0.02))


# ----------------------------------------------------------------------------------------------- EN_Fabrication_Bench

FB_W, FB_D, FB_TOP = 1.80, 0.75, 0.903
FB_BOARD_TOP = 1.85


def rotate_since(b, mark, pivot, axis, degrees):
    """Rotate every vertex the Builder added since `mark` about a pivot (face orientation is kept by rotation)."""
    from mathutils import Matrix
    m = Matrix.Rotation(math.radians(degrees), 3, axis)
    p = Vector(pivot)
    for i in range(mark, len(b.verts)):
        b.verts[i] = p + m @ (b.verts[i] - p)


def connector(b, ctx, wrong):
    """A service connector lying in the tray along X: matching ones are round bayonet plugs, the wrong one a
    rectangular D-shell, so the mismatch shows in the shape, not only in the colour (S11)."""
    s = ctx.seg(16, 8)
    if wrong:
        b.box((0, 0.011, 0), (0.044, 0.018, 0.026), "PaintGrey")
        b.box((-0.026, 0.011, 0), (0.010, 0.014, 0.020), "Steel")
        b.cylinder((0.022, 0.011, 0), (0.060, 0.011, 0), 0.005, "M_Rubber", segs=ctx.seg(10, 6))
    else:
        b.cylinder((-0.026, 0.014, 0), (0.016, 0.014, 0), 0.0135, "PaintNavy", segs=s)
        b.cylinder((-0.030, 0.014, 0), (-0.026, 0.014, 0), 0.0145, "Steel", segs=s)
        b.cylinder((0.016, 0.014, 0), (0.028, 0.014, 0), 0.0095, "M_Rubber", segs=s)
        b.cylinder((0.028, 0.014, 0), (0.066, 0.014, 0), 0.005, "M_Rubber", segs=ctx.seg(10, 6))
        if ctx.lod == 0:
            b.torus((-0.010, 0.014, 0), (1, 0, 0), 0.0138, 0.0012, "Steel", segs=16, rings=4)
    grain(b, 4.0)


def env_fabrication_bench(ctx):
    b, lod = ctx.body, ctx.lod
    hx, hz = FB_W / 2, FB_D / 2
    # frame: four steel legs with feet, stretchers, a navy lower shelf
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.box((sx * (hx - 0.04), 0.43, sz * (hz - 0.04)), (0.05, 0.86, 0.05), "Steel")
            b.cylinder((sx * (hx - 0.04), 0.0, sz * (hz - 0.04)), (sx * (hx - 0.04), 0.012, sz * (hz - 0.04)), 0.03, "M_Rubber", segs=ctx.seg(12, 6))
        b.box((sx * (hx - 0.04), 0.15, 0), (0.04, 0.04, FB_D - 0.1), "Steel")
    for sz in (-1, 1):
        b.box((0, 0.15, sz * (hz - 0.04)), (FB_W - 0.1, 0.04, 0.04), "Steel")
    b.box((-0.30, 0.18, 0), (1.10, 0.02, FB_D - 0.12), "PaintNavy")
    # drawer cabinet on the viewer's left (+x): grey carcass, three navy drawers with orange pulls
    b.box((0.56, 0.48, 0.02), (0.52, 0.70, FB_D - 0.10), "PaintGrey")
    for k, (y0, h) in enumerate(((0.15, 0.26), (0.42, 0.20), (0.63, 0.18))):
        b.box((0.56, y0 + h / 2, -hz + 0.045), (0.48, h - 0.02, 0.012), "PaintNavy")
        b.box((0.56, y0 + h - 0.05, -hz + 0.032), (0.16, 0.022, 0.014), "PaintOrange")
    # worktop slab and the ESD mat
    b.box((0, FB_TOP - 0.023, 0), (FB_W, 0.040, FB_D), "PaintGrey")
    b.box((0, FB_TOP - 0.0015, -0.01), (FB_W - 0.08, 0.003, FB_D - 0.10), "M_ESDMat")
    b.box((0, FB_TOP - 0.03, -hz - 0.004), (FB_W, 0.034, 0.008), "PaintOrange")          # front edge guard
    # back tool board: uprights, pegboard, a sparse hole grid, tool shadows and tools, shelf and task light
    zb = hz - 0.01
    for sx in (-1, 1):
        b.box((sx * (hx - 0.02), (FB_TOP + FB_BOARD_TOP) / 2, zb), (0.04, FB_BOARD_TOP - FB_TOP, 0.04), "Steel")
    b.box((0, 1.35, zb + 0.01), (FB_W - 0.08, 0.84, 0.02), "PaintWhite")
    zf = zb
    if lod == 0:
        for i in range(17):
            for j in range(8):
                x, y = -0.80 + i * 0.10, 0.99 + j * 0.10
                b.quad([(x + 0.004, y - 0.004, zf - 0.0005), (x - 0.004, y - 0.004, zf - 0.0005), (x - 0.004, y + 0.004, zf - 0.0005), (x + 0.004, y + 0.004, zf - 0.0005)], "PaintDark", outward=(0, 0, -1))
    def shadow(cx, cy, w, h):
        for p, q in (((cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2)), ((cx + w / 2, cy - h / 2), (cx + w / 2, cy + h / 2)),
                     ((cx + w / 2, cy + h / 2), (cx - w / 2, cy + h / 2)), ((cx - w / 2, cy + h / 2), (cx - w / 2, cy - h / 2))):
            strip(b, p, q, 0.004, zf, "PaintDark", proud=0.0008)
    tools = [(0.66, 1.38, 0.07, 0.40), (0.50, 1.40, 0.04, 0.24), (0.42, 1.40, 0.04, 0.24), (0.27, 1.40, 0.11, 0.24), (0.05, 1.42, 0.16, 0.22), (-0.22, 1.40, 0.20, 0.20)]
    for cx, cy, w, h in tools:
        shadow(cx, cy, w + 0.03, h + 0.03)
        b.cylinder((cx, cy + h / 2 + 0.01, zf), (cx, cy + h / 2 + 0.01, zf - 0.03), 0.004, "Steel", segs=ctx.seg(8, 4))
    s = ctx.seg(12, 6)
    b.cylinder((0.66, 1.20, zf - 0.02), (0.66, 1.52, zf - 0.02), 0.011, "Steel", segs=s)              # torque wrench
    b.box((0.66, 1.55, zf - 0.02), (0.05, 0.04, 0.02), "Steel")
    b.cylinder((0.66, 1.20, zf - 0.02), (0.66, 1.30, zf - 0.02), 0.014, "M_Rubber", segs=s)
    for x in (0.50, 0.42):                                                                             # screwdrivers
        b.cylinder((x, 1.40, zf - 0.02), (x, 1.52, zf - 0.02), 0.012, "PaintOrange", segs=s)
        b.cylinder((x, 1.28, zf - 0.02), (x, 1.40, zf - 0.02), 0.003, "Steel", segs=ctx.seg(8, 4))
    for dx in (-0.02, 0.02):                                                                           # crimper
        b.box((0.27 + dx, 1.36, zf - 0.02), (0.014, 0.16, 0.012), "PaintNavy")
    b.box((0.27, 1.48, zf - 0.02), (0.05, 0.06, 0.014), "Steel")
    b.box((0.05, 1.42, zf - 0.025), (0.14, 0.20, 0.04), "PaintNavy")                                   # meter (no text)
    b.box((0.05, 1.47, zf - 0.046), (0.10, 0.05, 0.002), "PaintDark")
    for k in range(3):
        b.cylinder((0.01 + k * 0.04, 1.37, zf - 0.045), (0.01 + k * 0.04, 1.37, zf - 0.050), 0.007, "PaintGrey", segs=ctx.seg(10, 6))
    b.torus((-0.22, 1.40, zf - 0.02), (0, 0, 1), 0.075, 0.009, "PaintOrange", segs=ctx.seg(24, 10), rings=ctx.seg(8, 4))   # cable coil
    b.box((0, FB_BOARD_TOP - 0.015, hz - 0.13), (FB_W, 0.03, 0.26), "PaintGrey")                      # shelf
    b.box((0, FB_BOARD_TOP - 0.045, hz - 0.20), (FB_W - 0.20, 0.03, 0.06), "Steel")                     # light housing
    b.quad([(-(FB_W - 0.24) / 2, FB_BOARD_TOP - 0.0605, hz - 0.225), ((FB_W - 0.24) / 2, FB_BOARD_TOP - 0.0605, hz - 0.225),
            ((FB_W - 0.24) / 2, FB_BOARD_TOP - 0.0605, hz - 0.175), (-(FB_W - 0.24) / 2, FB_BOARD_TOP - 0.0605, hz - 0.175)], "M_TaskLight", outward=(0, -1, 0))
    for x in (-0.6, 0.0, 0.6):                                                                           # storage bins on the shelf
        b.box((x, FB_BOARD_TOP + 0.05, hz - 0.12), (0.30, 0.10, 0.20), "PaintBlue" if x else "PaintNavy")
    y0 = FB_TOP
    # bench vise on the viewer's far left
    vx = 0.78
    b.box((vx, y0 + 0.03, -hz + 0.12), (0.12, 0.06, 0.16), "PaintNavy")
    b.box((vx, y0 + 0.08, -hz + 0.07), (0.14, 0.05, 0.03), "Steel")
    b.box((vx, y0 + 0.08, -hz + 0.13), (0.14, 0.05, 0.03), "Steel")
    b.cylinder((vx, y0 + 0.06, -hz + 0.05), (vx, y0 + 0.06, -hz - 0.03), 0.009, "Steel", segs=s)
    b.cylinder((vx - 0.07, y0 + 0.06, -hz - 0.03), (vx + 0.07, y0 + 0.06, -hz - 0.03), 0.007, "PaintOrange", segs=s)
    # controller cradle: where the December spare controller (PR_RelayController, 0.50 x 0.46 m crate) is checked
    cx, cz = 0.36, 0.04
    b.box((cx, y0 + 0.010, cz), (0.58, 0.020, 0.52), "PaintNavy")
    for sx in (-1, 1):
        b.box((cx + sx * 0.27, y0 + 0.035, cz), (0.02, 0.03, 0.48), "Steel")
    b.cylinder((cx - 0.31, y0 + 0.05, cz + 0.20), (cx - 0.31, y0 + 0.20, cz + 0.20), 0.004, "Steel", segs=ctx.seg(8, 4))   # harness post
    b.cylinder((cx - 0.31, y0 + 0.20, cz + 0.20), (cx - 0.24, y0 + 0.20, cz + 0.20), 0.007, "M_Rubber", segs=ctx.seg(8, 4))
    ctx.socket("Socket_Controller", (cx, y0 + 0.020, cz))
    # battery cradle and the spare battery (S11: "the player loads the spare battery")
    bx, bz = -0.16, 0.13
    b.box((bx, y0 + 0.012, bz), (0.34, 0.024, 0.25), "PaintNavy")
    for sx in (-1, 1):
        b.box((bx + sx * 0.155, y0 + 0.05, bz), (0.012, 0.06, 0.22), "Steel")
    bat = ctx.child("SpareBattery", (bx, y0 + 0.024, bz))
    bat.box((0, 0.08, 0), (0.28, 0.16, 0.20), "PaintDark")
    bat.box((0, 0.162, 0), (0.24, 0.004, 0.16), "PaintGrey")
    for x in (-0.09, 0.09):
        bat.box((x, 0.168, -0.04), (0.05, 0.012, 0.04), "PaintOrange")
    bat.cylinder((-0.08, 0.186, 0.04), (0.08, 0.186, 0.04), 0.008, "PaintOrange", segs=s)
    for x in (-0.08, 0.08):
        bat.box((x, 0.174, 0.04), (0.014, 0.024, 0.014), "PaintOrange")
    if lod == 0:
        for k in range(6):
            bat.box((0, 0.03 + k * 0.022, -0.1015), (0.20, 0.008, 0.003), "PaintNavy")
    bat.cylinder((0.11, 0.12, -0.1005), (0.11, 0.12, -0.104), 0.006, "Lamp_Battery", segs=ctx.seg(10, 6))
    ctx.socket("Socket_Battery", (bx, y0 + 0.024, bz))
    # echo test unit (S11: "a controlled known-content echo demonstration")
    ex, ez = -0.56, 0.16
    b.box((ex, y0 + 0.06, ez), (0.30, 0.12, 0.22), "PaintNavy")
    b.box((ex, y0 + 0.072, ez - 0.112), (0.18, 0.08, 0.004), "PaintDark")
    b.quad([(ex - 0.082, y0 + 0.038, ez - 0.1142), (ex + 0.082, y0 + 0.038, ez - 0.1142), (ex + 0.082, y0 + 0.106, ez - 0.1142), (ex - 0.082, y0 + 0.106, ez - 0.1142)],
           "Screen_Echo", [(1, 0), (0, 0), (0, 1), (1, 1)], outward=(0, 0, -1))
    for x in (ex + 0.12, ex - 0.12):
        b.cylinder((x, y0 + 0.07, ez - 0.11), (x, y0 + 0.07, ez - 0.125), 0.008, "Steel", segs=ctx.seg(12, 6))
    disc(b, (ex + 0.12, y0 + 0.035), 0.005, ez - 0.11, ez - 0.115, "Lamp_Echo", segs=ctx.seg(10, 6))
    ctx.socket("Socket_EchoUnit", (ex, y0 + 0.12, ez))
    # connector tray with three matching plugs and one wrong one
    tx, tz = -0.48, -0.20
    b.box((tx, y0 + 0.006, tz), (0.36, 0.012, 0.16), "PaintGrey")
    for sx in (-1, 1):
        b.box((tx + sx * 0.175, y0 + 0.018, tz), (0.01, 0.024, 0.16), "PaintGrey")
    for sz in (-1, 1):
        b.box((tx, y0 + 0.018, tz + sz * 0.075), (0.36, 0.024, 0.01), "PaintGrey")
    for k, name in enumerate(("Connector_A", "Connector_B", "Connector_C", "Connector_Wrong")):
        pz = tz - 0.054 + k * 0.036
        connector(ctx.child(name, (tx - 0.03, y0 + 0.012, pz)), ctx, name.endswith("Wrong"))
        ctx.socket("Socket_" + name, (tx - 0.03, y0 + 0.012, pz))
    # the isolation checklist on a clipboard (Ferreira signs it); the sheet is a live text slot
    kx, kz = 0.02, -0.21
    clip = ctx.child("Checklist", (kx, y0, kz))
    clip.box((0, 0.003, 0), (0.23, 0.006, 0.32), "PaintNavy")
    clip.quad([(0.105, 0.0062, -0.145), (-0.105, 0.0062, -0.145), (-0.105, 0.0062, 0.130), (0.105, 0.0062, 0.130)],
              "Screen_Checklist", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 1, 0))
    clip.box((0, 0.011, 0.14), (0.10, 0.010, 0.03), "Steel")
    ctx.socket("Socket_Checklist", (kx, y0, kz))
    # ESD wrist strap coiled by the battery
    b.torus((0.12, y0 + 0.004, -0.02), (0, 1, 0), 0.04, 0.003, "PaintOrange", segs=ctx.seg(20, 8), rings=4)
    ctx.socket("Stand_Operator", (0, 0, -hz - 0.45))
    ctx.col("Bench", (0, FB_TOP / 2, 0), (FB_W, FB_TOP, FB_D))
    ctx.col("ToolBoard", (0, (FB_TOP + FB_BOARD_TOP) / 2, hz - 0.03), (FB_W, FB_BOARD_TOP - FB_TOP, 0.06))
    ctx.col("Shelf", (0, FB_BOARD_TOP - 0.03, hz - 0.13), (FB_W, 0.06, 0.26))


# ----------------------------------------------------------------------------------------------- EN_Fabrication_RouteSimulator

RS_W, RS_D, RS_TABLE = 2.00, 0.82, 0.80
RS_TRAY = 0.020          # tray floor above the table top frame
RS_BASE = 0.012          # relief plinth below the lowest terrain
RS_GRID = {0: 0.0105, 1: 0.021}
RS_TEX = {0: (2048, 620), 1: (1024, 310)}
RS_RELIEF_CENTRE_Z = 0.02


class Relief:
    """The LOLA corridor relief on the simulator table: table-space heights for the mesh grid and the texture grid."""

    def __init__(self, data):
        self.hm = data["hm"]
        self.lx = (rsd.REGION_Y_M[1] - rsd.REGION_Y_M[0]) * rsd.SCALE
        self.lz = (rsd.REGION_X_M[1] - rsd.REGION_X_M[0]) * rsd.SCALE
        xs = np.linspace(rsd.REGION_X_M[0], rsd.REGION_X_M[1], 200)
        ys = np.linspace(rsd.REGION_Y_M[0], rsd.REGION_Y_M[1], 600)
        self.h_floor = math.floor(float(self.hm.grid(xs, ys).min()) / 100.0) * 100.0 - 100.0
        self.y0 = RS_TABLE + RS_TRAY

    def table_to_map(self, X, Z):
        xc, yc = sum(rsd.REGION_X_M) / 2, sum(rsd.REGION_Y_M) / 2
        return xc - (np.asarray(Z) - RS_RELIEF_CENTRE_Z) / rsd.SCALE, yc - np.asarray(X) / rsd.SCALE

    def map_to_table(self, x, y, h):
        X, Y, Z = rsd.to_table(x, y, h, self.h_floor)
        return X, self.y0 + RS_BASE + Y, Z + RS_RELIEF_CENTRE_Z

    def height(self, X, Z):
        mx, my = self.table_to_map(X, Z)
        return self.y0 + RS_BASE + (self.hm.sample(mx, my) - self.h_floor) * rsd.SCALE * rsd.VERTICAL_EXAGGERATION

    def grid(self, step):
        nx, nz = int(round(self.lx / step)) + 1, int(round(self.lz / step)) + 1
        X = np.linspace(-self.lx / 2, self.lx / 2, nx)
        Z = np.linspace(RS_RELIEF_CENTRE_Z - self.lz / 2, RS_RELIEF_CENTRE_Z + self.lz / 2, nz)
        XX, ZZ = np.meshgrid(X, Z)
        return X, Z, self.height(XX, ZZ)

    def mesh_height(self, lod, X, Z):
        """The relief mesh's own (bilinear) height at table (X, Z), so inlays sit on the visible surface."""
        Xg, Zg, H = self._grids[lod]
        fx = np.clip((X - Xg[0]) / (Xg[1] - Xg[0]), 0, len(Xg) - 1.001)
        fz = np.clip((Z - Zg[0]) / (Zg[1] - Zg[0]), 0, len(Zg) - 1.001)
        i, j = int(fx), int(fz)
        u, v = fx - i, fz - j
        return float(H[j, i] * (1 - u) * (1 - v) + H[j, i + 1] * u * (1 - v) + H[j + 1, i] * (1 - u) * v + H[j + 1, i + 1] * u * v)

    def build_maps(self):
        """The fine LOLA normal map (in the mesh's tangent frame), cavity AO in an ORM map and a resin base colour per
        LOD; returns {lod: maps}."""
        self._grids = {lod: self.grid(RS_GRID[lod]) for lod in (0, 1)}
        out = {}
        stage = STAGE / "textures"
        stage.mkdir(parents=True, exist_ok=True)
        for lod in (0, 1):
            w, h = RS_TEX[lod]
            sfx = "" if lod == 0 else "_LOD1"
            u = (np.arange(w) + 0.5) / w
            v = 1.0 - (np.arange(h) + 0.5) / h            # row 0 = top of the picture = v 1
            X = -self.lx / 2 + u * self.lx
            Z = (RS_RELIEF_CENTRE_Z + self.lz / 2) - v * self.lz   # v grows toward -Z (the operator): T x B = +Y
            XX, ZZ = np.meshgrid(X, Z)
            fine = self.height(XX, ZZ)
            Xg, Zg, Hg = self._grids[lod]
            fx = np.clip((XX - Xg[0]) / (Xg[1] - Xg[0]), 0, len(Xg) - 1.001)
            fz = np.clip((ZZ - Zg[0]) / (Zg[1] - Zg[0]), 0, len(Zg) - 1.001)
            i, j = fx.astype(int), fz.astype(int)
            a, c = fx - i, fz - j
            # The mesh already carries the coarse shape with smooth vertex normals; the map holds the fine LOLA normal
            # expressed in the coarse surface's own tangent frame (T along +u = +X, B along +v = -Z, N up), so the
            # shader rebuilds the full-resolution normal without seams at the 1 cm mesh grid.
            px, py = self.lx / w, self.lz / h
            fdx = np.gradient(fine, px, axis=1)                 # dY/dX
            fdz = np.gradient(fine, py, axis=0)                 # dY/dZ: row 0 is v = 1, the -Z end, so Z grows with the row
            nf = np.stack([-fdx, np.ones_like(fdx), -fdz], axis=-1)
            nf /= np.linalg.norm(nf, axis=-1, keepdims=True)
            gx = np.gradient(Hg, Xg[1] - Xg[0], axis=1)
            gz = np.gradient(Hg, Zg[1] - Zg[0], axis=0)
            nc = np.stack([-gx, np.ones_like(gx), -gz], axis=-1)
            nc /= np.linalg.norm(nc, axis=-1, keepdims=True)
            ncx = nc[j, i] * ((1 - a) * (1 - c))[..., None] + nc[j, i + 1] * (a * (1 - c))[..., None] + nc[j + 1, i] * ((1 - a) * c)[..., None] + nc[j + 1, i + 1] * (a * c)[..., None]
            ncx /= np.linalg.norm(ncx, axis=-1, keepdims=True)
            tx = np.zeros_like(ncx)
            tx[..., 0] = 1.0
            tx -= ncx * (ncx * tx).sum(-1, keepdims=True)
            tx /= np.linalg.norm(tx, axis=-1, keepdims=True)
            bx = np.cross(ncx, tx)                               # N x T = -Z for a flat table: the +v direction
            n = np.stack([(nf * tx).sum(-1), (nf * bx).sum(-1), (nf * ncx).sum(-1)], axis=-1)
            n /= np.linalg.norm(n, axis=-1, keepdims=True)
            k = max(3, w // 256)
            pad = np.pad(fine, k, mode="edge")
            blur = sum(pad[k + dj:k + dj + h, k + di:k + di + w] for dj in range(-k, k + 1, max(1, k // 2)) for di in range(-k, k + 1, max(1, k // 2)))
            blur /= len(range(-k, k + 1, max(1, k // 2))) ** 2
            cavity = np.clip((blur - fine) / 0.0015, 0, 1)
            ao = 1.0 - 0.35 * cavity
            orm = np.stack([ao, np.full_like(ao, 0.62), np.zeros_like(ao)], axis=-1)
            speckle = 0.985 + 0.015 * hk.fractal(np.random.default_rng(SEED + lod), 256, 8, 64, 1.4)[:, :, None] * 0.5
            base = np.clip(np.ones((256, 256, 3)) * np.array([0.80, 0.795, 0.78])[None, None, :] * speckle, 0, 1)
            out[lod] = dict(base=hk.save_image(f"T_RouteRelief_BaseColor{sfx}", base, stage),
                            normal=hk.save_image(f"T_RouteRelief_Normal{sfx}", (n + 1) / 2, stage, srgb=False),
                            orm=hk.save_image(f"T_RouteRelief_ORM{sfx}", orm, stage, srgb=False), tile=1.0)
        return out


def relief_mesh(b, relief, lod):
    """The relief: a smooth-shaded height grid with planar UVs over its extent, vertical skirts down to the tray."""
    X, Z, H = relief._grids[lod]
    nx, nz = len(X), len(Z)
    zmax = RS_RELIEF_CENTRE_Z + relief.lz / 2
    top = []
    for j in range(nz):
        top.append(b.add_verts([(X[i], H[j, i], Z[j]) for i in range(nx)]))
    uv = lambda i, j: ((X[i] + relief.lx / 2) / relief.lx, (zmax - Z[j]) / relief.lz)  # noqa: E731
    for j in range(nz - 1):
        for i in range(nx - 1):
            idx = [top[j] + i, top[j] + i + 1, top[j + 1] + i + 1, top[j + 1] + i]
            b.add_face(idx, [uv(i, j), uv(i + 1, j), uv(i + 1, j + 1), uv(i, j + 1)], "M_Resin", True, outward=(0, 1, 0))
    floor = relief.y0
    edges = [([(i, 0) for i in range(nx)], (0, 0, -1)), ([(i, nz - 1) for i in range(nx)], (0, 0, 1)),
             ([(0, j) for j in range(nz)], (-1, 0, 0)), ([(nx - 1, j) for j in range(nz)], (1, 0, 0))]
    for cells, out in edges:
        for (i0, j0), (i1, j1) in zip(cells, cells[1:]):
            p0, p1 = (X[i0], H[j0, i0], Z[j0]), (X[i1], H[j1, i1], Z[j1])
            b.quad([(p0[0], floor, p0[2]), (p1[0], floor, p1[2]), p1, p0], "PaintWhite", outward=out)


def env_route_simulator(ctx, relief, data):
    b, lod = ctx.body, ctx.lod
    hx, hz = RS_W / 2, RS_D / 2
    s = ctx.seg(12, 6)
    # table: navy legs with levelling feet, apron, orange front bumper, grey top frame and tray, white rim
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.box((sx * (hx - 0.05), RS_TABLE / 2, sz * (hz - 0.05)), (0.06, RS_TABLE, 0.06), "PaintNavy")
            b.cylinder((sx * (hx - 0.05), 0.0, sz * (hz - 0.05)), (sx * (hx - 0.05), 0.014, sz * (hz - 0.05)), 0.032, "M_Rubber", segs=s)
    b.box((0, RS_TABLE - 0.05, -hz + 0.02), (RS_W, 0.10, 0.04), "PaintNavy")
    b.box((0, RS_TABLE - 0.05, hz - 0.02), (RS_W, 0.10, 0.04), "PaintNavy")
    for sx in (-1, 1):
        b.box((sx * (hx - 0.02), RS_TABLE - 0.05, 0), (0.04, 0.10, RS_D), "PaintNavy")
    b.box((0, 0.20, 0), (RS_W - 0.12, 0.03, RS_D - 0.12), "PaintGrey")                     # lower shelf
    b.box((0, RS_TABLE - 0.06, -hz - 0.006), (RS_W, 0.06, 0.012), "PaintOrange")
    b.box((0, RS_TABLE + RS_TRAY / 2, 0), (RS_W, RS_TRAY, RS_D), "PaintGrey")
    rim_y = relief.y0 + 0.045
    ix, iz = relief.lx / 2 + 0.004, relief.lz / 2 + 0.004
    for sz in (-1, 1):
        b.box((0, (relief.y0 + rim_y) / 2, RS_RELIEF_CENTRE_Z + sz * (iz + 0.0125)), (2 * ix + 0.05, rim_y - relief.y0, 0.025), "PaintWhite")
    for sx in (-1, 1):
        b.box((sx * (ix + 0.0125), (relief.y0 + rim_y) / 2, RS_RELIEF_CENTRE_Z), (0.025, rim_y - relief.y0, 2 * iz), "PaintWhite")
    relief_mesh(b, relief, lod)
    # the surveyed road (make_terrain.py relay_road) inlaid on the relief surface
    road = data["road"]
    pts = []
    for p in road[::1 if lod == 0 else 3]:
        X, _, Z = relief.map_to_table(p[0], p[1], p[2])
        pts.append((X, relief.mesh_height(lod, X, Z) + 0.0006, Z))
    ribbon(b, pts, 0.0045 if lod == 0 else 0.006, 0.0014, "PaintOrange")
    # end markers: Aurora's mast (white, orange tip) and the summit relay dish (gold)
    ax, _, az = relief.map_to_table(data["aurora"][0], data["aurora"][1], 0)
    ay = relief.mesh_height(lod, ax, az)
    b.cylinder((ax, ay - 0.004, az), (ax, ay + 0.004, az), 0.010, "PaintNavy", segs=s)
    b.cylinder((ax, ay + 0.004, az), (ax, ay + 0.050, az), 0.0028, "PaintWhite", segs=ctx.seg(8, 4))
    sphere(b, (ax, ay + 0.053, az), 0.0045, "PaintOrange", segs=ctx.seg(10, 6), rings=ctx.seg(6, 4))
    sx_, _, sz_ = relief.map_to_table(data["summit"][0], data["summit"][1], 0)
    sy = relief.mesh_height(lod, sx_, sz_)
    b.cylinder((sx_, sy - 0.004, sz_), (sx_, sy + 0.004, sz_), 0.010, "PaintNavy", segs=s)
    b.cylinder((sx_, sy + 0.004, sz_), (sx_, sy + 0.035, sz_), 0.0028, "Steel", segs=ctx.seg(8, 4))
    b.cylinder((sx_, sy + 0.033, sz_), (sx_, sy + 0.041, sz_), 0.016, "M_Gold", segs=ctx.seg(16, 8), radius1=0.006)
    b.cylinder((sx_, sy + 0.041, sz_), (sx_, sy + 0.050, sz_), 0.0015, "Steel", segs=ctx.seg(6, 4))
    ctx.socket("Site_Aurora", (ax, ay, az))
    ctx.socket("Site_Summit", (sx_, sy, sz_))
    # computed pads (high ground beside the road) and their road-level alternatives
    for k, c in enumerate(data["pads"]):
        X, _, Z = relief.map_to_table(c["x"], c["y"], c["h"])
        ctx.socket(f"Pad_R{k + 1}", (X, relief.mesh_height(lod, X, Z), Z))
        rp = data["road"][c["road_index"]]
        X, _, Z = relief.map_to_table(rp[0], rp[1], rp[2])
        ctx.socket(f"Pad_R{k + 1}_Road", (X, relief.mesh_height(lod, X, Z), Z))
    # pin holder on the front rail (viewer's right) and the three repeater pins, tip at their pivot
    phx, phz = -0.78, -hz + 0.05
    b.box((phx, RS_TABLE + RS_TRAY + 0.015, phz), (0.15, 0.03, 0.05), "PaintNavy")
    for k in range(3):
        px = phx - 0.05 + k * 0.05
        tip = (px, RS_TABLE + RS_TRAY + 0.030 - 0.018, phz)
        ctx.socket(f"PinPark_{k + 1}", tip)
        pin = ctx.child(f"RepeaterPin_{k + 1}", tip)
        pin.cylinder((0, 0, 0), (0, 0.030, 0), 0.0012, "Steel", segs=ctx.seg(6, 4), radius1=0.0016)
        pin.cylinder((0, 0.030, 0), (0, 0.042, 0), 0.0065, "PaintOrange", segs=ctx.seg(14, 6))
        pin.cylinder((0, 0.042, 0), (0, 0.046, 0), 0.0072, "PaintNavy", segs=ctx.seg(14, 6))
        pin.cylinder((0, 0.046, 0), (0, 0.066, 0), 0.0012, "PaintWhite", segs=ctx.seg(6, 4))
        sphere(pin, (0, 0.067, 0), 0.0025, "PaintOrange", segs=ctx.seg(8, 4), rings=4)
    # monitor on a post at the back right, tilted toward the operator
    px, pz = -hx + 0.08, hz - 0.06
    b.cylinder((px, RS_TABLE, pz), (px, 1.30, pz), 0.022, "Steel", segs=s)
    b.box((px, RS_TABLE + 0.01, pz), (0.12, 0.02, 0.10), "PaintNavy")
    mark = len(b.verts)
    mc = Vector((px + 0.30, 1.42, pz - 0.02))
    b.box(tuple(mc), (0.60, 0.38, 0.045), "PaintNavy")
    b.box(tuple(mc + Vector((0, 0, -0.024))), (0.56, 0.34, 0.004), "PaintDark")
    zq = mc.z - 0.0265
    b.quad([(mc.x + 0.26, mc.y - 0.16, zq), (mc.x - 0.26, mc.y - 0.16, zq), (mc.x - 0.26, mc.y + 0.16, zq), (mc.x + 0.26, mc.y + 0.16, zq)],
           "Screen_Route", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 0, -1))
    b.box(tuple(mc + Vector((-0.30, -0.08, 0.03))), (0.06, 0.06, 0.03), "Steel")
    rotate_since(b, mark, (mc.x, mc.y, mc.z), "X", 15.0)
    ctx.socket("Screen_Route_Centre", (mc.x, mc.y, zq))
    ctx.socket("Stand_Operator", (0, 0, -hz - 0.45))
    top = float(relief._grids[0][2].max())
    ctx.col("Table", (0, top / 2, 0), (RS_W, top, RS_D))
    ctx.col("MonitorPost", (px + 0.15, 1.20, pz - 0.01), (0.66, 0.80, 0.12))


# ----------------------------------------------------------------------------------------------- PR_UplinkFeedthrough (reuse)

def feedthrough_source():
    """The Tripo export as committed on 27 Oct (never a re-export of this build), staged once from git + LFS."""
    src = STAGE / "source" / f"PR_UplinkFeedthrough_{FEEDTHROUGH_COMMIT}.glb"
    if not src.exists():
        src.parent.mkdir(parents=True, exist_ok=True)
        pointer = subprocess.run(["git", "show", f"{FEEDTHROUGH_COMMIT}:{FEEDTHROUGH_PATH}"], cwd=ROOT, capture_output=True, check=True).stdout
        data = subprocess.run(["git", "lfs", "smudge", "--", FEEDTHROUGH_PATH], cwd=ROOT, input=pointer, capture_output=True, check=True).stdout if pointer.startswith(b"version https://git-lfs") else pointer
        assert data[:4] == b"glTF", "the staged feedthrough is not a GLB"
        src.write_bytes(data)
    return src


def godot_bounds(obj):
    """Axis-aligned bounds of a Blender mesh object in Godot's frame (x, y, z) = (bx, bz, -by)."""
    pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
    g = np.array([(p.x, p.z, -p.y) for p in pts])
    return g.min(axis=0), g.max(axis=0), g


def diagnosed_tag(b, ctx):
    """An orange lockout tag on a steel tie, hanging flat against the plate below the junction box (blank: the
    words are a live Label3D). Pivot at the tie's top on the junction box's lower front edge; the tag hangs toward +z."""
    b.cylinder((0, 0, 0.003), (0, -0.030, 0.003), 0.0012, "M_TieSteel", segs=ctx.seg(6, 4))
    b.torus((0, -0.032, 0.003), (0, 0, 1), 0.004, 0.0009, "M_TieSteel", segs=ctx.seg(10, 6), rings=4)
    b.box((0, -0.075, 0.0035), (0.048, 0.080, 0.002), "M_TagOrange")
    b.box((0, -0.085, 0.0047), (0.038, 0.038, 0.0004), "M_TagWhite")


def build_feedthrough(lod, table):
    """The 27 Oct Tripo feedthrough with a collision box, the hidden DiagnosedTag and, for LOD1, a decimated copy
    with half-size textures. It faces +Z (the Tripo export convention), unlike this set's new -Z pieces."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(feedthrough_source()))
    imported = [o for o in bpy.data.objects if o not in before]
    mesh = next(o for o in imported if o.type == "MESH")
    for o in imported:
        if o is not mesh:
            bpy.data.objects.remove(o)
    mesh.name = "PR_UplinkFeedthrough_Mesh"
    mesh.parent = None
    if lod == 1:
        co = np.array([v.co[:] for v in mesh.data.vertices])
        lo_b, hi_b = co.min(axis=0), co.max(axis=0)
        mod = mesh.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = 0.32
        bpy.context.view_layer.objects.active = mesh
        bpy.ops.object.modifier_apply(modifier=mod.name)
        for v in mesh.data.vertices:  # edge collapse may place a vertex just outside the original hull: keep the bounds
            v.co = Vector(np.clip(np.array(v.co[:]), lo_b, hi_b))
        mat = mesh.data.materials[0].copy()
        mat.name = mesh.data.materials[0].name.split(".")[0] + "_LOD1"   # the second import got a ".001" suffix
        for node in mat.node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image is not None:
                small = node.image.copy()
                small.name = node.image.name.split(".")[0] + "_LOD1"
                small.scale(max(1, node.image.size[0] // 2), max(1, node.image.size[1] // 2))
                small.pack()
                node.image = small
        mesh.data.materials[0] = mat
    lo, hi, pts = godot_bounds(mesh)
    top = pts[pts[:, 1] > lo[1] + 0.85 * (hi[1] - lo[1])]
    plate_front = float(top[:, 2].max())          # the plate's face (the cable hangs toward +Z)
    cx, height = (lo[0] + hi[0]) / 2, hi[1] - lo[1]
    box = pts[(pts[:, 0] > cx + 0.06) & (pts[:, 1] > lo[1] + 0.36 * height) & (pts[:, 1] < lo[1] + 0.72 * height)]
    box_front = float(box[:, 2].max()) if len(box) else plate_front + 0.05   # the navy junction box (viewer's right)
    box_bottom = float(box[:, 1].min()) if len(box) else lo[1] + 0.35 * height
    root = hk.make_empty(f"PR_UplinkFeedthrough_LOD{lod}")
    mesh.parent = root
    objs = [mesh]
    ctx = Ctx(table, lod)
    pivot = (cx + 0.12, box_bottom + 0.004, box_front - 0.004)
    diagnosed_tag(ctx.child("DiagnosedTag", pivot), ctx)
    if lod == 0:
        ctx.col("UplinkFeedthrough", tuple((lo + hi) / 2), tuple(hi - lo))
        ctx.socket("Point_Feedthrough", ((lo[0] + hi[0]) / 2, lo[1] + 0.55 * (hi[1] - lo[1]), float(hi[2])))
        ctx.socket("Point_Tag", pivot)
    extra = materialise(ctx, root, f"PR_UplinkFeedthrough_LOD{lod}", body=False)
    return root, objs + extra, ctx


# ----------------------------------------------------------------------------------------------- assembly and export

def materialise(ctx, root, name, body=True):
    """Turns a Ctx into Blender objects under root (authored in Godot's frame; bake_blender_space converts them)."""
    objs = []
    if body:
        mesh = ctx.body.to_object(name.rsplit("_LOD", 1)[0] + "_Mesh")
        mesh.parent = root
        objs.append(mesh)
    for child, pivot, cb in ctx.children:
        empty = hk.make_empty(child, pivot, root)
        cm = cb.to_object(child + "_Mesh")
        cm.parent = empty
        objs += [empty, cm]
    if ctx.lod == 0:
        for col_name, centre, size in ctx.cols:
            cb = Builder(ctx.table)
            cb.box(centre, size, "PaintGrey")
            co = cb.to_object(col_name)
            co.data.materials.clear()
            co.parent = root
            co.display_type = "WIRE"
            objs.append(co)
        for sock, pos in ctx.sockets:
            objs.append(hk.make_empty(sock, pos, root))
    return objs


def bake(objs, skip=()):
    for o in objs:
        if o in skip:
            continue
        if o.type == "MESH":
            o.data.transform(hk.GODOT_TO_BLENDER)
            o.data.update()
        o.location = hk.GODOT_TO_BLENDER @ o.location


def share_textures(glb_path, lod):
    """Point every kit image at the kit's one shared file (never rewritten); any other image is moved to this asset's
    own textures folder (the relief maps). Images whose names are not files on disk stay embedded (the Tripo set)."""
    glb_path = Path(glb_path)
    doc, binary = _read_glb(glb_path)
    images = doc.get("images", [])
    removed = set()
    kit_dir = KIT / "textures" / ("lod1" if lod else "")
    own_dir = glb_path.parent / "textures" / ("lod1" if lod else "")
    for i, image in enumerate(images):
        if "bufferView" not in image:
            continue
        name = image.get("name", "")
        ext = EXTENSIONS.get(image.get("mimeType", "image/png"), ".png")
        view = doc["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        payload = binary[start: start + view["byteLength"]]
        if name.startswith("T_Kit_"):
            target = kit_dir / (name + ext)
            if not target.exists():
                raise FileNotFoundError(f"{glb_path.name} uses {name}, which the kit does not publish")
        elif name.startswith("T_RouteRelief_"):
            own_dir.mkdir(parents=True, exist_ok=True)
            target = own_dir / (name + ext)
            if not target.exists() or target.read_bytes() != payload:
                target.write_bytes(payload)
        else:
            continue
        removed.add(image["bufferView"])
        images[i] = {"name": name, "mimeType": image.get("mimeType", "image/png"), "uri": os.path.relpath(target, glb_path.parent).replace(os.sep, "/")}
    if not removed:
        return
    keep = [i for i in range(len(doc["bufferViews"])) if i not in removed]
    new_binary, new_views = bytearray(), []
    for i in keep:
        view = dict(doc["bufferViews"][i])
        start = view.pop("byteOffset", 0)
        new_binary += b"\0" * (-len(new_binary) % 4)
        view["byteOffset"] = len(new_binary)
        new_binary += binary[start: start + view["byteLength"]]
        new_views.append(view)
    _remap_buffer_views(doc, keep)
    doc["bufferViews"] = new_views
    if doc.get("buffers"):
        doc["buffers"][0]["byteLength"] = len(new_binary)
    _write_glb(glb_path, doc, new_binary)


def export(root, objs, path, lod):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_animations=False, export_cameras=False, export_lights=False,
                              export_extras=False, export_image_format="AUTO", export_texcoords=True, export_normals=True)
    share_textures(path, lod)


def write_scene_import(glb, embedded):
    """Godot import settings: GLBs that reference shared textures by uri use "extract" (1), as the kit does, so the
    already-imported textures are used as loaded; the Tripo feedthrough keeps its embedded Basis setting (2)."""
    handling = 2 if embedded else 1
    path = glb.with_name(glb.name + ".import")
    if path.exists():
        lines = path.read_text(encoding="utf-8").splitlines()
        lines = [f"gltf/embedded_image_handling={handling}" if l.startswith("gltf/embedded_image_handling=") else l for l in lines]
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    else:
        path.write_text('[remap]\n\nimporter="scene"\nimporter_version=1\ntype="PackedScene"\n\n[deps]\n\n'
                        'source_file="res://' + glb.relative_to(ROOT / "game").as_posix() + '"\n\n[params]\n\n'
                        + hk.SCENE_IMPORT_PARAMS.replace("gltf/embedded_image_handling=1", f"gltf/embedded_image_handling={handling}"), encoding="utf-8")


def write_texture_imports(folder):
    """VRAM-compressed, mipmapped import settings for the relief maps (the kit's own rule, hk.write_texture_imports)."""
    for png in sorted(folder.rglob("*.png")):
        import_file = png.with_name(png.name + ".import")
        uid = ""
        if import_file.exists():
            uid = next((l + "\n" for l in import_file.read_text(encoding="utf-8").splitlines() if l.startswith("uid=")), "")
        kind = "normal" if "_Normal" in png.stem else "orm" if "_ORM" in png.stem else "color"
        import_file.write_text(
            '[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n' + uid +
            '\n[deps]\n\nsource_file="res://' + png.relative_to(ROOT / "game").as_posix() + '"\n\n[params]\n\n'
            'compress/mode=2\ncompress/high_quality=false\ncompress/lossy_quality=0.7\ncompress/uastc_level=0\n'
            'compress/rdo_quality_loss=0.0\ncompress/hdr_compression=1\n'
            f'compress/normal_map={1 if kind == "normal" else 2}\n'
            f'compress/channel_pack={1 if kind != "color" else 0}\n'
            'mipmaps/generate=true\nmipmaps/limit=-1\nroughness/mode=0\nroughness/src_normal=""\n'
            'process/channel_remap/red=0\nprocess/channel_remap/green=1\nprocess/channel_remap/blue=2\nprocess/channel_remap/alpha=3\n'
            'process/fix_alpha_border=true\nprocess/premult_alpha=false\nprocess/normal_map_invert_y=false\n'
            'process/hdr_as_srgb=false\nprocess/hdr_clamp_exposure=false\nprocess/size_limit=0\ndetect_3d/compress_to=1\n',
            encoding="utf-8")


def visual(objs):
    return [o for o in objs if o.type == "MESH" and not o.name.endswith(COL)]


def tris(objs):
    return sum(len(p.vertices) - 2 for o in visual(objs) for p in o.data.polygons)


def godot_size(objs):
    """(min, max) of the visual meshes in Godot's frame, after the bake."""
    bpy.context.view_layer.update()
    pts = [o.matrix_world @ Vector(c) for o in visual(objs) for c in o.bound_box]
    g = [(p.x, p.z, -p.y) for p in pts]
    return Vector([min(q[i] for q in g) for i in range(3)]), Vector([max(q[i] for q in g) for i in range(3)])


# ----------------------------------------------------------------------------------------------- the set

ASSETS = [
    dict(id="PR_ShelterDiagram", folder="props", build=prop_shelter_diagram, flag="--height", size=SD_H, budget=8000, tex=1024,
         mount="wall", mount_y=1.05, lod_m=8.0, scenes=["EX-CH07-S02", "EX-CH07-S05"], front="-Z",
         display="Shelter diagram and five seat markers",
         notes="0.80 x 0.66 m magnetic wall board: the 8 x 6 m Safe Room plan (hatch, water-wall panels, four bundle slots, the central seed latch) with five seat positions (Seat_1..5); five role-colour seat markers SeatMarker_Kai/_Amara/_Mei/_Rafi/_Ferreira park on the steel strip (Park_1..5) until placed; Screen_Roster is the live readiness strip"),
    dict(id="PR_SeedCase", folder="props", build=prop_seed_case, flag="--longest", size=0.35, budget=15000, tex=1024,
         mount="table", mount_y=0.0, lod_m=6.0, scenes=["EX-CH07-S04", "EX-CH07-S05", "EX-CH07-S06", "EX-CH07-S07", "EX-CH07-S10", "EX-CH08-S12"], front="-Z",
         display="Founder-reserve seed case (15 + 15)",
         notes="0.35 x 0.25 x 0.15 m sealed case: two compartments of 15 vials, one seed in each (Well_A_01..15, Well_B_01..15), hinged Lid, draw Latch, CompartmentLid_A/_B with Lamp_SealA/_SealB, Screen_Case sealed-telemetry window, side grips Grip_L/_R; replaces the 27 Oct Tripo case whose vials held many seeds each"),
    dict(id="PR_ValveDiagram", folder="props", build=prop_valve_diagram, flag="--height", size=VD_H, budget=8000, tex=1024,
         mount="wall", mount_y=1.10, lod_m=8.0, scenes=["EX-CH07-S04", "EX-CH07-S08"], front="-Z",
         display="Water-wall valve diagram",
         notes="0.72 x 0.54 m enamel plate beside the water wall: garden reservoir, the six water units (WaterCell_1..6 show W), pump, supply and return valves with Lamp_Supply/_Return, the two-position ReturnSelector (early / after the exposure sample) and Screen_Return for the two return times"),
    dict(id="PR_TelemetryDisplay", folder="props", build=prop_telemetry_display, flag="--height", size=TD_H, budget=8000, tex=1024,
         mount="wall", mount_y=1.20, lod_m=10.0, scenes=["EX-CH07-S06", "EX-CH07-S08"], front="-Z",
         display="Safe Room local telemetry displays",
         notes="0.96 x 0.52 m wall unit: Screen_Systems (energy, air, food) and Screen_Garden (garden local telemetry) with the six ledger lamps Lamp_E/_A/_H/_C/_R/_Z between them, keys, speaker and grab handles"),
    dict(id="PR_ArchivePlayer", folder="props", build=prop_archive_player, flag="--longest", size=0.306, budget=5000, tex=1024,
         mount="table", mount_y=0.0, lod_m=6.0, scenes=["EX-CH07-S07"], front="-Z",
         display="Safe Room archive player",
         notes="0.30 x 0.20 x 0.13 m local archive player (no antenna: the last log is stored, not received): speaker grille, Screen_Archive, play/pause/stop keys with raised icons, volume knob, Lamp_Stored, the ArchiveCard and a folding handle"),
    dict(id="PR_UplinkFeedthrough", folder="props", build=None, flag="--height", size=0.60, budget=5300, tex=1024,
         mount="exterior wall", mount_y=1.2, lod_m=10.0, scenes=["EX-CH07-S09", "EX-CH08-S07"], front="+Z",
         display="Damaged external uplink feedthrough (A-43)",
         notes="the 27 Oct Tripo feedthrough (scorched boot, two cables, navy junction box) re-exported with a collision box and the DiagnosedTag lockout tag (hidden until F-EXT is diagnosed); faces +Z like the other Tripo exports"),
    dict(id="PR_NetworkDiagnostic", folder="props", build=prop_network_diagnostic, flag="--height", size=ND_H, budget=8000, tex=1024,
         mount="wall", mount_y=1.00, lod_m=8.0, scenes=["EX-CH07-S05", "EX-CH07-S09", "EX-CH07-S10"], front="-Z",
         display="Local network diagnostic panel",
         notes="0.84 x 0.66 m wall cabinet: mimic of the local network, the external feedthrough and the Earth dish with Lamp_Local/_Feed/_Dish, TestButton_Local/_Dish/_Feed, IsolationKey with Lamp_Isolated, Screen_Diag and the DataCard that carries the saved relay-bypass diagram to S10"),
    dict(id="EN_Fabrication_Bench", folder="fab", build=env_fabrication_bench, flag="--height", size=FB_BOARD_TOP + 0.10, budget=40000, tex=1024,
         mount="floor", mount_y=0.0, lod_m=12.0, scenes=["EX-CH07-S10", "EX-CH07-S11"], front="-Z",
         display="Local fabrication bench",
         notes="1.80 x 0.75 m bench, worktop 0.90 m, tool board to 1.85 m with shelf, bins and task light: controller cradle (Socket_Controller for PR_RelayController), SpareBattery in its cradle, connector tray with Connector_A/_B/_C (round bayonet) and Connector_Wrong (rectangular), echo test unit with Screen_Echo, Checklist clipboard (Screen_Checklist), vise, drawers"),
    dict(id="EN_Fabrication_RouteSimulator", folder="fab", build=None, flag="--height", size=1.61, budget=40000, tex=2048,
         mount="floor", mount_y=0.0, lod_m=12.0, scenes=["EX-CH07-S11"], front="-Z",
         display="Surveyed-route simulator",
         notes="2.00 x 0.82 m table with a relief of the real LOLA corridor from Aurora to the Malapert summit (1:90,000, vertical exaggeration 2), the computed surveyed road inlaid, Aurora's mast and the summit dish markers, three RepeaterPin_1..3 parked at PinPark_1..3, computed Pad_R1..3 and their road-level alternatives, Screen_Route on a tilted monitor"),
]


def out_path(spec, lod):
    if spec["folder"] == "props":
        return PROPS / spec["id"] / (spec["id"] + (".glb" if lod == 0 else "_LOD1.glb"))
    return FAB / f"{spec['id']}_LOD{lod}.glb"


def res_path(path):
    return "res://" + path.relative_to(ROOT / "game").as_posix()


LAMP_STATES = {"off": [0.20, 0.21, 0.22, 0.0], "idle": [0.55, 0.58, 0.62, 0.4], "pass": [0.20, 1.00, 0.35, 1.2],
               "fail": [1.00, 0.16, 0.10, 1.4], "warn": [1.00, 0.62, 0.10, 1.0], "on": [0.85, 0.95, 1.00, 1.0]}


def states_for(spec_id, ctx, data):
    """The runtime contract per asset: which node or material changes for which state (read by chapter7_assets.gd)."""
    if spec_id == "PR_ShelterDiagram":
        return dict(markers=[f"SeatMarker_{r}" for r, _ in ROLES], roles=[r for r, _ in ROLES], role_colours={r: c for r, c in ROLES},
                    seats=[f"Seat_{k + 1}" for k in range(5)], parking=[f"Park_{k + 1}" for k in range(5)],
                    marker_offset_m=[0, 0, 0], label_offset_m=[0, 0.032, -0.012], screen="Screen_Roster",
                    rule="a marker on a seat is a position, not proof: the roster gate still needs the name and the answer (EX-CH07-S05)")
    if spec_id == "PR_SeedCase":
        return dict(lid=dict(node="Lid", axis="x", open_deg=105.0), latch=dict(node="Latch", axis="x", released_deg=-120.0),
                    compartments={c: dict(node=f"CompartmentLid_{c}", axis="x", open_deg=100.0, lamp=f"Lamp_Seal{c}",
                                          wells=[f"Well_{c}_{k + 1:02d}" for k in range(SEEDS_PER_COMPARTMENT)]) for c in "AB"},
                    seeds_per_compartment=SEEDS_PER_COMPARTMENT, founder_total=2 * SEEDS_PER_COMPARTMENT, seed_material="M_Seed",
                    seed_triangles_lod0=64, grips=["Grip_L", "Grip_R"], screen="Screen_Case",
                    rule="the case stays latched during exposure; its seal lamps and Screen_Case are the safe check (EX-CH07-S06)")
    if spec_id == "PR_ValveDiagram":
        return dict(water_cells=[f"WaterCell_{k + 1}" for k in range(WATER_UNITS)], water_units_cap=WATER_UNITS,
                    selector=dict(node="ReturnSelector", axis="z", early_deg=-35.0, after_deg=35.0),
                    valves=dict(supply=dict(lamp="Lamp_Supply", point="Point_Supply"), ret=dict(lamp="Lamp_Return", point="Point_Return")),
                    screen="Screen_Return", witness_w=[4, 4, 4, 4, 4, 2],
                    rule="W = units in the wall (P-13 witness W4 through step 5, W2 after the step-6 sample); garden water = 6 - W")
    if spec_id == "PR_TelemetryDisplay":
        return dict(screens=["Screen_Systems", "Screen_Garden"], ledger_lamps={k: f"Lamp_{k}" for k in LEDGER},
                    ledger_letters="08 P-02: E energy, A air, H plant health, C edible-crop condition, R crew-day rations, Z game exposure")
    if spec_id == "PR_ArchivePlayer":
        return dict(screen="Screen_Archive", lamp="Lamp_Stored", card=dict(node="ArchiveCard", axis="y", eject_m=0.03),
                    keys=["Key_Play", "Key_Pause", "Key_Stop"], speaker="Speaker",
                    rule="a stored local recording: it never proves the Earth link is open (EX-CH07-S07)")
    if spec_id == "PR_UplinkFeedthrough":
        return dict(tag=dict(node="DiagnosedTag", visible_when="diagnosed"), states=["failed", "diagnosed"],
                    rule="the authored storm damage (P-14 F-EXT), never a penalty; no direct repair in the finale (A-43)")
    if spec_id == "PR_NetworkDiagnostic":
        return dict(branches={b: dict(button=f"TestButton_{b}", lamp=f"Lamp_{b}", press_m=0.004) for b in ("Local", "Dish", "Feed")},
                    expected_after_storm=dict(Local="pass", Dish="fail", Feed="fail"),
                    isolation=dict(node="IsolationKey", axis="z", isolated_deg=90.0, lamp="Lamp_Isolated"),
                    data_card=dict(node="DataCard", axis="z", pull_m=-0.05, carries="saved relay-bypass diagram (doc 24 join CH07 S09 -> S10)"),
                    screen="Screen_Diag")
    if spec_id == "EN_Fabrication_Bench":
        return dict(battery=dict(node="SpareBattery", socket="Socket_Battery", lamp="Lamp_Battery"),
                    connectors={"Connector_A": True, "Connector_B": True, "Connector_C": True, "Connector_Wrong": False},
                    controller_socket="Socket_Controller", controller_asset="PR_RelayController", checklist=dict(node="Checklist", screen="Screen_Checklist"),
                    echo=dict(screen="Screen_Echo", lamp="Lamp_Echo"),
                    rule="a bench pass is not field verification (EX-CH07-S11-L04): the echo test records a bench result only")
    if spec_id == "EN_Fabrication_RouteSimulator":
        return dict(pins=[f"RepeaterPin_{k + 1}" for k in range(3)], parking=[f"PinPark_{k + 1}" for k in range(3)],
                    pads=[f"Pad_R{k + 1}" for k in range(3)], road_level_pads=[f"Pad_R{k + 1}_Road" for k in range(3)], screen="Screen_Route")
    return {}


def route_catalogue(data, relief):
    """The simulator's science block: transform, road, sites, pads, hop table, blocked lines, the direct-line finding."""
    road = data["road"]
    road_table = []
    for p in road[::2]:
        X, _, Z = relief.map_to_table(p[0], p[1], p[2])
        road_table.append([round(X, 4), round(relief.mesh_height(0, X, Z), 4), round(Z, 4), round(p[3], 0)])
    pads = []
    for k, c in enumerate(data["pads"]):
        X, _, Z = relief.map_to_table(c["x"], c["y"], c["h"])
        rp = road[c["road_index"]]
        RX, _, RZ = relief.map_to_table(rp[0], rp[1], rp[2])
        pads.append(dict(id=f"R{k + 1}", socket=f"Pad_R{k + 1}", map_xy_m=[float(c["x"]), float(c["y"])], height_m=round(float(c["h"]), 1), road_km=round(float(c["road_m"]) / 1000, 1),
                         offset_from_road_m=float(c["offset_m"]), table=[round(X, 4), round(relief.mesh_height(0, X, Z), 4), round(Z, 4)],
                         road_level=dict(socket=f"Pad_R{k + 1}_Road", map_xy_m=[rp[0], rp[1]], height_m=rp[2],
                                         table=[round(RX, 4), round(relief.mesh_height(0, RX, RZ), 4), round(RZ, 4)])))
    ax, _, az = relief.map_to_table(data["aurora"][0], data["aurora"][1], 0)
    sx, _, sz = relief.map_to_table(data["summit"][0], data["summit"][1], 0)
    return dict(
        source="NASA LRO LOLA, PGDA product 90 (LDEM_80S_80MPP_ADJ, 80 m/px) via game/assets/environment/terrain/lola/relay_road (M1-34); road = routes.relay_road (make_terrain.py)",
        credit_line=data["credit"], credit_line_short=data["credit_short"],
        scale=f"1:{round(1 / rsd.SCALE):,}", table_m_per_map_m=rsd.SCALE, vertical_exaggeration=rsd.VERTICAL_EXAGGERATION,
        region_map_x_m=list(rsd.REGION_X_M), region_map_y_m=list(rsd.REGION_Y_M), height_floor_m=relief.h_floor,
        relief_size_m=[round(relief.lx, 4), round(relief.lz, 4)], relief_base_y=round(relief.y0 + RS_BASE, 4), relief_centre_z=RS_RELIEF_CENTRE_Z,
        transform="table X = -(map y - yc) * scale; table Z = zc - (map x - xc) * scale; table Y = relief_base_y + (h - height_floor_m) * scale * VE (xc, yc = region centres, zc = relief_centre_z)",
        masts_m=rsd.MAST_M, moon_radius_m=rsd.MOON_RADIUS_M, los_method="true-scale chord over bilinear LOLA heights every 40 m with the sagitta s(d - s)/2R subtracted; 500 m at each end ignored",
        sites=dict(Aurora=dict(socket="Site_Aurora", map_xy_m=list(data["aurora"]), table=[round(ax, 4), round(relief.mesh_height(0, ax, az), 4), round(az, 4)]),
                   Summit=dict(socket="Site_Summit", map_xy_m=list(data["summit"]), table=[round(sx, 4), round(relief.mesh_height(0, sx, sz), 4), round(sz, 4)])),
        road_length_km=round(data["road_length_m"] / 1000, 1), road_table=road_table,
        road_note="the computed road is 198 km on the 80 m grid; the game's travel numbers stay 120 km each way (08 P-15, M1-34 decision)",
        pads=pads, hops=data["hops"], road_level_alternatives=data["road_level_alternatives"], blocked_examples=data["blocked_examples"],
        direct_aurora_summit=dict(data["direct"], note="FINDING for the science reviewer: on the 80 m LOLA grid Aurora's ridge-top mast and the summit relay see each other directly; STORY_FULL EX-CH07-S11 says the base is 'hidden by terrain'. Not changed here (canon is Sadman's); the repeaters still matter for the rover on the road: two of the three pads are blocked when moved down to the road."))


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    (STAGE / "preview").mkdir(parents=True, exist_ok=True)
    data = rsd.compute()
    relief = Relief(data)
    relief_maps = relief.build_maps()
    images = load_kit_images()
    mats = chapter7_materials(images, relief_maps)
    rows, catalogue, built = [], [], {}
    for spec in ASSETS:
        if ONLY and spec["id"] not in ONLY:
            continue
        entry = dict(id=spec["id"], display=spec["display"], notes=spec["notes"], scenes=spec["scenes"], front=spec["front"],
                     mount=spec["mount"], mount_y=spec["mount_y"], lods=[], triangles=[], lod_distance_m=spec["lod_m"], collision=True)
        for lod in (0, 1):
            table = mats[lod]
            if spec["id"] == "PR_UplinkFeedthrough":
                root, objs, ctx = build_feedthrough(lod, table)
                skip = {o for o in objs if o.name == "PR_UplinkFeedthrough_Mesh"}
            else:
                ctx = Ctx(table, lod)
                if spec["id"] == "EN_Fabrication_RouteSimulator":
                    env_route_simulator(ctx, relief, data)
                else:
                    spec["build"](ctx)
                root = hk.make_empty(f"{spec['id']}_LOD{lod}")
                objs = materialise(ctx, root, f"{spec['id']}_LOD{lod}")
                skip = set()
            bake(objs, skip)
            lo, hi = godot_size(objs)
            n_tris = tris(objs)
            measured = (hi.y - lo.y) if spec["flag"] == "--height" else max(hi - lo)
            print(f"CH07 {spec['id']} LOD{lod}: {n_tris} tris, size {[round(v, 3) for v in (hi - lo)]}, min y {lo.y:.4f}")
            assert abs(lo.y) < 0.005, f"{spec['id']} LOD{lod} lowest point {lo.y:.4f} is not on the floor"
            assert abs(measured - spec["size"]) <= 0.015 * spec["size"], f"{spec['id']} LOD{lod} measures {measured:.3f}, spec {spec['size']}"
            assert n_tris <= spec["budget"], f"{spec['id']} LOD{lod} has {n_tris} triangles, over its {spec['budget']} budget"
            if lod == 1:
                assert n_tris <= entry["triangles"][0], f"{spec['id']} LOD1 is heavier than LOD0"
            path = out_path(spec, lod)
            if not ONLY:
                export(root, objs, path, lod)
                write_scene_import(path, embedded=spec["id"] == "PR_UplinkFeedthrough")
            source = {"PR_UplinkFeedthrough": "concept/props/uplink_feedthrough/uplink_feedthrough_v1.png (Tripo, 27 Oct) re-exported by tools/build_chapter7_assets.py",
                      "PR_SeedCase": "concept/props/seed_case/seed_case_v1.png (the approved case design) rebuilt procedurally by tools/build_chapter7_assets.py with exactly 15 + 15 seeds"}.get(spec["id"], SOURCE)
            rows.append(dict(name=path.stem, concept_or_source=source,
                             size_flag=spec["flag"], size_m=round(spec["size"], 4), tris=spec["budget"], tex=spec["tex"] if lod == 0 else spec["tex"] // 2,
                             game_path=path.relative_to(ROOT).as_posix(), art_status="procedural_m3-7a" if spec["id"] != "PR_UplinkFeedthrough" else "approved_concept_tripo",
                             notes=f"{TASK} {spec['display']}; " + ("game LOD with collision" if lod == 0 else "Compatibility LOD, no collision")))
            entry["lods"].append(res_path(path))
            entry["triangles"].append(n_tris)
            if lod == 0:
                entry["size_m"] = [round(v, 3) for v in (hi - lo)]
                entry["bounds_min_m"] = [round(v, 3) for v in lo]
                entry["sockets"] = {name: list(pos) for name, pos in ctx.sockets}
                entry["moving_parts"] = {name: [round(v, 4) for v in pivot] for name, pivot, _ in ctx.children}
                used = set()
                for bb in [ctx.body] + [cb for _, _, cb in ctx.children]:
                    used |= {bb.keys[m] for m in bb.mats}
                entry["screens"] = sorted(k for k in used if k.startswith("Screen"))
                entry["lamps"] = sorted(k for k in used if k.startswith("Lamp_"))
                entry["states"] = states_for(spec["id"], ctx, data)
            built[(spec["id"], lod)] = (root, objs, ctx)
            if not ONLY:
                for o in [root] + objs:
                    o.name = o.name + f".built{lod}"
        catalogue.append(entry)
    if not ONLY:
        write_texture_imports(FAB / "textures")
        with (ROOT / "production/manifest/chapter7_assets.csv").open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
        (PROPS / "chapter7_assets.json").write_text(json.dumps(dict(
            task=TASK, seed=SEED, about="Chapter 7 (The Great Storm) shelter and uplink props and EN_Fabrication; built by production/tools/build_chapter7_assets.py; read by chapter7_assets.gd",
            conventions=dict(units="metres", up="+Y", front="each asset's 'front': -Z for the procedural pieces (the habitat kit convention: a wall plate shares its kit wall's transform), +Z for the Tripo feedthrough",
                             pivot="base centre (lowest point y = 0); wall pieces: back face on z = 0, mounted at mount_y; moving parts on their own child pivots",
                             lods="<id>.glb (props) or <id>_LOD0.glb (EN_Fabrication) is the game LOD with collision; *_LOD1.glb is the Compatibility LOD (fewer segments, 512 px kit textures, no collision)",
                             textures="kit PBR sets referenced by uri from game/assets/environment/kit/textures (stored once); the relief's own maps in EN_Fabrication/textures",
                             text="no text on any surface: every word is a Screen_* slot or a Label3D the room adds; no logos",
                             lamp_states=LAMP_STATES),
            assets=catalogue, route_simulator=route_catalogue(data, relief)), indent=1), encoding="utf-8")
    if RENDER:
        render_previews(built)
    print(f"CHAPTER7_BUILD_PASS: {len(catalogue)} assets, {len(rows)} GLBs")


# ----------------------------------------------------------------------------------------------- previews

def frame(camera, centre, extent, direction, path, res=(720, 720)):
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = res
    camera.location = Vector(centre) + Vector(direction).normalized() * (extent * 4 + 3)
    camera.rotation_euler = (Vector(centre) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.ortho_scale = extent
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    scene.render.resolution_x = scene.render.resolution_y = 720


def godot_to_blender(p):
    return hk.GODOT_TO_BLENDER @ Vector(p)


def render_previews(built):
    camera, rig = hk.setup_render()
    bpy.context.scene.cycles.samples = 64
    preview = STAGE / "preview"
    hk.set_visible(bpy.context.scene.objects, False)
    hk.set_visible(rig, True)
    for spec in ASSETS:
        for lod in (0, 1):
            if (spec["id"], lod) not in built:
                continue
            root, objs, ctx = built[(spec["id"], lod)]
            shown = [o for o in objs if not o.name.split(".built")[0].endswith(COL)]
            hk.set_visible([root] + shown, True)
            front = (0.7, -1.0, 0.55) if spec["front"] == "+Z" else (0.7, 1.0, 0.55)
            pad = 1.12 if spec["folder"] == "fab" else 1.25
            hk.render_piece(camera, shown, preview / f"{spec['id']}_LOD{lod}.png", front, pad)
            if lod == 0:
                extra_views(spec, camera, root, shown, ctx, preview)
            hk.set_visible([root] + objs, False)


def child_obj(objs, name):
    return next(o for o in objs if o.type == "EMPTY" and o.name.split(".built")[0] == name)


def extra_views(spec, camera, root, shown, ctx, preview):
    sid = spec["id"]
    lo, hi = hk.bounds(shown)
    centre, extent = (lo + hi) / 2, max(hi - lo)
    if spec["mount"] in ("wall",):
        frame(camera, centre, extent * 1.08, (0.0, 1.0, 0.04), preview / f"{sid}_front.png")
    if sid == "PR_ShelterDiagram":
        socks = dict(ctx.sockets)
        for k, (role, _) in enumerate(ROLES):
            child_obj(shown, f"SeatMarker_{role}").location = godot_to_blender(socks[f"Seat_{k + 1}"])
        frame(camera, centre, extent * 1.08, (0.0, 1.0, 0.04), preview / f"{sid}_placed.png")
        for k, (role, _) in enumerate(ROLES):
            child_obj(shown, f"SeatMarker_{role}").location = godot_to_blender(socks[f"Park_{k + 1}"])
    if sid == "PR_SeedCase":
        lid, latch = child_obj(shown, "Lid"), child_obj(shown, "Latch")
        lid.rotation_euler.x = math.radians(105)
        latch.rotation_euler.x = math.radians(-120)
        for c in "AB":
            child_obj(shown, f"CompartmentLid_{c}").rotation_euler.x = math.radians(100)
        frame(camera, centre, extent * 1.35, (0.45, 1.0, 1.1), preview / f"{sid}_open.png")
        frame(camera, godot_to_blender((-0.073, 0.09, 0.0)), 0.25, (0.0, 0.18, 1.0), preview / f"{sid}_compartment_top.png")
        frame(camera, godot_to_blender((-0.073, 0.074, -0.07)), 0.075, (0.15, 0.45, 1.0), preview / f"{sid}_seed_macro.png")
        lid.rotation_euler.x = latch.rotation_euler.x = 0.0
        for c in "AB":
            child_obj(shown, f"CompartmentLid_{c}").rotation_euler.x = 0.0
    if sid == "EN_Fabrication_Bench":
        frame(camera, godot_to_blender((-0.25, 0.98, -0.05)), 0.95, (0.35, 1.0, 0.9), preview / f"{sid}_worktop.png")
    if sid == "EN_Fabrication_RouteSimulator":
        socks = dict(ctx.sockets)
        pins = [child_obj(shown, f"RepeaterPin_{k + 1}") for k in range(3)]
        for k, pin in enumerate(pins):
            pin.location = godot_to_blender(socks[f"Pad_R{k + 1}"])
        frame(camera, godot_to_blender((0.0, 0.95, 0.02)), 1.82, (0.0, 0.02, 1.0), preview / f"{sid}_top.png", res=(1440, 520))
        frame(camera, godot_to_blender((0.25, 0.95, 0.02)), 0.95, (0.5, 1.0, 0.75), preview / f"{sid}_relief.png", res=(1080, 720))
        for k, pin in enumerate(pins):
            pin.location = godot_to_blender(socks[f"PinPark_{k + 1}"])


if __name__ == "__main__":
    main()
