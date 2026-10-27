"""Hand review sheet: every Hand* pose on both hands, from the back, palm, thumb side and little-finger side.

  blender -b -P render_hands.py -- <character.glb> <out.jpg> [--res 240] [--poses Relaxed,Open,Grip,Fist,Point,Pinch]

The body stays in its rest pose; only the finger pose changes. Rows are poses, columns are the four views of the
right hand then the left hand.
"""
import argparse, json, math, os, subprocess, sys, tempfile

def compose(manifest):  # runs under the system python (Blender's has no PIL)
    from PIL import Image, ImageDraw
    m = json.load(open(manifest)); S, rows, heads = m["res"], m["rows"], m["heads"]
    sheet = Image.new("RGB", (S * len(heads), S * len(rows) + 18), "white"); d = ImageDraw.Draw(sheet)
    for j, h in enumerate(heads): d.text((j * S + 4, 3), h, fill=(0, 0, 0))
    for i, (label, cells) in enumerate(rows):
        for j, f in enumerate(cells): sheet.paste(Image.open(f).convert("RGB"), (j * S, 18 + i * S))
        d.rectangle((0, 18 + i * S + S - 16, 8 * len(label) + 8, 18 + i * S + S), fill=(0, 0, 0)); d.text((4, 18 + i * S + S - 15), label, fill=(255, 255, 255))
    sheet.save(m["out"], quality=90); print("HAND SHEET ->", m["out"])

if len(sys.argv) == 3 and sys.argv[1] == "--compose":
    compose(sys.argv[2]); sys.exit()
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser(); p.add_argument("src"); p.add_argument("out"); p.add_argument("--res", type=int, default=240)
p.add_argument("--poses", default="Relaxed,Open,Grip,Fist,Point,Pinch")
a = p.parse_args(argv)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE"); AW = arm.matrix_world
for t in arm.animation_data.nla_tracks: t.mute = True
sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE"
sc.render.resolution_x = sc.render.resolution_y = a.res
w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.55, 0.57, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 0.7
for n, rot, e in (("K", (50, 0, 30), 3.5), ("F", (70, 0, -60), 1.8), ("R", (60, 0, 180), 2.0)):
    l = bpy.data.objects.new(n, bpy.data.lights.new(n, "SUN")); l.data.energy = e; l.rotation_euler = [math.radians(r) for r in rot]; sc.collection.objects.link(l)
cam = bpy.data.objects.new("C", bpy.data.cameras.new("C")); cam.data.lens = 70; sc.collection.objects.link(cam); sc.camera = cam
P = "mixamorig:"
def head(b): return AW @ arm.pose.bones[P + b].head
tmp = tempfile.mkdtemp(); rows = []
heads = [f"{s} {v}" for s in ("R", "L") for v in ("back", "palm", "thumb side", "little side")]
for pose in a.poses.split(","):
    act = bpy.data.actions.get(f"Hand{pose}")
    if act is None: print("missing pose", pose); continue
    arm.animation_data.action = act; sc.frame_set(0); bpy.context.view_layer.update()
    cells = []
    for side in ("Right", "Left"):
        h, m1, i1, p1 = head(f"{side}Hand"), head(f"{side}HandMiddle1"), head(f"{side}HandIndex1"), head(f"{side}HandPinky1")
        pn = (i1 - p1).cross(m1 - h).normalized(); pn = -pn if side == "Left" else pn
        thumb = (i1 - p1).normalized(); fdir = (m1 - h).normalized()
        tips = [head(f"{side}Hand{f}{k}") for f in ("Thumb", "Index", "Middle", "Ring", "Pinky") for k in (1, 2, 3, 4)]
        c = (sum(tips, Vector()) + h) / (len(tips) + 1); dist = 3.2 * (m1 - h).length
        cam.data.clip_start = dist - 1.3 * (m1 - h).length   # clip anything (thigh, torso) between camera and hand
        for vdir in (-pn, pn, thumb, -thumb):
            cam.location = c + vdir * dist; cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
            up = -fdir   # fingers point down the frame
            cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
            q = (c - cam.location).normalized(); x = up.cross(q).normalized(); yv = q.cross(x)
            from mathutils import Matrix
            cam.matrix_world = Matrix((( x.x, yv.x, -q.x, cam.location.x), (x.y, yv.y, -q.y, cam.location.y), (x.z, yv.z, -q.z, cam.location.z), (0, 0, 0, 1)))
            f = os.path.join(tmp, f"{pose}_{side}_{len(cells)}.png"); sc.render.filepath = f; bpy.ops.render.render(write_still=True); cells.append(f)
    rows.append((pose, cells))
man = os.path.join(tmp, "manifest.json")
json.dump({"res": a.res, "rows": rows, "heads": heads, "out": os.path.abspath(a.out)}, open(man, "w"))
subprocess.run(["/usr/bin/env", "-u", "PYTHONPATH", "-u", "PYTHONHOME", "python3", os.path.abspath(__file__), "--compose", man], check=True)
