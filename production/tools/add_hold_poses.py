"""Add the upper-body hold poses the game layers over locomotion on the arm bones (game/scripts/player):
CarryBox_pose (both hands hold a small case in front of the belly) and HoldRight_pose (right forearm raised, the
right hand grips a hand-light-sized handle, 6.6 cm across). Every existing clip is kept (NLA tracks).

  blender -b -P add_hold_poses.py -- <in.glb> <out.glb> [--debug out.png]

The arms are placed with an analytic two-bone IK (wrist targets scaled to the character's height, elbows out and
back), each palm is turned to face the held object (palm direction from the finger roots), and the fingers take the
curl of the character's own HandRelaxed (case) or HandGrip (mug) clip.
"""
import argparse, os, sys
import bpy
from mathutils import Matrix, Vector

a = argparse.ArgumentParser(); a.add_argument("src"); a.add_argument("dst"); a.add_argument("--debug")
a = a.parse_args(sys.argv[sys.argv.index("--") + 1:])
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE"); ad = arm.animation_data or arm.animation_data_create()
for t in ad.nla_tracks: t.mute = True
ad.action = None
B = {b.name.split(":")[-1]: b.name for b in arm.data.bones}
FINGERS = ("Thumb", "Index", "Middle", "Ring", "Pinky")
height = max((arm.matrix_world @ b.tail_local).z for b in arm.data.bones) - min((arm.matrix_world @ b.head_local).z for b in arm.data.bones)
k = height / 1.74
hips = arm.data.bones[B["Hips"]].head_local

def finger_pose(clip):
    """Finger rotations of a hand-pose clip at its first frame."""
    act = bpy.data.actions.get(clip)
    if act is None: return {}
    ad.action = act; sc.frame_set(int(act.frame_range[0])); bpy.context.view_layer.update()
    got = {pb.name: pb.rotation_quaternion.copy() for pb in arm.pose.bones if any(f in pb.name for f in FINGERS)}
    ad.action = None; return got

def frame(d, n):
    d = d.normalized(); n = (n - d * n.dot(d)).normalized()
    return Matrix((d, n, d.cross(n))).transposed()           # columns: direction, palm normal, third axis

def palm_normal(side):
    """Palm direction (out of the palm) of a hand in the rest pose, from its bone and finger roots."""
    h = arm.data.bones[B[f"{side}Hand"]]; d = (h.tail_local - h.head_local).normalized()
    across = arm.data.bones[B[f"{side}HandIndex1"]].head_local - arm.data.bones[B[f"{side}HandPinky1"]].head_local
    return d.cross(across).normalized() if side == "Left" else across.cross(d).normalized()

def set_rot(name, rot):
    """Pose a bone so its armature-space rotation is rot (its head stays where the parent puts it)."""
    pb = arm.pose.bones[name]; bpy.context.view_layer.update()
    pb.matrix = Matrix.Translation(pb.matrix.translation) @ rot.to_4x4(); bpy.context.view_layer.update()

def place_arm(side, wrist, pole, hand_dir, palm_dir):
    up, fore, hand = (arm.pose.bones[B[f"{side}{n}"]] for n in ("Arm", "ForeArm", "Hand"))
    bpy.context.view_layer.update()
    s = up.matrix.translation; l1 = up.bone.length; l2 = fore.bone.length
    d = min((wrist - s).length, (l1 + l2) * 0.999); axis = (wrist - s).normalized()
    along = (l1 * l1 - l2 * l2 + d * d) / (2 * d); off = max(l1 * l1 - along * along, 0.0) ** 0.5
    p = pole - s; p = (p - axis * p.dot(axis)).normalized(); elbow = s + axis * along + p * off
    for pb, target in ((up, elbow), (fore, s + axis * d)):  # aim each bone with the least twist from where it points now
        bpy.context.view_layer.update(); m = pb.matrix.to_3x3(); cur = m.col[1].normalized()
        set_rot(pb.name, cur.rotation_difference((target - pb.matrix.translation).normalized()).to_matrix() @ m)
    rest = hand.bone.matrix_local.to_3x3()
    turn = frame(hand_dir, palm_dir) @ frame(rest.col[1], palm_normal(side)).transposed()
    set_rot(hand.name, turn @ rest)

def make_pose(name, sides, fingers):
    for pb in arm.pose.bones: pb.matrix_basis = Matrix.Identity(4)
    side_x = {"Left": 1.0, "Right": -1.0}                    # the character faces -Y, its left is +X
    for side, (wrist, pole, hand_dir, palm_dir) in sides.items():
        place_arm(side, wrist, pole, hand_dir, palm_dir)
        for bn, q in fingers.items():
            if f"{side}Hand" in bn: arm.pose.bones[bn].rotation_quaternion = q
    act = bpy.data.actions.new(name); ad.action = act
    keyed = [pb for pb in arm.pose.bones if any(f"{s}{n}" in pb.name for s in sides for n in ("Arm", "ForeArm", "Hand"))]
    for f in (1, 31):                                         # a still, one-second loop
        for pb in keyed:
            pb.rotation_mode = "QUATERNION"; pb.keyframe_insert("rotation_quaternion", frame=f)
    t = ad.nla_tracks.new(); t.name = name; t.strips.new(name, 1, act); t.mute = True; ad.action = None
    for pb in arm.pose.bones: pb.matrix_basis = Matrix.Identity(4)
    print(f"POSE {name}: {len(keyed)} bones keyed")

def curl_radius(fingers):
    """Radius of the circle through the right middle finger's three joints, fingers posed on the rest hand."""
    for pb in arm.pose.bones: pb.matrix_basis = Matrix.Identity(4)
    for bn, q in fingers.items():
        if "RightHand" in bn: arm.pose.bones[bn].rotation_quaternion = q
    bpy.context.view_layer.update()
    p, q, r = (arm.pose.bones[B[f"RightHandMiddle{i}"]].head for i in (1, 2, 3))
    pq, pr = q - p, r - p; n = pq.cross(pr)
    if n.length < 1e-9: return 1.0
    return ((n.cross(pq) * pr.length_squared + pr.cross(n) * pq.length_squared) / (2 * n.length_squared)).length

relaxed, grip = finger_pose("HandRelaxed"), finger_pose("HandGrip")
# HandGrip is a fist (a ~3.5 cm handle). Open it toward HandRelaxed until the curl wraps the hand light's barrel
# (radius 3.3 cm) with a finger's half thickness to spare, so the fingers sit on the barrel, not inside it.
HANDLE_RADIUS = 0.033 + 0.009
blend = lambda t: {b: relaxed.get(b, q).slerp(q, t) for b, q in grip.items()}
lo, hi = 0.0, 1.0
for _ in range(24):
    t = (lo + hi) / 2
    lo, hi = (t, hi) if curl_radius(blend(t)) > HANDLE_RADIUS else (lo, t)
grip = blend(lo)
print(f"GRIP close={lo:.3f} curl radius={curl_radius(grip):.4f} m (fist {curl_radius(finger_pose('HandGrip')):.4f})")
z = hips.z
make_pose("CarryBox_pose", {
    "Left": (Vector((0.17 * k, -0.24 * k, z + 0.12 * k)), Vector((0.45 * k, 0.04 * k, z + 0.02 * k)), Vector((-0.2, -1, -0.35)), Vector((-1, 0, 0))),
    "Right": (Vector((-0.17 * k, -0.24 * k, z + 0.12 * k)), Vector((-0.45 * k, 0.04 * k, z + 0.02 * k)), Vector((0.2, -1, -0.35)), Vector((1, 0, 0))),
}, relaxed)
make_pose("HoldRight_pose", {
    "Right": (Vector((-0.16 * k, -0.30 * k, z + 0.22 * k)), Vector((-0.32 * k, 0.08 * k, z - 0.05 * k)), Vector((0.15, -1, 0.1)), Vector((1, 0, 0.2))),
}, grip)

if a.debug:   # both poses, front and side, with a proxy case between the palms
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import blender_look
    blender_look.setup(sc, centre=Vector((0, 0, height * 0.6)), scale=height / 1.74)
    cam = bpy.data.objects.new("C", bpy.data.cameras.new("C")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 50
    sc.render.resolution_x = sc.render.resolution_y = 520; files = []
    palm = lambda side: (lambda h: (h.head + h.tail) / 2)(arm.pose.bones[B[f"{side}Hand"]])
    for name in ("CarryBox_pose", "HoldRight_pose"):
        for pb in arm.pose.bones: pb.matrix_basis = Matrix.Identity(4)   # unkeyed bones would keep the previous pose
        ad.action = bpy.data.actions[name]; sc.frame_set(1); bpy.context.view_layer.update()
        proxy = None
        if name == "CarryBox_pose":
            l, r = arm.matrix_world @ palm("Left"), arm.matrix_world @ palm("Right")
            bpy.ops.mesh.primitive_cube_add(location=(l + r) / 2); proxy = bpy.context.object
            proxy.scale = ((l - r).length / 2 - 0.02, 0.11, 0.09); print("CASE between palms", round((l - r).length, 3), "m")
        for view, d in (("front", Vector((0.35, -1, 0.15))), ("side", Vector((-1, -0.25, 0.15))), ("back", Vector((0.8, 1, 0.2)))):
            c = Vector((0, -0.1 * k, hips.z + 0.15 * k)); cam.location = c + d.normalized() * 1.7 * k
            cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
            f = a.debug.replace(".png", f"_{name}_{view}.png"); sc.render.filepath = f; bpy.ops.render.render(write_still=True); files.append(f)
        if proxy: bpy.data.objects.remove(proxy)
    print("DEBUG", files); sys.exit()
bpy.ops.export_scene.gltf(filepath=a.dst, export_format="GLB", export_yup=True, export_skins=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS")
print("HOLD POSES DONE", len(ad.nla_tracks), "clips ->", a.dst)
