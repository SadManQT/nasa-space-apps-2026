"""Actions in context: each story/interaction clip played with its real prop on a floor with shadows, so contact,
support and grip can be judged (audit items A01-A07, B02).

  blender -b -P render_context.py -- <character.glb> <out_dir> [--scenes Repair,Pollinate,...] [--res 960] [--step 2]

Props are placed from the animation itself: e.g. the rover's nearest wheel goes where the hands work during Repair,
the seat goes under the pelvis at the end of SitDown, a seed packet lies under the hand at the lowest point of
PickUp and then follows the hand. Hands get the matching pose (pinch for the brush and the packet, grip on the
wheel, open for the wave). Writes <scene>.mp4 (every --step frame, so 15 fps for step 2) and <scene>_keys.jpg (four key frames), and
prints the measured contact errors (hand to prop, pelvis to seat, feet to floor).
"""
import argparse, json, math, os, subprocess, sys, tempfile

def compose(manifest):   # system python: key-frame strip
    from PIL import Image
    m = json.load(open(manifest)); ims = [Image.open(f).convert("RGB") for f in m["keys"]]
    w, h = ims[0].size; s = Image.new("RGB", (w * len(ims) // 2, h // 2))
    for i, im in enumerate(ims): s.paste(im.resize((w // 2, h // 2)), (i * w // 2, 0))
    s.save(m["out"], quality=88)

if len(sys.argv) == 3 and sys.argv[1] == "--compose":
    compose(sys.argv[2]); sys.exit()

import bpy
from mathutils import Matrix, Quaternion, Vector
argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser(); p.add_argument("src"); p.add_argument("out")
p.add_argument("--scenes", default="Repair,Pollinate,Inspect,SitDown,PickUp,Type,Wave,Walk_loop")
p.add_argument("--res", type=int, default=960); p.add_argument("--step", type=int, default=2)
a = p.parse_args(argv)
ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "game", "assets")
P = "mixamorig:"

def fresh():
    bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=a.src)
    sc = bpy.context.scene
    for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
    arm = next(o for o in sc.objects if o.type == "ARMATURE")
    for t in arm.animation_data.nla_tracks: t.mute = True
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import blender_look
    sc.render.resolution_x, sc.render.resolution_y = a.res, a.res * 9 // 16
    blender_look.setup(sc, scale=1.6); blender_look.floor()
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); cam.data.lens = 45; sc.collection.objects.link(cam); sc.camera = cam
    return sc, arm, cam

def play(arm, clip):
    """Put the clip on its own NLA strip (so a hand override can sit above it); returns the frame range."""
    act = bpy.data.actions[clip]; ad = arm.animation_data; ad.action = None
    tr = ad.nla_tracks.new(); tr.name = "Clip"; st = tr.strips.new(clip, int(act.frame_range[0]), act)
    return int(act.frame_range[0]), int(act.frame_range[1])

def hand_override(arm, pose, side, f0, f1):
    """Replace one hand's finger rotations with a Hand* pose for the whole clip (an NLA track above the clip)."""
    sc = bpy.context.scene; src = bpy.data.actions[f"Hand{pose}"]; ad = arm.animation_data
    keep = [t.mute for t in ad.nla_tracks]
    for t in ad.nla_tracks: t.mute = True
    ad.action = src; sc.frame_set(0)
    vals = {pb.name: pb.rotation_quaternion.copy() for pb in arm.pose.bones if f"{side}Hand" in pb.name and pb.name[-1] in "1234" and pb.name != f"{P}{side}Hand"}
    ad.action = None
    for t, k in zip(ad.nla_tracks, keep): t.mute = k
    ov = bpy.data.actions.new(f"Override_{pose}_{side}"); ad.action = ov
    for b, q in vals.items():
        pb = arm.pose.bones[b]; pb.rotation_mode = "QUATERNION"; pb.rotation_quaternion = q
        pb.keyframe_insert("rotation_quaternion", frame=f0); pb.keyframe_insert("rotation_quaternion", frame=f1)
    ad.action = None
    tr = ad.nla_tracks.new(); tr.name = "Hand"; st = tr.strips.new(ov.name, f0, ov); st.frame_end = f1; st.blend_type = "REPLACE"

def bone(arm, name): return arm.matrix_world @ arm.pose.bones[P + name].head
def bone_m(arm, name): return arm.matrix_world @ arm.pose.bones[P + name].matrix
def sample(arm, f0, f1, fn):
    out = []
    for f in range(f0, f1 + 1): bpy.context.scene.frame_set(f); out.append(fn())
    return out

def prop(path, name):
    before = set(bpy.data.objects); bpy.ops.import_scene.gltf(filepath=os.path.join(ASSETS, path)); new = [o for o in bpy.data.objects if o not in before]
    root = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(root)
    for o in new:
        if o.parent is None: o.parent = root
    return root, [o for o in new if o.type == "MESH"]
def bounds(meshes):
    pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    return Vector([min(q[i] for q in pts) for i in range(3)]), Vector([max(q[i] for q in pts) for i in range(3)]), pts
def pedestal(top_z, xy, size=0.24):
    bpy.ops.mesh.primitive_cube_add(size=1); c = bpy.context.object; c.scale = (size, size, top_z); c.location = (xy.x, xy.y, top_z / 2)
    m = bpy.data.materials.new("Stand"); m.use_nodes = True; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.55, 0.56, 0.58, 1); c.data.materials.append(m)
def brush(arm, side):
    """Stand-in pollination brush: a 14 cm handle with a soft tip, held along the fingers."""
    bpy.ops.mesh.primitive_cylinder_add(radius=0.004, depth=0.14); h = bpy.context.object
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.009); tip = bpy.context.object; tip.location = (0, 0, 0.075); tip.scale = (1, 1, 1.8)
    for o, col in ((h, (0.85, 0.82, 0.75, 1)), (tip, (0.95, 0.85, 0.40, 1))):
        m = bpy.data.materials.new("Brush"); m.use_nodes = True; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = col; o.data.materials.append(m)
    tip.parent = h
    h.parent = arm; h.parent_type = "BONE"; h.parent_bone = f"{P}{side}HandIndex2"
    h.matrix_parent_inverse = Matrix.Identity(4)
    h.location = (0, 0.04, 0); h.rotation_euler = (math.radians(-90), 0, 0)   # bone space: +Y runs along the finger, past its tip
    return h, tip

def frame_camera(cam, pts, side=(1.0, -1.25, 0.45)):
    lo = Vector([min(q[i] for q in pts) for i in range(3)]); hi = Vector([max(q[i] for q in pts) for i in range(3)])
    c = (lo + hi) / 2; r = max((hi - lo).length / 2, 0.6)
    d = Vector(side).normalized(); cam.location = c + d * r * 4.3   # whole body plus prop in a 16:9 frame
    cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()

def render(sc, f0, f1, name, report):
    tmp = tempfile.mkdtemp(); frames = list(range(f0, f1 + 1, a.step)); keys = []
    for i, f in enumerate(frames):
        sc.frame_set(f); sc.render.filepath = os.path.join(tmp, f"f{i:04d}.png"); bpy.ops.render.render(write_still=True)
    for q in (0.15, 0.4, 0.65, 0.9): keys.append(os.path.join(tmp, f"f{int(q * (len(frames) - 1)):04d}.png"))
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(30 // a.step), "-i", os.path.join(tmp, "f%04d.png"), "-c:v", "libx264",
                    "-pix_fmt", "yuv420p", "-crf", "22", "-movflags", "+faststart", os.path.join(a.out, f"{name}.mp4")], check=True)
    man = os.path.join(tmp, "m.json"); json.dump({"keys": keys, "out": os.path.join(a.out, f"{name}_keys.jpg")}, open(man, "w"))
    subprocess.run(["/usr/bin/env", "-u", "PYTHONPATH", "-u", "PYTHONHOME", "python3", os.path.abspath(__file__), "--compose", man], check=True)
    print(f"SCENE {name}: {report}")

def feet_floor(arm, f0, f1):
    """Lowest point of the deformed character mesh on 8 frames: 0 = standing on the floor, below 0 = sinking."""
    me = next(o for o in bpy.data.objects if o.type == "MESH" and o.find_armature() == arm); lows = []
    for f in [f0 + (f1 - f0) * k // 7 for k in range(8)]:
        bpy.context.scene.frame_set(f); ev = me.evaluated_get(bpy.context.evaluated_depsgraph_get())
        lows.append(min((ev.matrix_world @ v.co).z for v in ev.data.vertices))
    return f"lowest point of the body {min(lows) * 100:+.1f} to {max(lows) * 100:+.1f} cm from the floor"

os.makedirs(a.out, exist_ok=True)
for name in a.scenes.split(","):
    sc, arm, cam = fresh(); f0, f1 = play(arm, name); report = ""
    body = sample(arm, f0, f1, lambda: [bone(arm, b) for b in ("Head", "Hips", "LeftHand", "RightHand", "LeftToeBase", "RightToeBase")])
    pts = [q for fr in body for q in fr]
    if name == "Repair":     # kneel at the rover's nearest wheel; hands work on the hub
        mid = body[len(body) // 5: 4 * len(body) // 5]; P_ = sum(((fr[2] + fr[3]) / 2 for fr in mid), Vector()) / len(mid)
        root, ms = prop("vehicles/VH_Rover/VH_Rover.glb", "Rover"); root.rotation_euler = (0, 0, math.radians(90)); bpy.context.view_layer.update()
        lo, hi, vp = bounds(ms); low = [q for q in vp if q.z < lo.z + 0.45 * (hi.z - lo.z)]
        near = [q for q in low if q.y > hi.y - 0.18 * (hi.y - lo.y)]                    # the side facing the character (+Y)
        cx_ = sorted(q.x for q in near); wx = cx_[len(cx_) // 4]                         # one wheel along that side
        wheel = [q for q in near if abs(q.x - wx) < 0.6]; hub = sum(wheel, Vector()) / len(wheel); face_y = max(q.y for q in wheel)
        root.location = Vector((P_.x - hub.x, P_.y - 0.06 - face_y, 0)); bpy.context.view_layer.update()
        report = f"wheel hub {hub.z * 100:.0f} cm high, hands at {P_.z * 100:.0f} cm (difference {(P_.z - hub.z) * 100:+.0f} cm); " + feet_floor(arm, f0, f1)
        hand_override(arm, "Grip", "Right", f0, f1); hand_override(arm, "Grip", "Left", f0, f1)
        pts += [P_ + Vector((0, -0.5, 0.4))]
    elif name == "Pollinate":   # brush in a pinch; the flower stands where the brush tip dabs
        hand_override(arm, "Pinch", "Right", f0, f1); h, tip = brush(arm, "Right")
        tips = sample(arm, f0, f1, lambda: tip.matrix_world.translation.copy())
        dab = min(tips, key=lambda q: q.y)
        root, ms = prop("plants/PL_Alo_Bloom/PL_Alo_Bloom.glb", "Flower"); lo, hi, vp = bounds(ms)
        bloom = sum((q for q in vp if q.z > hi.z - 0.06), Vector()) / max(1, len([q for q in vp if q.z > hi.z - 0.06]))
        stand = dab.z - (bloom.z - lo.z); pedestal(max(0.05, stand), Vector((dab.x, dab.y - 0.02, 0)))
        root.location = Vector((dab.x - bloom.x, dab.y - 0.02 - bloom.y, max(0.05, stand))); bpy.context.view_layer.update()
        pts += [dab, Vector((dab.x, dab.y, 0))]
        report = f"brush tip reaches the bloom centre within {(dab - (root.location + bloom)).length * 100:.1f} cm at the dab; " + feet_floor(arm, f0, f1)
    elif name == "Inspect":    # seedling tray on the floor where the lowered head looks
        hd = min((fr[0] for fr in body), key=lambda q: q.z)
        root, ms = prop("plants/PL_ZeroSeedlingTray/PL_ZeroSeedlingTray.glb", "Tray"); root.location = Vector((hd.x, hd.y - 0.32, 0))
        pts += [Vector((hd.x, hd.y - 0.6, 0))]
        report = f"head lowest at {hd.z * 100:.0f} cm, tray 32 cm ahead of it; " + feet_floor(arm, f0, f1)
    elif name == "SitDown":    # seat under the pelvis at the end of the clip
        hp = body[-1][1]; root, ms = prop("props/PR_CrewSeat/PR_CrewSeat.glb", "Seat"); lo, hi, vp = bounds(ms)
        top = [q for q in vp if q.z > lo.z + 0.7 * (hi.z - lo.z)]; back_y = sum(q.y for q in top) / len(top)
        if back_y < (lo.y + hi.y) / 2: root.rotation_euler = (0, 0, math.pi); bpy.context.view_layer.update(); lo, hi, vp = bounds(ms)
        cxy = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2 - 0.12 * (hi.y - lo.y), 0))
        dg = bpy.context.evaluated_depsgraph_get(); hit = sc.ray_cast(dg, Vector((cxy.x, cxy.y, hi.z + 1)), Vector((0, 0, -1)))
        seat_z = hit[1].z if hit[0] else lo.z + 0.45 * (hi.z - lo.z)
        root.location = Vector((hp.x - cxy.x, hp.y - cxy.y, 0)); bpy.context.view_layer.update()
        pts += [root.location + Vector((0, 0.5, 1.1))]
        report = f"seat surface {seat_z * 100:.0f} cm, pelvis joint ends at {hp.z * 100:.0f} cm (pelvis joint sits about 8-10 cm above the seat when seated); " + feet_floor(arm, f0, f1)
    elif name == "PickUp":     # the clip reaches to the floor for a small item: a seed packet under the hand, then carried
        low_i = min(range(len(body)), key=lambda i: body[i][3].z); hr = body[low_i][3]
        root, ms = prop("props/PR_SeedPacket/PR_SeedPacket.glb", "Packet"); lo, hi, vp = bounds(ms)
        root.location = Vector((hr.x, hr.y, 0)); bpy.context.view_layer.update()
        con = root.constraints.new("CHILD_OF"); con.target = arm; con.subtarget = f"{P}RightHand"
        sc.frame_set(f0 + low_i); bpy.context.view_layer.update(); con.inverse_matrix = bone_m(arm, "RightHand").inverted()
        con.influence = 0.0; con.keyframe_insert("influence", frame=f0 + low_i - 1); con.influence = 1.0; con.keyframe_insert("influence", frame=f0 + low_i)
        root.location = Vector((hr.x, hr.y, 0))
        hand_override(arm, "Pinch", "Right", f0, f1)
        pts += [Vector((hr.x, hr.y, 0))]
        report = f"wrist lowest at {hr.z * 100:.0f} cm, packet {(hi.z - lo.z) * 100:.0f} cm thick (picked up at frame {low_i}); " + feet_floor(arm, f0, f1)
    elif name == "Type":       # console in front of the hands
        mid = body[len(body) // 5: 4 * len(body) // 5]; k = sum(((fr[2] + fr[3]) / 2 for fr in mid), Vector()) / len(mid)
        root, ms = prop("props/PR_ControlConsole/PR_ControlConsole.glb", "Console"); lo, hi, vp = bounds(ms)
        root.location = Vector((k.x, k.y - 0.08 - hi.y, 0)); bpy.context.view_layer.update()
        dg = bpy.context.evaluated_depsgraph_get(); hit = sc.ray_cast(dg, Vector((k.x, k.y - 0.12, 3)), Vector((0, 0, -1)))
        report = f"hands at {k.z * 100:.0f} cm, console surface under them at {hit[1].z * 100 if hit[0] else -1:.0f} cm; " + feet_floor(arm, f0, f1)
    elif name == "Wave":       # open palm on the waving hand
        side = "Right" if max(fr[3].z for fr in body) > max(fr[2].z for fr in body) else "Left"
        hand_override(arm, "Open", side, f0, f1); report = f"{side.lower()} hand waves with an open palm; " + feet_floor(arm, f0, f1)
    else:
        report = feet_floor(arm, f0, f1)
    view = {"Repair": (1.3, 0.75, 0.45), "Type": (1.3, 0.75, 0.45), "Walk_loop": (1.0, -0.15, 0.2)}.get(name, (1.0, -1.3, 0.35))   # big props in front: look from the side and behind
    frame_camera(cam, pts, view)
    render(sc, f0, f1, name, report)
