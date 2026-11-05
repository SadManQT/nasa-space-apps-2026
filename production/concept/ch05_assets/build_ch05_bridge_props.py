"""M3-5A: the objects Chapter 5's scene joins carry (doc 24 §2.9, §4 clues 17-18, §5.2 D9). Blender 5.2, procedural, no credits.

Usage:
  blender -b --factory-startup --python build_ch05_bridge_props.py -- <game/assets/props> [sleeve records tape]

Writes <out>/<Name>/<Name>.glb for each prop and prints one STATS line per prop (size, triangles, textures).

What each object carries (game-design/24_NARRATIVE_REVISION.md)
  * PR_DocumentSleeve - CH05 S02->S03 (Fix): Ferreira unpacks a sealed document sleeve from her relief cargo on 12 Dec,
    leaves it unopened on her locker shelf and brings it to the table on 14 Dec. A rigid A4 archive case: navy body,
    a hinged lid (`Lid`, pivot on the hinge: rotate about local X to open), a tamper-evident orange seal band (`Seal`,
    hidden once opened) and a blank label window (`LabelWindow`, material `Label`, a live-text slot).
  * PR_Records2034 - CH05-S03 clue 17 and CH05-S05 clue 18: "Four records wait under transparent weights: a relay fault
    report, a greenhouse service note, an evacuation order and an ascent manifest" (STORY_FULL). Four A4 sheets, each
    its own node with its pivot at the sheet centre so one can be moved alone (D9: the ascent manifest or the greenhouse
    service note stays at Ferreira's place through CH06-CH07 and is propped on the lineage board in CH08-S12):
    `Record_RelayFault`, `Record_ServiceNote`, `Record_EvacuationOrder`, `Record_AscentManifest`, and four clear
    acrylic `Weight_01`..`Weight_04`. Each front is a blank printed 2034 form (header band in a per-record colour,
    rules and boxes; the ascent manifest has its roster grid with a boarding tick on every row, "Every name has a
    boarding mark"). There is no text: the words, timestamps and signatures are the game's live document text
    (material `Page_<Record>`). The evacuation order's back is its own material `Page_EvacuationOrder_Back`, blank, so
    Ferreira's approved margin note (clue 18) is shown only when she turns it over after her confession.
  * PR_MarkerTape - CH05->CH06 bridge: Kai's marker tape on the guide-light branch, which CH06-S01 opens beside. A 19 mm
    vinyl roll in Kai's role orange (`Roll`) and one cut strip wrapped once round a 12 mm cable with a folded flag
    (`Strip`, with `Socket_Cable` on the cable axis so the room can clip it onto the guide-light circuit).

Surfaces use the habitat kit's PBR sets (relative uris to game/assets/environment/kit/textures, never copied) where the
object is painted hardware; paper and tape use generated 1024 px maps embedded in the GLB.
Pivot at the base centre, metres, Y up in the GLB. No logos, flags, words or numbers anywhere.
"""
import bmesh, bpy, math, os, sys
import numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_impact_monitor as hw  # noqa: E402  (kit materials, boxes, cylinders, empties and kit-texture linking)

PAPER = np.array([0.93, 0.91, 0.85])      # 2034 office paper, twelve years in a dry habitat locker
INK = np.array([0.30, 0.32, 0.36])        # printed form rules
SHEET = (0.210, 0.297)                    # A4, metres
BANDS = {                                  # per-record header colour, so the four read apart at table distance
    "RelayFault": np.array([0.95, 0.42, 0.13]),       # hazard orange: equipment fault
    "ServiceNote": np.array([0.24, 0.55, 0.32]),      # horticulture green
    "EvacuationOrder": np.array([0.72, 0.16, 0.14]),  # order red, with a striped border
    "AscentManifest": np.array([0.12, 0.16, 0.27]),   # navy: crew and flight
}


# ------------------------------------------------------------------------------------------------ textures
def paper_base(rng, w, h):
    """Aged paper: faint fibre noise, a slightly warmer edge, one soft fold shadow across the middle."""
    y, x = np.mgrid[0:h, 0:w].astype(np.float64)
    img = np.ones((h, w, 3)) * PAPER
    img *= (1.0 - 0.025 * rng.random((h, w, 1)))
    edge = np.minimum(np.minimum(x, w - 1 - x), np.minimum(y, h - 1 - y))
    img *= (1.0 - 0.05 * np.exp(-edge / 18.0))[..., None] * np.array([1.0, 0.99, 0.96])
    img *= (1.0 - 0.035 * np.exp(-((y - h * 0.5) / 5.0) ** 2))[..., None]
    return img


def rect(img, x0, y0, x1, y1, col, a=1.0):
    img[y0:y1, x0:x1] = img[y0:y1, x0:x1] * (1 - a) + col * a


def frame(img, x0, y0, x1, y1, col, t=2):
    rect(img, x0, y0, x1, y0 + t, col)
    rect(img, x0, y1 - t, x1, y1, col)
    rect(img, x0, y0, x0 + t, y1, col)
    rect(img, x1 - t, y0, x1, y1, col)


def tick(img, cx, cy, s, col):
    """A hand-drawn boarding tick (a mark, not a letter)."""
    for k in range(-(s // 3), 0):                       # short leg: down from the upper left to the turn
        rect(img, cx + k, cy + k, cx + k + 3, cy + k + 3, col)
    for k in range(0, s):
        rect(img, cx + k, cy - k, cx + k + 3, cy - k + 3, col)


def form_texture(name, kind, w=724, h=1024, seed=2034):
    """The blank printed form of one 2034 record (image rows top-down; flipped into Blender's bottom-up order)."""
    rng = np.random.default_rng(seed + sum(map(ord, kind)))
    img = paper_base(rng, w, h)
    band = BANDS[kind]
    m = 46
    rect(img, m, m, w - m, m + 64, band, 0.92)                  # header band: the words are live text over it
    rect(img, w - m - 92, m + 10, w - m - 12, m + 54, PAPER, 0.85)  # reference-number box in the band
    frame(img, m, m + 84, w - m, m + 178, INK, 2)                  # summary box: date, author, station
    rect(img, m + (w - 2 * m) // 2, m + 84, m + (w - 2 * m) // 2 + 2, m + 178, INK)
    if kind == "AscentManifest":
        top, rows, rh = m + 206, 9, 62
        frame(img, m, top, w - m, top + rows * rh, INK, 2)
        for r in range(1, rows):
            rect(img, m, top + r * rh, w - m, top + r * rh + 1, INK)
        for cx in (m + 52, w - m - 210, w - m - 92):
            rect(img, cx, top, cx + 2, top + rows * rh, INK)
        ink = np.array([0.10, 0.17, 0.36])                          # ballpoint blue boarding marks, one per name row
        for r in range(1, rows):
            tick(img, w - m - 56, top + r * rh + 40, 22, ink)
        y_after = top + rows * rh + 28
    else:
        for i in range(12):                                         # ruled lines for the record's live text
            y = m + 216 + i * 44
            rect(img, m, y, w - m, y + 1, INK * 1.6)
        y_after = m + 216 + 12 * 44 + 10
    if kind == "EvacuationOrder":                                   # striped border: an order, not a note
        for k in range(0, w, 28):
            rect(img, k, h - 30, min(k + 14, w), h - 18, band, 0.9)
            rect(img, k, 18, min(k + 14, w), 30, band, 0.9)
    for i in range(2):                                              # two signature lines and their boxes
        x0 = m + i * ((w - 2 * m) // 2 + 10)
        frame(img, x0, y_after + 20, x0 + (w - 2 * m) // 2 - 10, y_after + 110, INK, 1)
        rect(img, x0 + 16, y_after + 86, x0 + (w - 2 * m) // 2 - 26, y_after + 88, INK)
    return to_image(name, img)


def back_texture(name, front_kind, w=724, h=1024, mirrored_front=None):
    """Plain back of a sheet; a faint mirrored show-through of the front's header band."""
    rng = np.random.default_rng(99 + sum(map(ord, name)))
    img = paper_base(rng, w, h)
    if front_kind:
        band = BANDS[front_kind]
        rect(img, 46, 46, w - 46, 110, band, 0.06)
    return to_image(name, img)


def tape_texture(name, w=256, h=256):
    """Vinyl tape: Kai's orange with a faint calendered sheen across the width."""
    y, x = np.mgrid[0:h, 0:w].astype(np.float64)
    base = np.array([0.95, 0.42, 0.13])
    img = np.ones((h, w, 3)) * base
    img *= (1.0 + 0.05 * np.sin(x / w * math.pi * 2))[..., None]
    img *= (1.0 - 0.02 * np.random.default_rng(7).random((h, w, 1)))
    return to_image(name, np.clip(img, 0, 1))


def to_image(name, img):
    h, w = img.shape[:2]
    rgba = np.concatenate([np.clip(img[::-1], 0, 1), np.ones((h, w, 1))], axis=2).astype(np.float32)
    im = bpy.data.images.new(name, w, h, alpha=False)
    im.pixels.foreach_set(rgba.ravel())
    im.pack()
    return im


def textured(name, image, rough=0.85, metal=0.0, alpha=None):
    m = hw.material(name, (1, 1, 1, 1), rough=rough, metal=metal)
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    if image is not None:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = image
        nt.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    if alpha is not None:
        b.inputs["Alpha"].default_value = alpha
        m.surface_render_method = "BLENDED"
    return m


# ------------------------------------------------------------------------------------------------ geometry
def sheet(name, at, rot_z, front, back, curl=0.0016):
    """A4 sheet as a 12 x 16 grid (front) plus its flipped back 0.3 mm below; corners lift by `curl` metres.
    The object origin is the sheet centre on the table, so a consumer can move this one record alone."""
    sw, sh = SHEET
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    nx, ny = 12, 16

    def z_at(u, v):
        return curl * (abs(2 * u - 1) ** 3 + abs(2 * v - 1) ** 3) / 2

    for side, mi in ((1, 0), (-1, 1)):
        verts = [[bm.verts.new(((u / nx - 0.5) * sw, (v / ny - 0.5) * sh,
                                0.0006 + z_at(u / nx, v / ny) + (0.0003 if side == 1 else 0.0)))
                  for u in range(nx + 1)] for v in range(ny + 1)]
        for v in range(ny):
            for u in range(nx):
                q = [verts[v][u], verts[v][u + 1], verts[v + 1][u + 1], verts[v + 1][u]]
                if side == -1:
                    q.reverse()
                f = bm.faces.new(q)
                f.material_index = mi
                for loop in f.loops:
                    co = loop.vert.co
                    uu, vv = co.x / sw + 0.5, co.y / sh + 0.5
                    loop[uv].uv = (uu if side == 1 else 1 - uu, vv)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    me.materials.append(front)
    me.materials.append(back)
    for p in me.polygons:
        p.use_smooth = True
    o.location = at
    o.rotation_euler = (0, 0, math.radians(rot_z))
    return o


def ring(name, r_in, r_out, width, at, mat, axis="Z", verts=64):
    """A tube (roll, core or wrapped band): inner and outer walls and both end faces."""
    bm = bmesh.new()
    rings = []
    for r in (r_out, r_in):
        for z in (-width / 2, width / 2):
            rings.append([bm.verts.new((r * math.cos(2 * math.pi * k / verts), r * math.sin(2 * math.pi * k / verts), z))
                          for k in range(verts)])
    o_lo, o_hi, i_lo, i_hi = rings
    for k in range(verts):
        n = (k + 1) % verts
        bm.faces.new((o_lo[k], o_lo[n], o_hi[n], o_hi[k]))     # outer wall
        bm.faces.new((i_lo[n], i_lo[k], i_hi[k], i_hi[n]))     # inner wall
        bm.faces.new((o_hi[k], o_hi[n], i_hi[n], i_hi[k]))     # top
        bm.faces.new((i_lo[k], i_lo[n], o_lo[n], o_lo[k]))     # bottom
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    me.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = True
    if axis == "X":
        o.rotation_euler = (0, math.radians(90), 0)
    elif axis == "Y":
        o.rotation_euler = (math.radians(90), 0, 0)
    o.location = at
    return o


# ------------------------------------------------------------------------------------------------ the props
def parent_keep(child, parent):
    """Parents `child` to `parent` without moving it in the world."""
    bpy.context.view_layer.update()
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()


def sleeve():
    navy = hw.kit_material("PaintNavy", 0.5)
    orange = hw.kit_material("PaintOrange", 0.5)
    steel = hw.kit_material("Steel", 0.25)
    label = hw.material("Label", hw.lin("#F1F2EE"), rough=0.6)
    body = hw.box("Body", (0.335, 0.245, 0.014), (0, 0, 0), navy, bevel=0.003)
    lid = hw.box("Lid", (0.335, 0.245, 0.005), (0, 0, 0), navy, bevel=0.002, segs=2)
    # the lid's origin is its hinge line on the far (+Y) edge, so rotating it about local X opens it
    for v in lid.data.vertices:
        v.co.y -= 0.1225
    lid.location = (0, 0.1225, 0.014)
    # tamper-evident band wrapped over lid and body near the right end; hidden once the sleeve is opened
    seal = hw.box("Seal", (0.028, 0.250, 0.0206), (0.110, 0, 0), orange, bevel=0.0012, segs=2)
    window = hw.box("LabelWindow", (0.120, 0.070, 0.0008), (-0.060, -0.015, 0.019), label, bevel=0.0, segs=1)
    parent_keep(window, lid)
    latch = hw.box("Latch", (0.040, 0.012, 0.006), (0.0, -0.1265, 0.008), steel, bevel=0.0015, segs=2)
    return "PR_DocumentSleeve", [body, lid, seal, window, latch]


def records():
    sheets, weights = [], []
    acrylic = textured("Acrylic", None, rough=0.08, alpha=0.32)
    acrylic.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.86, 0.93, 0.97, 1)
    layout = (   # (record, centre x, centre y, rotation): the four set down without arranging them (canon)
        ("RelayFault", -0.115, 0.075, 4.0),
        ("ServiceNote", 0.120, 0.085, -6.5),
        ("EvacuationOrder", -0.105, -0.105, -3.0),
        ("AscentManifest", 0.125, -0.095, 7.5),
    )
    for i, (kind, x, y, rz) in enumerate(layout):
        front = textured("Page_" + kind, form_texture("T_Page_%s" % kind, kind))
        back_name = "Page_EvacuationOrder_Back" if kind == "EvacuationOrder" else "Paper_Back"
        back = bpy.data.materials.get(back_name) or textured(back_name, back_texture("T_" + back_name, kind if kind == "EvacuationOrder" else None))
        # each sheet lies 0.8 mm above the one set down before it, so overlapping pages never share a depth
        s = sheet("Record_" + kind, (x, y, 0.0008 * i), rz, front, back)
        sheets.append(s)
        # the transparent weight sits on the sheet's outer corner, in the sheet's own frame
        cx, cy = (0.062 if x > 0 else -0.062), (0.105 if y > 0 else -0.105)
        a = math.radians(rz)
        wx, wy = x + cx * math.cos(a) - cy * math.sin(a), y + cx * math.sin(a) + cy * math.cos(a)
        w = hw.box("Weight_%02d" % (i + 1), (0.045, 0.045, 0.018), (wx, wy, 0.0016 + 0.0008 * i), acrylic, bevel=0.003, rot=(0, 0, rz))
        weights.append(w)
    return "PR_Records2034", sheets + weights


def tape():
    vinyl = textured("TapeOrange", tape_texture("T_TapeOrange_BaseColor"), rough=0.35)
    core = hw.material("TapeCore", hw.lin("#B79A72"), rough=0.9)
    roll = ring("Roll", 0.0195, 0.028, 0.019, (0, 0, 0.0095), vinyl)
    roll_core = ring("RollCore", 0.019, 0.0196, 0.0192, (0, 0, 0.0096), core)
    roll_core.parent = roll
    roll_core.location = (0, 0, 0)
    # one strip wrapped once round a 12 mm cable (axis X), its two ends pressed together into a 35 mm flag that hangs
    # below the cable; the flag's tip rests on the table in this rest layout
    cz = 0.035 + 0.0064
    band = ring("Strip", 0.0061, 0.0064, 0.019, (0.060, 0, cz), vinyl, axis="X", verts=40)
    flag = hw.box("StripFlag", (0.019, 0.0007, 0.035), (0.060, 0, 0.0), vinyl, bevel=0.0, segs=1)
    parent_keep(flag, band)
    sock = hw.empty("Socket_Cable", (0.060, 0, cz))
    parent_keep(sock, band)
    return "PR_MarkerTape", [roll, roll_core, band, flag]


def link_kit_only(glb_path):
    """As build_impact_monitor.link_kit_textures, but only the kit's own `T_Kit_*` images become relative uris;
    the generated paper and tape maps stay embedded."""
    doc, binary = hw.glbx._read_glb(glb_path)
    rel = os.path.relpath(hw.KIT_TEX, os.path.dirname(os.path.abspath(glb_path)))
    removed = set()
    for i, image in enumerate(doc.get("images", [])):
        name = image.get("name", "")
        if "bufferView" not in image or not name.startswith("T_Kit_"):
            continue
        assert os.path.exists(os.path.join(hw.KIT_TEX, name + ".png")), name
        removed.add(image["bufferView"])
        doc["images"][i] = {"name": name, "mimeType": "image/png", "uri": f"{rel}/{name}.png"}
    if not removed:
        return 0
    keep = [i for i in range(len(doc["bufferViews"])) if i not in removed]
    new_binary, new_views = bytearray(), []
    for i in keep:
        view = dict(doc["bufferViews"][i])
        start = view.pop("byteOffset", 0)
        new_binary += b"\0" * (-len(new_binary) % 4)
        view["byteOffset"] = len(new_binary)
        new_binary += binary[start: start + view["byteLength"]]
        new_views.append(view)
    hw.glbx._remap_buffer_views(doc, keep)
    doc["bufferViews"] = new_views
    if doc.get("buffers"):
        doc["buffers"][0]["byteLength"] = len(new_binary)
    hw.glbx._write_glb(glb_path, doc, bytes(new_binary))
    return len(removed)


def finish_and_export(name, objs, out_dir):
    """Applies modifiers, adds UVs where needed (kit materials get world planar UVs), measures and exports."""
    bpy.context.view_layer.update()
    for o in objs:
        if o.type != "MESH":
            continue
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        for mod in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=mod.name)
        mat = o.data.materials[0] if o.data.materials else None
        if mat is not None and "tile" in mat:
            hw.planar_uvs(o, mat["tile"])
        elif not o.data.uv_layers:
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02, scale_to_bounds=False)
            bpy.ops.object.mode_set(mode="OBJECT")
        if o.name.startswith(("Body", "Lid", "Seal", "Latch", "Weight")):
            bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
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
    d = os.path.join(out_dir, name)
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, name + ".glb")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=True,
                              export_animations=False, export_skins=False, export_image_format="JPEG",
                              export_jpeg_quality=90)
    linked = link_kit_only(path)
    if linked:
        hw.use_shared_textures_on_import(path)   # kit textures by uri: Godot must use them as imported (see there)
    size = mx - mn
    print(f"STATS {name} height={size.z:.4f} longest={max(size):.4f} size=({size.x:.4f},{size.y:.4f},{size.z:.4f}) "
          f"min_z={mn.z:.4f} tris={tris} kit_textures={linked} file={path}")


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = argv[0]
    builders = {"sleeve": sleeve, "records": records, "tape": tape}
    for key in (argv[1:] or list(builders)):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        hw._gltf_group = None
        name, objs = builders[key]()
        finish_and_export(name, objs, out)


if __name__ == "__main__":
    main()
