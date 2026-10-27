"""Prepare a static Tripo character for rigging: one mesh, facing -Y (glTF +Z), arms along X,
scaled to the character's height, feet on the floor at the origin, transforms applied.

  blender -b -P prep_tripo_character.py -- <in.glb|in.fbx> <height_m> <out.glb>

Tripo's multiview models come out about 1 m tall and facing +-X. The facing is found from the feet: toes
reach further forward than the shins.
"""
import math, sys
import bpy
from mathutils import Matrix, Vector

src, height, dst = sys.argv[sys.argv.index("--") + 1:]
height = float(height)
bpy.ops.wm.read_factory_settings(use_empty=True)
(bpy.ops.import_scene.fbx if src.lower().endswith(".fbx") else bpy.ops.import_scene.gltf)(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for o in bpy.context.scene.objects:
    o.select_set(o in meshes)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for o in list(bpy.context.scene.objects):
    if o is not ob:
        bpy.data.objects.remove(o)

V = [v.co.copy() for v in ob.data.vertices]
zmin = min(v.z for v in V); zmax = max(v.z for v in V); H = zmax - zmin
# arms (the widest part) lie along the lateral axis; the other horizontal axis is the facing axis
ext = lambda i: max(v[i] for v in V) - min(v[i] for v in V)
lat, fwd = (0, 1) if ext(0) > ext(1) else (1, 0)
feet = [v for v in V if v.z < zmin + 0.035 * H]
shins = [v for v in V if zmin + 0.10 * H < v.z < zmin + 0.22 * H]
toes_ahead = sum(v[fwd] for v in feet) / len(feet) - sum(v[fwd] for v in shins) / len(shins)
facing = Vector((0, 0, 0)); facing[fwd] = 1 if toes_ahead > 0 else -1
angle = math.atan2(facing.x, -facing.y)          # rotate the facing direction onto -Y
R = Matrix.Rotation(-angle, 4, "Z")
s = height / H
ob.data.transform(Matrix.Scale(s, 4) @ R)
V = [v.co for v in ob.data.vertices]
c = Vector(((max(v.x for v in V) + min(v.x for v in V)) / 2, (max(v.y for v in V) + min(v.y for v in V)) / 2, min(v.z for v in V)))
ob.data.transform(Matrix.Translation(-c))
ob.name = ob.data.name = "Body"
V = [v.co for v in ob.data.vertices]
print("PREP tris=%d height=%.3f width_x=%.3f depth_y=%.3f facing_was=%s%s toes_ahead=%.4f" % (
    sum(len(p.vertices) - 2 for p in ob.data.polygons), max(v.z for v in V), ext(0) * s, ext(1) * s,
    "+" if facing[fwd] > 0 else "-", "XY"[fwd], toes_ahead))
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", use_selection=False)
