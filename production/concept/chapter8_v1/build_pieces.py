"""Studio turntable stills of the EN_MalapertSummit and EN_RelayRoad pieces for the M3-8A sheets (Blender 5.2 Cycles,
grey cyclorama, one soft key; the same builders as the terrain scenes). No credits.

    python3 production/tools/heavy.py blender -b --factory-startup --python production/concept/chapter8_v1/build_pieces.py
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import ch08_common as C  # noqa: E402
import road_kit as RK  # noqa: E402
import summit_kit as K  # noqa: E402

PIECES = [
    ("summit_relay_deck", lambda P, pal: K.relay_deck(P, (0, 0), pal), (8.5, -8.0, 5.0)),
    ("summit_housing", lambda P, pal: K.controller_housing(P, (0, 0), pal, door_open_deg=105, state="green"), (2.6, -2.2, 1.7)),
    ("summit_isolator", lambda P, pal: K.power_isolator(P, (0, 0), pal, isolated=True), (1.5, -1.2, 1.4)),
    ("summit_pedestal", lambda P, pal: K.control_pedestal(P, (0, 0), pal, lit=True), (2.9, -1.9, 2.1)),
    ("summit_solar", lambda P, pal: K.solar_mast(P, (0, 0), pal, face_az=200), (6.0, -6.5, 3.4)),
    ("summit_ground", lambda P, pal: (K.tether_anchor(P, (-0.6, 0), pal), K.perimeter_marker(P, (0.4, 0.3), pal), K.umbilical_post(P, (1.3, -0.2), pal)), (2.6, -3.0, 1.6)),
    ("summit_viewpoint", lambda P, pal: K.viewpoint(P, (0, 0), pal), (2.8, -3.2, 2.0)),
    ("road_repeater", lambda P, pal: (RK.repeater(P, (0, 0), pal, yaw_back=200, yaw_fwd=20, state="lit", bay_open=True), RK.battery_module(P, (0.75, -0.6), pal)), (4.2, -4.6, 2.6)),
    ("road_guide_light", lambda P, pal: RK.guide_light(P, (0, 0), pal, lit=True), (1.0, -1.1, 0.8)),
    ("road_slope_sign", lambda P, pal: RK.slope_sign(P, (0, 0), pal, yaw=0), (0.5, -3.2, 0.25)),
    ("road_turnback", lambda P, pal: RK.turnback_barrier(P, (0, 0), pal, yaw=0), (3.2, -5.0, 2.0)),
    ("road_cache", lambda P, pal: RK.supply_cache(P, (0, 0), pal, yaw=0), (1.9, -2.4, 1.6)),
]


def studio():
    sc = C.reset()
    sc.cycles.samples = 64
    w = sc.world.node_tree.nodes["Background"]
    w.inputs["Color"].default_value = (0.5, 0.5, 0.52, 1)
    w.inputs["Strength"].default_value = 0.55
    sc.view_settings.look = "AgX - Base Contrast"
    floor = C.box("cyc", (40, 40, 0.02), (0, 0, -0.01), C.mat("Cyc", (0.42, 0.42, 0.43, 1), 0.9))
    key = C.point_light("Key", (4.0, -5.0, 7.0), 2500, (1, 0.98, 0.95), 3.0, "AREA", None, Vector((-4.0, 5.0, -7.0)))
    key.data.size = 4.0
    return sc


def main():
    only = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for name, make, cam_at in PIECES:
        if only and name not in only:
            continue
        studio()
        pal = C.palette()
        P = C.empty("P")
        make(P, pal)
        bpy.context.view_layer.update()
        pts = [o.matrix_world @ Vector(c) for o in bpy.data.objects if o.type in ("MESH", "CURVE") and o.name != "cyc" and not o.hide_render for c in o.bound_box]
        lo = Vector([min(p[i] for p in pts) for i in range(3)])
        hi = Vector([max(p[i] for p in pts) for i in range(3)])
        centre = (lo + hi) / 2
        cam = C.camera("cam", centre + Vector(cam_at), centre, 50)
        C.render(cam, C.OUT / f"piece_{name}.png", (720, 720), 64)
        print("SIZE", name, [round(v, 2) for v in (hi - lo)])
        C._MATS.clear()


main()
