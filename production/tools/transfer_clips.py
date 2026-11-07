"""Copy every clip of an installed character onto a new Mixamo rig of the same person (an outfit variant such as the
fitted EVA suit), so the variant moves exactly like the approved character.

  blender -b -P transfer_clips.py -- <tripo_mixamo_rig.glb> <installed_character.glb> <out.glb> [--skip A,B]

The source is an installed v7/v8 character (Tripo Mixamo rig, 44 clips made by retarget_clips.py and
add_hold_poses.py). The target is scaled so its joints stand at the source's joint heights (a least-squares fit over
hips, neck, head, shoulders and knees: the same person and skeleton, so hair or a bun no longer sets the
scale). Upper-body bones are first turned onto the source bone's rest direction, then take the source bone's
world-space change from rest (as retarget_clips.py does); legs take the change from rest only, so a wider suit stance
is kept. The hips get the source's root motion, and every frame the variant's lowest boot or knee point is put where
the source's was, so planted feet stay planted on the variant's own boots. Only the bones a source clip keys are
written (the Hand* poses stay finger-only). A bulkier variant (the EVA suit's hips and thighs stand wider than the
coverall's) has each whole arm turned out about the body's forward axis by the angle that keeps the hanging hand as
clear of its own hips as the source's was (measured on both meshes; never inward), as a pressurised suit holds the
arms a little out. --skip leaves clips out (the hold poses are rebuilt for the new body by
add_hold_poses.py). The main mesh is named "Body", as the later finishing steps expect.
"""
import argparse, math, sys
import bpy
from mathutils import Matrix, Quaternion, Vector

a = argparse.ArgumentParser(); a.add_argument("rig"); a.add_argument("src"); a.add_argument("dst")
a.add_argument("--skip", default="")
a = a.parse_args(sys.argv[sys.argv.index("--") + 1:])
SKIP = {s for s in a.skip.split(",") if s}
P = "mixamorig:"
LEGS = ("UpLeg", "Leg", "Foot", "ToeBase", "Toe_End")
FIT = ["Hips", "Neck", "Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg"]   # not the spine: riggers place Spine1/2 differently on a bulky suit

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


def import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    shapes = {pb.custom_shape for o in new if o.type == "ARMATURE" for pb in o.pose.bones} - {None}
    keep = [o for o in new if o not in shapes]
    for o in shapes:  # the glTF importer's bone-display icosphere
        bpy.data.objects.remove(o)
    return keep


def channel_bones(act):
    """Bone names an action keys (legacy and layered/slotted actions)."""
    curves = list(getattr(act, "fcurves", []) or [])
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for bag in getattr(strip, "channelbags", []):
                curves += list(bag.fcurves)
    return {fc.data_path.split('"')[1] for fc in curves if fc.data_path.startswith('pose.bones["')}


# target: the new rig, its placeholder animation cleared
tobjs = import_glb(a.rig)
tgt = next(o for o in tobjs if o.type == "ARMATURE")
tmesh = [o for o in tobjs if o.type == "MESH"]
body = max(tmesh, key=lambda o: len(o.data.vertices))
body.name = body.data.name = "Body"
tgt.animation_data_create()
for t in list(tgt.animation_data.nla_tracks): tgt.animation_data.nla_tracks.remove(t)
tgt.animation_data.action = None
for x in list(bpy.data.actions): bpy.data.actions.remove(x)

sobjs = import_glb(a.src)
src = next(o for o in sobjs if o.type == "ARMATURE")
sbody = max((o for o in sobjs if o.type == "MESH"), key=lambda o: len(o.data.vertices))
SW = src.matrix_world

# scale: least squares over the joint heights, then apply so the rig is in metres
th = [(tgt.matrix_world @ tgt.data.bones[P + b].head_local).z for b in FIT]
sh = [(SW @ src.data.bones[P + b].head_local).z for b in FIT]
k = sum(s * t for s, t in zip(sh, th)) / sum(t * t for t in th)
tgt.scale = [v * k for v in tgt.scale]
bpy.ops.object.select_all(action="DESELECT")
for o in [tgt] + tmesh: o.select_set(True)
bpy.context.view_layer.objects.active = tgt
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
TW = tgt.matrix_world
fit = max(abs((TW @ tgt.data.bones[P + b].head_local).z - s) for b, s in zip(FIT, sh))
top = max((o.matrix_world @ v.co).z for o in tmesh for v in o.data.vertices)
print(f"SCALE x{k:.4f}: joints within {fit * 100:.1f} cm of the source's; mesh height {top:.3f} m")
print("JOINTS (variant - source, cm):", {b: round(((TW @ tgt.data.bones[P + b].head_local).z - s) * 100, 1) for b, s in zip(FIT, sh)})

trest = {b.name: TW @ b.matrix_local for b in tgt.data.bones}
srest = {b.name: SW @ b.matrix_local for b in src.data.bones}
order = [b.name for b in tgt.data.bones]          # parents before children
common = [b for b in order if b in srest]
ALIGN = {}
for b in common:
    if b == P + "Hips" or b.endswith(LEGS): continue
    td = (trest[b].to_3x3() @ Vector((0, 1, 0))).normalized(); sd = (srest[b].to_3x3() @ Vector((0, 1, 0))).normalized()
    ALIGN[b] = td.rotation_difference(sd)
hip_k = trest[P + "Hips"].translation.z / srest[P + "Hips"].translation.z


def soles(arm, mesh):
    """Points over each boot (foot and toe bones) and around each knee, in their bone's rest frame."""
    out, W = [], arm.matrix_world
    groups = {g.name: g.index for g in mesh.vertex_groups}
    for side in ("Left", "Right"):
        for name in (P + side + "Foot", P + side + "ToeBase", P + side + "Leg"):
            gi = groups.get(name)
            if gi is None: continue
            pts = [mesh.matrix_world @ v.co for v in mesh.data.vertices if any(g.group == gi and g.weight > 0.5 for g in v.groups)]
            if name.endswith("Leg"):   # the knee only: when kneeling it is the lowest point
                knee = W @ arm.data.bones[name].head_local
                pts = [q for q in pts if (q - knee).length < 0.07]
            rest = (W @ arm.data.bones[name].matrix_local).inverted()
            out += [(name, rest @ q) for q in pts[::4]]
    return out


TSOLE, SSOLE = soles(tgt, body), soles(src, sbody)


def side_x(arm, mesh, side):
    """How far the body (no arm vertices) reaches out on one side at the height of a hanging wrist."""
    W = arm.matrix_world; sg = 1 if side == "Left" else -1
    up, fore, hand = (W @ arm.data.bones[P + side + b].head_local for b in ("Arm", "ForeArm", "Hand"))
    z = up.z - 0.982 * ((fore - up).length + (hand - fore).length)
    armg = {g.index for g in mesh.vertex_groups if any(t in g.name for t in ("Arm", "Hand"))}
    xs = [sg * (mesh.matrix_world @ v.co).x for v in mesh.data.vertices
          if sum(g.weight for g in v.groups if g.group in armg) < 0.3 and abs((mesh.matrix_world @ v.co).z - z) < 0.06]
    return max(xs), (hand - up).length


ABDUCT = {}
for side in ("Left", "Right"):   # each source arm already hangs clear of whatever is on its own side (a tool pouch)
    (tx, reach), (sx, _) = side_x(tgt, body, side), side_x(src, sbody, side)
    ABDUCT[side] = max(0.0, math.asin(min(max((tx - sx) / reach, -1.0), 1.0)))
    print(f"ABDUCT {side} arm: body side {sx:.3f} -> {tx:.3f} m at the wrist, arm turned out {math.degrees(ABDUCT[side]):.1f} degrees")
CHAIN = {}
for b in order:   # every bone below each upper arm (forearm, hand, fingers) turns with it
    for side in ("Left", "Right"):
        bone = tgt.data.bones[b]
        while bone is not None and bone.name != P + side + "Arm": bone = bone.parent
        if bone is not None: CHAIN[b] = side
for o in tmesh + [o for o in sobjs if o.type == "MESH"]: o.hide_viewport = True   # no mesh evaluation while baking
sacts = []
ad = src.animation_data
if ad:
    sacts = list(dict.fromkeys([ad.action] + [t.strips[0].action for t in ad.nla_tracks if t.strips]))
made = []

for act in [x for x in sacts if x]:
    name = act.name.split("|")[-1] if "|" in act.name else act.name
    if name in SKIP: continue
    keyed = channel_bones(act) & set(common)
    for pb in src.pose.bones: pb.matrix_basis.identity()
    ad.action = act
    for t in ad.nla_tracks: t.mute = True
    f0, f1 = (int(round(v)) for v in act.frame_range)
    full = P + "Hips" in keyed
    frames = []
    for f in range(f0, f1 + 1):
        sc.frame_set(f)
        spw = {b: SW @ src.pose.bones[b].matrix for b in keyed}
        pose_w, fr = {}, {}
        for b in order:
            par = tgt.data.bones[b].parent
            if par is None:
                if b in keyed:
                    q = spw[b].to_quaternion() @ srest[b].to_quaternion().inverted() @ trest[b].to_quaternion()
                    loc = trest[b].translation + (spw[b].translation - srest[b].translation) * hip_k
                    pose_w[b] = Matrix.Translation(loc) @ q.to_matrix().to_4x4()
                else:
                    pose_w[b] = trest[b]
                continue
            inherit = pose_w[par.name] @ trest[par.name].inverted() @ trest[b]
            if b in keyed:
                q = spw[b].to_quaternion() @ srest[b].to_quaternion().inverted() @ ALIGN.get(b, Quaternion()) @ trest[b].to_quaternion()
                if b in CHAIN and ABDUCT[CHAIN[b]] and P + CHAIN[b] + "Arm" in keyed:
                    fwd = pose_w[P + "Hips"].to_quaternion() @ trest[P + "Hips"].to_quaternion().inverted() @ Vector((0, -1, 0))
                    fwd.z = 0; fwd.normalize(); sg = 1 if CHAIN[b] == "Left" else -1
                    q = Quaternion(fwd, sg * ABDUCT[CHAIN[b]]) @ q
                pose_w[b] = Matrix.Translation(inherit.translation) @ q.to_matrix().to_4x4()
            else:
                pose_w[b] = inherit
        if full:   # floor: the variant's lowest boot point goes where the source's lowest boot point is
            s_low = min((SW @ src.pose.bones[b].matrix @ q).z for b, q in SSOLE)
            t_low = min((pose_w[b] @ q).z for b, q in TSOLE)
            lift = Matrix.Translation((0, 0, s_low - t_low))   # the whole body rides on the hips
            pose_w = {b: lift @ m for b, m in pose_w.items()}
        for b in order:
            if b not in keyed: continue
            par = tgt.data.bones[b].parent
            inherit = trest[b] if par is None else pose_w[par.name] @ trest[par.name].inverted() @ trest[b]
            basis = inherit.inverted() @ pose_w[b]
            fr[b] = (basis.to_quaternion(), basis.translation.copy() if par is None else None)
        frames.append(fr)
    # write the clip on the target under a temporary name (the source's action still holds the real one)
    tmp = bpy.data.actions.new("xfer_" + name)
    tgt.animation_data.action = tmp
    for b in sorted(keyed):
        pb = tgt.pose.bones[b]; pb.rotation_mode = "QUATERNION"
        for i, fr in enumerate(frames):
            q, loc = fr[b]
            pb.rotation_quaternion = q; pb.keyframe_insert("rotation_quaternion", frame=f0 + i)
            if loc is not None:
                pb.location = loc; pb.keyframe_insert("location", frame=f0 + i)
    tmp.use_fake_user = True
    tgt.animation_data.action = None
    made.append((name, tmp))
    print(f"CLIP {name}: {len(frames)} frames, {len(keyed)} bones")

# drop the source, then give the new clips their real names on NLA tracks (as retarget_clips.py exports them)
for o in sobjs: bpy.data.objects.remove(o)
for x in list(bpy.data.actions):
    if not x.name.startswith("xfer_"): bpy.data.actions.remove(x)
for name, act in made:
    act.name = name
    tr = tgt.animation_data.nla_tracks.new(); tr.name = name; tr.strips.new(name, int(act.frame_range[0]), act); tr.mute = True
for o in tmesh: o.hide_viewport = False
for pb in tgt.pose.bones: pb.matrix_basis.identity()
bpy.ops.export_scene.gltf(filepath=a.dst, export_format="GLB", export_yup=True, export_skins=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS")
print("TRANSFERRED", len(made), "clips,", len(tgt.data.bones), "bones ->", a.dst)
