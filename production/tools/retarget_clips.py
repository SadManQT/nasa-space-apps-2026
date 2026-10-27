"""Retarget Meshy animation clips onto a Mixamo-skeleton rig of the same character, add finger poses.

  blender -b -P retarget_clips.py -- <mixamo_rig.glb> <height_m> <out.glb> <clips.glb> [<clips.glb> ...] [Name=<clip.glb> ...]

The target is the character rigged by Tripo with the Mixamo spec (65 bones, three joints per finger);
the clips come from Meshy's rig of the same mesh (24 bones, no fingers). The two rigs rest the upper body a few
degrees apart, so each upper-body target bone is first turned onto its source bone's rest direction, then gets the
source bone's world-space rotation change from rest; the hips
also get the root motion. Fingers get each clip's hand pose (soft by default, open for gestures, a grip or pinch while
holding), and one-frame hand poses
(HandRelaxed, HandOpen, HandGrip, HandFist, HandPoint, HandPinch) are added for Godot to blend over the hands when holding
things. Name=file names a one-clip file's action (Meshy text-to-motion clips are all "retarget_clip").
"""
import math, os, re, sys
import bpy
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, os.path.dirname(__file__))
from clip_names import game_name

src, height, dst, *clip_args = sys.argv[sys.argv.index("--") + 1:]
height = float(height)
P = "mixamorig:"
BONE_MAP = {  # Meshy -> Mixamo (Meshy numbers its spine from the top down)
    "Hips": "Hips", "Spine02": "Spine", "Spine01": "Spine1", "Spine": "Spine2", "neck": "Neck", "Head": "Head",
    **{f"{s}{b}": f"{s}{b}" for s in ("Left", "Right") for b in ("Shoulder", "Arm", "ForeArm", "Hand", "UpLeg", "Leg", "Foot", "ToeBase")},
}

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene

def import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    shapes = {pb.custom_shape for o in new if o.type == "ARMATURE" for pb in o.pose.bones} - {None}
    keep = [o for o in new if o not in shapes]
    for o in shapes:  # glTF importer's bone-display icosphere
        bpy.data.objects.remove(o)
    return keep

# target: scale to real height, apply, clear its placeholder animation
objs = import_glb(src)
tgt = next(o for o in objs if o.type == "ARMATURE")
tmesh = [o for o in objs if o.type == "MESH"]
pts = [o.matrix_world @ v.co for o in tmesh for v in o.data.vertices]
k = height / (max(p.z for p in pts) - min(p.z for p in pts))
tgt.scale = [s * k for s in tgt.scale]
bpy.ops.object.select_all(action="DESELECT")
for o in [tgt] + tmesh: o.select_set(True)
bpy.context.view_layer.objects.active = tgt
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
tgt.animation_data_create()
for t in list(tgt.animation_data.nla_tracks): tgt.animation_data.nla_tracks.remove(t)
tgt.animation_data.action = None
for a in list(bpy.data.actions): bpy.data.actions.remove(a)
# soles: points over each whole boot (foot and toe bones) and around each knee, carried by those bones, so
# floor contact is measured on the actual boot, not on the joints
SOLE = []
_mo = max(tmesh, key=lambda o: len(o.data.vertices))
for _side in ("Left", "Right"):
    for _b in (P + _side + "Foot", P + _side + "ToeBase"):
        _gi = _mo.vertex_groups[_b].index
        _pts = [_mo.matrix_world @ v.co for v in _mo.data.vertices if any(g.group == _gi and g.weight > 0.5 for g in v.groups)]
        _rest = (tgt.matrix_world @ tgt.data.bones[_b].matrix_local).inverted()
        SOLE += [(_b, _rest @ q) for q in _pts[::4]]   # the whole boot: toe tips become lowest when the foot rolls
    # knees too: when kneeling, the knee is the lowest point and sits on the floor instead of sinking
    _b = P + _side + "Leg"; _gi = _mo.vertex_groups[_b].index; _k = tgt.matrix_world @ tgt.data.bones[_b].head_local
    _pts = [_mo.matrix_world @ v.co for v in _mo.data.vertices if any(g.group == _gi and g.weight > 0.5 for g in v.groups)]
    _rest = (tgt.matrix_world @ tgt.data.bones[_b].matrix_local).inverted()
    SOLE += [(_b, _rest @ q) for q in _pts if (q - _k).length < 0.07][::4]
for o in tmesh: o.hide_viewport = True  # skip mesh evaluation while baking
TW = tgt.matrix_world
trest = {b.name: TW @ b.matrix_local for b in tgt.data.bones}

# hand poses: each finger joint curls about its true hinge (the phalanx direction crossed with the palm normal, so
# the curl stays in the finger's plane whatever the bone roll), with a small fan or close of the fingers at the
# knuckles; the thumb is solved so its tip lands where a real thumb goes, without passing through the fingers
FINGERS = ("Index", "Middle", "Ring", "Pinky")
POSES = {  # per finger (index -> pinky): (knuckle, middle joint, end joint) curl in degrees, knuckle spread in degrees
    "Relaxed": (((12, 18, 10), -3), ((16, 24, 12), 0), ((20, 28, 14), 3), ((24, 30, 16), 7)),
    "Soft":    (((4, 7, 3), -3), ((6, 9, 4), 0), ((8, 11, 5), 3), ((10, 13, 6), 6)),   # default in clips: a calm, nearly straight hand
    "Open":    (((2, 3, 2), -6), ((2, 3, 2), 0), ((2, 3, 2), 6), ((3, 4, 2), 12)),
    "Grip":    (((50, 64, 40), -1), ((54, 68, 42), 0), ((58, 70, 44), 1), ((62, 72, 46), 3)),
    "Fist":    (((92, 112, 88), 2), ((95, 114, 90), 0), ((98, 114, 90), -2), ((100, 112, 88), -5)),   # short glove fingers: pack the tips into the palm
    "Point":   (((2, 4, 2), -1), ((95, 114, 90), 0), ((98, 114, 90), -2), ((100, 112, 88), -5)),
    "Pinch":   (((40, 52, 30), -2), ((30, 44, 26), 0), ((34, 48, 28), 3), ((40, 52, 30), 7)),
}
B = {b.name: b for b in tgt.data.bones}
REST = {n: b.matrix_local.copy() for n, b in B.items()}  # armature space
def rel(b): return REST[B[b].parent.name].inverted() @ REST[b]
def fk(chain, basis):
    """Armature-space matrices of a finger chain (hand at rest), given {bone: basis matrix}."""
    out, m = {}, REST[B[chain[0]].parent.name]
    for b in chain:
        m = m @ rel(b) @ basis.get(b, Matrix.Identity(4)); out[b] = m
    return out
def chain(side, f): return [f"{P}{side}Hand{f}{i}" for i in (1, 2, 3, 4)]
def T(b): return REST[b].translation
def palm_normal(side):
    h, i1, p1, m1 = T(f"{P}{side}Hand"), T(f"{P}{side}HandIndex1"), T(f"{P}{side}HandPinky1"), T(f"{P}{side}HandMiddle1")
    n = (i1 - p1).cross(m1 - h).normalized()
    return -n if side == "Left" else n
PALM = {s: palm_normal(s) for s in ("Left", "Right")}
HINGE = {}  # bone -> (local curl axis, local spread axis); positive curl moves the child toward the palm
for side in ("Left", "Right"):
    for f in FINGERS + ("Thumb",):
        c = chain(side, f)
        for k in range(3):
            d = (T(c[k + 1]) - T(c[k])).normalized(); inv = REST[c[k]].to_3x3().inverted()
            HINGE[c[k]] = ((inv @ d.cross(PALM[side])).normalized(), (inv @ PALM[side]).normalized())
def joint(b, curl, spread=0.0):
    ax, sp = HINGE[b]
    return Matrix.Rotation(math.radians(spread), 4, sp) @ Matrix.Rotation(math.radians(curl), 4, ax)
def finger_basis(side, pose):
    out = {}
    for f, (degs, spread) in zip(FINGERS, POSES[pose]):
        c = chain(side, f)
        sgn = -1 if side == "Left" else 1   # spread is mirrored between hands
        for k, d in enumerate(degs): out[c[k]] = joint(c[k], d, sgn * spread if k == 0 else 0.0)
    return out
def seg_dist(q, a, b):
    d = b - a; t = max(0.0, min(1.0, (q - a).dot(d) / max(d.length_squared, 1e-12))); return (a + d * t - q).length
def solve_thumb(side, target, fingers, seeds=None):
    """Search thumb base rotation (3 axes) and the two thumb bends so the tip reaches target, within joint limits,
    penalising any thumb joint that ends up inside a finger. Several starts; keeps the best."""
    c = chain(side, "Thumb"); r = finger_r(side)
    segs = [(fm[cc[k]].translation, fm[cc[k + 1]].translation) for f, (cc, fm) in fingers.items() for k in range(3)]
    def basis(p):
        m1 = Matrix.Rotation(math.radians(p[0]), 4, "X") @ Matrix.Rotation(math.radians(p[1]), 4, "Y") @ Matrix.Rotation(math.radians(p[2]), 4, "Z")
        return {c[0]: m1, c[1]: joint(c[1], p[3]), c[2]: joint(c[2], p[4])}
    def cost(p):
        if not (-5 <= p[3] <= 75 and -5 <= p[4] <= 90) or max(abs(v) for v in p[:3]) > 110: return 1e9
        m = fk(c, basis(p)); tip = m[c[3]].translation
        pen = sum(max(0.0, 1.4 * r - seg_dist(q, a, b)) for q in (m[c[2]].translation, m[c[3]].translation, (m[c[2]].translation + tip) / 2) for a, b in segs)
        return (tip - target).length + 2 * pen + 2e-7 * sum(v * v for v in p)   # 2e-7: about 1.6 mm per 90 degrees
    best = None
    import random; rng = random.Random(7)   # seed the descent from the best of a coarse random search
    pool = [[rng.uniform(-100, 100) for _ in range(3)] + [rng.uniform(0, 75), rng.uniform(0, 90)] for _ in range(3000)]
    starts = seeds if seeds else sorted(pool, key=cost)[:8] + [[0, 0, 0, 30, 40]]
    for start in starts:
        p, step, v = start[:], 16.0, cost(start)
        while step >= 0.5:
            moved = False
            for i in range(5):
                for d in (step, -step):
                    q = p[:]; q[i] += d; w = cost(q)
                    if w < v: v, p, moved = w, q, True
            if not moved: step /= 2
        if best is None or v < best[0]: best = (v, p)
    m = fk(c, basis(best[1])); err = (m[c[3]].translation - target).length
    if seeds and err > 0.005: return solve_thumb(side, target, fingers)   # mirrored start missed: full search
    return basis(best[1]), err, best[1]
def finger_r(side):
    c = chain(side, "Index"); return 0.35 * (T(c[1]) - T(c[0])).length   # about a third of the first phalanx
def hand_pose(name):
    out, right_p = {}, None
    for side in ("Right", "Left"):   # the left thumb starts from the mirrored right solution, so both hands match
        fb = finger_basis(side, name)
        fingers = {f: (chain(side, f), fk(chain(side, f), fb)) for f in FINGERS}
        pn = PALM[side]; r = finger_r(side)
        toward_thumb = (T(f"{P}{side}HandIndex1") - T(f"{P}{side}HandMiddle1")).normalized()
        def at(f, k, t=0.5):   # point along finger f's phalanx k (0 proximal, 1 middle, 2 distal)
            cc, fm = fingers[f]; return fm[cc[k]].translation.lerp(fm[cc[k + 1]].translation, t)
        if name in ("Relaxed", "Open"):   # resting beside the base of the index, a little in front of it (short thumbs reach it too)
            target = at("Index", 0, 0.7) + pn * r * 1.2 + toward_thumb * r * 2.0
        elif name == "Grip":              # wrapped round the handle to meet the index
            target = at("Index", 1, 0.8) + toward_thumb * r * 2.0
        elif name == "Pinch":             # pad to pad with the index tip
            target = at("Index", 2, 0.9) + toward_thumb * r * 1.9
        elif name == "Point":             # the index is out: the thumb rests on the curled middle finger
            target = at("Middle", 1) + pn * r * 2.0
        else:                             # fist: across the outside of the index and middle middle phalanges
            target = at("Index", 1).lerp(at("Middle", 1), 0.35) + pn * r * 2.0
        seeds = None if right_p is None else [[right_p[0], -right_p[1], -right_p[2], right_p[3], right_p[4]],
                                               [-right_p[0], right_p[1], -right_p[2], right_p[3], right_p[4]],
                                               [-right_p[0], -right_p[1], right_p[2], right_p[3], right_p[4]]]
        tb, err, right_p = solve_thumb(side, target, fingers, seeds)
        tc = chain(side, "Thumb"); reach = sum((T(tc[k + 1]) - T(tc[k])).length for k in range(3))
        print(f"HAND {name} {side}: thumb tip error {err * 100:.1f} cm (target {(target - T(tc[0])).length * 100:.1f} cm from the thumb base, reach {reach * 100:.1f} cm)")
        fb.update(tb)
        out.update({b: m.to_quaternion() for b, m in fb.items()})
    return out

def write_action(name, frames):
    """frames: list of {bone: (quat, loc or None)}; keyed on frames 0..n-1 as quaternion (+ location)."""
    act = bpy.data.actions.new(name)
    tgt.animation_data.action = act
    bones = sorted({b for fr in frames for b in fr})
    for b in bones:
        pb = tgt.pose.bones[b]; pb.rotation_mode = "QUATERNION"
        has_loc = any(fr[b][1] is not None for fr in frames if b in fr)
        for f, fr in enumerate(frames):
            q, loc = fr.get(b, (Quaternion(), None))
            pb.rotation_quaternion = q; pb.keyframe_insert("rotation_quaternion", frame=f)
            if has_loc:
                pb.location = loc if loc is not None else Vector(); pb.keyframe_insert("location", frame=f)
    act.use_fake_user = True
    tr = tgt.animation_data.nla_tracks.new(); tr.name = name; tr.strips.new(name, 0, act); tr.mute = True
    tgt.animation_data.action = None

# standing clips hold the arms a little out with locked elbows (the library idles were made on an A-pose); settle
# them: the whole arm chain rotates in toward the body, then the elbow softens (degrees: arm in, elbow bend)
SETTLE = {"LookAround_loop": (4, 6), "Talk_loop": (3, 5)}
# standing idles go further: each frame an IK puts each wrist where a relaxed arm hangs: just clear of the
# character's own hips and thighs (measured on the mesh), elbows soft and pointing back, hands beside the thighs, palms
# turned to them. It keeps 20 % of the clip's own arm motion so it still breathes. The library idles were recorded
# on a wide A-pose; this is the game pose.
HANG = {"Idle_loop", "IdleAlt_loop", "Breathe_loop", "Listen_loop"}
HANG_KEEP = 0.2
HANG_REACH = 0.982                     # of the arm's length: about 20 degrees of elbow bend
SIDE_X, HANG_PALM = {}, {}
_arm_groups = {g.index for g in _mo.vertex_groups if any(t in g.name for t in ("Arm", "Hand"))}
for _side, _sg in (("Left", 1), ("Right", -1)):
    _sh = trest[P + _side + "Arm"].translation
    _len = sum((trest[P + _side + b].translation - trest[P + _side + a].translation).length for a, b in (("Arm", "ForeArm"), ("ForeArm", "Hand")))
    _z = _sh.z - HANG_REACH * _len    # where a hanging wrist is: the body's side there (pouches and apron included)
    SIDE_X[_side] = max(_sg * q.x for q in (_mo.matrix_world @ v.co for v in _mo.data.vertices
                        if sum(g.weight for g in v.groups if g.group in _arm_groups) < 0.3)
                        if abs(q.z - _z) < 0.08 * k and _sg * q.x > 0) + 0.04 * k   # skin clearance plus half a hand
    _h = tgt.data.bones[P + _side + "Hand"]; _d = TW.to_3x3() @ (_h.tail_local - _h.head_local)
    _across = TW @ tgt.data.bones[P + _side + "HandIndex1"].head_local - TW @ tgt.data.bones[P + _side + "HandPinky1"].head_local
    _palm = (_d.cross(_across) if _side == "Left" else _across.cross(_d)).normalized()   # out of the palm, at rest
    HANG_PALM[_side] = trest[P + _side + "Hand"].to_quaternion().inverted() @ _palm   # in the hand's rest frame
print("HANG wrists clear the body at x =", {s_: round(v, 3) for s_, v in SIDE_X.items()})
# hand roll: the library motions assume the rest hands palm-down. A rig whose sculpt holds the hands rolled far off that
# (Amara's are ~90 degrees round) turns its palms forward or back in every clip, so a rest roll beyond 40 degrees is
# brought back to 40: the hand and forearm take the whole correction, the upper arm 35 % of it, so no joint twists hard.
ROLL_LIMIT = math.radians(40)
ROLL = {}
for _side in ("Left", "Right"):
    _h = tgt.data.bones[P + _side + "Hand"]; _d = (TW.to_3x3() @ (_h.tail_local - _h.head_local)).normalized()
    _across = TW @ tgt.data.bones[P + _side + "HandIndex1"].head_local - TW @ tgt.data.bones[P + _side + "HandPinky1"].head_local
    _palm = (_d.cross(_across) if _side == "Left" else _across.cross(_d)).normalized()
    _canon = (Vector((0, 0, -1)) - _d * -_d.z).normalized()
    _err = math.atan2(_d.dot(_canon.cross(_palm)), _canon.dot(_palm))
    _fix = min(max(_err, -ROLL_LIMIT), ROLL_LIMIT) - _err
    if abs(_fix) < 1e-4: continue
    for _b, _w in (("Arm", 0.35), ("ForeArm", 1.0), ("Hand", 1.0)):
        _bone = tgt.data.bones[P + _side + _b]; _axis = (TW.to_3x3() @ (_bone.tail_local - _bone.head_local)).normalized()
        ROLL[P + _side + _b] = Quaternion(_axis, _fix * _w)
    print(f"ROLL {_side} hand: rest palm {math.degrees(_err):+.0f} degrees off palm-down, corrected by {math.degrees(_fix):+.0f}")
def hang_arm(side, s_pos, hips_w, want):
    """Rewrite want[] for one arm so it hangs naturally from the shoulder at s_pos (world)."""
    sg = 1 if side == "Left" else -1                 # facing -Y: the left arm is on +X
    up, fore, hand = (P + side + n for n in ("Arm", "ForeArm", "Hand"))
    l1 = (trest[fore].translation - trest[up].translation).length; l2 = (trest[hand].translation - trest[fore].translation).length
    hb = hips_w.to_quaternion() @ trest[P + "Hips"].to_quaternion().inverted()   # the body's turn and lean since rest
    reach = HANG_REACH * (l1 + l2)
    sh = hb.inverted() @ (s_pos - hips_w.translation)                            # the shoulder, in the hips' rest frame
    out = math.asin(min(max((SIDE_X[side] - sg * sh.x) / reach, -1.0), 1.0))     # out just far enough to clear the hips
    out = min(max(out, math.radians(6)), math.radians(20))
    down = hb @ Vector((sg * math.sin(out), -math.sin(math.radians(3)), -math.cos(out))).normalized()
    src_elbow = s_pos + (want[up][0] @ Vector((0, 1, 0))) * l1
    src_wrist = src_elbow + (want[fore][0] @ Vector((0, 1, 0))) * l2
    wrist = src_wrist.lerp(s_pos + down * reach, 1 - HANG_KEEP)
    d = min((wrist - s_pos).length, (l1 + l2) * 0.999); axis = (wrist - s_pos).normalized()
    along = (l1 * l1 - l2 * l2 + d * d) / (2 * d); off = max(l1 * l1 - along * along, 0.0) ** 0.5
    pole = hb @ Vector((sg * 0.12, 0.4, 0.0))        # elbows point back, a little out
    pole = (pole - axis * pole.dot(axis)).normalized(); elbow = s_pos + axis * along + pole * off
    for b, a, z in ((up, s_pos, elbow), (fore, elbow, s_pos + axis * d)):
        q = want[b][0]; cur = q @ Vector((0, 1, 0))
        want[b] = (cur.rotation_difference((z - a).normalized()) @ q, want[b][1])
    rel = trest[fore].to_quaternion().inverted() @ trest[hand].to_quaternion()
    # turn the forearm about its own length so the palm faces the thigh, a little back, thumb forward
    fa = (want[fore][0] @ Vector((0, 1, 0))).normalized()
    palm = want[fore][0] @ rel @ HANG_PALM[side]; goal = hb @ Vector((-sg, 0.3, 0.0)).normalized()
    p1, g1 = palm - fa * palm.dot(fa), goal - fa * goal.dot(fa)
    if p1.length > 1e-4 and g1.length > 1e-4:
        tw = Quaternion(fa, math.atan2(fa.dot(p1.cross(g1)), p1.dot(g1)))   # about the forearm itself, even when opposite
        HANG_TWIST[0] = max(HANG_TWIST[0], math.degrees(tw.angle))
        want[fore] = (tw @ want[fore][0], want[fore][1])
    want[hand] = (want[fore][0] @ rel, want[hand][1])   # a straight wrist, as at rest
HANG_TWIST = [0.0]
# clavicles: the library clips disagree wildly here (the idles shrug 16-29 degrees above the mocap rig's rest, the
# walks drop 12-19 below it), so the clavicle is not copied. It follows the upper arm the way a shoulder blade does:
# it keeps its sculpted rest while the arm hangs, sinking up to 4 degrees as the arm comes in to the side, rises only
# once the arm is lifted past 60 degrees (a third of each degree beyond, up to 30), and swings a little forward or
# back with the arm (an eighth of its forward angle).
REST_DOWN = {s_: (trest[P + s_ + "ForeArm"].translation - trest[P + s_ + "Arm"].translation).angle(Vector((0, 0, -1))) for s_ in ("Left", "Right")}
# standing clips stand straight: the library idles sway back (the upper body 8-15 degrees behind the hips, the pelvis
# pushed forward, the head craned forward to make up for it), which reads as a hip-forward pose. Each standing clip's
# spine is tilted by one constant so its average lean (hips to neck) is 2 degrees forward; the sway and breathing stay,
# and the neck and head keep their own orientation.
POSTURE = {"Idle_loop", "IdleAlt_loop", "Listen_loop", "LookAround_loop", "Talk_loop"}
POSTURE_LEAN = math.radians(2)
SPINE = [P + b for b in ("Spine", "Spine1", "Spine2")]
_seg = [(trest[b2].translation - trest[b1].translation).length for b1, b2 in zip(SPINE, SPINE[1:] + [P + "Neck"])]
# ...and on straight legs: the idles bend the knees 13-26 degrees (a slight crouch); standing clips keep 45 % of each
# knee's bend, taken half from the thigh and half from the shin so the foot stays under the hip (the floor pass then
# lifts the body onto the longer legs).
KNEE_KEEP = 0.45
def straighten_knees(want):
    for side in ("Left", "Right"):
        up, low = P + side + "UpLeg", P + side + "Leg"
        t, sh = want[up][0] @ Vector((0, 1, 0)), want[low][0] @ Vector((0, 1, 0)); hinge = t.cross(sh)
        if hinge.length < 1e-6: continue
        half = t.angle(sh) * (1 - KNEE_KEEP) / 2; hinge.normalize()
        want[up] = (Quaternion(hinge, half) @ want[up][0], want[up][1])
        want[low] = (Quaternion(hinge, -half) @ want[low][0], want[low][1])
def facing(want):
    """The body's level forward direction and the axis that tips it forward, from the hips' turn since rest."""
    hb = want[P + "Hips"][0] @ trest[P + "Hips"].to_quaternion().inverted()
    fwd = hb @ Vector((0, -1, 0)); fwd.z = 0; fwd.normalize()
    return fwd, Vector((0, 0, 1)).cross(fwd)
def spine_lean(want):
    """Lean of the spine (first spine joint to the neck) in the body's own forward plane."""
    v = sum((want[b][0] @ Vector((0, l, 0)) for b, l in zip(SPINE, _seg)), Vector()); fwd, _ = facing(want)
    return math.atan2(v.dot(fwd), v.z)
def clavicle(side, chest_w, want):
    sg = 1 if side == "Left" else -1
    cd = chest_w.to_quaternion() @ trest[P + "Spine2"].to_quaternion().inverted()   # the chest's turn since rest
    a = (cd.inverted() @ (want[P + side + "Arm"][0] @ Vector((0, 1, 0)))).normalized()
    lift = a.angle(Vector((0, 0, -1)))
    back = max(a.y, 0.0) / max(math.hypot(a.x, a.y), 1e-6)            # an arm swung back does not lift the shoulder
    rise = min(max(lift - math.radians(60), 0.0) / 3, math.radians(30)) * (1 - back) - math.radians(4) * min(max(1 - lift / REST_DOWN[side], 0.0), 1.0)
    swing = math.asin(min(max(-a.y, -1.0), 1.0)) / 8
    return cd @ Quaternion(Vector((0, 0, -sg)), swing) @ Quaternion(Vector((0, -sg, 0)), rise) @ trest[P + side + "Shoulder"].to_quaternion()
def settle(want, arm_in, elbow):
    for side, sg in (("Left", 1), ("Right", -1)):   # facing -Y: the left arm is on +X
        ry = Quaternion((0, 1, 0), math.radians(sg * arm_in))
        for b in ("Arm", "ForeArm", "Hand"):
            q, loc = want[P + side + b]; want[P + side + b] = (ry @ q, loc)
        d = want[P + side + "ForeArm"][0] @ Vector((0, 1, 0)); k = d.cross(Vector((0, -1, 0)))
        if k.length > 1e-6:                          # flex the forearm (and hand) toward the front
            re = Quaternion(k.normalized(), math.radians(elbow))
            for b in ("ForeArm", "Hand"):
                q, loc = want[P + side + b]; want[P + side + b] = (re @ q, loc)
# gaits: the library walks and runs flap the wrists (up to 47 degrees in one frame of the 20-frame run), so the hands
# follow the forearms with a nearly straight wrist (30 % of the clip's own wrist motion kept), and one cyclic [1 2 1]
# smoothing pass over each arm joint takes the frame-to-frame jerk out of the swing (the swing itself loses ~2 %).
GAITS = {"Walk_loop", "WalkBasic_loop", "Run_loop", "RunBasic_loop", "Sprint_loop"}
ARM_CHAIN = [P + sd + b for sd in ("Left", "Right") for b in ("Shoulder", "Arm", "ForeArm", "Hand")]
def firm_wrists(want):
    for side in ("Left", "Right"):
        fore, hand = P + side + "ForeArm", P + side + "Hand"
        straight = want[fore][0] @ trest[fore].to_quaternion().inverted() @ trest[hand].to_quaternion()
        want[hand] = (straight.slerp(want[hand][0], 0.3), want[hand][1])
def smooth_cycle(frames):
    for b in ARM_CHAIN:
        qs = [fr[b][0].copy() for fr in frames]; n = len(qs)
        ends = math.degrees(qs[0].rotation_difference(qs[-1]).angle)
        closed = n > 2 and min(ends, 360 - ends) < 1.0
        if closed: n -= 1                            # the last frame repeats the first: smooth the cycle without it
        for i in range(n):
            a, c, q = qs[(i - 1) % n].copy(), qs[(i + 1) % n].copy(), qs[i]
            if a.dot(q) < 0: a.negate()
            if c.dot(q) < 0: c.negate()
            m = Quaternion([(a[j] + 2 * q[j] + c[j]) / 4 for j in range(4)]); m.normalize()
            frames[i][b] = (m, frames[i][b][1])
        if closed: frames[-1][b] = (frames[0][b][0].copy(), frames[-1][b][1])
# hands per clip (left, right): a soft hand by default, open for gestures, a grip or pinch while holding something.
# The short glove fingers read as a fist with even a moderate curl, so gestures must not inherit a resting curl.
HANDS = {"Wave": ("Soft", "Open"), "Cheer": ("Open", "Open"), "Push": ("Open", "Open"), "Repair": ("Grip", "Grip"),
         "Pollinate": ("Soft", "Pinch"), "Water": ("Soft", "Grip"), "Drink": ("Soft", "Grip"), "PickUp": ("Soft", "Pinch"),
         "OpenDoor": ("Soft", "Grip")}
POSE_CACHE = {}
def hands_for(clip):
    lp, rp = HANDS.get(clip, ("Soft", "Soft")); out = {}
    for side, pose in (("Left", lp), ("Right", rp)):
        if pose not in POSE_CACHE: POSE_CACHE[pose] = hand_pose(pose)
        out.update({b: q for b, q in POSE_CACHE[pose].items() if f"{side}Hand" in b})
    return out
relaxed = hand_pose("Relaxed")
order = [b.name for b in tgt.data.bones]

# foot zero: Meshy's clips stand with the feet about 20 degrees off Meshy's own bind pose, which sinks the heels and
# lifts the toes on the target. Take each foot's rotation in the standing idle as its zero, so standing feet land
# exactly at rest (flat on the floor); walking still rolls heel to toe on top of it.
FOOT_FIX, IDLE_OFF = {}, 0.0   # IDLE_OFF: the idle's planted ankle below the source bind pose = the floor level
for arg in clip_args:
    path = arg.partition("=")[2] if "=" in arg else arg
    before_acts = set(bpy.data.actions)
    sobjs = import_glb(path); srcarm = next(o for o in sobjs if o.type == "ARMATURE"); ad = srcarm.animation_data
    acts = [ad.action] + [t.strips[0].action for t in ad.nla_tracks if t.strips] if ad else []
    idle = next((x for x in acts if x and game_name(x.name.split("|")[1] if "|" in x.name else x.name) == "Idle_loop"), None)
    if idle:
        ad.action = idle
        for t in ad.nla_tracks: t.mute = True
        sc.frame_set(int(idle.frame_range[0])); SW = srcarm.matrix_world
        for b in ("LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"):
            d0 = (SW @ srcarm.pose.bones[b].matrix).to_quaternion() @ (SW @ srcarm.data.bones[b].matrix_local).to_quaternion().inverted()
            FOOT_FIX[P + b] = d0.inverted()
        IDLE_OFF = min((SW @ srcarm.pose.bones[b].head).z - (SW @ srcarm.data.bones[b].head_local).z for b in ("LeftFoot", "RightFoot"))
        print("FOOT ZERO from Idle_loop:", {k[10:]: round(math.degrees(v.angle), 1) for k, v in FOOT_FIX.items()}, f"ankle {IDLE_OFF * 100:+.1f} cm")
    for o in sobjs: bpy.data.objects.remove(o)
    for x in set(bpy.data.actions) - before_acts: bpy.data.actions.remove(x)   # or the main pass gets .001 names
    if FOOT_FIX: break  # parents come before children in Blender's bone list
done = set()

for arg in clip_args:
    given, _, path = arg.partition("=") if "=" in arg else ("", "", arg)
    sobjs = import_glb(path)
    srcarm = next(o for o in sobjs if o.type == "ARMATURE")
    for o in sobjs:
        if o.type == "MESH": o.hide_viewport = True
    SW = srcarm.matrix_world
    srest = {b.name: SW @ b.matrix_local for b in srcarm.data.bones}
    hip_k = trest[P + "Hips"].translation.z / srest["Hips"].translation.z
    # The two rigs rest the upper body a few degrees apart (up to ~17 at a shoulder or wrist), and copying only the
    # change from rest carries that offset into every pose: flared arms, bent wrists, hunched shoulders. Turn each
    # upper-body target bone's rest onto its source bone's rest direction first, so it points where the source points.
    # (Legs keep the change from rest: their foot zero and floor contact are tuned on it.)
    ALIGN = {}
    for sb, tb in BONE_MAP.items():
        if tb == "Hips" or tb.endswith(("UpLeg", "Leg", "Foot", "ToeBase")): continue
        sd = (srest[sb].to_3x3() @ Vector((0, 1, 0))).normalized(); td = (trest[P + tb].to_3x3() @ Vector((0, 1, 0))).normalized()
        ALIGN[P + tb] = td.rotation_difference(sd)
    ad = srcarm.animation_data  # the importer makes the first clip active and puts every clip on an NLA track
    acts = [ad.action] + ([] if given else [t.strips[0].action for t in ad.nla_tracks if t.strips])
    for sact in [a for a in dict.fromkeys(acts) if a]:
        raw = sact.name.split("|")[1] if "|" in sact.name else sact.name
        raw = re.sub(r"\.\d{3}$", "", raw)          # Blender's ".001" when two source files hold a clip of the same name
        name = given or game_name(raw)
        if name is None or name in done: continue
        done.add(name)
        srcarm.animation_data.action = sact
        for t in srcarm.animation_data.nla_tracks: t.mute = True
        f0, f1 = (int(round(v)) for v in sact.frame_range)
        frames, lows, contact, roots = [], [], [], []; hp = hands_for(name)
        tilt = 0.0
        if name in POSTURE:   # one pass over the clip for its average lean
            leans = []
            for f in range(f0, f1 + 1):
                sc.frame_set(f)
                w = {}
                for sb, tb in BONE_MAP.items():
                    if P + tb in SPINE or tb == "Hips":
                        dq = (SW @ srcarm.pose.bones[sb].matrix).to_quaternion() @ srest[sb].to_quaternion().inverted()
                        w[P + tb] = (dq @ ALIGN.get(P + tb, Quaternion()) @ trest[P + tb].to_quaternion(), None)
                leans.append(spine_lean(w))
            tilt = POSTURE_LEAN - sum(leans) / len(leans)
            print(f"POSTURE {name}: average lean {math.degrees(sum(leans) / len(leans)):+.1f} -> {math.degrees(POSTURE_LEAN):+.1f} degrees")
        for f in range(f0, f1 + 1):
            sc.frame_set(f)
            want = {}  # target bone -> desired world matrix (rotation part) for mapped bones
            for sb, tb in BONE_MAP.items():
                spw = SW @ srcarm.pose.bones[sb].matrix
                dq = spw.to_quaternion() @ srest[sb].to_quaternion().inverted()
                if P + tb in FOOT_FIX: dq = dq @ FOOT_FIX[P + tb]
                want[P + tb] = (dq @ ALIGN.get(P + tb, Quaternion()) @ ROLL.get(P + tb, Quaternion()) @ trest[P + tb].to_quaternion(), spw.translation)
            if name in SETTLE: settle(want, *SETTLE[name])
            if tilt:
                tip = Quaternion(facing(want)[1], tilt)
                for b in SPINE: want[b] = (tip @ want[b][0], want[b][1])
            if name in POSTURE: straighten_knees(want)
            if name in GAITS: firm_wrists(want)
            pose_w, fr = {}, {}
            for b in order:
                bone = tgt.data.bones[b]; par = bone.parent
                rest_w = trest[b]
                if par is None:
                    q_w = want[b][0] if b in want else rest_w.to_quaternion()
                    loc_w = rest_w.translation + (want[b][1] - srest["Hips"].translation) * hip_k if b in want else rest_w.translation
                    pose_w[b] = Matrix.Translation(loc_w) @ q_w.to_matrix().to_4x4()
                    basis = rest_w.inverted() @ pose_w[b]
                    fr[b] = (basis.to_quaternion(), basis.translation.copy()); root = (b, rest_w, loc_w, q_w)
                    continue
                inherit = pose_w[par.name] @ trest[par.name].inverted() @ rest_w
                if b in (P + "LeftShoulder", P + "RightShoulder"):
                    want[b] = (clavicle(b[len(P):-8], pose_w[par.name], want), want[b][1])
                if name in HANG and b in (P + "LeftArm", P + "RightArm"):
                    hang_arm(b[len(P):-3], inherit.translation, pose_w[P + "Hips"], want)
                if b in want:
                    pose_w[b] = Matrix.Translation(inherit.translation) @ want[b][0].to_matrix().to_4x4()
                    fr[b] = ((inherit.inverted() @ pose_w[b]).to_quaternion(), None)
                elif b in hp:
                    fr[b] = (hp[b], None)
                    pose_w[b] = inherit @ hp[b].to_matrix().to_4x4()
                else:
                    pose_w[b] = inherit
            lows.append(min((pose_w[b] @ q).z for b, q in SOLE))   # lowest boot point, before any correction
            contact.append(min(want[P + sd + "Foot"][1].z - srest[sd + "Foot"].translation.z for sd in ("Left", "Right")) - IDLE_OFF < 0.05)
            roots.append(root); frames.append(fr)
        # floor contact: while the source has a foot down, the lowest boot point sits on the floor; frames in the air
        # (a run's flight) blend between the corrections of the nearest contact frames
        cf = [i for i, c in enumerate(contact) if c] or [min(range(len(lows)), key=lambda i: lows[i])]
        for i, fr in enumerate(frames):
            if contact[i] or i in cf: dz = -lows[i]
            else:
                a_ = max((j for j in cf if j < i), default=None); b_ = min((j for j in cf if j > i), default=None)
                if a_ is None or b_ is None: dz = -lows[a_ if b_ is None else b_]
                else: t = (i - a_) / (b_ - a_); dz = -(lows[a_] * (1 - t) + lows[b_] * t)
            b, rest_w, loc_w, q_w = roots[i]
            basis = rest_w.inverted() @ (Matrix.Translation(loc_w + Vector((0, 0, dz))) @ q_w.to_matrix().to_4x4())
            fr[b] = (basis.to_quaternion(), basis.translation.copy())
        if name in GAITS: smooth_cycle(frames)
        write_action(name, frames)
        print(f"CLIP {name}: {len(frames)} frames")
    for o in sobjs: bpy.data.objects.remove(o)

for pname in ("Relaxed", "Open", "Grip", "Fist", "Point", "Pinch"):
    q = relaxed if pname == "Relaxed" else hand_pose(pname)
    write_action(f"Hand{pname}", [{b: (v, None) for b, v in q.items()}])

for o in tmesh: o.hide_viewport = False
for pb in tgt.pose.bones: pb.matrix_basis.identity()
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_yup=True, export_skins=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS")
print(f"HANG forearm turn to face the palms to the thighs: up to {HANG_TWIST[0]:.0f} degrees")
print("RETARGETED", sorted(done), "->", dst)
