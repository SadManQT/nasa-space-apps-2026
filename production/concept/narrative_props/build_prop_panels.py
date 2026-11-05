"""M3-99 narrative-prop approval panels (Blender, no AI generation, no credits).

Usage:
  blender -b --factory-startup --python build_prop_panels.py -- <out_dir> [panel ...]

Every written word comes from game-design/24_NARRATIVE_REVISION.md (§3.9,
§4 clues 2 and 12, §5.2 D10, §7.6) or STORY_FULL.md (CH01-S04: Mei presses
both names onto their holders, "two empty circles"). English only, Latin
letters, no logos. Role colours from ART_BIBLE §3.
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sheet_common as C
from build_plant_panels import lin

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
FONTS = "/System/Library/Fonts/Supplemental/"
PRINT = FONTS + "DIN Alternate Bold.ttf"
HAND = FONTS + "Bradley Hand Bold.ttf"

ROLE = {"KAI": "#F26B21", "AMARA": "#20B8C9", "MEI": "#4CAF50", "RAFI": "#8E5CC2", "FERREIRA": "#B8A06A"}


def text(body, font, size, mat, loc=(0, 0, 0), align='CENTER', depth=0.0, rot=(0, 0, 0)):
    """Mesh text object lying in the XY plane (readable from +Z)."""
    cu = bpy.data.curves.new("T", 'FONT')
    cu.body = body
    cu.font = bpy.data.fonts.load(font, check_existing=True)
    cu.size = size
    cu.align_x = align; cu.align_y = 'CENTER'
    cu.extrude = depth
    o = bpy.data.objects.new("Text_" + body[:12], cu)
    bpy.context.collection.objects.link(o)
    o.location = loc; o.rotation_euler = rot
    o.data.materials.append(mat)
    return o


def cyl(r, h, loc, mat, verts=64, name="Cyl"):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=loc)
    o = bpy.context.object; o.name = name
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def rounded_box(sx, sy, sz, loc, mat, bevel, name="Box"):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object; o.name = name
    o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True)
    b = o.modifiers.new("bev", 'BEVEL'); b.width = bevel; b.segments = 4
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def paper(hex_base, hex_fibre, rough=0.85, scale=400.0):
    """Paper/card material with fine fibre noise."""
    m = C.material("Paper" + hex_base, lin(hex_base), rough=rough)
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    n = nt.nodes.new("ShaderNodeTexNoise"); n.inputs["Scale"].default_value = scale; n.inputs["Detail"].default_value = 8
    r = nt.nodes.new("ShaderNodeValToRGB")
    r.color_ramp.elements[0].color = lin(hex_base); r.color_ramp.elements[1].color = lin(hex_fibre)
    r.color_ramp.elements[0].position = 0.35; r.color_ramp.elements[1].position = 0.7
    nt.links.new(n.outputs["Fac"], r.inputs[0]); nt.links.new(r.outputs[0], b.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.08
    nt.links.new(n.outputs["Fac"], bump.inputs["Height"]); nt.links.new(bump.outputs[0], b.inputs["Normal"])
    return m


def brushed(hex_base, rough=0.32):
    """Brushed metal: anisotropic-looking streaks via stretched noise."""
    m = C.material("Metal" + hex_base, lin(hex_base), rough=rough, metal=1.0)
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping"); mp.inputs["Scale"].default_value = (4000, 30, 30)
    nt.links.new(tc.outputs["Object"], mp.inputs[0])
    n = nt.nodes.new("ShaderNodeTexNoise"); n.inputs["Detail"].default_value = 4
    nt.links.new(mp.outputs[0], n.inputs["Vector"])
    rr = nt.nodes.new("ShaderNodeMapRange"); rr.inputs[3].default_value = rough - 0.1; rr.inputs[4].default_value = rough + 0.12
    nt.links.new(n.outputs["Fac"], rr.inputs[0]); nt.links.new(rr.outputs[0], b.inputs["Roughness"])
    return m


# ---------------------------------------------------------------- nameplates
def holder_disc(cx, cy, label, sub, band_hex, hand=False, stand=False):
    """Round label holder (the CH01-S04 'empty circle') with a pressed-on label."""
    holder = C.material("Holder", lin("#3A3D42"), rough=0.45)
    card = paper("#F3F1EA", "#E4E0D4", rough=0.7, scale=900)
    ink = C.material("Ink", lin("#1F2A44"), rough=0.6)
    band = C.material("Band" + band_hex, lin(band_hex), rough=0.5)
    parts = []
    z0 = 0.0
    if stand:  # small weighted table stand so the holder sits upright at the table
        parts.append(rounded_box(0.034, 0.02, 0.006, (cx, cy, 0.003), holder, 0.002, "Stand"))
        z0 = 0.006
    ring = cyl(0.019, 0.004, (cx, cy, z0 + 0.002), holder, name="Ring")
    parts.append(ring)
    parts.append(cyl(0.0168, 0.0006, (cx, cy, z0 + 0.0043), card, name="Label"))
    # colour band: a thin arc printed along the label's lower edge, plus words so colour is never the only cue
    bpy.ops.mesh.primitive_torus_add(major_radius=0.0150, minor_radius=0.0011, location=(cx, cy, z0 + 0.0046))
    t = bpy.context.object; t.scale.z = 0.12; t.data.materials.append(band); parts.append(t)
    font = HAND if hand else PRINT
    parts.append(text(label, font, 0.0105 if not hand else 0.014, ink, (cx, cy + (0.0025 if sub else 0), z0 + 0.0048)))
    if sub:
        parts.append(text(sub, PRINT, 0.0028, ink, (cx, cy - 0.0062, z0 + 0.0048)))
    if stand:  # tilt the whole holder back like a place card
        pass
    return parts


def nameplates(out):
    C.reset()
    parts = holder_disc(-0.024, 0, "ALO", "ALO-01  |  purple stem", "#6E3E6C")
    parts += holder_disc(0.024, 0, "TARA", "TARA-01  |  green stem", "#4F8A3A")
    C.studio(parts, elev=58, azim=0, margin=1.12)
    C.render(out)


def n_holder(out):
    C.reset()
    parts = holder_disc(0, 0, "N.", "", "#F2C230", hand=True)
    C.studio(parts, elev=58, azim=-12, margin=1.6)
    C.render(out)


# ---------------------------------------------------------------- mugs
def wrap_to_cylinder(obj, radius, cx=0.0, y_front=-1.0):
    """Map an object's local XZ plane onto a vertical cylinder of `radius` (decals)."""
    bpy.context.view_layer.objects.active = obj
    for o in bpy.context.selected_objects:
        o.select_set(False)
    obj.select_set(True)
    if obj.type == 'FONT':
        bpy.ops.object.convert(target='MESH')
        obj = bpy.context.object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for v in obj.data.vertices:
        x, y, z = v.co
        r = radius + (-y if y_front < 0 else y)  # y offset in front of the surface stays an offset
        a = x / radius
        v.co = Vector((cx + r * math.sin(a), -r * math.cos(a), z))
    return obj


def orient_mug(mug):
    """Turn PR_Mug so its handle points to +X; return (body radius, body axis x).

    The importer uses quaternion rotation, so the turn is applied to the mesh.
    The handle side is the one whose far verts sit in a narrow |x| band.
    """
    band = [v.co for v in mug.data.vertices if 0.04 < v.co.z < 0.06]
    R = (max(c.x for c in band) - min(c.x for c in band)) / 2
    ymin = min(c.y for c in band); ymax = max(c.y for c in band)
    handle_pos_y = (ymax - ymin) > 2.2 * R and sum(1 for c in band if c.y > ymax - 0.01) < sum(1 for c in band if c.y < ymin + 0.01)
    # handle is on the side whose extreme verts are fewer (a thin handle, not the round body)
    ang = -90 if handle_pos_y else 90
    mug.rotation_mode = 'XYZ'
    mug.rotation_euler = (0, 0, math.radians(ang))
    for o in bpy.context.selected_objects:
        o.select_set(False)
    mug.select_set(True); bpy.context.view_layer.objects.active = mug
    bpy.ops.object.transform_apply(rotation=True)
    band = [v.co.copy() for v in mug.data.vertices if 0.038 < v.co.z < 0.066]
    ymin = min(c.y for c in band)
    front = [c for c in band if c.y < ymin + 0.002]
    cx = sum(c.x for c in front) / len(front)          # axis of the round body
    sector = [c for c in band if c.y < 0 and abs(c.x - cx) < 0.6 * R]
    r = max(math.hypot(c.x - cx, c.y) for c in sector) + 0.0008  # clear of every facet
    return r, cx


def mugs(out):
    C.reset()
    tape = paper("#E8DDBF", "#D9CBA5", rough=0.75, scale=600)
    parts = []
    names = ["KAI", "AMARA", "MEI", "RAFI", "FERREIRA"]
    for i, name in enumerate(names):
        x0 = (i - 2) * 0.112
        mug = C.import_glb(os.path.join(ROOT, "game", "assets", "props", "PR_Mug", "PR_Mug.glb"))
        r, cx = orient_mug(mug)
        w = 0.026 + 0.0088 * len(name)
        bpy.ops.mesh.primitive_grid_add(x_subdivisions=40, y_subdivisions=4, size=1, location=(0, 0, 0))
        strip = bpy.context.object
        strip.scale = (w, 0.021, 1); strip.rotation_euler.x = math.radians(90)
        strip.location = (0, -0.0004, 0.052)
        strip.data.materials.append(tape)
        strip = wrap_to_cylinder(strip, r, cx)
        ink = C.material("Marker" + name, tuple(c * (0.45 if name == "FERREIRA" else 0.7) for c in lin(ROLE[name])[:3]) + (1,), rough=0.45)
        t = text(name, HAND, 0.0150, ink, (0, -0.0008, 0.0512), rot=(math.radians(90), 0, 0))
        t = wrap_to_cylinder(t, r, cx)
        for o in (mug, strip, t):
            o.location.x += x0
        parts += [mug, strip, t]
    bpy.context.scene.render.resolution_x = 1800
    bpy.context.scene.render.resolution_y = 600
    C.studio(parts, elev=8, azim=0, margin=1.04)
    C.render(out)


# ---------------------------------------------------------------- tool tag
def gear_outline(teeth=12, r_out=0.0085, r_in=0.0068, n=8):
    pts = []
    for t in range(teeth):
        for k in range(n):
            a = 2 * math.pi * (t + k / n) / teeth
            ph = k / n
            r = r_out if 0.15 < ph < 0.55 else r_in
            pts.append((r * math.cos(a), r * math.sin(a)))
    return pts


def tool_tag(out):
    C.reset()
    steel = brushed("#9EA3A8", rough=0.5)
    dark = C.material("Engrave", lin("#4B5056"), rough=0.75)
    ring_m = brushed("#B8BCC0", rough=0.25)
    tag = rounded_box(0.052, 0.026, 0.0016, (0, 0, 0.0008), steel, 0.004, "Tag")
    hole = cyl(0.0032, 0.01, (-0.020, 0, 0.0008), steel, name="Hole")
    bo = tag.modifiers.new("hole", 'BOOLEAN'); bo.object = hole; bo.operation = 'DIFFERENCE'
    hole.hide_render = True; hole.hide_viewport = True
    # engraved gear-wheel emblem (Ferreira's old engineering patch, clue 12)
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, 0.0012)) for x, y in gear_outline()]
    f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    bmesh.ops.translate(bm, vec=(0, 0, 0.00045), verts=[e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("Gear"); bm.to_mesh(me); bm.free()
    gear = bpy.data.objects.new("Gear", me); bpy.context.collection.objects.link(gear)
    gear.location = (0.004, 0, 0)
    gear.data.materials.append(dark)
    hub = cyl(0.0034, 0.0006, (0.004, 0, 0.00168), steel, name="Hub")
    hub2 = cyl(0.0014, 0.0008, (0.004, 0, 0.0017), dark, name="Axle")
    stamp = text("ENG-07", PRINT, 0.0042, dark, (0.0175, -0.0005, 0.00166), rot=(0, 0, math.radians(90)))
    # split ring through the hole, standing perpendicular to the tag
    bpy.ops.mesh.primitive_torus_add(major_radius=0.0085, minor_radius=0.0007, location=(-0.0285, 0, 0.0008),
                                     rotation=(math.radians(90), 0, 0))
    ring = bpy.context.object; ring.data.materials.append(ring_m)
    parts = [tag, gear, hub, hub2, stamp, ring]
    C.studio(parts, elev=60, azim=-15, margin=1.25)
    C.render(out)


# ---------------------------------------------------------------- drawer lid
def drawer_lid(out):
    C.reset()
    alu = brushed("#C3C7CB", rough=0.4)
    graphite = C.material("Graphite", lin("#4A4C50"), rough=0.35, metal=0.3)
    lid = rounded_box(0.17, 0.095, 0.004, (0, 0, 0.002), alu, 0.002, "Lid")
    lines = ["Seed 1: outer chamber.", "Seed 2: inside, for comparison.", "Water at"]
    parts = [lid]
    for i, line in enumerate(lines):
        parts.append(text(line, HAND, 0.0102, graphite, (-0.072, 0.024 - i * 0.021, 0.00402), align='LEFT',
                          rot=(0, 0, math.radians(-1.2 + 0.8 * i))))
    C.studio(parts, elev=72, azim=0, margin=1.08)
    C.render(out)


# ---------------------------------------------------------------- envelope
def envelope(out):
    C.reset()
    kraft = paper("#B58E60", "#9C774C", rough=0.9, scale=500)
    tape = C.material("SealTape", (0.85, 0.80, 0.62, 1), rough=0.15)
    tape.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.55
    ink = C.material("Ink", lin("#1F2A44"), rough=0.55)
    body = rounded_box(0.075, 0.115, 0.003, (0, 0, 0.0015), kraft, 0.0015, "Envelope")
    flap = rounded_box(0.075, 0.03, 0.0006, (0, 0.044, 0.0033), kraft, 0.0006, "Flap")
    seal = rounded_box(0.05, 0.012, 0.0003, (0, 0.03, 0.0038), tape, 0.0001, "Seal")
    t1 = text("Working stock", HAND, 0.0105, ink, (0, 0.002, 0.0031))
    t2 = text("Tara × Alo", HAND, 0.0125, ink, (0, -0.017, 0.0031))
    C.studio([body, flap, seal, t1, t2], elev=62, azim=-10, margin=1.12)
    C.render(out)


PANELS = {
    "nameplates": nameplates,
    "mugs": mugs,
    "tool_tag": tool_tag,
    "drawer_lid_note": drawer_lid,
    "n_label_holder": n_holder,
    "working_stock_envelope": envelope,
}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:]
    out_dir = argv[0]
    os.makedirs(out_dir, exist_ok=True)
    for name in (argv[1:] or PANELS):
        PANELS[name](os.path.join(out_dir, name + ".png"))
