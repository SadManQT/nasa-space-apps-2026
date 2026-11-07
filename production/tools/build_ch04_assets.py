"""Chapter 4 (Into the Cold Trap) environment assets with Blender alone (board M3-4A): EN_Garage and EN_ColdTrap.
No generation service, no credits.

    python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 \
        --python production/tools/build_ch04_assets.py -- <what> [--samples N] [--small]

<what> is any of: pieces (neutral Cycles previews of every new piece), garage (the assembled LOC-08 views),
coldtrap (LOC-09 beacon corners and the LOC-10 vault shelf on the real LOLA terrain), all.
Phase 1 (this run, before Sadman approves the 2D sheets) only renders previews into production/models/ch04/preview/
for production/tools/ch04_sheets.py; phase 2 adds LOD1, collision export, the catalogue json and the gate rows from
the same piece functions, so what is approved is what ships.

Design references: game-design/09_WORLD_AND_LEVEL_DESIGN.md LOC-08 (garage 12 x 9 m, pressure-rated rover bay, cargo
rack, pad camera, route board, supply ledger, suit seals, relief locker), LOC-09 (surveyed approach, three beacons,
dry reference plate, sample points, slope sign, return marker), LOC-10 (20 x 15 m shelf, old marker, insulated box, two
tether anchors, probe socket, carrier tether, archival survey tag); STORY_FULL EX-CH04-S01..S12; doc 24 sections 2.4
and 2.9 (CH04 bridges) and section 4 clues 14-15; the approved M1-05 habitat kit (materials, grid, conventions);
production/models/ch04/coldtrap_survey.json (production/tools/coldtrap_survey.py, Computed from LOLA).

Conventions (as the kit): metres, +Y up, authored in Godot's frame and baked to Blender's; wall modules have the room
face on z = 0 facing -Z; standing pieces face -Z with the pivot at the base centre; moving parts are child empties.
No text on any surface: screens are material slots (Screen, Screen2, Screen3) and labels are blank plates (Label).
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_habitat_kit as hk  # noqa: E402
from build_chapter2_assets import load_kit_images  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "production/models/ch04"
PREVIEW = STAGE / "preview"
LOLA = ROOT / "game/assets/environment/terrain/lola"
SEED = 20261107
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
WHAT = {a for i, a in enumerate(ARGS) if not a.startswith("--") and (i == 0 or ARGS[i - 1] != "--samples")} or {"all"}
SAMPLES = int(ARGS[ARGS.index("--samples") + 1]) if "--samples" in ARGS else 96
SMALL = "--small" in ARGS
WALL_H, WALL_D = hk.WALL_H, hk.WALL_D
Builder = hk.Builder
G2B = hk.GODOT_TO_BLENDER
R_MOON = 1737400.0

# ----------------------------------------------------------------------------------------------- materials

def node_material(name, color, rough=0.6, metal=0.0, emission=None, bump=None, coat=0.0):
    """A plain Principled material for the extra slots; bump = (scale, strength) adds a fine noise relief."""
    mat = bpy.data.materials.new(name)
    t = mat.node_tree
    bsdf = t.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if coat:
        bsdf.inputs["Coat Weight"].default_value = coat
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission[0], 1)
        bsdf.inputs["Emission Strength"].default_value = emission[1]
    if bump:
        noise = t.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = bump[0]
        noise.inputs["Detail"].default_value = 8
        bn = t.nodes.new("ShaderNodeBump")
        bn.inputs["Strength"].default_value = bump[1]
        t.links.new(noise.outputs["Fac"], bn.inputs["Height"])
        t.links.new(bn.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def retro_material(name, color, boost):
    """Retroreflective tape: bright when the light source sits beside the camera (headlights, helmet lamps). Cycles has
    no retroreflective BSDF, so the facing ratio drives a small emission; boost 0 in sunlit shots."""
    mat = node_material(name, color, 0.35)
    t = mat.node_tree
    bsdf = t.nodes["Principled BSDF"]
    lw = t.nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.2
    inv = t.nodes.new("ShaderNodeMath")
    inv.operation = "SUBTRACT"
    inv.inputs[0].default_value = 1.0
    t.links.new(lw.outputs["Facing"], inv.inputs[1])
    mul = t.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = boost
    t.links.new(inv.outputs[0], mul.inputs[0])
    bsdf.inputs["Emission Color"].default_value = (*color, 1)
    t.links.new(mul.outputs[0], bsdf.inputs["Emission Strength"])
    return mat


def mli_material(name, color, scale=9.0):
    """Multi-layer insulation: crinkled metallic foil."""
    mat = node_material(name, color, 0.22, 1.0)
    t = mat.node_tree
    bsdf = t.nodes["Principled BSDF"]
    vor = t.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = scale
    noise = t.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale * 3
    mix = t.nodes.new("ShaderNodeMath")
    mix.operation = "ADD"
    t.links.new(vor.outputs["Distance"], mix.inputs[0])
    t.links.new(noise.outputs["Fac"], mix.inputs[1])
    bn = t.nodes.new("ShaderNodeBump")
    bn.inputs["Strength"].default_value = 0.35
    t.links.new(mix.outputs[0], bn.inputs["Height"])
    t.links.new(bn.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def sintered_material(name):
    """Sintered-regolith pavers (0.5 m), dark grey with fine joints: the bay floor and the plinth."""
    mat = node_material(name, (0.11, 0.105, 0.10), 0.92)
    t = mat.node_tree
    bsdf = t.nodes["Principled BSDF"]
    coord = t.nodes.new("ShaderNodeTexCoord")
    brick = t.nodes.new("ShaderNodeTexBrick")
    brick.offset = 0.0
    brick.inputs["Color1"].default_value = (0.115, 0.11, 0.105, 1)
    brick.inputs["Color2"].default_value = (0.095, 0.092, 0.088, 1)
    brick.inputs["Mortar"].default_value = (0.04, 0.04, 0.04, 1)
    brick.inputs["Scale"].default_value = 1.0
    brick.inputs["Mortar Size"].default_value = 0.006
    brick.inputs["Brick Width"].default_value = 0.5
    brick.inputs["Row Height"].default_value = 0.5
    t.links.new(coord.outputs["Object"], brick.inputs["Vector"])
    noise = t.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 40
    mixc = t.nodes.new("ShaderNodeMix")
    mixc.data_type = "RGBA"
    mixc.inputs["Factor"].default_value = 0.25
    t.links.new(brick.outputs["Color"], mixc.inputs[6])
    t.links.new(noise.outputs["Color"], mixc.inputs[7])
    t.links.new(mixc.outputs[2], bsdf.inputs["Base Color"])
    bn = t.nodes.new("ShaderNodeBump")
    bn.inputs["Strength"].default_value = 0.25
    t.links.new(brick.outputs["Fac"], bn.inputs["Height"])
    t.links.new(bn.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def regolith_material(name="M_Regolith", albedo=0.19):
    """Lunar regolith for the exteriors: ART_BIBLE regolith grey #7A7672 (linear about 0.19), never brown; fine
    multi-scale relief in the shader below the mesh resolution (clods, pebbles, tracks are geometry)."""
    mat = bpy.data.materials.new(name)
    t = mat.node_tree
    bsdf = t.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.2
    coord = t.nodes.new("ShaderNodeTexCoord")
    n1 = t.nodes.new("ShaderNodeTexNoise")
    n1.inputs["Scale"].default_value = 0.08
    n1.inputs["Detail"].default_value = 6
    t.links.new(coord.outputs["Object"], n1.inputs["Vector"])
    ramp = t.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (albedo * 0.78, albedo * 0.77, albedo * 0.75, 1)
    ramp.color_ramp.elements[1].color = (albedo * 1.12, albedo * 1.10, albedo * 1.07, 1)
    t.links.new(n1.outputs["Fac"], ramp.inputs["Fac"])
    t.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    n2 = t.nodes.new("ShaderNodeTexNoise")
    n2.inputs["Scale"].default_value = 9.0
    n2.inputs["Detail"].default_value = 12
    n2.inputs["Roughness"].default_value = 0.65
    t.links.new(coord.outputs["Object"], n2.inputs["Vector"])
    vor = t.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 30.0
    t.links.new(coord.outputs["Object"], vor.inputs["Vector"])
    add = t.nodes.new("ShaderNodeMath")
    add.operation = "MULTIPLY_ADD"
    add.inputs[1].default_value = 0.4
    t.links.new(vor.outputs["Distance"], add.inputs[0])
    t.links.new(n2.outputs["Fac"], add.inputs[2])
    bn = t.nodes.new("ShaderNodeBump")
    bn.inputs["Strength"].default_value = 0.6
    bn.inputs["Distance"].default_value = 0.02
    t.links.new(add.outputs[0], bn.inputs["Height"])
    t.links.new(bn.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def ch04_materials():
    """The kit's LOD0 table plus Chapter 4 slots. Everything plain here is a shader for the phase 1 previews; phase 2
    bakes the procedural ones (Sintered, MLI, Fabric) into 2K PBR sets like the kit's."""
    table = dict(hk.make_materials(load_kit_images())[0])
    extra = {
        "Screen2": (hk.pbr_material("Screen2", None, 0.12, (0.02, 0.025, 0.03)), 1.0),
        "Screen3": (hk.pbr_material("Screen3", None, 0.12, (0.02, 0.025, 0.03)), 1.0),
        "Label": (node_material("Label", (0.80, 0.80, 0.78), 0.55), 0.25),
        "LampSealed": (node_material("LampSealed", (0.55, 0.06, 0.04), 0.25, emission=((1.0, 0.10, 0.06), 1.5)), 1.0),
        "LampEqualising": (node_material("LampEqualising", (0.60, 0.38, 0.05), 0.25, emission=((1.0, 0.62, 0.10), 0.8)), 1.0),
        "LampSafe": (node_material("LampSafe", (0.08, 0.45, 0.14), 0.25, emission=((0.20, 1.0, 0.35), 0.6)), 1.0),
        "LampDry": (node_material("LampDry", (0.06, 0.20, 0.55), 0.25, emission=((0.25, 0.55, 1.0), 0.8)), 1.0),
        "Flood": (node_material("Flood", (0.95, 0.96, 1.0), 0.4, emission=((0.92, 0.95, 1.0), 6.0)), 1.0),
        "Rubber": (node_material("Rubber", (0.025, 0.025, 0.027), 0.8, bump=(60, 0.1)), 0.5),
        "Fabric": (node_material("Fabric", (0.16, 0.165, 0.17), 0.85, bump=(140, 0.25)), 0.5),
        "Sintered": (sintered_material("Sintered"), 1.0),
        "MLIGold": (mli_material("MLIGold", (0.80, 0.56, 0.22)), 1.0),
        "MLISilver": (mli_material("MLISilver", (0.80, 0.81, 0.82)), 1.0),
        "Retro": (retro_material("Retro", (0.92, 0.92, 0.88), 0.0), 1.0),
        "RetroOrange": (retro_material("RetroOrange", (0.95, 0.36, 0.08), 0.0), 1.0),
        "Brass": (node_material("Brass", (0.75, 0.55, 0.25), 0.35, 1.0), 1.0),
        "Anodised": (node_material("Anodised", (0.20, 0.22, 0.26), 0.35, 0.8), 1.0),
        "Foam": (node_material("Foam", (0.72, 0.72, 0.70), 0.95, bump=(90, 0.3)), 1.0),
        "OldPaint": (node_material("OldPaint", (0.80, 0.62, 0.10), 0.7, bump=(50, 0.15)), 1.0),
    }
    table.update(extra)
    return table


def set_retro_boost(boost):
    for name in ("Retro", "RetroOrange"):
        mat = bpy.data.materials.get(name)
        if mat:
            mul = next(n for n in mat.node_tree.nodes if n.type == "MATH" and n.operation == "MULTIPLY")
            mul.inputs[1].default_value = boost

# ----------------------------------------------------------------------------------------------- small helpers

def rr(w, h, r, n=6):
    return hk.rounded_rect(w, h, r, n)


def frame_ring(b, w, h, cy, r, lip, depth, z, key, cx=0.0, n=6, facing=-1):
    """A rounded-rect frame ring around an opening, front face at z, extruded by depth (towards +z when facing -1)."""
    inner = [(cx + x, cy + y, z) for x, y in rr(w, h, r, n)]
    outer = [(cx + x, cy + y, z) for x, y in rr(w + 2 * lip, h + 2 * lip, r + lip * 0.6, n)]
    b.ring_prism(inner, outer, (0, 0, -facing * depth), key, (0, 0, facing), centre=(cx, cy, z), smooth_inner=True)


def wall_with_opening(b, width, x0, x1, y0, y1, key="PaintGrey", z0=0.0, depth=WALL_D, height=WALL_H):
    """A wall slab of `width` (centred on x = 0) from z0 to z0 + depth with a rectangular hole x0..x1, y0..y1."""
    zc = z0 + depth / 2
    if x0 > -width / 2:
        b.box(((-width / 2 + x0) / 2, height / 2, zc), (x0 + width / 2, height, depth), key)
    if x1 < width / 2:
        b.box(((x1 + width / 2) / 2, height / 2, zc), (width / 2 - x1, height, depth), key)
    if y0 > 0:
        b.box(((x0 + x1) / 2, y0 / 2, zc), (x1 - x0, y0, depth), key)
    if y1 < height:
        b.box(((x0 + x1) / 2, (y1 + height) / 2, zc), (x1 - x0, height - y1, depth), key)


def rib_panel(b, x0, x1, y0, y1, z, pitch, key="PaintWhite", rib_key="PaintGrey", vertical=True, rib=0.04):
    """Corrugated shield panel: a flat sheet facing -Z at z with ribs standing towards -Z every `pitch`."""
    b.box(((x0 + x1) / 2, (y0 + y1) / 2, z + 0.01), (x1 - x0, y1 - y0, 0.02), key)
    if vertical:
        n = max(1, int((x1 - x0) / pitch))
        for i in range(n + 1):
            x = x0 + (x1 - x0) * i / n
            b.box((x, (y0 + y1) / 2, z - rib / 2), (0.035, y1 - y0, rib), rib_key)
    else:
        n = max(1, int((y1 - y0) / pitch))
        for i in range(n + 1):
            y = y0 + (y1 - y0) * i / n
            b.box(((x0 + x1) / 2, y, z - rib / 2), (x1 - x0, 0.035, rib), rib_key)


def lamp(b, x, y, z, key, r=0.018):
    b.cylinder((x, y, z), (x, y, z - 0.012), r, key, segs=12)
    b.torus((x, y, z), (0, 0, 1), r + 0.004, 0.004, "Steel", segs=12, rings=5)


def gauge(b, x, y, z, r=0.055):
    b.cylinder((x, y, z), (x, y, z - 0.018), r, "PaintDark", segs=18)
    b.torus((x, y, z - 0.018), (0, 0, 1), r, 0.006, "Steel", segs=18, rings=6)
    b.box((x + r * 0.35, y + r * 0.15, z - 0.021), (r * 0.7, 0.006, 0.002), "PaintOrange")


def screen(b, x, y, z, w, h, key="Screen", bezel=0.03, tilt=0.0):
    """A screen with its bezel facing -Z at z (optionally tilted back by `tilt` radians about X)."""
    c, s = math.cos(tilt), math.sin(tilt)

    def p(px, py, pz):
        dy, dz = py - y, pz - z
        return (px, y + dy * c - dz * s, z + dy * s + dz * c)
    b.box((x, y, z + 0.02), (w + 2 * bezel, h + 2 * bezel, 0.04), "PaintNavy") if not tilt else None
    if tilt:
        pts = [p(x - w / 2 - bezel, y - h / 2 - bezel, z), p(x + w / 2 + bezel, y - h / 2 - bezel, z), p(x + w / 2 + bezel, y + h / 2 + bezel, z), p(x - w / 2 - bezel, y + h / 2 + bezel, z)]
        b.quad(pts, "PaintNavy", outward=(0, s, -c))
    q = [p(x - w / 2, y - h / 2, z - 0.002), p(x + w / 2, y - h / 2, z - 0.002), p(x + w / 2, y + h / 2, z - 0.002), p(x - w / 2, y + h / 2, z - 0.002)]
    b.quad(q, key, [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, s, -c))


def blank_plate(b, x, y, z, w, h):
    b.box((x, y, z - 0.002), (w + 0.01, h + 0.01, 0.004), "Steel")
    b.box((x, y, z - 0.005), (w, h, 0.003), "Label")

# ----------------------------------------------------------------------------------------------- EN_Garage pieces
# Room section (decision 1): a loading-dock garage. The pressurised ready room deck stands 1.4 m above the vacuum bay
# floor, level with the rover's cabin sill (its side hatches are 1.85-2.96 m up), and the EVA porch at the rover's
# rear (two suitports, cargo rack) is at the same height. Ready-room pieces are kit-height (2.6 m) wall modules.

DOCK_W, DOCK_H, DOCK_SILL = 0.90, 1.15, 0.45      # docking hatch clear opening; sill above the ready-room deck
TUNNEL_L = 1.10                                     # wall bay face to the rover's side at hatch height
DECK_Y = 1.40                                       # ready-room deck and EVA porch above the bay floor


def piece_docking_port(b, lod):
    """2 m pressure-wall module: rover docking hatch 0.90 x 1.15 m (sill 0.45 m) with its vestibule panel (Screen, three
    lamps, gauge); on the bay side the telescoping docking tunnel (child DockCollar) that meets the rover's side hatch."""
    cy = DOCK_SILL + DOCK_H / 2
    hw, hh = DOCK_W / 2 + 0.22, DOCK_H / 2 + 0.22
    wall_with_opening(b, 2.0, -hw, hw, cy - hh, cy + hh)
    hk.wall_frame(b, 2.0, skirting=True) if False else None
    b.box((0, 0.15, -0.03), (1.92, 0.30, 0.06), "PaintNavy")
    for sx in (-1, 1):
        b.box((sx * 0.98, WALL_H / 2, 0.025), (hk.RAIL, WALL_H, 0.05), "PaintGrey")
    b.box((0, WALL_H - hk.RAIL / 2, 0.025), (2.0 - 2 * hk.RAIL, hk.RAIL, 0.05), "PaintGrey")
    n = 6 if lod == 0 else 2
    frame_ring(b, DOCK_W, DOCK_H, cy, 0.22, 0.20, WALL_D + 0.12, -0.06, "PaintGrey", n=n)
    frame_ring(b, DOCK_W + 0.30, DOCK_H + 0.30, cy, 0.30, 0.06, 0.02, -0.065, "PaintNavy", n=n)
    if lod == 0:
        for x, y in rr(DOCK_W + 0.30, DOCK_H + 0.30, 0.30, 4):
            b.cylinder((x, cy + y, -0.065), (x, cy + y, -0.072), 0.011, "Steel", segs=8)
    # orange grab handles both sides of the hatch, room side
    for sx in (-1, 1):
        hk.handle(b, (sx * (hw + 0.10), cy, -0.06), 0.55, lod)
    # vestibule panel (right of the hatch): Screen with SEALED / EQUALISING / SAFE TO OPEN live words, lamps, gauge
    px = 0.80
    b.box((px, 1.45, -0.01), (0.30, 0.70, 0.04), "PaintNavy")
    screen(b, px, 1.62, -0.032, 0.22, 0.14, "Screen", bezel=0.015)
    for k, key in enumerate(("LampSealed", "LampEqualising", "LampSafe")):
        lamp(b, px - 0.07 + 0.07 * k, 1.42, -0.032, key)
    gauge(b, px, 1.24, -0.032, 0.06)
    # bay side: fixed sleeve through the plinth face, white pressure-shell paint
    sleeve_in = [(x, cy + y, WALL_D) for x, y in rr(DOCK_W + 0.02, DOCK_H + 0.02, 0.22, n)]
    sleeve_out = [(x, cy + y, WALL_D) for x, y in rr(DOCK_W + 0.36, DOCK_H + 0.36, 0.36, n)]
    b.ring_prism(sleeve_in, sleeve_out, (0, 0, 0.30), "PaintWhite", (0, 0, -1), centre=(0, cy, WALL_D + 0.15), smooth_inner=True)
    b.box((0, cy - DOCK_H / 2 - 0.02, WALL_D + 0.15), (DOCK_W, 0.04, 0.30), "PaintDark")
    return [("DockWall_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (2.0, WALL_H, WALL_D))]


def dock_collar(b, lod):
    """The telescoping part of the docking tunnel (pivot at the end of the fixed sleeve): accordion bellows, the
    rigid collar ring with its black seal face and two alignment guides. Extended it reaches the rover's hatch."""
    n = 6 if lod == 0 else 2
    cy = 0.0
    length = TUNNEL_L - 0.30
    folds = 9 if lod == 0 else 4
    for k in range(folds):
        z0 = length * 0.75 * k / folds
        w = DOCK_W + (0.40 if k % 2 == 0 else 0.30)
        h = DOCK_H + (0.40 if k % 2 == 0 else 0.30)
        inner = [(x, cy + y, z0) for x, y in rr(DOCK_W + 0.04, DOCK_H + 0.04, 0.24, n)]
        outer = [(x, cy + y, z0) for x, y in rr(w, h, 0.34, n)]
        b.ring_prism(inner, outer, (0, 0, length * 0.75 / folds), "Fabric", (0, 0, -1), centre=(0, cy, z0), smooth_inner=True)
    z1 = length * 0.75
    inner = [(x, cy + y, z1) for x, y in rr(DOCK_W + 0.02, DOCK_H + 0.02, 0.22, n)]
    outer = [(x, cy + y, z1) for x, y in rr(DOCK_W + 0.44, DOCK_H + 0.44, 0.38, n)]
    b.ring_prism(inner, outer, (0, 0, length * 0.25 - 0.03), "PaintWhite", (0, 0, -1), centre=(0, cy, z1), smooth_inner=True)
    seal_o = [(x, cy + y, length - 0.03) for x, y in rr(DOCK_W + 0.30, DOCK_H + 0.30, 0.32, n)]
    seal_i = [(x, cy + y, length - 0.03) for x, y in rr(DOCK_W + 0.10, DOCK_H + 0.10, 0.26, n)]
    b.ring_prism(seal_i, seal_o, (0, 0, 0.03), "Rubber", (0, 0, -1), centre=(0, cy, length))
    for sx in (-1, 1):
        p = Vector((sx * (DOCK_W / 2 + 0.17), cy + DOCK_H / 2 + 0.10, length - 0.03))
        b.cylinder(p, p + Vector((0, 0, 0.12)), 0.03, "PaintOrange", segs=12, radius1=0.004)
    b.box((0, cy - DOCK_H / 2 - 0.02, z1 + (length - z1) / 2), (DOCK_W, 0.04, length - z1), "PaintDark")
    return [("DockCollar_Col-convcolonly", (0, cy, length / 2), (DOCK_W + 0.44, DOCK_H + 0.44, length))]


def dock_hatch_leaf(b, lod):
    """Room-side hatch leaf, hinged on its left edge (pivot), opening into the room by a positive Y rotation."""
    n = 6 if lod == 0 else 2
    w, h, t = DOCK_W + 0.16, DOCK_H + 0.16, 0.07
    cx = w / 2
    outline = rr(w, h, 0.26, n)
    front = [(cx + x, y, -t / 2) for x, y in outline]
    back = [(cx + x, y, t / 2) for x, y in outline]
    fb, bb = b.add_verts(front), b.add_verts(back)
    m = len(outline)
    b.add_face([fb + i for i in range(m)], [(x, y) for x, y, _ in front], "PaintGrey", outward=(0, 0, -1))
    b.add_face([bb + i for i in range(m)], [(x, y) for x, y, _ in back], "PaintGrey", outward=(0, 0, 1))
    for i in range(m):
        j = (i + 1) % m
        b.add_face([fb + i, fb + j, bb + j, bb + i], [(0, 0), (1, 0), (1, 0.1), (0, 0.1)], "PaintGrey", outward=Vector((front[i][0] - cx, front[i][1], 0)))
    win = [(cx + x, 0.22 + y, -t / 2 - 0.004) for x, y in rr(0.28, 0.20, 0.08, n)]
    frame_ring(b, 0.28, 0.20, 0.22, 0.08, 0.04, 0.02, -t / 2 - 0.002, "PaintNavy", cx=cx, n=n)
    base = b.add_verts(win)
    b.add_face([base + i for i in range(len(win))], [(x, y) for x, y, _ in win], "Glass", outward=(0, 0, -1))
    hk.handle(b, (w - 0.16, -0.05, -t / 2), 0.32, lod)
    b.box((w - 0.16, -0.30, -t / 2 - 0.03), (0.06, 0.12, 0.06), "PaintOrange")
    return [("DockHatch_Col-convcolonly", (cx, 0, 0), (w, h, t))]


def piece_bay_window(b, lod):
    """2 m pressure-wall module with a 1.70 x 1.00 m window (sill 1.0 m) looking into the vacuum bay: navy room-side
    frame, white bay-side frame, two panes."""
    w, h, cy, lip = 1.70, 1.00, 1.50, 0.10
    wall_with_opening(b, 2.0, -w / 2 - 0.03, w / 2 + 0.03, cy - h / 2 - 0.03, cy + h / 2 + 0.03)
    b.box((0, 0.15, -0.03), (1.92, 0.30, 0.06), "PaintNavy")
    n = 6 if lod == 0 else 2
    frame_ring(b, w, h, cy, 0.14, lip, WALL_D + 0.10, -0.05, "PaintNavy", n=n)
    frame_ring(b, w, h, cy, 0.14, 0.08, 0.04, WALL_D + 0.05, "PaintWhite", n=n, facing=1)
    for z in (0.02, 0.11):
        pane = [(x * 0.99, cy + y * 0.99, z) for x, y in rr(w, h, 0.14, n)]
        base = b.add_verts(pane)
        b.add_face([base + i for i in range(len(pane))], [(x, y) for x, y, _ in pane], "Glass", outward=(0, 0, -1))
    if lod == 0:
        for x, y in rr(w + lip, h + lip, 0.18, 5):
            b.cylinder((x, cy + y, -0.05), (x, cy + y, -0.057), 0.009, "Steel", segs=8)
    hk.handrail(b, (-0.80, 0.92, -0.04), (0.80, 0.92, -0.04), lod)
    return [("BayWindow_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (2.0, WALL_H, WALL_D))]


LOCK_W, LOCK_H, LOCK_Y0, LOCK_ROOM, LOCK_BAY = 0.72, 0.56, 0.86, 0.34, 0.30


def piece_cargo_lock(b, lod):
    """1 m pressure-wall module with the cargo lock: a 0.72 x 0.56 m chamber at bench height through the wall (it
    stands 0.34 m into the room and 0.30 m over the EVA porch), a cradle tray inside, InnerDoor (room, hinged left) and
    OuterDoor (bay, hinged at the top); LampDry shows the dry-nitrogen fill, LampSafe the equalised state; Screen."""
    x0, x1, y0, y1 = -LOCK_W / 2 - 0.05, LOCK_W / 2 + 0.05, LOCK_Y0 - 0.05, LOCK_Y0 + LOCK_H + 0.05
    wall_with_opening(b, 1.0, x0, x1, y0, y1)
    b.box((0, 0.15, -0.03), (0.92, 0.30, 0.06), "PaintNavy")
    zr, zb = -LOCK_ROOM, WALL_D + LOCK_BAY
    yc = LOCK_Y0 + LOCK_H / 2
    # chamber shell (outside) and steel liner (inside)
    for (cx, cy, sx, sy) in ((0, y0 + 0.03, x1 - x0, 0.06), (0, y1 - 0.03, x1 - x0, 0.06), (x0 + 0.03, yc, 0.06, y1 - y0), (x1 - 0.03, yc, 0.06, y1 - y0)):
        b.box((cx, cy, (zr + zb) / 2), (sx, sy, zb - zr), "PaintWhite")
    b.box((0, LOCK_Y0 + 0.005, (zr + zb) / 2), (LOCK_W - 0.04, 0.01, zb - zr - 0.04), "Steel")
    for sx in (-1, 1):
        b.box((sx * 0.20, LOCK_Y0 + 0.03, (zr + zb) / 2), (0.04, 0.04, zb - zr - 0.06), "Steel")
    b.box((0, y0 - 0.12, zr / 2), (x1 - x0 + 0.06, 0.24, -zr), "PaintNavy")
    b.box((0, y1 + 0.03, zr / 2), (x1 - x0 + 0.06, 0.06, -zr), "PaintGrey")
    # panel: screen, dry and safe lamps, gauge above the lock
    b.box((0, 1.82, -0.01), (0.56, 0.36, 0.04), "PaintNavy")
    screen(b, -0.10, 1.84, -0.032, 0.24, 0.14, "Screen", bezel=0.015)
    lamp(b, 0.12, 1.88, -0.032, "LampDry")
    lamp(b, 0.19, 1.88, -0.032, "LampSafe")
    gauge(b, 0.155, 1.76, -0.032, 0.045)
    hk.handle(b, (x0 - 0.04, yc, zr), 0.40, lod)
    return [("CargoLock_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D)),
            ("CargoLockBox_Col-convcolonly", (0, yc, (zr + zb) / 2), (x1 - x0, y1 - y0, zb - zr))]


def lock_door(face):
    def build(b, lod):
        w, h, t = LOCK_W + 0.12, LOCK_H + 0.12, 0.05
        if face < 0:   # room door, hinge at its left edge (pivot), panel along +X
            b.box((w / 2, 0, -t / 2), (w, h, t), "PaintGrey")
            win = [(w / 2 + x, y, -t - 0.002) for x, y in rr(0.30, 0.18, 0.06, 4)]
            base = b.add_verts(win)
            b.add_face([base + i for i in range(len(win))], [(x, y) for x, y, _ in win], "Glass", outward=(0, 0, -1))
            frame_ring(b, 0.30, 0.18, 0.0, 0.06, 0.03, 0.015, -t - 0.001, "PaintNavy", cx=w / 2, n=4)
            hk.handle(b, (w - 0.08, 0, -t), 0.26, lod)
            return [("InnerDoor_Col-convcolonly", (w / 2, 0, -t / 2), (w, h, t))]
        b.box((0, -h / 2, t / 2), (w, h, t), "PaintWhite")   # bay door, hinge along its top edge (pivot)
        b.box((0, -h + 0.06, t + 0.03), (0.30, 0.04, 0.06), "PaintOrange")
        return [("OuterDoor_Col-convcolonly", (0, -h / 2, t / 2), (w, h, t))]
    return build


def piece_suit_seal_panel(b, lod):
    """1 m wall module: seal checks for the two rear suitports and the docking seal (three gauges, three lamps) and a
    Screen with the leak-check trace; the ready room's 'suit seals' station."""
    b.box((0, WALL_H / 2, WALL_D / 2 + 0.02), (1.0, WALL_H, WALL_D - 0.04), "PaintGrey", skip=((0, 0, -1),))
    for sx in (-1, 1):
        b.box((sx * (0.5 - hk.RAIL / 2), WALL_H / 2, 0.025), (hk.RAIL, WALL_H, 0.05), "PaintGrey")
    b.box((0, WALL_H - hk.RAIL / 2, 0.025), (1.0 - 2 * hk.RAIL, hk.RAIL, 0.05), "PaintGrey")
    b.box((0, 0.15, 0.03), (1.0 - 2 * hk.RAIL, 0.30, 0.06), "PaintNavy")
    b.box((0, (0.30 + 0.95) / 2, 0.02), (1.0 - 2 * hk.RAIL, 0.65, 0.02), "PaintGrey")
    b.box((0, (2.15 + WALL_H - hk.RAIL) / 2, 0.02), (1.0 - 2 * hk.RAIL, WALL_H - hk.RAIL - 2.15, 0.02), "PaintGrey")
    b.box((0, 1.55, 0.03), (1.0 - 2 * hk.RAIL, 1.20, 0.04), "PaintNavy")
    screen(b, 0, 1.84, 0.008, 0.56, 0.30, "Screen", bezel=0.02)
    for k in range(3):
        x = -0.27 + 0.27 * k
        gauge(b, x, 1.40, 0.008, 0.075)
        lamp(b, x, 1.22, 0.008, "LampSafe")
        b.box((x, 1.10, 0.004), (0.16, 0.05, 0.006), "Label")
    hk.handle(b, (-0.43, 1.45, 0.01), 0.5, lod)
    hk.handle(b, (0.43, 1.45, 0.01), 0.5, lod)
    return [("SuitSeal_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D))]


def piece_route_board(b, lod):
    """2 m wall module: the route board, a 1.80 x 0.95 m Screen (route cards A/B/C, slope map, beacon chain) on a navy
    bezel, and a card rail with three blank physical route cards under it."""
    hk.wall_frame(b, 2.0)
    hk.quilt_region(b, -0.96, 0.33, 1.92, 0.62, lod)
    b.box((0, 1.62, 0.0), (1.94, 1.10, 0.06), "PaintNavy")
    screen(b, 0, 1.62, -0.032, 1.80, 0.95, "Screen", bezel=0.0)
    hk.quilt_region(b, -0.96, 2.18, 1.92, WALL_H - hk.RAIL - 2.18, lod)
    b.box((0, 1.00, -0.04), (1.6, 0.03, 0.06), "Steel")
    for k in range(3):
        x = -0.45 + 0.45 * k
        b.box((x, 0.93, -0.05), (0.30, 0.18, 0.006), "Label")
        b.box((x, 1.01, -0.055), (0.05, 0.02, 0.02), "PaintOrange")
    return [("RouteBoard_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (2.0, WALL_H, WALL_D))]


def piece_departure_board(b, lod):
    """1 m wall module: one destination board, a portrait 0.74 x 1.20 m Screen (destination, roster with role colours,
    provisions, departure time; all live text) and a status lamp. Two stand side by side (EX-CH07-S12, CH08-S01)."""
    hk.wall_frame(b, 1.0)
    hk.quilt_region(b, -0.46, 0.33, 0.92, 0.40, lod)
    b.box((0, 1.45, 0.0), (0.86, 1.36, 0.06), "PaintNavy")
    screen(b, 0, 1.43, -0.032, 0.74, 1.20, "Screen", bezel=0.0)
    lamp(b, 0, 2.20, -0.032, "LampSafe", r=0.022)
    hk.quilt_region(b, -0.46, 2.28, 0.92, WALL_H - hk.RAIL - 2.28, lod)
    return [("DepartureBoard_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D))]


CONSOLE_W, CONSOLE_D = 1.80, 0.72


def piece_handover_console(b, lod):
    """Standing base-handover console, 1.80 x 0.72 m: sloped desk at 0.95 m and a riser with three screens: Screen
    (route map and the beacon chain), Screen2 (Amara's slope card), Screen3 (the landing-pad camera, CH05-S01)."""
    w, d = CONSOLE_W, CONSOLE_D
    b.box((0, 0.42, 0.08), (w, 0.84, d - 0.16), "PaintNavy")
    b.box((0, 0.03, -0.02), (w - 0.06, 0.06, d - 0.30), "PaintDark")
    top = [(-w / 2, 0.84, -d / 2), (w / 2, 0.84, -d / 2), (w / 2, 0.98, d / 2 - 0.12), (-w / 2, 0.98, d / 2 - 0.12)]
    b.quad(top, "PaintGrey", outward=(0, 1, -0.3))
    b.box((0, 0.91, -d / 2 - 0.005), (w, 0.14, 0.03), "PaintGrey")
    b.box((0, 1.40, d / 2 - 0.08), (w, 0.86, 0.12), "PaintNavy")
    screen(b, 0, 1.42, d / 2 - 0.145, 0.78, 0.44, "Screen", bezel=0.02, tilt=math.radians(8))
    screen(b, -0.66, 1.42, d / 2 - 0.145, 0.40, 0.30, "Screen2", bezel=0.02, tilt=math.radians(8))
    screen(b, 0.66, 1.42, d / 2 - 0.145, 0.40, 0.30, "Screen3", bezel=0.02, tilt=math.radians(8))
    if lod == 0:
        for k in range(6):
            x = -0.35 + 0.14 * k
            b.box((x, 0.935, 0.0), (0.09, 0.012, 0.06), "PaintDark")
        b.cylinder((0.55, 0.94, -0.05), (0.55, 0.96, -0.05), 0.035, "PaintOrange", segs=14)
        b.box((-0.62, 0.925, -0.08), (0.30, 0.01, 0.20), "PaintDark")
    hk.handrail(b, (-0.85, 0.98, -0.40), (0.85, 0.98, -0.40), lod) if False else None
    return [("Console_Col-convcolonly", (0, 0.65, 0.0), (w, 1.30, d))]


RACK_W, RACK_D, RACK_H = 2.0, 0.60, 2.20


def piece_cargo_rack(b, lod):
    """2.0 x 0.6 x 2.2 m cargo rack with four shelves of sealed bins (blank label plates), orange restraint straps and
    the supply-ledger tablet (Screen2) docked on the right upright at 1.25 m."""
    w, d, h = RACK_W, RACK_D, RACK_H
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        for z in (-d / 2 + 0.03, d / 2 - 0.03):
            b.box((x, h / 2, z), (0.05, h, 0.05), "Steel")
    shelves = (0.12, 0.62, 1.12, 1.62, 2.12)
    rng = np.random.default_rng(SEED + 4)
    for y in shelves:
        b.box((0, y, 0), (w - 0.02, 0.04, d - 0.02), "PaintGrey")
    for si, y in enumerate(shelves[:-1]):
        x = -w / 2 + 0.06
        while x < w / 2 - 0.30:
            bw = float(rng.choice([0.38, 0.45, 0.56]))
            bh = float(rng.choice([0.30, 0.36, 0.40]))
            if x + bw > w / 2 - 0.06:
                break
            b.box((x + bw / 2, y + 0.02 + bh / 2, 0.02), (bw - 0.02, bh, d - 0.12), "PaintWhite")
            b.box((x + bw / 2, y + 0.02 + bh + 0.015, 0.02), (bw - 0.01, 0.03, d - 0.10), "PaintNavy" if (si + int(x * 10)) % 2 else "PaintOrange")
            blank_plate(b, x + bw / 2, y + 0.02 + bh * 0.55, -d / 2 + 0.058, 0.12, 0.06)
            x += bw + 0.03
        b.box((0, y + 0.24, -d / 2 + 0.02), (w - 0.06, 0.035, 0.008), "PaintOrange")
    b.box((w / 2 - 0.03, 1.25, -d / 2 - 0.03), (0.03, 0.06, 0.06), "Steel")
    screen(b, w / 2 - 0.10, 1.32, -d / 2 - 0.06, 0.16, 0.22, "Screen2", bezel=0.015)
    return [("CargoRack_Col-convcolonly", (0, h / 2, 0), (w, h, d))]


LOCKER_W, LOCKER_D, LOCKER_H = 1.20, 0.60, 2.20


def piece_relief_locker(b, lod):
    """1.2 x 0.6 x 2.2 m relief locker for the 8-12 Dec relief cargo (EX-CH04-S12; CH05 crates): white body, navy
    plinth and stripe, a blank label plate; children DoorL / DoorR swing out 110 degrees."""
    w, d, h = LOCKER_W, LOCKER_D, LOCKER_H
    b.box((0, h / 2 + 0.05, 0.03), (w, h - 0.10, d - 0.06), "PaintWhite", skip=((0, 0, -1),))
    b.box((0, 0.05, 0.0), (w, 0.10, d), "PaintNavy")
    b.box((0, h - 0.025, 0.0), (w, 0.05, d), "PaintGrey")
    b.box((0, 1.2, -d / 2 + 0.035), (w - 0.06, 2.0, 0.01), "PaintDark")
    for y in (0.55, 1.05, 1.55):
        b.box((0, y, -d / 2 + 0.25), (w - 0.10, 0.03, 0.45), "PaintGrey")
    return [("Locker_Col-convcolonly", (0, h / 2, 0), (w, h, d))]


def locker_door(side):
    def build(b, lod):
        w, h, t = LOCKER_W / 2 - 0.01, LOCKER_H - 0.16, 0.025
        x0 = 0.0
        sx = 1 if side == "L" else -1
        b.box((sx * w / 2, h / 2, -t / 2), (w, h, t), "PaintWhite")
        b.box((sx * w / 2, h * 0.72, -t - 0.002), (w - 0.04, 0.06, 0.004), "PaintNavy")
        if side == "L":
            blank_plate(b, sx * w / 2, h * 0.85, -t, 0.22, 0.08)
        for k in range(5):
            b.box((sx * w / 2, 0.20 + 0.05 * k, -t - 0.001), (w - 0.16, 0.012, 0.003), "PaintDark")
        hk.handle(b, (sx * (w - 0.06), h * 0.48, -t), 0.30, lod)
        return [(f"Door{side}_Col-convcolonly", (sx * w / 2, h / 2, -t / 2), (w, h, t))]
    return build


BAY_D, BAY_H = 5.85, 5.60   # bay depth (pressure-wall bay face to the far wall) and clear height to the roof sheet


def piece_bay_frame(b, lod):
    """2 m bay module of the vacuum rover shelter (repeat along X): steel portal (column at the far wall, roof beam over
    the bay, purlins), ribbed shield sheet on the far wall and the roof, near-side cladding above the ready room, one
    LED floodlight on the beam and the sintered-regolith floor. Local z runs from 0 (pressure-wall bay face) to BAY_D;
    the pivot is the base centre of the near edge."""
    d, h = BAY_D, BAY_H
    b.box((0, -0.03, d / 2), (2.0, 0.06, d), "Sintered")
    b.box((-0.98, h / 2, d - 0.15), (0.24, h, 0.24), "PaintGrey")
    b.box((-0.98, h / 2, d - 0.15), (0.06, h, 0.24), "Steel") if lod == 0 else None
    b.box((-0.98, h - 0.20, d / 2), (0.24, 0.40, d), "PaintGrey")
    for z in (1.0, 2.5, 4.0, 5.4):
        b.box((0, h - 0.06, z), (2.0, 0.10, 0.10), "Steel")
    rib_panel(b, -1.0, 1.0, 0.0, h, d + 0.02, 0.25, "PaintWhite", "PaintGrey") if True else None
    b.box((0, h + 0.02, d / 2), (2.0, 0.04, d + 0.30), "PaintGrey")
    for x in np.linspace(-0.875, 0.875, 8):
        b.box((float(x), h - 0.01, d / 2), (0.035, 0.03, d), "PaintWhite")
    # near side above the ready room: cladding from the plinth top + ready-room height up to the roof
    rib_panel(b, -1.0, 1.0, DECK_Y + WALL_H + 0.15, h, -0.02, 0.25, "PaintWhite", "PaintGrey")
    b.box((-0.98, (DECK_Y + WALL_H + 0.15 + h) / 2, 0.12), (0.24, h - DECK_Y - WALL_H - 0.15, 0.24), "PaintGrey")
    # floodlight under the beam at mid-depth, pointing down
    b.box((0, h - 0.48, d / 2), (0.70, 0.08, 0.36), "PaintDark")
    b.quad([(-0.32, h - 0.525, d / 2 - 0.15), (0.32, h - 0.525, d / 2 - 0.15), (0.32, h - 0.525, d / 2 + 0.15), (-0.32, h - 0.525, d / 2 + 0.15)], "Flood", outward=(0, -1, 0))
    b.box((0, h - 0.33, d / 2), (0.05, 0.22, 0.05), "Steel")
    # cable tray along the far wall at 4 m
    b.box((0, 4.0, d - 0.18), (2.0, 0.08, 0.22), "PaintNavy")
    return [("BayFloor_Col-convcolonly", (0, -0.03, d / 2), (2.0, 0.06, d)),
            ("BayFarWall_Col-convcolonly", (0, h / 2, d), (2.0, h, 0.10)),
            ("BayRoof_Col-convcolonly", (0, h + 0.02, d / 2), (2.0, 0.04, d))]


DOOR_OPEN_W, DOOR_OPEN_H = 5.55, 4.90


def piece_bay_door(b, lod):
    """End wall of the bay with the rover door: portal (posts and header box) round a 5.55 x 4.90 m opening; child
    DoorPanel (ribbed, rolls up into the header by +4.95 m). The rover door is not a pressure door: the bay is an
    unpressurised shelter (decision 1). Local x spans the bay depth (-BAY_D/2..BAY_D/2), face on z = 0 facing -Z."""
    w, h = BAY_D, BAY_H
    side = (w - DOOR_OPEN_W) / 2
    for sx in (-1, 1):
        b.box((sx * (w / 2 - side / 2), h / 2, 0.12), (side, h, 0.24), "PaintGrey")
        b.box((sx * (DOOR_OPEN_W / 2 + 0.03), DOOR_OPEN_H / 2, -0.02), (0.06, DOOR_OPEN_H, 0.06), "PaintOrange")
    b.box((0, (DOOR_OPEN_H + h) / 2, 0.12), (DOOR_OPEN_W, h - DOOR_OPEN_H, 0.24), "PaintGrey")
    b.cylinder((-DOOR_OPEN_W / 2 - 0.15, DOOR_OPEN_H + 0.36, -0.24), (DOOR_OPEN_W / 2 + 0.15, DOOR_OPEN_H + 0.36, -0.24), 0.32, "PaintNavy", segs=20 if lod == 0 else 10)
    b.box((0, 0.01, 0.12), (DOOR_OPEN_W, 0.02, 0.30), "Steel")
    return [("BayDoorPortal_Col-convcolonly", (0, h / 2, 0.12), (w, h, 0.24))]


def bay_door_panel(b, lod):
    w, h = DOOR_OPEN_W + 0.10, DOOR_OPEN_H
    n = 12 if lod == 0 else 6
    for k in range(n):
        y0 = h * k / n
        b.box((0, y0 + h / n / 2, 0.06), (w, h / n - 0.012, 0.05), "PaintWhite")
        b.box((0, y0 + 0.006, 0.03), (w, 0.012, 0.02), "PaintGrey")
    b.box((0, 0.04, 0.06), (w, 0.08, 0.08), "Rubber")
    for sx in (-1, 1):
        for k in range(5):
            y = 0.5 + k * 0.08
            b.box((sx * 0.9 + sx * 0.08 * k, y + 0.6, 0.02), (0.30, 0.05, 0.01), "PaintOrange") if False else None
    return [("DoorPanel_Col-convcolonly", (0, h / 2, 0.06), (w, h, 0.08))]


def piece_bay_end_wall(b, lod):
    """The closed end wall of the bay (behind the EVA porch): ribbed shield sheet on a frame, 5.85 x 5.60 m."""
    w, h = BAY_D, BAY_H
    b.box((0, h / 2, 0.15), (w, h, 0.06), "PaintGrey")
    rib_panel(b, -w / 2, w / 2, 0.0, h, 0.10, 0.25, "PaintWhite", "PaintGrey")
    for x in (-w / 2 + 0.12, w / 2 - 0.12):
        b.box((x, h / 2, 0.0), (0.24, h, 0.24), "PaintGrey")
    b.box((0, 4.0, 0.0), (w, 0.08, 0.20), "PaintNavy")
    return [("BayEndWall_Col-convcolonly", (0, h / 2, 0.10), (w, h, 0.20))]


PORCH_X = 3.30


def piece_eva_porch(b, lod):
    """EVA porch at the rover's rear, deck at 1.40 m (the ready-room deck height): 3.30 x 5.85 m steel grating on
    sintered-block piers, guard rail on the bay side with a gate at the rover's suitports, a stair down to the bay
    floor. Suited crew back into the rear suitports and load the cargo lock from here. Local x 0..2.90 from the
    end wall, z 0..BAY_D from the pressure wall; pivot at the near end-wall corner. A hinged bridge plate spans the
    0.4 m to the parked rover's rear sill; the stair hugs the far wall clear of the rover's wheels."""
    w, d, y = PORCH_X, BAY_D, DECK_Y
    b.box((w / 2, y / 2 - 0.03, d / 2), (w, y - 0.06, d), "Sintered")
    b.box((w / 2, y - 0.03, d / 2), (w, 0.06, d), "Steel")
    if lod == 0:
        for k in range(1, int(d / 0.25)):
            b.box((w / 2, y + 0.002, k * 0.25), (w - 0.04, 0.004, 0.02), "PaintDark")
    b.box((w - 0.02, y + 0.005, d / 2), (0.04, 0.01, d), "PaintOrange")
    segs = 10 if lod == 0 else 6
    posts_z = (0.3, 1.40, 3.80, 4.90)
    for z in posts_z:
        b.cylinder((w - 0.06, y, z), (w - 0.06, y + 1.05, z), 0.024, "PaintOrange", segs=segs)
    for z0, z1 in ((0.3, 1.40), (3.80, 4.90)):
        b.cylinder((w - 0.06, y + 1.05, z0), (w - 0.06, y + 1.05, z1), 0.022, "PaintOrange", segs=segs)
        b.cylinder((w - 0.06, y + 0.55, z0), (w - 0.06, y + 0.55, z1), 0.018, "PaintOrange", segs=segs)
    # stair down to the bay floor along the far wall
    b.box((w + 0.20, y - 0.02, 2.60), (0.40, 0.03, 2.20), "Steel")
    steps = 7
    for k in range(steps):
        sy = y - (k + 1) * y / (steps + 1)
        b.box((w + 0.14 + k * 0.26, sy, d - 0.32), (0.28, 0.05, 0.60), "Steel")
    b.cylinder((w + 0.1, y + 0.9, d - 0.05), (w + 0.1 + steps * 0.26, 0.9, d - 0.05), 0.02, "PaintOrange", segs=segs)
    return [("Porch_Col-convcolonly", (w / 2, y / 2, d / 2), (w, y, d))]


def piece_umbilical(b, lod):
    """Charge and coolant umbilical post (bay floor): 0.36 x 0.36 x 1.70 m navy post with an orange connector head and
    a hanging cable loop; the room owner draws the live cable to the rover's socket."""
    b.box((0, 0.85, 0), (0.36, 1.70, 0.36), "PaintNavy")
    b.box((0, 0.04, 0), (0.50, 0.08, 0.50), "PaintGrey")
    b.box((0, 1.55, -0.20), (0.26, 0.20, 0.08), "PaintOrange")
    b.cylinder((0, 1.48, -0.22), (0, 1.20, -0.30), 0.03, "Rubber", segs=10)
    b.torus((0, 1.00, -0.31), (0, 0, 1), 0.20, 0.03, "Rubber", segs=20, rings=6)
    lamp(b, 0.10, 1.30, -0.18, "LampSafe")
    return [("Umbilical_Col-convcolonly", (0, 0.85, 0), (0.40, 1.70, 0.40))]

# ----------------------------------------------------------------------------------------------- EN_ColdTrap pieces

MAST_H = 5.0   # decision 9: the beacon antenna on a 5 m mast gives canon's three beacons on the real road


def piece_beacon_mast(b, lod):
    """Survey beacon on its 5 m telescoping mast (replaces the 1.8 m tripod's height; decision 9): tripod feet on
    screw anchors, three telescoping sections, orange guy lines to the feet, the beacon head (antenna, status lamp
    under a guard) and two retroreflective bands at 1.2 m and 2.2 m that flash back in the rover's headlights."""
    segs = 12 if lod == 0 else 6
    for k in range(3):
        a = math.radians(90 + 120 * k)
        foot = Vector((0.75 * math.cos(a), 0.0, 0.75 * math.sin(a)))
        b.cylinder(foot + Vector((0, 0.02, 0)), Vector((0.08 * math.cos(a), 0.95, 0.08 * math.sin(a))), 0.022, "Anodised", segs=segs)
        b.cylinder(foot + Vector((0, -0.0, 0)), foot + Vector((0, 0.03, 0)), 0.07, "Steel", segs=segs)
        b.cylinder(foot + Vector((0, 0.03, 0)), foot + Vector((0, 0.10, 0)), 0.018, "PaintOrange", segs=8)
        b.cylinder(foot + Vector((0, 0.08, 0)), Vector((0, MAST_H - 0.6, 0)), 0.003, "PaintOrange", segs=4)
    for (y0, y1, r) in ((0.85, 2.6, 0.045), (2.6, 4.0, 0.036), (4.0, MAST_H - 0.55, 0.028)):
        b.cylinder((0, y0, 0), (0, y1, 0), r, "Anodised", segs=segs)
        b.cylinder((0, y1 - 0.04, 0), (0, y1 + 0.02, 0), r + 0.01, "Steel", segs=segs)
    for y in (1.2, 2.2):
        b.cylinder((0, y, 0), (0, y + 0.12, 0), 0.05, "Retro", segs=segs)
    hy = MAST_H - 0.55
    b.box((0, hy + 0.13, 0), (0.22, 0.26, 0.22), "PaintWhite")
    b.box((0, hy + 0.27, 0), (0.24, 0.02, 0.24), "PaintNavy")
    b.box((0, hy + 0.13, -0.112), (0.14, 0.14, 0.004), "Screen")
    b.cylinder((0, hy + 0.28, 0), (0, MAST_H - 0.02, 0), 0.008, "Steel", segs=6)
    b.cylinder((0, MAST_H - 0.04, 0), (0, MAST_H, 0), 0.015, "PaintOrange", segs=8)
    b.cylinder((0.07, hy + 0.28, 0.07), (0.07, hy + 0.33, 0.07), 0.018, "LampSafe", segs=10)
    b.box((0, hy - 0.08, 0), (0.12, 0.06, 0.12), "PaintDark")
    return [("BeaconMast_Col-convcolonly", (0, MAST_H / 2, 0), (0.30, MAST_H, 0.30))]


def piece_return_marker(b, lod):
    """Return marker: 2.0 m pole on a base plate with three retroreflective bands and a stiff orange flag plate (no
    cloth: nothing flutters in vacuum); marks the way back to the rover at each segment."""
    segs = 12 if lod == 0 else 6
    b.cylinder((0, 0, 0), (0, 0.03, 0), 0.20, "Steel", segs=segs)
    b.cylinder((0, 0.03, 0), (0, 2.0, 0), 0.025, "PaintWhite", segs=segs)
    for y in (0.6, 1.1, 1.6):
        b.cylinder((0, y, 0), (0, y + 0.15, 0), 0.028, "RetroOrange", segs=segs)
    b.box((0.17, 1.86, 0), (0.30, 0.20, 0.008), "PaintOrange")
    b.box((0.17, 1.86, -0.005), (0.28, 0.04, 0.002), "Retro")
    return [("ReturnMarker_Col-convcolonly", (0, 1.0, 0), (0.40, 2.0, 0.40))]


def piece_slope_sign(b, lod):
    """Slope sign: a 0.55 x 0.40 m blank sign face (Label slot; the slope value is live text) with a retroreflective
    border on a 1.5 m post; stands at each segment's steepest point."""
    segs = 10 if lod == 0 else 6
    b.cylinder((0, 0, 0), (0, 0.03, 0), 0.16, "Steel", segs=segs)
    b.cylinder((0, 0.03, 0), (0, 1.50, 0), 0.022, "Anodised", segs=segs)
    b.box((0, 1.40, -0.02), (0.55, 0.40, 0.012), "PaintNavy")
    for (x, y, sx, sy) in ((0, 1.585, 0.55, 0.03), (0, 1.215, 0.55, 0.03), (-0.26, 1.40, 0.03, 0.40), (0.26, 1.40, 0.03, 0.40)):
        b.box((x, y, -0.028), (sx, sy, 0.003), "Retro")
    b.box((0, 1.40, -0.029), (0.44, 0.30, 0.002), "Label")
    return [("SlopeSign_Col-convcolonly", (0, 0.8, 0), (0.55, 1.6, 0.20))]


def piece_reference_plate(b, lod):
    """Dry reference plate (EX-CH04-S05, the scanner's dry reference 2): a 0.40 x 0.40 m calibration plate of four
    dry-standard tiles on a low tripod stand, levelled 0.30 m above the ground; a socket for the scanner's nose."""
    segs = 10 if lod == 0 else 6
    for k in range(3):
        a = math.radians(90 + 120 * k)
        b.cylinder((0.22 * math.cos(a), 0, 0.22 * math.sin(a)), (0, 0.26, 0), 0.012, "Anodised", segs=segs)
    b.box((0, 0.28, 0), (0.44, 0.03, 0.44), "PaintNavy")
    for i in range(2):
        for j in range(2):
            b.box((-0.10 + 0.20 * i, 0.30, -0.10 + 0.20 * j), (0.18, 0.012, 0.18), "Foam" if (i + j) % 2 else "PaintGrey")
    b.cylinder((0.20, 0.30, 0.20), (0.20, 0.34, 0.20), 0.03, "PaintOrange", segs=segs)
    return [("RefPlate_Col-convcolonly", (0, 0.16, 0), (0.44, 0.32, 0.44))]


def piece_sample_stake(b, lod):
    """Sample-point stake: 0.60 m with a stiff orange tag (live sample number) and a retro tip; three per station."""
    segs = 8 if lod == 0 else 5
    b.cylinder((0, -0.10, 0), (0, 0.60, 0), 0.010, "Steel", segs=segs, radius1=0.010)
    b.box((0.07, 0.52, 0), (0.12, 0.08, 0.004), "PaintOrange")
    b.box((0.07, 0.52, -0.003), (0.09, 0.05, 0.001), "Label")
    b.cylinder((0, 0.60, 0), (0, 0.64, 0), 0.014, "Retro", segs=segs)
    return [("Stake_Col-convcolonly", (0, 0.30, 0), (0.20, 0.64, 0.05))]


def piece_tether_anchor(b, lod):
    """Helical ground anchor (driven into the regolith) with a bearing plate and a D-ring for the carrier tether."""
    segs = 10 if lod == 0 else 6
    b.cylinder((0, -0.40, 0), (0, 0.10, 0), 0.02, "Steel", segs=segs)
    if lod == 0:
        for k in range(6):
            b.torus((0, -0.35 + 0.07 * k, 0), (0, 1, 0), 0.05, 0.004, "Steel", segs=12, rings=4)
    b.cylinder((0, 0.0, 0), (0, 0.02, 0), 0.10, "PaintGrey", segs=segs)
    b.torus((0, 0.15, 0), (0, 0, 1), 0.045, 0.008, "PaintOrange", segs=14, rings=6)
    return [("Anchor_Col-convcolonly", (0, 0.10, 0), (0.20, 0.20, 0.20))]


def piece_survey_marker_2034(b, lod):
    """The 2034 survey marker on the vault shelf (LOC-10 'old marker'): a 1.5 m pole with faded-yellow bands and the
    archival survey tag (a blank aluminium plate: its text is live, and it cannot name Noor before CH05). Twelve
    years in permanent shadow: no sunlight means no UV fading, so only a thin dust film ages it."""
    segs = 10 if lod == 0 else 6
    b.cylinder((0, -0.30, 0), (0, 1.50, 0), 0.03, "PaintGrey", segs=segs)
    for y in (0.5, 0.9, 1.3):
        b.cylinder((0, y, 0), (0, y + 0.12, 0), 0.032, "OldPaint", segs=segs)
    b.box((0, 1.15, -0.035), (0.16, 0.09, 0.004), "Steel")
    b.box((0, 1.15, -0.038), (0.14, 0.07, 0.002), "Label")
    b.cylinder((0, 1.50, 0), (0, 1.53, 0), 0.04, "PaintGrey", segs=segs)
    return [("Marker2034_Col-convcolonly", (0, 0.75, 0), (0.10, 1.53, 0.10))]


# vault set: the closed case is the installed Tripo PR_VaultCase (0.60 x 0.39 x 0.27 m); the open state, the probe,
# the carrier and the cargo mount are new (decision 12)
VC_L, VC_W, VC_H = 0.60, 0.39, 0.27


def piece_vault_open(b, lod):
    """PR_VaultCase rebuilt hinged (decision 12): the installed case's look (white shell, navy corner guards, latches,
    identification window), the outer probe socket on the end, and inside a 12-well inner container (4 x 3 wells,
    each with a capped specimen tube and a blank label tab) in grey foam. Child Lid (hinged at the back, opens 105 deg)
    carries the inscription slot Label_Lid on its underside (live text, clue 15)."""
    L, W, H = VC_L, VC_W, VC_H
    base_h = H * 0.62
    t = 0.02
    b.box((0, 0.01, 0), (L, 0.02, W), "PaintWhite")
    for (cx, cz, sx, sz) in ((0, -W / 2 + t / 2, L, t), (0, W / 2 - t / 2, L, t), (-L / 2 + t / 2, 0, t, W), (L / 2 - t / 2, 0, t, W)):
        b.box((cx, base_h / 2, cz), (sx, base_h, sz), "PaintWhite")
    b.box((0, base_h - 0.03, 0), (L - 2 * t, 0.04, W - 2 * t), "Foam")
    segs = 12 if lod == 0 else 6
    for i in range(4):
        for j in range(3):
            x = -0.20 + 0.133 * i
            z = -0.11 + 0.11 * j
            b.cylinder((x, base_h - 0.10, z), (x, base_h - 0.005, z), 0.028, "PaintDark", segs=segs)
            b.cylinder((x, base_h - 0.06, z), (x, base_h + 0.02, z), 0.020, "Glass", segs=segs)
            b.cylinder((x, base_h + 0.02, z), (x, base_h + 0.035, z), 0.021, "PaintNavy" if (i + j) % 3 else "PaintOrange", segs=segs)
            b.box((x + 0.042, base_h - 0.0, z), (0.03, 0.004, 0.05), "Label")
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.box((sx * (L / 2 - 0.035), base_h / 2, sz * (W / 2 - 0.035)), (0.08, base_h + 0.01, 0.08), "PaintNavy")
    for sz in (-1, 1):
        b.box((sz * 0.17, base_h - 0.03, -W / 2 - 0.012), (0.05, 0.06, 0.02), "Steel")
    b.cylinder((L / 2, base_h * 0.5, 0), (L / 2 + 0.03, base_h * 0.5, 0), 0.025, "Steel", segs=segs)
    b.cylinder((L / 2 + 0.03, base_h * 0.5, 0), (L / 2 + 0.035, base_h * 0.5, 0), 0.012, "PaintDark", segs=segs)
    b.torus((L / 2 + 0.032, base_h * 0.5, 0), (1, 0, 0), 0.03, 0.005, "PaintOrange", segs=14, rings=5)
    return [("VaultBase_Col-convcolonly", (0, base_h / 2, 0), (L, base_h, W))]


def vault_lid(b, lod):
    """Lid, pivot on the back hinge line; closed it sits on the base. Label_Lid: the inscription plate underneath."""
    L, W, H = VC_L, VC_W, VC_H
    lh = H * 0.38
    t = 0.02
    b.box((0, lh - t / 2, -W / 2), (L, t, W), "PaintWhite")
    for (cx, cz, sx, sz) in ((0, -t / 2, L, t), (0, -W + t / 2, L, t), (-L / 2 + t / 2, -W / 2, t, W), (L / 2 - t / 2, -W / 2, t, W)):
        b.box((cx, lh / 2, cz), (sx, lh, sz), "PaintWhite")
    b.box((0, lh + 0.002, -W / 2), (0.16, 0.004, 0.10), "PaintDark")
    b.box((0, lh + 0.004, -W / 2), (0.14, 0.002, 0.08), "Glass")
    for sx in (-1, 1):
        for sz in (0, -1):
            b.box((sx * (L / 2 - 0.035), lh / 2, -0.035 if sz == 0 else -W + 0.035), (0.08, lh + 0.01, 0.08), "PaintNavy")
    b.box((0, 0.012, -W / 2), (L - 0.12, 0.004, W - 0.12), "Foam")
    b.box((0, 0.016, -W / 2), (0.34, 0.002, 0.14), "Label")
    return [("VaultLid_Col-convcolonly", (0, lh / 2, -W / 2), (L, lh, W))]


def piece_vault_probe(b, lod):
    """Thermal contact probe for the outer case (EX-CH04-S07): 0.45 m wand, grip with a small Screen, coiled cable."""
    segs = 12 if lod == 0 else 6
    b.cylinder((0, 0.03, -0.22), (0, 0.03, 0.02), 0.006, "Steel", segs=segs, radius1=0.01)
    b.cylinder((0, 0.03, 0.02), (0, 0.03, 0.20), 0.022, "PaintNavy", segs=segs)
    b.cylinder((0, 0.03, -0.235), (0, 0.03, -0.22), 0.004, "Brass", segs=segs)
    b.box((0, 0.056, 0.10), (0.03, 0.004, 0.05), "Screen")
    b.cylinder((0, 0.03, 0.20), (0, 0.03, 0.23), 0.012, "PaintOrange", segs=segs)
    b.torus((0, 0.012, 0.32), (0, 1, 0), 0.08, 0.006, "Rubber", segs=16, rings=5)
    return [("Probe_Col-convcolonly", (0, 0.03, 0.03), (0.06, 0.06, 0.50))]


CARRIER_L, CARRIER_W, CARRIER_H = 0.86, 0.58, 0.52


def piece_vault_carrier(b, lod):
    """Recovery carrier (EX-CH04-S02 'closed carrier', S06 tethered, S08 cradle transfer): a rigid cradle frame with
    two lift handles (two support points: Rafi and Kai), the insulated MLI sleeve inside (seated over the case
    before the lift), a tether eye, and the latch rails that lock onto the rover cargo mount. Shown loaded: the
    sleeved case sits in the cradle."""
    L, W, H = CARRIER_L, CARRIER_W, CARRIER_H
    segs = 10 if lod == 0 else 6
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.box((sx * (L / 2 - 0.02), H / 2, sz * (W / 2 - 0.02)), (0.04, H, 0.04), "Anodised")
        b.box((sx * (L / 2 - 0.02), 0.02, 0), (0.04, 0.04, W), "Anodised")
        b.box((sx * (L / 2 - 0.02), H - 0.02, 0), (0.04, 0.04, W), "Anodised")
        b.cylinder((sx * (L / 2 + 0.10), H - 0.02, -0.12), (sx * (L / 2 + 0.10), H - 0.02, 0.12), 0.018, "PaintOrange", segs=segs)
        for sz in (-1, 1):
            b.cylinder((sx * (L / 2 - 0.02), H - 0.02, sz * 0.12), (sx * (L / 2 + 0.10), H - 0.02, sz * 0.12), 0.012, "PaintOrange", segs=segs)
    for sz in (-1, 1):
        b.box((0, 0.02, sz * (W / 2 - 0.02)), (L, 0.04, 0.04), "Anodised")
        b.box((0, H - 0.02, sz * (W / 2 - 0.02)), (L, 0.04, 0.04), "Anodised")
        b.box((0, -0.0 + 0.01, sz * 0.18), (L + 0.10, 0.02, 0.05), "Steel")
    # the sleeve: a quilted MLI bag around the case with a navy zip band and a dry-N2 valve
    b.box((0, 0.05 + 0.16, 0), (VC_L + 0.10, 0.32, VC_W + 0.10), "MLISilver")
    b.box((0, 0.05 + 0.33, 0), (VC_L + 0.06, 0.03, VC_W + 0.06), "MLISilver")
    b.box((0, 0.05 + 0.20, -VC_W / 2 - 0.052), (VC_L + 0.10, 0.03, 0.006), "PaintNavy")
    b.cylinder((VC_L / 2 + 0.05, 0.25, 0.10), (VC_L / 2 + 0.08, 0.25, 0.10), 0.02, "Steel", segs=segs)
    b.torus((0, H + 0.04, W / 2 - 0.02), (1, 0, 0), 0.03, 0.007, "Steel", segs=12, rings=5)
    blank_plate(b, -0.20, 0.30, -VC_W / 2 - 0.054, 0.12, 0.06)
    return [("Carrier_Col-convcolonly", (0, H / 2, 0), (L + 0.24, H, W))]


def piece_rover_cargo_mount(b, lod):
    """Rover cargo mount for VH_Rover's rear rack (EX-CH04-S08): two latch rails, a latch with a position flag (the
    'shows closed' indication) and an independent lock pin with its own lamp ('testing locked'): position and lock are
    two results. 0.96 x 0.66 m, bolts to the rack at 1.60 m."""
    segs = 10 if lod == 0 else 6
    b.box((0, 0.03, 0), (0.96, 0.06, 0.66), "Anodised")
    for sz in (-1, 1):
        b.box((0, 0.08, sz * 0.18), (0.94, 0.05, 0.07), "Steel")
    b.box((0.44, 0.13, 0), (0.08, 0.14, 0.22), "PaintNavy")
    b.box((0.47, 0.22, -0.06), (0.03, 0.06, 0.02), "PaintOrange")
    b.cylinder((0.40, 0.18, 0.10), (0.52, 0.18, 0.10), 0.012, "Steel", segs=segs)
    b.cylinder((0.52, 0.18, 0.10), (0.55, 0.18, 0.10), 0.02, "PaintOrange", segs=segs)
    lamp(b, 0.49, 0.21, 0.12, "LampSafe")
    return [("CargoMount_Col-convcolonly", (0, 0.08, 0), (0.96, 0.16, 0.66))]


GARAGE_PIECES = [
    dict(id="EN_Garage_DockingPort", display="Rover docking port", build=piece_docking_port, wall=True,
         children=[("HatchLeaf", (-(DOCK_W + 0.16) / 2, DOCK_SILL + DOCK_H / 2, -0.10), dock_hatch_leaf),
                   ("DockCollar", (0, DOCK_SILL + DOCK_H / 2, WALL_D + 0.30), dock_collar)],
         lines=["2 m wall; hatch 0.90 x 1.15 m, sill 0.45 m", "telescoping tunnel to the rover hatch"]),
    dict(id="EN_Garage_BayWindow", display="Bay window", build=piece_bay_window, wall=True, lines=["2 m wall; 1.70 x 1.00 m window", "sill 1.0 m, two panes"]),
    dict(id="EN_Garage_CargoLock", display="Dry cargo lock", build=piece_cargo_lock, wall=True,
         children=[("InnerDoor", (-(LOCK_W + 0.12) / 2, LOCK_Y0 + LOCK_H / 2, -LOCK_ROOM), lock_door(-1)),
                   ("OuterDoor", (0, LOCK_Y0 + LOCK_H + 0.06, WALL_D + LOCK_BAY), lock_door(1))],
         lines=["1 m wall; chamber 0.72 x 0.56 m", "dry N2 fill, one door at a time"]),
    dict(id="EN_Garage_SuitSealPanel", display="Suit seal station", build=piece_suit_seal_panel, wall=True, lines=["1 m wall; 2 suitports + dock seal", "gauges, lamps, Screen"]),
    dict(id="EN_Garage_RouteBoard", display="Route board", build=piece_route_board, wall=True, lines=["2 m wall; 1.80 x 0.95 m Screen", "route cards A/B/C (blank)"]),
    dict(id="EN_Garage_DepartureBoard", display="Departure board", build=piece_departure_board, wall=True, lines=["1 m wall; 0.74 x 1.20 m Screen", "two side by side"]),
    dict(id="EN_Garage_HandoverConsole", display="Base handover console", build=piece_handover_console, lines=["1.80 x 0.72 m, desk 0.95 m", "map, slope card, pad camera"]),
    dict(id="EN_Garage_CargoRack", display="Cargo rack + supply ledger", build=piece_cargo_rack, lines=["2.0 x 0.6 x 2.2 m", "ledger tablet = Screen2"]),
    dict(id="EN_Garage_ReliefLocker", display="Relief locker", build=piece_relief_locker,
         children=[("DoorL", (-LOCKER_W / 2 + 0.005, 0.08, -LOCKER_D / 2), locker_door("L")), ("DoorR", (LOCKER_W / 2 - 0.005, 0.08, -LOCKER_D / 2), locker_door("R"))],
         lines=["1.2 x 0.6 x 2.2 m", "relief cargo, blank plate"]),
    dict(id="EN_Garage_BayFrame", display="Bay module (vacuum)", build=piece_bay_frame, lines=["2 m x 5.85 m x 5.6 m", "portal, shield, flood, floor"]),
    dict(id="EN_Garage_BayDoor", display="Rover door", build=piece_bay_door, children=[("DoorPanel", (0, 0, -0.10), bay_door_panel)],
         lines=["opening 5.55 x 4.90 m", "panel rolls up 4.95 m"]),
    dict(id="EN_Garage_BayEndWall", display="Bay end wall", build=piece_bay_end_wall, lines=["5.85 x 5.60 m", "ribbed shield"]),
    dict(id="EN_Garage_EVAPorch", display="EVA porch", build=piece_eva_porch, lines=["3.30 x 5.85 m deck at 1.40 m", "rail, suitport gate, stair"]),
    dict(id="EN_Garage_Umbilical", display="Charge umbilical", build=piece_umbilical, lines=["0.36 x 1.70 m post", "power + coolant"]),
]
COLDTRAP_PIECES = [
    dict(id="EN_ColdTrap_BeaconMast", display="Beacon on 5 m mast", build=piece_beacon_mast, lines=["5.0 m; tripod 1.5 m across", "retro bands, status lamp"]),
    dict(id="EN_ColdTrap_ReturnMarker", display="Return marker", build=piece_return_marker, lines=["2.0 m pole", "3 retro bands, stiff flag"]),
    dict(id="EN_ColdTrap_SlopeSign", display="Slope sign", build=piece_slope_sign, lines=["1.5 m; face 0.55 x 0.40 m", "value is live text"]),
    dict(id="EN_ColdTrap_ReferencePlate", display="Dry reference plate", build=piece_reference_plate, lines=["0.40 x 0.40 m at 0.30 m", "four dry-standard tiles"]),
    dict(id="EN_ColdTrap_SampleStake", display="Sample stake", build=piece_sample_stake, lines=["0.60 m, stiff tag", "three per station"]),
    dict(id="EN_ColdTrap_TetherAnchor", display="Tether anchor", build=piece_tether_anchor, lines=["helical, D-ring", "two on the shelf"]),
    dict(id="EN_ColdTrap_SurveyMarker2034", display="2034 marker + tag", build=piece_survey_marker_2034, lines=["1.5 m, archival tag", "unfaded: no UV in a PSR"]),
    dict(id="PR_VaultCase_Open", display="Vault V12, open", build=piece_vault_open, children=[("Lid", (0, VC_H * 0.62, VC_W / 2), vault_lid)],
         lines=["0.60 x 0.39 x 0.27 m", "12 wells, lid inscription slot"]),
    dict(id="PR_VaultProbe", display="Thermal probe", build=piece_vault_probe, lines=["0.45 m wand", "Screen, cable"]),
    dict(id="PR_VaultCarrier", display="Recovery carrier", build=piece_vault_carrier, lines=["0.86 x 0.58 x 0.52 m", "cradle + MLI sleeve"]),
    dict(id="PR_RoverCargoMount", display="Rover cargo mount", build=piece_rover_cargo_mount, lines=["0.96 x 0.66 m", "latch flag + lock pin"]),
]
ALL_PIECES = GARAGE_PIECES + COLDTRAP_PIECES

# ----------------------------------------------------------------------------------------------- build and place

def build_piece(spec, table):
    """(root, objects) for a piece at LOD0 in Godot's frame, children as pivoted empties (like build_chapter2_assets)."""
    root = hk.make_empty(spec["id"])
    b = Builder(table)
    cols = spec["build"](b, 0)
    body = b.to_object(spec["id"] + "_Mesh")
    body.parent = root
    objs = [body] + hk.collision_objects(cols, body, table)
    for name, pivot, fn in spec.get("children", []):
        child = hk.make_empty(spec["id"] + "_" + name, pivot, root)
        cb = Builder(table)
        ccols = fn(cb, 0)
        cmesh = cb.to_object(spec["id"] + "_" + name + "_Mesh")
        cmesh.parent = child
        objs += [child, cmesh] + hk.collision_objects(ccols, cmesh, table)
    hk.bake_blender_space(objs)
    for o in objs:
        if o.name.endswith(hk.COL_SUFFIXES):
            o.hide_render = True
            o.hide_viewport = True
    bpy.context.view_layer.update()
    return root, objs


def child(objs, name):
    return next(o for o in objs if o.type == "EMPTY" and o.name.split(".")[0].endswith("_" + name))


def place(root, x, y, z, yaw=0.0):
    """Put a built piece at Godot room position (x, y, z) with a yaw (degrees about +Y)."""
    root.location = (x, -z, y)
    root.rotation_euler = (0, 0, math.radians(yaw))


def instance(template, parent=None):
    """A linked copy of a built piece tree (meshes shared)."""
    root, objs = template
    mapping = {}

    def dup(o, new_parent):
        c = o.copy()
        c.parent = new_parent
        if new_parent is not None:
            c.matrix_parent_inverse = o.matrix_parent_inverse.copy()
        bpy.context.scene.collection.objects.link(c)
        c.hide_render = o.hide_render
        mapping[o] = c
        for ch in o.children:
            dup(ch, c)
        return c
    r = dup(root, parent)
    return r, [mapping[o] for o in objs if o in mapping]


def hide_tree(root, hidden=True):
    for o in [root] + list(root.children_recursive):
        if "colonly" not in o.name:
            o.hide_render = hidden

# ----------------------------------------------------------------------------------------------- render setup

def setup_cycles(samples, w, h):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "METAL"
        prefs.get_devices()
        for device in prefs.devices:
            device.use = True
        scene.cycles.device = "GPU"
    except Exception as error:
        print("cycles GPU unavailable:", error)
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = (w // 2, h // 2) if SMALL else (w, h)
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Base Contrast"
    scene.view_settings.exposure = 0.0
    if scene.world is None:
        scene.world = bpy.data.worlds.new("World")
    return scene


def world_color(rgb, strength):
    bg = bpy.context.scene.world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (*rgb, 1)
    bg.inputs["Strength"].default_value = strength


def camera_at(loc, target, lens=35.0, ortho=None):
    cam = bpy.context.scene.camera
    if cam is None:
        cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
        bpy.context.scene.collection.objects.link(cam)
        bpy.context.scene.camera = cam
    cam.location = Vector(loc)
    cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    cam.data.clip_start = 0.05
    cam.data.clip_end = 120000.0
    if ortho:
        cam.data.type = "ORTHO"
        cam.data.ortho_scale = ortho
    else:
        cam.data.type = "PERSP"
        cam.data.lens = lens
    return cam


def render(name):
    bpy.context.scene.render.filepath = str(PREVIEW / f"{name}.png")
    bpy.ops.render.render(write_still=True)
    print("CH04 rendered", name)


def add_light(kind, loc, energy, color=(1, 1, 1), target=None, size=None, spot=None, name="L"):
    data = bpy.data.lights.new(name, kind)
    data.energy = energy
    data.color = color
    if size is not None:
        if kind == "AREA":
            data.size = size
        elif kind in ("POINT", "SPOT"):
            data.shadow_soft_size = size
        elif kind == "SUN":
            data.angle = size
    if spot is not None:
        data.spot_size = math.radians(spot[0])
        data.spot_blend = spot[1]
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = Vector(loc)
    if target is not None:
        obj.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return obj


def studio_rig():
    """The neutral grey studio of the kit and airlock sheets (piece previews)."""
    world_color((0.50, 0.51, 0.53), 0.55)
    sun = add_light("SUN", (3, 5, 8), 2.2, size=math.radians(4), name="StudioSun")
    sun.rotation_euler = (Vector((0, 0, 0)) - Vector((3, -5, 8))).to_track_quat("-Z", "Y").to_euler()
    fill = add_light("AREA", (-4, -5, 4), 250, size=5, target=(0, 0, 1.2), name="StudioFill")
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, -0.002))
    floor = bpy.context.object
    floor.name = "StudioFloor"
    mat = bpy.data.materials.new("StudioFloor")
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.42, 0.43, 0.45, 1)
    mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    floor.data.materials.append(mat)
    return [sun, fill, floor]


def bounds_of(objs):
    vis = [o for o in objs if o.type == "MESH" and not o.hide_render]
    pts = [o.matrix_world @ Vector(c) for o in vis for c in o.bound_box]
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])


def render_piece_preview(root, objs, name, direction=(0.75, 1.0, 0.6), pad=1.25):
    bpy.context.view_layer.update()
    lo, hi = bounds_of(objs)
    c = (lo + hi) / 2
    ext = max(hi - lo)
    camera_at(c + Vector(direction).normalized() * (ext * 4 + 3), c, ortho=ext * pad)
    render(name)

# ----------------------------------------------------------------------------------------------- scale figures

def face(dx, dy):
    """Yaw (deg) that turns a scale figure (front = local -Y) to look along the Blender direction (dx, dy)."""
    return math.degrees(math.atan2(dx, -dy))


def figure(loc, yaw=0.0, suited=False, lamp=False, name="Figure"):
    """1.75 m scale figure (as on the M3-2A sheets): grey for the coverall cast, white suit with helmet, backpack and
    an optional helmet lamp for EVA. The cel-shaded cast is composited at runtime, never in these renders."""
    mats = bpy.data.materials
    grey = mats.get("ScaleGrey") or node_material("ScaleGrey", (0.30, 0.31, 0.33), 0.6)
    suit = mats.get("ScaleSuit") or node_material("ScaleSuit", (0.55, 0.56, 0.57), 0.8, bump=(30, 0.15))
    visor = mats.get("ScaleVisor") or node_material("ScaleVisor", (0.55, 0.42, 0.18), 0.08, 1.0)
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    parts = []

    def add(obj, mat):
        obj.data.materials.append(mat)
        obj.parent = root
        parts.append(obj)
    m = suit if suited else grey
    r = 0.24 if suited else 0.18
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=1.30 if suited else 1.42, location=(0, 0, 0.66 if suited else 0.72))
    add(bpy.context.object, m)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.17 if suited else 0.11, location=(0, 0, 1.52 if suited else 1.62))
    add(bpy.context.object, m)
    if suited:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.15, location=(0, -0.06, 1.53))
        v = bpy.context.object
        v.scale = (1.0, 0.75, 0.85)
        add(v, visor)
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.30, 1.05))
        bp = bpy.context.object
        bp.scale = (0.46, 0.22, 0.62)
        add(bp, suit)
        if lamp:
            lt = add_light("SPOT", (0, -0.16, 1.70), 300, (1.0, 0.97, 0.92), target=(0, -6, 0.6), size=0.02, spot=(36, 0.35), name=name + "_Lamp")
            lt.parent = root
            lt.location = (0.12, -0.14, 1.68)
            lt.rotation_euler = (math.radians(-55), 0, 0)
    root.location = Vector(loc)
    root.rotation_euler = (0, 0, math.radians(yaw))
    return root

# ----------------------------------------------------------------------------------------------- pieces mode

def run_pieces(table):
    setup_cycles(SAMPLES, 720, 720)
    rig = studio_rig()
    for spec in ALL_PIECES:
        root, objs = build_piece(spec, table)
        set_retro_boost(0.0)
        hide_tree(root, False)
        direction = (0.75, 1.0, 0.6)
        if spec["id"] in ("EN_Garage_BayFrame", "EN_Garage_EVAPorch"):
            direction = (-1.0, 0.8, 0.7)
        render_piece_preview(root, objs, spec["id"], direction)
        if spec["id"] == "EN_Garage_DockingPort":
            leaf = child(objs, "HatchLeaf")
            leaf.rotation_euler = (0, 0, math.radians(100))
            render_piece_preview(root, objs, spec["id"] + "_open", direction)
            render_piece_preview(root, objs, spec["id"] + "_bay", (-0.6, -1.0, 0.45))
            leaf.rotation_euler = (0, 0, 0)
        if spec["id"] == "EN_Garage_CargoLock":
            child(objs, "InnerDoor").rotation_euler = (0, 0, math.radians(100))
            render_piece_preview(root, objs, spec["id"] + "_open", direction)
            child(objs, "InnerDoor").rotation_euler = (0, 0, 0)
            render_piece_preview(root, objs, spec["id"] + "_bay", (-0.6, -1.0, 0.45))
        if spec["id"] == "EN_Garage_ReliefLocker":
            child(objs, "DoorL").rotation_euler = (0, 0, math.radians(110))
            child(objs, "DoorR").rotation_euler = (0, 0, math.radians(-110))
            render_piece_preview(root, objs, spec["id"] + "_open", direction)
        if spec["id"] == "EN_Garage_BayDoor":
            panel = child(objs, "DoorPanel")
            panel.scale.z, panel.location.z = 0.04, panel.location.z + DOOR_OPEN_H * 0.96
            render_piece_preview(root, objs, spec["id"] + "_open", direction)
            panel.scale.z, panel.location.z = 1.0, panel.location.z - DOOR_OPEN_H * 0.96
        if spec["id"] == "PR_VaultCase_Open":
            lid = child(objs, "Lid")
            lid.rotation_euler = (math.radians(105), 0, 0)
            render_piece_preview(root, objs, spec["id"], (0.7, 1.0, 0.9))
            render_piece_preview(root, objs, spec["id"] + "_lid", (0.0, 1.0, 0.35), pad=1.3)
            lid.rotation_euler = (0, 0, 0)
            render_piece_preview(root, objs, spec["id"] + "_closed", direction)
        hide_tree(root, True)


# ----------------------------------------------------------------------------------------------- LOLA terrain

class Field:
    """One LOLA region heightmap (r16 + json) sampled in map metres (bicubic Catmull-Rom, vectorised)."""

    def __init__(self, region, mpp, detail):
        stem = f"heightmap_{mpp}m" + ("_detail" if detail else "")
        self.meta = json.loads((LOLA / region / f"{stem}.json").read_text())
        m = self.meta
        raw = np.fromfile(LOLA / region / f"{stem}.r16", dtype="<u2").reshape(m["rows"], m["columns"])
        self.h = m["z_min_m"] + raw.astype(np.float64) * (m["z_max_m"] - m["z_min_m"]) / 65535.0
        self.mpp, self.ox, self.oy = float(m["metres_per_pixel"]), m["origin_x_m"], m["origin_y_m"]

    def inside(self, x, y, margin=2):
        c = (x - self.ox) / self.mpp
        r = (self.oy - y) / self.mpp
        return (c >= margin) & (c <= self.h.shape[1] - 1 - margin) & (r >= margin) & (r <= self.h.shape[0] - 1 - margin)

    def sample(self, x, y):
        c = np.clip((x - self.ox) / self.mpp, 1, self.h.shape[1] - 3)
        r = np.clip((self.oy - y) / self.mpp, 1, self.h.shape[0] - 3)
        c0, r0 = np.floor(c).astype(int), np.floor(r).astype(int)
        tc, tr = c - c0, r - r0

        def w(t):
            return [((-t + 2) * t - 1) * t / 2, (((3 * t - 5) * t) * t + 2) / 2, ((-3 * t + 4) * t + 1) * t / 2, ((t - 1) * t * t) / 2]
        wc, wr = w(tc), w(tr)
        out = np.zeros_like(c)
        for j in range(4):
            row = np.zeros_like(c)
            for i in range(4):
                row += wc[i] * self.h[r0 + j - 1, c0 + i - 1]
            out += wr[j] * row
        return out


FIELDS = []


def fields():
    if not FIELDS:
        FIELDS.extend([Field("aurora_ridge", 5, True), Field("cold_trap", 10, True), Field("aurora_vista", 40, False)])
    return FIELDS


def height_map(x, y):
    """Composite LOLA height (m above the 1,737.4 km sphere): the 5 m Aurora ridge, else the 10 m cold trap, else
    the 40 m vista (the same priority the game's tiles give the hero regions)."""
    out = np.full(np.shape(x), np.nan)
    for f in reversed(fields()):
        m = f.inside(x, y)
        if m.any():
            out = np.where(m, f.sample(x, y), out)
    return np.nan_to_num(out, nan=float(np.nanmean(out)) if np.isfinite(out).any() else 0.0)


def fractal2d(rng, n, low, high, beta=2.0):
    f = np.fft.fftfreq(n) * n
    r = np.sqrt(f[:, None] ** 2 + f[None, :] ** 2)
    spec = rng.standard_normal((n, n)) + 1j * rng.standard_normal((n, n))
    filt = np.where((r >= low) & (r <= high), 1.0 / np.maximum(r, 1) ** (beta / 2), 0.0)
    out = np.real(np.fft.ifft2(spec * filt))
    return out / (out.std() + 1e-9)


def grid_mesh(name, xs, ys, z, mat, hole=None, skirt=0.0):
    """Mesh from a height grid z[j, i] at Blender (xs[i], ys[j]); faces whose centre falls inside hole
    (x0, x1, y0, y1) are dropped; skirt adds a downward lip on the outer edge (hides T-junction cracks)."""
    nx, ny = len(xs), len(ys)
    X, Y = np.meshgrid(xs, ys)
    verts = np.stack([X.ravel(), Y.ravel(), z.ravel()], axis=1)
    idx = np.arange(nx * ny).reshape(ny, nx)
    a, b, c, d = idx[:-1, :-1].ravel(), idx[:-1, 1:].ravel(), idx[1:, 1:].ravel(), idx[1:, :-1].ravel()
    faces = np.stack([a, b, c, d], axis=1)
    if hole is not None:
        cx = (X[:-1, :-1] + X[:-1, 1:]).ravel() / 2
        cy = (Y[:-1, :-1] + Y[1:, :-1]).ravel() / 2
        keep = ~((cx > hole[0]) & (cx < hole[1]) & (cy > hole[2]) & (cy < hole[3]))
        faces = faces[keep]
    verts = list(map(tuple, verts))
    faces = [tuple(f) for f in faces]
    if skirt:
        ring = list(idx[0, :]) + list(idx[1:, -1]) + list(idx[-1, -2::-1]) + list(idx[-2:0:-1, 0])
        base = len(verts)
        for k in ring:
            vx, vy, vz = verts[k]
            verts.append((vx, vy, vz - skirt))
        for i in range(len(ring)):
            j = (i + 1) % len(ring)
            faces.append((ring[i], base + i, base + j, ring[j]))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(mat)
    for p in mesh.polygons:
        p.use_smooth = True
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def build_terrain(x0, y0, h0, near=120.0, step=0.25, mid=2400.0, mstep=5.0, far=30000.0, fstep=100.0, seed=1, edits=None):
    """Three nested terrain meshes centred on map (x0, y0), heights relative to h0 minus the sphere's drop (the scene
    is a local tangent frame like the game's region frames). edits(xn, yn, zn) may modify the near grid (ruts,
    graded pads). Near detail adds a seeded sub-pixel relief and small fresh craters (fading to zero at the edge)."""
    mat = bpy.data.materials.get("M_Regolith") or regolith_material()
    rng = np.random.default_rng(seed)

    def local(xs, ys):
        X, Y = np.meshgrid(xs, ys)
        z = height_map(X + x0, Y + y0) - h0 - (X ** 2 + Y ** 2) / (2 * R_MOON)
        return X, Y, z
    n = int(round(near / step))
    xs = np.linspace(-near / 2, near / 2, n + 1)
    X, Y, z = local(xs, xs)
    fade = np.clip((near / 2 - np.maximum(np.abs(X), np.abs(Y))) / (near * 0.12), 0, 1)
    size = 1 << int(math.ceil(math.log2(n + 1)))
    noise = fractal2d(rng, size, 2, size / 10, 2.6)[: n + 1, : n + 1]
    z = z + 0.035 * noise * fade
    count = int(near * near * 0.004)
    for _ in range(count):
        D = float(np.clip(rng.pareto(1.8) * 0.6 + 0.4, 0.4, 14.0))
        cx, cy = rng.uniform(-near / 2, near / 2, 2)
        rr_ = np.hypot(X - cx, Y - cy) / (D / 2)
        depth = D * float(rng.uniform(0.03, 0.11))
        bowl = np.where(rr_ < 1, -depth * (1 - rr_ ** 2), 0.0)
        rim = np.where((rr_ >= 0.8) & (rr_ < 1.6), 0.25 * depth * np.exp(-((rr_ - 1.0) / 0.25) ** 2), 0.0)
        z = z + (bowl + rim) * fade
    if edits is not None:
        z = edits(X, Y, z)
    objs = [grid_mesh("TerrainNear", xs, xs, z, mat, skirt=1.0)]
    m = int(round(mid / mstep))
    xs2 = np.linspace(-mid / 2, mid / 2, m + 1)
    X2, Y2, z2 = local(xs2, xs2)
    hole = (-near / 2 + mstep, near / 2 - mstep, -near / 2 + mstep, near / 2 - mstep)
    objs.append(grid_mesh("TerrainMid", xs2, xs2, z2, mat, hole=hole, skirt=3.0))
    f_ = int(round(far / fstep))
    xs3 = np.linspace(-far / 2, far / 2, f_ + 1)
    X3, Y3, z3 = local(xs3, xs3)
    hole3 = (-mid / 2 + fstep, mid / 2 - fstep, -mid / 2 + fstep, mid / 2 - fstep)
    objs.append(grid_mesh("TerrainFar", xs3, xs3, z3, mat, hole=hole3))
    return objs


def ground_z(x0, y0, h0, lx, ly):
    """Base LOLA height (no near detail) at local (lx, ly) of a scene centred on map (x0, y0)."""
    return float(height_map(np.array([lx + x0]), np.array([ly + y0]))[0] - h0 - (lx * lx + ly * ly) / (2 * R_MOON))


def sun_vector(x_m, y_m, az, el):
    """Toward the Sun in Blender's scene frame (x = map x, y = map y, z up), from a Horizons azimuth (local north =
    away from the pole) and elevation: terrain_heightfield.gd sun_direction_at() in Blender axes."""
    r = math.hypot(x_m, y_m)
    n = Vector((x_m / r, y_m / r, 0.0))
    e = Vector((y_m / r, -x_m / r, 0.0))
    a, b = math.radians(az), math.radians(el)
    return ((n * math.cos(a) + e * math.sin(a)) * math.cos(b) + Vector((0, 0, math.sin(b)))).normalized()


def add_sun(vec, strength=5.0):
    sun = add_light("SUN", (0, 0, 10), strength, (1.0, 1.0, 1.0), size=math.radians(0.53), name="Sun")
    sun.rotation_euler = (-vec).to_track_quat("-Z", "Y").to_euler()
    return sun


def scene_row(scene_id):
    rows = json.loads((LOLA / "sun_positions.json").read_text())["scene_lighting"]
    return next(r for r in rows if r["scene"] == scene_id)


ROCKS = []


def scatter_rocks(near, z_at, seed, count=260, avoid=()):
    """M1-35 rock kit instances (power-law sizes), resting on the ground; none inside the avoid circles."""
    if not ROCKS:
        for k in range(1, 17):
            form = ["Chip", "Shard", "Block", "Slab"][(k - 1) % 4]
            path = ROOT / f"game/assets/environment/terrain/rocks/EN_LunarRock_{k:02d}_{form}_LOD0.glb"
            before = set(bpy.data.objects)
            bpy.ops.import_scene.gltf(filepath=str(path))
            new = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
            for o in new:
                o.hide_render = True
                o.location = (0, 0, -1000)
                for m in o.data.materials:
                    if m and m.node_tree:
                        bsdf = m.node_tree.nodes.get("Principled BSDF")
                        if bsdf is not None:
                            bsdf.inputs["Roughness"].default_value = 1.0
                ROCKS.append(o)
    rng = np.random.default_rng(seed)
    placed = []
    for _ in range(count):
        src = ROCKS[int(rng.integers(len(ROCKS)))]
        x, y = rng.uniform(-near / 2 * 0.9, near / 2 * 0.9, 2)
        if any(math.hypot(x - ax, y - ay) < ar for ax, ay, ar in avoid):
            continue
        dim = max(src.dimensions)
        target = float(np.clip(rng.pareto(2.2) * 0.12 + 0.05, 0.05, 1.4))
        o = bpy.data.objects.new(src.name + "_i", src.data)
        bpy.context.scene.collection.objects.link(o)
        s = target / max(dim, 1e-3)
        o.scale = (s, s, s)
        o.rotation_euler = (rng.uniform(-0.3, 0.3), rng.uniform(-0.3, 0.3), rng.uniform(0, 6.28))
        o.location = (x, y, z_at(x, y) - target * 0.25)
        placed.append(o)
    return placed


def import_glb(path, loc=(0, 0, 0), rot_z=0.0, scale=1.0):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    new = [o for o in bpy.data.objects if o not in before]
    roots = [o for o in new if o.parent is None]
    holder = bpy.data.objects.new(Path(path).stem + "_holder", None)
    bpy.context.scene.collection.objects.link(holder)
    for r in roots:
        r.parent = holder
    holder.location = Vector(loc)
    holder.rotation_euler = (0, 0, rot_z)
    holder.scale = (scale, scale, scale)
    return holder, new


def screen_image(name, rgb):
    """A small text-free picture for a live-screen slot in the renders (maps, colour blocks); no words, no numbers."""
    h, w = rgb.shape[:2]
    im = bpy.data.images.new(name, width=w, height=h)
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[:, :, :3] = np.clip(rgb, 0, 1)
    im.pixels.foreach_set(np.ascontiguousarray(np.flipud(rgba)).ravel())
    return im


def emissive_image_material(mat_name, image, strength=1.2):
    mat = bpy.data.materials.get(mat_name)
    if mat is None:
        return
    t = mat.node_tree
    bsdf = t.nodes["Principled BSDF"]
    tex = t.nodes.new("ShaderNodeTexImage")
    tex.image = image
    t.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
    t.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Emission Strength"].default_value = strength


def ui_pictures():
    """Text-free stand-ins for the live UI in the room renders: the cold-trap hillshade with the road and the three
    beacon dots (route board and console map), a slope ramp (slope card), role-colour roster blocks (departure
    boards). The game draws the real UI with words at runtime."""
    f = Field("cold_trap", 10, False)
    n = 256
    xs = np.linspace(-8225 + 50, -225 - 50, n)
    ys = np.linspace(-7975 - 50, -15965 + 50, n)
    X, Y = np.meshgrid(xs, ys)
    hgt = f.sample(X, Y)
    gy, gx = np.gradient(hgt)
    shade = np.clip(0.55 + (gx - gy) * 0.02, 0, 1)
    rgb = np.stack([shade * 0.25, shade * 0.38, shade * 0.52], axis=-1)
    survey = json.loads((STAGE / "coldtrap_survey.json").read_text())
    for p in survey["polyline_every_100m"]:
        c, r = int((p[0] - xs[0]) / (xs[1] - xs[0])), int((p[1] - ys[0]) / (ys[1] - ys[0]))
        if 0 <= c < n and 0 <= r < n:
            rgb[max(0, r - 1):r + 2, max(0, c - 1):c + 2] = (0.95, 0.42, 0.13)
    for bcn in survey["beacons"]:
        c, r = int((bcn["x_m"] - xs[0]) / (xs[1] - xs[0])), int((bcn["y_m"] - ys[0]) / (ys[1] - ys[0]))
        if 0 <= c < n and 0 <= r < n:
            rgb[max(0, r - 3):r + 4, max(0, c - 3):c + 4] = (0.3, 1.0, 0.45)
    route = screen_image("UI_RouteMap", rgb)
    ramp = np.zeros((64, 128, 3))
    ramp[:, :, 0] = np.linspace(0.1, 0.9, 128)[None, :]
    ramp[:, :, 1] = np.linspace(0.6, 0.3, 128)[None, :]
    ramp[:, :, 2] = 0.25
    ramp[28:36, :, :] = 0.9
    slope = screen_image("UI_SlopeCard", ramp)
    roster = np.full((192, 120, 3), 0.06)
    for k, col in enumerate(((0.95, 0.42, 0.13), (0.13, 0.72, 0.79), (0.30, 0.69, 0.31), (0.56, 0.36, 0.76), (0.72, 0.63, 0.42))):
        roster[30 + k * 30: 52 + k * 30, 12:28] = col
        roster[34 + k * 30: 48 + k * 30, 36:108] = 0.55
    roster[8:20, 12:108] = (0.2, 0.5, 0.9)
    board = screen_image("UI_Departure", roster)
    pad = np.full((64, 96, 3), 0.05)
    pad[40:, :] = 0.18
    pad[30:42, 40:56] = 0.55
    padcam = screen_image("UI_PadCam", pad)
    lock = np.full((32, 64, 3), (0.05, 0.25, 0.10))
    return dict(Screen=route, Screen2=slope, Screen3=padcam, Departure=board, Lock=screen_image("UI_Lock", lock))

# ----------------------------------------------------------------------------------------------- the garage (LOC-08)

GARAGE_BEARING_DEG = 100.0   # azimuth the rover door faces (decision 3); the Sun at EX-CH04-S02 is az 59.8, el 1.8
GARAGE_SITE = (80.0, 150.0)  # (distance m, azimuth deg) from Aurora's site origin, on the courtyard edge


def garage_layout():
    """Room-frame placements (Godot x right, y up, z from the ready room's back wall into the bay), 12 x 9 m."""
    P = []

    def put(pid, x, y, z, yaw=0.0, role=""):
        P.append(dict(piece=pid, position=[x, y, z], yaw=yaw, role=role))
    D = DECK_Y
    for x in range(12):
        for z in range(3):
            put("EN_Kit_FloorTile", x + 0.5, D - 0.06, z + 0.5)
            put("EN_Kit_CeilingTile", x + 0.5, D + WALL_H, z + 0.5)
    # pressure wall (z = 3), room face towards the ready room
    put("EN_Kit_Wall_Corner", 0, D, 3, -90)
    put("EN_Garage_SuitSealPanel", 1.0, D, 3, 0, "suit_seals")
    put("EN_Garage_CargoLock", 2.0, D, 3, 0, "cargo_lock")
    put("EN_Garage_BayWindow", 3.5, D, 3, 0, "window_porch")
    put("EN_Garage_BayWindow", 5.5, D, 3, 0, "window_rover")
    put("EN_Kit_Wall_Window", 7.0, D, 3, 0)
    put("EN_Garage_DockingPort", 8.5, D, 3, 0, "docking_port")
    put("EN_Garage_BayWindow", 10.5, D, 3, 0, "window_door")
    put("EN_Kit_Wall_Corner", 12, D, 3, 0)
    # back wall (z = 0), faces into the room
    put("EN_Kit_Wall_Corner", 0, D, 0, 180)
    put("EN_Kit_DoorFrame", 2.0, D, 0, 180, "inner_door")
    put("EN_Garage_RouteBoard", 4.5, D, 0, 180, "route_board")
    put("EN_Garage_DepartureBoard", 6.0, D, 0, 180, "departure_a")
    put("EN_Garage_DepartureBoard", 7.0, D, 0, 180, "departure_b")
    for x in (8.0, 9.0, 10.0):
        put("EN_Kit_Wall_Straight", x, D, 0, 180)
    put("EN_Kit_Wall_EquipBay", 11.0, D, 0, 180, "pad_camera_bay")
    put("EN_Kit_Wall_Corner", 12, D, 0, 90)
    # end walls
    put("EN_Kit_Wall_Straight", 0, D, 1.0, -90)
    put("EN_Kit_Wall_EquipBay", 0, D, 2.0, -90)
    put("EN_Kit_Wall_Straight", 12, D, 1.0, 90)
    put("EN_Kit_Wall_Straight", 12, D, 2.0, 90)
    # furniture
    put("EN_Garage_HandoverConsole", 8.5, D, 0.15 + CONSOLE_D / 2 + 0.02, 180, "handover_console")
    put("EN_Garage_ReliefLocker", 10.0, D, 0.15 + LOCKER_D / 2 + 0.02, 180, "relief_locker")
    put("EN_Garage_CargoRack", 12 - 0.15 - RACK_D / 2 - 0.02, D, 1.5, 90, "cargo_rack")
    for x in (1.5, 4.5, 7.5, 10.5):
        put("EN_Kit_LightStrip", x, D + WALL_H - 0.08, 1.5)
    # the vacuum bay
    zb = 3.0 + WALL_D
    for x in (1, 3, 5, 7, 9, 11):
        put("EN_Garage_BayFrame", x, 0, zb)
    put("EN_Garage_BayEndWall", 0, 0, zb + BAY_D / 2, -90)
    put("EN_Garage_BayDoor", 12, 0, zb + BAY_D / 2, 90, "rover_door")
    put("EN_Garage_EVAPorch", 0, 0, zb, 0, "eva_porch")
    put("EN_Garage_Umbilical", 10.9, 0, zb + 0.45, 0, "umbilical")
    rover = dict(centre=[6.7, 0.0, zb + TUNNEL_L + 1.42], front="+x", length_m=6.0, track_m=4.66, hatch=[8.5, DECK_Y + DOCK_SILL, zb + TUNNEL_L])
    anchors = dict(player=[4.2, D, 1.6], amara_handover=[8.5, D, 1.25], mei_handover=[6.5, D, 1.4], rafi_rover_slot=[8.5, D, 2.5],
                   kai_rover_slot=[7.6, D, 2.4], suit_seals=[1.0, D, 2.4], cargo_lock_room=[2.0, D, 2.2], porch_eva=[2.2, D, zb + 2.5],
                   rover_door_apron=[13.5, 0.0, zb + BAY_D / 2], route_board=[4.5, D, 0.9], departure_boards=[6.5, D, 1.0], relief_locker=[10.0, D, 1.3], pad_camera_bay=[11.0, D, 0.9])
    return dict(bounds_m=[12.0, 9.0], deck_y=D, bay_floor_y=0.0, bay_clear_height_m=BAY_H, ready_room=dict(x=[0, 12], z=[0, 3], pressure="habitat"),
                bay=dict(x=[0, 12], z=[zb, zb + BAY_D], pressure="vacuum"), placements=P, rover=rover, anchors=anchors,
                connections={"inner_door": "pressurised corridor to the habitat (decision 2)", "rover_door": "apron and the marked path to LOC-06 (courtyard), the roads to LOC-09 and LOC-11",
                             "docking_port": "VH_Rover cabin", "cargo_lock": "EVA porch (vacuum side)"})


KIT_TEMPLATES = {}


def kit_template(pid, table):
    if pid not in KIT_TEMPLATES:
        spec = next(s for s in hk.PIECES if s["id"] == pid)
        root, objs = hk.build_piece(spec, 0, hk.make_materials(load_kit_images())[0] if False else KIT_TABLE[0])
        bpy.context.view_layer.update()
        hk.bake_blender_space(objs)
        for o in objs:
            if o.name.endswith(hk.COL_SUFFIXES):
                o.hide_render = True
        root.location = (0, 0, -500)
        KIT_TEMPLATES[pid] = (root, objs)
    return KIT_TEMPLATES[pid]


KIT_TABLE = {}


def build_garage(table, origin=Vector((0, 0, 0)), yaw_deg=0.0, rover=True):
    """Assemble the garage under one empty (Godot room frame -> Blender), return (holder, roles, layout)."""
    layout = garage_layout()
    mounts = {s["id"]: s["mount_y"] for s in hk.PIECES}
    holder = bpy.data.objects.new("Garage", None)
    bpy.context.scene.collection.objects.link(holder)
    templates = {}
    roles = {}
    for pl in layout["placements"]:
        pid = pl["piece"]
        if pid.startswith("EN_Kit_"):
            tpl = kit_template(pid, table)
        else:
            if pid not in templates:
                spec = next(s for s in ALL_PIECES if s["id"] == pid)
                templates[pid] = build_piece(spec, table)
                templates[pid][0].location = (0, 0, -500)
            tpl = templates[pid]
        r, objs = instance(tpl, holder)
        x, y, z = pl["position"]
        y = y + (mounts.get(pid, 0.0) if pid.startswith("EN_Kit_") and pid not in ("EN_Kit_FloorTile", "EN_Kit_CeilingTile", "EN_Kit_LightStrip") else 0.0)
        place(r, x, y, z, pl["yaw"])
        roles.setdefault(pl["role"] or pid, []).append((r, objs))
    # sintered plinth under the ready room, the floor markings and the wheel guide
    sint = table["Sintered"][0]
    for (cx, cy, cz, sx, sy, sz) in ((6.0, DECK_Y / 2 - 0.06, 1.5, 12.3, DECK_Y - 0.12, 3.30),):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(cx, -cz, cy))
        o = bpy.context.object
        o.scale = (sx, sz, sy)
        o.data.materials.append(sint)
        o.parent = holder
    orange = table["PaintOrange"][0]
    zb = 3.0 + WALL_D
    stall = [(3.5, 10.0, zb + 0.30, 0.08), (3.5, 10.0, zb + BAY_D - 0.70, 0.08)]
    for x0, x1, z, w in stall:
        bpy.ops.mesh.primitive_cube_add(size=1, location=((x0 + x1) / 2, -z, 0.003))
        o = bpy.context.object
        o.scale = (x1 - x0, w, 0.006)
        o.data.materials.append(orange)
        o.parent = holder
    for k in range(9):
        x = 3.6 + 0.8 * k
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -(zb + 0.18), 0.003))
        o = bpy.context.object
        o.scale = (0.4, 0.12, 0.006)
        o.data.materials.append(table["PaintWhite"][0])
        o.parent = holder
    rover_obj = None
    if rover:
        c = layout["rover"]["centre"]
        rh, new = import_glb(ROOT / "game/assets/vehicles/VH_Rover/VH_Rover.glb", (c[0], -c[2], 0.0), math.radians(90))
        rh.parent = holder
        rover_obj = rh
        # cargo mount on the rear rack and the docked collar extension
        spec = next(s for s in ALL_PIECES if s["id"] == "PR_RoverCargoMount")
        r, objs = build_piece(spec, table)
        r.parent = holder
        place(r, c[0] - 2.45, 2.28, c[2], 90)
    holder.location = origin
    holder.rotation_euler = (0, 0, math.radians(yaw_deg))
    return holder, roles, layout, rover_obj


def interior_lights(holder, bay=True, ready=True):
    """Ready room: warm 3,500 K strips (ART_BIBLE section 4 living-space practicals). Bay: neutral 5,000 K LED floods
    and the rover's work lights. Lights are in the room frame (Godot), converted here."""
    lights = []

    def L(kind, gx, gy, gz, energy, color, size=None, target=None, spot=None):
        loc = holder.matrix_world @ Vector((gx, -gz, gy))
        tgt = None if target is None else holder.matrix_world @ Vector((target[0], -target[2], target[1]))
        lights.append(add_light(kind, loc, energy, color, target=tgt, size=size, spot=spot, name="GarageLight"))
    if ready:
        for x in (1.5, 4.5, 7.5, 10.5):
            L("AREA", x, DECK_Y + WALL_H - 0.10, 1.5, 70, (1.0, 0.84, 0.68), size=0.9, target=(x, 0, 1.5))
    if bay:
        zb = 3.0 + WALL_D
        for x in (1, 3, 5, 7, 9, 11):
            L("AREA", x, BAY_H - 0.56, zb + BAY_D / 2, 260, (0.93, 0.95, 1.0), size=0.6, target=(x, 0, zb + BAY_D / 2))
    return lights


def screens_on(pics):
    emissive_image_material("Screen", pics["Screen"], 1.4)
    emissive_image_material("Screen2", pics["Screen2"], 1.2)
    emissive_image_material("Screen3", pics["Screen3"], 1.0)


def run_garage(table):
    """Three garage views: the measured cutaway (neutral studio), the bay seen from the EVA porch through the open
    rover door to the sunlit apron (photoreal, EX-CH04-S02's dated Sun), and the ready room looking through the
    windows and the docking hatch (photoreal practicals)."""
    scene = setup_cycles(SAMPLES, 1600, 900)
    pics = ui_pictures()
    screens_on(pics)
    # exterior: the garage on the Aurora ridge; scene origin = the garage site
    sx, sy = 0.0, 0.0
    sites = json.loads((ROOT / "production/terrain/sites.json").read_text())["sites"]
    a = sites["aurora"]
    nvec = Vector((a["x_m"], a["y_m"], 0)).normalized()
    evec = Vector((nvec.y, -nvec.x, 0))
    dist, az = GARAGE_SITE
    site_xy = Vector((a["x_m"], a["y_m"], 0)) + (nvec * math.cos(math.radians(az)) + evec * math.sin(math.radians(az))) * dist
    gx, gy = site_xy.x, site_xy.y
    h0 = float(height_map(np.array([gx]), np.array([gy]))[0])
    # door bearing -> Blender yaw: the room's +x (door direction) must point along azimuth GARAGE_BEARING_DEG
    door_dir = nvec * math.cos(math.radians(GARAGE_BEARING_DEG)) + evec * math.sin(math.radians(GARAGE_BEARING_DEG))
    yaw = math.degrees(math.atan2(door_dir.y, door_dir.x))
    holder_origin = Vector((0, 0, 0))

    def pad_edit(X, Y, Z):
        # graded apron: level at the garage floor inside the footprint + 25 m in front, blended over 12 m
        rot = Matrix.Rotation(-math.radians(yaw), 3, "Z")
        lx = X * rot[0][0] + Y * rot[0][1]
        ly = X * rot[1][0] + Y * rot[1][1]
        inside = np.maximum(np.maximum(-3 - lx, lx - 40), np.maximum(-(ly + 13), ly - 4))
        w = np.clip(1 - inside / 12.0, 0, 1)
        w = w * w * (3 - 2 * w)
        out = Z * (1 - w) + 0.0 * w
        for off in (-2.15, 2.15):
            u = (ly + 6.07 - off) / 0.21
            out = out + np.where((np.abs(u) < 1) & (lx > 11.8), -0.03 * (1 - u ** 2), 0.0)
        return out
    build_terrain(gx, gy, h0, near=160.0, step=0.25, mid=3000.0, mstep=6.0, far=40000.0, fstep=100.0, seed=SEED + 2, edits=pad_edit)
    holder, roles, layout, rover = build_garage(table, holder_origin, yaw)
    # regolith berm over the garage (1 m overburden, 35 deg sides), the door portal left clear
    berm = build_berm(table, holder)
    row = scene_row("EX-CH04-S02")
    sun = add_sun(sun_vector(gx, gy, row["sun_az_deg"], row["sun_el_deg"]), 30.0)
    world_color((0, 0, 0), 0.0)
    clear_glass()
    lights = interior_lights(holder)
    door = roles["rover_door"][0][1]
    panel = child(door, "DoorPanel")
    panel.scale.z, panel.location.z = 0.04, panel.location.z + DOOR_OPEN_H * 0.96
    xdir = holder.matrix_world.to_3x3() @ Vector((1, 0, 0))
    back = holder.matrix_world.to_3x3() @ Vector((0, 1, 0))

    def G(x, y, z):
        return holder.matrix_world @ Vector((x, -z, y))
    terrain_tree = None

    def z_at(wx, wy):
        nonlocal terrain_tree
        from mathutils.bvhtree import BVHTree
        if terrain_tree is None:
            terrain_tree = BVHTree.FromObject(bpy.data.objects["TerrainNear"], bpy.context.evaluated_depsgraph_get())
        hit = terrain_tree.ray_cast(Vector((wx, wy, 500.0)), Vector((0, 0, -1)))
        return hit[0].z if hit[0] is not None else 0.0
    # Aurora's habitat module and solar mast where M1-82 stages them (LOC-06), and the marked path's markers
    aurora_off = Vector((a["x_m"] - gx, a["y_m"] - gy, 0))
    for path, off in ((ROOT / "game/assets/environment/EN_ExteriorModule/EN_ExteriorModule.glb", (0.0, 8.0)), (ROOT / "game/assets/environment/EN_SolarMast/EN_SolarMast.glb", (-8.0, 6.0))):
        wx, wy = aurora_off.x + off[0], aurora_off.y + off[1]
        import_glb(path, (wx, wy, z_at(wx, wy) - 0.3))
    marker = next(sp for sp in ALL_PIECES if sp["id"] == "EN_ColdTrap_ReturnMarker")
    mtpl = build_piece(marker, table)
    mtpl[0].location = (0, 0, -900)
    for k in range(6):
        for side in (-1, 1):
            gp = G(16.0 + 7.0 * k, 0.0, 6.07 + side * 3.6)
            r, _ = instance(mtpl)
            hide_tree(r, False)
            r.location = (gp.x, gp.y, z_at(gp.x, gp.y))
    figs = [figure(G(2.2, DECK_Y, 5.75), face(xdir.x, xdir.y), suited=True, name="FigPorch")]
    # 1. into the bay from the apron through the open rover door: the docked rover, the warm ready-room windows
    camera_at(G(17.5, 1.75, 7.9), G(3.0, 2.4, 4.4), lens=20)
    scene.view_settings.exposure = 0.3
    render("EN_Garage_view_bay")
    # 2. exterior: the rover rolled out onto the apron (EX-CH04-S02 departure), seen from the marked path
    home = rover.location.copy()
    out = G(17.5, 0.0, 6.07)
    rover.location = (17.5, -6.07, z_at(out.x, out.y) - 0.02 - holder.location.z)
    camera_at(G(44.0, 3.6, 0.5), G(11.0, 2.7, 6.2), lens=28)
    scene.view_settings.exposure = 0.0
    render("EN_Garage_view_exterior")
    rover.location = home
    # 3. the ready room towards the windows and the docking hatch (hatch open)
    dock = roles["docking_port"][0][1]
    child(dock, "HatchLeaf").rotation_euler = (0, 0, math.radians(100))
    figs.append(figure(G(8.5, DECK_Y, 1.3), face(back.x, back.y), name="FigAmara"))
    camera_at(G(1.2, DECK_Y + 1.62, 0.55), G(8.8, DECK_Y + 1.35, 2.9), lens=18)
    scene.view_settings.exposure = 0.4
    render("EN_Garage_view_ready")
    child(dock, "HatchLeaf").rotation_euler = (0, 0, 0)
    # 4. cutaway: roof, far wall, door wall, ceiling, berm and terrain hidden; neutral studio light
    for o in [berm] + [o for o in bpy.data.objects if o.name.startswith(("Terrain", "EN_ExteriorModule", "EN_SolarMast", "EN_ColdTrap_ReturnMarker"))]:
        o.hide_render = True
    for o in bpy.data.objects:
        if o.parent is not None and o.parent.name.startswith(("EN_ExteriorModule", "EN_SolarMast")):
            o.hide_render = True
    for pl_role in ("EN_Kit_CeilingTile", "EN_Kit_LightStrip", "rover_door"):
        for r, objs in roles.get(pl_role, []):
            hide_tree(r, True)
    for r, objs in roles.get("EN_Garage_BayFrame", []):
        for o in objs:
            if o.type == "MESH":
                o.hide_render = True
    for o in holder.children:
        if o.type == "MESH" and ((o.name.startswith("Cube") and o.matrix_world.translation.z > 3.0) or o.name.startswith("WingWall")):
            o.hide_render = True
    cutaway_bay(table, holder)
    sun.hide_render = True
    for lt in lights:
        lt.hide_render = True
    world_color((0.50, 0.51, 0.53), 0.9)
    key = add_light("SUN", (0, 0, 20), 2.6, size=math.radians(4), name="CutSun")
    key.rotation_euler = (holder.matrix_world.to_3x3() @ Vector((-0.35, 0.5, -1.0))).to_track_quat("-Z", "Y").to_euler()
    figs.append(figure(G(11.0, 0.0, 4.4), face(back.x, back.y), name="FigScale"))
    camera_at(G(16.5, 15.0, 17.0), G(5.6, 0.6, 3.6), lens=24)
    scene.view_settings.exposure = 0.0
    render("EN_Garage_view_cutaway")


def clear_glass():
    """Renders only: the kit's glass slot as clear glass (the game keeps its alpha material)."""
    mat = bpy.data.materials.get("M_Kit_Glass")
    if mat is None:
        return
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Alpha"].default_value = 1.0
    bsdf.inputs["Base Color"].default_value = (1, 1, 1, 1)
    bsdf.inputs["Transmission Weight"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.0
    bsdf.inputs["IOR"].default_value = 1.5


def build_berm(table, holder):
    """Regolith overburden on the garage: a 1 m layer over the roof and 35 deg sides down to the apron (shielding,
    thermal mass, micrometeoroid cover), clear of the rover door's portal. A grid mesh in the room frame."""
    mat = bpy.data.materials.get("M_Regolith") or regolith_material()
    xs = np.linspace(-9, 21, 151)
    zs = np.linspace(-9, 18, 136)
    X, Z = np.meshgrid(xs, zs)
    top = BAY_H + 1.0
    dx = np.maximum(np.maximum(-0.2 - X, X - 12.2), 0)
    dz = np.maximum(np.maximum(-0.4 - Z, Z - 9.3), 0)
    d = np.hypot(dx, dz)
    Y = np.clip(top - d * math.tan(math.radians(35)), -0.5, top)
    rng = np.random.default_rng(SEED + 9)
    Y = Y + 0.06 * fractal2d(rng, 256, 3, 60, 2.0)[: Y.shape[0], : Y.shape[1]] * (Y > 0)
    door = (X > 11.5) & (Z > 2.9) & (Z < 9.5)
    verts = []
    for j in range(len(zs)):
        for i in range(len(xs)):
            verts.append((xs[i], -zs[j], Y[j, i]))
    nx = len(xs)
    faces = []
    for j in range(len(zs) - 1):
        for i in range(nx - 1):
            if door[j, i] and xs[i] >= 12.0:
                continue
            faces.append((j * nx + i, j * nx + i + 1, (j + 1) * nx + i + 1, (j + 1) * nx + i))
    mesh = bpy.data.meshes.new("Berm")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(mat)
    for p in mesh.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new("Berm", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = holder
    # wing walls: wedges along the door band's edges, holding the berm back from the apron
    run = (BAY_H + 1.0) / math.tan(math.radians(35)) + 0.4
    for zw in (2.9, 9.5):
        verts, faces = [], []
        for dz in (-0.2, 0.2):
            verts += [(12.0, -(zw + dz), 0.0), (12.0 + run, -(zw + dz), 0.0), (12.0, -(zw + dz), BAY_H + 1.0)]
        faces = [(0, 1, 2), (3, 5, 4), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)]
        m = bpy.data.meshes.new("WingWall")
        m.from_pydata(verts, [], faces)
        m.materials.append(table["Sintered"][0])
        w = bpy.data.objects.new("WingWall", m)
        bpy.context.scene.collection.objects.link(w)
        w.parent = holder
    # sintered headwall round the rover door, holding the berm back from the opening
    sint = table["Sintered"][0]
    for (x0, x1, z0, z1, y0, y1) in ((12.0, 12.45, -0.6, 3.25, 0.0, BAY_H + 1.0), (12.0, 12.45, 8.95, 9.9, 0.0, BAY_H + 1.0), (12.0, 12.45, 3.25, 8.95, DOOR_OPEN_H + 0.70, BAY_H + 1.0)):
        bpy.ops.mesh.primitive_cube_add(size=1, location=((x0 + x1) / 2, -(z0 + z1) / 2, (y0 + y1) / 2))
        o = bpy.context.object
        o.scale = (x1 - x0, z1 - z0, y1 - y0)
        o.data.materials.append(sint)
        o.parent = holder
    return obj


def cutaway_bay(table, holder):
    """For the cutaway only: the bay's floor and far wall without the roof, so the layout reads from above."""
    objs = []
    zb = 3.0 + WALL_D
    for (cx, cy, cz, sx, sy, sz, key) in ((6.0, -0.03, zb + BAY_D / 2, 12.0, 0.06, BAY_D, "Sintered"),):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(cx, -cz, cy))
        o = bpy.context.object
        o.scale = (sx, sz, sy)
        o.data.materials.append(table[key][0])
        o.parent = holder
        objs.append(o)
    return objs

# ----------------------------------------------------------------------------------------------- the cold trap (LOC-09, LOC-10)

def smooth_road(points, x0, y0, passes=3):
    """The survey's 20 m road cells as a smooth local polyline (Chaikin), Blender frame around (x0, y0)."""
    p = np.array([[q[0] - x0, q[1] - y0] for q in points], dtype=float)
    for _ in range(passes):
        q = 0.75 * p[:-1] + 0.25 * p[1:]
        r = 0.25 * p[:-1] + 0.75 * p[1:]
        p = np.vstack([p[:1], np.column_stack([q, r]).reshape(-1, 2), p[-1:]])
    return p


def track_edit(road, half_track=2.15, width=0.42, depth=0.035):
    """Rover ruts along the road (two tracks, 4.3 m apart on VH_Rover's wheels), a few centimetres deep with low
    berms: crisp, because nothing blows them away in vacuum."""
    def edit(X, Y, Z):
        out = Z.copy()
        pts = road
        best = np.full(X.shape, 1e9)
        side = np.zeros(X.shape)
        for a, b in zip(pts[:-1], pts[1:]):
            ab = b - a
            L2 = float(ab @ ab) + 1e-9
            t = np.clip(((X - a[0]) * ab[0] + (Y - a[1]) * ab[1]) / L2, 0, 1)
            px, py = a[0] + t * ab[0], a[1] + t * ab[1]
            d = np.hypot(X - px, Y - py)
            cross = (ab[0] * (Y - a[1]) - ab[1] * (X - a[0])) / math.sqrt(L2)
            m = d < best
            best = np.where(m, d, best)
            side = np.where(m, cross, side)
        for off in (-half_track, half_track):
            u = (side - off) / (width / 2)
            rut = np.where(np.abs(u) < 1, -depth * (1 - u ** 2), 0.0)
            berm = np.where((np.abs(u) >= 1) & (np.abs(u) < 2.2), 0.012 * np.exp(-((np.abs(u) - 1.4) / 0.4) ** 2), 0.0)
            out = out + rut + berm
        smooth = np.where(np.abs(side) < half_track + 1.0, 1.0, 0.0)
        return out * (1 - 0.3 * smooth) + (Z * 0.0 + Z) * 0.3 * smooth
    return edit


def place_on_ground(obj_root, x, y, z_at, yaw_deg=0.0, dz=0.0):
    obj_root.location = (x, y, z_at(x, y) + dz)
    obj_root.rotation_euler = (0, 0, math.radians(yaw_deg))


def road_heading(road, i):
    a, b = road[max(0, i - 2)], road[min(len(road) - 1, i + 2)]
    return math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))


def nearest_index(road, x, y):
    return int(np.argmin(np.hypot(road[:, 0] - x, road[:, 1] - y)))


def run_coldtrap(table):
    survey = json.loads((STAGE / "coldtrap_survey.json").read_text())
    scene = setup_cycles(SAMPLES, 1600, 900)
    world_color((0, 0, 0), 0.0)
    shots = [("B2", "EX-CH04-S04", "sunlit"), ("B3", "EX-CH04-S04", "dark"), ("shelf", "EX-CH04-S06", "dark")]
    only = {a for a in ARGS if a.startswith("shot=")}
    for key, scene_id, mood in shots:
        if only and f"shot={key}" not in only:
            continue
        for o in list(bpy.data.objects):
            if o not in ROCKS:
                bpy.data.objects.remove(o)
        bpy.context.scene.camera = None
        render_coldtrap_shot(table, survey, key, scene_id, mood)


def render_coldtrap_shot(table, survey, key, scene_id, mood):
    scene = bpy.context.scene
    row = scene_row(scene_id)
    pts = survey["polyline_every_100m"]
    full_road = json.loads((STAGE / "coldtrap_survey.json").read_text())
    if key == "shelf":
        sh = survey["vault_shelf"]
        x0, y0 = sh["x_m"], sh["y_m"]
    else:
        bcn = next(b for b in survey["beacons"] if b["id"] == key)
        x0, y0 = bcn["x_m"], bcn["y_m"]
    h0 = float(height_map(np.array([x0]), np.array([y0]))[0])
    road = smooth_road(survey["road_cells_20m"], x0, y0)
    road = road[np.hypot(road[:, 0], road[:, 1]) < 400]
    edits = track_edit(road) if key != "shelf" else shelf_edit()
    terrain = build_terrain(x0, y0, h0, near=140.0, step=0.25, mid=3600.0, mstep=6.0, far=56000.0, fstep=160.0, seed=SEED + {"B2": 11, "B3": 13, "shelf": 17}[key], edits=edits)
    near = terrain[0]

    def z_at(x, y):
        # height of the near mesh surface (ray cast straight down)
        from mathutils.bvhtree import BVHTree
        if not hasattr(z_at, "tree"):
            z_at.tree = BVHTree.FromObject(near, bpy.context.evaluated_depsgraph_get())
        hit = z_at.tree.ray_cast(Vector((x, y, 500.0)), Vector((0, 0, -1)))
        return hit[0].z if hit[0] is not None else ground_z(x0, y0, h0, x, y)
    sun_vec = sun_vector(x0, y0, row["sun_az_deg"], row["sun_el_deg"])
    sun = add_sun(sun_vec, 22.0)
    pieces = {}

    def piece(pid):
        spec = next(s for s in ALL_PIECES if s["id"] == pid)
        if pid not in pieces:
            pieces[pid] = build_piece(spec, table)
            pieces[pid][0].location = (0, 0, -900)
        r, objs = instance(pieces[pid])
        hide_tree(r, False)
        return r, objs
    set_retro_boost(0.0 if mood == "sunlit" else 3.0)
    avoid = []
    if key in ("B2", "B3"):
        i = nearest_index(road, 0, 0)
        hd = road_heading(road, i)
        hrad = math.radians(hd)
        fwd = Vector((math.cos(hrad), math.sin(hrad), 0))
        left = Vector((-fwd.y, fwd.x, 0))
        bpos = left * 5.2
        r, _ = piece("EN_ColdTrap_BeaconMast")
        place_on_ground(r, bpos.x, bpos.y, z_at, hd)
        rp = fwd * 9 + left * 4.0
        r, _ = piece("EN_ColdTrap_ReturnMarker")
        place_on_ground(r, rp.x, rp.y, z_at, hd)
        sp = fwd * 16 - left * 4.2
        r, _ = piece("EN_ColdTrap_SlopeSign")
        place_on_ground(r, sp.x, sp.y, z_at, hd + 180)
        rover_at = -fwd * 14.0
        rh, _ = import_glb(ROOT / "game/assets/vehicles/VH_Rover/VH_Rover.glb", (rover_at.x, rover_at.y, z_at(rover_at.x, rover_at.y) - 0.05), math.radians(hd + 90))
        f1 = bpos - fwd * 1.0 - left * 1.2
        figure((f1.x, f1.y, z_at(f1.x, f1.y)), face(*(bpos - f1).xy), suited=True, lamp=(mood == "dark"), name="FigRafi")
        f2 = bpos - fwd * 2.4 - left * 3.4
        figure((f2.x, f2.y, z_at(f2.x, f2.y)), face(*(bpos - f2).xy), suited=True, lamp=(mood == "dark"), name="FigKai")
        avoid = [(bpos.x, bpos.y, 3.0), (rover_at.x, rover_at.y, 6.0), (rp.x, rp.y, 1.5), (sp.x, sp.y, 1.5)] + [(float(q[0]), float(q[1]), 3.2) for q in road[::2]]
        headlights(rh, mood)
        cam = rover_at - fwd * 3.0 - left * 7.5 if mood == "sunlit" else rover_at + fwd * 3.5 - left * 6.0
        tgt = bpos + fwd * (10.0 if mood == "sunlit" else 4.0)
        camera_at((cam.x, cam.y, z_at(cam.x, cam.y) + 1.8), (tgt.x, tgt.y, z_at(tgt.x, tgt.y) + 2.2), lens=24)
    else:
        avoid = shelf_props(piece, z_at)
        cam = Vector((-1.2, -6.4, 0))
        camera_at((cam.x, cam.y, z_at(cam.x, cam.y) + 1.45), (0.4, 0.6, z_at(0.4, 0.6) + 0.55), lens=28)
    scatter_rocks(140.0, z_at, SEED + 31, count=900, avoid=avoid)
    scene.view_settings.exposure = 0.15 if mood == "sunlit" else 0.2
    render(f"EN_ColdTrap_view_{key}")
    if key == "B2":
        cam = -fwd * 45.0 - left * 30.0
        camera_at((cam.x, cam.y, z_at(cam.x, cam.y) + 18.0), (fwd.x * 15, fwd.y * 15, z_at(fwd.x * 15, fwd.y * 15) + 1.0), lens=28)
        render("EN_ColdTrap_view_B2_high")


def headlights(rover_holder, mood):
    """VH_Rover's two front lamps and a roof work light as spot lights (no visible beams: vacuum)."""
    m = rover_holder.matrix_world
    power = {"dark": 4500, "shelf": 3000}.get(mood, 600)
    for sx in (-0.55, 0.55):
        lt = add_light("SPOT", m @ Vector((sx, -3.05, 1.25)), power, (1.0, 0.97, 0.92), target=m @ Vector((sx * 3, -30, 0.0)), size=0.06, spot=(55, 0.3), name="Headlight")
    add_light("SPOT", m @ Vector((0.0, -1.6, 4.05)), power * 0.8, (1.0, 0.98, 0.95), target=m @ Vector((0, -18, 0)), size=0.08, spot=(70, 0.4), name="RoofLight")


def shelf_edit():
    """LOC-10: the 20 x 15 m level shelf graded into the basin floor, with the 2034 crew's boot prints and the old
    rover tracks still crisp (twelve years with no wind and no sunlight)."""
    rng = np.random.default_rng(SEED + 77)
    prints = [(float(rng.uniform(-8, 8)), float(rng.uniform(-6, 6)), float(rng.uniform(0, 6.28))) for _ in range(70)]

    def edit(X, Y, Z):
        inside = np.maximum(np.abs(X) - 10, np.abs(Y) - 7.5)
        w = np.clip(1 - inside / 6.0, 0, 1)
        w = w * w * (3 - 2 * w)
        zc = float(Z[Z.shape[0] // 2, Z.shape[1] // 2])
        out = Z * (1 - w) + (zc + 0.25 * (Z - zc)) * w
        for px, py, a in prints:
            u = ((X - px) * math.cos(a) + (Y - py) * math.sin(a)) / 0.16
            v = (-(X - px) * math.sin(a) + (Y - py) * math.cos(a)) / 0.07
            out = out - np.where(u * u + v * v < 1, 0.012, 0.0)
        for off in (-2.15, 2.15):
            d = np.abs((X + 0.4 * Y) / math.hypot(1, 0.4) - off - 14.0)
            out = out - np.where(d < 0.2, 0.018 * (1 - (d / 0.2) ** 2), 0.0)
        return out
    return edit


def shelf_props(piece, z_at):
    """LOC-10 staging (EX-CH04-S06..S08): vault V12 where it was deposited, the 2034 marker with its archival tag, two
    tether anchors, the recovery carrier tethered beside the vault, the probe on its case, two suited cadets with helmet
    lamps (one manipulates, one assists) and the rover parked 16 m back with its lights on the shelf."""
    tpl_vault, new = import_glb(ROOT / "game/assets/props/PR_VaultCase/PR_VaultCase.glb", (0.3, 0.5, z_at(0.3, 0.5) - 0.02), math.radians(18))
    r, _ = piece("EN_ColdTrap_SurveyMarker2034")
    place_on_ground(r, 1.6, 1.4, z_at, 200)
    for ax, ay in ((-1.6, 0.9), (2.4, -0.6)):
        r, _ = piece("EN_ColdTrap_TetherAnchor")
        place_on_ground(r, ax, ay, z_at)
    r, _ = piece("PR_VaultCarrier")
    place_on_ground(r, -1.0, -0.5, z_at, 12)
    line = bpy.data.curves.new("Tether", "CURVE")
    line.dimensions = "3D"
    line.bevel_depth = 0.006
    sp = line.splines.new("BEZIER")
    sp.bezier_points.add(1)
    for k, (px, py, pz) in enumerate(((-1.6, 0.9, z_at(-1.6, 0.9) + 0.15), (-0.7, -0.3, z_at(-0.7, -0.3) + 0.55))):
        bp = sp.bezier_points[k]
        bp.co = (px, py, pz)
        bp.handle_left_type = bp.handle_right_type = "AUTO"
    tob = bpy.data.objects.new("TetherLine", line)
    tob.data.materials.append(bpy.data.materials["M_Kit_PaintOrange"])
    bpy.context.scene.collection.objects.link(tob)
    r, _ = piece("PR_VaultProbe")
    place_on_ground(r, 0.75, 0.15, z_at, 60, dz=0.0)
    figure((-1.9, 0.2, z_at(-1.9, 0.2)), face(2.0, 0.2), suited=True, lamp=True, name="FigKai")
    figure((2.6, 1.9, z_at(2.6, 1.9)), face(-2.2, -1.4), suited=True, lamp=True, name="FigRafi")
    rh, _ = import_glb(ROOT / "game/assets/vehicles/VH_Rover/VH_Rover.glb", (-12.0, -9.0, z_at(-12.0, -9.0) - 0.05), math.radians(127))
    headlights(rh, "shelf")
    return [(0.3, 0.5, 2.6), (1.6, 1.4, 1.0), (-1.0, -0.5, 1.5), (-12.0, -9.0, 6.0), (-1.9, 0.2, 1.0), (2.6, 1.9, 1.0), (0, 0, 9.0)]


if __name__ == "__main__":
    PREVIEW.mkdir(parents=True, exist_ok=True)
    for _o in list(bpy.data.objects):  # the factory startup scene (cube, light, camera)
        bpy.data.objects.remove(_o)
    TABLE = ch04_materials()
    KIT_TABLE[0] = TABLE
    if WHAT & {"layout", "garage", "all"}:
        (STAGE / "garage_layout.json").write_text(json.dumps(dict(garage_layout(), pieces={s["id"]: dict(display=s["display"], lines=s["lines"]) for s in ALL_PIECES},
                                                                     section=dict(deck_y=DECK_Y, ready_height=WALL_H, bay_height=BAY_H, berm_m=1.0, dock_sill=DOCK_SILL, dock_w=DOCK_W, dock_h=DOCK_H,
                                                                                  tunnel_l=TUNNEL_L, door=[DOOR_OPEN_W, DOOR_OPEN_H], porch_x=PORCH_X, rover_hatch_m=[1.85, 2.96])), indent=1))
    if WHAT & {"pieces", "all"}:
        run_pieces(TABLE)
    if WHAT & {"garage", "all"}:
        for _o in list(bpy.data.objects):
            bpy.data.objects.remove(_o)
        bpy.context.scene.camera = None
        run_garage(TABLE)
    if WHAT & {"coldtrap", "all"}:
        for _o in list(bpy.data.objects):
            bpy.data.objects.remove(_o)
        KIT_TEMPLATES.clear()
        bpy.context.scene.camera = None
        run_coldtrap(TABLE)
    print("CH04_BUILD_DONE", sorted(WHAT))
