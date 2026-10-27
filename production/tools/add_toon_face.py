"""Add the anime face layers (FaceEyeL/R, FaceBrowL/R, FaceMouth) to a rigged, animated character.

  blender -b -P add_toon_face.py -- <body.glb> <prepared.glb> <facekit_dir> <out.glb>

facekit_dir comes from make_toon_face_atlas.py: face_<part>.png atlases and face.json with each layer's rectangle in
the prepared model's space. The body may be rescaled from the prepared model, so rectangles are mapped through the two
bounding boxes. Each layer is a grid moulded onto the skin: rays start inside the head and go out through the face,
so the first hit is the skin even where hair hangs in front of it. Layers sit 0.7 mm off the skin, follow the Head
bone, and show cell 0 of their atlas (transparent) by default; the game's FaceAtlas shader picks the cell.
Every clip is kept: actions are put back on NLA tracks before export, as retarget_clips.py exports them.
"""
import json, os, sys
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

body, prep, kit, dst = sys.argv[sys.argv.index("--") + 1:]
GRID = {"eye": (16, 10), "brow": (14, 8), "mouth": (18, 10)}
LIFT = 0.0007

bpy.ops.wm.read_factory_settings(use_empty=True)

def bbox(objs):
    pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])

bpy.ops.import_scene.gltf(filepath=prep)
plo, phi = bbox([o for o in bpy.context.scene.objects if o.type == "MESH"])
for o in list(bpy.context.scene.objects):
    bpy.data.objects.remove(o)
for m in [m for m in bpy.data.meshes if m.users == 0]:   # the prepared mesh, so the body can take the name "Body"
    bpy.data.meshes.remove(m)

bpy.ops.import_scene.gltf(filepath=body)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}:
    bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE")
meshes = [o for o in sc.objects if o.type == "MESH"]
skin_obj = max(meshes, key=lambda o: len(o.data.vertices))
skin_obj.name = skin_obj.data.name = "Body"
blo, bhi = bbox([skin_obj])
k = (bhi.z - blo.z) / (phi.z - plo.z)
to_body = lambda x, z: (blo.x + (x - plo.x) * k + ((bhi.x - blo.x) - (phi.x - plo.x) * k) / 2, blo.z + (z - plo.z) * k)

dg = bpy.context.evaluated_depsgraph_get()
arm.data.pose_position = "REST"; dg.update()
ev = skin_obj.evaluated_get(dg); me = ev.to_mesh()
mw = skin_obj.matrix_world
tree = BVHTree.FromPolygons([mw @ v.co for v in me.vertices], [p.vertices[:] for p in me.polygons])
head_pts = [mw @ v.co for v in me.vertices if (mw @ v.co).z > bhi.z - 0.16 * k]
head_y = sorted(p.y for p in head_pts)[len(head_pts) // 2]
ev.to_mesh_clear()

info = json.load(open(os.path.join(kit, "face.json")))
head_bone = next(b.name for b in arm.data.bones if b.name.endswith("Head"))
for part, d in info.items():
    x0, z0 = to_body(d["rect_world"][0], d["rect_world"][1]); x1, z1 = to_body(d["rect_world"][2], d["rect_world"][3])
    nx, nz = GRID[part[:-1] if part != "mouth" else "mouth"]
    verts, uvs, hits = [], [], 0
    for j in range(nz + 1):
        for i in range(nx + 1):
            u, v = i / nx, j / nz; x, z = x0 + (x1 - x0) * u, z0 + (z1 - z0) * v
            loc, nrm, _, _ = tree.ray_cast(Vector((x, head_y, z)), Vector((0, -1, 0)))
            if loc is None:
                verts.append(None)
            else:
                hits += 1; n = nrm if nrm.y < 0 else -nrm
                verts.append(loc + n * LIFT)
            uvs.append((u, v))
    for idx, p in enumerate(verts):        # rare misses at the face edge take the nearest hit's depth
        if p is None:
            near = min((q for q in verts if q is not None), key=lambda q: (q.x - (x0 + (x1 - x0) * uvs[idx][0])) ** 2 + (q.z - (z0 + (z1 - z0) * uvs[idx][1])) ** 2)
            verts[idx] = Vector((x0 + (x1 - x0) * uvs[idx][0], near.y, z0 + (z1 - z0) * uvs[idx][1]))
    faces = [(j * (nx + 1) + i, j * (nx + 1) + i + 1, (j + 1) * (nx + 1) + i + 1, (j + 1) * (nx + 1) + i) for j in range(nz) for i in range(nx)]
    name = {"eyeL": "FaceEyeL", "eyeR": "FaceEyeR", "browL": "FaceBrowL", "browR": "FaceBrowR", "mouth": "FaceMouth"}[part]
    m = bpy.data.meshes.new(name); m.from_pydata([tuple(p) for p in verts], [], faces); m.update()
    uvl = m.uv_layers.new(name="UVMap")
    for poly in m.polygons:
        for li in poly.loop_indices:
            uvl.data[li].uv = uvs[m.loops[li].vertex_index]
    ob = bpy.data.objects.new(name, m); sc.collection.objects.link(ob)
    mat = bpy.data.materials.new(name); mat.use_nodes = True; nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(os.path.join(kit, f"face_{part}.png")); tex.image.pack()
    mp = nt.nodes.new("ShaderNodeMapping"); uvn = nt.nodes.new("ShaderNodeTexCoord")
    cols, rows = d["grid"]; mp.inputs["Scale"].default_value = (1 / cols, 1 / rows, 1); mp.inputs["Location"].default_value = (0, (rows - 1) / rows, 0)
    nt.links.new(uvn.outputs["UV"], mp.inputs["Vector"]); nt.links.new(mp.outputs[0], tex.inputs["Vector"])
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"]); nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    bsdf.inputs["Roughness"].default_value = 0.9
    mat.blend_method = "BLEND" if hasattr(mat, "blend_method") else mat.blend_method
    if hasattr(mat, "surface_render_method"): mat.surface_render_method = "BLENDED"
    m.materials.append(mat)
    vg = ob.vertex_groups.new(name=head_bone); vg.add(list(range(len(verts))), 1.0, "REPLACE")
    ob.parent = arm; mod = ob.modifiers.new("Armature", "ARMATURE"); mod.object = arm
    print(f"LAYER {name}: {len(verts)} verts, {hits} hits, rect x {x0:.4f}..{x1:.4f} z {z0:.4f}..{z1:.4f}")

# The face skin follows the Head bone alone, like the drawn layers on it: with neck weight under the mouth and eyes,
# the painted features slide out from under the drawn ones whenever the head turns. Below the chin the weights ramp
# back into the rig's own over a few centimetres, so the neck still bends smoothly.
chin = to_body(0.0, info["mouth"]["rect_world"][1])[1] - 0.03 * k; ramp = 0.035 * k
hg = skin_obj.vertex_groups.get(head_bone) or skin_obj.vertex_groups.new(name=head_bone)
moved = 0
for v in skin_obj.data.vertices:
    t = min(max(((mw @ v.co).z - (chin - ramp)) / ramp, 0.0), 1.0)
    if t <= 0.0: continue
    head_w = 0.0
    for g in v.groups:
        if g.group == hg.index: head_w = g.weight; continue
        skin_obj.vertex_groups[g.group].add([v.index], g.weight * (1.0 - t), "REPLACE")
    hg.add([v.index], head_w + (1.0 - head_w) * t, "REPLACE"); moved += 1
print(f"FACE WEIGHTS: {moved} head vertices follow {head_bone} (chin at {chin:.3f} m)")

arm.data.pose_position = "POSE"
ad = arm.animation_data or arm.animation_data_create()
have = {s.action.name for t in ad.nla_tracks for s in t.strips if s.action}
for act in bpy.data.actions:
    if act.name in have: continue
    t = ad.nla_tracks.new(); t.name = act.name
    t.strips.new(act.name, int(act.frame_range[0]), act); t.mute = True
ad.action = None
print("CLIPS", len(ad.nla_tracks), sorted(t.name for t in ad.nla_tracks))
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_yup=True, export_skins=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS")
print("FACE DONE ->", dst)
