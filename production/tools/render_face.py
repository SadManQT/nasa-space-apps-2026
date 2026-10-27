"""Face review sheet: each shape key (or mix) from the front, both three-quarters and profile, close on the mouth.

  blender -b -P render_face.py -- <rigged.glb> <out.jpg> [--keys viseme_aa,viseme_O,...] [--mix "name=key:w+key:w"] [--res 320] [--wide]

Rows are shapes ("Basis" = rest), columns are front / 3-4 left / 3-4 right / profile. --wide frames the whole
face instead of the mouth. Labels are drawn with PIL after rendering.
"""
import argparse, json, math, os, subprocess, sys, tempfile

def compose(manifest):  # runs under the system python (Blender's has no PIL)
    from PIL import Image, ImageDraw
    m = json.load(open(manifest)); S, cells, views = m["res"], m["cells"], m["views"]
    sheet = Image.new("RGB", (S * len(views), S * len(cells)), "white"); d = ImageDraw.Draw(sheet)
    for i, (label, row) in enumerate(cells):
        for j, f in enumerate(row):
            sheet.paste(Image.open(f).convert("RGB"), (j * S, i * S))
            if i == 0: d.text((j * S + 6, 4), views[j], fill=(255, 255, 255))
        d.rectangle((0, i * S + S - 18, 8 * len(label) + 8, i * S + S), fill=(0, 0, 0)); d.text((4, i * S + S - 16), label, fill=(255, 255, 255))
    sheet.save(m["out"], quality=90); print("FACE SHEET ->", m["out"], len(cells), "rows")

if len(sys.argv) == 3 and sys.argv[1] == "--compose":
    compose(sys.argv[2]); sys.exit()
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser(); p.add_argument("src"); p.add_argument("out")
p.add_argument("--keys", default="Basis,viseme_PP,viseme_FF,viseme_aa,viseme_E,viseme_I,viseme_O,viseme_U,jawOpen")
p.add_argument("--mix", action="append", default=[]); p.add_argument("--res", type=int, default=320); p.add_argument("--wide", action="store_true")
a = p.parse_args(argv)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE"); AW = arm.matrix_world
if arm.animation_data:
    for t in arm.animation_data.nla_tracks: t.mute = True
    arm.animation_data.action = None
for pb in arm.pose.bones: pb.matrix_basis.identity()
me = next(o for o in sc.objects if o.type == "MESH" and o.data.shape_keys); keys = me.data.shape_keys.key_blocks
h0 = AW @ arm.data.bones["mixamorig:Head"].head_local; h1 = AW @ arm.data.bones["mixamorig:HeadTop_End"].head_local; H = h1.z - h0.z
sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE"
sc.render.resolution_x = sc.render.resolution_y = a.res
w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.55, 0.57, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 0.6
for n, rot, e in (("K", (50, 0, 25), 3.5), ("F", (70, 0, -50), 1.5), ("R", (60, 0, 170), 2.0)):
    l = bpy.data.objects.new(n, bpy.data.lights.new(n, "SUN")); l.data.energy = e; l.rotation_euler = [math.radians(r) for r in rot]; sc.collection.objects.link(l)
cam = bpy.data.objects.new("C", bpy.data.cameras.new("C")); cam.data.lens = 85; sc.collection.objects.link(cam); sc.camera = cam
# aim at the mouth: the inner-lip/mouth parts if present, else the front of the lower face
V = [me.matrix_world @ v.co for v in me.data.vertices]
mi = {i for i, m in enumerate(me.data.materials) if m and m.name.split(".")[0] in ("LipInner", "MouthInterior")}
mv = [V[v] for f in me.data.polygons if f.material_index in mi for v in f.vertices]
face = [q for q in V if h0.z + 0.05 * H < q.z < h0.z + 0.30 * H and abs(q.x - h0.x) < 0.15 * H]
fy = min(q.y for q in face)
mz = sum(q.z for q in mv) / len(mv) if mv else h0.z + 0.15 * H
c = Vector((h0.x, fy + 0.2 * H, h0.z + 0.35 * H if a.wide else mz - 0.03 * H))
dist = (3.2 if a.wide else 1.25) * H
shapes = [(k, {k: 1.0} if k != "Basis" else {}) for k in a.keys.split(",") if k == "Basis" or k in keys]
for m in a.mix:  # "label=key:w+key:w"
    label, spec = m.split("=", 1); shapes.append((label, {s.split(":")[0]: float(s.split(":")[1]) for s in spec.split("+")}))
views = (("front", 0), ("3/4 L", -40), ("3/4 R", 40), ("profile", 90))
tmp = tempfile.mkdtemp(); cells = []
for label, mix in shapes:
    for k in keys: k.value = 0.0
    for k, v in mix.items():
        if k in keys: keys[k].value = v
    row = []
    for vname, ang in views:
        r = math.radians(ang); cam.location = c + Vector((dist * math.sin(r), -dist * math.cos(r), 0.08 * H))
        cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
        f = os.path.join(tmp, f"{len(cells)}_{len(row)}.png"); sc.render.filepath = f; bpy.ops.render.render(write_still=True); row.append(f)
    cells.append((label, row))
man = os.path.join(tmp, "manifest.json")
json.dump({"res": a.res, "cells": cells, "views": [v[0] for v in views], "out": os.path.abspath(a.out)}, open(man, "w"))
subprocess.run(["/usr/bin/env", "-u", "PYTHONPATH", "-u", "PYTHONHOME", "python3", os.path.abspath(__file__), "--compose", man], check=True)
