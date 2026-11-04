"""M3-99 plant-stage approval panels (Blender, no AI generation, no credits).

Usage:
  blender -b --factory-startup --python build_plant_panels.py -- <out_dir> [panel ...]

Stages come from game-design/24_NARRATIVE_REVISION.md §3.8/§3.9 and the
Fast Plants life cycle. Botany (ART_BIBLE §2 rule 8, §6): Brassica rapa,
Alo purple stem, Tara green stem, four-petal cross flowers, no face ever.

Senescent, dry and Tara variants are texture remaps plus a lean of the
existing Tripo models (the planned build method: no new mesh). Seedlings are
procedural Blender geometry in the existing PL_Alo_Bud pot.
"""
import bpy, bmesh, math, os, sys, random
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sheet_common as C

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
PLANTS = os.path.join(ROOT, "game", "assets", "plants")


def lin(hexstr):
    """sRGB hex -> linear RGBA."""
    h = hexstr.lstrip("#")
    return tuple(((int(h[i:i + 2], 16) / 255) ** 2.2) for i in (0, 2, 4)) + (1.0,)


# ---------------------------------------------------------------- remaps
def _range_mask(nt, value, lo, hi, soft):
    """Smooth 0..1 mask for lo <= value <= hi."""
    a = nt.nodes.new("ShaderNodeMapRange"); a.interpolation_type = 'SMOOTHSTEP'
    a.inputs[1].default_value, a.inputs[2].default_value = lo - soft, lo
    nt.links.new(value, a.inputs[0])
    b = nt.nodes.new("ShaderNodeMapRange"); b.interpolation_type = 'SMOOTHSTEP'
    b.inputs[1].default_value, b.inputs[2].default_value = hi, hi + soft
    b.inputs[3].default_value, b.inputs[4].default_value = 1.0, 0.0
    nt.links.new(value, b.inputs[0])
    m = nt.nodes.new("ShaderNodeMath"); m.operation = 'MULTIPLY'
    nt.links.new(a.outputs[0], m.inputs[0]); nt.links.new(b.outputs[0], m.inputs[1])
    return m.outputs[0]


def _mul(nt, x, y):
    m = nt.nodes.new("ShaderNodeMath"); m.operation = 'MULTIPLY'
    for i, v in enumerate((x, y)):
        if isinstance(v, float):
            m.inputs[i].default_value = v
        else:
            nt.links.new(v, m.inputs[i])
    return m.outputs[0]


def _hsv(nt, h, s, v):
    """Combine HSV from sockets or floats."""
    c = nt.nodes.new("ShaderNodeCombineColor"); c.mode = 'HSV'
    for i, x in enumerate((h, s, v)):
        if isinstance(x, float):
            c.inputs[i].default_value = x
        else:
            nt.links.new(x, c.inputs[i])
    return c.outputs[0]


def _affine(nt, x, mul, add):
    m = nt.nodes.new("ShaderNodeMath"); m.operation = 'MULTIPLY_ADD'
    nt.links.new(x, m.inputs[0]); m.inputs[1].default_value = mul; m.inputs[2].default_value = add
    m.use_clamp = True
    return m.outputs[0]


def _mix(nt, a, b, fac):
    m = nt.nodes.new("ShaderNodeMix"); m.data_type = 'RGBA'
    nt.links.new(fac, m.inputs[0]); nt.links.new(a, m.inputs[6]); nt.links.new(b, m.inputs[7])
    return m.outputs[2]


def remap(obj, stem, foliage, z_top, rim):
    """Recolour the baked base colour by hue class.

    stem:    None (keep), 'green' (Tara), 'alo_dry', 'tara_dry'
    foliage: None (keep), 'green' (living pods/leaves), 'dry'
    """
    mat = obj.active_material
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = bsdf.inputs["Base Color"].links[0].from_socket
    sep = nt.nodes.new("ShaderNodeSeparateColor"); sep.mode = 'HSV'
    nt.links.new(tex, sep.inputs[0])
    H, S, V = sep.outputs
    sat_ok = _range_mask(nt, S, 0.14, 1.0, 0.06)
    purple = _mul(nt, _range_mask(nt, H, 0.66, 0.97, 0.05), sat_ok)
    warm = _mul(nt, _range_mask(nt, H, 0.05, 0.19, 0.03), sat_ok)     # yellow leaves, straw pods
    green = _mul(nt, _range_mask(nt, H, 0.20, 0.50, 0.04), sat_ok)
    # height 0..1 for gradients (object space)
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sx = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(tc.outputs["Object"], sx.inputs[0])
    above = _range_mask(nt, sx.outputs[2], rim + 0.002, 10.0, 0.003)
    bright = _range_mask(nt, V, 0.42, 2.0, 0.08)
    mx = nt.nodes.new("ShaderNodeMath"); mx.operation = 'MAXIMUM'
    nt.links.new(above, mx.inputs[0]); nt.links.new(bright, mx.inputs[1])
    above = mx.outputs[0]  # leaves the dark soil alone, catches leaves lying on it
    purple, warm, green = (_mul(nt, m, above) for m in (purple, warm, green))
    noise = nt.nodes.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value = 60.0
    nt.links.new(tc.outputs["Object"], noise.inputs["Vector"])
    nz = noise.outputs["Fac"]
    col = tex
    if foliage == 'green':
        living = _hsv(nt, _affine(nt, nz, 0.06, 0.24), _affine(nt, S, 0.6, 0.30), _affine(nt, V, 0.72, 0.02))
        col = _mix(nt, col, living, warm)
    elif foliage == 'dry':
        both = nt.nodes.new("ShaderNodeMath"); both.operation = 'MAXIMUM'
        nt.links.new(warm, both.inputs[0]); nt.links.new(green, both.inputs[1])
        brown = _hsv(nt, _affine(nt, nz, 0.05, 0.065), _affine(nt, nz, 0.25, 0.30), _affine(nt, V, 0.62, 0.06))
        col = _mix(nt, col, brown, both.outputs[0])
    if stem == 'green':
        g = _hsv(nt, 0.27, _affine(nt, S, 0.9, 0.12), _affine(nt, V, 1.05, 0.03))
        col = _mix(nt, col, g, purple)
    elif stem == 'alo_dry':
        p = _hsv(nt, 0.92, 0.30, _affine(nt, V, 0.7, 0.0))
        col = _mix(nt, col, p, purple)
    elif stem == 'tara_dry':
        o = _hsv(nt, 0.20, 0.38, _affine(nt, V, 0.85, 0.02))
        col = _mix(nt, col, o, purple)
    nt.links.new(col, bsdf.inputs["Base Color"])
    if foliage == 'dry':
        r = bsdf.inputs["Roughness"]
        for l in list(r.links):
            nt.links.remove(l)
        r.default_value = 0.85


def soil_height(obj):
    """Top of the pot rim: highest vertex on the pot's outer wall band.

    The wall band is read from the pot foot (lowest 1 cm), so leaves that droop
    past the rim do not count.
    """
    vs = [v.co for v in obj.data.vertices]
    ztop = max(v.z for v in vs)
    foot = [v for v in vs if v.z < 0.01]
    ex = max(abs(v.x) for v in foot); ey = max(abs(v.y) for v in foot)
    wall = [v for v in vs if v.z < 0.2 * ztop and
            ((0.9 * ex < abs(v.x) < 1.12 * ex and abs(v.y) < 1.12 * ey) or
             (0.9 * ey < abs(v.y) < 1.12 * ey and abs(v.x) < 1.12 * ex))]
    rim = sorted(v.z for v in wall)[int(0.98 * (len(wall) - 1))]
    return rim, ztop


def lean(obj, degrees, base_z, axis_dir=1.0):
    """Lean everything above base_z, increasing towards the top (stem bending, not tipping)."""
    ztop = max(v.co.z for v in obj.data.vertices)
    for v in obj.data.vertices:
        if v.co.z <= base_z:
            continue
        t = (v.co.z - base_z) / (ztop - base_z)
        ang = math.radians(degrees) * t * axis_dir
        rel = v.co - Vector((0, 0, base_z))
        v.co = Matrix.Rotation(ang, 3, 'Y') @ rel + Vector((0, 0, base_z))


def bake_transforms(obj):
    """Apply the importer's rotation so vertex z is world up."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def variant(glb, stem, foliage, lean_deg, out, mirror=False):
    C.reset()
    o = C.import_glb(os.path.join(PLANTS, glb, glb + ".glb"))
    if mirror:  # Tara reuses the pod mesh mirrored so the two plants never read as copies
        o.scale.x *= -1
    bake_transforms(o)
    rim, ztop = soil_height(o)
    if lean_deg:
        lean(o, lean_deg, rim + 0.004)
    remap(o, stem, foliage, ztop, rim)
    C.studio([o])
    C.render(out)


# ---------------------------------------------------------------- seedlings
def outline_heart(n=72):
    """Obcordate cotyledon: notched at the apex, narrow at the petiole."""
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((x, y))
    ymin = min(p[1] for p in pts)
    return [(x, y - ymin) for x, y in pts]  # point (petiole end) at y=0, notch at the far end


def outline_true_leaf(n=120, teeth=11):
    """Ovate, toothed true leaf (rough-edged), base at y=0."""
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n          # 0 = tip, pi = base
        s = (1 + math.cos(t)) / 2        # 1 tip .. 0 base
        w = math.sin(math.pi * (s ** 0.75)) * 0.42
        w *= 1.0 + 0.09 * max(0.0, math.sin(2 * math.pi * teeth * s))
        if s < 0.3:  # small basal lobe (lyrate tendency of Brassica rapa)
            w *= 1.0 - 0.35 * math.sin(math.pi * s / 0.3)
        x = w * math.copysign(1, math.sin(t)) if abs(math.sin(t)) > 1e-6 else 0.0
        pts.append((x, s))
    return pts


def blade(name, outline, length, mat, cup=0.18, curl=0.0):
    """Ringed fill of a 2D outline (base at origin, +y along the blade), cupped upwards."""
    xs = [p[0] for p in outline]; ys = [p[1] for p in outline]
    sc = length / (max(ys) - min(ys))
    w = (max(xs) - min(xs)) * sc / 2
    cx = 0.0; cy = (max(ys) + min(ys)) / 2
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new()
    K = 6
    rings = []
    for k in range(1, K + 1):
        f = k / K
        ring = []
        for (x, y) in outline:
            px = (cx + (x - cx) * f) * sc
            py = (cy + (y - cy) * f) * sc
            z = cup * length * (px / w) ** 2 + curl * length * ((py / length) ** 2)
            ring.append(bm.verts.new((px, py, z)))
        rings.append(ring)
    centre = bm.verts.new((cx * sc, cy * sc, 0))
    n = len(outline)
    for i in range(n):
        bm.faces.new((centre, rings[0][i], rings[0][(i + 1) % n]))
    for k in range(K - 1):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((rings[k][i], rings[k + 1][i], rings[k + 1][j], rings[k][j]))
    for f in bm.faces:
        for l in f.loops:
            co = l.vert.co
            l[uv].uv = (co.x / (2 * w) + 0.5, co.y / length)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = True
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    sol = o.modifiers.new("thick", 'SOLIDIFY'); sol.thickness = 0.00035
    o.data.materials.append(mat)
    return o


def leaf_material(name, base_hex, vein_hex, rough=0.55):
    """Leaf: base colour, lighter midrib from UV, fine vein bump, light subsurface."""
    m = C.material(name, lin(base_hex), rough=rough, sss=0.12)
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    uvn = nt.nodes.new("ShaderNodeUVMap")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(uvn.outputs[0], sep.inputs[0])
    d = nt.nodes.new("ShaderNodeMath"); d.operation = 'SUBTRACT'; d.inputs[1].default_value = 0.5
    nt.links.new(sep.outputs[0], d.inputs[0])
    a = nt.nodes.new("ShaderNodeMath"); a.operation = 'ABSOLUTE'; nt.links.new(d.outputs[0], a.inputs[0])
    rib = nt.nodes.new("ShaderNodeMapRange"); rib.interpolation_type = 'SMOOTHSTEP'
    rib.inputs[1].default_value, rib.inputs[2].default_value = 0.012, 0.03
    rib.inputs[3].default_value, rib.inputs[4].default_value = 1.0, 0.0
    nt.links.new(a.outputs[0], rib.inputs[0])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = 'RGBA'
    mix.inputs[6].default_value = lin(base_hex); mix.inputs[7].default_value = lin(vein_hex)
    nt.links.new(rib.outputs[0], mix.inputs[0]); nt.links.new(mix.outputs[2], b.inputs["Base Color"])
    vor = nt.nodes.new("ShaderNodeTexVoronoi"); vor.feature = 'DISTANCE_TO_EDGE'; vor.inputs["Scale"].default_value = 14
    nt.links.new(uvn.outputs[0], vor.inputs["Vector"])
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.18
    nt.links.new(vor.outputs["Distance"], bump.inputs["Height"]); nt.links.new(bump.outputs[0], b.inputs["Normal"])
    return m


def tube(name, pts, radius, mat, taper=1.0):
    """Bevelled poly curve through pts (stems, petioles)."""
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'
    sp = cu.splines.new('NURBS'); sp.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        sp.points[i].co = (p[0], p[1], p[2], 1)
        sp.points[i].radius = 1.0 + (taper - 1.0) * i / max(1, len(pts) - 1)
    sp.use_endpoint_u = True; sp.order_u = min(4, len(pts))
    cu.bevel_depth = radius; cu.bevel_resolution = 4; cu.use_fill_caps = True
    o = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    return o


def place(o, at, yaw_deg, pitch_deg):
    """Blade base at `at`, pointing along yaw, raised by pitch above horizontal."""
    o.rotation_euler = (math.radians(pitch_deg), 0, math.radians(yaw_deg))
    o.location = at


def pot_only():
    """Square black seedling pot with a dark moist soil surface (procedural, 6.5 cm)."""
    bm = bmesh.new()
    top, bot, hgt, lip = 0.0325, 0.024, 0.055, 0.0035
    rings = [(bot, 0.0), (top, hgt), (top + lip * 0.6, hgt), (top + lip * 0.6, hgt + 0.002),
             (top - 0.002, hgt + 0.002), (top - 0.0025, hgt - 0.006)]
    vs = []
    for half, z in rings:
        vs.append([bm.verts.new((sx * half, sy * half, z)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    bm.faces.new(vs[0][::-1])
    for a, b in zip(vs, vs[1:]):
        for i in range(4):
            j = (i + 1) % 4
            bm.faces.new((a[i], a[j], b[j], b[i]))
    me = bpy.data.meshes.new("Pot"); bm.to_mesh(me); bm.free()
    pot = bpy.data.objects.new("Pot", me); bpy.context.collection.objects.link(pot)
    bev = pot.modifiers.new("bev", 'BEVEL'); bev.width = 0.0012; bev.segments = 3
    pot.data.materials.append(C.material("PotPlastic", lin("#2B2C2E"), rough=0.55))
    soil_z = hgt - 0.006
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=80, y_subdivisions=80, size=2 * (top - 0.0026), location=(0, 0, soil_z))
    soil = bpy.context.object
    tex = bpy.data.textures.new("SoilTex", 'CLOUDS'); tex.noise_scale = 0.004
    d = soil.modifiers.new("disp", 'DISPLACE'); d.texture = tex; d.strength = 0.0025; d.mid_level = 0.5
    sm = C.material("Soil", lin("#3B2E24"), rough=0.95)
    nt = sm.node_tree; b = nt.nodes["Principled BSDF"]
    vor = nt.nodes.new("ShaderNodeTexVoronoi"); vor.inputs["Scale"].default_value = 900
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = lin("#2A2019"); ramp.color_ramp.elements[1].color = lin("#5A4838")
    nt.links.new(vor.outputs["Distance"], ramp.inputs[0]); nt.links.new(ramp.outputs[0], b.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.6
    nt.links.new(vor.outputs["Distance"], bump.inputs["Height"]); nt.links.new(bump.outputs[0], b.inputs["Normal"])
    soil.data.materials.append(sm)
    return [pot, soil], soil_z


def seedling(true_leaves, out):
    C.reset()
    pots, soil = pot_only()
    stem_m = C.material("AloStem", lin("#6E3E6C"), rough=0.45, sss=0.1)
    coty_m = leaf_material("Cotyledon", "#5E9B3C", "#8FBF6A")
    leaf_m = leaf_material("TrueLeaf", "#4E7F3A", "#7FA866", rough=0.7)
    h = 0.032 if true_leaves else 0.022
    top = Vector((0.0015, 0.0, soil + h))
    stem = [(0, 0, soil - 0.004), (0.0004, 0, soil + h * 0.4), (0.0012, 0, soil + h * 0.8), tuple(top)]
    parts = pots + [tube("Hypocotyl", stem, 0.0011, stem_m, taper=0.8)]
    coty_len = 0.0115 if true_leaves else 0.0095
    for yaw in (90, -90):
        pet_end = top + Vector((0.0035 * (1 if yaw == -90 else -1), 0, 0.0012))
        parts.append(tube("CotPetiole", [tuple(top), tuple((top + pet_end) / 2 + Vector((0, 0, 0.0008))), tuple(pet_end)], 0.0005, stem_m))
        b = blade("Cotyledon", outline_heart(), coty_len, coty_m, cup=0.10)
        place(b, pet_end, yaw, 14 if true_leaves else 22)
        parts.append(b)
    if true_leaves:
        green_stem = C.material("Petiole", lin("#5F7F45"), rough=0.5)
        for yaw, ln, pitch, rise in ((0, 0.024, -38, 0.010), (180, 0.019, -48, 0.012), (35, 0.010, -62, 0.014)):
            base = top + Vector((0, 0, 0.002))
            d = Vector((-math.sin(math.radians(yaw)), math.cos(math.radians(yaw)), 0))
            end = base + d * 0.005 + Vector((0, 0, rise * 0.5))
            parts.append(tube("Petiole", [tuple(base), tuple(base + d * 0.002 + Vector((0, 0, rise * 0.35))), tuple(end)], 0.0006, green_stem))
            b = blade("TrueLeaf", outline_true_leaf(), ln, leaf_m, cup=0.12, curl=-0.05)
            place(b, end, yaw, -pitch)
            parts.append(b)
    C.studio(parts[1:], elev=22, margin=1.7)  # frame on soil and seedling; pot body runs off the bottom
    C.render(out)


PANELS = {
    # name: callable(out)
    "alo_cotyledon": lambda out: seedling(False, out),
    "alo_trueleaf": lambda out: seedling(True, out),
    "alo_pods_green": lambda out: variant("PL_Alo_Pods", None, 'green', 0, out),
    "alo_senescent": lambda out: variant("PL_Alo_Pods", None, None, 18, out),
    "alo_dry": lambda out: variant("PL_Alo_Pods", 'alo_dry', 'dry', 28, out),
    "tara_pods": lambda out: variant("PL_Alo_Pods", 'green', 'green', 0, out, mirror=True),
    "tara_senescent": lambda out: variant("PL_Alo_Pods", 'green', None, 16, out, mirror=True),
    "tara_dry": lambda out: variant("PL_Alo_Pods", 'tara_dry', 'dry', 25, out, mirror=True),
}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:]
    out_dir = argv[0]
    os.makedirs(out_dir, exist_ok=True)
    for name in (argv[1:] or PANELS):
        PANELS[name](os.path.join(out_dir, name + ".png"))
