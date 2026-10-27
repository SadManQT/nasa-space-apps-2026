"""Render front / side / back / 3-4 preview stills of a GLB for review.

  blender -b -P render_preview.py -- <model.glb> <out_prefix> [--res 768] [--views front,side,back,34,top34]

Writes <out_prefix>_front.png, _side.png, _back.png, _34.png, _top34.png and prints mesh stats.
Neutral grey studio lighting, orthographic-ish long lens, EEVEE.
"""
import argparse, math, sys
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser()
p.add_argument("src"); p.add_argument("out"); p.add_argument("--res", type=int, default=768)
p.add_argument("--views", default="front,side,back,34,top34")
a = p.parse_args(argv)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
shapes = {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones}
for o in [o for o in sc.objects if o in shapes]:  # glTF importer's bone-display icosphere
    bpy.data.objects.remove(o)
meshes = [o for o in sc.objects if o.type == "MESH"]
pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
lo = Vector([min(q[i] for q in pts) for i in range(3)])
hi = Vector([max(q[i] for q in pts) for i in range(3)])
centre, size = (lo + hi) / 2, hi - lo
tris = sum(sum(len(f.vertices) - 2 for f in o.data.polygons) for o in meshes)
mats = {m.name for o in meshes for m in o.data.materials if m}
imgs = [(i.name, tuple(i.size)) for i in bpy.data.images]
print(f"STATS meshes={len(meshes)} tris={tris} size={tuple(round(v, 3) for v in size)} "
      f"materials={len(mats)} images={imgs} armatures={sum(o.type == 'ARMATURE' for o in sc.objects)} "
      f"actions={[ac.name for ac in bpy.data.actions]}")

sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE"
sc.render.resolution_x = sc.render.resolution_y = a.res
sc.render.film_transparent = False
world = bpy.data.worlds.new("W"); sc.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.55, 0.57, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.6
for name, rot, energy in (("Key", (50, 0, 35), 4.0), ("Fill", (60, 0, -60), 1.5), ("Rim", (70, 0, 180), 2.5)):
    light = bpy.data.objects.new(name, bpy.data.lights.new(name, "SUN"))
    light.data.energy = energy
    light.rotation_euler = [math.radians(r) for r in rot]
    sc.collection.objects.link(light)

cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.lens = 85
sc.collection.objects.link(cam); sc.camera = cam
dist = max(size) * 3.6
# Blender is Z-up; glTF front (+Z forward in glTF) imports facing -Y.
for tag, ang, high in [v for v in (("front", 0, 0), ("side", 90, 0), ("back", 180, 0), ("34", 35, 0), ("top34", 35, 1)) if v[0] in a.views.split(",")]:
    r = math.radians(ang)
    # top34 looks down from about 50 degrees so open lids, trays and table tops are visible
    cam.location = centre + Vector((dist * math.sin(r), -dist * math.cos(r), dist * 1.2 if high else size.z * 0.05))
    cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = f"{a.out}_{tag}.png"
    bpy.ops.render.render(write_still=True)
    print("WROTE", sc.render.filepath)
