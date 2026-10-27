"""Showcase render of a character clip with game-style lighting (soft environment light, warm key, cool rim, AgX
film tonemapping, contact shadows on a ground plane), for reviews that should look like the game, not a grey void.

  blender -b -P render_showcase.py -- <character.glb> <action> <out_prefix> [--frames 10,30,50] [--video] [--shot full|medium|upper]
         [--res 1280] [--side right|left|front] [--label TEXT]

--frames writes <out_prefix>_f<N>.png stills; --video writes <out_prefix>.mp4 (every frame, 30 fps). The camera
frames the character over the whole clip so nothing leaves the shot.
"""
import argparse, math, os, subprocess, sys, tempfile
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser(); p.add_argument("src"); p.add_argument("action"); p.add_argument("out")
p.add_argument("--frames", default=""); p.add_argument("--video", action="store_true"); p.add_argument("--shot", default="medium")
p.add_argument("--res", type=int, default=1280); p.add_argument("--side", default="right"); p.add_argument("--label", default="")
a = p.parse_args(argv)

bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE"); AW = arm.matrix_world
ad = arm.animation_data
for t in ad.nla_tracks: t.mute = True
act = next(x for x in bpy.data.actions if x.name == a.action or a.action in x.name.split("|"))
ad.action = act; f0, f1 = (int(round(v)) for v in act.frame_range)

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blender_look
sc.render.resolution_x, sc.render.resolution_y = a.res, a.res * 9 // 16
blender_look.setup(sc); blender_look.floor()
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.lens = {"full": 50, "medium": 70, "upper": 85}.get(a.shot, 70); cam.data.dof.use_dof = False

# frame the character over the clip
P = "mixamorig:" if any(b.name.startswith("mixamorig:") for b in arm.data.bones) else ""
def bone(n):
    b = arm.pose.bones.get(P + n) or arm.pose.bones.get(n)
    return AW @ b.head if b else None
pts = []
for f in range(f0, f1 + 1, max(1, (f1 - f0) // 24)):
    sc.frame_set(f); pts += [q for q in (bone("Head"), bone("Hips"), bone("LeftHand"), bone("RightHand"), bone("LeftFoot"), bone("RightFoot")) if q]
lo = Vector([min(q[i] for q in pts) for i in range(3)]); hi = Vector([max(q[i] for q in pts) for i in range(3)])
top = hi.z + 0.18
if a.shot == "full": c = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, top / 2)); hgt = top + 0.15
elif a.shot == "upper": c = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, top - 0.35)); hgt = 0.85
else: c = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, top - 0.55)); hgt = 1.25
vfov = 2 * math.atan(18 * 9 / 16 / cam.data.lens)
dist = (hgt / 2) / math.tan(vfov / 2) * 1.08
d = {"right": Vector((0.55, -1.0, 0.12)), "left": Vector((-0.55, -1.0, 0.12)), "front": Vector((0.0, -1.0, 0.1))}[a.side].normalized()
cam.location = c + d * dist; cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()

tmp = tempfile.mkdtemp()
if a.frames:
    for k in a.frames.split(","):
        sc.frame_set(f0 + int(k)); sc.render.filepath = f"{a.out}_f{int(k):03d}.png"; bpy.ops.render.render(write_still=True)
if a.video:
    for i, f in enumerate(range(f0, f1 + 1)):
        sc.frame_set(f); sc.render.filepath = os.path.join(tmp, f"f{i:04d}.png"); bpy.ops.render.render(write_still=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", "30", "-i", os.path.join(tmp, "f%04d.png"), "-c:v", "libx264", "-pix_fmt", "yuv420p",
                    "-crf", "20", "-movflags", "+faststart", f"{a.out}.mp4"], check=True)
print("SHOWCASE ->", a.out)
