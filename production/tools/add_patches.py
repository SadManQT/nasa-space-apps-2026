"""Replace the AI-painted sleeve patches with crisp patch layers: the Bangladesh flag on the LEFT upper sleeve and the
round Aurora patch on the RIGHT upper sleeve (production/concept/patches, tools/make_patches.py).

  blender -b -P add_patches.py -- <in.glb> <patch_dir> <out.glb> [--debug out.png]

The painted placeholder is found by colour on the outer side of each upper arm (rays from the side, texture sampled
at each hit): flag green/red on the left, patch yellow on the right. A layer grid is moulded over it, 1 mm off the
sleeve, filled with the sleeve colour around the patch so no trace of the placeholder shows, and bound to the upper
arm bone. Unambiguous green/red flags on safe garment UVs (including copies on the back or wrong arm) are
painted back to the fabric around them. Ambiguous details and protected UVs are left for review.
Every clip is kept (NLA tracks).

EVA suits (M3-3A) add three options. --fabric light lets the off-white suit fabric (not only navy) fill painted-out flags. --chest moulds the round Aurora patch onto the RIGHT chest (PatchAuroraChest, 6 cm,
beside the chest control pack), the 25 Oct lock that the approved sheets drew on the wrong side or left out (decision 4).
--pack paints the life-support pack back to its own navy wherever Tripo copied a large light mark onto it (the white
shoulder dome of the arm-free side views, a flag); its small grey details stay.
"""
import argparse, math, os, sys
import bpy, numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.interpolate import poly_3d_calc

a = argparse.ArgumentParser(); a.add_argument("src"); a.add_argument("patches"); a.add_argument("dst"); a.add_argument("--debug")
a.add_argument("--chest", action="store_true"); a.add_argument("--pack", action="store_true")
a.add_argument("--fabric", choices=("navy", "light"), default="navy")   # light: the off-white EVA suit also donates fill
a = a.parse_args(sys.argv[sys.argv.index("--") + 1:])
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE"); body = bpy.data.objects["Body"]
arm.data.pose_position = "REST"; bpy.context.view_layer.update()
mw = body.matrix_world; me = body.data
tree = BVHTree.FromPolygons([mw @ v.co for v in me.vertices], [p.vertices[:] for p in me.polygons])
img = next(n.image for n in body.active_material.node_tree.nodes if n.type == "TEX_IMAGE" and n.image and n.outputs["Color"].links
           and any(l.to_socket.name == "Base Color" for l in n.outputs["Color"].links))
W, H = img.size; px = np.empty(W * H * 4, np.float32); img.pixels.foreach_get(px); px = px.reshape(H, W, 4)
uvl = me.uv_layers.active.data

def colour_at(loc, face):
    poly = me.polygons[face]; vs = [mw @ me.vertices[i].co for i in poly.vertices]
    w = poly_3d_calc(vs, loc); u = sum(wi * uvl[li].uv[0] for wi, li in zip(w, poly.loop_indices)); v = sum(wi * uvl[li].uv[1] for wi, li in zip(w, poly.loop_indices))
    return px[int(min(max(v, 0), 0.9999) * H), int(min(max(u, 0), 0.9999) * W), :3]   # sRGB-encoded 0..1

def bone_pts(name):
    b = next(b for b in arm.data.bones if b.name.endswith(name)); return arm.matrix_world @ b.head_local, arm.matrix_world @ b.tail_local, b.name

def frame(side):
    s0, s1, _ = bone_pts(f"{side}Arm"); along = (s1 - s0).normalized()
    out = Vector((1 if side == "Left" else -1, 0, 0)); out = (out - along * out.dot(along)).normalized()
    return s0, s1, along, out, along.cross(out).normalized()

def radial_hit(s0, along, out, across, t, th):
    """Ray from outside the sleeve toward the arm's axis at height t along the bone and angle th around it."""
    r = out * math.cos(th) + across * math.sin(th); o = s0 + along * t
    return tree.ray_cast(o + r * 0.25, -r), r

def find_patch(side, test):
    """Scan around the outer half of the upper arm; return the placeholder's centre (t, angle), half-extents in metres
    of arc and length, the arm radius there and the sleeve colour."""
    s0, s1, along, out, across = frame(side); L = (s1 - s0).length
    hits, sleeve = [], []
    for i in range(48):
        for j in range(-54, 55):
            t, th = L * (0.0 + 0.76 * i / 47), math.radians(2.5 * j)
            (loc, nrm, face, _), r = radial_hit(s0, along, out, across, t, th)
            if loc is None: continue
            c = colour_at(loc, face); rad = (loc - (s0 + along * t)).length
            (hits if test(c) else sleeve).append((t, th, rad, c))
    if not hits: return None
    # keep the largest connected cluster on the scan grid (shoulder tabs, straps and the like are separate clusters)
    step_t, step_th = L * 0.76 / 47, math.radians(2.5)
    cells = {(round(h[0] / step_t), round(h[1] / step_th)): h for h in hits}
    seen, best, comps = set(), [], []
    for c0 in cells:
        if c0 in seen: continue
        comp, stack = [], [c0]; seen.add(c0)
        while stack:
            k = stack.pop(); comp.append(cells[k])
            for di in (-1, 0, 1):
                for dj in (-1, 0, 1):
                    q = (k[0] + di, k[1] + dj)
                    if q in cells and q not in seen: seen.add(q); stack.append(q)
        comps.append(comp)
        if len(comp) > len(best): best = comp
    if a.fabric == "light":   # EVA suits: Tripo often paints the flag twice; the copy facing straight out wins
        big = [c for c in comps if len(c) >= 0.3 * len(best)]
        best = min(big, key=lambda c: abs(sum(h[1] for h in c) / len(c)))
    allhits, hits = hits, best
    ts = [h[0] for h in hits]; ths = [h[1] for h in hits]; R = float(np.median([h[2] for h in hits]))
    tc, thc = (max(ts) + min(ts)) / 2, (max(ths) + min(ths)) / 2
    hw_c = max(abs(max(ths) - thc), abs(min(ths) - thc)) * R; hh_c = max(abs(max(ts) - tc), abs(min(ts) - tc))   # the patch itself
    near = [h for h in allhits if abs(h[0] - tc) < 0.08 and abs(h[1] - thc) * R < 0.08]   # placeholder bits next to it
    ts += [h[0] for h in near]; ths += [h[1] for h in near]
    near = [q[3] for q in sleeve if abs(q[0] - tc) < 0.06 and abs(q[1] - thc) < 0.9]
    if a.fabric == "light":   # the off-white suit: the margin takes the quilting's colour, never a trim band or tab
        near = [c for c in near if min(c) > 0.55 and max(c) - min(c) < 0.15] or near
    col = tuple(np.median(np.array(near), axis=0)) if near else (0.1, 0.12, 0.25)
    return tc, thc, (hw_c, hh_c), (max(abs(max(ths) - thc), abs(min(ths) - thc)) * R, max(abs(max(ts) - tc), abs(min(ts) - tc))), R, col, len(hits)

is_flag = lambda c: (c[1] > c[0] + 0.15 and c[1] > c[2] + 0.05) or (c[0] > 0.6 and c[1] < 0.3 and c[2] < 0.35)
is_aurora = lambda c: (c[0] > 0.8 and c[1] > 0.68 and c[2] < 0.3) or (min(c) > 0.88)   # bright patch yellow or white, not a muted gold tab
is_aurora_light = lambda c: c[0] > 0.75 and c[1] > 0.55 and c[2] < 0.35 and c[0] - c[2] > 0.4   # on the white EVA suit: the yellow only

def build(side, patch_png, test, aspect):
    f = None if a.fabric == "light" else find_patch(side, test)   # EVA: always the outer upper sleeve; copies are painted out
    if f is None:   # no painted placeholder (models built from arm-free side views): the usual spot on the outer sleeve
        s0, s1, along, out, across = frame(side); tc = 0.2 * (s1 - s0).length
        (loc, nrm, face, _), r = radial_hit(s0, along, out, across, tc, 0.0)
        if loc is None:
            print("PATCH", side, "no placeholder and no sleeve surface found"); return
        R = (loc - (s0 + along * tc)).length; sleeve = tuple(colour_at(loc, face))
        f = (tc, 0.0, (0.0375, 0.0375 * aspect), (0.0, 0.0), R, sleeve, 0)
        print("PATCH", side, "placed on the outer upper sleeve" if a.fabric == "light" else "no painted placeholder: placed on the outer upper sleeve")
    tc, thc, (hw, hh), (mhw, mhh), R, sleeve, n = f
    if a.fabric == "light":   # the margin takes the suit's light quilting around the spot, never a seam, band or tab
        s0, s1, along, out, across = frame(side); ring = []
        for dt in np.linspace(-0.10, 0.10, 11):
            for dth in range(-90, 91, 10):
                (l2, _, f2, _), _ = radial_hit(s0, along, out, across, tc + dt, thc + math.radians(dth))
                if l2 is not None: ring.append(colour_at(l2, f2))
        light = [c for c in ring if min(c) > 0.5 and max(c) - min(c) < 0.15]
        if light: sleeve = tuple(float(v) for v in np.median(np.array(light), axis=0))
    s0, s1, along, out, across = frame(side)
    pw = 0.08 if aspect < 1 else 0.06; ph = pw * aspect   # one uniform: every flag 8 x 4.8 cm, every round patch 6 cm
    mw_, mh_ = max(pw, 2 * mhw) + 0.05, max(ph, 2 * mhh) + 0.05   # sleeve-coloured margin hides all of the placeholder
    if a.fabric == "light":   # the layer is the patch alone; paint_under() clears the body 1.5 cm round it
        mw_, mh_ = pw + 0.03, ph + 0.03
    nx, ny = 18, 14; verts, uvs = [], []
    for jy in range(ny + 1):
        for ix in range(nx + 1):
            u, v = ix / nx, jy / ny
            t = tc + (v - 0.5) * mh_; th = thc + (u - 0.5) * mw_ / R   # wrap around the sleeve by arc length
            (loc, nrm, face, _), r = radial_hit(s0, along, out, across, t, th)
            if loc is None: loc, nrm = s0 + along * t + r * R, r
            n_ = nrm if nrm.dot(r) > 0 else -nrm
            verts.append(loc + n_ * 0.001); uvs.append((u if side == "Left" else 1 - u, 1 - v))
    faces = [(j * (nx + 1) + i, j * (nx + 1) + i + 1, (j + 1) * (nx + 1) + i + 1, (j + 1) * (nx + 1) + i) for j in range(ny) for i in range(nx)]
    name = "PatchFlagL" if side == "Left" else "PatchAuroraR"
    m = bpy.data.meshes.new(name); m.from_pydata([tuple(p) for p in verts], [], faces); m.update()
    m.polygons.foreach_set("use_smooth", [True] * len(m.polygons))
    ul = m.uv_layers.new(name="UVMap")
    for poly in m.polygons:
        for li in poly.loop_indices: ul.data[li].uv = uvs[m.loops[li].vertex_index]
    return name, m, (pw, ph, mw_, mh_), sleeve, patch_png, side

def texture(patch_png, pw, ph, mw_, mh_, sleeve, flip):
    pimg = bpy.data.images.load(patch_png); PW, PH = pimg.size
    pp = np.empty(PW * PH * 4, np.float32); pimg.pixels.foreach_get(pp); pp = pp.reshape(PH, PW, 4)
    if flip: pp = pp[:, ::-1]
    R = 512; TW, TH = R, int(R * mh_ / mw_)
    out = np.zeros((TH, TW, 4), np.float32); out[..., :3] = sleeve
    yy, xx = np.mgrid[0:TH, 0:TW]; edge = np.minimum.reduce([xx, yy, TW - 1 - xx, TH - 1 - yy]) / (0.06 * TW)
    out[..., 3] = 0.0 if a.fabric == "light" else np.clip(edge, 0, 1)   # light: only the patch itself (the body under it is painted)
    x0, y0 = int((mw_ - pw) / 2 / mw_ * TW), int((mh_ - ph) / 2 / mh_ * TH); sw, sh = int(pw / mw_ * TW), int(ph / mh_ * TH)
    small = pimg.copy(); small.scale(sw, sh)                    # Blender's filtered resize, no aliasing
    patch = np.empty(sw * sh * 4, np.float32); small.pixels.foreach_get(patch); patch = patch.reshape(sh, sw, 4)
    if flip: patch = patch[:, ::-1]
    al = patch[..., 3:4]
    region = out[TH - y0 - sh:TH - y0, x0:x0 + sw]          # Blender images are stored bottom-up
    region[..., :3] = region[..., :3] * (1 - al) + patch[..., :3] * al; region[..., 3:4] = np.maximum(region[..., 3:4], al)
    im = bpy.data.images.new(os.path.basename(patch_png).replace(".png", "_layer"), TW, TH, alpha=True)
    im.pixels.foreach_set(out.ravel()); im.pack(); return im

def dilate(m, r):
    for _ in range(r):
        n = m.copy(); n[1:] |= m[:-1]; n[:-1] |= m[1:]; n[:, 1:] |= m[:, :-1]; n[:, :-1] |= m[:, 1:]; m = n
    return m

def nb_sum(x):
    """Sum of each texel's 8 neighbours (zero beyond the edge)."""
    p = np.pad(x, [(1, 1), (1, 1)] + [(0, 0)] * (x.ndim - 2)); h, w = x.shape[:2]
    return sum(p[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx)

def raster(uv, tris, W, H):
    """Texels covered by the given triangles (uv: (n, 3, 2) in texels)."""
    m = np.zeros((H, W), bool)
    for t in tris:
        (ax, ay), (bx, by), (cx, cy) = uv[t]; d = (bx - ax) * (cy - ay) - (cx - ax) * (by - ay)
        if abs(d) < 1e-9: continue
        x0, x1 = max(int(min(ax, bx, cx)), 0), min(int(max(ax, bx, cx)) + 1, W - 1)
        y0, y1 = max(int(min(ay, by, cy)), 0), min(int(max(ay, by, cy)) + 1, H - 1)
        if x1 < x0 or y1 < y0: continue
        ys, xs = np.mgrid[y0:y1 + 1, x0:x1 + 1] + 0.5
        w1 = ((xs - ax) * (cy - ay) - (cx - ax) * (ys - ay)) / d; w2 = ((bx - ax) * (ys - ay) - (xs - ax) * (by - ay)) / d
        m[y0:y1 + 1, x0:x1 + 1] |= (w1 >= -1e-6) & (w2 >= -1e-6) & (w1 + w2 <= 1.000001)
    return m

def pull_push(c, k):
    """Fill the unknown texels (~k) from ever coarser averages of the known ones, smoothing at each level: a membrane
    that meets the surrounding texels everywhere and never extrapolates."""
    if k.all() or not k.any() or min(k.shape) < 2:
        c = c.copy()
        if k.any(): c[~k] = c[k].mean(0)
        return c
    h, w = k.shape; h2, w2 = -(-h // 2), -(-w // 2)
    cp = np.zeros((h2 * 2, w2 * 2, c.shape[2]), np.float32); wp = np.zeros((h2 * 2, w2 * 2), np.float32)
    cp[:h, :w] = c * k[..., None]; wp[:h, :w] = k
    cs = cp.reshape(h2, 2, w2, 2, -1).sum((1, 3)); ws = wp.reshape(h2, 2, w2, 2).sum((1, 3))
    coarse = pull_push(cs / np.maximum(ws, 1e-6)[..., None], ws > 0)
    out = c.copy(); out[~k] = coarse.repeat(2, 0).repeat(2, 1)[:h, :w][~k]
    ones = nb_sum(np.ones((h, w), np.float32))[..., None]
    for _ in range(3):
        out[~k] = (nb_sum(out) / ones)[~k]
    return out

def blobs(mask, B=16):
    """Bounding boxes (y0, y1, x0, x1) of the mask's separate pieces, joined on a coarse B-texel grid."""
    gh, gw = -(-mask.shape[0] // B), -(-mask.shape[1] // B); cells = np.zeros((gh, gw), bool)
    ys, xs = np.nonzero(mask); cells[ys // B, xs // B] = True; seen = np.zeros_like(cells); out = []
    for sy, sx in zip(*np.nonzero(cells)):
        if seen[sy, sx]: continue
        stack, got = [(sy, sx)], []; seen[sy, sx] = True
        while stack:
            y, x = stack.pop(); got.append((y, x))
            for q in ((y + dy, x + dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1)):
                if 0 <= q[0] < gh and 0 <= q[1] < gw and cells[q] and not seen[q]: seen[q] = True; stack.append(q)
        gy, gx = np.array(got).T; out.append((gy.min() * B, (gy.max() + 1) * B, gx.min() * B, (gx.max() + 1) * B))
    return out

def flag_green(rgb):
    """Candidate dark, saturated flag green; flag_mask disambiguates it from shaded teal details."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]; mx = rgb.max(-1)
    return (g > r + 0.12) & (g > b + 0.02) & (mx < 0.65) & (mx - rgb.min(-1) > 0.5 * mx)

def flag_mask(rgb, near, tpm):
    """Only erase green fields connected to a red disc; isolated teal details are ambiguous."""
    # shortcut: green-only placeholders stay untouched; use a reviewed mask when a flag lacks its red disc.
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    green = near & flag_green(rgb)
    red = near & (r > 0.6) & (g < 0.3) & (b < 0.35)
    core = np.zeros_like(near)
    for y0, y1, x0, x1 in blobs(green):
        y0, y1, x0, x1 = max(y0 - 2, 0), min(y1 + 2, near.shape[0]), max(x0 - 2, 0), min(x1 + 2, near.shape[1])
        field = green[y0:y1, x0:x1]
        part = field & dilate(red[y0:y1, x0:x1], 2)
        while True:
            grown = field & dilate(part, 1)
            if np.array_equal(part, grown): break
            part = grown
        core[y0:y1, x0:x1] |= part
    core |= red & dilate(core, max(1, int(0.03 * tpm)))
    inky = (rgb.max(-1) < 0.22) & (rgb.max(-1) - rgb.min(-1) < 0.08)
    blueish = b - g > 0.06
    # Expansion may reach fabric or a dark border, never skin, tabs or name tapes.
    allowed = near & (core | inky | blueish)
    border = dilate(core, max(1, int(0.008 * tpm))) & inky
    hole = dilate(core | border, 3) & allowed
    return hole, blueish


def fill(arr, hole, known):
    """Fill only masked texels, using donors from this map (never base colour in a normal map)."""
    h, w = hole.shape
    for y0, y1, x0, x1 in blobs(hole):
        y0, y1, x0, x1 = max(y0 - 12, 0), min(y1 + 12, h), max(x0 - 12, 0), min(x1 + 12, w)
        c = arr[y0:y1, x0:x1].copy(); mask = hole[y0:y1, x0:x1]; k = known[y0:y1, x0:x1] & ~mask
        if not k.any(): raise ValueError("Paint-out has no nearby fabric samples; review the mask before export")
        c[mask] = pull_push(c, k)[mask] if k.sum() >= 30 else np.median(c[k], axis=0)
        weights = (mask | k).astype(np.float32)
        count = nb_sum(weights)[..., None]
        for _ in range(3):
            smooth = np.divide(nb_sum(c * weights[..., None]), count, out=c.copy(), where=count > 0)
            c[mask] = smooth[mask]
        arr[y0:y1, x0:x1][mask] = np.clip(c[mask], 0, 1)


def fill_or_flat(arr, hole, known, fallback):
    """fill(), except that a piece with no donor in fill's window takes the median donor colour (or fallback)."""
    hole = hole.copy(); h, w = hole.shape
    base = np.median(arr[known], axis=0) if known.any() else np.array(fallback, np.float32)
    for y0, y1, x0, x1 in blobs(hole):
        y0, y1, x0, x1 = max(y0 - 12, 0), min(y1 + 12, h), max(x0 - 12, 0), min(x1 + 12, w)
        if not (known[y0:y1, x0:x1] & ~hole[y0:y1, x0:x1]).any():
            m = hole[y0:y1, x0:x1].copy(); arr[y0:y1, x0:x1][m] = base; hole[y0:y1, x0:x1] &= ~m
    if hole.any(): fill(arr, hole, known)


def linked_images(socket):
    """Images feeding a material input, including through normal-map and channel-split nodes."""
    images, seen, pending = set(), set(), [socket]
    while pending:
        for link in pending.pop().links:
            node = link.from_node
            if node in seen: continue
            seen.add(node)
            if node.type == "TEX_IMAGE":
                if node.image: images.add(node.image)
            else:
                pending.extend(node.inputs)
    return images


def mesh_arrays():
    """World vertex positions, triangle vertex and loop indices, and per-triangle UVs in texels of the body mesh."""
    co = np.empty(len(me.vertices) * 3, np.float32); me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3) @ np.array(mw.to_3x3()).T + np.array(mw.translation)
    me.calc_loop_triangles(); n = len(me.loop_triangles)
    tv = np.empty(n * 3, np.int32); me.loop_triangles.foreach_get("vertices", tv); tv = tv.reshape(-1, 3)
    tl = np.empty(n * 3, np.int32); me.loop_triangles.foreach_get("loops", tl); tl = tl.reshape(-1, 3)
    uv = np.empty(len(uvl) * 2, np.float32); uvl.foreach_get("uv", uv); uv = uv.reshape(-1, 2)[tl] * (W, H)
    return co, tv, uv


def texels_per_metre(co, tv, uv, tris):
    e = co[tv[tris]]; wa = np.linalg.norm(np.cross(e[:, 1] - e[:, 0], e[:, 2] - e[:, 0]), axis=1).sum()
    u = uv[tris]; ab, ac = u[:, 1] - u[:, 0], u[:, 2] - u[:, 0]
    return math.sqrt(np.abs(ab[:, 0] * ac[:, 1] - ab[:, 1] * ac[:, 0]).sum() / max(wa, 1e-12))


def body_weights(ob, points):
    """Give each vertex of a layer (world positions in points) the skin weights of the nearest body vertex."""
    from mathutils.kdtree import KDTree
    kd = KDTree(len(me.vertices))
    for i, v in enumerate(me.vertices): kd.insert(mw @ v.co, i)
    kd.balance()
    names = {g.index: g.name for g in body.vertex_groups}
    for i, p in enumerate(points):
        for g in me.vertices[kd.find(p)[1]].groups:
            if g.weight > 0: (ob.vertex_groups.get(names[g.group]) or ob.vertex_groups.new(name=names[g.group])).add([i], g.weight, "REPLACE")


def paint_under(layer, side):
    """EVA suits: paint the body texture under a patch layer (and 2 cm round every placeholder-coloured blob on that
    upper arm: flag green/red on the left, Aurora yellow on the right, with their dark borders, never the navy trim) with the light suit
    fabric, and flatten the normal map there, so only the crisp layer shows and nothing reads as a pale square."""
    co, tv, uv = mesh_arrays()
    arm_bone = next(b.name for b in arm.data.bones if b.name.endswith(f"{side}Arm"))
    gi = body.vertex_groups[arm_bone].index
    on_arm = np.array([any(g.group == gi and g.weight > 0.5 for g in v.groups) for v in me.vertices])
    tris = np.nonzero(on_arm[tv].all(1))[0]
    if not len(tris): return
    tpm = texels_per_metre(co, tv, uv, tris)
    region = raster(uv, tris, W, H) & ~dilate(raster(uv, np.nonzero(~on_arm[tv].all(1))[0], W, H), 2)
    rgb = px[..., :3]
    fabric = region & (rgb.min(-1) > 0.55) & (rgb.max(-1) - rgb.min(-1) < 0.15)
    colour = np.median(rgb[fabric], axis=0) if fabric.any() else np.array([0.9, 0.88, 0.8], np.float32)
    # the layer's footprint: texels at the UVs of the body points under its grid, grown by 2 texels
    foot = np.zeros((H, W), bool); lw = layer.matrix_world
    for v in layer.data.vertices:
        p = lw @ v.co; loc, nrm, face, _ = tree.find_nearest(p)
        if face is None: continue
        poly = me.polygons[face]; vs = [mw @ me.vertices[i].co for i in poly.vertices]; wts = poly_3d_calc(vs, loc)
        u = sum(w_ * uvl[li].uv[0] for w_, li in zip(wts, poly.loop_indices)); q = sum(w_ * uvl[li].uv[1] for w_, li in zip(wts, poly.loop_indices))
        foot[int(min(max(q, 0), 0.9999) * H), int(min(max(u, 0), 0.9999) * W)] = True
    foot = dilate(foot, max(2, int(0.006 * tpm))) & region
    r_, g_, b_ = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    if side == "Left":
        mark = (flag_green(rgb) & (rgb.max(-1) < 0.6)) | ((r_ > 0.6) & (g_ < 0.3) & (b_ < 0.35))
    else:
        mark = (r_ > 0.75) & (g_ > 0.55) & (b_ < 0.35) & (r_ - b_ > 0.4)
    mark &= region
    blobs_ = np.zeros_like(mark)
    for y0, y1, x0, x1 in blobs(mark):
        if mark[y0:y1, x0:x1].sum() > (0.006 * tpm) ** 2: blobs_[y0:y1, x0:x1] |= mark[y0:y1, x0:x1]
    navy = (b_ - r_ > 0.05) & (rgb.max(-1) < 0.45)                      # the suit's own navy trim stays whole
    around = dilate(blobs_, int(0.015 * tpm)) & region & ~fabric & ~navy  # the placeholder's dark border and lettering
    hole = foot | blobs_ | around
    rgb[hole] = colour; img.pixels.foreach_set(px.ravel()); img.update()
    for node in body.active_material.node_tree.nodes:
        if node.type != "BSDF_PRINCIPLED": continue
        for o in linked_images(node.inputs["Normal"]) - {img}:
            Wo, Ho = o.size; q = np.empty(Wo * Ho * 4, np.float32); o.pixels.foreach_get(q); q = q.reshape(Ho, Wo, 4)
            m_ = hole[np.ix_(np.arange(Ho) * H // Ho, np.arange(Wo) * W // Wo)]
            q[m_, 0], q[m_, 1], q[m_, 2] = 0.5, 0.5, 1.0; o.pixels.foreach_set(q.ravel()); o.update()
    print(f"PATCH {layer.name}: body painted with the suit fabric under it and round {int(blobs_.sum())} placeholder texels ({int(hole.sum())} texels)")


def build_chest(patch_png):
    """The round Aurora patch on the RIGHT chest: a 6 cm grid moulded onto the chest by rays from the front, centred
    where the sheets drew the chest badge (mirrored): 0.57 of the way out to the shoulder joint and 10.5 cm below it
    (scaled with the body). Each grid vertex takes the skin weights of the nearest body vertex, so it deforms with the
    chest exactly."""
    sh = bone_pts("RightArm")[0]; k = sh.z / 1.356                     # 1.356 m: Kai's shoulder joint
    cx, cz, pw = 0.57 * sh.x, sh.z - 0.105 * k, 0.06
    nx = ny = 16; verts, uvs = [], []
    for jy in range(ny + 1):
        for ix in range(nx + 1):
            u, v = ix / nx, jy / ny
            o = Vector((cx + (u - 0.5) * pw, -1.0, cz + (0.5 - v) * pw))
            loc, nrm, face, _ = tree.ray_cast(o, Vector((0, 1, 0)))
            if loc is None: print("PATCH chest: no chest surface in front of", tuple(round(c, 3) for c in o)); return None
            verts.append(loc + (nrm if nrm.y < 0 else -nrm) * 0.001); uvs.append((1 - u, 1 - v))
    faces = [(j * (nx + 1) + i, j * (nx + 1) + i + 1, (j + 1) * (nx + 1) + i + 1, (j + 1) * (nx + 1) + i) for j in range(ny) for i in range(nx)]
    m = bpy.data.meshes.new("PatchAuroraChest"); m.from_pydata([tuple(p) for p in verts], [], faces); m.update()
    m.polygons.foreach_set("use_smooth", [True] * len(m.polygons))
    ul = m.uv_layers.new(name="UVMap")
    for poly in m.polygons:
        for li in poly.loop_indices: ul.data[li].uv = uvs[m.loops[li].vertex_index]
    ob = bpy.data.objects.new("PatchAuroraChest", m); sc.collection.objects.link(ob)
    pimg = bpy.data.images.load(patch_png); pimg.pack()
    mat = bpy.data.materials.new("PatchAuroraChest"); mat.use_nodes = True; nt = mat.node_tree; bs = nt.nodes["Principled BSDF"]
    t = nt.nodes.new("ShaderNodeTexImage"); t.image = pimg
    nt.links.new(t.outputs["Color"], bs.inputs["Base Color"]); nt.links.new(t.outputs["Alpha"], bs.inputs["Alpha"]); bs.inputs["Roughness"].default_value = 0.85
    if hasattr(mat, "surface_render_method"): mat.surface_render_method = "BLENDED"
    m.materials.append(mat)
    body_weights(ob, verts)
    ob.parent = arm; mod = ob.modifiers.new("Armature", "ARMATURE"); mod.object = arm
    print(f"PATCH PatchAuroraChest: {pw*100:.0f} cm at x {cx:+.3f} z {cz:.3f} (right chest), weights from the body")
    return ob


def paint_pack():
    """Paint every flag colour and every large light mark on the life-support pack (the part of the back that stands clear of
    the seat and shoulders) with the pack's own navy, filled from its navy texels; small details are kept."""
    co, tv, uv = mesh_arrays(); c = co[tv].mean(1); top = co[:, 2].max(); k = top / 1.74
    seat = co[(co[:, 2] > 0.44 * top) & (co[:, 2] < 0.52 * top) & (np.abs(co[:, 0]) < 0.15 * k)][:, 1].max()   # the seat, below the pack (not the hands)
    pack = (c[:, 1] > seat + 0.05 * k) & (c[:, 2] > 0.50 * top) & (c[:, 2] < 0.88 * top) & (np.abs(c[:, 0]) < 0.30 * k)
    tris = np.nonzero(pack)[0]
    if not len(tris): print("PACK no pack triangles behind the back"); return
    tpm = texels_per_metre(co, tv, uv, tris)
    region = raster(uv, tris, W, H) & ~dilate(raster(uv, np.nonzero(~pack)[0], W, H), 2)
    rgb = px[..., :3]; L = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    navy = region & (L < 0.40) & (rgb[..., 2] > rgb[..., 0])
    flag = region & (flag_green(rgb) | ((rgb[..., 0] > 0.6) & (rgb[..., 1] < 0.3) & (rgb[..., 2] < 0.35)))
    light = region & (L > 0.45)
    hole = flag.copy(); big = (0.04 * tpm) ** 2            # any flag colour; light marks only above 4 x 4 cm
    for y0, y1, x0, x1 in blobs(light):
        piece = light[y0:y1, x0:x1]
        if piece.sum() > big: hole[y0:y1, x0:x1] |= piece
    hole = dilate(hole, 3) & region
    if not hole.any(): print(f"PACK {len(tris)} pack triangles, no large light marks"); return
    hole |= dilate(hole, int(0.03 * tpm)) & region & ~navy   # the mark's own outline and remnants within 3 cm of it
    known = navy & ~hole
    marks = hole.copy()
    fill_or_flat(rgb, hole, known, (0.12, 0.15, 0.27))
    img.pixels.foreach_set(px.ravel()); img.update()
    # the copied mark's relief lives in the normal map, across the pack's UV islands (a flag's edge, the dome's rim):
    # the pack's normal map is flattened wherever a mark was found (its shape is in the geometry; its panel lines are paint)
    painted = region.copy()
    for node in body.active_material.node_tree.nodes:
        if node.type != "BSDF_PRINCIPLED": continue
        for o in linked_images(node.inputs["Normal"]) - {img}:
            Wo, Ho = o.size; q = np.empty(Wo * Ho * 4, np.float32); o.pixels.foreach_get(q); q = q.reshape(Ho, Wo, 4)
            m = painted[np.ix_(np.arange(Ho) * H // Ho, np.arange(Wo) * W // Wo)]
            q[m, 0], q[m, 1], q[m, 2] = 0.5, 0.5, 1.0
            o.pixels.foreach_set(q.ravel()); o.update(); print("PACK normal map flattened over the pack in", o.name)
    # ...and often relief in the mesh as well, which bands under the toon ramp: smooth the pack's surface under the marks
    cu = uv[tris].mean(1)
    under = marks[np.clip(cu[:, 1].astype(int), 0, H - 1), np.clip(cu[:, 0].astype(int), 0, W - 1)]
    sel = np.unique(tv[tris[under]])
    if len(sel):
        e = np.empty(len(me.edges) * 2, np.int32); me.edges.foreach_get("vertices", e); e = e.reshape(-1, 2)
        loc = np.empty(len(me.vertices) * 3, np.float32); me.vertices.foreach_get("co", loc); loc = loc.reshape(-1, 3)
        moving = np.zeros(len(me.vertices), bool); moving[sel] = True
        for _ in range(8):
            acc = np.zeros_like(loc); cnt = np.zeros(len(loc))
            np.add.at(acc, e[:, 0], loc[e[:, 1]]); np.add.at(acc, e[:, 1], loc[e[:, 0]])
            np.add.at(cnt, e[:, 0], 1); np.add.at(cnt, e[:, 1], 1)
            avg = acc / np.maximum(cnt, 1)[:, None]
            loc[moving] = 0.5 * loc[moving] + 0.5 * avg[moving]
        me.vertices.foreach_set("co", loc.ravel()); me.update()
        print(f"PACK {len(sel)} pack vertices under the marks smoothed")
    print(f"PACK {len(tris)} pack triangles behind y {seat + 0.05 * k:+.3f}: {int(hole.sum())} texels painted navy ({tpm:.0f} texels/m)")


def paint_out_flags():
    """Paint every painted flag on the upper body (green field, red disc, dark border) back to the fabric around it.
    Only garment triangles below the neck are eligible. Protected UVs and non-flag colours always win;
    ambiguous green-only details are left for review. Clean only padding immediately beside the garment."""
    neck, hips = bone_pts("Neck")[0].z, bone_pts("Hips")[0].z    # stop below exposed neck skin
    co = np.empty(len(me.vertices) * 3, np.float32); me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3) @ np.array(mw.to_3x3()).T + np.array(mw.translation)
    me.calc_loop_triangles(); n = len(me.loop_triangles)
    tv = np.empty(n * 3, np.int32); me.loop_triangles.foreach_get("vertices", tv); tv = tv.reshape(-1, 3)
    tl = np.empty(n * 3, np.int32); me.loop_triangles.foreach_get("loops", tl); tl = tl.reshape(-1, 3)
    uv = np.empty(len(uvl) * 2, np.float32); uvl.foreach_get("uv", uv); uv = uv.reshape(-1, 2)[tl] * (W, H)   # (n, 3, 2) texels
    z = co[tv][:, :, 2]
    protected_groups = {g.index for g in body.vertex_groups if any(s in g.name for s in ("Head", "Neck", "Hand", "Ponytail", "Hair"))}
    protected_vertices = np.array([any(g.group in protected_groups and g.weight > 0.01 for g in v.groups) for v in me.vertices])
    garment = (z > hips).all(1) & (z < neck).all(1) & ~protected_vertices[tv].any(1)
    band = np.nonzero(garment)[0]
    if not len(band): print("PAINT-OUT no safe garment triangles"); return
    e = co[tv[band]]; wa = np.linalg.norm(np.cross(e[:, 1] - e[:, 0], e[:, 2] - e[:, 0]), axis=1).sum()
    u = uv[band]; ab, ac = u[:, 1] - u[:, 0], u[:, 2] - u[:, 0]
    ua = np.abs(ab[:, 0] * ac[:, 1] - ab[:, 1] * ac[:, 0]).sum()
    if wa <= 1e-12 or ua <= 1e-12: raise ValueError("Paint-out needs nondegenerate garment geometry and UVs")
    tpm = math.sqrt(ua / wa)                                   # texels per metre on the upper body
    region = raster(uv, band, W, H)
    protected = raster(uv, np.nonzero(~garment)[0], W, H)
    near = dilate(region, 2) & ~dilate(protected, 2)   # only adjacent padding; shared/protected UVs always win
    rgb = px[..., :3]
    hole, blueish = flag_mask(rgb, near, tpm)
    if not hole.any():
        print("PAINT-OUT no unambiguous flags on safe fabric")
        if a.fabric != "light": return
    if a.fabric == "light":   # the EVA suit: off-white quilting donates too (low saturation, light)
        blueish = blueish | ((rgb.min(-1) > 0.55) & (rgb.max(-1) - rgb.min(-1) < 0.15))
    known = near & ~hole & blueish
    fill(rgb, hole, known); img.pixels.foreach_set(px.ravel()); img.update()
    hole2 = near & dilate(hole, int(0.006 * tpm)) & (blueish | hole)   # the placeholder's embossed edge runs past its paint
    known2 = near & ~hole2 & blueish
    maps = set()
    for node in body.active_material.node_tree.nodes:
        if node.type == "BSDF_PRINCIPLED":
            for name in ("Normal", "Roughness"):
                maps.update(linked_images(node.inputs[name]))
    for o in maps - {img}:
        Wo, Ho = o.size
        if Wo < 1 or Ho < 1: raise ValueError("Paint-out map has no pixels: " + o.name)
        q = np.empty(Wo * Ho * 4, np.float32); o.pixels.foreach_get(q); q = q.reshape(Ho, Wo, 4)
        rows, cols = np.arange(Ho) * H // Ho, np.arange(Wo) * W // Wo
        # Lower-resolution maps can share a texel with protected UVs; exclude those cells too.
        safe = raster(uv * (Wo / W, Ho / H), np.nonzero(~garment)[0], Wo, Ho)
        h = hole2[np.ix_(rows, cols)] & ~dilate(safe, 2)
        k = known2[np.ix_(rows, cols)] & ~dilate(safe, 2)
        fill(q[..., :3], h, k); o.pixels.foreach_set(q.ravel()); o.update()
        print("PAINT-OUT also in", o.name)
    h0 = hole
    if a.fabric == "light":   # EVA suits: Tripo also copies loose flag pieces (a second flag beside the first, a lone disc)
        r_, g_, b_ = rgb[..., 0], rgb[..., 1], rgb[..., 2]
        sleeve_light = tuple(np.median(rgb[near & (rgb.min(-1) > 0.5)], axis=0)) if (near & (rgb.min(-1) > 0.5)).any() else (0.9, 0.88, 0.8)
        loose = near & ((flag_green(rgb) & (rgb.max(-1) < 0.55)) | ((r_ > 0.6) & (g_ < 0.3) & (b_ < 0.35))) & ~hole
        extra = np.zeros_like(loose)
        for y0, y1, x0, x1 in blobs(loose):
            piece = loose[y0:y1, x0:x1]
            if piece.sum() > (0.008 * tpm) ** 2: extra[y0:y1, x0:x1] |= piece
        extra = dilate(extra, 3) & near
        if extra.any():
            fill_or_flat(rgb, extra, near & ~extra & ~hole & blueish, sleeve_light)
            img.pixels.foreach_set(px.ravel()); img.update()
            print(f"PAINT-OUT {int(extra.sum())} more texels of loose flag pieces")
    left = int((hole & flag_green(rgb)).sum())
    print(f"PAINT-OUT {int(h0.sum())} texels ({tpm:.0f} texels/m, masked fabric), flag green left: {left}")
    assert left == 0

made = []
for side, png, test, aspect in [("Left", "patch_bangladesh.png", is_flag, 0.6), ("Right", "patch_aurora.png", is_aurora_light if a.fabric == "light" else is_aurora, 1.0)]:
    r = build(side, os.path.join(a.patches, png), test, aspect)
    if not r: continue
    name, m, (pw, ph, mw_, mh_), sleeve, ppng, side = r
    im = texture(ppng, pw, ph, mw_, mh_, sleeve, flip=False)
    ob = bpy.data.objects.new(name, m); sc.collection.objects.link(ob)
    mat = bpy.data.materials.new(name); mat.use_nodes = True; nt = mat.node_tree; bs = nt.nodes["Principled BSDF"]
    t = nt.nodes.new("ShaderNodeTexImage"); t.image = im
    nt.links.new(t.outputs["Color"], bs.inputs["Base Color"]); nt.links.new(t.outputs["Alpha"], bs.inputs["Alpha"]); bs.inputs["Roughness"].default_value = 0.85
    if hasattr(mat, "surface_render_method"): mat.surface_render_method = "BLENDED"
    m.materials.append(mat)
    bone = bone_pts(f"{side}Arm")[2]
    if a.fabric == "light":   # the bulky suit sleeve blends shoulder and arm weights: the layer takes the sleeve's own
        body_weights(ob, [v.co.copy() for v in m.vertices])   # the layer object sits at the origin: its vertices are world positions
    else:
        vg = ob.vertex_groups.new(name=bone); vg.add(list(range(len(m.vertices))), 1.0, "REPLACE")
    ob.parent = arm; mod = ob.modifiers.new("Armature", "ARMATURE"); mod.object = arm; made.append(ob)
    if a.fabric == "light": paint_under(ob, side)
    print(f"PATCH {name}: {pw*100:.1f} x {ph*100:.1f} cm on {bone}, sleeve colour {tuple(round(float(x), 3) for x in sleeve)}")
if a.chest:
    ob = build_chest(os.path.join(a.patches, "patch_aurora.png"))
    if ob: made.append(ob)
paint_out_flags()
if a.pack: paint_pack()

arm.data.pose_position = "POSE"
if a.debug:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import blender_look
    if arm.animation_data:
        for t in arm.animation_data.nla_tracks: t.mute = True
        arm.animation_data.action = None
    blender_look.setup(sc, centre=Vector((0, 0, 1.3)), scale=0.6)
    cam = bpy.data.objects.new("C", bpy.data.cameras.new("C")); sc.collection.objects.link(cam); sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = 900, 450; files = []
    for k, d in enumerate((Vector((1, -0.35, 0.1)), Vector((-1, -0.35, 0.1)))):
        c = Vector((0.18 * (1 if k == 0 else -1), 0, 1.30)); cam.location = c + d.normalized() * 0.9
        cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler(); cam.data.lens = 70
        f = a.debug.replace(".png", f"_{k}.png"); sc.render.filepath = f; bpy.ops.render.render(write_still=True); files.append(f)
    print("DEBUG", files); sys.exit()
ad = arm.animation_data or arm.animation_data_create()
have = {s.action.name for t in ad.nla_tracks for s in t.strips if s.action}
for act in bpy.data.actions:
    if act.name in have: continue
    t = ad.nla_tracks.new(); t.name = act.name; t.strips.new(act.name, int(act.frame_range[0]), act); t.mute = True
ad.action = None
bpy.ops.export_scene.gltf(filepath=a.dst, export_format="GLB", export_yup=True, export_skins=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS", export_image_quality=92)
print("PATCHES DONE", len(made), "layers,", len(ad.nla_tracks), "clips ->", a.dst)
