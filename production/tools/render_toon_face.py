"""Close-up sheet of a v7 character's anime face states, rendered in 3D with the face layers (front and 3/4 views).

  blender -b -P render_toon_face.py -- <character.glb> <out.jpg> [--res 320] [--pose Idle_loop]

Each column is one state: the eye, brow and mouth atlas cells are picked by moving the layers' texture mapping, the
same cells the game's FaceAtlas shader shows. Composes the sheet with the system python3.
"""
import argparse, json, math, os, subprocess, sys, tempfile

STATES = [  # label, eye cell, brow cell, mouth cell
    ("neutral", 0, 0, 0), ("blink half", 1, 0, 0), ("closed", 2, 0, 0), ("happy", 3, 1, 3), ("surprised", 4, 1, 4),
    ("worried", 5, 3, 6), ("serious", 0, 2, 1), ("talk B", 0, 0, 2), ("talk E", 0, 0, 5), ("talk G", 0, 0, 7)]

if len(sys.argv) == 3 and sys.argv[1] == "--compose":
    from PIL import Image, ImageDraw
    m = json.load(open(sys.argv[2])); S = m["res"]
    sheet = Image.new("RGB", (S * len(m["cols"]), S * 2), "white"); d = ImageDraw.Draw(sheet)
    for i, (label, files) in enumerate(m["cols"]):
        for j, f in enumerate(files): sheet.paste(Image.open(f).convert("RGB"), (i * S, j * S))
        d.rectangle((i * S, 0, i * S + 8 * len(label) + 8, 14), fill=(0, 0, 0)); d.text((i * S + 4, 1), label, fill=(255, 255, 255))
    sheet.save(m["out"], quality=90); print("FACE SHEET ->", m["out"]); sys.exit()

import bpy
from mathutils import Vector
a = argparse.ArgumentParser(); a.add_argument("src"); a.add_argument("out"); a.add_argument("--res", type=int, default=320); a.add_argument("--pose", default="Idle_loop")
a = a.parse_args(sys.argv[sys.argv.index("--") + 1:])
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE")
ad = arm.animation_data
if ad:
    for t in ad.nla_tracks: t.mute = True
    act = next((x for x in bpy.data.actions if x.name.split("|")[0] == a.pose or a.pose in x.name), None)
    ad.action = act
sc.frame_set(1)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import blender_look
head = arm.matrix_world @ arm.pose.bones[next(b.name for b in arm.data.bones if b.name.endswith("Head"))].head
blender_look.setup(sc, centre=head, scale=0.35)
sc.render.resolution_x = sc.render.resolution_y = a.res
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 85
layers = {o.name.split(".")[0]: o for o in sc.objects if o.name.startswith("Face")}
def mapping(o):
    nt = o.active_material.node_tree
    return next(n for n in nt.nodes if n.type == "MAPPING"), next(n for n in nt.nodes if n.type == "TEX_IMAGE")
grids = {}
for name, o in layers.items():
    mp, tex = mapping(o); s = mp.inputs["Scale"].default_value; grids[name] = (round(1 / s[0]), round(1 / s[1]))
tmp = tempfile.mkdtemp(); cols = []
def centre(o):
    pts = [o.matrix_world @ v.co for v in o.data.vertices]; return sum(pts, Vector()) / len(pts)
target = sum((centre(o) for o in layers.values()), Vector()) / len(layers)   # the middle of the face layers
for label, e, b, m in STATES:
    for name, o in layers.items():
        idx = e if "Eye" in name else b if "Brow" in name else m
        c, r = grids[name]; mp, _ = mapping(o)
        mp.inputs["Location"].default_value = ((idx % c) / c, (r - 1 - idx // c) / r, 0)
    files = []
    for v, d in (("front", Vector((0, -1, 0.05))), ("34", Vector((0.6, -0.8, 0.08)))):
        cam.location = target + d.normalized() * 0.55; cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
        f = os.path.join(tmp, f"{label.replace(' ', '_')}_{v}.png"); sc.render.filepath = f; bpy.ops.render.render(write_still=True); files.append(f)
    cols.append((label, files))
man = os.path.join(tmp, "m.json"); json.dump({"res": a.res, "cols": cols, "out": a.out}, open(man, "w"))
subprocess.run(["python3", os.path.abspath(__file__), "--compose", man], check=True)
