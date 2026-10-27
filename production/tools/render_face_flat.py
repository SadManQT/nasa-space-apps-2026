"""Flat (unlit base colour) orthographic front render of a character's face, for placing the toon face layers.

  blender -b -P render_face_flat.py -- <prepared.glb> <out.png> [--res 2048] [--size 0.32] [--drop 0.13]

The character must face -Y with feet at z=0 (prep_tripo_character.py). Writes <out.png> and <out>.json with the
camera centre (x, z) and ortho size, so a pixel maps to world as x = cx + (px/res - 0.5) * size,
z = cz - (py/res - 0.5) * size.
"""
import argparse, json, sys
import bpy
from mathutils import Vector

a = argparse.ArgumentParser()
a.add_argument("src"); a.add_argument("out"); a.add_argument("--res", type=int, default=2048); a.add_argument("--size", type=float, default=0.32)
a.add_argument("--drop", type=float, default=0.13)   # crown to face centre; more for tall hair (Amara's bun)
a = a.parse_args(sys.argv[sys.argv.index("--") + 1:])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
ob = next(o for o in sc.objects if o.type == "MESH")
V = [ob.matrix_world @ v.co for v in ob.data.vertices]
top = max(v.z for v in V)
head = [v for v in V if v.z > top - 0.16]
cx = sum(v.x for v in head) / len(head)
cz = top - a.drop                     # the whole face, crown to chin, fits in the default 0.32 m square
for m in ob.data.materials:           # unlit base colour, so the render is the texture as seen from the front
    nt = m.node_tree; bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if not bsdf: continue
    src = bsdf.inputs["Base Color"].links[0].from_socket if bsdf.inputs["Base Color"].links else None
    em = nt.nodes.new("ShaderNodeEmission"); out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
    if src: nt.links.new(src, em.inputs["Color"])
    else: em.inputs["Color"].default_value = bsdf.inputs["Base Color"].default_value
    nt.links.new(em.outputs[0], out.inputs["Surface"])
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = a.size
cam.location = Vector((cx, -2.0, cz)); cam.rotation_euler = (1.5707963, 0, 0)
sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x = sc.render.resolution_y = a.res
sc.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (1, 0, 1, 1)
sc.render.filepath = a.out; bpy.ops.render.render(write_still=True)
json.dump({"cx": cx, "cz": cz, "size": a.size, "res": a.res}, open(a.out.rsplit(".", 1)[0] + ".json", "w"))
print("FACE", a.out, "cx=%.4f cz=%.4f" % (cx, cz))
