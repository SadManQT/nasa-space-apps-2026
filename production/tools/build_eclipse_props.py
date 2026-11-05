"""Build the Chapter 6 eclipse power props (board M3-6A) with Blender alone: no generation service, no credits.

    python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 \
        --python production/tools/build_eclipse_props.py [-- --no-render | --only ID,ID]

--only renders the previews of the listed props without touching the published files.

The props of PRODUCTION_HANDBOOK.md section 8.4, CH06 (EX-CH06-S01..S12, puzzles P-11 and P-12 in
game-design/08_PUZZLE_DESIGNS.md): the eclipse allocation board with its five segment cards and service tags, the
guide-light branch and its run, a decorative flood, the protected-bus test panel with camera feeder F2 (A-42), the
filtered remote camera and the monitor whose live screen carries the labelled Earth-limb inset. They are hard-surface
equipment that has to snap to the habitat kit, carry named moving parts, lamps, live screens and label sockets, so
they are authored procedurally like the kit (build_habitat_kit.py, M1-05) and share its photoreal PBR sets: every GLB
points at the kit's textures (game/assets/environment/kit/textures/) instead of storing its own copy.

Output (deterministic):
  game/assets/props/eclipse_power/<Prop>_LOD0.glb   visual mesh, Godot collision nodes (-convcolonly), named parts,
                                                    lamps, screens, label and socket nodes
  game/assets/props/eclipse_power/<Prop>_LOD1.glb   Compatibility LOD: fewer segments, no small detail, 512 px
                                                    kit textures, no collision; keeps every part, lamp and screen
  game/assets/props/eclipse_power/eclipse_props.json  generated catalogue: LODs, triangles, size, anchor, mount
                                                    height, parts (pivot, axis, positions), lamps, screens, labels,
                                                    sockets. Text, variants and state presets are authored separately
                                                    in eclipse_props_content.json (no rebuild needed to change words).
  production/manifest/eclipse_props.csv             gate specs for production/tools/verify_gate.py
  production/models/eclipse_props/preview/*.png     Cycles previews for production/tools/eclipse_props_contact.py

Conventions (metres, +Y up, Godot -Z forward; authored in that frame, axis swap baked like the kit):
  * the viewer stands on the -Z side, so the viewer's right is world -X: layouts are written in viewer
    coordinates u (right) and converted with x = -u;
  * anchor "wall": the back plane is z = 0 and the body extends towards -Z; the lowest point is y = 0 and the
    catalogue's mount_y lifts it to its working height on a kit wall (place it at the wall's grid position);
  * anchor "floor": stands on y = 0; a floor cabinet also has its back on z = 0 so it sits flush with a kit wall;
  * anchor "loose": a hand-held card or tag, base centre at the origin, back on z = 0 (sits in a board socket);
  * moving parts are child nodes on their own pivots; lamps are mesh nodes "Lamp_<id>", live screens are mesh nodes
    "Screen_<id>" with a material named Screen*, labels are empty nodes "Label_<id>" 0.5 mm in front of a blank plate
    (the runtime puts a Label3D there), sockets are empty nodes "Socket_<id>";
  * no text, numbers or logos on any surface.
"""
import csv
import json
import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_habitat_kit as kit  # noqa: E402  (Builder, PBR material and render helpers; nothing runs on import)
from glb_external_textures import _read_glb, _remap_buffer_views, _write_glb  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/props/eclipse_power"
KIT_TEX = ROOT / "game/assets/environment/kit/textures"
STAGE = ROOT / "production/models/eclipse_props"
TASK = "M3-6A"
SOURCE = "tools/build_eclipse_props.py (procedural, M3-6A) on the M1-05 habitat kit materials"
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDER = "--no-render" not in ARGS
ONLY = ARGS[ARGS.index("--only") + 1].split(",") if "--only" in ARGS else []
Z = (0, 0, -1)  # outward normal of a front face

# ----------------------------------------------------------------------------------------------- materials

TEXTURED = ("PaintGrey", "PaintWhite", "PaintNavy", "PaintOrange", "PaintBlue", "PaintDark", "Steel", "Quilt")


def kit_maps(key, lod):
    """The kit's own PNGs for one material key at one LOD, loaded once (Blender shares the image blocks)."""
    suffix = "_LOD1" if lod else ""
    folder = KIT_TEX / "lod1" if lod else KIT_TEX
    shared = "Paint" if key.startswith("Paint") else key
    maps = {}
    for slot, stem, colour in (("base", f"T_Kit_{key}_BaseColor{suffix}", True), ("normal", f"T_Kit_{shared}_Normal{suffix}", False),
                               ("orm", f"T_Kit_{shared}_ORM{suffix}", False)):
        image = bpy.data.images.get(stem)
        if image is None:
            image = bpy.data.images.load(str(folder / (stem + ".png")))
            image.name = stem
            image.colorspace_settings.name = "sRGB" if colour else "Non-Color"
        maps[slot] = image
    maps["tile"] = 0.25 if key == "Steel" else 0.5
    return maps


def make_table(lod):
    """Material table for one LOD: key -> (material, tile metres). Kit names, so a toon pass restyles both alike."""
    suffix = "" if lod == 0 else "_LOD1"
    table = {key: (kit.pbr_material("M_Kit_" + key + suffix, kit_maps(key, lod)), kit_maps(key, lod)["tile"]) for key in TEXTURED}
    table["Lamp"] = (kit.pbr_material("Lamp" + suffix, None, 0.22, (0.11, 0.11, 0.12)), 1.0)
    table["LightLens"] = (kit.pbr_material("LightLens" + suffix, None, 0.45, (0.80, 0.76, 0.68)), 1.0)
    table["Screen"] = (kit.pbr_material("Screen" + suffix, None, 0.12, (0.02, 0.025, 0.03)), 1.0)
    table["Glass"] = (kit.pbr_material("M_Kit_Glass" + suffix, None, 0.05, (0.75, 0.85, 0.95), alpha=0.22), 1.0)
    table["CameraGlass"] = (kit.pbr_material("CameraGlass" + suffix, None, 0.06, (0.012, 0.014, 0.018)), 1.0)
    filter_mat = kit.pbr_material("FilterGlass" + suffix, None, 0.05, (0.62, 0.63, 0.66))
    filter_mat.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 1.0
    table["FilterGlass"] = (filter_mat, 1.0)
    return table


# ----------------------------------------------------------------------------------------------- geometry helpers

def P(u, y, z):
    """Viewer coordinates (u to the viewer's right, seen from -Z) to the authoring frame."""
    return (-u, y, z)


def slab(b, outline, z_front, z_back, key):
    """A filled outline in the XY plane (Godot x, y) between z_front (facing -Z) and z_back, with side walls."""
    n = len(outline)
    front = [(x, y, z_front) for x, y in outline]
    back = [(x, y, z_back) for x, y in outline]
    b.quad(front, key, outward=Z)
    b.quad(back, key, outward=(0, 0, 1))
    cx, cy = sum(p[0] for p in outline) / n, sum(p[1] for p in outline) / n
    for i in range(n):
        j = (i + 1) % n
        mid = ((front[i][0] + front[j][0]) / 2 - cx, (front[i][1] + front[j][1]) / 2 - cy, 0)
        b.quad([front[i], front[j], back[j], back[i]], key, outward=mid)


def rounded(cx, cy, w, h, r, n_arc):
    return [(cx + x, cy + y) for x, y in kit.rounded_rect(w, h, r, n_arc)]


def screws(b, centres, z_front, lod, r=0.0035):
    if lod:
        return
    for c in centres:
        b.cylinder((c[0], c[1], z_front), (c[0], c[1], z_front - 0.002), r, "Steel", segs=6)


def toggle_body(b, u, y, zf, lod):
    """A miniature breaker body (dark case, steel bezel) whose lever is a separate part or added by the caller."""
    b.box(P(u, y, zf - 0.015), (0.05, 0.09, 0.03), "PaintDark")
    b.box(P(u, y, zf - 0.031), (0.022, 0.05, 0.002), "PaintGrey")


def lever_geo(b, origin, lod, length=0.042):
    """A toggle lever standing straight out of the panel (-Z) from origin; the part's rotation tilts it."""
    o = Vector(origin)
    b.cylinder(o, o + Vector((0, 0, -length)), 0.0055, "Steel", segs=10 if lod == 0 else 6)
    b.box(o + Vector((0, 0, -length - 0.006)), (0.016, 0.012, 0.012), "PaintDark")


# ----------------------------------------------------------------------------------------------- build context

class Ctx:
    """One prop at one LOD: a body builder plus named parts, lamps, screens, labels, sockets and collision boxes.
    All positions are in the prop frame; parts are re-pivoted when the objects are made."""

    def __init__(self, prop_id, lod, table):
        self.id, self.lod, self.table = prop_id, lod, table
        self.body = kit.Builder(table)
        self.parts = {}     # name -> dict(builder, pivot, parent, meta)
        self.lamps = {}     # name -> dict(centre, radius, parent, axis)
        self.screens = {}   # name -> dict(centre, size, parent)
        self.labels = {}    # name -> dict(centre, size, parent)
        self.sockets = {}   # name -> dict(position, parent)
        self.cols = []

    def builder(self, parent):
        return self.body if parent is None else self.parts[parent]["builder"]

    def part(self, name, pivot, axis, positions, rest, parent=None, note=""):
        """A moving child node. axis: rot_x / rot_y / rot_z (degrees) or move_z (metres); positions: named values."""
        self.parts[name] = dict(builder=kit.Builder(self.table), pivot=Vector(pivot), parent=parent,
                                meta=dict(axis=axis, positions=positions, rest=rest, note=note))
        return self.parts[name]["builder"]

    def lamp(self, name, centre, radius, parent=None, height=0.004, bezel=True):
        """Indicator: a lens mesh node Lamp_<name> standing out of a front face, with a steel bezel on the parent."""
        c = Vector(centre)
        self.lamps[name] = dict(centre=c, radius=radius, height=height, parent=parent)
        if bezel:
            self.builder(parent).cylinder(c + Vector((0, 0, 0.0005)), c + Vector((0, 0, -0.002)), radius + 0.004, "Steel", segs=14 if self.lod == 0 else 8)

    def screen(self, name, centre, size, parent=None):
        self.screens[name] = dict(centre=Vector(centre), size=size, parent=parent)

    def label(self, name, centre, size, z_surface, parent=None, key="PaintWhite", depth=0.002):
        """A blank plate mounted on the front face at z_surface (it stands depth proud of it, towards -Z); the
        Label_<name> node sits 0.5 mm in front of the plate."""
        c = Vector((centre[0], centre[1], z_surface - depth / 2))
        self.builder(parent).box(c, (size[0], size[1], depth), key)
        self.labels[name] = dict(centre=Vector((centre[0], centre[1], z_surface - depth - 0.0005)), size=size, parent=parent)

    def socket(self, name, position, parent=None):
        self.sockets[name] = dict(position=Vector(position), parent=parent)

    def collide(self, centre, size):
        self.cols.append((Vector(centre), Vector(size)))

    # --- objects -------------------------------------------------------------------------------------------

    def _pivot(self, parent):
        return Vector((0, 0, 0)) if parent is None else self.parts[parent]["pivot"]

    def finish(self):
        """Makes the Blender objects (authored frame) and returns (root, objects)."""
        root = kit.make_empty(f"{self.id}_LOD{self.lod}")
        objs = []
        body = self.body.to_object(f"{self.id}_Mesh_LOD{self.lod}")
        body.parent = root
        objs.append(body)
        holders = {None: root}
        for name in self.parts:  # parents are declared before their children
            spec = self.parts[name]
            empty = kit.make_empty(name, spec["pivot"] - self._pivot(spec["parent"]), holders[spec["parent"]])
            holders[name] = empty
            objs.append(empty)
            if spec["builder"].faces:
                mesh = spec["builder"].to_object(name + "_Mesh")
                mesh.data.transform(Matrix.Translation(-spec["pivot"]))
                mesh.parent = empty
                objs.append(mesh)
        for name, spec in self.lamps.items():
            b = kit.Builder(self.table)
            c, r, h = spec["centre"], spec["radius"], spec["height"]
            segs = 16 if self.lod == 0 else 8
            b.cylinder(c, c + Vector((0, 0, -h * 0.6)), r, "Lamp", segs=segs, caps=False)
            b.cylinder(c + Vector((0, 0, -h * 0.6)), c + Vector((0, 0, -h)), r, "Lamp", segs=segs, radius1=r * 0.72)
            obj = b.to_object("Lamp_" + name)
            obj.data.transform(Matrix.Translation(-c))
            obj.location = c - self._pivot(spec["parent"])
            obj.parent = holders[spec["parent"]]
            objs.append(obj)
        for name, spec in self.screens.items():
            b = kit.Builder(self.table)
            c, (w, h) = spec["centre"], spec["size"]
            b.quad([(c.x + w / 2, c.y - h / 2, c.z), (c.x - w / 2, c.y - h / 2, c.z), (c.x - w / 2, c.y + h / 2, c.z), (c.x + w / 2, c.y + h / 2, c.z)],
                   "Screen", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=Z)
            obj = b.to_object("Screen_" + name)
            obj.data.transform(Matrix.Translation(-c))
            obj.location = c - self._pivot(spec["parent"])
            obj.parent = holders[spec["parent"]]
            objs.append(obj)
        if self.lod == 0:
            for prefix, table in (("Label_", self.labels), ("Socket_", self.sockets)):
                for name, spec in table.items():
                    pos = spec["centre"] if prefix == "Label_" else spec["position"]
                    objs.append(kit.make_empty(prefix + name, pos - self._pivot(spec["parent"]), holders[spec["parent"]]))
            for k, (c, s) in enumerate(self.cols):
                b = kit.Builder(self.table)
                b.box(c, s, "PaintGrey")
                obj = b.to_object(f"{self.id}_Col{k}-convcolonly")
                obj.data.materials.clear()
                obj.parent = root
                obj.display_type = "WIRE"
                objs.append(obj)
        return root, objs

    def metadata(self):
        """Catalogue facts (prop frame, Godot axes) for the generated eclipse_props.json."""
        r = lambda v: [round(float(a), 4) for a in v]
        return dict(
            parts={n: dict(s["meta"], pivot_m=r(s["pivot"]), parent=s["parent"]) for n, s in self.parts.items()},
            lamps={n: dict(node="Lamp_" + n, centre_m=r(s["centre"]), radius_m=s["radius"], parent=s["parent"]) for n, s in self.lamps.items()},
            screens={n: dict(node="Screen_" + n, centre_m=r(s["centre"]), size_m=list(s["size"]), parent=s["parent"]) for n, s in self.screens.items()},
            labels={n: dict(node="Label_" + n, centre_m=r(s["centre"]), plate_m=list(s["size"]), parent=s["parent"]) for n, s in self.labels.items()},
            sockets={n: dict(node="Socket_" + n, position_m=r(s["position"]), parent=s["parent"]) for n, s in self.sockets.items()})


# ----------------------------------------------------------------------------------------------- props

BOARD_W, BOARD_H = 1.60, 1.00
BOARD_FACE_Z = -0.0515           # front of the white magnetic face
BOARD_COLS = [-0.322 + 0.236 * k for k in range(5)]  # viewer u of the five segment columns, left to right
BOARD_ROWS = [0.58, 0.44, 0.30, 0.16]                  # y of the four service rows, top to bottom
CARD_W, CARD_H, CARD_T = 0.20, 0.13, 0.004
TAG_W, TAG_H, TAG_T = 0.15, 0.075, 0.012
SLOT_Y = 0.672                                          # top of the card ledge


def prop_board(c):
    """EX-CH06-S03/S04: the eclipse allocation board in the power room. Five card slots (precharge..recovery, left to
    right), four service rows (essentials, return pump, camera, decorative floods) with a magnetic tag socket in every
    cell, one warning lamp per segment and a live forecast strip. Wall-mounted, back on z = 0."""
    b, lod = c.body, c.lod
    # mounting rails behind the board and the navy frame
    for y in (0.16, 0.84):
        b.box(P(0, y, -0.0075), (1.50, 0.04, 0.015), "Steel")
    b.box(P(0, 0.5, -0.0325), (BOARD_W, BOARD_H, 0.035), "PaintNavy")
    b.box(P(0, 0.47, -0.0505), (1.52, 0.76, 0.002), "PaintWhite")          # magnetic face u -0.76..0.76
    # grid: raised dark rules between rows and columns
    for y in (0.51, 0.37, 0.23):
        b.box(P(0, y, BOARD_FACE_Z - 0.0015), (1.50, 0.004, 0.003), "PaintDark")
    for u in [BOARD_COLS[0] - 0.118] + [u + 0.118 for u in BOARD_COLS[:-1]]:
        b.box(P(u, 0.37, BOARD_FACE_Z - 0.0015), (0.004, 0.54, 0.003), "PaintDark")
    # header plate, a navy row-header band with its plates, segment columns
    b.box(P(-0.60, 0.37, BOARD_FACE_Z - 0.001), (0.31, 0.56, 0.002), "PaintNavy")
    c.label("Header", P(0, 0.925, 0), (0.86, 0.05), -0.05)
    for k, y in enumerate(BOARD_ROWS):
        c.label(f"Row{k + 1}", P(-0.60, y, 0), (0.27, 0.05), BOARD_FACE_Z - 0.002)
        for s, u in enumerate(BOARD_COLS):
            c.socket(f"Tag_{s + 1}_{k + 1}", P(u, y - TAG_H / 2, BOARD_FACE_Z))
    for s, u in enumerate(BOARD_COLS):
        # card ledge: a steel lip with two side clips; the card stands on it against the face
        b.box(P(u, SLOT_Y - 0.006, BOARD_FACE_Z - 0.006), (0.215, 0.012, 0.012), "PaintGrey")
        b.box(P(u, SLOT_Y + 0.004, BOARD_FACE_Z - 0.0115), (0.215, 0.008, 0.002), "PaintGrey")
        for su in (-1, 1):
            b.box(P(u + su * 0.104, SLOT_Y + 0.03, BOARD_FACE_Z - 0.004), (0.008, 0.06, 0.008), "PaintGrey")
        c.socket(f"Card_{s + 1}", P(u, SLOT_Y, BOARD_FACE_Z))
        c.lamp(f"Seg{s + 1}", P(u + 0.09, SLOT_Y - 0.036, BOARD_FACE_Z - 0.001), 0.007)
        c.label(f"SegState{s + 1}", P(u - 0.02, SLOT_Y - 0.036, 0), (0.15, 0.022), BOARD_FACE_Z, key="PaintGrey")
    # forecast strip along the bottom: a live screen in a steel bezel, with its plate on the left
    b.box(P(0.09, 0.05, -0.0515), (1.06, 0.072, 0.003), "Steel")
    c.screen("Forecast", P(0.09, 0.05, -0.0535), (1.02, 0.056))
    c.label("Forecast", P(-0.62, 0.05, 0), (0.22, 0.04), -0.0505)
    # pen rail and end caps for a finished edge (LOD0)
    if lod == 0:
        for su in (-1, 1):
            b.box(P(su * 0.795, 0.5, -0.0325), (0.012, 0.98, 0.037), "PaintDark")
        screws(b, [P(su * 0.76, y, 0) for su in (-1, 1) for y in (0.06, 0.94)], -0.05, lod)
    c.collide(P(0, 0.5, -0.03), (BOARD_W, BOARD_H, 0.06))


def prop_segment_card(c):
    """EX-CH06-S03: one of the five rigid segment cards (precharge, ingress, totality, egress, recovery). Its top band
    is a separate node the runtime tints per segment; the name goes on the blank face as a Label3D. Back on z = 0."""
    b, lod = c.body, c.lod
    n_arc = 4 if lod == 0 else 1
    slab(b, rounded(0, CARD_H / 2, CARD_W, CARD_H, 0.008, n_arc), -CARD_T, 0.0, "PaintWhite")
    band = c.part("Band", (0, CARD_H - 0.016, -CARD_T), "none", {}, None, note="tinted per segment by the runtime")
    band.box((0, CARD_H - 0.016, -CARD_T - 0.0004), (CARD_W - 0.016, 0.022, 0.0008), "PaintWhite")
    c.label("Name", (0, 0.052, 0), (CARD_W - 0.024, 0.07), -CARD_T, depth=0.0006)
    if lod == 0:
        for x in (-0.06, 0.06):
            b.cylinder((x, CARD_H / 2, 0.0), (x, CARD_H / 2, 0.0015), 0.008, "Steel", segs=10)
    c.collide((0, CARD_H / 2, -CARD_T / 2), (CARD_W, CARD_H, CARD_T + 0.002))


def prop_service_tag(c):
    """EX-CH06-S03: a magnetic service tag (essentials package, return pump, camera, decorative floods) for one cell of
    the board. A side stripe node is tinted per service; the name is a Label3D. Back on z = 0."""
    b, lod = c.body, c.lod
    n_arc = 4 if lod == 0 else 1
    slab(b, rounded(0, TAG_H / 2, TAG_W, TAG_H, 0.006, n_arc), -TAG_T, 0.0, "PaintWhite")
    band = c.part("Band", P(-TAG_W / 2 + 0.013, TAG_H / 2, -TAG_T), "none", {}, None, note="tinted per service by the runtime")
    band.box(P(-TAG_W / 2 + 0.013, TAG_H / 2, -TAG_T - 0.0004), (0.014, TAG_H - 0.014, 0.0008), "PaintWhite")
    c.label("Name", P(0.012, TAG_H / 2, 0), (TAG_W - 0.042, 0.048), -TAG_T, depth=0.0006)
    if lod == 0:
        b.cylinder((0, TAG_H / 2, 0), (0, TAG_H / 2, 0.0012), 0.012, "Steel", segs=10)
    c.collide((0, TAG_H / 2, -TAG_T / 2), (TAG_W, TAG_H, TAG_T + 0.002))


GUIDE_CH_Y, GUIDE_CH_H, GUIDE_CH_D = 0.07, 0.032, 0.028
GUIDE_RUN_Y = (GUIDE_CH_H + 0.016) / 2       # the run's clips stand on y = 0; mount it 0.046 higher than the branch
GUIDE_MOUNT_Y = 0.36


def guide_channel(c, u0, u1, lod, end_cap=False, cy=GUIDE_CH_Y):
    """Aluminium LED channel along the wall from u0 to u1 (viewer coordinates), centred at height cy, with an amber
    diffuser node."""
    b = c.body
    length = u1 - u0
    um = (u0 + u1) / 2
    b.box(P(um, cy, -GUIDE_CH_D / 2 - 0.004), (length, GUIDE_CH_H, GUIDE_CH_D), "PaintGrey", skip=((0, 0, -1),))
    for sy in (-1, 1):  # front lips either side of the diffuser
        b.box(P(um, cy + sy * (GUIDE_CH_H / 2 - 0.004), -GUIDE_CH_D - 0.005), (length, 0.008, 0.002), "PaintGrey")
    diffuser = c.part("Diffuser", P(um, cy, -GUIDE_CH_D - 0.004), "none", {}, None,
                      note="emissive when the guide light is on")
    diffuser.box(P(um, cy, -GUIDE_CH_D - 0.0035), (length - 0.004, GUIDE_CH_H - 0.016, 0.003), "LightLens")
    n = max(2, round(length / 0.25)) if lod == 0 else 2
    for k in range(n):  # wall clips
        u = u0 + length * (k + 0.5) / n
        b.box(P(u, cy, -0.0025), (0.03, GUIDE_CH_H + 0.016, 0.005), "PaintDark")
    if end_cap:
        cap = c.part("EndCap", P(u1 - 0.006, cy, -GUIDE_CH_D / 2 - 0.004), "none", {}, None, note="hidden when another run continues the line")
        cap.box(P(u1 - 0.006, cy, -GUIDE_CH_D / 2 - 0.004), (0.012, GUIDE_CH_H + 0.004, GUIDE_CH_D + 0.004), "PaintDark")


def prop_guide_branch(c):
    """EX-CH05-S12 to EX-CH06-S11: the branch where the guide light leaves the protected bus. A junction box with its
    status lamp and blank branch label, the conduit that rises into the wall wrapped in Kai's orange marker tape (the
    CH05 -> CH06 bridge), and the first 0.82 m of amber LED channel. Wall-mounted at 0.36 m, 1 m wide on the kit grid."""
    b, lod = c.body, c.lod
    segs = 14 if lod == 0 else 8
    ub = -0.41  # junction box centre (viewer left end)
    b.box(P(ub, 0.10, -0.035), (0.16, 0.20, 0.07), "PaintGrey")
    b.box(P(ub, 0.10, -0.0715), (0.146, 0.186, 0.003), "PaintWhite")   # cover plate
    screws(b, [P(ub + su * 0.064, 0.10 + sy * 0.084, 0) for su in (-1, 1) for sy in (-1, 1)], -0.073, lod)
    c.lamp("Branch", P(ub + 0.045, 0.168, -0.073), 0.008)
    c.label("Branch", P(ub - 0.012, 0.115, 0), (0.12, 0.05), -0.073)
    c.label("BranchState", P(ub + 0.0, 0.05, 0), (0.12, 0.024), -0.073, key="PaintGrey")
    # conduit up out of the box top, elbow into the wall, wrapped in marker tape
    top = Vector(P(ub, 0.20, -0.035))
    b.cylinder(top, top + Vector((0, 0.38, 0)), 0.013, "PaintGrey", segs=segs)
    b.cylinder(top + Vector((0, 0.38, 0)), Vector(P(ub, 0.58, 0.0)), 0.013, "PaintGrey", segs=segs)
    b.box(top + Vector((0, 0.38, 0)), (0.03, 0.03, 0.03), "PaintGrey")                                   # elbow
    b.cylinder(top + Vector((0, 0.008, 0)), top + Vector((0, -0.004, 0)), 0.02, "Steel", segs=segs)   # gland
    tape = c.part("MarkerTape", tuple(top + Vector((0, 0.15, 0))), "none", {}, None, note="Kai's orange marker tape (CH05 -> CH06 bridge)")
    tape.cylinder(top + Vector((0, 0.125, 0)), top + Vector((0, 0.175, 0)), 0.0145, "PaintOrange", segs=segs)
    if lod == 0:  # the loose tail of the tape
        tape.box(top + Vector((0.0, 0.11, -0.016)), (0.016, 0.03, 0.0008), "PaintOrange")
    tape.box(P(ub + 0.11, GUIDE_CH_Y, -0.0185), (0.02, GUIDE_CH_H + 0.004, 0.031), "PaintOrange")
    guide_channel(c, ub + 0.08, 0.5, lod)
    c.socket("RunJoin", P(0.5, 0.0, 0.0))
    c.collide(P(ub, 0.10, -0.035), (0.16, 0.20, 0.07))
    c.collide(P(0.045, GUIDE_CH_Y, -0.018), (0.91, GUIDE_CH_H + 0.016, 0.036))


def prop_guide_run(c):
    """A 1 m continuation of the guide-light channel; chains on the kit grid (EndCap hides when the next run joins)."""
    cy = GUIDE_RUN_Y
    guide_channel(c, -0.5, 0.5, c.lod, end_cap=True, cy=cy)
    c.socket("RunJoin", P(0.5, 0.0, 0.0))
    c.collide(P(0, cy, -0.018), (1.0, GUIDE_CH_H + 0.016, 0.036))


FLOOD_AIM_DEG = -25.0


def prop_flood(c):
    """EX-CH06-S04: a decorative wall flood (the comfortable plan Kai sheds). Wall plate, yoke and a finned LED head
    on a tilt pivot aimed 25 degrees down; the lens is a node the runtime lights, LightSocket carries its spot light."""
    b, lod = c.body, c.lod
    segs = 12 if lod == 0 else 6
    b.box(P(0, 0.09, -0.006), (0.12, 0.18, 0.012), "PaintGrey")
    screws(b, [P(su * 0.04, 0.09 + sy * 0.065, 0) for su in (-1, 1) for sy in (-1, 1)], -0.012, lod)
    b.cylinder(P(0, 0.09, -0.012), P(0, 0.09, -0.07), 0.012, "Steel", segs=segs)
    pivot = P(0, 0.09, -0.115)
    for su in (-1, 1):  # yoke arms either side of the head
        b.box(P(su * 0.139, 0.09, -0.085), (0.008, 0.03, 0.07), "Steel")
    b.box(P(0, 0.09, -0.052), (0.286, 0.03, 0.008), "Steel")
    head = c.part("Head", pivot, "rot_x", {"aim": FLOOD_AIM_DEG, "level": 0.0}, "aim")
    # the head is authored level (lens facing -Z) and exported at its aim tilt so the bounds are true
    head.box(P(0, 0.09, -0.115), (0.26, 0.15, 0.09), "PaintDark")
    for k in range(9 if lod == 0 else 4):  # heat-sink fins on the back face
        u = -0.11 + 0.22 * k / (8 if lod == 0 else 3)
        head.box(P(u, 0.09, -0.066), (0.006, 0.13, 0.012), "PaintDark")
    head.box(P(0, 0.09, -0.1615), (0.236, 0.126, 0.003), "Steel")       # bezel
    for su in (-1, 1):
        head.cylinder(P(su * 0.13, 0.09, -0.115), P(su * 0.135, 0.09, -0.115), 0.016, "Steel", segs=segs)
    lens = c.part("Lens", P(0, 0.09, -0.164), "none", {}, None, parent="Head", note="emissive when the flood is on")
    lens.box(P(0, 0.09, -0.1645), (0.222, 0.112, 0.003), "LightLens")
    c.socket("Light", P(0, 0.09, -0.17), parent="Head")
    c.collide(P(0, 0.09, -0.08), (0.30, 0.18, 0.16))


PANEL_W, PANEL_H, PANEL_D = 0.90, 2.00, 0.45
ZF = -0.461                    # front of the control plates
PROTECTED_U = [-0.33, -0.23, -0.13, -0.03]   # air, heat, grow light, guide light (viewer left)
SHED_U = [0.150, 0.255, 0.360]                # test branch, F2 camera, floods (viewer right)
BOUNDARY_U = 0.075


def prop_panel(c):
    """EX-CH06-S05 and S10, P-12 (A-42): the protected-bus test panel with camera feeder F2. A floor cabinet whose
    mimic diagram shows the protected bus and its seven branches; an orange isolation boundary separates the four
    protected essentials (breakers under a sealed guard) from the sheddable test, F2 camera and flood branches, which
    carry the operable controls: test selector, F2 isolator, F2 breaker, fault lamp, current readout and test button,
    and the flood breaker. Status is text as well as colour (labels and the main screen)."""
    b, lod = c.body, c.lod
    segs = 16 if lod == 0 else 8
    # carcass, plinth, front plates
    b.box(P(0, 0.04, -0.215), (0.86, 0.08, 0.41), "PaintDark")
    b.box(P(0, 1.04, -0.225), (PANEL_W, 1.92, PANEL_D), "PaintWhite", skip=((0, 0, -1),))
    b.box(P(0, 0.52, -0.455), (0.84, 0.84, 0.012), "PaintGrey")                 # lower door
    b.box(P(0, 1.215, -0.455), (0.84, 0.50, 0.012), "PaintNavy")                # control zone
    b.box(P(0, 1.72, -0.455), (0.84, 0.46, 0.012), "PaintNavy")                 # mimic zone
    for y0, y1 in ((0.08, 0.10), (0.94, 0.965), (1.465, 1.49), (1.95, 2.0)):    # white frame rails between zones
        b.box(P(0, (y0 + y1) / 2, -0.4505), (PANEL_W, y1 - y0, 0.003), "PaintWhite")
    for su in (-1, 1):
        b.box(P(su * 0.435, 1.04, -0.4505), (0.03, 1.92, 0.003), "PaintWhite")
    # lower door: louvres, handle, hinges
    b.box(P(0, 0.25, -0.4625), (0.52, 0.16, 0.002), "PaintDark")
    for k in range(6 if lod == 0 else 3):
        b.box(P(0, 0.185 + k * (0.026 if lod == 0 else 0.052), -0.468), (0.50, 0.009, 0.012), "PaintGrey")
    kit.handle(b, P(0.34, 0.62, -0.461), 0.22, lod)
    for y in (0.25, 0.80):
        b.cylinder(P(-0.418, y - 0.04, -0.463), P(-0.418, y + 0.04, -0.463), 0.011, "Steel", segs=segs)
    # mimic: header, bus bar, drops, branch lamps and two-line label plates
    c.label("Header", P(0, 1.915, 0), (0.52, 0.036), ZF)
    b.box(P(0.02, 1.86, ZF - 0.004), (0.76, 0.014, 0.008), "Steel")
    branches = ["Air", "Heat", "Grow", "Guide", "Test", "F2", "Floods"]
    for name, u in zip(branches, PROTECTED_U + SHED_U):
        b.box(P(u, 1.795, ZF - 0.002), (0.007, 0.13, 0.004), "PaintWhite")
        c.lamp(name, P(u, 1.725, ZF), 0.011)
        c.label(name, P(u, 1.668, 0), (0.096, 0.036), ZF)
    c.screen("Main", P(-0.18, 1.56, ZF - 0.002), (0.44, 0.115))
    b.box(P(-0.18, 1.56, ZF - 0.0005), (0.456, 0.131, 0.001), "Steel")
    c.label("Shed", P(0.255, 1.56, 0), (0.30, 0.05), ZF)
    # the isolation boundary: an orange rule down through both zones
    b.box(P(BOUNDARY_U, 1.43, ZF - 0.0025), (0.008, 0.90, 0.005), "PaintOrange")
    # protected essentials: four breakers (levers fixed ON) under a sealed clear guard
    c.label("Protected", P(-0.18, 1.425, 0), (0.36, 0.03), ZF)
    for name, u in zip(branches[:4], PROTECTED_U):
        toggle_body(b, u, 1.26, ZF, lod)
        lever = Vector(P(u, 1.26, ZF - 0.032))
        b.cylinder(lever, lever + Vector((0, 0.027, -0.032)), 0.0055, "Steel", segs=10 if lod == 0 else 6)
        b.box(lever + Vector((0, 0.031, -0.037)), (0.016, 0.012, 0.012), "PaintDark")
        c.label("Breaker" + name, P(u, 1.185, 0), (0.088, 0.03), ZF)
    gu, gy0, gy1, gz = -0.18, 1.145, 1.345, ZF - 0.075
    guard = c.part("ProtectedGuard", P(gu, gy1, ZF - 0.0375), "rot_x", {"closed": 0.0, "open": -100.0}, "closed",
                   note="sealed: the runtime refuses to open it and shows the survival-services warning")
    gw = 0.40
    guard.quad([P(gu - gw / 2, gy0, gz), P(gu + gw / 2, gy0, gz), P(gu + gw / 2, gy1, gz), P(gu - gw / 2, gy1, gz)], "Glass", outward=Z)
    for su in (-1, 1):
        guard.quad([P(gu + su * gw / 2, gy0, gz), P(gu + su * gw / 2, gy1, gz), P(gu + su * gw / 2, gy1, ZF), P(gu + su * gw / 2, gy0, ZF)], "Glass",
                   outward=P(su, 0, 0))
    guard.quad([P(gu - gw / 2, gy0, gz), P(gu + gw / 2, gy0, gz), P(gu + gw / 2, gy0, ZF), P(gu - gw / 2, gy0, ZF)], "Glass", outward=(0, -1, 0))
    for y in (gy0, gy1):
        guard.box(P(gu, y, gz), (gw + 0.008, 0.008, 0.008), "PaintOrange")
    for su in (-1, 1):
        guard.box(P(gu + su * gw / 2, (gy0 + gy1) / 2, gz), (0.008, gy1 - gy0, 0.008), "PaintOrange")
        guard.cylinder(P(gu + su * (gw / 2 - 0.03), gy1, ZF - 0.004), P(gu + su * (gw / 2 - 0.03), gy1, gz), 0.006, "Steel", segs=8)
    # hasp and the seal tag hanging from it
    b.box(P(gu, gy0 - 0.026, ZF - 0.006), (0.03, 0.03, 0.012), "Steel")
    seal = c.part("SealTag", P(gu, gy0 - 0.03, ZF - 0.016), "none", {}, None, note="orange do-not-switch tag on the guard hasp")
    seal.torus(P(gu, gy0 - 0.03, ZF - 0.016), (1, 0, 0), 0.009, 0.0018, "Steel", segs=12 if lod == 0 else 6, rings=4)
    c.label("SealTag", P(gu, gy0 - 0.068, 0), (0.12, 0.05), ZF - 0.019, parent="SealTag", key="PaintOrange", depth=0.001)
    # sheddable branches: header plate and one column per branch
    for name, u, title in zip(("Test", "F2", "Floods"), SHED_U, ("ColTest", "ColF2", "ColFloods")):
        c.label(title, P(u, 1.425, 0), (0.10, 0.03), ZF)
    # test branch: rotary selector (pointer up = connected, a quarter turn clockwise = disconnected)
    tu = SHED_U[0]
    b.cylinder(P(tu, 1.32, ZF), P(tu, 1.32, ZF - 0.004), 0.03, "PaintDark", segs=segs)
    sel = c.part("TestSwitch", P(tu, 1.32, ZF - 0.004), "rot_z", {"connected": 0.0, "disconnected": 90.0}, "connected")
    sel.cylinder(P(tu, 1.32, ZF - 0.004), P(tu, 1.32, ZF - 0.026), 0.019, "PaintDark", segs=segs)
    sel.box(P(tu, 1.333, ZF - 0.027), (0.008, 0.03, 0.003), "PaintWhite")
    c.label("TestSwitch", P(tu, 1.255, 0), (0.096, 0.04), ZF)
    # F2 camera feeder: rotary isolator, breaker, fault lamp, test button, current readout
    fu = SHED_U[1]
    b.cylinder(P(fu, 1.33, ZF), P(fu, 1.33, ZF - 0.006), 0.038, "PaintDark", segs=segs)
    iso = c.part("F2Isolator", P(fu, 1.33, ZF - 0.006), "rot_z", {"connected": 0.0, "isolated": 90.0}, "connected",
                 note="isolate before reset (P-12)")
    iso.cylinder(P(fu, 1.33, ZF - 0.006), P(fu, 1.33, ZF - 0.03), 0.016, "PaintOrange", segs=segs)
    iso.box(P(fu, 1.33, ZF - 0.04), (0.018, 0.078, 0.018), "PaintOrange")
    iso.box(P(fu, 1.362, ZF - 0.0495), (0.006, 0.012, 0.001), "PaintWhite")
    toggle_body(b, fu, 1.205, ZF, lod)
    brk = c.part("F2Breaker", P(fu, 1.205, ZF - 0.032), "rot_x", {"on": 40.0, "tripped": 0.0, "off": -40.0}, "on",
                 note="trips to the middle; reset is off then on, interlocked behind the isolator")
    lever_geo(brk, P(fu, 1.205, ZF - 0.032), lod)
    c.lamp("F2Fault", P(fu - 0.025, 1.115, ZF), 0.012)
    b.cylinder(P(fu + 0.028, 1.115, ZF), P(fu + 0.028, 1.115, ZF - 0.008), 0.014, "Steel", segs=segs)
    btn = c.part("F2TestButton", P(fu + 0.028, 1.115, ZF - 0.008), "move_z", {"released": 0.0, "pressed": 0.004}, "released")
    btn.cylinder(P(fu + 0.028, 1.115, ZF - 0.008), P(fu + 0.028, 1.115, ZF - 0.018), 0.0105, "PaintBlue", segs=segs)
    c.screen("F2Current", P(fu, 1.06, ZF - 0.002), (0.08, 0.03))
    b.box(P(fu, 1.06, ZF - 0.0005), (0.09, 0.04, 0.001), "Steel")
    c.label("F2Controls", P(fu, 1.005, 0), (0.10, 0.03), ZF)
    # floods: breaker only (decorative, sheddable)
    du = SHED_U[2]
    toggle_body(b, du, 1.30, ZF, lod)
    fbk = c.part("FloodBreaker", P(du, 1.30, ZF - 0.032), "rot_x", {"on": 40.0, "off": -40.0}, "off")
    lever_geo(fbk, P(du, 1.30, ZF - 0.032), lod)
    c.label("FloodBreaker", P(du, 1.215, 0), (0.096, 0.04), ZF)
    screws(b, [P(su * 0.405, y, 0) for su in (-1, 1) for y in (0.99, 1.44, 1.515, 1.925)], ZF, lod)
    c.collide(P(0, 1.0, -0.23), (PANEL_W, PANEL_H, 0.46))


CAM_MAST_TOP = 1.50


def prop_camera(c):
    """EX-CH06-S06/S07/S10: the filtered remote camera outside Aurora. Ballast foot on the regolith, mast with the
    feeder F2 junction box and cable, pan unit, tilt yoke and an MLI-wrapped camera whose sun hood carries a hinged
    solar filter. The filter closed over the hood is the protective configuration checked before the image appears."""
    b, lod = c.body, c.lod
    segs = 18 if lod == 0 else 8
    # foot: plate on three pads, gussets
    slab_y = 0.025
    b.box((0, slab_y / 2 + 0.01, 0), (0.46, slab_y, 0.46), "PaintWhite")
    for a in range(3):
        ang = math.radians(90 + 120 * a)
        p = Vector((0.2 * math.cos(ang), 0.0, 0.2 * math.sin(ang)))
        b.cylinder(p, p + Vector((0, 0.012, 0)), 0.045, "Steel", segs=segs)
    b.cylinder((0, 0.035, 0), (0, CAM_MAST_TOP, 0), 0.032, "PaintWhite", segs=segs)
    for y in (0.035, CAM_MAST_TOP - 0.02):  # clamp collars
        b.cylinder((0, y, 0), (0, y + 0.02, 0), 0.038, "Steel", segs=segs)
    if lod == 0:
        for a in range(4):
            ang = math.radians(45 + 90 * a)
            d = Vector((math.cos(ang), 0, math.sin(ang)))
            b.quad([d * 0.03 + Vector((0, 0.035, 0)), d * 0.15 + Vector((0, 0.035, 0)), d * 0.03 + Vector((0, 0.25, 0))], "PaintWhite")
            b.quad([d * 0.03 + Vector((0, 0.035, 0)), d * 0.03 + Vector((0, 0.25, 0)), d * 0.15 + Vector((0, 0.035, 0))], "PaintWhite")
    # junction box on the mast (feeder F2 termination) and the cable to the habitat along the ground
    b.box(P(0, 0.70, -0.075), (0.15, 0.20, 0.09), "PaintWhite")
    b.box(P(0, 0.70, -0.121), (0.13, 0.17, 0.003), "PaintGrey")
    c.lamp("Power", P(0.045, 0.765, -0.1225), 0.007)
    b.cylinder(P(0, 0.60, -0.075), P(0, 0.12, -0.075), 0.01, "PaintDark", segs=8)
    b.cylinder(P(0, 0.12, -0.075), P(0, 0.035, -0.16), 0.01, "PaintDark", segs=8)
    b.cylinder(P(0, 0.035, -0.16), P(0, 0.012, -0.30), 0.01, "PaintDark", segs=8)
    b.cylinder(P(0, 0.012, -0.30), P(0, 0.012, -0.45), 0.01, "PaintDark", segs=8)
    # pan unit
    pan = c.part("Pan", (0, CAM_MAST_TOP, 0), "rot_y", {"home": 0.0}, "home", note="yaw; the runtime aims it at the eclipse")
    pan.cylinder((0, CAM_MAST_TOP, 0), (0, CAM_MAST_TOP + 0.09, 0), 0.065, "PaintWhite", segs=segs)
    pan.cylinder((0, CAM_MAST_TOP + 0.09, 0), (0, CAM_MAST_TOP + 0.10, 0), 0.07, "Steel", segs=segs)
    for su in (-1, 1):
        pan.box(P(su * 0.105, CAM_MAST_TOP + 0.20, 0), (0.016, 0.21, 0.07), "PaintWhite")
    pan.box(P(0, CAM_MAST_TOP + 0.105, 0), (0.226, 0.016, 0.07), "PaintWhite")
    tilt_y = CAM_MAST_TOP + 0.25
    tilt = c.part("Tilt", (0, tilt_y, 0), "rot_x", {"level": 0.0, "up": 12.0}, "level", parent="Pan",
                  note="pitch; elevation of the Earth from Aurora is low")
    for su in (-1, 1):
        tilt.cylinder(P(su * 0.097, tilt_y, 0), P(su * 0.08, tilt_y, 0), 0.022, "Steel", segs=segs)
    # camera body wrapped in MLI, radiator plate on top, lens and sun hood at the front (-Z)
    tilt.box((0, tilt_y, 0.02), (0.15, 0.14, 0.30), "Quilt")
    tilt.box((0, tilt_y + 0.075, 0.03), (0.13, 0.008, 0.22), "PaintWhite")
    tilt.box((0, tilt_y, 0.175), (0.13, 0.12, 0.012), "PaintGrey")
    c.lamp("Status", (0.04, tilt_y + 0.03, 0.182), 0.006, parent="Tilt", height=-0.003, bezel=False)
    tilt.cylinder((0, tilt_y, -0.13), (0, tilt_y, -0.19), 0.05, "PaintDark", segs=segs)
    tilt.cylinder((0, tilt_y, -0.19), (0, tilt_y, -0.192), 0.04, "CameraGlass", segs=segs)
    hz0, hz1, hw = -0.19, -0.27, 0.066  # square sun hood around the lens
    for su in (-1, 1):
        tilt.box(P(su * hw, tilt_y, (hz0 + hz1) / 2), (0.004, 2 * hw, hz0 - hz1), "PaintWhite")
        tilt.box(P(0, tilt_y + su * hw, (hz0 + hz1) / 2), (2 * hw, 0.004, hz0 - hz1), "PaintWhite")
    flap = c.part("Filter", (0, tilt_y + hw, hz1), "rot_x", {"in": 0.0, "out": 115.0}, "in", parent="Tilt",
                  note="solar filter: 'in' is the protective configuration (EX-CH06-S06)")
    flap.box((0, tilt_y, hz1 - 0.004), (2 * hw + 0.012, 2 * hw + 0.012, 0.008), "PaintDark")
    flap.quad([P(hw - 0.006, tilt_y - hw + 0.006, hz1 - 0.0085), P(-hw + 0.006, tilt_y - hw + 0.006, hz1 - 0.0085),
               P(-hw + 0.006, tilt_y + hw - 0.006, hz1 - 0.0085), P(hw - 0.006, tilt_y + hw - 0.006, hz1 - 0.0085)], "FilterGlass", outward=Z)
    flap.cylinder(P(-hw - 0.01, tilt_y + hw, hz1), P(hw + 0.01, tilt_y + hw, hz1), 0.005, "Steel", segs=8)
    c.collide((0, 0.02, 0), (0.46, 0.04, 0.46))
    c.collide((0, 0.8, 0), (0.12, 1.5, 0.12))
    c.collide((0, tilt_y, -0.02), (0.24, 0.24, 0.52))


MON_W, MON_H = 0.62, 0.38
MON_HINGE_Y = 0.25


def prop_monitor(c):
    """EX-CH06-S06..S11: the filtered remote-camera monitor at the mission table. Desk foot, column and a tilting
    16:9 display whose Screen_Main shows the live camera view with the labelled Earth-limb inset
    (monitor/eclipse_monitor_screen.gd). A record lamp and a hold-frame button sit on the bottom bezel."""
    b, lod = c.body, c.lod
    segs = 16 if lod == 0 else 8
    # foot: rounded slab lying flat (built in XZ by swapping axes of a rounded outline)
    pts = kit.rounded_rect(0.28, 0.21, 0.03, 4 if lod == 0 else 1)
    top = [(x, 0.016, y + 0.02) for x, y in pts]
    bot = [(x, 0.0, y + 0.02) for x, y in pts]
    b.quad(top, "PaintDark", outward=(0, 1, 0))
    b.quad(bot, "PaintDark", outward=(0, -1, 0))
    for i in range(len(pts)):
        j = (i + 1) % len(pts)
        mid = ((top[i][0] + top[j][0]) / 2, 0, (top[i][2] + top[j][2]) / 2 - 0.02)
        b.quad([top[i], top[j], bot[j], bot[i]], "PaintDark", outward=mid)
    b.box((0, 0.13, 0.055), (0.06, 0.23, 0.03), "PaintNavy")                         # column
    b.cylinder(P(-0.035, MON_HINGE_Y, 0.04), P(0.035, MON_HINGE_Y, 0.04), 0.016, "Steel", segs=segs)
    disp = c.part("Display", (0, MON_HINGE_Y, 0.04), "rot_x", {"upright": 0.0, "tilted": 8.0}, "upright", note="tilt hinge; tilted faces up")
    dy, dz = MON_HINGE_Y + 0.16, 0.0
    disp.box((0, dy, dz + 0.012), (MON_W, MON_H, 0.024), "PaintNavy")
    disp.box((0, dy, dz + 0.03), (0.30, 0.20, 0.016), "PaintNavy")                   # back housing
    disp.box((0, dy, dz + 0.04), (0.10, 0.10, 0.006), "Steel")                       # mount plate
    disp.box((0, MON_HINGE_Y + 0.02, 0.035), (0.05, 0.06, 0.02), "Steel")
    c.screen("Main", (0, dy + 0.012, dz - 0.0005), (0.576, 0.324), parent="Display")
    c.lamp("Rec", P(0.27, dy - 0.168, dz), 0.0045, parent="Display", height=0.002)
    hold = c.part("HoldButton", P(0.225, dy - 0.168, dz), "move_z", {"released": 0.0, "pressed": 0.002}, "released", parent="Display")
    hold.box(P(0.225, dy - 0.168, dz - 0.002), (0.022, 0.01, 0.004), "PaintDark")
    c.label("Bezel", P(-0.17, dy - 0.168, 0), (0.22, 0.02), dz, parent="Display", key="PaintNavy", depth=0.0008)
    c.collide((0, 0.008, 0.02), (0.28, 0.016, 0.21))
    c.collide((0, dy, 0.02), (MON_W, MON_H, 0.06))


PROPS = [
    dict(id="PR_EclipseBoard", build=prop_board, anchor="wall", mount_y=1.10, flag="--longest", size=BOARD_W, cap=40000, lod_distance_m=12.0,
         display="Eclipse allocation board", scenes=["EX-CH06-S03", "EX-CH06-S04", "EX-CH06-S11"],
         notes="protected-service board: five segment card slots, four service rows, 20 tag sockets, five warning lamps, live forecast strip"),
    dict(id="PR_SegmentCard", build=prop_segment_card, anchor="loose", mount_y=0.0, flag="--longest", size=CARD_W, cap=5000, lod_distance_m=6.0,
         display="Eclipse segment card", scenes=["EX-CH06-S03"], notes="one card, five variants (precharge, ingress, totality, egress, recovery)"),
    dict(id="PR_ServiceTag", build=prop_service_tag, anchor="loose", mount_y=0.0, flag="--longest", size=TAG_W, cap=5000, lod_distance_m=6.0,
         display="Service tag", scenes=["EX-CH06-S03", "EX-CH06-S04"], notes="magnetic tag, four variants (essentials, return pump, camera, decorative floods)"),
    dict(id="PR_GuideLightBranch", build=prop_guide_branch, anchor="wall", mount_y=GUIDE_MOUNT_Y, flag="--longest", size=1.0, cap=5000, lod_distance_m=12.0,
         display="Guide-light branch", scenes=["EX-CH05-S12", "EX-CH06-S02", "EX-CH06-S04", "EX-CH06-S10"],
         notes="junction box, status lamp, branch label, conduit with Kai's marker tape, first 0.82 m of amber channel"),
    dict(id="PR_GuideLightRun", build=prop_guide_run, anchor="wall", mount_y=round(GUIDE_MOUNT_Y + GUIDE_CH_Y - GUIDE_RUN_Y, 3), flag="--longest", size=1.0, cap=5000, lod_distance_m=12.0,
         display="Guide-light run", scenes=["EX-CH06-S04", "EX-CH06-S10"], notes="1 m amber LED channel that chains on the kit grid"),
    dict(id="PR_DecorativeFlood", build=prop_flood, anchor="wall", mount_y=2.0, flag="--longest", size=0.286, cap=5000, lod_distance_m=12.0,
         display="Decorative flood", scenes=["EX-CH06-S03", "EX-CH06-S04"], notes="finned LED wall flood on a tilt yoke, aimed 25 deg down"),
    dict(id="PR_ProtectedBusPanel", build=prop_panel, anchor="floor", mount_y=0.0, flag="--height", size=PANEL_H, cap=40000, lod_distance_m=12.0,
         display="Protected-bus test panel and feeder F2", scenes=["EX-CH06-S02", "EX-CH06-S05", "EX-CH06-S10", "EX-CH06-S11"],
         notes="A-42: mimic diagram, isolation boundary, sealed protected breakers, test selector, F2 isolator/breaker/fault lamp/readout/test button, flood breaker"),
    dict(id="PR_FilteredCamera", build=prop_camera, anchor="floor", mount_y=0.0, flag="--height", size=1.83, cap=40000, lod_distance_m=20.0,
         display="Filtered remote camera", scenes=["EX-CH06-S06", "EX-CH06-S07", "EX-CH06-S10", "EX-CH06-S11"],
         notes="exterior mast camera: pan, tilt, MLI body, sun hood with hinged solar filter, F2 junction box and cable"),
    dict(id="PR_EclipseMonitor", build=prop_monitor, anchor="floor", mount_y=0.0, flag="--height", size=0.60, cap=15000, lod_distance_m=10.0,
         display="Filtered-camera monitor", scenes=["EX-CH06-S06", "EX-CH06-S07", "EX-CH06-S09", "EX-CH06-S10", "EX-CH06-S11"],
         notes="desk display; Screen_Main takes monitor/eclipse_monitor_screen.gd (camera view + labelled Earth-limb inset)"),
]


# ----------------------------------------------------------------------------------------------- export

def bake(objs):
    for o in objs:
        if o.type == "MESH":
            o.data.transform(kit.GODOT_TO_BLENDER)
            o.data.update()
        o.location = kit.GODOT_TO_BLENDER @ o.location


def relink_to_kit(glb_path, lod):
    """Drops the texture bytes the exporter embedded and points every image at the kit's own PNG (relative uri), so
    Godot loads the one imported copy the kit already has. Any image the kit does not have is an error."""
    doc, binary = _read_glb(glb_path)
    folder = KIT_TEX / "lod1" if lod else KIT_TEX
    removed = set()
    for image in doc.get("images", []):
        name = Path(image.get("name", "")).stem
        target = folder / (name + ".png")
        if not target.exists():
            raise RuntimeError(f"{glb_path.name}: image {name} is not a kit texture")
        if "bufferView" in image:
            removed.add(image.pop("bufferView"))
        image["uri"] = os.path.relpath(target, glb_path.parent).replace(os.sep, "/")
        image["mimeType"] = "image/png"
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
    doc["buffers"][0]["byteLength"] = len(new_binary)
    _write_glb(glb_path, doc, new_binary)


def export(root, objs, path, lod):
    bpy.ops.object.select_all(action="DESELECT")
    for o in [root] + objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True, export_apply=True,
                              export_animations=False, export_cameras=False, export_lights=False, export_extras=False,
                              export_image_format="AUTO", export_texcoords=True, export_normals=True)
    relink_to_kit(path, lod)


def write_scene_imports():
    """Same import settings as the kit GLBs: external textures used as already imported (embedded_image_handling=1)."""
    for glb in sorted(OUT.glob("*.glb")):
        import_file = glb.with_name(glb.name + ".import")
        if import_file.exists():
            lines = import_file.read_text(encoding="utf-8").splitlines()
            lines = ["gltf/embedded_image_handling=1" if line.startswith("gltf/embedded_image_handling=") else line for line in lines]
            import_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
        else:
            import_file.write_text('[remap]\n\nimporter="scene"\nimporter_version=1\ntype="PackedScene"\n\n[deps]\n\n'
                                   'source_file="res://' + glb.relative_to(ROOT / "game").as_posix() + '"\n\n[params]\n\n' + kit.SCENE_IMPORT_PARAMS,
                                   encoding="utf-8")


def rename_done(objs, lod):
    """Exported names (parts, lamps, labels) repeat in the next LOD; park this LOD's objects under unique names."""
    for o in objs:
        o.name = o.name + f"~{lod}"


# ----------------------------------------------------------------------------------------------- previews

def render_views(spec, root, objs, lod, states):
    """Three-quarter view (and front view for LOD0) of one prop; states is a list of (suffix, {part: degrees})."""
    camera = bpy.data.objects["PreviewCamera"]
    kit.set_visible(bpy.context.scene.objects, False)
    kit.set_visible([o for o in bpy.context.scene.objects if o.name.startswith("Preview")], True)
    kit.set_visible([root] + objs, True)
    kit.set_visible([o for o in objs if o.name.split("~")[0].endswith(kit.COL_SUFFIXES)], False)
    # Blender is Z-up after the bake: the viewer side (Godot -Z) is Blender +Y
    views = [("34", (-0.75, 1.0, 0.55))] + ([("front", (0.0, 1.0, 0.12))] if lod == 0 else [])
    for tag, direction in views:
        kit.render_piece(camera, objs, STAGE / "preview" / f"{spec['id']}_LOD{lod}_{tag}.png", direction, pad=1.3)
    if lod == 0:
        for suffix, pose in states:
            saved = {}
            for part, (axis, value) in pose.items():
                o = next(o for o in objs if o.name.split("~")[0] == part)
                saved[part] = (o.location.copy(), o.rotation_euler.copy())
                apply_pose(o, axis, value)
            kit.render_piece(camera, objs, STAGE / "preview" / f"{spec['id']}_LOD0_{suffix}.png", (-0.6, 1.0, 0.3), pad=1.3)
            for part, (loc, rot) in saved.items():
                o = next(o for o in objs if o.name.split("~")[0] == part)
                o.location, o.rotation_euler = loc, rot
    kit.set_visible([root] + objs, False)


def apply_pose(o, axis, value):
    """Godot-frame pose on a baked Blender object: Godot x = Blender x, Godot y = Blender z, Godot z = Blender -y."""
    if axis == "rot_x":
        o.rotation_euler.x += math.radians(value)
    elif axis == "rot_y":
        o.rotation_euler.z += math.radians(value)
    elif axis == "rot_z":
        o.rotation_euler.y -= math.radians(value)
    elif axis == "move_z":
        o.location.y -= value


PREVIEW_STATES = {
    "PR_ProtectedBusPanel": [("f2_isolated", {"F2Isolator": ("rot_z", 90.0), "F2Breaker": ("rot_x", -40.0), "TestSwitch": ("rot_z", 90.0)})],
    "PR_FilteredCamera": [("filter_out", {"Filter": ("rot_x", 115.0)})],
}


def setup_preview():
    camera, rig = kit.setup_render()
    for o in rig:
        o.name = "Preview" + o.name
    camera.name = "PreviewCamera"
    bpy.context.scene.cycles.samples = 64
    return camera


# ----------------------------------------------------------------------------------------------- main

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (STAGE / "preview").mkdir(parents=True, exist_ok=True)
    if not ONLY:
        for old in OUT.glob("*.glb"):
            old.unlink()
    if RENDER:
        setup_preview()
    tables = {lod: make_table(lod) for lod in (0, 1)}
    rows, catalogue = [], []
    for spec in PROPS:
        entry = dict(id=spec["id"], display=spec["display"], scenes=spec["scenes"], notes=spec["notes"], anchor=spec["anchor"],
                     mount_y=spec["mount_y"], lod_distance_m=spec["lod_distance_m"], lods=[], triangles=[], collision="LOD0")
        for lod in (0, 1):
            ctx = Ctx(spec["id"], lod, tables[lod])
            spec["build"](ctx)
            root, objs = ctx.finish()
            # pose parts that ship tilted (the flood head) before measuring and exporting
            for o in objs:
                if o.type == "EMPTY" and o.name in ctx.parts:
                    meta = ctx.parts[o.name]["meta"]
                    if meta["rest"] and meta["axis"].startswith("rot_") and meta["positions"].get(meta["rest"]):
                        value = math.radians(meta["positions"][meta["rest"]])
                        o.rotation_euler = {"rot_x": (value, 0, 0), "rot_y": (0, value, 0), "rot_z": (0, 0, value)}[meta["axis"]]
            bpy.context.view_layer.update()
            lo, hi = kit.bounds(objs)
            tris = kit.triangles(objs)
            assert abs(lo.y) < 0.005, f"{spec['id']} LOD{lod} lowest point {lo.y:.4f} is not on y = 0"
            measured = (hi.y - lo.y) if spec["flag"] == "--height" else max(hi - lo)
            assert abs(measured - spec["size"]) <= 0.02 * spec["size"], f"{spec['id']} LOD{lod} measures {measured:.3f}, design {spec['size']}"
            assert tris <= spec["cap"], f"{spec['id']} LOD{lod} has {tris} triangles, over the art bible's {spec['cap']}"
            if spec["anchor"] == "wall" or spec["id"] == "PR_ProtectedBusPanel":
                assert hi.z <= 0.005, f"{spec['id']} LOD{lod} reaches z {hi.z:.3f} behind its back plane"
            if lod == 0:
                entry.update(ctx.metadata())
                entry["size_m"] = [round(v, 3) for v in (hi - lo)]
                entry["bounds_min_m"] = [round(v, 3) for v in lo]
                entry["bounds_max_m"] = [round(v, 3) for v in hi]
            name = f"{spec['id']}_LOD{lod}"
            path = OUT / (name + ".glb")
            bake(objs)
            bpy.context.view_layer.update()
            if not ONLY:
                export(root, objs, path, lod)
                print(f"PROP {name}: {tris} tris, size {[round(v, 3) for v in (hi - lo)]}, {path.stat().st_size // 1024} KB")
            rows.append(dict(name=name, concept_or_source=SOURCE, size_flag=spec["flag"], size_m=round(measured, 3), tris=tris,
                             tex=1024 if lod == 0 else 512, game_path=path.relative_to(ROOT).as_posix(), art_status="procedural_m3-6a",
                             notes=f"{TASK} {spec['display']}; " + ("game LOD with collision" if lod == 0 else "Compatibility LOD, no collision")))
            entry["lods"].append(f"res://assets/props/eclipse_power/{name}.glb")
            entry["triangles"].append(tris)
            rename_done(objs, lod)
            if RENDER and (not ONLY or spec["id"] in ONLY):
                render_views(spec, root, objs, lod, PREVIEW_STATES.get(spec["id"], []))
        catalogue.append(entry)
    if ONLY:
        print(f"ECLIPSE_PROPS_PREVIEWS_PASS: {ONLY}")
        return
    with (ROOT / "production/manifest/eclipse_props.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    write_scene_imports()
    (OUT / "eclipse_props.json").write_text(json.dumps(dict(
        task=TASK, generated_by="production/tools/build_eclipse_props.py", content="res://assets/props/eclipse_power/eclipse_props_content.json",
        conventions=dict(units="metres", up="+Y", front="-Z (Godot forward); the viewer stands on the -Z side, so the viewer's right is -X",
                         anchors=dict(wall="back plane z=0, body towards -Z, lowest point y=0; place at a kit wall's grid position and lift by mount_y",
                                      floor="stands on y=0; a floor cabinet also has its back on z=0 to sit flush with a kit wall",
                                      loose="hand-held card or tag: base centre at the origin, back on z=0; sits in a board socket"),
                         textures="the habitat kit's PBR sets, referenced by uri from game/assets/environment/kit/textures (LOD0 1024 px, LOD1 512 px)",
                         nodes="parts are child nodes on their own pivots; Lamp_<id> lens meshes; Screen_<id> live-UI meshes (material Screen*); "
                               "Label_<id> empties in front of blank plates (LOD0 only); Socket_<id> empties (LOD0 only)"),
        props=catalogue), indent=1), encoding="utf-8")
    print(f"ECLIPSE_PROPS_BUILD_PASS: {len(PROPS)} props, {len(rows)} GLBs")


if __name__ == "__main__":
    main()
