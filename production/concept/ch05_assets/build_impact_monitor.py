"""M3-5A: PR_ImpactMonitor, the Aurora impact-camera monitor station (Blender 5.2, procedural, no credits).

Usage:
  blender -b --factory-startup --python build_impact_monitor.py -- <out_dir>

Writes <out_dir>/PR_ImpactMonitor/PR_ImpactMonitor.glb and prints a STATS line.

Design (ART_BIBLE 3 palette, grounded ISS/Artemis hardware; EX-CH05-S07 "a dark room lit by the monitor")
  * A bench-standing instrument console: navy base plinth, a tilted navy control deck on a wedge riser and a white display head
    with a navy bezel, two signal-orange grab handles and a cable gland at the back. 0.52 x 0.36 m footprint,
    0.60 m tall, pivot at the base centre so it sits on any desk or bracket (M3-5R places it).
  * Controls on the deck: a jog wheel for scrubbing frame by frame, two rows of three blank keys (the two coloured
    keys are the reject and verify actions; the words are live UI), a long compare bar and a status light strip.
    No text, numbers or logos are modelled or baked; readouts, reason chips and timestamps are the game's UI.
  * The screen is its own mesh object `Screen` with the material `Screen` (the habitat kit's live-UI convention), a
    0.44 x 0.275 m 16:10 surface, so the game can set a surface override with the authored frames
    (game/assets/ui/impact_monitor/impact_frames.json) or a SubViewport.

Runtime contract
  * Nodes: `Base`, `Deck`, `DeckRiser`, `Head`, `Screen`, `JogWheel` (pivot on its axle; rotate about the deck
    normal to scrub: local Z here, local Y in the GLB and Godot), `Key_01`..`Key_06` (pivot at the key base; press =
    move -3 mm along the deck normal: local -Z here, local -Y in Godot), `CompareBar`, `StatusStrip`.
  * Empties: `Socket_Focus` 0.25 m in front of the screen centre (camera focus and the Inspect verb),
    `Socket_Hand` on the jog wheel for a hand contact.
  * Surfaces: the habitat kit's photoreal PBR sets (game/assets/environment/kit/textures, M1-05): PaintWhite on
    the housing, PaintNavy on the plinth, deck and bezel, PaintOrange on the handles, PaintDark on the feet and jog
    wheel, Steel on the fasteners and jog cap, UV-mapped at the kit's 0.5 m tile (0.25 m for steel) so the monitor
    reads at the same texel density as the room around it. The exported GLB references those PNGs by relative uri
    and stores no image of its own (the 5 Nov realism lock: photoreal interiors; textures are never stored twice).
    Keys, the status strip and the screen are material factors. States (candidate, paired reference, artifact rejection, six verified,
    eight mastery) are screen content, listed in impact_frames.json.
"""
import bmesh, bpy, math, os, sys
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
KIT_TEX = os.path.join(ROOT, "game", "assets", "environment", "kit", "textures")
sys.path.insert(0, os.path.join(ROOT, "production", "tools"))
import glb_external_textures as glbx  # noqa: E402  (shared GLB reader/writer, M1-05)

NAVY, WHITE, ORANGE, GOLD, GREY, BLACK = "#1F2A44", "#ECEEF0", "#F26B21", "#F2C230", "#8A9099", "#0A0C10"


def lin(hexstr):
    h = hexstr.lstrip("#")
    return tuple(((int(h[i:i + 2], 16) / 255) ** 2.2) for i in (0, 2, 4)) + (1.0,)


def material(name, color, rough=0.5, metal=0.0, emit=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = color
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = emit
        b.inputs["Emission Strength"].default_value = 1.0
    return m


_gltf_group = None


def gltf_output_group():
    """The node group Blender's glTF exporter reads the occlusion channel from (as build_habitat_kit.py)."""
    global _gltf_group
    if _gltf_group is None:
        _gltf_group = bpy.data.node_groups.new("glTF Material Output", "ShaderNodeTree")
        _gltf_group.interface.new_socket("Occlusion", in_out="INPUT", socket_type="NodeSocketFloat")
        _gltf_group.nodes.new("NodeGroupInput")
    return _gltf_group


def kit_image(name, non_color=False):
    """One of the kit's published PNGs, loaded once and named exactly like the file (without .png)."""
    img = bpy.data.images.get(name)
    if img is None:
        img = bpy.data.images.load(os.path.join(KIT_TEX, name + ".png"))
        img.name = name
        if non_color:
            img.colorspace_settings.name = "Non-Color"
    return img


def kit_material(key, tile):
    """The habitat kit's PBR material `M_Kit_<key>` (same maps and wiring as build_habitat_kit.pbr_material)."""
    shared = "Steel" if key == "Steel" else "Paint"
    m = bpy.data.materials.new("M_Kit_" + key)
    m["tile"] = tile
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = kit_image(f"T_Kit_{key}_BaseColor")
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    orm = nt.nodes.new("ShaderNodeTexImage")
    orm.image = kit_image(f"T_Kit_{shared}_ORM", True)
    split = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(orm.outputs["Color"], split.inputs["Color"])
    nt.links.new(split.outputs["Green"], bsdf.inputs["Roughness"])
    nt.links.new(split.outputs["Blue"], bsdf.inputs["Metallic"])
    group = nt.nodes.new("ShaderNodeGroup")
    group.node_tree = gltf_output_group()
    nt.links.new(split.outputs["Red"], group.inputs["Occlusion"])
    nrm = nt.nodes.new("ShaderNodeTexImage")
    nrm.image = kit_image(f"T_Kit_{shared}_Normal", True)
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(nrm.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def planar_uvs(o, tile):
    """World-space planar UVs on the face's dominant axis at the kit's tile size (build_habitat_kit.planar_uv)."""
    me = o.data
    uv = me.uv_layers.active or me.uv_layers.new(name="UVMap")
    mw = o.matrix_world
    for poly in me.polygons:
        n = (mw.to_3x3() @ poly.normal)
        ax = [abs(n.x), abs(n.y), abs(n.z)]
        a_i, b_i = {0: (1, 2), 1: (0, 2), 2: (0, 1)}[ax.index(max(ax))]
        for li in poly.loop_indices:
            p = mw @ me.vertices[me.loops[li].vertex_index].co
            uv.data[li].uv = (p[a_i] / tile, p[b_i] / tile)


def link_kit_textures(glb_path):
    """Replace the images Blender embedded with relative uris to the kit's own PNGs (nothing is written there)."""
    doc, binary = glbx._read_glb(glb_path)
    rel = os.path.relpath(KIT_TEX, os.path.dirname(os.path.abspath(glb_path)))
    removed = set()
    for i, image in enumerate(doc.get("images", [])):
        if "bufferView" not in image:
            continue
        name = image["name"]
        assert os.path.exists(os.path.join(KIT_TEX, name + ".png")), name
        removed.add(image["bufferView"])
        doc["images"][i] = {"name": name, "mimeType": "image/png", "uri": f"{rel}/{name}.png"}
    keep = [i for i in range(len(doc["bufferViews"])) if i not in removed]
    new_binary, new_views = bytearray(), []
    for i in keep:
        view = dict(doc["bufferViews"][i])
        start = view.pop("byteOffset", 0)
        new_binary += b"\0" * (-len(new_binary) % 4)
        view["byteOffset"] = len(new_binary)
        new_binary += binary[start: start + view["byteLength"]]
        new_views.append(view)
    glbx._remap_buffer_views(doc, keep)
    doc["bufferViews"] = new_views
    if doc.get("buffers"):
        doc["buffers"][0]["byteLength"] = len(new_binary)
    glbx._write_glb(glb_path, doc, bytes(new_binary))
    return len(removed)


def use_shared_textures_on_import(glb_path):
    """Sets Godot's import of `glb_path` to extract (1) instead of the project default, embedding as Basis Universal:
    with the default, Godot re-encodes the shared kit textures per scene and the imported materials end up with empty
    textures (the M1-05 kit hit the same; see production/tools/build_habitat_kit.py write_scene_imports). A missing
    .import file is created with just the importer and this setting; Godot fills in the rest on import."""
    import_file = glb_path + ".import"
    if os.path.exists(import_file):
        lines = open(import_file, encoding="utf-8").read().splitlines()
        lines = ["gltf/embedded_image_handling=1" if l.startswith("gltf/embedded_image_handling=") else l for l in lines]
        if "gltf/embedded_image_handling=1" not in lines:
            lines.append("gltf/embedded_image_handling=1")
        open(import_file, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    else:
        rel = os.path.relpath(glb_path, os.path.join(ROOT, "game")).replace(os.sep, "/")
        open(import_file, "w", encoding="utf-8").write('[remap]\n\nimporter="scene"\nimporter_version=1\ntype="PackedScene"\n\n'
                                                       f'[deps]\n\nsource_file="res://{rel}"\n\n[params]\n\ngltf/embedded_image_handling=1\n')


def box(name, size, at, mat, bevel=0.004, segs=3, rot=(0, 0, 0)):
    """Bevelled box of `size` (x, y, z) whose bottom centre sits at `at`, rotated about its bottom centre."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
    o = bpy.context.object
    o.name = name
    o.scale = (size[0], size[1], size[2])
    bpy.ops.object.transform_apply(scale=True)
    for v in o.data.vertices:
        v.co.z += size[2] / 2
    if bevel:
        bv = o.modifiers.new("bevel", "BEVEL")
        bv.width = bevel
        bv.segments = segs
        bv.limit_method = "ANGLE"
    o.rotation_euler = [math.radians(r) for r in rot]
    o.location = at
    o.data.materials.append(mat)
    return o


def cylinder(name, radius, depth, at, mat, axis="Z", verts=48, bevel=0.0015):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=(0, 0, 0))
    o = bpy.context.object
    o.name = name
    if axis == "X":
        o.rotation_euler = (0, math.radians(90), 0)
    elif axis == "Y":
        o.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    if bevel:
        bv = o.modifiers.new("bevel", "BEVEL")
        bv.width = bevel
        bv.segments = 2
        bv.limit_method = "ANGLE"
    o.location = at
    o.data.materials.append(mat)
    return o


def handle(name, at, length, mat, rot=(0, 0, 0)):
    """ISS-style grab handle: a bent round bar, two standoffs, lying along local X at `at`."""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    sp = cu.splines.new("POLY")
    pts = [(-length / 2, 0, 0), (-length / 2, 0, 0.028), (length / 2, 0, 0.028), (length / 2, 0, 0)]
    sp.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        sp.points[i].co = (*p, 1.0)
    cu.bevel_depth = 0.009
    cu.bevel_resolution = 4
    cu.use_fill_caps = True
    o = bpy.data.objects.new(name, cu)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.convert(target="MESH")
    bpy.ops.object.shade_smooth()
    o.rotation_euler = [math.radians(r) for r in rot]
    o.location = at
    return o


def wedge(name, width, ys, floor_z, tilt, pivot, mat):
    """Prism of `width` (x) from y = ys[0] to ys[1], bottom on z = floor_z, top on the plane through `pivot` (y, z)
    rising at `tilt` radians towards +y: the support under a tilted deck."""
    bm = bmesh.new()
    rows = []
    for y in ys:
        top = max(floor_z, pivot[1] + (y - pivot[0]) * math.tan(tilt))
        rows.append([bm.verts.new((sx * width / 2, y, z)) for sx in (-1, 1) for z in (floor_z, top)])
    (f_lb, f_lt, f_rb, f_rt), (b_lb, b_lt, b_rb, b_rt) = rows
    for quad in ((f_lb, f_rb, f_rt, f_lt), (b_lb, b_lt, b_rt, b_rb), (f_lb, f_lt, b_lt, b_lb), (f_rb, b_rb, b_rt, f_rt),
                 (f_lt, f_rt, b_rt, b_lt), (f_lb, b_lb, b_rb, f_rb)):
        if len({tuple(round(c, 6) for c in v.co) for v in quad}) == 4:   # skip faces that collapse to a line
            bm.faces.new(quad)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    return o


def empty(name, at, parent=None):
    e = bpy.data.objects.new(name, None)
    e.empty_display_type = "ARROWS"
    e.empty_display_size = 0.05
    e.location = at
    bpy.context.collection.objects.link(e)
    if parent:
        e.parent = parent
    return e


def build(out_dir):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    m_white = kit_material("PaintWhite", 0.5)
    m_navy = kit_material("PaintNavy", 0.5)
    m_orange = kit_material("PaintOrange", 0.5)
    m_rubber = kit_material("PaintDark", 0.5)
    m_steel = kit_material("Steel", 0.25)
    m_gold = material("KeyVerify", lin(GOLD), rough=0.5)
    m_keys = material("Keys", lin("#D7DADF"), rough=0.5)
    m_screen = material("Screen", lin(BLACK), rough=0.2, emit=lin("#0B1118"))
    m_led = material("StatusLED", lin("#20B8C9"), rough=0.4, emit=lin("#20B8C9"))

    parts = []
    # base plinth with rubber feet
    base = box("Base", (0.46, 0.32, 0.055), (0, 0, 0.012), m_navy, bevel=0.006)
    parts.append(base)
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(cylinder(f"Foot_{sx}{sy}", 0.018, 0.012, (sx * 0.19, sy * 0.12, 0.006), m_rubber, bevel=0.001))
    # control deck: tilted 18 degrees towards the user (the user stands at -Y). It is raised so that its front
    # bottom edge rests on the plinth top, and a wedge riser fills the space under its back edge, so the deck never
    # dips into the plinth or floats above it in the side view.
    tilt = math.radians(18)
    deck_z = 0.067 + 0.12 * math.sin(tilt)
    deck = box("Deck", (0.50, 0.24, 0.045), (0, -0.045, deck_z), m_navy, bevel=0.005, rot=(18, 0, 0))
    parts.append(deck)
    parts.append(wedge("DeckRiser", 0.46, (-0.045 - 0.12 * math.cos(tilt) + 0.004, -0.045 + 0.12 * math.cos(tilt) - 0.004),
                       0.067, tilt, (-0.045, deck_z), m_navy))
    # keys: two rows of three, on the deck surface (local frame of the deck)
    keys = []
    for r in range(2):
        for c in range(3):
            i = r * 3 + c
            mat = m_orange if i == 2 else m_gold if i == 5 else m_keys
            k = box(f"Key_{i + 1:02d}", (0.034, 0.028, 0.009), (-0.17 + c * 0.044, -0.032 + r * 0.040, 0.045), mat, bevel=0.0025, segs=2)
            k.parent = deck
            keys.append(k)
    # jog wheel on the right of the deck, axle out of the deck surface
    jog = cylinder("JogWheel", 0.038, 0.014, (0.165, -0.012, 0.052), m_rubber, verts=64, bevel=0.003)
    jog.parent = deck
    knurl = cylinder("JogCap", 0.012, 0.004, (0.165, -0.012, 0.0595), m_steel, verts=32, bevel=0.0008)
    knurl.parent = deck
    # compare bar (a long rocker) and status strip
    bar = box("CompareBar", (0.11, 0.022, 0.007), (0.0, -0.034, 0.045), m_keys, bevel=0.002, segs=2)
    bar.parent = deck
    strip = box("StatusStrip", (0.19, 0.008, 0.003), (-0.10, 0.085, 0.045), m_led, bevel=0.001, segs=1)
    strip.parent = deck
    # neck and display head, tilted back 12 degrees
    neck = box("Neck", (0.12, 0.05, 0.14), (0, 0.06, 0.06), m_white, bevel=0.004)
    parts.append(neck)
    head = box("Head", (0.52, 0.062, 0.37), (0, 0.075, 0.195), m_white, bevel=0.008, rot=(-12, 0, 0))
    parts.append(head)
    bezel = box("Bezel", (0.48, 0.012, 0.32), (0, -0.034, 0.025), m_navy, bevel=0.003, segs=2)
    bezel.parent = head
    # screen: its own object, slightly proud of the bezel, 16:10
    screen = box("Screen", (0.44, 0.004, 0.275), (0, -0.0395, 0.0475), m_screen, bevel=0.0, segs=1)   # front face 1.5 mm proud of the bezel (no z-fighting)
    screen.parent = head
    # grab handles on both sides of the head, a cable gland and vents at the back
    for sx, nm in ((-1, "Handle_L"), (1, "Handle_R")):
        h = handle(nm, (sx * 0.265, 0.0, 0.10), 0.16, m_orange, rot=(0, sx * 90, 0))
        h.parent = head
    gland = cylinder("CableGland", 0.016, 0.03, (0.14, 0.040, 0.09), m_rubber, axis="Y", verts=24)
    gland.parent = head
    for i in range(6):
        v = box(f"Vent_{i}", (0.30, 0.004, 0.006), (0, 0.032, 0.26 + i * 0.014), m_navy, bevel=0.0, segs=1)
        v.parent = head
    # captive fasteners: bezel and deck corners (kit Steel), so the housing reads as serviceable hardware
    for i, (sx, sz) in enumerate(((-1, -1), (-1, 1), (1, -1), (1, 1))):
        f = cylinder(f"Fastener_Bezel_{i}", 0.0045, 0.003, (sx * 0.226, -0.0405, 0.025 + 0.16 + sz * 0.148), m_steel, axis="Y", verts=16, bevel=0.0006)
        f.parent = head
        g = cylinder(f"Fastener_Deck_{i}", 0.0045, 0.003, (sx * 0.232, sz * 0.105, 0.046), m_steel, verts=16, bevel=0.0006)
        g.parent = deck
    # sockets
    empty("Socket_Focus", (0, -0.30, 0.19), parent=head)
    empty("Socket_Hand", (0.165, -0.012, 0.075), parent=deck)
    # smooth shading on the bevels
    for o in bpy.data.objects:
        if o.type == "MESH":
            bpy.context.view_layer.objects.active = o
            o.select_set(True)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
    # UVs: kit materials get world-space planar UVs at the kit tile (texel density matches the room); the rest
    # are material factors, smart-projected so the exporter still writes tangents
    bpy.context.view_layer.update()
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        for mod in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=mod.name)
        mat = o.data.materials[0] if o.data.materials else None
        if mat is not None and "tile" in mat:
            planar_uvs(o, mat["tile"])
        else:
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02, scale_to_bounds=False)
            bpy.ops.object.mode_set(mode="OBJECT")
    # the screen's front face (local -Y) maps the whole 0..1 UV range, so one live texture fills it edge to edge
    scr = bpy.data.objects["Screen"]
    bm = bmesh.new()
    bm.from_mesh(scr.data)
    uv = bm.loops.layers.uv.active
    xs = [v.co.x for v in bm.verts]
    zs = [v.co.z for v in bm.verts]
    for f in bm.faces:
        front = f.normal.y < -0.9
        for l in f.loops:
            l[uv].uv = ((l.vert.co.x - min(xs)) / (max(xs) - min(xs)), (l.vert.co.z - min(zs)) / (max(zs) - min(zs))) if front else (0.0, 0.0)
    bm.to_mesh(scr.data)
    bm.free()
    # measure
    dg = bpy.context.evaluated_depsgraph_get()
    pts, tris = [], 0
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        pts += [oe.matrix_world @ v.co for v in me.vertices]
        tris += sum(len(p.vertices) - 2 for p in me.polygons)
        oe.to_mesh_clear()
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    d = os.path.join(out_dir, "PR_ImpactMonitor")
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, "PR_ImpactMonitor.glb")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=True,
                              export_animations=False, export_skins=False, export_image_format="AUTO")
    linked = link_kit_textures(path)
    use_shared_textures_on_import(path)
    print(f"STATS PR_ImpactMonitor height={mx.z - mn.z:.4f} size=({mx.x - mn.x:.4f},{mx.y - mn.y:.4f}) min_z={mn.z:.4f} tris={tris} kit_textures={linked} file={path}")


if __name__ == "__main__":
    build(sys.argv[sys.argv.index("--") + 1])
