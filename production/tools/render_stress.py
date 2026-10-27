"""Shoulder and arm stress sheet: both arms posed through their range, the upper body seen from front, side and back,
to judge shoulder volume, armpit, sleeve, patch and harness deformation (audit S01-S03).

  blender -b -P render_stress.py -- <character.glb> <out.jpg> [--res 300]

Poses (upper-arm direction; elbows straight unless noted): rest, forward, out to the side, overhead, across the
chest (right arm), reaching behind, and a working pose with elbows bent.
"""
import argparse, json, math, os, subprocess, sys, tempfile

def compose(manifest):
    from PIL import Image, ImageDraw
    m = json.load(open(manifest)); S = m["res"]; rows = m["rows"]
    sheet = Image.new("RGB", (S * 3, S * len(rows)), "white"); d = ImageDraw.Draw(sheet)
    for i, (label, cells) in enumerate(rows):
        for j, f in enumerate(cells): sheet.paste(Image.open(f).convert("RGB"), (j * S, i * S))
        d.rectangle((0, i * S + S - 16, 8 * len(label) + 8, i * S + S), fill=(0, 0, 0)); d.text((4, i * S + S - 15), label, fill=(255, 255, 255))
    sheet.save(m["out"], quality=90); print("STRESS SHEET ->", m["out"])

if len(sys.argv) == 3 and sys.argv[1] == "--compose":
    compose(sys.argv[2]); sys.exit()

import bpy
from mathutils import Matrix, Vector
argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser(); p.add_argument("src"); p.add_argument("out"); p.add_argument("--res", type=int, default=300)
a = p.parse_args(argv)
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE"); AW = arm.matrix_world
if arm.animation_data:  # a bare rig straight from the rigging service has no animation data
    for t in arm.animation_data.nla_tracks: t.mute = True
    arm.animation_data.action = None
sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE"
sc.render.resolution_x = sc.render.resolution_y = a.res
w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.55, 0.57, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 0.65
for n, rot, e in (("K", (45, 0, 30), 3.5), ("F", (70, 0, -60), 1.5), ("R", (60, 0, 180), 2.2)):
    l = bpy.data.objects.new(n, bpy.data.lights.new(n, "SUN")); l.data.energy = e; l.rotation_euler = [math.radians(r) for r in rot]; sc.collection.objects.link(l)
cam = bpy.data.objects.new("C", bpy.data.cameras.new("C")); cam.data.lens = 50; sc.collection.objects.link(cam); sc.camera = cam
P = "mixamorig:"
def aim(side, direction, elbow=0.0):
    """Point the upper arm along a world direction (rotating about the shoulder); optionally bend the elbow forward."""
    for b in ("Arm", "ForeArm", "Hand"): arm.pose.bones[P + side + b].matrix_basis.identity()
    bpy.context.view_layer.update()
    pb = arm.pose.bones[P + side + "Arm"]
    cur = (pb.tail - pb.head).normalized(); tgt = (AW.inverted().to_3x3() @ Vector(direction)).normalized()
    r = cur.rotation_difference(tgt).to_matrix().to_4x4()
    pb.matrix = Matrix.Translation(pb.head) @ r @ Matrix.Translation(-pb.head) @ pb.matrix; bpy.context.view_layer.update()
    if elbow:
        fb = arm.pose.bones[P + side + "ForeArm"]; d = (fb.tail - fb.head).normalized()
        k = d.cross(AW.inverted().to_3x3() @ Vector((0, -1, 0)))
        if k.length > 1e-6:
            fb.matrix = Matrix.Translation(fb.head) @ Matrix.Rotation(math.radians(elbow), 4, k.normalized()) @ Matrix.Translation(-fb.head) @ fb.matrix
        bpy.context.view_layer.update()
POSES = [("rest", None, None), ("forward", (0, -1, 0), (0, -1, 0)), ("side", (1, 0, 0), (-1, 0, 0)), ("overhead", (0.25, 0, 1), (-0.25, 0, 1)),
         ("across chest", None, (0.75, -0.65, 0.05)), ("reach behind", (0.35, 0.75, -0.55), (-0.35, 0.75, -0.55)), ("work, elbows bent", (0.15, -0.6, -0.78), (-0.15, -0.6, -0.78))]
chest = lambda: AW @ arm.pose.bones[P + "Spine2"].head
tmp = tempfile.mkdtemp(); rows = []
for label, ld, rd in POSES:
    for b in ("Arm", "ForeArm", "Hand"):
        for s in ("Left", "Right"): arm.pose.bones[P + s + b].matrix_basis.identity()
    bpy.context.view_layer.update()
    if ld: aim("Left", ld, 70 if "work" in label else 0)
    if rd: aim("Right", rd, 70 if "work" in label else 0)
    c = chest() + Vector((0, 0, 0.12)); cells = []
    for v in ((0, -1, 0.05), (1, -0.15, 0.05), (0, 1, 0.05)):
        cam.location = c + Vector(v).normalized() * 1.9; cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
        f = os.path.join(tmp, f"{len(rows)}_{len(cells)}.png"); sc.render.filepath = f; bpy.ops.render.render(write_still=True); cells.append(f)
    rows.append((label, cells))
man = os.path.join(tmp, "m.json"); json.dump({"res": a.res, "rows": rows, "out": os.path.abspath(a.out)}, open(man, "w"))
subprocess.run(["/usr/bin/env", "-u", "PYTHONPATH", "-u", "PYTHONHOME", "python3", os.path.abspath(__file__), "--compose", man], check=True)
