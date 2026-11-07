"""EN_RelayRoad (LOC-11) approval renders for M3-8A: the marker-two service pad (repeater R2, M3-7A route simulator) on the
real LOLA terrain (LDEM_80S_40MPP_ADJ round the pad plus the authored crater layer; the 80 m relay corridor to the
horizon; lunar curvature), in the dark of EX-CH08-S04 (8 Apr 2047 10:00 UTC: the Sun 0.06 deg under the horizon at
azimuth 53, so only high distant ground catches it). Light comes from the rover, the guide lights and the repeater.

    python3 production/concept/chapter8_v1/road_data.py
    python3 production/tools/heavy.py blender -b --factory-startup --python production/concept/chapter8_v1/build_road.py -- [--quick]
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
import road_kit as RK  # noqa: E402

QUICK = "--quick" in sys.argv
DATA = C.ROOT / "production/models/chapter8/data"
SUN_ROW = {"az": 52.898, "el": -0.056}  # sun_positions.json EX-CH08-S04 (relay_road_mid row)
SPUR_AZ = 247.8  # pad -> main road (road_data.py spur_r2)


def terrain(theta, site_h):
    rng = np.random.default_rng(4102)
    g = json.loads((DATA / "r2_40m.json").read_text())
    a = np.load(DATA / "r2_40m.npy").astype(np.float64)
    xs40 = g["origin_x_m"] + np.arange(g["cols"]) * g["mpp"] - g["site_x"]
    ys40 = g["origin_y_m"] - np.arange(g["rows"]) * g["mpp"] - g["site_y"]
    z40 = a - site_h
    half, step = 140.0, 0.5
    xs = np.arange(-half, half + step / 2, step)
    ys = np.arange(-half, half + step / 2, step)
    X, Y = np.meshgrid(xs, ys)
    base = C.bilinear(z40, xs40, ys40, X, Y)
    base += C.craters(X, Y, rng, 1100, 0.4, 22.0, (-half - 10, half + 10, -half - 10, half + 10), depth=0.12)
    c, s = math.cos(theta), math.sin(theta)
    XL, YL = c * X + s * Y, -s * X + c * Y
    # service pad 20 x 15 m graded level at the pad height, spur road graded 5 m wide toward the main road
    grade = float(C.bilinear(z40, xs40, ys40, np.array([0.0]), np.array([0.0]))[0])
    dx = np.maximum(np.abs(XL) - 10, 0); dy = np.maximum(np.abs(YL) - 7.5, 0)
    t = np.clip((np.hypot(dx, dy) - 1.0) / 6.0, 0, 1); t = t * t * (3 - 2 * t)
    z = grade * (1 - t) + base * t
    sa = math.radians(SPUR_AZ)
    ux, uy = math.sin(sa), math.cos(sa)
    along = XL * ux + YL * uy
    across = -XL * uy + YL * ux
    road = (along > 0) & (np.abs(across) < 6.0)
    smooth = C.bilinear(z40, xs40, ys40, X, Y)  # the road follows the surveyed grade, without the small craters
    tr = np.clip((np.abs(across) - 2.5) / 3.5, 0, 1)
    z = np.where(road, z * tr + np.minimum(smooth, z + 0.3) * (1 - tr), z)
    near = C.grid_mesh("Terrain_Near", xs, ys, z, C.regolith("Regolith"))
    zm = z40 - C.curvature(xs40, ys40)
    C.grid_mesh("Terrain_Mid", xs40, ys40, zm, C.regolith("RegolithMid", repeat_m=16.0), hole=(-138, 138, -138, 138), z_offset=-0.4)
    hc, mc = C.load_heightmap("relay_road", 80)
    xsc, ysc = C.map_axes(mc, g["site_x"], g["site_y"])
    sl = slice(None, None, 2)
    zc = (hc - site_h)[sl, sl] - C.curvature(xsc[sl], ysc[sl])
    C.grid_mesh("Terrain_Far", xsc[sl], ysc[sl], zc, C.regolith("RegolithFar", repeat_m=60.0), hole=(-5800, 5800, -5800, 5800), z_offset=-3.0)
    return grade, (xs, ys, z)


def surface_z(grid, x, y):
    xs, ys, z = grid
    return float(C.bilinear(z, xs, ys, np.array([x]), np.array([y]))[0])


def main():
    sc = C.reset()
    sc.cycles.max_bounces = 4
    pal = C.palette()
    g = json.loads((DATA / "r2_40m.json").read_text())
    lam = math.degrees(math.atan2(g["site_x"], g["site_y"])) % 360
    north, east = C.site_axes(lam)
    theta = math.atan2(-north.x, north.y)
    grade, grid = terrain(theta, g["site_h"])
    P = C.empty("Pad", (0, 0, grade), (0, 0, theta))
    c, s = math.cos(theta), math.sin(theta)

    def local_to_scene(x, y):
        return c * x - s * y, s * x + c * y

    RK.repeater(P, (0.0, 4.0), pal, yaw_back=SPUR_AZ, yaw_fwd=40.0, state="dark", bay_open=True)
    RK.battery_module(P, (0.75, 3.2), pal)               # the replacement, set down on the pad
    RK.battery_module(P, (-0.7, 3.0), pal).rotation_euler = (0, 0, 0.5)  # the old one, lifted out
    RK.tether_anchor(P, (2.0, 5.5), pal, "Anchor")
    C.tube("tether", [(2.0, 5.5, 0.7), (1.0, 4.6, 0.5), (0.2, 4.1, 0.9)], 0.006, C.mat("TetherYellow", C.srgb("#F2C230"), 0.6), P)
    for x in (-10, 0, 10):
        for y in (-7.5, 7.5):
            RK.perimeter_marker(P, (x, y), pal)
    for y in (0,):
        for x in (-10, 10):
            RK.perimeter_marker(P, (x, y), pal)
    # guide lights down the spur, alternating sides every 18 m
    sa = math.radians(SPUR_AZ)
    ux, uy = math.sin(sa), math.cos(sa)
    for k in range(9):
        d = 14 + k * 18
        side = 3.4 if k % 2 == 0 else -3.4
        lx, ly = ux * d - uy * side, uy * d + ux * side
        sx, sy = local_to_scene(lx, ly)
        gl = RK.guide_light(P, (lx, ly), pal)
        gl.location.z = surface_z(grid, sx, sy) - grade
    rov = [o for o in C.import_glb(C.ROOT / "game/assets/vehicles/VH_Rover/VH_Rover.glb") if o.type == "MESH"][0]
    rov.parent = P
    rov.rotation_mode = "XYZ"
    R3 = P.matrix_world.to_3x3()

    def park(x, y, heading, roof=True):
        """Place the rover (the GLB's cabin end is -Y, so rotation = 180 - heading) and rebuild its lights."""
        for o in [o for o in bpy.data.objects if o.name.startswith(("Headlight", "RoofFlood", "CabinGlow"))]:
            bpy.data.objects.remove(o)
        h = math.radians(heading)
        rov.location = (x, y, 0.0)
        rov.rotation_euler = (0, 0, math.radians(180 - heading))
        bpy.context.view_layer.update()
        rov.location.z -= min((rov.matrix_world @ Vector(cn)).z for cn in rov.bound_box) - grade
        bpy.context.view_layer.update()
        cen = sum((rov.matrix_world @ Vector(cn) for cn in rov.bound_box), Vector()) / 8.0
        fwd_w = R3 @ Vector((math.sin(h), math.cos(h), 0))
        side_w = R3 @ Vector((math.cos(h), -math.sin(h), 0))
        for k, sd in enumerate((-0.9, 0.9)):
            pos = cen + fwd_w * 3.45 + side_w * sd
            pos.z = grade + 1.15
            C.point_light(f"Headlight{k}", pos, 4200, (0.92, 0.95, 1.0), 0.12, "SPOT", 55, fwd_w + Vector((0, 0, -0.12)))
        glow = cen + fwd_w * 1.4
        glow.z = grade + 1.9
        C.point_light("CabinGlow", glow, 40, (1.0, 0.8, 0.55), 0.4)
        if roof:  # roof work floods: an EVA stop is worked under the rover's own lights
            for k, sd in enumerate((-1.6, 1.6)):
                r = cen + fwd_w * 1.0 + side_w * sd
                r.z = grade + 4.6
                C.point_light(f"RoofFlood{k}", r, 5200, (0.95, 0.97, 1.0), 0.3, "SPOT", 95, fwd_w * 0.9 + side_w * (sd * 0.15) + Vector((0, 0, -1.0)))

    park(-6.5, -1.5, 50.0)  # stopped on the pad, facing the repeater
    # a crew member's helmet lamp on the rover's near side (Rafi checking the tether point)
    C.point_light("HelmetLamp", P.matrix_world @ Vector((-9.5, -6.5, 1.7)), 420, (0.95, 0.97, 1.0), 0.08, "SPOT", 50, R3 @ Vector((0.45, 0.75, -0.12)))
    C.point_light("WorkLight", P.matrix_world @ Vector((-1.2, 1.6, 2.2)), 220, (0.95, 0.97, 1.0), 0.25, "SPOT", 70, R3 @ Vector((0.6, 1.0, -0.9)))
    # turnback zone and slope sign where the apparent bypass leaves the spur toward the steep south-west slope
    bx, by = ux * 40 - uy * -9, uy * 40 + ux * -9
    bsx, bsy = local_to_scene(bx, by)
    tb = RK.turnback_barrier(P, (bx, by), pal, yaw=SPUR_AZ + 90 - 35)
    tb.location.z = surface_z(grid, bsx, bsy) - grade
    sg = RK.slope_sign(P, (bx + 1.6, by + 2.4), pal, yaw=SPUR_AZ + 180 - 35)
    sg.location.z = surface_z(grid, *local_to_scene(bx + 1.6, by + 2.4)) - grade
    sun = C.azel(SUN_ROW["az"], SUN_ROW["el"], north, east)
    C.sun_lamp(sun, strength=24.0)
    bpy.context.view_layer.update()
    res = (960, 540) if QUICK else (1920, 1080)
    smp = 32 if QUICK else 192
    camA = C.camera("A", (-15.0, -23.0, 8.0), (-1.5, 1.0, 0.4), 30, parent=P)
    C.faint_stars(True)  # ART_BIBLE 2 rule 12: no sunlit surface in this frame, so faint stars
    C.render(camA, C.OUT / "road_A_marker_two.png", res, smp)
    C.faint_stars(False)  # B has no sky; C shows the sunlit far horizon, so its sky stays black
    camB = C.camera("B", (-1.6, 1.9, 1.45), (0.05, 3.95, 0.5), 30, parent=P)
    C.render(camB, C.OUT / "road_B_battery_bay.png", res, smp)
    # after the swap: beacon and both link lamps lit, bay closed
    for o in list(bpy.data.objects):
        if o.name.startswith("bay_lid"):
            o.rotation_euler.x = 0.0
        if o.name.startswith(("ring_lamp", "link_lamp")):
            o.data.materials.clear()
            o.data.materials.append(pal["lamp_amber"] if o.name.startswith("ring_lamp") else pal["lamp_green"])
    C.point_light("BeaconGlow", P.matrix_world @ Vector((0.0, 4.0, 2.78)), 25, (1.0, 0.55, 0.15), 0.2)
    for o in [o for o in bpy.data.objects if o.name.startswith(("WorkLight", "BatteryModule", "HelmetLamp"))]:
        o.hide_render = True
    for o in bpy.data.objects:
        if o.parent and o.parent.name.startswith("BatteryModule"):
            o.hide_render = True
    park(ux * 26, uy * 26, SPUR_AZ, roof=False)  # "Test both neighbours. Then continue."
    camC = C.aim_camera("C", (5.5, 8.5, 1.9), C.azel(SPUR_AZ - 8, -2.0, north, east), 28, parent=P)
    C.render(camC, C.OUT / "road_C_marker_lit.png", res, smp)


main()
