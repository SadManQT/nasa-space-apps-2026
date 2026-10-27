"""Render evenly spaced frames of an animated GLB, to check a clip's motion and skinning.

  blender -b -P render_anim.py -- <animated.glb> <out.png> [--frames 6] [--res 512] [--angle 35] [--action Walk]
  blender -b -P render_anim.py -- <animated.glb> <out_dir> --action all      (one <clip>.png strip per clip)
  blender -b -P render_anim.py -- <animated.glb> <out.mp4> --action Walk --video [--res 720]   (every frame, H.264)

Same studio lighting as render_preview.py. The camera is fixed on each clip's whole motion range (sampled
first), so travel, crouches and reaches stay in frame. Without --action the first action is used; --action matches part of a clip name.
"""
import argparse, math, os, subprocess, sys, tempfile
from pathlib import Path
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser()
p.add_argument("src"); p.add_argument("out")
p.add_argument("--frames", type=int, default=6); p.add_argument("--res", type=int, default=512)
p.add_argument("--angle", type=float, default=35); p.add_argument("--action")
p.add_argument("--video", action="store_true", help="render every frame of the clip to an MP4 instead of a strip")
a = p.parse_args(argv)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
shapes = {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones}
for o in [o for o in sc.objects if o in shapes]:  # glTF importer's bone-display icosphere
    bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE")
if a.action == "all":
    acts = sorted(bpy.data.actions, key=lambda ac: ac.name)
else:
    acts = [next((ac for ac in bpy.data.actions if a.action and a.action.lower() in ac.name.lower()), None)
            or arm.animation_data.action]
print("ACTIONS", [ac.name for ac in acts])

def frames_of(act):
    f0, f1 = (int(v) for v in act.frame_range)
    if a.video:
        return list(range(f0, f1 + 1))
    return [round(f0 + (f1 - f0) * i / max(1, a.frames - 1)) for i in range(a.frames)]

meshes = [o for o in sc.objects if o.type == "MESH"]
def motion_box(clips):
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for act in clips:
        arm.animation_data.action = act
        for f in frames_of(act):
            sc.frame_set(f)
            dg = bpy.context.evaluated_depsgraph_get()
            for o in meshes:
                ev = o.evaluated_get(dg)
                for c in ev.bound_box:
                    w = ev.matrix_world @ Vector(c)
                    lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
    return (lo + hi) / 2, hi - lo

sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE"
sc.render.resolution_x = sc.render.resolution_y = a.res
world = bpy.data.worlds.new("W"); sc.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.55, 0.57, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.6
for name, rot, energy in (("Key", (50, 0, 35), 4.0), ("Fill", (60, 0, -60), 1.5), ("Rim", (70, 0, 180), 2.5)):
    light = bpy.data.objects.new(name, bpy.data.lights.new(name, "SUN"))
    light.data.energy = energy
    light.rotation_euler = [math.radians(r) for r in rot]
    sc.collection.objects.link(light)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); cam.data.lens = 85
sc.collection.objects.link(cam); sc.camera = cam
def aim(centre, size):
    r = math.radians(a.angle)
    dist = max(size) * 3.6
    cam.location = centre + Vector((dist * math.sin(r), -dist * math.cos(r), size.z * 0.05))
    cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()

cols = min(a.frames, 6)
if a.action == "all":
    os.makedirs(a.out, exist_ok=True)
for act in acts:
    aim(*motion_box([act]))
    arm.animation_data.action = act
    tmp = Path(tempfile.mkdtemp())
    for i, f in enumerate(frames_of(act)):
        sc.frame_set(f)
        sc.render.filepath = str(tmp / f"f{i:02d}.png") if not a.video else str(tmp / f"f{i:04d}.png")
        bpy.ops.render.render(write_still=True)
    out = os.path.join(a.out, f"{act.name}.png") if a.action == "all" else a.out
    if a.video:
        fps = round(sc.render.fps / sc.render.fps_base)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(fps), "-i", str(tmp / "f%04d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", out], check=True)
    else:
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(tmp / "f%02d.png"),
                        "-vf", f"tile={cols}x{math.ceil(a.frames / cols)}", "-frames:v", "1", out], check=True)
    print("WROTE", out)
