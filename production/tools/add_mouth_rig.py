"""Make a rigged character's closed, sculpted mouth speech ready: cut the lips apart, build a mouth (inner lip
surfaces, cavity, teeth, gums, tongue) and add viseme and expression blend shapes.

  blender -b -P add_mouth_rig.py -- <in.glb> <out.glb> [--landmarks rigs/face_landmarks.json --name CH_Kai] [--debug lipline]

AI-generated heads have the mouth as a painted, closed groove. The lip line is found as the darkest smooth path in
a flat base-colour render of the face, projected onto the mesh, and the mesh is split along it. The mouth parts are
added to the same mesh, each with its own material, so one set of shape keys drives everything:
- inner lip surfaces curl from each cut edge into the mouth, so an opening shows lip thickness, not a bare cut;
- the cavity, tongue and gums are shaded darker with depth; teeth are separate crowns on curved arches, set back
  behind the lips (upper teeth fixed to the skull, lower teeth, tongue and the cavity floor follow the jaw);
- any part that would poke through the skin is pushed back inside.
Mouth controls: jaw (an arc about the jaw hinge; at the corners both lips drop together, so the opening is
rounded and never tears), wide, pucker (corners in, lips forward), flare, upper-lip raise, lower-lip tuck,
press, neutral (relaxes the modelled smile) and tongue tip. Shape keys:
  speech: viseme_sil, PP, FF, TH, DD, kk, CH, SS, nn, RR, aa, E, I, O, U (Oculus/OVR names) and jawOpen;
  expression: exprNeutral, exprSerious, browUp, browDown, eyesBlink (never written by lip-sync).
With --landmarks (eye and brow positions marked on the standard flat face view) the script also adds eyelids
(skin-coloured, with a lash line, tucked under the upper lid at rest; eyesBlink sweeps them down over the painted
eye) and brow shapes, and searches for the lip line below the eyes.
"""
import argparse, heapq, json, math, os, sys, tempfile
import bpy, bmesh
from mathutils import Vector, Matrix
from mathutils.kdtree import KDTree
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser(); p.add_argument("src"); p.add_argument("dst"); p.add_argument("--debug")
p.add_argument("--landmarks"); p.add_argument("--name")
a = p.parse_args(argv)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
shapes = {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}
for o in shapes: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE"); AW = arm.matrix_world
me = next(o for o in sc.objects if o.type == "MESH"); M = me.matrix_world; Mi = M.inverted()
if arm.animation_data: arm.animation_data.action = None
for pb in arm.pose.bones: pb.matrix_basis.identity()
bpy.context.view_layer.update()

pristine = me.copy(); pristine.data = me.data.copy(); pristine.modifiers.clear(); sc.collection.objects.link(pristine)
P = "mixamorig:"
h0 = AW @ arm.data.bones[P + "Head"].head_local
h1 = AW @ arm.data.bones[P + "HeadTop_End"].head_local
H = h1.z - h0.z                                     # head height (base of skull to top)
LM = json.load(open(a.landmarks)).get(a.name) if a.landmarks else None
if a.landmarks and not LM: print(f"FACE: no landmarks for {a.name}; skipping eyelids and brows")
EYE_C, EYE_S = Vector((h0.x, h0.y - 0.5, h0.z + 0.20 * H)), 0.70 * H     # the standard flat face view (see the landmarks file)
def eye_world(u, v): return Vector((EYE_C.x + (u - 0.5) * EYE_S, 0, EYE_C.z + (0.5 - v) * EYE_S))

# 1) find the mouth in 2D: orthographic front render of the face, base colour only
mats = []
for m in me.data.materials:
    nt = m.node_tree
    tex = next(n for n in nt.nodes if n.type == "TEX_IMAGE" and any(l.to_socket.name == "Base Color" for l in n.outputs[0].links))
    outn = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"); old = outn.inputs[0].links[0].from_socket
    em = nt.nodes.new("ShaderNodeEmission"); nt.links.new(tex.outputs[0], em.inputs[0]); nt.links.new(em.outputs[0], outn.inputs[0])
    mats.append((nt, outn, old, em))
RES = 800
centre = Vector((h0.x, h0.y - 0.5, h0.z + 0.10 * H)); size = 0.80 * H
cam = bpy.data.objects.new("MouthCam", bpy.data.cameras.new("MouthCam")); cam.data.type = "ORTHO"; cam.data.ortho_scale = size
sc.collection.objects.link(cam); sc.camera = cam
cam.location = centre; cam.rotation_euler = Vector((0, 1, 0)).to_track_quat("-Z", "Z").to_euler()
sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE"
sc.view_settings.view_transform = "Standard"
sc.render.resolution_x = sc.render.resolution_y = RES
flat = os.path.join(tempfile.mkdtemp(), "flat.png"); sc.render.filepath = flat; bpy.ops.render.render(write_still=True)
if LM:
    cam.location, cam.data.ortho_scale = EYE_C, EYE_S
    eflat = os.path.join(os.path.dirname(flat), "eyes.png"); sc.render.filepath = eflat; bpy.ops.render.render(write_still=True)
    cam.location, cam.data.ortho_scale = centre, size
for nt, outn, old, em in mats:
    nt.links.new(old, outn.inputs[0]); nt.nodes.remove(em)
fimg = bpy.data.images.load(flat); fp = fimg.pixels[:]; FW, FH = fimg.size
def RGB(x, y):  # display-encoded colour at image pixel (x right, y down)
    i = ((FH - 1 - y) * FW + x) * 4; return fp[i], fp[i + 1], fp[i + 2]
def L2(x, y):
    r, g, b = RGB(x, y); return 0.2126 * r + 0.7152 * g + 0.0722 * b
# skin reference: median luminance of the lower-middle face
y0, y1, x0, x1 = int(RES * 0.62), int(RES * 0.86), int(RES * 0.22), int(RES * 0.78)
if LM:   # search from well below the eyes, so the lashes can never win over the lip line
    top_z = min(eye_world(e[0], e[1]).z - 2.5 * e[3] * EYE_S for e in LM["eyes"])
    y0 = max(0, int(RES * (0.5 - (top_z - centre.z) / size))); y1 = min(RES - 2, y0 + int(RES * 0.33))
skin = sorted(L2(x, y) for y in range(y0, y1, 4) for x in range(x0, x1, 4))[int(0.6 * ((y1 - y0) // 4) * ((x1 - x0) // 4))]
# lip line: the darkest smooth path across the band (dynamic programming, at most 3 px up or down per column),
# so the long smile beats short dark spots such as nostrils; then keep its longest clearly dark stretch
ys = range(y0, y1); cost = {y: L2(x0, y) for y in ys}; back = []
for x in range(x0 + 1, x1):
    nc, bk = {}, {}
    for y in ys:
        py = min((q for q in range(y - 3, y + 4) if q in cost), key=lambda q: cost[q] + 0.01 * abs(q - y))
        nc[y] = cost[py] + 0.01 * abs(py - y) + L2(x, y); bk[y] = py
    cost = nc; back.append(bk)
y = min(cost, key=cost.get); trace = {x1 - 1: y}
for x, bk in zip(range(x1 - 1, x0, -1), reversed(back)):
    y = bk[y]; trace[x - 1] = y
dark_cols = [x for x in sorted(trace) if L2(x, trace[x]) < 0.72 * skin]
runs, cur = [], []
for x in dark_cols:
    if cur and x - cur[-1] > 4: runs.append(cur); cur = []
    cur.append(x)
runs.append(cur); stroke = max(runs, key=len)
# the stroke fades out at the corners: end the cut where the line is still clearly dark, or it overshoots the painted mouth
while len(stroke) > 20 and L2(stroke[-1], trace[stroke[-1]]) > 0.62 * skin: stroke.pop()
while len(stroke) > 20 and L2(stroke[0], trace[stroke[0]]) > 0.62 * skin: stroke.pop(0)
line = trace
# lip tone: median colour just above and below the line over the middle of the mouth
mid = stroke[len(stroke) // 4: 3 * len(stroke) // 4]
tone = [sorted(RGB(x, line[x] + d)[c] for x in mid[::2] for d in (-9, -7, -5, 5, 7, 9))[len(mid) * 3 // 2] for c in range(3)]
print(f"MOUTH 2D: columns {stroke[0]}-{stroke[-1]} ({len(stroke)} px), skin lum {skin:.2f}, lip tone {[round(c, 2) for c in tone]}")
# 2) project the stroke onto the mesh
dg = bpy.context.evaluated_depsgraph_get()
def to_world(x, y):
    u, v = (x + 0.5) / RES - 0.5, 0.5 - (y + 0.5) / RES
    return centre + Vector((u * size, 0, v * size))
poly = []
for x in stroke[::2]:
    hit, loc, *_ = sc.ray_cast(dg, to_world(x, line[x]), Vector((0, 1, 0)))
    if hit: poly.append(loc)
cl, cr = poly[0], poly[-1]
print(f"MOUTH corners {[round(c, 3) for c in cl]} {[round(c, 3) for c in cr]}, width {(cr - cl).length * 100:.1f} cm")
# 3) mesh path along the projected stroke: Dijkstra, edge cost grows with distance from the stroke
bm = bmesh.new(); bm.from_mesh(me.data); bm.verts.ensure_lookup_table(); bm.edges.ensure_lookup_table()
kd = KDTree(len(poly))
for i, q in enumerate(poly): kd.insert(q, i)
kd.balance()
width = (cr - cl).length
# the importer splits vertices along UV seams: rejoin them around the mouth so the cut can run across a seam
# (UVs are stored per face corner, so merging keeps them)
bmesh.ops.remove_doubles(bm, verts=[v for v in bm.verts if kd.find(M @ v.co)[2] < 1.5 * width], dist=1e-5)
bm.verts.ensure_lookup_table(); bm.edges.ensure_lookup_table()
# the head is sparsely meshed: subdivide the faces around the stroke twice so the cut can follow it closely
for _ in range(2):
    zf = [f for f in bm.faces if kd.find(M @ f.calc_center_median())[2] < 0.30 * width]
    bmesh.ops.subdivide_edges(bm, edges=list({e for f in zf for e in f.edges}), cuts=1, use_grid_fill=True)
    bm.verts.ensure_lookup_table(); bm.edges.ensure_lookup_table()
# faces bordering the subdivided area gained a vertex on one edge: triangulate every non-triangle cleanly so
# none is left for the exporter to split into slivers
bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 3], quad_method="BEAUTY", ngon_method="BEAUTY")
bm.verts.ensure_lookup_table(); bm.edges.ensure_lookup_table()
wpos = {v.index: M @ v.co for v in bm.verts}
near = [v for v in bm.verts if kd.find(wpos[v.index])[2] < 0.25 * width]
nset = {v.index for v in near}
def nearest(q): return min(near, key=lambda v: (wpos[v.index] - q).length)
s0, s1 = nearest(cl), nearest(cr)
dist, prev, pq = {s0.index: 0.0}, {}, [(0.0, s0.index)]
while pq:
    d, i = heapq.heappop(pq)
    if i == s1.index: break
    if d > dist.get(i, 1e9): continue
    for e in bm.verts[i].link_edges:
        j = e.other_vert(bm.verts[i]).index
        if j not in nset: continue
        c = e.calc_length() * (1 + (kd.find(wpos[j])[2] / (0.01 * width)) ** 2)
        if d + c < dist.get(j, 1e9):
            dist[j] = d + c; prev[j] = i; heapq.heappush(pq, (d + c, j))
if s1.index not in prev:
    sys.exit("MOUTH: the lip line crosses separate mesh pieces; cannot cut along one edge path")
path = [s1.index]
while path[-1] != s0.index: path.append(prev[path[-1]])
path = path[::-1]
print(f"LIP LINE {len(path)} vertices, max distance from stroke {max(kd.find(wpos[i])[2] for i in path) * 1000:.1f} mm")

if a.debug == "lipline":
    sc.view_settings.view_transform = "AgX" if "AgX" in [t.identifier for t in bpy.types.ColorManagedViewSettings.bl_rna.properties["view_transform"].enum_items] else "Filmic"
    red = bpy.data.materials.new("DBG"); red.use_nodes = True
    red.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (1, 0, 0, 1)
    red.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 4
    for i in path:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.0012 * H / 0.18, location=wpos[i]); bpy.context.object.data.materials.append(red)
    w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    cam.data.type = "PERSP"; cam.data.lens = 85; sc.render.resolution_x = sc.render.resolution_y = 700
    c = (cl + cr) / 2
    cam.location = c + Vector((0, -1.3 * H, 0.1 * H)); cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = f"{a.debug}_lipline.png"; bpy.ops.render.render(write_still=True)
    sys.exit()

# 4) snap the path onto the stroke and split the mesh along it (the two corner vertices stay joined)
def on_stroke(q):
    best = None
    for p0, p1 in zip(poly, poly[1:]):
        d = p1 - p0; t = max(0.0, min(1.0, (q - p0).dot(d) / d.length_squared)); c = p0 + d * t
        if best is None or (c - q).length < (best - q).length: best = c
    return best
for i in path[1:-1]:
    bm.verts[i].co = Mi @ on_stroke(wpos[i]); wpos[i] = M @ bm.verts[i].co
pedges = [bm.edges.get((bm.verts[i], bm.verts[j])) for i, j in zip(path, path[1:])]
bmesh.ops.split_edges(bm, edges=pedges)
bm.verts.ensure_lookup_table(); bm.verts.index_update()
cx = (cl.x + cr.x) / 2; cz = sum(q.z for q in poly) / len(poly); front = sum(q.y for q in poly) / len(poly)
xs = [q.x for q in poly]
def line_z(x):
    x = min(max(x, xs[0]), xs[-1])
    for p0, p1 in zip(poly, poly[1:]):
        if p0.x <= x <= p1.x: return p0.z + (p1.z - p0.z) * (x - p0.x) / max(1e-9, p1.x - p0.x)
    return cz
mid_z = line_z(cx); smile = (line_z(xs[0]) + line_z(xs[-1])) / 2 - mid_z   # > 0: the corners are modelled raised
# lip sides by topology: inside the mouth span the cut separates upper from lower, so flood-fill the lower
# side from vertices well below the line without crossing the cut (heights alone mislabel faces at the cut)
band = {v.index for v in bm.verts
        if cl.x + 0.01 * width < (M @ v.co).x < cr.x - 0.01 * width and abs((M @ v.co).z - line_z((M @ v.co).x)) < 0.25 * width
        and (M @ v.co).y < front + 0.3 * width}
seeds = [i for i in band if (M @ bm.verts[i].co).z < line_z((M @ bm.verts[i].co).x) - 0.12 * width]
lower_ids, stack = set(seeds), list(seeds)
while stack:
    v = bm.verts[stack.pop()]
    for e in v.link_edges:
        o = e.other_vert(v).index
        if o in band and o not in lower_ids: lower_ids.add(o); stack.append(o)
upper_ids = band - lower_ids
# the two cut edges as ordered chains, corner to corner
cut = [v for v in bm.verts if v.is_boundary and kd.find(M @ v.co)[2] < 0.05 * width and v not in (s0, s1)]
up_chain = [s0] + sorted((v for v in cut if v.index not in lower_ids), key=lambda v: (M @ v.co).x) + [s1]
lo_chain = [s0] + sorted((v for v in cut if v.index in lower_ids), key=lambda v: (M @ v.co).x) + [s1]
up_chain = [(v.index, M @ v.co) for v in up_chain]; lo_chain = [(v.index, M @ v.co) for v in lo_chain]
print(f"CUT: split {len(pedges)} edges; mouth band {len(band)} vertices: {len(lower_ids)} lower, {len(upper_ids)} upper; "
      f"edges {len(up_chain)} upper / {len(lo_chain)} lower; smile {smile * 1000:.1f} mm")
bm.to_mesh(me.data); me.data.update(); bm.free()
# restore the original shading: copy custom normals from the untouched mesh (the subdivided mouth area gets
# interpolated normals instead of stale ones, everything else is unchanged)
bpy.ops.object.select_all(action="DESELECT"); bpy.context.view_layer.objects.active = me; me.select_set(True)
dt = me.modifiers.new("NormalsFromOriginal", "DATA_TRANSFER"); dt.object = pristine
dt.use_loop_data = True; dt.data_types_loops = {"CUSTOM_NORMAL"}; dt.loop_mapping = "POLYINTERP_NEAREST"
bpy.ops.object.modifier_move_to_index(modifier=dt.name, index=0)
bpy.ops.object.modifier_apply(modifier=dt.name)
bpy.data.objects.remove(pristine)
n_face = len(me.data.vertices)
skin_bvh = BVHTree.FromPolygons([M @ v.co for v in me.data.vertices], [list(f.vertices) for f in me.data.polygons])

# 5) mouth parts, added to the same mesh, weighted to the head
head_vg = me.vertex_groups[P + "Head"]; UVN = me.data.uv_layers.active.name
def gradient(name, rows, w=4):
    """A small vertical gradient texture (v = 0 at the first colour), colours display-encoded like the base map."""
    img = bpy.data.images.new(name, w, len(rows)); px = []
    for r in rows: px += [*r, 1.0] * w
    img.pixels[:] = px; img.pack(); return img
def material(name, rows, rough):
    mat = bpy.data.materials.new(name); mat.use_nodes = True; mat.use_backface_culling = False   # exported double-sided
    nt = mat.node_tree; bs = nt.nodes["Principled BSDF"]; bs.inputs["Roughness"].default_value = rough
    tx = nt.nodes.new("ShaderNodeTexImage"); tx.image = gradient(name + "_ramp", rows); tx.interpolation = "Linear"
    nt.links.new(tx.outputs[0], bs.inputs["Base Color"]); return mat
def ramp(c0, c1, n=32): return [[c0[k] + (c1[k] - c0[k]) * t / (n - 1) for k in range(3)] for t in range(n)]
lip_in = [tone[0] * 0.92, tone[1] * 0.78, tone[2] * 0.78]
MAT = {"lip": material("LipInner", ramp(lip_in, [lip_in[0] * 0.75, lip_in[1] * 0.45, lip_in[2] * 0.45], 16) + ramp([lip_in[0] * 0.75, lip_in[1] * 0.45, lip_in[2] * 0.45], [0.30, 0.10, 0.10], 16), 0.45),
       "cavity": material("MouthInterior", ramp([0.55, 0.24, 0.24], [0.10, 0.035, 0.035]), 0.6),
       "teeth": material("Teeth", ramp([0.97, 0.96, 0.92], [0.78, 0.76, 0.70]), 0.3),
       "gum": material("Gums", ramp([0.74, 0.40, 0.40], [0.45, 0.20, 0.20]), 0.45),
       "tongue": material("Tongue", ramp([0.66, 0.33, 0.33], [0.32, 0.12, 0.12]), 0.4)}
def keep_inside(v, gap=0.0025):
    """Push a part vertex back (+y) until it sits behind the skin: nothing may poke through the lips or chin."""
    hit = skin_bvh.ray_cast(Vector((v.x, front - 0.5, v.z)), Vector((0, 1, 0)), 1.0)
    if hit[0] is not None and v.y < hit[0].y + gap: v.y = hit[0].y + gap; return 1
    return 0
pushed = {}
def add_part(name, mat, pid, build):
    b2 = bmesh.new(); uv = b2.loops.layers.uv.new(UVN); parent = build(b2, uv) or {}
    b2.verts.index_update()
    pushed[name] = sum(keep_inside(v.co) for v in b2.verts) if pid not in (5, 6, 9) else 0
    for v in b2.verts: v.co = Mi @ v.co
    tmp = bpy.data.meshes.new(name); b2.to_mesh(tmp); b2.free()
    o = bpy.data.objects.new(name, tmp); sc.collection.objects.link(o); o.data.materials.append(mat)
    o.vertex_groups.new(name=head_vg.name).add(list(range(len(tmp.vertices))), 1.0, "REPLACE")
    ap = tmp.attributes.new("mr_part", "INT", "POINT"); apar = tmp.attributes.new("mr_parent", "INT", "POINT")
    for i in range(len(tmp.vertices)): ap.data[i].value = pid; apar.data[i].value = parent.get(i, -1)
    return o
def skirt(chain, sign):
    """Inner lip surface: three rings from the cut edge into the mouth, curling away from the other lip."""
    def build(b2, uv):
        rings, n = [], len(chain)
        for fi, q in chain:
            ax = min(1.0, abs(q.x - cx) / (0.5 * width)); t = 0.35 + 0.65 * (1 - ax * ax)
            rings.append([b2.verts.new(q + Vector((0, dy * width * t, sign * dz * width * t))) for dy, dz in ((0, 0), (0.035, 0.012), (0.085, 0.032))])
        for j in range(n - 1):
            for k in range(2):
                f = b2.faces.new((rings[j][k], rings[j + 1][k], rings[j + 1][k + 1], rings[j][k + 1]))
                for loop, (jj, kk) in zip(f.loops, ((j, k), (j + 1, k), (j + 1, k + 1), (j, k + 1))): loop[uv].uv = (jj / (n - 1), kk / 2)
        b2.normal_update()
        for f in b2.faces:
            if f.normal.z * sign > 0: f.normal_flip()   # face the opening
        b2.verts.index_update()
        return {v.index: chain[j][0] for j, r in enumerate(rings) for v in r}
    return build
def ellipsoid(c, r, segs=(24, 14), flat_top=1.0):
    def build(b2, uv):
        bmesh.ops.create_uvsphere(b2, u_segments=segs[0], v_segments=segs[1], radius=1.0)
        for v in b2.verts:
            k = flat_top if v.co.z > 0 else 1.0
            v.co = Vector((c.x + v.co.x * r.x, c.y + v.co.y * r.y, c.z + v.co.z * r.z * k))
        for f in b2.faces:
            for loop in f.loops: loop[uv].uv = (0.5, min(1.0, max(0.0, (loop.vert.co.y - (c.y - r.y)) / (2 * r.y))))
    return build
def cavity(build_ok=True):
    """Mouth cavity: an open-fronted tube from just behind the lips to a rounded back, deeper below than above,
    so the teeth and tongue sit inside it and nothing behind the lips is ever see-through."""
    def build(b2, uv):
        rings, nseg, nrng = [], 20, 9
        for r in range(nrng):
            t = r / (nrng - 1); y = front + (0.07 + 0.58 * t) * width
            hw, hu, hd = 0.56 * width * (1 - 0.45 * t * t), 0.22 * width * (1 - 0.3 * t), 0.34 * width * (1 - 0.4 * t)
            ring = []
            for k in range(nseg):
                th = 2 * math.pi * k / nseg; sn = math.sin(th)
                ring.append(b2.verts.new(Vector((cx + math.cos(th) * hw, y, mid_z - 0.03 * width + sn * (hu if sn > 0 else hd)))))
            rings.append((ring, t))
        for (ra, ta), (rb, tb) in zip(rings, rings[1:]):
            for k in range(nseg):
                f = b2.faces.new((ra[k], ra[(k + 1) % nseg], rb[(k + 1) % nseg], rb[k]))
                for loop, tt in zip(f.loops, (ta, ta, tb, tb)): loop[uv].uv = (0.5, tt)
        cap = b2.verts.new(sum((v.co for v in rings[-1][0]), Vector()) / nseg + Vector((0, 0.04 * width, 0)))
        for k in range(nseg):
            f = b2.faces.new((rings[-1][0][k], rings[-1][0][(k + 1) % nseg], cap))
            for loop in f.loops: loop[uv].uv = (0.5, 1.0)
    return build
def arch_y(x, y0): return y0 + 0.83 * (x - cx) ** 2 / width
def teeth(y0, edge, height, upper):
    """Separate crowns along a curved arch: central and lateral incisors, canine, first premolar each side."""
    def build(b2, uv):
        for s in (-1, 1):
            x = 0.001 * width
            for k, wf in enumerate((0.125, 0.105, 0.10, 0.095) if upper else (0.10, 0.095, 0.095, 0.095)):
                tw = wf * width; xc = cx + s * (x + tw / 2); x += tw + 0.001 * width
                th, hh = 0.055 * width, height * (1 - 0.1 * k)
                zc = edge + hh / 2 if upper else edge - hh / 2
                ang = math.atan(2 * 0.83 * (xc - cx) / width)
                mtx = Matrix.Translation((xc, arch_y(xc, y0) + th / 2, zc)) @ Matrix.Rotation(ang, 4, "Z") @ Matrix.Diagonal((tw, th, hh, 1))
                cube = bmesh.ops.create_cube(b2, size=1.0, matrix=mtx)["verts"]
                es = list({e for v in cube for e in v.link_edges})
                bmesh.ops.bevel(b2, geom=es, offset=0.14 * min(tw, th), segments=2, affect="EDGES", profile=0.6)
        for f in b2.faces:
            for loop in f.loops:
                q = loop.vert.co; loop[uv].uv = (0.5, min(1.0, abs(q.x - cx) / (0.55 * width) * 0.8 + max(0.0, q.y - y0) / (0.2 * width) * 0.2))
    return build
def gum(y0, z_lo, z_hi):
    def build(b2, uv):
        cols = 17; grid = []
        for i in range(cols):
            xx = cx + (i / (cols - 1) - 0.5) * 0.76 * width; row = []
            for j, zz in enumerate((z_lo, (z_lo + z_hi) / 2, z_hi)):
                row.append(b2.verts.new(Vector((xx, arch_y(xx, y0) + 0.01 * width - 0.006 * width * (j == 1), zz))))
            grid.append(row)
        for i in range(cols - 1):
            for j in range(2):
                f = b2.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
                for loop in f.loops: loop[uv].uv = (0.5, min(1.0, abs(loop.vert.co.x - cx) / (0.5 * width)))
    return build
lid_full = []
def eyelids(build_ok=True):
    """Per eye: a 13 x 7 patch over the eye opening, projected onto the face 0.8 mm in front of it. At rest it is
    folded into a thin strip tucked 1.5 mm under the upper lid; eyesBlink unfolds it down over the eye."""
    def build(b2, uv):
        cols, rows = 13, 7
        for e in LM["eyes"]:
            c = eye_world(e[0], e[1]); ew, eh = e[2] * EYE_S, e[3] * EYE_S; grid = []
            for j in range(cols):
                t = -1 + 2 * j / (cols - 1); xx = c.x + 1.08 * ew * t; arc = math.sqrt(max(0.0, 1 - t * t))
                top, bot = c.z + 1.3 * eh * arc, c.z - 1.15 * eh * arc
                col_pts = []
                for k in range(rows):
                    zz = top + (bot - top) * k / (rows - 1)
                    hit = skin_bvh.ray_cast(Vector((xx, front - 0.5, zz)), Vector((0, 1, 0)), 1.0)
                    col_pts.append((hit[0] if hit[0] is not None else Vector((xx, front, zz))) + Vector((0, -0.0008, 0)))
                row = []
                for k, q in enumerate(col_pts):
                    rest = col_pts[0] + (q - col_pts[0]) * 0.1 + Vector((0, 0.0015, 0))
                    row.append(b2.verts.new(rest)); lid_full.append(q)
                grid.append(row)
            for j in range(cols - 1):
                for k in range(rows - 1):
                    f = b2.faces.new((grid[j][k], grid[j + 1][k], grid[j + 1][k + 1], grid[j][k + 1]))
                    for loop, (jj, kk) in zip(f.loops, ((j, k), (j + 1, k), (j + 1, k + 1), (j, k + 1))): loop[uv].uv = (jj / (cols - 1), kk / (rows - 1))
    return build
up_edge, lo_edge = mid_z - 0.03 * width, mid_z - 0.06 * width
y_up, y_lo = front + 0.10 * width, front + 0.135 * width
parts = [
    add_part("LipInnerUpper", MAT["lip"], 5, skirt(up_chain, +1)),
    add_part("LipInnerLower", MAT["lip"], 6, skirt(lo_chain, -1)),
    add_part("MouthInterior", MAT["cavity"], 1, cavity()),
    add_part("TeethUpper", MAT["teeth"], 2, teeth(y_up, up_edge, 0.24 * width, True)),
    add_part("TeethLower", MAT["teeth"], 3, teeth(y_lo, lo_edge, 0.19 * width, False)),
    add_part("GumUpper", MAT["gum"], 7, gum(y_up, up_edge + 0.20 * width, up_edge + 0.31 * width)),
    add_part("GumLower", MAT["gum"], 8, gum(y_lo, lo_edge - 0.16 * width, lo_edge - 0.27 * width)),
    add_part("Tongue", MAT["tongue"], 4, ellipsoid(Vector((cx, front + 0.50 * width, lo_edge - 0.085 * width)), Vector((0.29 * width, 0.30 * width, 0.09 * width)), (16, 10), 0.7))]
if LM:   # lid skin: the colour just above each upper lid in the flat eye view; dark lash line along the lid edge
    eimg = bpy.data.images.load(eflat); ep = eimg.pixels[:]; EW, EH = eimg.size
    def ergb(u, v): x, y = int(u * (EW - 1)), int(v * (EH - 1)); i = ((EH - 1 - y) * EW + x) * 4; return ep[i:i + 3]
    samp = [ergb(e[0] + du * e[2], e[1] - dv * e[3]) for e in LM["eyes"] for du in (-0.4, -0.2, 0.0, 0.2, 0.4) for dv in (2.3, 2.6)]   # brow-bone skin, above the crease shadow
    lid = [sorted(c[k] for c in samp)[len(samp) // 2] for k in range(3)]
    lash = [0.10, 0.07, 0.06]
    MAT["lid"] = material("Eyelid", ramp([c * 0.98 for c in lid], [min(1.0, c * 1.03) for c in lid], 20) + ramp(lid, [c * 0.8 for c in lid], 6) + ramp([c * 0.6 for c in lid], lash, 6), 0.5)
    parts.append(add_part("Eyelids", MAT["lid"], 9, eyelids()))
print("PARTS pushed inside the skin:", {k: v for k, v in pushed.items() if v})
bpy.ops.object.select_all(action="DESELECT")
for o in parts: o.select_set(True)
me.select_set(True); bpy.context.view_layer.objects.active = me
bpy.ops.object.join()
me = bpy.context.view_layer.objects.active; M = me.matrix_world; Mi = M.inverted()
part = [d.value for d in me.data.attributes["mr_part"].data]; parent = [d.value for d in me.data.attributes["mr_parent"].data]
for nm in ("mr_part", "mr_parent"): me.data.attributes.remove(me.data.attributes[nm])

# 6) mouth controls: per-vertex weights, then each shape key is a mix of controls
V = [M @ v.co for v in me.data.vertices]
hinge = Vector((cx, h0.y, mid_z + 0.5 * width))
chin_z = min(q.z for q in V[:n_face] if abs(q.x - cx) < 0.3 * width and q.y < front + 0.3 * width and q.z > mid_z - 1.6 * width)
tongue_front = min(q.y for i, q in enumerate(V) if part[i] == 4)
corners = (Vector((xs[0], 0, line_z(xs[0]))), Vector((xs[-1], 0, line_z(xs[-1]))))
def smooth(t): t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)
N = len(V); wj, fl, fp, fpi, lo, cf, chf, tip, lf = ([0.0] * N for _ in range(9))
for i, q in enumerate(V[:n_face]):
    d = line_z(q.x) - q.z                               # > 0 below the lip line
    ax = abs(q.x - cx) / (0.5 * width); beyond = max(0.0, abs(q.x - cx) - 0.5 * width)
    # jaw weight at the lip line: the lower lip follows the jaw, the upper lip stays, and toward the corners both
    # lips share 0.4, so the opening is an ellipse whose corners drop with the jaw instead of tearing
    e = 1 - math.sqrt(max(0.0, 1 - min(1.0, ax) ** 2)); Lc, Uc = 1 - 0.6 * e, 0.4 * e
    lower = i in lower_ids or (i not in upper_ids and d > 0)
    if lower: w = Lc + (1 - Lc) * smooth(d / (0.25 * width + 1.5 * beyond))
    else: w = Uc * smooth(1 + d / (0.35 * width))
    lat = smooth(1 - beyond / (1.0 * width))
    neck = smooth((q.z - (chin_z - 0.25 * width)) / (0.3 * width)) if q.z > mid_z - 2.0 * width else 0.0
    depth = smooth((hinge.y - q.y) / (0.4 * width))
    wj[i] = w * lat * neck * depth
    lf[i] = math.sqrt(max(0.0, 1 - min(1.0, ax) ** 2))   # opening profile: 1 mid-mouth, 0 at and past the corners
    lo[i] = 1.0 if i in lower_ids else 0.0 if i in upper_ids else smooth(0.5 + d / (0.2 * width))
    front_f = smooth((front + 0.6 * width - q.y) / (0.3 * width))
    fl[i] = smooth(1 - math.hypot((q.x - cx) / (0.9 * width), (q.z - cz) / (0.55 * width))) * front_f
    fp[i] = smooth(1 - math.hypot((q.x - cx) / (1.35 * width), (q.z - cz) / (0.8 * width))) * front_f
    fpi[i] = smooth(1 - math.hypot((q.x - cx) / (0.75 * width), (q.z - cz) / (0.45 * width))) * front_f
    cf[i] = max(smooth(1 - math.hypot(q.x - c.x, q.z - c.z) / (0.55 * width)) for c in corners) * front_f
    chf[i] = smooth(1 - math.hypot((q.x - cx) / (0.6 * width), (q.z - (mid_z - 0.75 * width)) / (0.45 * width))) * front_f
skin_kd = KDTree(n_face)
for i, q in enumerate(V[:n_face]): skin_kd.insert(q, i)
skin_kd.balance()
for i, q in enumerate(V):
    if i < n_face: continue
    pid = part[i]
    if pid in (5, 6):                                    # inner lips move exactly like their cut edge
        j = parent[i]; wj[i], fl[i], fp[i], fpi[i], lo[i], cf[i], lf[i] = wj[j], fl[j], fp[j], fpi[j], lo[j], cf[j], lf[j]
    elif pid in (3, 4): wj[i] = 1.0                      # lower teeth and tongue follow the jaw
    elif pid in (7, 8):                                  # gums move like the skin in front of them
        j = skin_kd.find(q)[1]; wj[i], fl[i], fp[i], fpi[i], lo[i], cf[i], chf[i], lf[i] = (arr[j] for arr in (wj, fl, fp, fpi, lo, cf, chf, lf))
        if pid == 8: wj[i] = 1.0
    elif pid == 1:                                      # cavity: roof stays, floor follows; narrows with a pucker
        own = smooth((mid_z + 0.25 * width - q.z) / (0.5 * width))
        k = smooth(1 - (q.y - front - 0.07 * width) / (0.2 * width)); j = skin_kd.find(q)[1]
        wj[i] = k * wj[j] + (1 - k) * own; fp[i] = k * fp[j] + (1 - k) * 0.65
        fl[i], fpi[i], lo[i], cf[i], chf[i], lf[i] = (k * arr[j] for arr in (fl, fpi, lo, cf, chf, lf))
    if pid == 4: tip[i] = smooth((tongue_front + 0.30 * width - q.y) / (0.30 * width))
brow = [0.0] * N; brow_in = [0.0] * N; lid_off = {}
if LM:
    for e, bp in zip(LM["eyes"], LM["brows"]):
        c, b = eye_world(e[0], e[1]), eye_world(bp[0], bp[1]); ew, eh = e[2] * EYE_S, e[3] * EYE_S
        face_y = skin_bvh.ray_cast(Vector((b.x, front - 0.5, b.z)), Vector((0, 1, 0)), 1.0)[0]
        fy = face_y.y if face_y is not None else front
        for i, q in enumerate(V[:n_face]):
            w = smooth(1 - math.hypot((q.x - b.x) / (1.6 * ew), (q.z - b.z) / (2.2 * eh))) * smooth((q.z - (c.z + 0.9 * eh)) / (0.8 * eh)) * smooth((fy + 0.03 - q.y) / 0.015)
            if w > brow[i]: brow[i] = w; brow_in[i] = math.copysign(1.0, cx - b.x) * ew
    BROW_H = sum(e[3] for e in LM["eyes"]) / len(LM["eyes"]) * EYE_S   # eye half-height: the brow shapes scale with the face
    lid_ids = [i for i in range(N) if part[i] == 9]
    lid_off = {i: lid_full[k] - V[i] for k, i in enumerate(lid_ids)}
def offsets(jaw=0, wide=0, pucker=0, flare=0, uplip=0, tuck=0, press=0, neutral=0, tongue=0, tonguefwd=0, browup=0, browdown=0, blink=0):
    R = Matrix.Rotation(math.radians(jaw), 3, "X"); out = []
    for i, q in enumerate(V):
        o = Vector()
        if brow[i] and (browup or browdown):   # lift; or lower and draw toward the nose (a frown)
            o.z += (browup * 0.65 - browdown * 0.40) * BROW_H * brow[i]; o.x += browdown * 0.12 * brow_in[i] * brow[i]
        if blink and i in lid_off: o += lid_off[i] * blink
        if wj[i] and jaw: o += (R @ (q - hinge) + hinge - q) * wj[i]
        up = 1 - lo[i]; sx = max(-1.0, min(1.0, (q.x - cx) / (0.5 * width)))
        if fl[i]:
            o += Vector((wide * 0.20 * width * sx, wide * 0.035 * width * abs(sx), wide * 0.035 * width * abs(sx))) * fl[i]
            o.z += (uplip * 0.065 * up + tuck * 0.075 * lo[i] - press * 0.016 * up + press * 0.016 * lo[i]) * width * fl[i] * lf[i]
            o.y += (tuck * 0.11 * lo[i] * lf[i] - press * 0.02) * width * fl[i]
        if fp[i] and pucker:
            dx = q.x - cx; ad = abs(dx)
            o.x -= pucker * 0.58 * (dx if ad < 0.5 * width else math.copysign(0.5 * width, dx) * smooth(1 - (ad - 0.5 * width) / (0.5 * width))) * fp[i]
            o.y -= pucker * 0.26 * width * fpi[i]
        if fpi[i] and flare: o.z += flare * 0.05 * width * (up - lo[i]) * fpi[i] * lf[i]
        if cf[i] and neutral: o.z -= neutral * 1.0 * smile * cf[i]
        if chf[i] and press: o.z += press * 0.025 * width * chf[i]
        if tip[i]: o += Vector((0, -0.04 * tongue - 0.15 * tonguefwd, 0.14 * tongue + 0.15 * tonguefwd)) * width * tip[i]
        out.append(o)
    return out
SHAPES = {
    "viseme_sil": {}, "viseme_PP": {"press": 1, "neutral": 0.3},
    "viseme_FF": {"jaw": 3, "tuck": 1, "uplip": 0.45, "neutral": 0.3},
    "viseme_TH": {"jaw": 6, "tonguefwd": 1, "neutral": 0.3}, "viseme_DD": {"jaw": 7, "tongue": 0.8, "wide": 0.1, "neutral": 0.3},
    "viseme_kk": {"jaw": 8, "wide": 0.15, "neutral": 0.3}, "viseme_CH": {"jaw": 5, "pucker": 0.5, "uplip": 0.35, "neutral": 0.4},
    "viseme_SS": {"jaw": 3, "wide": 0.35, "uplip": 0.3, "neutral": 0.2}, "viseme_nn": {"jaw": 6, "tongue": 1, "neutral": 0.3},
    "viseme_RR": {"jaw": 6, "pucker": 0.45, "neutral": 0.4}, "viseme_aa": {"jaw": 16, "neutral": 0.4},
    "viseme_E": {"jaw": 7, "wide": 0.5, "uplip": 0.3}, "viseme_I": {"jaw": 5, "wide": 0.6, "uplip": 0.2},
    "viseme_O": {"jaw": 10, "pucker": 0.75, "flare": 0.6, "neutral": 0.6}, "viseme_U": {"jaw": 5, "pucker": 1.0, "flare": 0.7, "neutral": 0.8},
    "jawOpen": {"jaw": 20},
    "exprNeutral": {"neutral": 1}, "exprSerious": {"neutral": 1.3, "press": 0.3, "browdown": 0.4},
    "browUp": {"browup": 1}, "browDown": {"browdown": 1}, "eyesBlink": {"blink": 1},
}
if not LM:
    for k in ("browUp", "browDown", "eyesBlink"): SHAPES.pop(k)
    SHAPES["exprSerious"].pop("browdown")
me.shape_key_add(name="Basis", from_mix=False)
Mi3 = Mi.to_3x3()
for name, ctl in SHAPES.items():
    k = me.shape_key_add(name=name, from_mix=False); k.value = 0.0   # rest = closed mouth (exported as the default weight)
    if ctl:
        for i, o in enumerate(offsets(**ctl)):
            if o.length_squared: k.data[i].co = me.data.vertices[i].co + Mi3 @ o
print(f"SHAPES {len(SHAPES)} keys on {len(V)} vertices; jaw region {sum(1 for w in wj[:n_face] if w > 0.5)} vertices, "
      f"chin {(mid_z - chin_z) * 100:.1f} cm below the mouth, lowest moved vertex z {min((V[i].z for i, w in enumerate(wj) if w > 0.01), default=0):.3f}")
bpy.ops.export_scene.gltf(filepath=a.dst, export_format="GLB", export_yup=True, export_skins=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS", export_morph=True)
print("MOUTH RIG ->", a.dst)
