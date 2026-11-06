"""M3-5A: cotton seed, sprout and seedling stages for Chapter 5 (Blender 5.2, no AI generation, no credits).

Usage:
  blender -b --factory-startup --python build_cotton_stages.py -- <out_dir> [stage ...]
  stages: seed sprout seedling   (default: all three)

Writes <out_dir>/PL_Cotton_<Stage>/PL_Cotton_<Stage>.glb and prints STAGE lines with the measured size,
triangle count and the pot rim height, which the manifest rows copy.

Canon and botany
  * Cotton is planted on 15 Dec 2046 in Tara's indoor reference bay (EX-CH05-S12); dated care runs into January and
    PL_Cotton_Young (0.32 m, first light) is the next stage. These three cover sowing, emergence and the first true leaf.
  * Gossypium hirsutum: the acid-delinted seed is an ovoid dark-brown 9-10 mm grain sown about 2 cm deep; the hypocotyl
    pushes up as a hook 5-10 days after sowing (warm medium), then the two kidney-shaped (reniform) cotyledons unfold,
    wider than long with a basal notch, light green and smooth; the first true leaf comes 7-10 days later, heart-shaped
    (ovate-cordate) with a weak three-lobe outline and palmate veins, the start of the lobed leaves on PL_Cotton_Young.
  * No eyes, face or mouth on any plant (ART_BIBLE 2.11). The plant lives in a pressurised bay; this is the pot only.
  * The pot, soil and their textures are the Tripo pot of the installed PL_Cotton_Young (the registry's "Blender
    (scaled from PL_Cotton_Young)" build method), so the later stage swap keeps the same container. Textures are
    downscaled to 1024 px because only the pot uses them.

Runtime contract (consumers: the biology service and the LOC-03 room, M3-5R / M3-96)
  * Mesh nodes: `Pot` (reused) and `Plant` (procedural; absent in the seed stage, which has `Seed` instead).
  * Blend shapes on `Plant` (sprout and seedling): `Thirst` (cotyledons and leaf droop, hypocotyl leans) and
    `Cold` (blades cup downwards and tuck in). Both change the silhouette, not only colour.
  * Pivot at the base centre, metres, Y up in the GLB.
"""
import bmesh, bpy, math, os, sys
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
YOUNG = os.path.join(ROOT, "game", "assets", "plants", "PL_Cotton_Young", "PL_Cotton_Young.glb")

POT_TOP = 0.097          # everything of PL_Cotton_Young below this height is pot and soil
SOIL_Z = 0.081           # soil surface of that pot; measured again from the mesh in pot() (rim at ~0.095)
POT_TEX = 1024
CLEAR_R = 0.0185        # radius of old soil cleared round the axis (the dimple and soil cap are 0.019)
DIMPLE_R, DIMPLE_DEPTH, DIMPLE_SINK = 0.019, 0.0038, 0.0012   # sowing dimple: radius, bowl depth, centre below SOIL_Z


def lin(hexstr):
    """sRGB hex -> linear RGBA."""
    h = hexstr.lstrip("#")
    return tuple(((int(h[i:i + 2], 16) / 255) ** 2.2) for i in (0, 2, 4)) + (1.0,)


def material(name, color, rough=0.5, sss=0.0, double=True):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = color
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = 0.0
    if sss:
        b.inputs["Subsurface Weight"].default_value = sss
        b.inputs["Subsurface Radius"].default_value = (0.4, 1.0, 0.25)
        b.inputs["Subsurface Scale"].default_value = 0.002
    m.use_backface_culling = not double
    return m


# ---------------------------------------------------------------- pot (reused from PL_Cotton_Young)
def pot():
    """Import the installed young cotton, keep only the pot and soil, downscale its textures."""
    global SOIL_Z
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=YOUNG)
    o = [x for x in bpy.data.objects if x not in before and x.type == "MESH"][0]
    for x in [x for x in bpy.data.objects if x not in before and x is not o]:
        bpy.data.objects.remove(x)
    o.parent = None
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    kill = []
    for f in bm.faces:
        zs = [v.co.z for v in f.verts]
        r = max(math.hypot(v.co.x, v.co.y) for v in f.verts)
        # plant faces: above the pot top; stem and soil faces near the axis: inside CLEAR_R, which the sowing dimple
        # and the soil cap (radius 0.019) replace, so no old soil pokes through the new surface
        if max(zs) > POT_TOP or (min(zs) > SOIL_Z - 0.006 and r < CLEAR_R):
            kill.append(f)
    bmesh.ops.delete(bm, geom=kill, context="FACES")
    ring = [v.co.z for v in bm.verts if CLEAR_R < max(abs(v.co.x), abs(v.co.y)) < 0.034 and v.co.z < POT_TOP]
    SOIL_Z = sorted(ring)[int(0.9 * (len(ring) - 1))]
    # the Tripo soil has large triangles that span the cleared circle; their inner corners drop 1.5 mm under the
    # sowing dimple's bowl, so those faces slope under the new surface instead of cutting through it or opening a pit
    for v in bm.verts:
        r = math.hypot(v.co.x, v.co.y)
        if r < CLEAR_R and v.co.z > SOIL_Z - 0.012:
            v.co.z = min(v.co.z, SOIL_Z - DIMPLE_SINK - DIMPLE_DEPTH * (1 - (r / DIMPLE_R) ** 2) - 0.0015)
    bm.to_mesh(o.data)
    bm.free()
    o.name = o.data.name = "Pot"
    print(f"SOIL_Z measured {SOIL_Z:.4f}")
    for m in o.data.materials:
        m.name = "CottonPot"
    for img in bpy.data.images:
        if img.size[0] > POT_TEX:
            img.scale(POT_TEX, POT_TEX)
            img.pack()
    return o


def soil_cap(radius=0.019, height=0.0035, mat=None):
    """Small mound of soil over the hole the young plant's stem left, and where the seedling emerges."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=10, radius=radius, location=(0, 0, SOIL_Z - 0.001))
    o = bpy.context.object
    o.scale = (1.0, 1.0, height / radius)
    bpy.ops.object.transform_apply(scale=True)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if all(v.co.z < SOIL_Z - 0.0015 for v in f.verts)], context="FACES")
    import random
    rnd = random.Random(3)
    for v in bm.verts:                       # crumb texture so the cap reads as soil, not a disc
        v.co.z += rnd.uniform(-0.0006, 0.0006)
        v.co.x += rnd.uniform(-0.0005, 0.0005)
        v.co.y += rnd.uniform(-0.0005, 0.0005)
    bm.to_mesh(o.data)
    bm.free()
    o.name = "SoilCap"
    o.data.materials.append(mat)
    return o


# ---------------------------------------------------------------- geometry helpers
def blade(name, outline, attach, mat, cup=0.0, droop=0.0, curl=0.0):
    """Ringed fill of a 2D outline (metres, +y along the blade), attached at `attach` (an (x, y) on the outline frame).

    cup: edges rise (positive) or fall (negative) with the square of the distance from the midrib.
    droop: the blade bends down along its length (thirst). curl: edges roll under (cold).
    Returns a mesh object with the attach point at its origin.
    """
    xs = [p[0] for p in outline]
    ys = [p[1] for p in outline]
    w = (max(xs) - min(xs)) / 2
    length = max(ys) - min(ys)
    cx, cy = attach
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new()
    K = 5
    rings = []
    for k in range(1, K + 1):
        f = k / K
        ring = []
        for (x, y) in outline:
            px = (x - cx) * f
            py = (y - cy) * f
            t = max(0.0, py) / length
            z = cup * length * (px / w) ** 2 - droop * length * t * t - curl * length * (abs(px) / w) ** 3
            ring.append(bm.verts.new((px, py, z)))
        rings.append(ring)
    centre = bm.verts.new((0.0, 0.0, 0.0))
    n = len(outline)
    for i in range(n):
        bm.faces.new((centre, rings[0][i], rings[0][(i + 1) % n]))
    for k in range(K - 1):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((rings[k][i], rings[k + 1][i], rings[k + 1][j], rings[k][j]))
    bm.normal_update()
    for f in bm.faces:
        for l in f.loops:
            co = l.vert.co
            l[uv].uv = (co.x / (2 * w) + 0.5, (co.y + cy - min(ys)) / length)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    sol = o.modifiers.new("thick", "SOLIDIFY")
    sol.thickness = 0.0004
    sol.offset = 0.0
    o.data.materials.append(mat)
    return o


def tube(name, pts, radius, mat, taper=1.0, segments=10):
    """Bevelled NURBS curve through pts (stems, petioles), converted to a mesh."""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    sp = cu.splines.new("NURBS")
    sp.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        sp.points[i].co = (p[0], p[1], p[2], 1.0)
        sp.points[i].radius = 1.0 + (taper - 1.0) * i / max(1, len(pts) - 1)
    sp.use_endpoint_u = True
    sp.order_u = min(4, len(pts))
    cu.bevel_depth = radius
    cu.bevel_resolution = 3
    cu.resolution_u = segments
    cu.use_fill_caps = True
    o = bpy.data.objects.new(name, cu)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    return o


def place(o, at, yaw_deg, pitch_deg):
    """Attach point at `at`; the blade points along yaw and is lifted by pitch above horizontal."""
    o.rotation_euler = (math.radians(pitch_deg), 0.0, math.radians(yaw_deg))
    o.location = at


def outline_reniform(width, length, n=56):
    """Cotton cotyledon: kidney-shaped, wider than long, with a basal notch at the petiole."""
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x = 0.5 * width * math.sin(t)
        y = 0.5 * length * (1 - math.cos(t))
        # basal sinus: the base rises towards the petiole, deepest on the midline
        y += 0.22 * length * math.exp(-(x / (0.28 * width)) ** 2) * (1.0 - y / length)
        pts.append((x, y))
    return pts, (0.0, 0.20 * length)


def outline_cordate(width, length, n=72):
    """First true leaf: heart-shaped with a weak three-lobe outline and a notched base."""
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        s = (1 - math.cos(t)) / 2              # 0 base .. 1 tip
        half = math.sin(math.pi * s ** 0.85) * 0.5 * width
        half *= 1.0 + 0.10 * math.cos(3 * math.pi * (s - 0.55))   # gentle lobes
        x = half * (1 if math.sin(t) >= 0 else -1)
        y = length * s
        y += 0.14 * length * math.exp(-(x / (0.22 * width)) ** 2) * (1.0 - s)   # cordate base
        pts.append((x, y))
    return pts, (0.0, 0.12 * length)


def leaf_texture(name, base_hex, vein_hex, size=512):
    """512 px base-colour map: base green with a lighter midrib and palmate veins fanning from the blade base.

    The blade UV runs u across the blade (0.5 = midrib) and v along it (0 = base). Generated with numpy and packed
    into the GLB, so the exporter keeps it (node mixes are not exportable).
    """
    import numpy as np
    base = np.array([int(base_hex.lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)])
    vein = np.array([int(vein_hex.lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)])
    u = (np.arange(size) + 0.5) / size
    U, V = np.meshgrid(u, u)                      # V is the row (v along the blade)
    rng = np.random.default_rng(7)
    mottle = 1.0 + 0.05 * (rng.random((size, size)) - 0.5)
    img = base[None, None, :] * mottle[..., None]
    w = np.zeros((size, size))
    # midrib: widest at the base, fading to the tip
    w = np.maximum(w, np.clip(1.0 - np.abs(U - 0.5) / (0.012 + 0.016 * (1 - V)), 0, 1))
    # side veins: lines from the base point (0.5, 0.12) at +-28, +-55 degrees and secondary ribs off the midrib
    for ang in (28.0, 55.0, -28.0, -55.0):
        a = math.radians(90 - ang)
        dx, dy = math.cos(a), math.sin(a)
        px, py = U - 0.5, V - 0.12
        t = px * dx + py * dy
        dist = np.abs(px * dy - py * dx)
        on = (t > 0.02) & (t < 0.75)
        w = np.maximum(w, np.where(on, np.clip(1.0 - dist / (0.006 + 0.004 * (1 - t)), 0, 1), 0))
    for k in range(5):
        v0 = 0.3 + 0.13 * k
        for sgn in (1, -1):
            px, py = U - 0.5, V - v0
            a = math.radians(50)
            dx, dy = sgn * math.cos(a), math.sin(a)
            t = px * dx + py * dy
            dist = np.abs(px * dy - py * dx)
            on = (t > 0.0) & (t < 0.22)
            w = np.maximum(w, 0.6 * np.where(on, np.clip(1.0 - dist / 0.0035, 0, 1), 0))
    img = img * (1 - w[..., None]) + vein[None, None, :] * w[..., None]
    rgba = np.concatenate([img, np.ones((size, size, 1))], axis=2).astype(np.float32)
    im = bpy.data.images.new(name, size, size, alpha=False)
    im.pixels.foreach_set(rgba.ravel())
    im.pack()
    return im


def leaf_material(name, base_hex, vein_hex, rough=0.55):
    """Leaf: generated vein map as base colour, light subsurface, double-sided."""
    m = material(name, lin(base_hex), rough=rough, sss=0.12)
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = leaf_texture("T_" + name + "_BaseColor", base_hex, vein_hex)
    nt.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    return m


# ---------------------------------------------------------------- the plant at each stage and pose
def seed(mat):
    """Acid-delinted cotton seed, ovoid 9.5 x 5.5 mm, resting half-covered in its sowing dimple."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=16, radius=0.00275, location=(0, 0, 0))
    o = bpy.context.object
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        t = (v.co.z / 0.00275 + 1) / 2                  # 0 chalazal (blunt) end .. 1 micropylar (pointed) end
        v.co.z *= 1.72
        s = 1.0 - 0.45 * max(0.0, t - 0.55) / 0.45     # taper to the pointed end
        v.co.x *= s
        v.co.y *= s * 0.92
    bm.to_mesh(o.data)
    bm.free()
    for p in o.data.polygons:
        p.use_smooth = True
    o.name = "Seed"
    o.data.materials.append(mat)
    o.rotation_euler = (math.radians(74), 0.0, math.radians(28))   # lying in the dimple, point slightly down
    o.location = (0.0, 0.0, SOIL_Z - 0.0022)
    return o


def dimple(mat):
    """Sowing dimple pressed into the soil: a shallow bowl whose rim sits a little proud of the surface."""
    R, depth, lip = DIMPLE_R, DIMPLE_DEPTH, 0.0014
    bm = bmesh.new()
    rings = []
    for k in range(1, 7):
        r = R * k / 6
        z = -depth * (1 - (r / R) ** 2) + lip * max(0.0, r / R - 0.75) / 0.25
        rings.append([bm.verts.new((r * math.cos(2 * math.pi * i / 40), r * math.sin(2 * math.pi * i / 40), z)) for i in range(40)])
    c = bm.verts.new((0.0, 0.0, -depth))
    for i in range(40):
        bm.faces.new((c, rings[0][i], rings[0][(i + 1) % 40]))
    for a, b in zip(rings, rings[1:]):
        for i in range(40):
            j = (i + 1) % 40
            bm.faces.new((a[i], b[i], b[j], a[j]))
    import random
    rnd = random.Random(5)
    for v in bm.verts:
        if math.hypot(v.co.x, v.co.y) > 0.003:
            v.co.z += rnd.uniform(-0.0005, 0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new("Dimple")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    o = bpy.data.objects.new("Dimple", me)
    bpy.context.collection.objects.link(o)
    o.location = (0.0, 0.0, SOIL_Z - DIMPLE_SINK)
    o.data.materials.append(mat)
    return o


def plant(stage, pose, mats):
    """Procedural plant parts for `stage` in `pose` ('base', 'thirst', 'cold'). Same part order in every pose."""
    thirst = pose == "thirst"
    cold = pose == "cold"
    parts = []
    if stage == "sprout":
        h, lean = 0.038, 0.004
        cot_w, cot_l, pitch = 0.034, 0.024, 20.0
        pet = 0.007
    else:
        h, lean = 0.054, 0.006
        cot_w, cot_l, pitch = 0.042, 0.029, 12.0
        pet = 0.010
    if thirst:
        lean *= 3.2
    top = Vector((lean, 0.0, SOIL_Z + h))
    hyp = [(0.0, 0.0, SOIL_Z - 0.006), (lean * 0.15, 0.0, SOIL_Z + 0.35 * h), (lean * 0.55, 0.0, SOIL_Z + 0.78 * h), tuple(top)]
    parts.append(tube("Hypocotyl", hyp, 0.0016, mats["stem"], taper=0.78))
    out, att = outline_reniform(cot_w, cot_l)
    for yaw in (90.0, -90.0):
        side = 1.0 if yaw == -90.0 else -1.0
        pet_end = top + Vector((side * pet, 0.0, 0.0022 if not thirst else -0.0012))
        mid = (top + pet_end) / 2 + Vector((0.0, 0.0, 0.0012))
        parts.append(tube("CotPetiole", [tuple(top), tuple(mid), tuple(pet_end)], 0.0007, mats["stem"]))
        b = blade("Cotyledon", out, att, mats["cotyledon"],
                  cup=0.06 if not cold else -0.30, droop=0.0 if not thirst else 0.55, curl=0.0 if not cold else 0.40)
        place(b, pet_end, yaw, pitch - (38.0 if thirst else 14.0 if cold else 0.0))
        parts.append(b)
    if stage == "seedling":
        # first true leaf above the cotyledons, offset 90 degrees from them, plus the second leaf as a small folded blade
        node = top + Vector((0.0, 0.0, 0.004))
        parts.append(tube("Epicotyl", [tuple(top), tuple(node + Vector((0, 0, 0.012))), tuple(node + Vector((0, 0.002, 0.022)))], 0.0012, mats["stem"], taper=0.7))
        leaf_base = node + Vector((0.0, 0.002, 0.020))
        pet_end = leaf_base + Vector((0.0, 0.012, 0.006 if not thirst else -0.004))
        parts.append(tube("LeafPetiole", [tuple(leaf_base), tuple((leaf_base + pet_end) / 2 + Vector((0, 0, 0.002))), tuple(pet_end)], 0.0008, mats["petiole"]))
        out2, att2 = outline_cordate(0.040, 0.042)
        b = blade("TrueLeaf", out2, att2, mats["leaf"],
                  cup=0.05 if not cold else -0.28, droop=0.0 if not thirst else 0.5, curl=0.0 if not cold else 0.38)
        place(b, pet_end, 0.0, -48.0 if thirst else -24.0 if cold else -12.0)
        parts.append(b)
        tip = node + Vector((0.0, 0.002, 0.024))
        out3, att3 = outline_cordate(0.012, 0.014)
        b2 = blade("SecondLeafBud", out3, att3, mats["leaf"], cup=0.9 if not cold else 0.9, droop=0.0, curl=0.0)
        place(b2, tip, 180.0, 70.0 if not thirst else 40.0)
        parts.append(b2)
    return parts


def join(parts, name):
    """Convert curves to meshes, join into one object with that name, origin at the world origin."""
    bpy.ops.object.select_all(action="DESELECT")
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.convert(target="MESH")
    bpy.ops.object.select_all(action="DESELECT")
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    o = bpy.context.object
    o.name = o.data.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.shade_smooth()
    return o


def build(stage, out_dir):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    soil = material("CottonSoil", lin("#4A4336"), rough=0.98)
    mats = {
        "stem": material("CottonStem", lin("#7E5A52"), rough=0.5, sss=0.08, double=False),     # reddish hypocotyl
        "petiole": material("CottonPetiole", lin("#6E8A4A"), rough=0.5, double=False),
        "cotyledon": leaf_material("CottonCotyledon", "#6FA04A", "#9CC276"),
        "leaf": leaf_material("CottonLeaf", "#4F8540", "#86B06C", rough=0.65),
        "seed": material("CottonSeed", lin("#3B2A1E"), rough=0.75, double=False),
    }
    objs = [pot()]
    if stage == "seed":
        objs += [dimple(soil), seed(mats["seed"])]
    else:
        objs.append(soil_cap(mat=soil))
        base = join(plant(stage, "base", mats), "Plant")
        for pose, key in (("thirst", "Thirst"), ("cold", "Cold")):
            alt = join(plant(stage, pose, mats), "Plant_" + pose)
            if len(alt.data.vertices) != len(base.data.vertices):
                raise RuntimeError(f"{stage} {pose}: vertex count differs from the base pose")
            if base.data.shape_keys is None:
                base.shape_key_add(name="Basis", from_mix=False)
            sk = base.shape_key_add(name=key, from_mix=False)
            for i, v in enumerate(alt.data.vertices):
                sk.data[i].co = v.co
            bpy.data.objects.remove(alt)
        for kb in base.data.shape_keys.key_blocks:
            kb.value = 0.0          # the GLB's default weights must be the healthy pose
        objs.append(base)
    # measure
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    tris = 0
    for o in objs:
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        pts += [oe.matrix_world @ v.co for v in me.vertices]
        tris += sum(len(p.vertices) - 2 for p in me.polygons)
        oe.to_mesh_clear()
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    name = {"seed": "PL_Cotton_Seed", "sprout": "PL_Cotton_Sprout", "seedling": "PL_Cotton_Seedling"}[stage]
    d = os.path.join(out_dir, name)
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, name + ".glb")
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_morph=True, export_morph_normal=False,
                              export_animations=False, export_skins=False, export_image_format="JPEG",
                              export_jpeg_quality=90)
    print(f"STAGE {name} height={mx.z - mn.z:.4f} size=({mx.x - mn.x:.4f},{mx.y - mn.y:.4f}) min_z={mn.z:.4f} tris={tris} file={path}")


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = argv[0]
    for st in (argv[1:] or ["seed", "sprout", "seedling"]):
        build(st, out)
