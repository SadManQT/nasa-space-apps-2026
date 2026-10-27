"""Headless Blender clean-up for raw Tripo/Meshy GLBs -> Godot-ready GLB.

  blender -b -P blender_cleanup.py -- <in.glb> <out.glb> --tris 50000 [--height 1.75 | --longest 0.25] [--yaw -90] [--rigged] [--tex 2048]

- Decimates every mesh so the total triangle count lands near --tris (art bible §7).
  Vertices are welded first and the Decimate runs before any Armature modifier, so skin
  weights survive.
- --yaw rotates about the vertical axis (Tripo exports characters facing +X; -90 turns
  them to face glTF/Godot forward).
- Scales so the model is --height metres tall, puts the origin at the base centre (between
  the feet) and applies all transforms, armature included.
- --rigged: drops loose meshes that are not skinned to the armature (Tripo adds a stray
  icosphere) and exports skins and animations.
Prints before/after triangle counts and bounding size.
"""
import argparse, math, sys
import bmesh, bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser()
p.add_argument("src"); p.add_argument("dst")
p.add_argument("--tris", type=int, required=True)
p.add_argument("--height", type=float)
p.add_argument("--longest", type=float, help="scale so the longest side is this many metres (props lying flat)")
p.add_argument("--yaw", type=float, default=0.0)
p.add_argument("--rigged", action="store_true")
p.add_argument("--tex", type=int, default=2048, help="max texture size in px (art bible: characters 4096, hero props 2048, small props 1024)")
a = p.parse_args(argv)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
scene = bpy.context.scene

if a.rigged:
    for o in [o for o in scene.objects if o.type == "MESH" and not any(m.type == "ARMATURE" for m in o.modifiers)]:
        print("DROP", o.name)
        bpy.data.objects.remove(o)
meshes = [o for o in scene.objects if o.type == "MESH"]


def tris(objs):
    return sum(sum(len(f.vertices) - 2 for f in o.data.polygons) for o in objs)


def bounds(objs):
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    lo = Vector([min(q[i] for q in pts) for i in range(3)])
    hi = Vector([max(q[i] for q in pts) for i in range(3)])
    return lo, hi


before = tris(meshes)
ratio = min(1.0, a.tris / max(before, 1))
for o in meshes:
    if ratio < 1.0:
        # glTF import splits vertices at UV/normal seams; collapse-decimating disconnected
        # triangles deletes whole regions, so weld first (UVs stay per-loop).
        bm = bmesh.new(); bm.from_mesh(o.data)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bm.to_mesh(o.data); bm.free()
        m = o.modifiers.new("Decimate", "DECIMATE")
        m.ratio = ratio
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_move_to_index(modifier=m.name, index=0)  # before Armature
        bpy.ops.object.modifier_apply(modifier=m.name)

lo, hi = bounds(meshes)
scale = a.height / (hi.z - lo.z) if a.height else a.longest / max(hi - lo) if a.longest else 1.0  # Blender is Z-up; glTF export converts to Y-up
offset = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
xform = Matrix.Scale(scale, 4) @ Matrix.Rotation(math.radians(a.yaw), 4, "Z") @ Matrix.Translation(-offset)
for o in [o for o in scene.objects if o.parent is None]:
    o.matrix_world = xform @ o.matrix_world

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

for img in bpy.data.images:
    w, h = img.size
    if max(w, h) > a.tex:
        img.scale(int(w * a.tex / max(w, h)), int(h * a.tex / max(w, h)))
tex = max((max(i.size) for i in bpy.data.images), default=0)

lo, hi = bounds(meshes)
print(f"CLEANUP tris {before} -> {tris(meshes)} | size {tuple(round(v, 3) for v in (hi - lo))} m | base z {lo.z:.3f} | tex {tex}px")
bpy.ops.export_scene.gltf(filepath=a.dst, export_format="GLB", export_yup=True,
                          export_animations=a.rigged, export_skins=a.rigged)
