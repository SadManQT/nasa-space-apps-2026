"""Replace the AI-painted sleeve patches with crisp patch layers: the Bangladesh flag on the LEFT upper sleeve and the
round Aurora patch on the RIGHT upper sleeve (production/concept/patches, tools/make_patches.py).

  blender -b -P add_patches.py -- <in.glb> <patch_dir> <out.glb> [--debug out.png]

The painted placeholder is found by colour on the outer side of each upper arm (rays from the side, texture sampled
at each hit): flag green/red on the left, patch yellow on the right. A layer grid is moulded over it, 1 mm off the
sleeve, filled with the sleeve colour around the patch so no trace of the placeholder shows, and bound to the upper
arm bone. Unambiguous green/red flags on safe garment UVs (including copies on the back or wrong arm) are
painted back to the fabric around them. Ambiguous details and protected UVs are left for review.
Every clip is kept (NLA tracks).
"""
import argparse, math, os, sys
import bpy, numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.interpolate import poly_3d_calc

a = argparse.ArgumentParser(); a.add_argument("src"); a.add_argument("patches"); a.add_argument("dst"); a.add_argument("--debug")
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
    seen, best = set(), []
    for c0 in cells:
        if c0 in seen: continue
        comp, stack = [], [c0]; seen.add(c0)
        while stack:
            k = stack.pop(); comp.append(cells[k])
            for di in (-1, 0, 1):
                for dj in (-1, 0, 1):
                    q = (k[0] + di, k[1] + dj)
                    if q in cells and q not in seen: seen.add(q); stack.append(q)
        if len(comp) > len(best): best = comp
    allhits, hits = hits, best
    ts = [h[0] for h in hits]; ths = [h[1] for h in hits]; R = float(np.median([h[2] for h in hits]))
    tc, thc = (max(ts) + min(ts)) / 2, (max(ths) + min(ths)) / 2
    hw_c = max(abs(max(ths) - thc), abs(min(ths) - thc)) * R; hh_c = max(abs(max(ts) - tc), abs(min(ts) - tc))   # the patch itself
    near = [h for h in allhits if abs(h[0] - tc) < 0.08 and abs(h[1] - thc) * R < 0.08]   # placeholder bits next to it
    ts += [h[0] for h in near]; ths += [h[1] for h in near]
    near = [q[3] for q in sleeve if abs(q[0] - tc) < 0.06 and abs(q[1] - thc) < 0.9]
    col = tuple(np.median(np.array(near), axis=0)) if near else (0.1, 0.12, 0.25)
    return tc, thc, (hw_c, hh_c), (max(abs(max(ths) - thc), abs(min(ths) - thc)) * R, max(abs(max(ts) - tc), abs(min(ts) - tc))), R, col, len(hits)

is_flag = lambda c: (c[1] > c[0] + 0.15 and c[1] > c[2] + 0.05) or (c[0] > 0.6 and c[1] < 0.3 and c[2] < 0.35)
is_aurora = lambda c: (c[0] > 0.8 and c[1] > 0.68 and c[2] < 0.3) or (min(c) > 0.88)   # bright patch yellow or white, not a muted gold tab

def build(side, patch_png, test, aspect):
    f = find_patch(side, test)
    if f is None:   # no painted placeholder (models built from arm-free side views): the usual spot on the outer sleeve
        s0, s1, along, out, across = frame(side); tc = 0.2 * (s1 - s0).length
        (loc, nrm, face, _), r = radial_hit(s0, along, out, across, tc, 0.0)
        if loc is None:
            print("PATCH", side, "no placeholder and no sleeve surface found"); return
        R = (loc - (s0 + along * tc)).length; sleeve = tuple(colour_at(loc, face))
        f = (tc, 0.0, (0.0375, 0.0375 * aspect), (0.0, 0.0), R, sleeve, 0)
        print("PATCH", side, "no painted placeholder: placed on the outer upper sleeve")
    tc, thc, (hw, hh), (mhw, mhh), R, sleeve, n = f
    s0, s1, along, out, across = frame(side)
    pw = 0.08 if aspect < 1 else 0.06; ph = pw * aspect   # one uniform: every flag 8 x 4.8 cm, every round patch 6 cm
    mw_, mh_ = max(pw, 2 * mhw) + 0.05, max(ph, 2 * mhh) + 0.05   # sleeve-coloured margin hides all of the placeholder
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
    out[..., 3] = np.clip(edge, 0, 1)
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
    if not hole.any(): print("PAINT-OUT no unambiguous flags on safe fabric"); return
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
    left = int((hole & flag_green(rgb)).sum())
    print(f"PAINT-OUT {int(h0.sum())} texels ({tpm:.0f} texels/m, masked fabric), flag green left: {left}")
    assert left == 0

made = []
for side, png, test, aspect in [("Left", "patch_bangladesh.png", is_flag, 0.6), ("Right", "patch_aurora.png", is_aurora, 1.0)]:
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
    bone = bone_pts(f"{side}Arm")[2]; vg = ob.vertex_groups.new(name=bone); vg.add(list(range(len(m.vertices))), 1.0, "REPLACE")
    ob.parent = arm; mod = ob.modifiers.new("Armature", "ARMATURE"); mod.object = arm; made.append(ob)
    print(f"PATCH {name}: {pw*100:.1f} x {ph*100:.1f} cm on {bone}, sleeve colour {tuple(round(float(x), 3) for x in sleeve)}")
paint_out_flags()

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
