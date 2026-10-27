"""Paint over a baked-in detail (name-tag letters, a fake screen) in a GLB's base-colour texture.

  blender -b -P blank_texture_region.py -- <in.glb> <x0> <y0> <x1> <y1> --res 1600 --fill <out.glb> [--color r,g,b] [--radius 3] [--flatten] [--screen 10]

x0..y1 is a pixel box in the FRONT view rendered by render_preview.py at the same --res; keep it
inside the detail (e.g. inside a name tag's border). Rays are cast from that camera through the box
every quarter pixel; every texel they hit, plus --radius texels around it, is painted with --color
(0-255) or, by default, the median colour under the hits (the plate colour behind the letters).
This works even when the detail is split across several UV islands. Without --fill it only reports.
"""
import argparse, collections, statistics, sys
import bpy
from mathutils import Vector
from mathutils.geometry import barycentric_transform

argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser()
p.add_argument("src"); p.add_argument("box", type=int, nargs=4)
p.add_argument("--res", type=int, default=1600)
p.add_argument("--fill"); p.add_argument("--color"); p.add_argument("--radius", type=int, default=3)
p.add_argument("--flatten", action="store_true",
               help="also flatten the hit surface onto its best-fit plane (detail modelled into the mesh)")
p.add_argument("--screen", type=int, metavar="CHAMFER_PX",
               help="also add a flat 'Screen' surface over the box (corners cut by CHAMFER_PX), "
                    "a separate material slot Godot can give a live UI texture")
a = p.parse_args(argv)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
shapes = {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones}
for o in [o for o in sc.objects if o in shapes]:  # glTF importer's bone-display icosphere, not part of the asset
    bpy.data.objects.remove(o)
meshes = [o for o in sc.objects if o.type == "MESH"]
pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
lo = Vector([min(q[i] for q in pts) for i in range(3)]); hi = Vector([max(q[i] for q in pts) for i in range(3)])
centre, size = (lo + hi) / 2, hi - lo

# same front camera as render_preview.py
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); cam.data.lens = 85
sc.collection.objects.link(cam); sc.camera = cam
sc.render.resolution_x = sc.render.resolution_y = a.res
cam.location = centre + Vector((0, -max(size) * 3.6, size.z * 0.05))
cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
bpy.context.view_layer.update()
tr, br, bl, tl = [cam.matrix_world @ v for v in cam.data.view_frame(scene=sc)]
dg = bpy.context.evaluated_depsgraph_get()

tris_of = {}  # (object, polygon) -> its loop triangles, built on first hit
hits = []     # (object, u, v)
faces = set() # (object, polygon) hit by any ray
x0, y0, x1, y1 = a.box
step = 0.25
y = y0
while y <= y1:
    x = x0
    while x <= x1:
        fx, fy = (x + 0.5) / a.res, (y + 0.5) / a.res
        target = tl.lerp(tr, fx).lerp(bl.lerp(br, fx), fy)
        hit, loc, _n, face, obj, _m = sc.ray_cast(dg, cam.location, (target - cam.location).normalized())
        if hit:
            me = obj.evaluated_get(dg).data
            if obj not in {k[0] for k in tris_of}:
                for t in me.loop_triangles:
                    tris_of.setdefault((obj, t.polygon_index), []).append(t)
            faces.add((obj, face))
            lp = obj.matrix_world.inverted() @ loc
            uvl = me.uv_layers.active.data
            for t in tris_of.get((obj, face), []):
                vs = [me.vertices[me.loops[l].vertex_index].co for l in t.loops]
                b = barycentric_transform(lp, *vs, Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)))
                if min(b) >= -1e-3:
                    uv = sum((uvl[l].uv * w for l, w in zip(t.loops, b)), Vector((0, 0)))
                    hits.append((obj, uv.x, uv.y))
                    break
        x += step
    y += step

if not hits:
    sys.exit("no hits: check the box against the front render")
obj = hits[0][0]
img = next(n.image for m in obj.data.materials for n in m.node_tree.nodes
           if n.type == "TEX_IMAGE" and any(l.to_socket.name == "Base Color" for l in n.outputs[0].links))
W, H = img.size
texels = {(min(W - 1, int(u * W)), min(H - 1, int(v * H))) for o, u, v in hits if o == obj}
islands = collections.Counter((tx // 128, ty // 128) for tx, ty in texels)
print(f"HITS {len(hits)} rays, {len(texels)} texels in {img.name} {W}x{H}; 128-texel cells: {islands.most_common(8)}")

if a.fill:
    px = list(img.pixels)
    if a.color:
        col = [int(c) / 255 for c in a.color.split(",")] + [1.0]
    else:
        under = [px[(ty * W + tx) * 4:(ty * W + tx) * 4 + 4] for tx, ty in texels]
        col = [statistics.median(c[k] for c in under) for k in range(4)]
    r = a.radius
    paint = {(tx + dx, ty + dy) for tx, ty in texels for dx in range(-r, r + 1) for dy in range(-r, r + 1)
             if dx * dx + dy * dy <= r * r and 0 <= tx + dx < W and 0 <= ty + dy < H}
    for tx, ty in paint:
        i = (ty * W + tx) * 4
        px[i:i + 4] = col
    img.pixels = px
    img.pack()
    # flatten the same texels in the normal map, or the old letters still show as relief
    nimg = next((n.image for m in obj.data.materials for n in m.node_tree.nodes if n.type == "TEX_IMAGE"
                 and any(l.to_node.type == "NORMAL_MAP" for l in n.outputs[0].links)), None)
    if nimg is not None:
        nW, nH = nimg.size
        npx = list(nimg.pixels)
        for tx, ty in paint:
            x, y = tx * nW // W, ty * nH // H
            npx[(y * nW + x) * 4:(y * nW + x) * 4 + 4] = [0.5, 0.5, 1.0, 1.0]
        nimg.pixels = npx
        nimg.pack()
    me = obj.data
    hit = {f for o, f in faces if o == obj}
    c = sum((me.polygons[f].center for f in hit), Vector()) / len(hit)
    n = sum((me.polygons[f].normal * me.polygons[f].area for f in hit), Vector()).normalized()
    if a.flatten:
        # move vertices that lie wholly inside the hit faces onto the faces' best-fit plane; the rim stays put
        inside = {v for f in hit for v in me.polygons[f].vertices}
        for poly in me.polygons:
            if poly.index not in hit:
                inside -= set(poly.vertices)
        for v in inside:
            co = me.vertices[v].co
            me.vertices[v].co = co - n * (co - c).dot(n)
        me.update()
        print(f"FLATTENED {len(inside)} vertices of {len(hit)} faces")
    if a.screen is not None:
        import bmesh
        # just in front of whatever relief is left, so nothing pokes through
        lift = max((me.vertices[v].co - c).dot(n) for f in hit for v in me.polygons[f].vertices) + 0.0002
        inv = obj.matrix_world.inverted()
        o = inv @ cam.location
        def on_plane(x, y):
            fx, fy = (x + 0.5) / a.res, (y + 0.5) / a.res
            d = inv @ tl.lerp(tr, fx).lerp(bl.lerp(br, fx), fy) - o
            return o + d * ((c + n * lift - o).dot(n) / d.dot(n))
        k = a.screen
        ring = [(x0 + k, y0), (x1 - k, y0), (x1, y0 + k), (x1, y1 - k),
                (x1 - k, y1), (x0 + k, y1), (x0, y1 - k), (x0, y0 + k)]
        mat = bpy.data.materials.new("Screen"); mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        # col is sRGB (texture space); the socket wants linear
        bsdf.inputs["Base Color"].default_value = [((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92
                                                   for v in col[:3]] + [1.0]
        bsdf.inputs["Roughness"].default_value = 0.15
        me.materials.append(mat)
        bm = bmesh.new(); bm.from_mesh(me)
        uvl = bm.loops.layers.uv.active
        face = bm.faces.new([bm.verts.new(on_plane(x, y)) for x, y in ring])
        face.material_index = len(me.materials) - 1
        face.normal_update()
        if face.normal.dot(n) < 0:
            face.normal_flip()
        for loop in face.loops:
            # back to pixel space for a 0..1 UV over the box
            x, y = next((x, y) for x, y in ring if (on_plane(x, y) - loop.vert.co).length < 1e-7)
            loop[uvl].uv = ((x - x0) / (x1 - x0), 1 - (y - y0) / (y1 - y0))
        bm.to_mesh(me); bm.free(); me.update()
        print(f"SCREEN surface added {lift * 1000:.2f} mm above the plane")
    bpy.ops.export_scene.gltf(filepath=a.fill, export_format="GLB", export_yup=True,
                              export_skins=True, export_animations=True)
    print(f"FILLED {len(paint)} texels with {[round(c * 255) for c in col[:3]]} -> {a.fill}")
