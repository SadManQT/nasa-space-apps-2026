"""M3-99: build the approved Alo/Tara stage variants and the narrative props as runtime GLBs.

Blender 5.2, no AI generation, no credits. Source of truth: the 2D sheets Sadman approved on 5 Nov 2026
(production/concept/narrative_props/, PRODUCTION_HANDBOOK.md §3 "all are approved"). This script reuses the
sheet scripts' own colour remap, lean and geometry code, so what ships is what was approved.

Usage (repository root, through the heavy-process gate; Cycles bakes at 4 samples on 4 threads):
  python3 production/tools/heavy.py /opt/homebrew/bin/blender -b --factory-startup -t 4 \
      --python production/concept/narrative_props/build_runtime_assets.py -- [--only ID ...] [--preview DIR]

Writes
  game/assets/plants/<PL_id>/<PL_id>.glb        six stage variants of the PL_Alo_Pods Tripo mesh (texture bake + lean)
  game/assets/props/narrative/<PR_id>.glb        five props (procedural geometry, baked 512/1024 px PBR sets)
  game/assets/props/narrative/narrative_props.json   generated catalogue: sizes, triangles, text anchors, mug arc
  DIR/<PL_id>.png (only with --preview)              Cycles renders of the exported plant GLBs in the sheet's framing,
                                                     for comparing the bake with the approved panels (M3-99_bake_vs_approved.png)

Plants: the remap classifies the baked Tripo colour by hue (purple stem, warm yellow/straw, green) and recolours it,
exactly as the approval panels did in the shader; here the result is baked into a new 2048 px base-colour map on the
same UVs. Leaning stems rotate positions and custom normals together. Tara's variants mirror the mesh (winding and
normals corrected), so the two plants never read as copies. No flowers exist at these stages; no plant has a face.

Props: no text, numbers or logos are modelled or baked (ART_BIBLE §7). Every word is drawn at runtime by
game/assets/props/narrative/narrative_props.gd from narrative_props_content.json onto the `Text_*` anchors and the
mug's `NameArc`. Anchor convention: Godot local +Z leaves the surface (the reading side), +Y is the text's up.
"""
import bpy, bmesh, json, math, os, shutil, sys, tempfile
import numpy as np
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)  # the approval-sheet scripts live beside this one
import sheet_common as C          # noqa: E402  (studio framing, material helper, GLB import)
import build_plant_panels as P    # noqa: E402  (approved remap, lean, soil line)
import build_prop_panels as PP    # noqa: E402  (approved paper, brushed metal, primitives, gear outline)

PLANT_DIR = os.path.join(ROOT, "game", "assets", "plants")
PROP_DIR = os.path.join(ROOT, "game", "assets", "props", "narrative")
SOURCE_POD = os.path.join(PLANT_DIR, "PL_Alo_Pods", "PL_Alo_Pods.glb")
SOURCE_MUG = os.path.join(ROOT, "game", "assets", "props", "PR_Mug", "PR_Mug.glb")

# id: (stem, foliage, lean degrees, mirrored, date and code stage). Values are build_plant_panels.PANELS, unchanged.
PLANTS = {
    "PL_Alo_PodsGreen": (None, "green", 0, False, "8 May 2046 (day 27), pod_bearing"),
    "PL_Alo_Senescent": (None, None, 18, False, "16 May 2046 (day 35), mature_pods"),
    "PL_Alo_Dry": ("alo_dry", "dry", 28, False, "16-21 May 2046 (day 35-40), mature_dry"),
    "PL_Tara_Pods": ("green", "green", 0, True, "8-26 May 2046, pod_bearing"),
    "PL_Tara_Senescent": ("green", None, 16, True, "26 May 2046 (day 45), mature_pods"),
    "PL_Tara_Dry": ("tara_dry", "dry", 25, True, "26-31 May 2046 (day 45-50), mature_dry"),
}
PROPS = ["PR_LabelHolder", "PR_Mug_Named", "PR_ToolTag_Gear", "PR_DrawerLidNote", "PR_WorkingStockEnvelope"]
MUG_NAMES = ["KAI", "AMARA", "MEI", "RAFI", "FERREIRA"]
TAPE_Z, TAPE_H, TEXT_Z = 0.052, 0.021, 0.0512  # the approval sheet's tape centre, tape height and text line
BAKE_SAMPLES = 4
TMP = tempfile.mkdtemp(prefix="m399_")
DRY_ROUGHNESS = 0.85  # the approval panels' dry-foliage roughness


# ------------------------------------------------------------------------------------------------ scene
def reset():
    """Empty scene, Cycles CPU on 4 threads, few samples (bakes are emission/normal passes, not lighting)."""
    sc = C.reset()
    sc.cycles.samples = BAKE_SAMPLES
    sc.render.threads_mode = 'FIXED'
    sc.render.threads = 4
    sc.render.bake.margin = 16
    sc.render.bake.margin_type = 'EXTEND'
    return sc


def select_only(objs, active=None):
    bpy.context.view_layer.update()
    for o in bpy.context.view_layer.objects:
        if o is not None:
            o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or (objs[0] if objs else None)


def triangles(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def signed_volume(me):
    """Sum of signed tetra volumes; its sign tells whether the faces wind outwards."""
    co = np.empty(len(me.vertices) * 3, np.float64)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    me.calc_loop_triangles()
    tri = np.empty(len(me.loop_triangles) * 3, np.int64)
    me.loop_triangles.foreach_get("vertices", tri)
    t = co[tri.reshape(-1, 3)]
    return float(np.einsum("ij,ij->i", t[:, 0], np.cross(t[:, 1], t[:, 2])).sum() / 6.0)


def corner_normals(me):
    return [Vector(c.vector) for c in me.corner_normals]


def reverse_winding(me):
    """Reverse every face's winding (loops reversed in place; polygon order is kept)."""
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()


def mirror_x(obj):
    """Mirror the mesh in x with correct winding and custom normals (a negative scale would invert both)."""
    me = obj.data
    normals = corner_normals(me)
    keyed = {}
    for poly in me.polygons:
        for li in poly.loop_indices:
            keyed[(poly.index, me.loops[li].vertex_index)] = normals[li]
    for v in me.vertices:
        v.co.x = -v.co.x
    reverse_winding(me)
    out = []
    for poly in me.polygons:
        for li in poly.loop_indices:
            n = keyed[(poly.index, me.loops[li].vertex_index)]
            out.append((-n.x, n.y, n.z))
    me.normals_split_custom_set(out)


def lean_with_normals(obj, degrees, base_z):
    """The approved lean (rotation about y growing with height above the soil), applied to custom normals too."""
    me = obj.data
    normals = corner_normals(me)
    ztop = max(v.co.z for v in me.vertices)
    rot = {}
    for v in me.vertices:
        if v.co.z <= base_z:
            continue
        ang = math.radians(degrees) * (v.co.z - base_z) / (ztop - base_z)
        m = Matrix.Rotation(ang, 3, 'Y')
        rot[v.index] = m
        v.co = m @ (v.co - Vector((0, 0, base_z))) + Vector((0, 0, base_z))
    out = []
    for loop, n in zip(me.loops, normals):
        m = rot.get(loop.vertex_index)
        out.append(tuple((m @ n) if m else n))
    me.normals_split_custom_set(out)


# ------------------------------------------------------------------------------------------------ baking
def _output(nt):
    return next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output)


def new_image(name, size, colorspace, fmt):
    img = bpy.data.images.new(name, size, size, alpha=False, float_buffer=False)
    img.colorspace_settings.name = colorspace
    img.file_format = fmt
    return img


def bake_input(objs, input_name, image, override=None):
    """Bake what feeds every material's Principled `input_name` (or `override` socket) into `image` via emission."""
    restore = []
    for mat in {s.material for o in objs for s in o.material_slots if s.material}:
        nt = mat.node_tree
        bsdf = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
        out = _output(nt)
        surface = out.inputs["Surface"].links[0].from_socket
        em = nt.nodes.new("ShaderNodeEmission")
        src = override.get(mat.name) if override else None
        sock = bsdf.inputs[input_name]
        if src is not None:
            nt.links.new(src, em.inputs["Color"])
        elif sock.is_linked:
            nt.links.new(sock.links[0].from_socket, em.inputs["Color"])
        else:
            v = sock.default_value
            em.inputs["Color"].default_value = tuple(v) if hasattr(v, "__len__") else (v, v, v, 1.0)
        nt.links.new(em.outputs[0], out.inputs["Surface"])
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = image
        for n in nt.nodes:
            n.select = False
        tex.select = True
        nt.nodes.active = tex
        restore.append((nt, out, surface, em, tex))
    select_only(objs)
    bpy.ops.object.bake(type='EMIT', margin=16, use_clear=True)
    for nt, out, surface, em, tex in restore:
        nt.links.new(surface, out.inputs["Surface"])
        nt.nodes.remove(em)
        nt.nodes.remove(tex)


def bake_normal(objs, image):
    restore = []
    for mat in {s.material for o in objs for s in o.material_slots if s.material}:
        nt = mat.node_tree
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = image
        for n in nt.nodes:
            n.select = False
        tex.select = True
        nt.nodes.active = tex
        restore.append((nt, tex))
    select_only(objs)
    bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT', margin=16, use_clear=True)
    for nt, tex in restore:
        nt.nodes.remove(tex)


def as_jpeg(img, quality=90):
    """Write a baked map as a JPEG file and reload it, so the glTF exporter embeds JPEG instead of a 4x larger PNG."""
    path = os.path.join(TMP, img.name + ".jpg")
    img.filepath_raw = path
    img.file_format = 'JPEG'
    bpy.context.scene.render.image_settings.quality = quality
    img.save(filepath=path, quality=quality)
    img.source = 'FILE'
    img.reload()
    return img


def pixels(img):
    a = np.empty(img.size[0] * img.size[1] * 4, np.float32)
    img.pixels.foreach_get(a)
    return a.reshape(img.size[1], img.size[0], 4)


def set_pixels(img, a):
    img.pixels.foreach_set(a.astype(np.float32).ravel())
    img.update()


def pbr_material(name, base, orm=None, normal=None, roughness=0.5, metallic=0.0):
    """glTF-shaped material: base colour map, ORM through Separate Color (G roughness, B metallic), normal map."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    t = nt.nodes.new("ShaderNodeTexImage"); t.image = base
    nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
    if orm is not None:
        t2 = nt.nodes.new("ShaderNodeTexImage"); t2.image = orm
        sep = nt.nodes.new("ShaderNodeSeparateColor")
        nt.links.new(t2.outputs["Color"], sep.inputs[0])
        nt.links.new(sep.outputs["Green"], b.inputs["Roughness"])
        nt.links.new(sep.outputs["Blue"], b.inputs["Metallic"])
    else:
        b.inputs["Roughness"].default_value = roughness
        b.inputs["Metallic"].default_value = metallic
    if normal is not None:
        t3 = nt.nodes.new("ShaderNodeTexImage"); t3.image = normal
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(t3.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    return m


def bake_set(objs, pid, size, label="Body"):
    """BaseColor + ORM + Normal maps of `objs` (already sharing one non-overlapping UV layout)."""
    base = new_image(f"T_{pid}_{label}_BaseColor", size, "sRGB", "JPEG")
    rough = new_image(f"tmp_rough_{pid}", size, "Non-Color", "PNG")
    metal = new_image(f"tmp_metal_{pid}", size, "Non-Color", "PNG")
    normal = new_image(f"T_{pid}_{label}_Normal", size, "Non-Color", "PNG")
    bake_input(objs, "Base Color", base)
    bake_input(objs, "Roughness", rough)
    bake_input(objs, "Metallic", metal)
    bake_normal(objs, normal)
    orm = new_image(f"T_{pid}_{label}_ORM", size, "Non-Color", "JPEG")
    a = pixels(rough).copy()
    a[..., 0] = 1.0
    a[..., 1] = pixels(rough)[..., 0]
    a[..., 2] = pixels(metal)[..., 0]
    set_pixels(orm, a)
    bpy.data.images.remove(rough)
    bpy.data.images.remove(metal)
    return as_jpeg(base), as_jpeg(orm), normal


def unwrap(obj, margin=0.01):
    select_only([obj])
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=margin)
    bpy.ops.object.mode_set(mode='OBJECT')


def to_mesh(objs):
    """Apply modifiers (bevels, booleans, solidify) and return mesh objects."""
    out = []
    for o in objs:
        select_only([o])
        if o.type != 'MESH' or o.modifiers:
            bpy.ops.object.convert(target='MESH')
        out.append(bpy.context.view_layer.objects.active)
    return out


def join(objs, name):
    objs = to_mesh(objs)
    select_only(objs, objs[0])
    if len(objs) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = name
    o.data.name = name
    return o


def baked_body(objs, pid, size, name=None):
    """Join `objs`, unwrap once, bake their approved materials into one PBR set and swap it in."""
    body = join(objs, name or pid)
    unwrap(body)
    base, orm, normal = bake_set([body], pid, size)
    mat = pbr_material(f"M_{pid}", base, orm, normal)
    body.data.materials.clear()
    body.data.materials.append(mat)
    smooth(body, 35)
    return body


def smooth(obj, degrees):
    select_only([obj])
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(degrees))


def anchor(name, location, rot_z=0.0, flat=True):
    """Empty a runtime label hangs from. flat: the reading side faces +Z (Blender), so Godot local +Z = up."""
    e = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(e)
    e.empty_display_size = 0.01
    e.location = location
    e.rotation_euler = (-math.pi / 2 if flat else 0.0, 0.0, rot_z)
    return e


def export(path, objs):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    select_only(objs)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_yup=True,
                              export_apply=True, export_image_format='AUTO', export_jpeg_quality=90,
                              export_texcoords=True, export_normals=True, export_tangents=False,
                              export_materials='EXPORT', export_animations=False, export_skins=False,
                              export_morph=False, export_extras=False, export_cameras=False, export_lights=False)


def godot_size(objs):
    """Bounding size (x, y, z) in Godot axes of the exported meshes."""
    mn, mx = C.bbox(objs)
    return [round(mx.x - mn.x, 4), round(mx.z - mn.z, 4), round(mx.y - mn.y, 4)], round(mn.z, 5)


def godot_point(v):
    return [round(v.x, 5), round(v.z, 5), round(-v.y, 5)]


# ------------------------------------------------------------------------------------------------ plants
# Tara's stem colours from build_plant_panels.remap, as (hue, saturation, value) node recipes.
TARA_STEMS = {
    "green": lambda nt, S, V: P._hsv(nt, 0.27, P._affine(nt, S, 0.9, 0.12), P._affine(nt, V, 1.05, 0.03)),
    "tara_dry": lambda nt, S, V: P._hsv(nt, 0.20, 0.38, P._affine(nt, V, 0.85, 0.02)),
}


def green_stem_base(nt, bsdf, src_base, stem):
    """Tara's stem is green to the soil. The approval remap only recoloured texels above the tray rim, which left a
    purple stem foot inside the tray; Brassica rapa's green-stem form has no anthocyanin anywhere, so the same stem
    colour is applied to every purple texel (nothing else on the mesh is purple: tray grey, soil brown, leaves green)."""
    sep = nt.nodes.new("ShaderNodeSeparateColor"); sep.mode = 'HSV'
    nt.links.new(src_base.outputs["Color"], sep.inputs[0])
    H, S, V = sep.outputs
    purple = P._mul(nt, P._range_mask(nt, H, 0.66, 0.97, 0.05), P._range_mask(nt, S, 0.14, 1.0, 0.06))
    current = bsdf.inputs["Base Color"].links[0].from_socket
    nt.links.new(P._mix(nt, current, TARA_STEMS[stem](nt, S, V), purple), bsdf.inputs["Base Color"])


def build_plant(pid, stem, foliage, lean_deg, mirrored, preview):
    reset()
    o = C.import_glb(SOURCE_POD)
    P.bake_transforms(o)
    me = o.data
    vol_before = signed_volume(me)
    if mirrored:
        mirror_x(o)
    vol_after = signed_volume(me)
    assert vol_before * vol_after > 0, f"{pid}: winding inverted ({vol_before} -> {vol_after})"
    rim, ztop = P.soil_height(o)
    if lean_deg:
        lean_with_normals(o, lean_deg, rim + 0.004)
    mat = o.active_material
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    rough_src = bsdf.inputs["Roughness"].links[0].from_socket
    rm_node = rough_src.node.inputs[0].links[0].from_node  # Separate Color <- METALLIC ROUGHNESS image
    P.remap(o, stem, foliage, ztop, rim)
    src_base = next(n for n in nt.nodes if n.type == 'TEX_IMAGE' and n.label == "BASE COLOR")
    if stem in TARA_STEMS:
        green_stem_base(nt, bsdf, src_base, stem)
    size = src_base.image.size[0]
    base = new_image(f"T_{pid}_BaseColor", size, "sRGB", "JPEG")
    bake_input([o], "Base Color", base)
    as_jpeg(base)
    # swap the bake in: base colour map straight into the BSDF; the remap nodes go
    keep = {bsdf, _output(nt), rough_src.node, rm_node}
    keep |= {n for n in nt.nodes if n.type in ('NORMAL_MAP',) or (n.type == 'TEX_IMAGE' and n.label == "NORMAL MAP")}
    for n in list(nt.nodes):
        if n not in keep:
            nt.nodes.remove(n)
    t = nt.nodes.new("ShaderNodeTexImage"); t.image = base
    nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(rough_src, bsdf.inputs["Roughness"])
    if foliage == "dry":  # approval panels: matte dry tissue everywhere
        src = rm_node.image
        orm = new_image(f"T_{pid}_ORM", src.size[0], "Non-Color", "JPEG")
        a = pixels(src).copy()
        a[..., 1] = DRY_ROUGHNESS
        set_pixels(orm, a)
        rm_node.image = as_jpeg(orm)
    for img_node in [n for n in nt.nodes if n.type == 'TEX_IMAGE' and n.label == "NORMAL MAP"]:
        img_node.image.name = f"T_{pid}_Normal"
    if foliage != "dry":
        rm_node.image.name = f"T_{pid}_ORM"
    mat.name = f"M_{pid}"
    o.name = pid
    me.name = pid
    path = os.path.join(PLANT_DIR, pid, pid + ".glb")
    export(path, [o])
    size_g, min_y = godot_size([o])
    entry = {"id": pid, "kind": "plant", "path": "res://" + os.path.relpath(path, os.path.join(ROOT, "game")),
             "source": "res://assets/plants/PL_Alo_Pods/PL_Alo_Pods.glb", "stem": stem or "unchanged",
             "foliage": foliage or "unchanged", "lean_degrees": lean_deg, "mirrored": mirrored,
             "triangles": triangles(o), "size_m": size_g, "min_y_m": min_y, "texture_px": size,
             "soil_rim_m": round(rim, 4)}
    if preview:
        render_plant_preview(path, pid, preview)
    return entry


def render_plant_preview(glb, pid, out_dir):
    """Re-import the exported GLB and render it like the approval panel, so the bake can be compared by eye."""
    C.reset()
    sc = bpy.context.scene
    sc.cycles.samples = 48
    sc.render.threads_mode = 'FIXED'
    sc.render.threads = 4
    sc.render.resolution_x = sc.render.resolution_y = 600
    o = C.import_glb(glb)
    C.studio([o])
    os.makedirs(out_dir, exist_ok=True)
    C.render(os.path.join(out_dir, pid + ".png"))


# ------------------------------------------------------------------------------------------------ props
def label_holder():
    """The CH01-S04 'empty circle': dark holder ring, pressed-on paper label, printed colour band (runtime colour)."""
    holder = C.material("Holder", P.lin("#3A3D42"), rough=0.45)
    card = PP.paper("#F3F1EA", "#E4E0D4", rough=0.7, scale=900)
    ring = PP.cyl(0.019, 0.004, (0, 0, 0.002), holder, verts=64, name="Ring")
    bev = ring.modifiers.new("bev", 'BEVEL'); bev.width = 0.0006; bev.segments = 2; bev.limit_method = 'ANGLE'
    label = PP.cyl(0.0168, 0.0006, (0, 0, 0.0043), card, verts=64, name="Label")
    body = baked_body([ring, label], "PR_LabelHolder", 512)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.0150, minor_radius=0.0011, major_segments=64, minor_segments=8,
                                     location=(0, 0, 0.0046))
    band = bpy.context.object
    band.scale.z = 0.12
    band.name = band.data.name = "Band"
    band.data.materials.append(C.material("M_PR_LabelHolder_Band", (1, 1, 1, 1), rough=0.5))
    bpy.ops.object.shade_smooth()
    a = anchor("Text_Label", (0, 0, 0.0048))
    return [body, band, a], {"Text_Label": a}, {"band_node": "Band"}


def mug_frame(mug):
    """Handle direction, body axis, tape radius and wall slope of PR_Mug in its own (unrotated) frame.

    The Tripo mug is a sparse, irregular mesh, so the axis comes from a least-squares circle through the rim band
    above the handle (z 84-100 mm); the handle is whatever stands well outside that circle lower down."""
    vs = [v.co.copy() for v in mug.data.vertices]
    rim = np.array([(c.x, c.y) for c in vs if 0.084 < c.z < 0.100])
    sol = np.linalg.lstsq(np.c_[rim, np.ones(len(rim))], (rim ** 2).sum(1), rcond=None)[0]
    centre = Vector((sol[0] / 2, sol[1] / 2, 0))
    R = float(np.median(np.hypot(rim[:, 0] - centre.x, rim[:, 1] - centre.y)))
    flat = lambda c: Vector((c.x - centre.x, c.y - centre.y, 0))
    side = [flat(c) for c in vs if 0.02 < c.z < 0.08]
    reach = max(v.length for v in side)
    far = [v for v in side if v.length > reach - 0.005]     # the handle's outer bow, not its sparse flanks
    assert reach > R + 0.01, "PR_Mug: no handle found outside the body"
    handle = sum(far, Vector((0, 0, 0))).normalized()
    tape_dir = Vector((handle.y, -handle.x, 0))       # handle rotated -90 degrees: handle on the reader's right
    # the front sector the tape covers (within 60 degrees of its centre), over the tape's height
    sector = [c for c in vs if TAPE_Z - TAPE_H / 2 - 0.004 < c.z < TAPE_Z + TAPE_H / 2 + 0.004
              and flat(c).length > 0.6 * R and flat(c).normalized().dot(tape_dir) > math.cos(math.radians(60))]
    dist = np.array([flat(c).length for c in sector])
    zs = np.array([c.z for c in sector]) - TEXT_Z
    slope = float(np.polyfit(zs, dist, 1)[0]) if len(sector) > 8 else 0.0
    slope = slope if abs(slope) > 0.05 else 0.0     # the measured wall is cylindrical; keep noise out
    r_text = float(np.max(dist - slope * zs)) + 0.0006   # clear of every wall vertex the tape passes over
    assert abs(r_text - R) < 0.004, f"PR_Mug tape radius {r_text:.4f} m does not match the rim radius {R:.4f} m"
    return handle, centre, tape_dir, r_text, slope


def tape_strip(name, centre, tape_dir, r_text, slope, width, mat):
    """Masking-tape strip on the mug's conical wall; UVs at 0.1 m per unit so every tape shares one paper map."""
    base_ang = math.atan2(tape_dir.y, tape_dir.x)
    half = width / 2 / r_text
    nu, nv = 40, 4
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new()
    grid = []
    for j in range(nv + 1):
        z = TAPE_Z - TAPE_H / 2 + TAPE_H * j / nv
        r = r_text + slope * (z - TEXT_Z)
        row = []
        for i in range(nu + 1):
            a = base_ang - half + 2 * half * i / nu   # left to right as read from outside
            row.append(bm.verts.new((centre.x + r * math.cos(a), centre.y + r * math.sin(a), z)))
        grid.append(row)
    for j in range(nv):
        for i in range(nu):
            quad = ((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1))
            f = bm.faces.new([grid[jj][ii] for ii, jj in quad])
            for loop, (ii, jj) in zip(f.loops, quad):
                loop[uv].uv = (0.02 + (width * ii / nu) / 0.1, 0.05 + (TAPE_H * jj / nv) / 0.1)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    # outward-facing check: the strip must face away from the mug axis
    p = o.data.polygons[len(o.data.polygons) // 2]
    if p.normal.dot((p.center - Vector((centre.x, centre.y, p.center.z))).normalized()) < 0:
        reverse_winding(o.data)
    for poly in o.data.polygons:
        poly.use_smooth = True
    return o, half


def paper_tile(pid, hex_base, hex_fibre, rough, scale, size):
    """Bake an approved paper material on a 0.1 m tile (UV 0..1) and return a ready PBR material."""
    bpy.ops.mesh.primitive_plane_add(size=0.1, location=(0.05, 0.05, 0))
    tile = bpy.context.object
    tile.data.materials.append(PP.paper(hex_base, hex_fibre, rough=rough, scale=scale))
    base, orm, normal = bake_set([tile], pid, size, "Tape")
    bpy.data.objects.remove(tile)
    bpy.context.view_layer.update()
    return pbr_material(f"M_{pid}_Tape", base, orm, normal)


def mug_named():
    """PR_Mug unchanged, plus one blank tape strip per crew name (shown by variant) and the NameArc anchor."""
    mug = C.import_glb(SOURCE_MUG)
    mug.name = "Mug"
    mug.data.name = "PR_Mug"
    handle, centre, tape_dir, r_tape, slope = mug_frame(mug)
    tape_mat = paper_tile("PR_Mug_Named", "#E8DDBF", "#D9CBA5", 0.75, 600, 512)
    objs = [mug]
    tapes = {}
    for name in MUG_NAMES:
        width = 0.026 + 0.0088 * len(name)  # the approval sheet's tape length per name
        t, half = tape_strip("Tape_" + name, centre, tape_dir, r_tape, slope, width, tape_mat)
        objs.append(t)
        tapes[name] = {"node": "Tape_" + name, "width_m": round(width, 4), "half_angle_rad": round(half, 4)}
    rot = math.atan2(tape_dir.x, -tape_dir.y)
    a = anchor("NameArc", (centre.x, centre.y, TEXT_Z), rot_z=rot, flat=False)
    objs.append(a)
    extra = {"arc_radius_m": round(r_tape + 0.0003, 5), "arc_slope": round(slope, 4), "tapes": tapes,
             "handle_dir": godot_point(handle), "tape_dir": godot_point(tape_dir)}
    return objs, {"NameArc": a}, extra


def tool_tag():
    """Steel tool tag with the gear-wheel emblem of Ferreira's old patch (clue 12) and a split ring; stamp at runtime."""
    steel = PP.brushed("#9EA3A8", rough=0.5)
    dark = C.material("Engrave", P.lin("#4B5056"), rough=0.75)
    ring_m = PP.brushed("#B8BCC0", rough=0.25)
    tag = PP.rounded_box(0.052, 0.026, 0.0016, (0, 0, 0.0008), steel, 0.004, "Tag")
    bpy.ops.object.shade_flat()
    hole = PP.cyl(0.0032, 0.01, (-0.020, 0, 0.0008), steel, verts=32, name="Hole")
    bo = tag.modifiers.new("hole", 'BOOLEAN'); bo.object = hole; bo.operation = 'DIFFERENCE'
    tag = to_mesh([tag])[0]
    bpy.data.objects.remove(hole)
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, 0.0012)) for x, y in PP.gear_outline()]
    f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    bmesh.ops.translate(bm, vec=(0, 0, 0.00045), verts=[e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=[x for x in bm.faces if len(x.verts) > 4])
    me = bpy.data.meshes.new("Gear"); bm.to_mesh(me); bm.free()
    gear = bpy.data.objects.new("Gear", me); bpy.context.collection.objects.link(gear)
    gear.location = (0.004, 0, 0)
    gear.data.materials.append(dark)
    hub = PP.cyl(0.0034, 0.0006, (0.004, 0, 0.00168), steel, verts=32, name="Hub")
    axle = PP.cyl(0.0014, 0.0008, (0.004, 0, 0.0017), dark, verts=24, name="Axle")
    # split ring through the hole, standing up as on the sheet; its lowest point rests in the hole, never below 0
    alpha = math.radians(81)
    centre = (-0.020 - 0.0085 * math.cos(alpha), 0, 0.0008 + 0.0085 * math.sin(alpha))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.0085, minor_radius=0.0007, major_segments=48, minor_segments=8,
                                     location=centre, rotation=(math.radians(90), 0, 0))
    ring = bpy.context.object; ring.name = "SplitRing"; ring.data.materials.append(ring_m)
    bpy.ops.object.shade_smooth()
    body = baked_body([tag, gear, hub, axle, ring], "PR_ToolTag_Gear", 512)
    a = anchor("Text_Stamp", (0.0175, -0.0005, 0.00166), rot_z=math.radians(90))
    return [body, a], {"Text_Stamp": a}, {}


def drawer_lid():
    """Brushed aluminium lid of the dry-storage drawer; N.'s pencil lines are drawn at runtime (clue 2)."""
    alu = PP.brushed("#C3C7CB", rough=0.4)
    lid = PP.rounded_box(0.17, 0.095, 0.004, (0, 0, 0.002), alu, 0.002, "Lid")
    body = baked_body([lid], "PR_DrawerLidNote", 1024)
    a = anchor("Text_Note", (-0.072, 0.024, 0.00402))
    return [body, a], {"Text_Note": a}, {}


def envelope():
    """Kraft seed envelope, sealed with clear tape, for the Tara x Alo working stock (no count anywhere)."""
    kraft = PP.paper("#B58E60", "#9C774C", rough=0.9, scale=500)
    # the sheet's clear tape (alpha 0.55 over kraft) as the opaque colour it reads as, so it needs no blending
    seal_m = C.material("SealTape", tuple(0.55 * a + 0.45 * b for a, b in zip((0.85, 0.80, 0.62), P.lin("#B58E60")[:3])) + (1,),
                        rough=0.15)
    body = PP.rounded_box(0.075, 0.115, 0.003, (0, 0, 0.0015), kraft, 0.0015, "Envelope")
    flap = PP.rounded_box(0.075, 0.03, 0.0006, (0, 0.044, 0.0033), kraft, 0.0006, "Flap")
    seal = PP.rounded_box(0.05, 0.012, 0.0003, (0, 0.03, 0.0038), seal_m, 0.0001, "Seal")
    body = baked_body([body, flap, seal], "PR_WorkingStockEnvelope", 1024)
    a = anchor("Text_Label", (0, 0, 0.0031))
    return [body, a], {"Text_Label": a}, {}


BUILDERS = {"PR_LabelHolder": label_holder, "PR_Mug_Named": mug_named, "PR_ToolTag_Gear": tool_tag,
            "PR_DrawerLidNote": drawer_lid, "PR_WorkingStockEnvelope": envelope}


def build_prop(pid):
    reset()
    objs, anchors, extra = BUILDERS[pid]()
    meshes = [o for o in objs if o.type == 'MESH']
    for m in {s.material for o in meshes for s in o.material_slots if s.material}:
        assert "." not in m.name, f"{pid}: duplicate material name {m.name}"
    path = os.path.join(PROP_DIR, pid + ".glb")
    export(path, objs)
    size_g, min_y = godot_size(meshes)
    tex = max((n.image.size[0] for o in meshes for s in o.material_slots if s.material
               for n in s.material.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image), default=0)
    return {"id": pid, "kind": "prop", "path": "res://" + os.path.relpath(path, os.path.join(ROOT, "game")),
            "triangles": sum(triangles(o) for o in meshes), "size_m": size_g, "min_y_m": min_y, "texture_px": tex,
            "anchors": {k: godot_point(v.location) for k, v in anchors.items()}, **extra}


# ------------------------------------------------------------------------------------------------ main
def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    only = []
    if "--only" in argv:
        for a in argv[argv.index("--only") + 1:]:
            if a.startswith("--"):
                break
            only.append(a)
    preview = argv[argv.index("--preview") + 1] if "--preview" in argv else ""
    cat_path = os.path.join(PROP_DIR, "narrative_props.json")
    catalog = json.load(open(cat_path)) if os.path.exists(cat_path) else {"plants": [], "props": []}
    done = {e["id"]: e for e in catalog["plants"] + catalog["props"]}
    for pid, (stem, foliage, lean_deg, mirrored, when) in PLANTS.items():
        if only and pid not in only:
            continue
        e = build_plant(pid, stem, foliage, lean_deg, mirrored, preview)
        e["stage"] = when
        done[pid] = e
        print("BUILT", json.dumps(e))
    for pid in PROPS:
        if only and pid not in only:
            continue
        e = build_prop(pid)
        done[pid] = e
        print("BUILT", json.dumps(e))
    catalog = {
        "generated_by": "production/concept/narrative_props/build_runtime_assets.py (M3-99)",
        "approved_sheets": "production/concept/narrative_props/ (Sadman, 5 Nov 2026)",
        "anchor_convention": "Text_* and NameArc nodes: local +Z leaves the surface (reading side), +Y is up",
        "plants": [done[p] for p in PLANTS if p in done],
        "props": [done[p] for p in PROPS if p in done],
    }
    os.makedirs(PROP_DIR, exist_ok=True)
    with open(cat_path, "w") as f:
        json.dump(catalog, f, indent=1)
        f.write("\n")
    shutil.rmtree(TMP, ignore_errors=True)


if __name__ == "__main__":
    main()
