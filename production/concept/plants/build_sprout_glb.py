"""Build the runtime seedling GLBs PL_Alo_Sprout and PL_Tara_Sprout (M1-07; no AI generation, no credits).

Usage:
  blender -b --factory-startup --python build_sprout_glb.py -- [<preview_dir>]

Design: the cotyledon and true-leaf states approved by Sadman on 5 Nov 2026 (M3-99 sheet,
production/concept/narrative_props/, handbook §3). The leaf outlines and dimensions are imported from that
sheet's own builder (build_plant_panels.py), so the shipped seedlings are the approved ones.

Each GLB keeps the plant's existing pot, so a stage swap never changes the container: the pot and soil are cut
out of PL_Alo_Bud (Alo) or PL_Tara_Bloom (Tara) with the plant removed, and the stem hole is capped with the
same soil texel. Three stage nodes sit on the soil at the old stem position:

  Stage_Seed       11 Apr (day 0): a 1.5 mm seed pressed into a moist spot (Fast Plants sowing)
  Stage_Cotyledon  12-13 Apr (days 1-3): purple (Alo) or green (Tara) hypocotyl, two notched seed leaves
  Stage_TrueLeaf   15-17 Apr (days 4-6): first toothed true leaves above the cotyledons

Cotyledon and true-leaf meshes carry two morph targets for posture, never a face:
  Droop  thirst (leaves hang, hypocotyl bows)
  Cup    cold (blades cup upwards and lift)

Botany: Brassica rapa (ART_BIBLE §2 rule 8, §6). Alo's stem is purple and Tara's green at every stage.
The biology service owns which state shows (PlantService.seedling_form); this file only supplies the art.
"""
import bpy, bmesh, colorsys, math, os, sys
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "production", "concept", "narrative_props"))
import sheet_common as C                        # noqa: E402  (Blender-only helpers)
import build_plant_panels as P                  # noqa: E402  (approved seedling outlines)

PLANTS = os.path.join(ROOT, "game", "assets", "plants")

SPECIES = {
    # name: source pot GLB, stem colour, petiole colour of the true leaves
    "PL_Alo_Sprout": {"pot": "PL_Alo_Bud", "stem": "#6E3E6C", "petiole": "#5F7F45"},
    "PL_Tara_Sprout": {"pot": "PL_Tara_Bloom", "stem": "#5E8E3E", "petiole": "#5F7F45"},
}
SEED_HEX = "#4A2619"           # Brassica rapa seed: dark reddish brown, about 1.5 mm
MOIST_HEX = "#271C15"          # freshly watered soil around the sown seed


# ---------------------------------------------------------------- pot (cut from the existing plant)
def cut_pot(src):
    """Return (pot object, soil height at the stem, stem axis xy, ground(x, y) height function) with the plant
    removed and a fresh soil surface laid in."""
    o = C.import_glb(os.path.join(PLANTS, src, src + ".glb"))
    P.bake_transforms(o)
    o.name = "Pot"
    o.data.name = "Pot"
    me = o.data
    a = np.array([v.co[:] for v in me.vertices])
    r = np.maximum(np.abs(a[:, 0]), np.abs(a[:, 1]))
    # Slice upwards in 1 mm steps: the pot is wide; the first slice holding only the stem is above the lip.
    # (P.soil_height reads the wall below 20 % of the height, which cuts the 0.2 m bud's pot too low.)
    pot_r = r[(a[:, 2] > 0.004) & (a[:, 2] < 0.02)].max()
    cut_z = next(z for z in np.arange(0.01, a[:, 2].max(), 0.001)
                 if 0 < np.count_nonzero((a[:, 2] >= z) & (a[:, 2] < z + 0.001))
                 and r[(a[:, 2] >= z) & (a[:, 2] < z + 0.001)].max() < 0.5 * pot_r)
    wall_top = float(a[(r > 0.7 * pot_r) & (a[:, 2] < cut_z), 2].max())
    stem = a[(a[:, 2] >= cut_z) & (a[:, 2] < cut_z + 0.008) & (r < 0.5 * pot_r)]
    axis = Vector((float(np.median(stem[:, 0])), float(np.median(stem[:, 1])), 0))
    d = np.hypot(a[:, 0] - axis.x, a[:, 1] - axis.y)
    soil_z = float(np.median(a[(d > 0.006) & (d < 0.6 * pot_r) & (a[:, 2] > wall_top - 0.02) & (a[:, 2] < wall_top), 2]))
    bm = bmesh.new(); bm.from_mesh(me)
    uv = bm.loops.layers.uv.active
    soil_rgb = soil_colours(o, bm, uv, axis, soil_z)
    # Remove the plant: everything above the lip, and the stem stub down into the soil.
    near = lambda c, rad: (Vector((c.x, c.y, 0)) - axis).length < rad
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z > wall_top + 0.0005
                               or (near(v.co, 0.008) and v.co.z > soil_z - 0.004)], context='VERTS')
    # New soil surface just above the old one: the stem's root collar and the Tripo soil's fragmented UV islands
    # cannot be patched cleanly, so the old surface is buried and a clean one laid over it.
    top = soil_z + 0.0012
    walls = bm.copy()                                      # rays see only the near-vertical wall faces
    bmesh.ops.delete(walls, geom=[f for f in walls.faces if abs(f.normal.z) > 0.6], context='FACES')
    tree = BVHTree.FromBMesh(walls)

    def wall(direction):
        """Distance from the stem axis to the pot's inner wall at the new soil height."""
        hit = tree.ray_cast(Vector((axis.x, axis.y, top)), direction, 0.2)[0]
        return (Vector((hit.x, hit.y, 0)) - Vector((axis.x, axis.y, 0))).length if hit else 0.03

    hx = (wall(Vector((-1, 0, 0))), wall(Vector((1, 0, 0))))
    hy = (wall(Vector((0, -1, 0))), wall(Vector((0, 1, 0))))

    def covered(v):
        """True when the new surface lies over this old vertex (keeps the old soil at the rounded corners)."""
        d = Vector((v.co.x - axis.x, v.co.y - axis.y, 0))
        return d.length < 1e-6 or d.length < wall(d.normalized()) + 0.0003

    # Old soil humps and leaf scraps under the lip: any near-horizontal surface the new soil covers.
    # Wall vertices keep at least one steep face, so the walls and the lip stay.
    poke = [v for v in bm.verts if v.co.z > top - 0.0008 and v.co.z < wall_top - 0.001 and covered(v)
            and all(abs(f.normal.z) > 0.35 for f in v.link_faces)]
    bmesh.ops.delete(bm, geom=poke, context='VERTS')       # old humps that would show through
    # Plant tissue left against the walls (leaf tips, stem flare): faces above the old soil whose own texel is
    # leaf green or stem purple, as the M3-99 remap classifies hues (brightness alone would take the glossy lip).
    tex = next(n for n in o.active_material.node_tree.nodes if n.type == 'TEX_IMAGE').image
    tw, th = tex.size
    px = np.array(tex.pixels[:], dtype=np.float32).reshape(th, tw, tex.channels)[..., :3]
    tissue = []
    for f in bm.faces:
        if f.calc_center_median().z < soil_z - 0.002:
            continue
        u = sum(l[uv].uv.x for l in f.loops) / len(f.loops); v = sum(l[uv].uv.y for l in f.loops) / len(f.loops)
        rgb = px[min(th - 1, int((v % 1) * th)), min(tw - 1, int((u % 1) * tw))] ** (1 / 2.2)
        hh, ss, vv = colorsys.rgb_to_hsv(*rgb)
        if ss > 0.22 and (0.15 < hh < 0.5 or 0.66 < hh < 0.97):
            tissue.append(f)
    bmesh.ops.delete(bm, geom=tissue, context='FACES')
    print(f"tissue faces removed: {len(tissue)}")
    N = 44
    rng = np.random.default_rng(11)
    bumps = rng.normal(0, 1, (6, 4))                      # a few soft lumps, fixed seed (deterministic build)

    def ground(x, y):
        """Height of the new soil surface at offset (x, y) from the stem axis."""
        h = sum(0.00045 * b[0] * math.exp(-((x - 0.012 * b[1]) ** 2 + (y - 0.012 * b[2]) ** 2) / (2 * (0.006 + 0.002 * abs(b[3])) ** 2))
                for b in bumps)
        return top + h + 0.0007 * math.exp(-(x ** 2 + y ** 2) / (2 * 0.004 ** 2))   # firmed mound over the seed
    verts = {}
    for i in range(N + 1):
        for j in range(N + 1):
            x = -hx[0] - 0.0008 + (hx[0] + hx[1] + 0.0016) * i / N
            y = -hy[0] - 0.0008 + (hy[0] + hy[1] + 0.0016) * j / N
            p = Vector((x, y, 0))
            if p.length > 1e-6:                            # clip the rounded inner corners to the wall
                lim = wall(Vector((x, y, 0)).normalized()) + 0.0006
                if p.length > lim:
                    p = p.normalized() * lim
            verts[(i, j)] = bm.verts.new((axis.x + p.x, axis.y + p.y, ground(p.x, p.y)))
    mat_index = len(o.data.materials)
    o.data.materials.append(soil_material("PotSoil", soil_rgb))
    span = max(hx[0] + hx[1], hy[0] + hy[1]) + 0.0016
    for i in range(N):
        for j in range(N):
            f = bm.faces.new((verts[(i, j)], verts[(i + 1, j)], verts[(i + 1, j + 1)], verts[(i, j + 1)]))
            f.smooth = True
            f.material_index = mat_index
            for l in f.loops:
                l[uv].uv = ((l.vert.co.x - axis.x + hx[0]) / span, (l.vert.co.y - axis.y + hy[0]) / span)
    walls.free()
    bm.to_mesh(me); bm.free()
    return o, ground(0.0, 0.0), axis, ground


def soil_colours(o, bm, uv, axis, soil_z):
    """Median and speck colours of the source pot's soil, read from its own texture (linear RGB)."""
    tex = next(n for n in o.active_material.node_tree.nodes if n.type == 'TEX_IMAGE').image
    w, h = tex.size
    px = np.array(tex.pixels[:], dtype=np.float32).reshape(h, w, tex.channels)[..., :3]
    cols = []
    for f in bm.faces:
        c = f.calc_center_median()
        if f.normal.z > 0.8 and abs(c.z - soil_z) < 0.003 and 0.010 < (Vector((c.x, c.y, 0)) - axis).length < 0.025:
            for l in f.loops:
                u, v = l[uv].uv
                cols.append(px[min(h - 1, int((v % 1) * h)), min(w - 1, int((u % 1) * w))])
    cols = np.array(cols)
    lum = cols.mean(axis=1)
    return {"base": np.median(cols, axis=0), "dark": np.percentile(cols, 15, axis=0),
            "speck": cols[lum >= np.percentile(lum, 97)].mean(axis=0)}


def soil_material(name, rgb):
    """Potting mix: the source soil's own colours as fine grain, darker clods and pale perlite specks."""
    n = 512
    rng = np.random.default_rng(7)
    def smooth(scale):
        g = rng.random((n // scale + 2, n // scale + 2))
        g = np.kron(g, np.ones((scale, scale)))[:n, :n]
        k = np.ones(scale) / scale                        # box blur both ways
        g = np.apply_along_axis(lambda r: np.convolve(r, k, mode="same"), 0, g)
        return np.apply_along_axis(lambda r: np.convolve(r, k, mode="same"), 1, g)
    clods = np.clip((smooth(24) - 0.35) * 2.2, 0, 1)
    grain = rng.random((n, n))
    img_rgb = rgb["base"] * (1 - clods[..., None]) + rgb["dark"] * clods[..., None]
    img_rgb *= (0.85 + 0.3 * grain)[..., None]
    specks = rng.random((n, n)) > 0.985
    img_rgb[specks] = rgb["speck"]
    img = bpy.data.images.new(name, n, n, alpha=False)
    out = np.ones((n, n, 4), dtype=np.float32); out[..., :3] = np.clip(img_rgb, 0, 1)
    img.pixels.foreach_set(out.ravel()); img.pack()
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    t = m.node_tree.nodes.new("ShaderNodeTexImage"); t.image = img
    m.node_tree.links.new(t.outputs[0], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.95
    return m


# ---------------------------------------------------------------- export-friendly materials
def leaf_texture(name, base_hex, vein_hex, true_leaf):
    """Albedo with a pale midrib and pinnate veins on the blade's own UVs (u across, v base->tip)."""
    n = 256
    u, v = np.meshgrid(np.linspace(0, 1, n), np.linspace(0, 1, n))
    base = np.array(P.lin(base_hex)[:3]); vein = np.array(P.lin(vein_hex)[:3])
    d = np.abs(u - 0.5)
    rib = np.clip(1 - d / (0.022 if true_leaf else 0.016), 0, 1) ** 1.5 * (1 - 0.6 * v)
    # side veins leave the midrib towards the tip and the margin
    k = 9 if true_leaf else 5
    phase = (v - d * 1.15) * k
    side = np.clip(1 - np.abs(phase - np.round(phase)) / 0.06, 0, 1) * np.clip(d / 0.03, 0, 1) * (1 - 0.7 * v)
    side *= 0.55 if true_leaf else 0.35
    shade = 1 - 0.10 * np.clip((d - 0.3) / 0.2, 0, 1) + 0.04 * (v - 0.5)
    w = np.clip(np.maximum(rib, side), 0, 1)[..., None]
    rgb = (base * (1 - w) + vein * w) * shade[..., None]
    img = bpy.data.images.new(name, n, n, alpha=False)
    px = np.ones((n, n, 4), dtype=np.float32); px[..., :3] = np.clip(rgb, 0, 1)
    img.pixels.foreach_set(px.ravel())
    img.pack()
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    t = m.node_tree.nodes.new("ShaderNodeTexImage"); t.image = img
    m.node_tree.links.new(t.outputs[0], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.6 if true_leaf else 0.5
    return m


def flat(name, hexstr, rough=0.5):
    return C.material(name, P.lin(hexstr), rough=rough)


# ---------------------------------------------------------------- seedling geometry (approved dimensions)
def blade(name, outline, length, mat, cup, curl=0.0, rings=3):
    """P.blade with fewer rings (runtime budget); same outline, length and cupping law."""
    xs = [p[0] for p in outline]; ys = [p[1] for p in outline]
    sc = length / (max(ys) - min(ys)); w = (max(xs) - min(xs)) * sc / 2
    cy = (max(ys) + min(ys)) / 2
    bm = bmesh.new(); uv = bm.loops.layers.uv.new()
    rs = []
    for k in range(1, rings + 1):
        f = k / rings
        rs.append([bm.verts.new((x * f * sc, (cy + (y - cy) * f) * sc,
                                 cup * length * ((x * f * sc) / w) ** 2 + curl * length * (((cy + (y - cy) * f) * sc / length) ** 2)))
                   for x, y in outline])
    c = bm.verts.new((0, cy * sc, 0)); n = len(outline)
    for i in range(n):
        bm.faces.new((c, rs[0][i], rs[0][(i + 1) % n]))
    for k in range(rings - 1):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((rs[k][i], rs[k + 1][i], rs[k + 1][j], rs[k][j]))
    for f in bm.faces:
        f.smooth = True
        for l in f.loops:
            l[uv].uv = (l.vert.co.x / (2 * w) + 0.5, l.vert.co.y / length)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    o.modifiers.new("thick", 'SOLIDIFY').thickness = 0.00035
    o.data.materials.append(mat)
    return o


def tube(name, pts, radius, mat):
    o = P.tube(name, pts, radius, mat)
    o.data.bevel_resolution = 2
    o.data.resolution_u = 6
    return o


def realise(objs, name):
    """Convert curves, apply modifiers and join into one mesh named `name`."""
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    meshes = []
    for o in objs:
        oe = o.evaluated_get(dg)
        me = bpy.data.meshes.new_from_object(oe, depsgraph=dg)
        me.transform(o.matrix_world)
        n = bpy.data.objects.new(o.name, me); bpy.context.collection.objects.link(n)
        meshes.append(n)
    for o in objs:
        bpy.data.objects.remove(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    j = bpy.context.view_layer.objects.active
    j.name = name; j.data.name = name
    return j


def seedling(name, soil_z, axis, mats, true_leaves, pose):
    """One seedling mesh; pose = 'rest', 'droop' or 'cup' (same topology for morph targets)."""
    droop, cold = pose == "droop", pose == "cup"
    h = 0.032 if true_leaves else 0.022                 # approved: ~2 cm at days 1-2, 3-4 cm at days 4-6
    bow = (0.006 if true_leaves else 0.005) if droop else 0.0
    top = Vector((axis.x + 0.0015 + bow, axis.y, soil_z + h - (0.003 if droop else 0.0)))
    stem = [(axis.x, axis.y, soil_z - 0.004), (axis.x + 0.0004 + bow * 0.2, axis.y, soil_z + h * 0.4),
            (axis.x + 0.0012 + bow * 0.7, axis.y, soil_z + h * 0.8), tuple(top)]
    parts = [tube("Hypocotyl", stem, 0.0011, mats["stem"])]
    coty_len = 0.0115 if true_leaves else 0.0095
    base_pitch = 14 if true_leaves else 22
    pitch = base_pitch - 40 if droop else base_pitch + 14 if cold else base_pitch
    for yaw in (90, -90):
        pet_end = top + Vector((0.0035 * (1 if yaw == -90 else -1), 0, 0.0012 - (0.0012 if droop else 0)))
        parts.append(tube("CotPetiole", [tuple(top), tuple((top + pet_end) / 2 + Vector((0, 0, 0.0008))), tuple(pet_end)],
                          0.0005, mats["stem"]))
        b = blade("Cotyledon", P.outline_heart(40), coty_len, mats["coty"], cup=0.30 if cold else 0.10)
        P.place(b, pet_end, yaw, pitch)
        parts.append(b)
    if true_leaves:
        for yaw, ln, p, rise in ((0, 0.024, -38, 0.010), (180, 0.019, -48, 0.012), (35, 0.010, -62, 0.014)):
            base = top + Vector((0, 0, 0.002))
            d = Vector((-math.sin(math.radians(yaw)), math.cos(math.radians(yaw)), 0))
            r = rise * (0.45 if droop else 1.0)
            end = base + d * 0.005 + Vector((0, 0, r * 0.5))
            parts.append(tube("Petiole", [tuple(base), tuple(base + d * 0.002 + Vector((0, 0, r * 0.35))), tuple(end)],
                              0.0006, mats["petiole"]))
            b = blade("TrueLeaf", P.outline_true_leaf(72, 11), ln, mats["leaf"], cup=0.32 if cold else 0.12,
                      curl=-0.05 if not droop else -0.22)
            P.place(b, end, yaw, -p - (38 if droop else 0) + (12 if cold else 0))
            parts.append(b)
    return realise(parts, name)


def with_posture(name, soil_z, axis, mats, true_leaves):
    """Rest mesh with Droop and Cup morph targets."""
    rest = seedling(name, soil_z, axis, mats, true_leaves, "rest")
    for pose, key in (("droop", "Droop"), ("cup", "Cup")):
        other = seedling(key, soil_z, axis, mats, true_leaves, pose)
        assert len(other.data.vertices) == len(rest.data.vertices), "pose changed topology"
        if rest.data.shape_keys is None:
            rest.shape_key_add(name="Basis")
        sk = rest.shape_key_add(name=key)
        co = np.empty(len(other.data.vertices) * 3, dtype=np.float32)
        other.data.vertices.foreach_get("co", co)
        sk.data.foreach_set("co", co)
        sk.value = 0.0                                     # exported as the default glTF weight: rest posture
        bpy.data.objects.remove(other)
    return rest


def seed_stage(ground, axis, mats):
    """A sown seed: 1.5 mm reddish-brown bead half pressed into a small moist spot that follows the soil."""
    sx, sy = 0.0008, -0.0005
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.00075,
                                         location=(axis.x + sx, axis.y + sy, ground(sx, sy) + 0.00035))
    seed = bpy.context.object; seed.scale = (1.0, 0.9, 0.8)
    seed.data.materials.append(mats["seed"])
    bm = bmesh.new()
    rings, seg, rad = 4, 24, 0.0042
    centre = bm.verts.new((axis.x, axis.y, ground(0, 0) + 0.00012))
    rows = [[bm.verts.new((axis.x + rad * k / rings * math.cos(2 * math.pi * i / seg),
                           axis.y + rad * k / rings * math.sin(2 * math.pi * i / seg),
                           ground(rad * k / rings * math.cos(2 * math.pi * i / seg),
                                  rad * k / rings * math.sin(2 * math.pi * i / seg)) + 0.00012))
             for i in range(seg)] for k in range(1, rings + 1)]
    for i in range(seg):
        bm.faces.new((centre, rows[0][i], rows[0][(i + 1) % seg]))
    for k in range(rings - 1):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((rows[k][i], rows[k + 1][i], rows[k + 1][j], rows[k][j]))
    me = bpy.data.meshes.new("MoistSpot"); bm.to_mesh(me); bm.free()
    spot = bpy.data.objects.new("MoistSpot", me); bpy.context.collection.objects.link(spot)
    spot.data.materials.append(mats["moist"])
    return realise([seed, spot], "Stage_Seed")


def build(name, spec):
    """Build one species' GLB into game/assets/plants/<name>/<name>.glb. Returns the stage objects."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pot, soil_z, axis, ground = cut_pot(spec["pot"])
    mats = {
        "stem": flat(name + "_Stem", spec["stem"], 0.45),
        "petiole": flat(name + "_Petiole", spec["petiole"], 0.5),
        "coty": leaf_texture(name + "_Cotyledon", "#5E9B3C", "#8FBF6A", False),
        "leaf": leaf_texture(name + "_TrueLeaf", "#4E7F3A", "#7FA866", True),
        "seed": flat(name + "_Seed", SEED_HEX, 0.4),
        "moist": flat(name + "_MoistSoil", MOIST_HEX, 0.9),
    }
    stages = [seed_stage(ground, axis, mats),
              with_posture("Stage_Cotyledon", soil_z, axis, mats, False),
              with_posture("Stage_TrueLeaf", soil_z, axis, mats, True)]
    for o in stages:
        o["soil_z"] = soil_z
    out = os.path.join(PLANTS, name, name + ".glb")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_apply=True, export_morph=True,
                              export_yup=True, export_extras=False, export_animations=False)
    print(f"BUILT {name}: soil {soil_z:.4f} m, axis ({axis.x:.4f}, {axis.y:.4f}), "
          + ", ".join(f"{o.name} {len(o.data.polygons)} faces" for o in [pot] + stages))
    return pot, stages


if __name__ == "__main__":
    for n, s in SPECIES.items():
        build(n, s)
