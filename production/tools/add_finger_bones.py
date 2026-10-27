"""Add finger bones and grip poses to a Meshy-rigged character (Meshy rigs stop at the wrist).

  blender -b -P add_finger_bones.py -- <in.glb> <out.glb> [--debug <prefix>]

Per hand: five chains (thumb 2 bones, fingers 3) are fitted to the glove's own geometry. The hand's
vertices are expressed in the wrist frame (along the forearm = forward, palm normal = down); the five
digit tips are the extreme points found by angle around the knuckle line, and each chain runs from its
knuckle to its tip. Hand-bone weights are split between the new bones by nearest-segment distance with
smooth falloff, so the palm stays on the hand and fingers bend at three joints. Static grip poses
(Grip, Point, Fist, Relaxed) are added as one-frame actions; Godot blends them on the hand bones over
any body clip. --debug renders the bones over the glove and a full fist, to check the fit.
"""
import argparse, math, sys
import bpy, bmesh
from mathutils import Vector, Matrix
from mathutils.kdtree import KDTree

argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser(); p.add_argument("src"); p.add_argument("dst"); p.add_argument("--debug")
a = p.parse_args(argv)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
shapes = {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones}
for o in [o for o in sc.objects if o in shapes]:
    bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE")
me = next(o for o in sc.objects if o.type == "MESH")
saved_action = arm.animation_data.action if arm.animation_data else None
if arm.animation_data: arm.animation_data.action = None
for pb in arm.pose.bones: pb.matrix_basis.identity()
bpy.context.view_layer.update()
AW, AWi = arm.matrix_world, arm.matrix_world.inverted()
MW = me.matrix_world
DIGITS = ("Thumb", "Index", "Middle", "Ring", "Pinky")

def hand_frame(side):
    """Wrist frame in world space: x = along hand (forearm direction), z = palm normal (down in a T-pose)."""
    fa, hb = arm.pose.bones[f"{side}ForeArm"], arm.pose.bones[f"{side}Hand"]
    wrist = AW @ hb.head
    along = (AW @ hb.head - AW @ fa.head).normalized()
    up = Vector((0, 0, 1))
    side_v = along.cross(up).normalized()
    up = side_v.cross(along).normalized()
    return wrist, along, side_v, up

plans, plans_up = {}, {}
for side in ("Left", "Right"):
    vg = me.vertex_groups[f"{side}Hand"]
    wrist, along, side_v, up = hand_frame(side)
    pts = [MW @ v.co for v in me.data.vertices if any(g.group == vg.index and g.weight > 0.3 for g in v.groups)]
    loc = [Vector(((q - wrist).dot(along), (q - wrist).dot(side_v), (q - wrist).dot(up))) for q in pts]
    L = max(v.x for v in loc)                        # hand length from the wrist
    knuckle_x = 0.45 * L
    fingers = [v for v in loc if v.x > knuckle_x]
    # fingers spread across the side axis: split by side position into 4 bands; thumb = points that stick out
    # sideways beyond the finger bands near the palm
    ys = sorted(v.y for v in fingers)
    lo_y, hi_y = ys[int(len(ys) * 0.03)], ys[int(len(ys) * 0.97)]
    thumb_on_plus = (side == "Left") ^ (along.cross(side_v).z < 0)  # thumb lies toward +side for one hand
    band = (hi_y - lo_y) / 4
    chains = {}
    order = ("Index", "Middle", "Ring", "Pinky") if thumb_on_plus else ("Pinky", "Ring", "Middle", "Index")
    order = order[::-1] if thumb_on_plus else order
    for k, name in enumerate(order):
        y0, y1 = lo_y + band * k, lo_y + band * (k + 1)
        sel = [v for v in fingers if y0 <= v.y < y1]
        if not sel: continue
        tip = max(sel, key=lambda v: v.x)
        root = Vector((knuckle_x, (y0 + y1) / 2, sum(v.z for v in sel) / len(sel)))
        chains[name] = (root, Vector((tip.x, (y0 + y1) / 2, tip.z)))
    palm = [v for v in loc if 0.15 * L < v.x < 0.6 * L]
    tside = (max if thumb_on_plus else min)(palm, key=lambda v: v.y)
    thumb_pts = [v for v in loc if (v.y - tside.y) * (1 if thumb_on_plus else -1) > -0.25 * band and v.x < 0.75 * L]
    ttip = max(thumb_pts, key=lambda v: v.x * 0.6 + abs(v.y) * 0.4)
    chains["Thumb"] = (Vector((0.18 * L, tside.y * 0.7, tside.z)), ttip)
    to_world = lambda v: wrist + along * v.x + side_v * v.y + up * v.z
    plans[side] = {n: (to_world(r), to_world(t)) for n, (r, t) in chains.items()}
    plans_up[side] = up
    print(f"HAND {side}: length {L:.3f} m, digits {sorted(chains)}")

# add bones
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones
for side, chains in plans.items():
    parent = eb[f"{side}Hand"]
    for name, (root, tip) in chains.items():
        n = 2 if name == "Thumb" else 3
        fr = (0.45, 0.30, 0.25) if n == 3 else (0.55, 0.45)
        prev, start = parent, root
        for i in range(n):
            end = start + (tip - root) * fr[i]
            b = eb.new(f"{side}Hand{name}{i + 1}")
            b.head, b.tail = AWi @ start, AWi @ end
            b.align_roll(AWi.to_3x3() @ -plans_up[side])   # bone Z faces the palm: +X rotation curls inward
            b.parent = prev; b.use_connect = i > 0
            prev, start = b, end
bpy.ops.object.mode_set(mode="OBJECT")

# weights: each hand vertex near a digit goes to that one digit only, blended along the chain; palm stays
RADIUS, FADE, BLEND = 0.022, 0.012, 0.008
def closest_on_chain(q, pts):
    """Arc-length position and distance of q's closest point on polyline pts (s < 0 before the root)."""
    best, acc = (1e9, 0.0), 0.0
    for h, t in zip(pts, pts[1:]):
        d = t - h; L = d.length; u = (q - h).dot(d) / (L * L)
        uc = max(0.0, min(1.0, u)) if acc > 0 else min(1.0, u)
        dist = (q - (h + d * max(0.0, uc))).length
        if dist < best[0]: best = (dist, acc + uc * L)
        acc += L
    return best
for side, chains in plans.items():
    hand_vg = me.vertex_groups[f"{side}Hand"]
    digit = {}
    for name in chains:
        n = 2 if name == "Thumb" else 3
        bones = [arm.data.bones[f"{side}Hand{name}{i + 1}"] for i in range(n)]
        pts = [AW @ bones[0].head_local] + [AW @ b.tail_local for b in bones]
        cuts = [0.0]
        for h, t in zip(pts, pts[1:]): cuts.append(cuts[-1] + (t - h).length)
        digit[name] = (pts, cuts, [me.vertex_groups.new(name=b.name) for b in bones])
    for v in me.data.vertices:
        w = next((g.weight for g in v.groups if g.group == hand_vg.index), 0.0)
        if w < 0.01: continue
        q = MW @ v.co
        name, (d, sarc) = min(((n, closest_on_chain(q, dg[0])) for n, dg in digit.items()), key=lambda x: x[1][0])
        if d > RADIUS or sarc < -FADE: continue
        pts, cuts, groups = digit[name]
        share = w * max(0.0, min(1.0, (sarc + FADE) / FADE))     # hand -> first bone across the knuckle
        k = max(0, min(len(groups) - 1, next((i for i in range(len(groups)) if sarc < cuts[i + 1]), len(groups) - 1)))
        ws = {k: 1.0}
        if k + 1 < len(groups) and cuts[k + 1] - sarc < BLEND:   # near the next joint: blend into the next bone
            f = 0.5 * (1 - (cuts[k + 1] - sarc) / BLEND); ws = {k: 1 - f, k + 1: f}
        elif k > 0 and sarc - cuts[k] < BLEND:
            f = 0.5 * (1 - (sarc - cuts[k]) / BLEND); ws = {k: 1 - f, k - 1: f}
        for gi, f in ws.items():
            groups[gi].add([v.index], share * f, "ADD")
        hand_vg.add([v.index], w - share, "REPLACE")

# grip poses: curl angles (degrees) per joint, about each bone's local X
POSES = {"Relaxed": (12, 10, 8, 10), "Grip": (55, 70, 45, 35), "Fist": (80, 95, 70, 55), "Point": None}
arm.animation_data_create()
def pose(curl, idx_straight=False):
    for side in plans:
        for name in DIGITS:
            n = 2 if name == "Thumb" else 3
            for i in range(n):
                pb = arm.pose.bones.get(f"{side}Hand{name}{i + 1}")
                if not pb: continue
                ang = curl[min(i, 2)] if name != "Thumb" else curl[3] * (0.6 if i == 0 else 1.0)
                if idx_straight and name == "Index": ang = 4
                pb.rotation_mode = "XYZ"; pb.rotation_euler = (math.radians(ang), 0, 0)
for pname, curl in POSES.items():
    act = bpy.data.actions.new(f"Hand{pname}")
    arm.animation_data.action = act
    pose(POSES["Fist"] if pname == "Point" else curl, idx_straight=pname == "Point")
    for side in plans:
        for name in DIGITS:
            for i in range(3):
                pb = arm.pose.bones.get(f"{side}Hand{name}{i + 1}")
                if pb: pb.keyframe_insert("rotation_euler", frame=0)
    act.use_fake_user = True
    tr = arm.animation_data.nla_tracks.new(); tr.name = act.name; tr.strips.new(act.name, 0, act); tr.mute = True
arm.animation_data.action = None
for pb in arm.pose.bones: pb.matrix_basis.identity()

if a.debug:
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE"
    sc.render.resolution_x = sc.render.resolution_y = 600
    w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    l = bpy.data.objects.new("K", bpy.data.lights.new("K", "SUN")); l.data.energy = 3; sc.collection.objects.link(l)
    cam = bpy.data.objects.new("C", bpy.data.cameras.new("C")); cam.data.lens = 60; sc.collection.objects.link(cam); sc.camera = cam
    wrist, along, side_v, up = hand_frame("Left")
    c = wrist + along * 0.09
    mark = bpy.data.materials.new("M"); mark.use_nodes = True
    mark.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (1, 0.1, 0.1, 1)
    mark.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 5
    marks = []
    for b in arm.data.bones:
        if b.name.startswith("LeftHand") and b.name[-1].isdigit():
            for pnt in (b.head_local, b.tail_local):
                bpy.ops.mesh.primitive_uv_sphere_add(radius=0.0035, location=AW @ pnt); o = bpy.context.object
                o.data.materials.append(mark); o.show_in_front = True; marks.append(o)
    for vt, d in (("side", -side_v * 0.4 + up * 0.05), ("top", up * 0.4)):
        cam.location = c + d; cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = f"{a.debug}_joints_{vt}.png"; bpy.ops.render.render(write_still=True)
    for o in marks: bpy.data.objects.remove(o)
    for tag, curl in (("relaxed", POSES["Relaxed"]), ("grip", POSES["Grip"]), ("fist", POSES["Fist"])):
        pose(curl); bpy.context.view_layer.update()
        for vt, d in (("side", -side_v * 0.4 + up * 0.05), ("top", up * 0.4)):
            cam.location = c + d; cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
            sc.render.filepath = f"{a.debug}_{tag}_{vt}.png"; bpy.ops.render.render(write_still=True)
    for pb in arm.pose.bones: pb.matrix_basis.identity()

if saved_action and arm.animation_data: arm.animation_data.action = None
bpy.ops.export_scene.gltf(filepath=a.dst, export_format="GLB", export_yup=True, export_skins=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS")
print("FINGERS added:", sum(1 for b in arm.data.bones if "Hand" in b.name and b.name[-1].isdigit()), "bones ->", a.dst)
