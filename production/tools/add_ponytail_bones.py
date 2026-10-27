"""Add a three-bone ponytail chain (Ponytail1-3, parented to the Head bone) to a rigged character and weight the
ponytail to it, so the game's hair springs can swing it. Every clip is kept (NLA tracks, as retarget_clips.py exports).

  blender -b -P add_ponytail_bones.py -- <in.glb> <out.glb> --ztop 1.56 --zbottom 1.18 [--ztie 1.47 --skull-back 0.065]
         [--xmax 0.075] [--debug out.png]

The ponytail is the narrow band (|x| < xmax) between ztop and zbottom: above ztie, whatever lies behind the back of
the skull (y > skull-back); below it, whatever hangs beyond the air gap behind the neck and upper back. Weights ramp from the Head bone at the tie into the chain, so the root never tears.
"""
import argparse, sys
import bpy
from mathutils import Vector

a = argparse.ArgumentParser(); a.add_argument("src"); a.add_argument("dst")
a.add_argument("--ztop", type=float, required=True); a.add_argument("--zbottom", type=float, required=True)
a.add_argument("--xmax", type=float, default=0.075); a.add_argument("--debug")
a.add_argument("--ztie", type=float, default=1.47); a.add_argument("--skull-back", dest="skull_back", type=float, default=0.065)
a = a.parse_args(sys.argv[sys.argv.index("--") + 1:])
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE"); body = bpy.data.objects["Body"]
mw = body.matrix_world; P = [mw @ v.co for v in body.data.vertices]

def gap_split(z, half=0.006):
    """Behind the neck the ponytail hangs clear of the body: in a thin height band, the ponytail is everything
    beyond the widest gap (>= 1 cm) between centre-line vertices, counted from the back."""
    ys = sorted(p.y for p in P if abs(p.z - z) < half and abs(p.x) < a.xmax and p.y > -0.02)
    best, cut = 0.0, None
    for y0, y1 in zip(ys, ys[1:]):
        if y1 - y0 > best: best, cut = y1 - y0, (y0 + y1) / 2
    return cut if best >= 0.01 else None

pony = {}
cuts = {}
for i, p in enumerate(P):
    if not (a.zbottom <= p.z <= a.ztop and abs(p.x) < a.xmax): continue
    if p.z >= a.ztie:                        # at the tie the ponytail grows out of the back of the skull
        if p.y > a.skull_back: pony[i] = p
        continue
    zb = round(p.z, 2)
    if zb not in cuts: cuts[zb] = gap_split(zb)
    if cuts[zb] is not None and p.y > cuts[zb]: pony[i] = p
# keep only the largest connected piece: stray matches on the back of the coverall are separate islands. The
# imported mesh is split at UV seams, so vertices at the same position count as one before following edges.
key = lambda v: tuple(round(c / 0.0005) for c in v)
group = {}
for i in pony: group.setdefault(key(body.data.vertices[i].co), []).append(i)
canon = {i: key(body.data.vertices[i].co) for i in pony}
nbr = {k: set() for k in group}
for e in body.data.edges:
    i, j = e.vertices
    if i in canon and j in canon and canon[i] != canon[j]: nbr[canon[i]].add(canon[j]); nbr[canon[j]].add(canon[i])
seen, best = set(), []
for start in nbr:
    if start in seen: continue
    comp, stack = [], [start]; seen.add(start)
    while stack:
        k = stack.pop(); comp.append(k)
        for w in nbr[k]:
            if w not in seen: seen.add(w); stack.append(w)
    if sum(len(group[k]) for k in comp) > sum(len(group[k]) for k in best): best = comp
pony = {i: pony[i] for k in best for i in group[k]}

# strand tips that rest on the back have no air gap: grow the selection along the mesh into vertices below the skull
# that the rigger still gave mostly to the Head/Neck bones - hanging hair, never coverall - so no tip stays behind
gnames = {g.index: g.name for g in body.vertex_groups}
def head_held(i):
    w = {gnames[g.group]: g.weight for g in body.data.vertices[i].groups}
    return sum(v for n, v in w.items() if n.endswith(":Head") or n.endswith(":Neck")) >= 0.5
allkey = {}
for v in body.data.vertices: allkey.setdefault(key(v.co), []).append(v.index)
adj = {}
for e in body.data.edges:
    ki, kj = key(body.data.vertices[e.vertices[0]].co), key(body.data.vertices[e.vertices[1]].co)
    if ki != kj: adj.setdefault(ki, set()).add(kj); adj.setdefault(kj, set()).add(ki)
front = {canon[i] for i in pony}; added = 0
while front:
    nxt = set()
    for k in front:
        for w in adj.get(k, ()):
            vs = allkey[w]
            if vs[0] in pony: continue
            p = P[vs[0]]
            if a.zbottom - 0.05 <= p.z < a.ztie and abs(p.x) < a.xmax + 0.03 and p.y > 0.04 and head_held(vs[0]):
                for i in vs: pony[i] = P[i]
                added += len(vs); nxt.add(w)
    front = nxt
print("PONYTAIL grown by", added, "head-held tip vertices")
print("PONYTAIL vertices", len(pony))
# chain points: the ponytail's centre line at four heights
def centre(z0, z1):
    q = [p for p in pony.values() if z0 <= p.z <= z1] or list(pony.values())
    return sum(q, Vector()) / len(q)
zt, zb = max(p.z for p in pony.values()), min(p.z for p in pony.values())   # the ponytail's real extent
span = zt - zb
pts = [centre(zt - span * f - 0.025, zt - span * f + 0.025) for f in (0.06, 0.37, 0.68, 0.96)]

bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones; head = next(b for b in eb if b.name.endswith(":Head")); prefix = head.name[:-4]
inv = arm.matrix_world.inverted(); parent = head; names = []
for k in range(3):
    b = eb.new(f"{prefix}Ponytail{k + 1}"); b.head = inv @ pts[k]; b.tail = inv @ pts[k + 1]
    b.parent = parent; b.use_connect = k > 0; parent = b; names.append(b.name)
bpy.ops.object.mode_set(mode="OBJECT")

groups = [body.vertex_groups.get(n) or body.vertex_groups.new(name=n) for n in names]
hg = body.vertex_groups.get(head.name if False else prefix + "Head")
for i, p in pony.items():
    for g in body.vertex_groups:
        try: g.remove([i])
        except RuntimeError: pass
    t = min(max((zt - p.z) / span, 0.0), 1.0)              # 0 at the tie, 1 at the tip
    root = min(max((t - 0.02) / 0.14, 0.0), 1.0)           # head -> chain over the first part
    root = min(root, max(0.0, (p.y - 0.03) / 0.05))         # where the ponytail's inner side lies on the nape, follow the head more
    f = t * 3 - 0.5                                         # position along the three bones
    w = [max(0.0, 1 - abs(f - k)) for k in range(3)]; s = sum(w) or 1.0
    for g, wk in zip(groups, w):
        if wk > 0: g.add([i], root * wk / s, "REPLACE")
    if root < 1: hg.add([i], 1 - root, "REPLACE")
print("BONES", names, "points", [tuple(round(c, 3) for c in p) for p in pts])

if a.debug:   # colour the ponytail weights red on a side view
    import os, sys as _s
    _s.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import blender_look
    m = bpy.data.materials.new("dbg"); m.use_nodes = True
    attr = body.data.color_attributes.new("pw", "FLOAT_COLOR", "POINT")
    for i in range(len(P)): attr.data[i].color = (1, 0.1, 0.1, 1) if i in pony else (0.8, 0.8, 0.8, 1)
    nt = m.node_tree; ca = nt.nodes.new("ShaderNodeVertexColor"); ca.layer_name = "pw"; nt.links.new(ca.outputs[0], nt.nodes["Principled BSDF"].inputs["Base Color"])
    body.data.materials.clear(); body.data.materials.append(m)
    blender_look.setup(sc, centre=Vector((0, 0, (a.ztop + a.zbottom) / 2)), scale=0.5)
    cam = bpy.data.objects.new("C", bpy.data.cameras.new("C")); sc.collection.objects.link(cam); sc.camera = cam
    c = Vector((0, 0.02, (a.ztop + a.zbottom) / 2)); cam.location = c + Vector((1.1, 0.6, 0.1)); cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.resolution_x = sc.render.resolution_y = 600; sc.render.filepath = a.debug; bpy.ops.render.render(write_still=True)
    print("DEBUG ->", a.debug); sys.exit()

ad = arm.animation_data or arm.animation_data_create()
have = {s.action.name for t in ad.nla_tracks for s in t.strips if s.action}
for act in bpy.data.actions:
    if act.name in have: continue
    t = ad.nla_tracks.new(); t.name = act.name; t.strips.new(act.name, int(act.frame_range[0]), act); t.mute = True
ad.action = None
bpy.ops.export_scene.gltf(filepath=a.dst, export_format="GLB", export_yup=True, export_skins=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS")
print("PONYTAIL DONE", len(ad.nla_tracks), "clips ->", a.dst)
