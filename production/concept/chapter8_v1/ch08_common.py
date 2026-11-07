"""Shared Blender helpers for the M3-8A Chapter 8 approval sheets (Blender 5.2, Cycles; no image generation, no credits).

Imported by build_ch08_scenes.py. Units are metres; scene frame for the lunar sites: X = map x - site x (toward 90 deg E),
Y = map y - site y (toward 0 deg E), Z = height - site height - (X^2 + Y^2) / 2R, so a Sun or Earth placed by its
JPL Horizons azimuth/elevation (sun_positions.json) meets the real LOLA horizon exactly as in the game
(game/assets/environment/terrain/lola/README.md).
"""
import json
import math
from pathlib import Path

import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector

ROOT = Path(__file__).resolve().parents[3]
LOLA = ROOT / "game/assets/environment/terrain/lola"
TERRAIN_TEX = ROOT / "game/assets/environment/terrain/textures"
ROCKS = ROOT / "game/assets/environment/terrain/rocks"
OUT = ROOT / "production/models/chapter8/render"
R_MOON = 1737400.0


# ------------------------------------------------------------------ scene and render

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    try:
        prefs.compute_device_type = "METAL"
        prefs.get_devices()
        for d in prefs.devices:
            d.use = True
        sc.cycles.device = "GPU"
    except Exception:
        sc.cycles.device = "CPU"
    sc.cycles.use_denoising = True
    sc.cycles.denoiser = "OPENIMAGEDENOISE"
    sc.cycles.samples = 96
    sc.cycles.max_bounces = 6
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"
    sc.render.film_transparent = False
    world = bpy.data.worlds.new("World")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0, 0, 0, 1)
    bg.inputs["Strength"].default_value = 0.0
    return sc


def render(cam, path, res=(1600, 900), samples=None):
    sc = bpy.context.scene
    sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    if samples:
        sc.cycles.samples = samples
    sc.render.image_settings.file_format = "PNG"
    sc.render.filepath = str(path)
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.render.render(write_still=True)
    print("RENDERED", path)


def camera(name, loc, target, lens=35.0, clip_end=200000.0, parent=None):
    cd = bpy.data.cameras.new(name)
    cd.lens = lens
    cd.clip_start = 0.05
    cd.clip_end = clip_end
    cd.sensor_width = 36.0
    cam = bpy.data.objects.new(name, cd)
    bpy.context.scene.collection.objects.link(cam)
    loc, target = Vector(loc), Vector(target)
    if parent is not None:
        loc, target = parent.matrix_world @ loc, parent.matrix_world @ target
    cam.location = loc
    cam.rotation_euler = (target - loc).to_track_quat("-Z", "Y").to_euler()
    return cam


def aim_camera(name, loc, direction, lens, parent=None):
    """Camera at loc looking along a world direction vector."""
    loc = Vector(loc)
    if parent is not None:
        loc = parent.matrix_world @ loc
    return camera(name, loc, loc + Vector(direction) * 100.0, lens)


# ------------------------------------------------------------------ directions on the Moon

def site_axes(lon_deg):
    """Local north (away from the pole) and east as map-frame unit vectors at longitude lon (south polar stereographic)."""
    lam = math.radians(lon_deg)
    north = Vector((math.sin(lam), math.cos(lam), 0.0))
    east = Vector((math.cos(lam), -math.sin(lam), 0.0))
    return north, east


def azel(az_deg, el_deg, north, east):
    az, el = math.radians(az_deg), math.radians(el_deg)
    return (north * (math.cos(az) * math.cos(el)) + east * (math.sin(az) * math.cos(el)) + Vector((0, 0, math.sin(el)))).normalized()


def sun_lamp(direction, strength=8.0, angle_deg=0.53):
    ld = bpy.data.lights.new("Sun", "SUN")
    ld.energy = strength
    ld.angle = math.radians(angle_deg)
    ob = bpy.data.objects.new("Sun", ld)
    bpy.context.scene.collection.objects.link(ob)
    ob.rotation_euler = Vector(direction).to_track_quat("Z", "Y").to_euler()
    return ob


def earth(direction, distance=60000.0, diameter_deg=1.899, seed=7):
    """Earth at its true angular size, lit by the scene's Sun lamp (so its phase is the real one for the dated row)."""
    r = distance * math.tan(math.radians(diameter_deg / 2))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=96, ring_count=48, radius=r, location=Vector(direction) * distance)
    ob = bpy.context.object
    ob.name = "Earth"
    bpy.ops.object.shade_smooth()
    m = bpy.data.materials.new("Earth")
    nt = m.node_tree
    nt.nodes.clear()
    o = nt.nodes.new("ShaderNodeOutputMaterial")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    land = nt.nodes.new("ShaderNodeTexNoise"); land.inputs["Scale"].default_value = 2.2; land.inputs["Detail"].default_value = 8
    cloud = nt.nodes.new("ShaderNodeTexNoise"); cloud.inputs["Scale"].default_value = 4.5; cloud.inputs["Detail"].default_value = 10
    cloud.inputs["Distortion"].default_value = 1.2
    nt.links.new(tc.outputs["Object"], land.inputs["Vector"]); nt.links.new(tc.outputs["Object"], cloud.inputs["Vector"])
    lr = nt.nodes.new("ShaderNodeValToRGB")
    lr.color_ramp.elements[0].position = 0.54; lr.color_ramp.elements[0].color = (0.010, 0.030, 0.090, 1)
    lr.color_ramp.elements[1].position = 0.56; lr.color_ramp.elements[1].color = (0.11, 0.10, 0.06, 1)
    cr = nt.nodes.new("ShaderNodeValToRGB")
    cr.color_ramp.elements[0].position = 0.50; cr.color_ramp.elements[0].color = (0, 0, 0, 1)
    cr.color_ramp.elements[1].position = 0.66; cr.color_ramp.elements[1].color = (1, 1, 1, 1)
    nt.links.new(land.outputs["Fac"], lr.inputs["Fac"]); nt.links.new(cloud.outputs["Fac"], cr.inputs["Fac"])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
    nt.links.new(cr.outputs["Color"], mix.inputs["Factor"]); nt.links.new(lr.outputs["Color"], mix.inputs["A"])
    mix.inputs["B"].default_value = (0.95, 0.96, 0.98, 1)
    bsdf = nt.nodes.new("ShaderNodeBsdfDiffuse")
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Color"]); nt.links.new(bsdf.outputs["BSDF"], o.inputs["Surface"])
    ob.data.materials.append(m)
    ob.visible_shadow = False
    return ob


# ------------------------------------------------------------------ materials

def srgb(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c) + (1.0,)


_MATS = {}


def mat(name, color=(0.8, 0.8, 0.8, 1), rough=0.5, metal=0.0, emit=None, emit_strength=0.0, spec=0.5, grain=0.0):
    if name in _MATS:
        return _MATS[name]
    m = bpy.data.materials.new(name)
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = color if len(color) == 4 else tuple(color) + (1,)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    b.inputs["Specular IOR Level"].default_value = spec
    if emit is not None:
        b.inputs["Emission Color"].default_value = emit
        b.inputs["Emission Strength"].default_value = emit_strength
    if grain:  # subtle wear: noise-driven roughness and colour variation, object space
        tc = nt.nodes.new("ShaderNodeTexCoord")
        n = nt.nodes.new("ShaderNodeTexNoise"); n.inputs["Scale"].default_value = 18.0; n.inputs["Detail"].default_value = 6
        nt.links.new(tc.outputs["Object"], n.inputs["Vector"])
        rr = nt.nodes.new("ShaderNodeMapRange")
        rr.inputs["To Min"].default_value = max(0.0, rough - grain); rr.inputs["To Max"].default_value = min(1.0, rough + grain)
        nt.links.new(n.outputs["Fac"], rr.inputs["Value"]); nt.links.new(rr.outputs["Result"], b.inputs["Roughness"])
        mx = nt.nodes.new("ShaderNodeMix"); mx.data_type = "RGBA"
        mx.inputs["Factor"].default_value = 0.0
        c = b.inputs["Base Color"].default_value
        mx.inputs["A"].default_value = tuple(c)
        mx.inputs["B"].default_value = (c[0] * 0.82, c[1] * 0.82, c[2] * 0.80, 1)
        nt.links.new(n.outputs["Fac"], mx.inputs["Factor"]); nt.links.new(mx.outputs["Result"], b.inputs["Base Color"])
    _MATS[name] = m
    return m


def palette():
    return {
        "white": mat("PaintWhite", srgb("#E4E6E8"), 0.55, grain=0.12),
        "beta": mat("BetaCloth", srgb("#EDEBE4"), 0.9, grain=0.05),
        "navy": mat("PaintNavy", srgb("#1F2A44"), 0.5, grain=0.1),
        "orange": mat("PaintOrange", srgb("#F26B21"), 0.45, grain=0.1),
        "gold": mat("MustardGold", srgb("#F2C230"), 0.45),
        "steel": mat("Steel", (0.62, 0.63, 0.65, 1), 0.32, metal=1.0, grain=0.08),
        "dark": mat("DarkMetal", (0.035, 0.037, 0.04, 1), 0.45, metal=0.6),
        "rubber": mat("Rubber", (0.02, 0.02, 0.02, 1), 0.8),
        "screen": mat("ScreenOff", (0.01, 0.012, 0.015, 1), 0.08, spec=0.9),
        "cell": mat("SolarCell", (0.012, 0.02, 0.06, 1), 0.18, metal=0.2, spec=0.8),
        "foil": mat("Foil", (0.85, 0.70, 0.35, 1), 0.22, metal=1.0, grain=0.15),
        "lamp_green": mat("LampGreen", (0.05, 0.3, 0.08, 1), 0.3, emit=(0.15, 1.0, 0.3, 1), emit_strength=6.0),
        "lamp_amber": mat("LampAmber", (0.3, 0.15, 0.02, 1), 0.3, emit=(1.0, 0.55, 0.1, 1), emit_strength=25.0),
        "lamp_off": mat("LampOff", (0.04, 0.05, 0.045, 1), 0.2, spec=0.8),
        "lamp_red": mat("LampRed", (0.3, 0.02, 0.02, 1), 0.3, emit=(1.0, 0.08, 0.05, 1), emit_strength=6.0),
        "reflector": mat("Reflector", srgb("#F26B21"), 0.25, emit=(1.0, 0.42, 0.13, 1), emit_strength=0.0, spec=1.0),
    }


def image_tex(nt, path, colour=True):
    im = bpy.data.images.load(str(path), check_existing=True)
    if not colour:
        im.colorspace_settings.name = "Non-Color"
    n = nt.nodes.new("ShaderNodeTexImage")
    n.image = im
    return n


def regolith(name="Regolith", kind="Fresh", tint=1.0, repeat_m=4.0, macro=True):
    """Kit regolith (M1-35 textures, one repeat per 4 m) with macro albedo variation; matte, no sheen."""
    if name in _MATS:
        return _MATS[name]
    m = bpy.data.materials.new(name)
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = 1.0
    b.inputs["Specular IOR Level"].default_value = 0.15
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping"); mp.inputs["Scale"].default_value = (1 / repeat_m, 1 / repeat_m, 1 / repeat_m)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    bc = image_tex(nt, TERRAIN_TEX / f"T_Regolith_{kind}_BaseColor.png")
    nm = image_tex(nt, TERRAIN_TEX / f"T_Regolith_{kind}_Normal.png", colour=False)
    nt.links.new(mp.outputs["Vector"], bc.inputs["Vector"]); nt.links.new(mp.outputs["Vector"], nm.inputs["Vector"])
    nmap = nt.nodes.new("ShaderNodeNormalMap"); nmap.inputs["Strength"].default_value = 1.2
    nt.links.new(nm.outputs["Color"], nmap.inputs["Color"]); nt.links.new(nmap.outputs["Normal"], b.inputs["Normal"])
    col = bc.outputs["Color"]
    if macro:
        n = nt.nodes.new("ShaderNodeTexNoise"); n.inputs["Scale"].default_value = 0.012; n.inputs["Detail"].default_value = 6
        nt.links.new(tc.outputs["Object"], n.inputs["Vector"])
        rr = nt.nodes.new("ShaderNodeMapRange"); rr.inputs["To Min"].default_value = 0.72 * tint; rr.inputs["To Max"].default_value = 1.18 * tint
        nt.links.new(n.outputs["Fac"], rr.inputs["Value"])
        mul = nt.nodes.new("ShaderNodeMix"); mul.data_type = "RGBA"; mul.blend_type = "MULTIPLY"; mul.inputs["Factor"].default_value = 1.0
        nt.links.new(col, mul.inputs["A"])
        nt.links.new(rr.outputs["Result"], mul.inputs["B"])
        col = mul.outputs["Result"]
    nt.links.new(col, b.inputs["Base Color"])
    _MATS[name] = m
    return m


# ------------------------------------------------------------------ meshes

def grid_mesh(name, xs, ys, z, material=None, hole=None, z_offset=0.0):
    """Quad grid; xs (ncols), ys (nrows) in metres, z (nrows, ncols). hole=(xmin,xmax,ymin,ymax) drops quads fully inside."""
    nr, nc = z.shape
    X, Y = np.meshgrid(xs, ys)
    verts = np.stack([X, Y, z + z_offset], axis=-1).reshape(-1, 3).astype(np.float32)
    i = np.arange(nr * nc).reshape(nr, nc)
    q = np.stack([i[:-1, :-1], i[1:, :-1], i[1:, 1:], i[:-1, 1:]], axis=-1).reshape(-1, 4)
    if hole is not None:
        cx = (X[:-1, :-1] + X[1:, 1:]) / 2
        cy = (Y[:-1, :-1] + Y[1:, 1:]) / 2
        inside = ((cx > hole[0]) & (cx < hole[1]) & (cy > hole[2]) & (cy < hole[3])).reshape(-1)
        q = q[~inside]
    # wind faces counter-clockwise seen from +Z whatever the y order
    if (ys[1] - ys[0]) * (xs[1] - xs[0]) < 0:
        q = q[:, ::-1]
    me = bpy.data.meshes.new(name)
    me.vertices.add(len(verts))
    me.vertices.foreach_set("co", verts.ravel())
    me.loops.add(q.size)
    me.loops.foreach_set("vertex_index", q.ravel().astype(np.int32))
    me.polygons.add(len(q))
    me.polygons.foreach_set("loop_start", np.arange(0, q.size, 4, dtype=np.int32))
    me.update(calc_edges=True)
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    for p in me.polygons:
        pass
    me.shade_smooth() if hasattr(me, "shade_smooth") else None
    if material:
        me.materials.append(material)
    return ob


def load_heightmap(region, mpp, detail=False):
    stem = f"heightmap_{mpp}m" + ("_detail" if detail else "")
    meta = json.loads((LOLA / region / f"{stem}.json").read_text())
    raw = np.fromfile(LOLA / region / f"{stem}.r16", dtype="<u2").reshape(meta["rows"], meta["columns"])
    h = meta["z_min_m"] + raw.astype(np.float64) * (meta["z_max_m"] - meta["z_min_m"]) / 65535.0
    return h, meta


def map_axes(meta, site_x, site_y):
    """Scene-frame x of each column and y of each row (row 0 is the top = largest map y)."""
    m = meta["metres_per_pixel"]
    xs = meta["origin_x_m"] + np.arange(meta["columns"]) * m - site_x
    ys = meta["origin_y_m"] - np.arange(meta["rows"]) * m - site_y
    return xs, ys


def curvature(xs, ys):
    X, Y = np.meshgrid(xs, ys)
    return (X ** 2 + Y ** 2) / (2 * R_MOON)


def bilinear(h, xs, ys, px, py):
    """Sample grid h (rows=ys descending or ascending, cols=xs ascending) at scene points px, py (arrays)."""
    fx = (px - xs[0]) / (xs[1] - xs[0])
    fy = (py - ys[0]) / (ys[1] - ys[0])
    c0 = np.clip(np.floor(fx).astype(int), 0, len(xs) - 2)
    r0 = np.clip(np.floor(fy).astype(int), 0, len(ys) - 2)
    tx, ty = np.clip(fx - c0, 0, 1), np.clip(fy - r0, 0, 1)
    return (h[r0, c0] * (1 - tx) * (1 - ty) + h[r0, c0 + 1] * tx * (1 - ty) + h[r0 + 1, c0] * (1 - tx) * ty + h[r0 + 1, c0 + 1] * tx * ty)


def craters(px, py, rng, n, dmin, dmax, area, depth=0.12):
    """Sum of bowl-shaped craters with raised rims (authored sub-resolution detail, not survey data)."""
    z = np.zeros_like(px)
    (x0, x1, y0, y1) = area
    # power-law diameters: many small, few large
    u = rng.random(n)
    a = 1.8
    d = (dmin ** -a - u * (dmin ** -a - dmax ** -a)) ** (-1 / a)
    cx, cy = rng.uniform(x0, x1, n), rng.uniform(y0, y1, n)
    for k in range(n):
        r = d[k] / 2
        dd = np.hypot(px - cx[k], py - cy[k]) / r
        m = dd < 1.6
        if not m.any():
            continue
        t = dd[m]
        dep = depth * d[k] * rng.uniform(0.6, 1.2)
        bowl = np.where(t < 1, -dep * (1 - t ** 2), 0.0)
        rim = 0.25 * dep * np.exp(-((t - 1.0) / 0.22) ** 2)
        z[m] += bowl + rim
    return z


# ------------------------------------------------------------------ primitives

def _link(ob, parent=None, material=None):
    if material is not None:
        ob.data.materials.clear()
        ob.data.materials.append(material)
    if parent is not None:
        ob.parent = parent
    return ob


def box(name, size, loc, material=None, parent=None, rot=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    ob = bpy.context.object
    ob.name = name
    ob.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = ob.modifiers.new("Bevel", "BEVEL"); mod.width = bevel; mod.segments = 2
        mod.limit_method = "ANGLE"
    return _link(ob, parent, material)


def cyl(name, r, depth, loc, material=None, parent=None, rot=(0, 0, 0), verts=32, smooth=True):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    ob = bpy.context.object
    ob.name = name
    if smooth:
        bpy.ops.object.shade_auto_smooth() if hasattr(bpy.ops.object, "shade_auto_smooth") else bpy.ops.object.shade_smooth()
    return _link(ob, parent, material)


def sphere(name, r, loc, material=None, parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=r, location=loc)
    ob = bpy.context.object
    ob.name = name
    bpy.ops.object.shade_smooth()
    return _link(ob, parent, material)


def tube(name, points, r, material=None, parent=None):
    """Cable or rail along a polyline (curve with bevel)."""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = r
    cu.bevel_resolution = 3
    sp = cu.splines.new("POLY")
    sp.points.add(len(points) - 1)
    for p, c in zip(sp.points, points):
        p.co = (c[0], c[1], c[2], 1)
    ob = bpy.data.objects.new(name, cu)
    bpy.context.scene.collection.objects.link(ob)
    if material:
        cu.materials.append(material)
    if parent is not None:
        ob.parent = parent
    return ob


def dish(name, diameter, depth, material, parent=None, segments=48, rings=12):
    """Parabolic reflector, vertex at the origin, opening toward +Z."""
    import bmesh
    bm = bmesh.new()
    rmax = diameter / 2
    f = rmax ** 2 / (4 * depth)
    rows = []
    for i in range(rings + 1):
        r = rmax * i / rings
        z = r * r / (4 * f)
        row = []
        for j in range(segments if i else 1):
            a = 2 * math.pi * j / segments
            row.append(bm.verts.new((r * math.cos(a), r * math.sin(a), z)))
        rows.append(row)
    for j in range(segments):
        bm.faces.new((rows[0][0], rows[1][j], rows[1][(j + 1) % segments]))
    for i in range(1, rings):
        for j in range(segments):
            a, b2 = rows[i][j], rows[i][(j + 1) % segments]
            c, d = rows[i + 1][(j + 1) % segments], rows[i + 1][j]
            bm.faces.new((a, d, c, b2))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    sol = ob.modifiers.new("Solid", "SOLIDIFY"); sol.thickness = 0.025
    for p in me.polygons:
        p.use_smooth = True
    me.materials.append(material)
    if parent is not None:
        ob.parent = parent
    return ob, f


def empty(name, loc=(0, 0, 0), rot=(0, 0, 0), parent=None):
    ob = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = rot
    if parent is not None:
        ob.parent = parent
    return ob


def import_glb(path, name=None):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.type == "EMPTY" and not o.children:
            pass
    meshes = [o for o in new if o.type == "MESH"]
    if name and meshes:
        meshes[0].name = name
    return new


def point_light(name, loc, energy, color=(1, 1, 1), radius=0.05, kind="POINT", spot_deg=None, direction=None):
    ld = bpy.data.lights.new(name, kind)
    ld.energy = energy
    ld.color = color
    if kind in ("POINT", "SPOT"):
        ld.shadow_soft_size = radius
    if kind == "SPOT" and spot_deg:
        ld.spot_size = math.radians(spot_deg)
        ld.spot_blend = 0.35
    if kind == "AREA":
        ld.size = radius
    ob = bpy.data.objects.new(name, ld)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = loc
    if direction is not None:
        ob.rotation_euler = Vector(direction).to_track_quat("-Z", "Y").to_euler()
    return ob
