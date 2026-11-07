"""EN_MalapertSummit (LOC-12) approval renders for M3-8A: the real LOLA summit (PGDA Site23 5 m + the authored crater
layer, malapert_vista 40 m to the horizon, lunar curvature), the dated Sun and Earth of EX-CH08-S10 (JPL Horizons rows in
sun_positions.json), the 30 x 20 m graded work platform and its pieces (summit_kit.py). Blender 5.2 Cycles, no credits.

    python3 production/tools/heavy.py blender -b --factory-startup --python production/concept/chapter8_v1/build_summit.py -- [--quick]

Writes production/models/chapter8/render/summit_*.png (git-ignored); the sheet is composed by compose_ch08.py.
"""
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import ch08_common as C  # noqa: E402
import summit_kit as K  # noqa: E402

QUICK = "--quick" in sys.argv
SUN = 24.0  # W/m2-equivalent; exposure for grazing polar light (flat ground gets sin 2.3 deg of it)
HERE = Path(__file__).resolve().parent
LAYOUT = json.loads((HERE / "summit_layout.json").read_text())
SKY = LAYOUT["dated_sky"]
OUT = C.OUT


def terrain(theta):
    """Near patch (0.5 m, +-80 m, graded pad), mid (hero 5 m data at 10 m, +-4 km), far (vista 40 m at 80 m, +-32 km)."""
    rng = np.random.default_rng(80412)
    h5, m5 = C.load_heightmap("malapert_summit", 5, detail=True)
    site = m5["site"]
    xs5, ys5 = C.map_axes(m5, site["x_m"], site["y_m"])
    z5 = h5 - site["height_m"]
    # near patch
    half, step = 80.0, 0.5
    xs = np.arange(-half, half + step / 2, step)
    ys = np.arange(-half, half + step / 2, step)
    X, Y = np.meshgrid(xs, ys)
    base = C.bilinear(z5, xs5, ys5, X, Y)
    base += C.craters(X, Y, rng, 900, 0.4, 9.0, (-half - 5, half + 5, -half - 5, half + 5), depth=0.11)
    base += 0.04 * np.sin(X * 1.7 + np.cos(Y * 1.3)) * np.cos(Y * 2.1)
    # platform frame coordinates
    c, s = math.cos(theta), math.sin(theta)
    XL, YL = c * X + s * Y, -s * X + c * Y
    x0, x1, y0, y1 = LAYOUT["pad_bounds"]
    inside = (XL > x0) & (XL < x1) & (YL > y0) & (YL < y1)
    # the pad is cut level just under the crown and filled outward (a pad at the median height would put the crown
    # between the crew and Earth, which sits only 2 deg above the summit skyline)
    grade = -0.3
    dx = np.maximum(np.maximum(x0 - XL, XL - x1), 0)
    dy = np.maximum(np.maximum(y0 - YL, YL - y1), 0)
    dist = np.hypot(dx, dy) - 1.5  # 1.5 m graded apron round the pad
    t = np.clip(dist / 8.0, 0, 1)
    t = t * t * (3 - 2 * t)
    zn = grade * (1 - t) + base * t
    zn += 0.008 * rng.standard_normal(zn.shape) * (t > 0.2)
    near = C.grid_mesh("Terrain_Near", xs, ys, zn, C.regolith("Regolith"))
    # compacted pad decal: a thin plane in the platform frame
    pad = C.grid_mesh("PadSurface", np.linspace(x0 - 1.4, x1 + 1.4, 2), np.linspace(y0 - 1.4, y1 + 1.4, 2), np.full((2, 2), grade + 0.004), C.regolith("RegolithPad", "Fresh", tint=0.9))
    pad.rotation_euler = (0, 0, theta)
    # mid: 10 m from the 5 m detail grid
    sl = slice(None, None, 2)
    zm = z5[sl, sl] - C.curvature(xs5[sl], ys5[sl])
    C.grid_mesh("Terrain_Mid", xs5[sl], ys5[sl], zm, C.regolith("Regolith"), hole=(-78, 78, -78, 78), z_offset=-0.05)
    # far: vista 40 m at 80 m
    hv, mv = C.load_heightmap("malapert_vista", 40)
    xsv, ysv = C.map_axes(mv, site["x_m"], site["y_m"])
    zv = (hv - site["height_m"])[sl, sl] - C.curvature(xsv[sl], ysv[sl])
    C.grid_mesh("Terrain_Far", xsv[sl], ysv[sl], zv, C.regolith("RegolithFar", "Fresh", repeat_m=40.0), hole=(-3900, 3900, -3900, 3900), z_offset=-1.0)
    return grade, (xs, ys, zn), near


def scatter_rocks(near_grid, theta, n=520):
    xs, ys, zn = near_grid
    forms = sorted(p for p in C.ROCKS.glob("EN_LunarRock_*_LOD0.glb"))
    protos = []
    for p in forms:
        objs = C.import_glb(p)
        for o in objs:
            if o.type == "MESH":
                o.hide_render = True
                o.data.materials.clear()
                o.data.materials.append(C.regolith("RockMat", "Fresh", tint=0.85, repeat_m=1.0, macro=False))
                protos.append(o)
    rng = np.random.default_rng(1207)
    c, s = math.cos(theta), math.sin(theta)
    placed = 0
    while placed < n:
        x, y = rng.uniform(-75, 75, 2)
        xl, yl = c * x + s * y, -s * x + c * y
        if -18 < xl < 18 and -13 < yl < 13:
            continue
        if yl > 8 and abs(xl - 2.0) < 0.45 * (yl - 4.0):  # keep the line of sight to Earth clear (az ~359)
            continue
        size = float(np.clip(rng.pareto(2.2) * 0.12 + 0.05, 0.05, 1.6))
        proto = protos[int(rng.integers(len(protos)))]
        dup = proto.copy()
        bpy.context.scene.collection.objects.link(dup)
        dup.hide_render = False
        k = size / max(proto.dimensions)
        dup.scale = (k * rng.uniform(0.8, 1.2), k * rng.uniform(0.8, 1.2), k * rng.uniform(0.6, 1.0))
        z = float(C.bilinear(zn, xs, ys, np.array([x]), np.array([y]))[0])
        dup.location = (x, y, z - 0.3 * size)
        dup.rotation_mode = "XYZ"
        dup.rotation_euler = (rng.uniform(-0.3, 0.3), rng.uniform(-0.3, 0.3), rng.uniform(0, 6.28))
        placed += 1


def build(state="dark", door=0.0):
    sc = C.reset()
    pal = C.palette()
    north, east = C.site_axes(357.6652468663214)
    theta = math.atan2(-north.x, north.y)  # rotate platform +y onto local north
    grade, near_grid, near = terrain(theta)
    scatter_rocks(near_grid, theta, 160 if QUICK else 520)
    P = C.empty("Platform", (0, 0, grade), (0, 0, theta))
    K.relay_deck(P, (-5.0, 5.5), pal)
    K.controller_housing(P, (-4.0, 1.4), pal, door_open_deg=door, state=state)
    K.power_isolator(P, (-3.3, 0.2), pal, isolated=(state == "dark"))
    K.control_pedestal(P, (-1.8, 2.8), pal, lit=(state == "green"))
    K.solar_mast(P, (-11.5, 5.0), pal)
    for i, a in enumerate(LAYOUT["pieces"][8]["at"]):
        K.tether_anchor(P, a, pal, f"Anchor{i}")
    C.tube("tether_line", [(-8.5, -0.5, 0.7), (-4.5, -0.55, 0.55), (-0.5, -0.5, 0.7)], 0.006, C.mat("TetherYellow", C.srgb("#F2C230"), 0.6), P)
    x0, x1, y0, y1 = LAYOUT["pad_bounds"]
    for x in range(int(x0), int(x1) + 1, 5):
        for y in (y0, y1):
            K.perimeter_marker(P, (x, y), pal)
    for y in range(int(y0) + 5, int(y1), 5):
        for x in (x0, x1):
            K.perimeter_marker(P, (x, y), pal)
    K.viewpoint(P, (6.0, 9.3), pal)
    K.cable_tray(P, [(-11.5, 3.5), (-11.5, 0.2), (-3.5, 0.2)], pal, "tray_power")
    K.cable_tray(P, [(-4.0, 2.2), (-4.0, 3.2), (-4.6, 3.6)], pal, "tray_deck")
    K.cable_tray(P, [(-1.8, 2.2), (-1.8, 0.6), (3.0, 0.6)], pal, "tray_data")
    # rover, heading west, cabin toward the housing
    rov = [o for o in C.import_glb(C.ROOT / "game/assets/vehicles/VH_Rover/VH_Rover.glb") if o.type == "MESH"][0]
    rov.parent = P
    rov.rotation_mode = "XYZ"  # the glTF importer leaves quaternion mode, which ignores rotation_euler
    rov.location = (7.6, -1.0, 0.0)
    rov.rotation_euler = (0, 0, math.radians(180))  # GLB front is +X; heading west
    bpy.context.view_layer.update()
    lo = min((rov.matrix_world @ Vector(cn)).z for cn in rov.bound_box)
    rov.location.z -= lo - grade
    K.umbilical_post(P, (3.2, 0.4), pal, rover_port=(5.0, -0.2, 0.9))
    # tyre tracks on the pad
    trk = C.regolith("Tracks", "Disturbed", tint=0.8)
    for off in (-1.55, 1.55):
        pts = [(12.0 + off * 0.2, -10.5), (10.5 + off * 0.3, -5.0), (9.0, -1.0 + off)]
        for (a, b) in zip(pts[:-1], pts[1:]):
            L = math.hypot(b[0] - a[0], b[1] - a[1]); ang = math.atan2(b[1] - a[1], b[0] - a[0])
            C.box("track", (L, 0.55, 0.006), ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, 0.006), trk, P, rot=(0, 0, ang))
    # sky
    sun_dir = C.azel(SKY["sun_az_deg"], SKY["sun_el_deg"], north, east)
    earth_dir = C.azel(SKY["earth_az_deg"], SKY["earth_el_deg"], north, east)
    C.sun_lamp(sun_dir, strength=SUN)
    C.earth(earth_dir)
    bpy.context.view_layer.update()
    return sc, P, north, east, sun_dir, earth_dir, grade


def main():
    res = (960, 540) if QUICK else (1920, 1080)
    smp = 24 if QUICK else 160
    sc, P, north, east, sun_dir, earth_dir, grade = build(state="dark", door=0.0)
    # A: toward Earth across the platform (S06/S08 mood), Sun 36 deg off frame right
    cam = C.aim_camera("A", (2.5, -9.5, 1.6), C.azel(343.0, -1.8, north, east), 35, parent=P)
    for c in (cam,):
        hit = bpy.context.scene.ray_cast(bpy.context.view_layer.depsgraph, c.location, earth_dir)
        print("EARTH_RAY", c.name, hit[0], hit[4].name if hit[4] else None)
    C.render(cam, OUT / "summit_A_toward_earth.png", res, smp)
    # B: lit overview from the north-east, Sun behind the camera
    camB = C.camera("B", (18.0, 24.0, 10.5), (-3.0, 2.0, 0.0), 30, parent=P)
    C.render(camB, OUT / "summit_B_overview.png", res, smp)
    # D: Earth from the viewpoint, 200 mm
    camD = C.aim_camera("D", (6.0, 8.6, 1.6), earth_dir + Vector((0, 0, 0.012)), 200, parent=P)
    hit = bpy.context.scene.ray_cast(bpy.context.view_layer.depsgraph, camD.location, earth_dir)
    print("EARTH_RAY D", hit[0], hit[4].name if hit[4] else None)
    C.render(camD, OUT / "summit_D_earth_200mm.png", (1600, 900) if not QUICK else (800, 450), smp)
    # C: the housing, door open, isolated (S07), rover work light from the pad
    for o in list(bpy.data.objects):
        if o.name.startswith("door_hinge"):
            o.rotation_euler.z = math.radians(105)
    C.point_light("RoverFlood", P.matrix_world @ Vector((4.9, -0.2, 2.2)), 900, (1.0, 0.96, 0.9), 0.3, "SPOT", 40, (P.matrix_world @ Vector((-3.6, 1.5, 0.9))) - (P.matrix_world @ Vector((4.9, -0.2, 2.2))))
    camC = C.camera("C", (-0.6, -0.4, 1.55), (-3.9, 1.5, 0.95), 32, parent=P)
    C.render(camC, OUT / "summit_C_housing.png", res, smp)


main()
