"""Fit PR_Helmet_Roles to each fitted EVA suit (M3-3A) and write the per-cadet scale and offset into helmet_roles.json.

  blender -b -P fit_helmets_eva.py -- [--write]

Measured, not guessed: on PR_Helmet_Roles.glb, the shell's inner surface (interior width and depth above the neck
ring, usable height) and its base opening; on each installed game/assets/characters/CH_<Name>_EVA/CH_<Name>_EVA.glb at
rest, the head with its hair (every vertex whose strongest weight is the Head bone; a ponytail on its own bones is
tucked away while the helmet is on) and the suit's rigid neck ring (the collar around the Neck joint). The helmet is
carried by the Head bone: on the chest bone (as a real helmet locks onto the neck ring) the clips' head pitch and gaze
pushed the face out through the front of the shell (Godot side captures, 7 Nov). The scale is the smallest (in 0.01 steps, never below the approved 1.0) that leaves 2 cm around the head and
hair at the sides and front/back (the depth runs from the closed sun visor to the back of the shell), 1.5 cm over the crown, and an opening 1 cm wider than the suit ring; the helmet's
base sits 2 cm down over the ring top, and the shell is centred on the head in plan. Prints a table; --write updates
the json (the original coverall-era fit values are replaced: helmets are only worn with the EVA suits).
"""
import json, math, os, sys
import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HELMET = os.path.join(ROOT, "game/assets/props/PR_Helmet_Roles/PR_Helmet_Roles.glb")
DATA = os.path.join(ROOT, "game/assets/props/PR_Helmet_Roles/helmet_roles.json")
WRITE = "--write" in sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else False
P = "mixamorig:"
SIDE, CROWN, RING, SEAT = 0.02, 0.015, 0.01, 0.02


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=path)
    sc = bpy.context.scene
    for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
    return sc


# the helmet (Blender frame: z up, front -y), scale 1
sc = load(HELMET)
shell = next(o for o in sc.objects if o.type == "MESH" and o.data.name.startswith("tripo_mesh") or o.name == "Shell")
visor = sc.objects["Visor"]
hinge = sc.objects["Socket_Head"].matrix_world.translation.copy()
inner = [shell.matrix_world @ v.co for v in shell.data.vertices
         if (shell.matrix_world @ v.co).z > 0.16 and (shell.matrix_world.to_3x3() @ v.normal).dot(hinge - shell.matrix_world @ v.co) > 0]
ilo = Vector([min(p[i] for p in inner) for i in range(3)]); ihi = Vector([max(p[i] for p in inner) for i in range(3)])
pts = [o.matrix_world @ v.co for o in (shell, visor) for v in o.data.vertices]
top = max(p.z for p in pts)
clear_w, clear_h = ihi.x - ilo.x, top - 0.012
# depth along the centre line, front to back: the closed sun visor is the helmet's front (the shell alone is open there)
data0 = json.load(open(DATA))
from mathutils import Matrix
close = Matrix.Translation(hinge) @ Matrix.Rotation(math.radians(data0.get("visor_closed_rotation_deg_x", 78.0)), 4, "X") @ Matrix.Translation(-hinge)
vis = [close @ (visor.matrix_world @ v.co) for v in visor.data.vertices]
vis_n = [(close.to_3x3() @ (visor.matrix_world.to_3x3() @ v.normal)) for v in visor.data.vertices]
front = min(p.y for p, n in zip(vis, vis_n) if abs(p.x) < 0.04 and 0.10 < p.z < 0.30 and n.dot(hinge - p) > 0)
back = max(p.y for p in inner if abs(p.x) < 0.04 and 0.10 < p.z < 0.30)
clear_d = back - front
icx, icy = (ilo.x + ihi.x) / 2, (front + back) / 2
base = [shell.matrix_world @ v.co for v in shell.data.vertices if (shell.matrix_world @ v.co).z < 0.03]
open_w = (max(p.x for p in base) - min(p.x for p in base)) - 0.02      # the ring's own wall, about 1 cm each side
open_d = (max(p.y for p in base) - min(p.y for p in base)) - 0.02
print(f"HELMET shell-only depth {ihi.y - ilo.y:.3f}; interior w {clear_w:.3f} d {clear_d:.3f} (closed visor to shell back) h {clear_h:.3f}, centre ({icx:+.3f}, {icy:+.3f}); base opening {open_w:.3f} x {open_d:.3f}")

data = json.load(open(DATA))
rows = {}
for key in data["roles"]:
    path = os.path.join(ROOT, f"game/assets/characters/CH_{key.capitalize()}_EVA/CH_{key.capitalize()}_EVA.glb")
    if not os.path.exists(path):
        if WRITE: sys.exit(f"FIT {key}: no EVA suit at {path}; fit every role before --write")
        print(f"FIT {key}: no EVA suit yet"); continue
    sc = load(path)
    arm = next(o for o in sc.objects if o.type == "ARMATURE"); body = sc.objects["Body"]
    if arm.animation_data:
        for t in arm.animation_data.nla_tracks: t.mute = True
        arm.animation_data.action = None
    W = arm.matrix_world
    head_j = W @ arm.data.bones[P + "Head"].head_local; neck_j = W @ arm.data.bones[P + "Neck"].head_local
    names = {g.index: g.name for g in body.vertex_groups}
    def strongest(v):
        g = max(v.groups, key=lambda x: x.weight, default=None); return names.get(g.group, "") if g else ""
    V = [(body.matrix_world @ v.co, strongest(v)) for v in body.data.vertices]
    head = [p for p, g in V if g == P + "Head"]
    hx0, hx1 = min(p.x for p in head), max(p.x for p in head); hy0, hy1 = min(p.y for p in head), max(p.y for p in head)
    htop = max(p.z for p in head)
    # the neck ring: suit vertices (not Head) within 9 cm of the neck axis' height band, wider than the neck itself
    ring = [p for p, g in V if g != P + "Head" and abs(p.z - neck_j.z) < 0.07 and math.hypot(p.x - neck_j.x, p.y - neck_j.y) < 0.16]
    rtop = max(p.z for p in ring)
    rw = max(p.x for p in ring) - min(p.x for p in ring); rd = max(p.y for p in ring) - min(p.y for p in ring)
    base_z = rtop - SEAT
    need = {"width": (hx1 - hx0 + 2 * SIDE) / clear_w, "depth": (hy1 - hy0 + 2 * SIDE) / clear_d,
            "height": (htop - base_z + CROWN) / clear_h, "ring": max((rw + RING) / open_w, (rd + RING) / open_d)}
    s = round(math.ceil(max(1.0, *need.values()) * 100 - 1e-6) / 100, 2)
    # helmet origin (its base centre) so that the scaled interior is centred on the head in plan, base on the ring
    origin = Vector(((hx0 + hx1) / 2 - icx * s, (hy0 + hy1) / 2 - icy * s, base_z))
    rows[key] = dict(scale=s, origin=origin, head=(hx1 - hx0, hy1 - hy0, htop - base_z), ring=(rw, rd, rtop), need=need,
                     clear=dict(width=round(clear_w * s - (hx1 - hx0), 3), depth=round(clear_d * s - (hy1 - hy0), 3), height=round(clear_h * s - (htop - base_z), 3)))
    print(f"FIT {key:9s} head {hx1 - hx0:.3f} x {hy1 - hy0:.3f}, {htop - base_z:.3f} above the seat; ring {rw:.3f} x {rd:.3f} top {rtop:.3f}"
          f" -> scale {s:.2f} (" + ", ".join(f"{k} {v:.2f}" for k, v in need.items()) + f"); clearance {rows[key]['clear']}")

if WRITE:
    data["task"] = "M3-3A"
    data["fit"] = ("Measured on the installed CH_<Name>_EVA suits by production/tools/fit_helmets_eva.py: the smallest scale "
                   f"(never below 1.0) leaving {SIDE * 100:.0f} cm round the head and hair, {CROWN * 100:.1f} cm over the crown and an opening "
                   f"{RING * 100:.0f} cm wider than the suit's neck ring; the base sits {SEAT * 100:.0f} cm down over the ring and the shell is centred on the head. "
                   "A ponytail (its own bones) is tucked while the helmet is on.")
    data["equip_bone"] = "Head"
    data["states"]["equipped"] = ("carried by the suit's Head bone (equip_bone), so the face stays inside the shell in every clip: its base centre "
                                  "at equip_origin_m in the rest pose (character space, Godot axes) with scale; a ponytail is tucked (tuck_bones scaled down)")
    data["interior_clearance_m"] = dict(width=round(clear_w, 3), depth=round(clear_d, 3), height=round(clear_h, 3))
    for key, r in rows.items():
        role = data["roles"][key]
        for old in ("equip_offset_from_head_bone_m", "head_clearance_m"): role.pop(old, None)
        role["scale"] = r["scale"]
        # the helmet's base centre in the character's rest pose, Godot axes (x, up, front = Blender x, z, -y);
        # helmet_roles.gd turns it into an offset from equip_bone's rest at equip time
        role["equip_origin_m"] = [round(r["origin"].x, 4), round(r["origin"].z, 4), round(-r["origin"].y, 4)]
        role["head_clearance_m"] = r["clear"]
        role["suit"] = f"CH_{key.capitalize()}_EVA"
    data["tuck_bones"] = ["Ponytail1"]
    open(DATA, "w").write(json.dumps(data, indent=1) + "\n")
    print("WROTE", DATA)
