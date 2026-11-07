"""EN_RelayRoad pieces for the M3-8A sheet (procedural Blender geometry; platform frame x = local east, y = local north,
z up, metres). The repeater keeps PR_SurveyBeacon's language (white head, navy trim, orange ring lamp, tripod with
ballast feet) at the route simulator's 3 m mast height (production/tools/route_simulator_data.py MAST_M)."""
import math

import bpy

import ch08_common as C
from summit_kit import aim_vector, perimeter_marker, tether_anchor  # noqa: F401  (re-exported for build_road)


def repeater(P, at, pal, yaw_back=0.0, yaw_fwd=180.0, state="dark", bay_open=True, name="Repeater"):
    x0, y0 = at
    R = C.empty(name, (x0, y0, 0), parent=P)
    for k in range(3):  # tripod with ballast bags
        a = math.radians(90 + k * 120)
        foot = (0.85 * math.cos(a), 0.85 * math.sin(a), 0.05)
        C.tube("leg", [foot, (0, 0, 0.9)], 0.03, pal["steel"], R)
        C.sphere("ballast", 0.13, foot, C.mat("Ballast", (0.33, 0.32, 0.30, 1), 0.95), R).scale = (1.3, 1.0, 0.55)
    C.cyl("mast", 0.04, 2.3, (0, 0, 1.95), pal["steel"], R, verts=16)
    C.box("head", (0.34, 0.34, 0.34), (0, 0, 2.55), pal["white"], R, bevel=0.02)
    C.box("head_trim", (0.36, 0.36, 0.05), (0, 0, 2.38), pal["navy"], R)
    ring = pal["lamp_amber"] if state == "lit" else pal["lamp_off"]
    C.cyl("ring_lamp", 0.2, 0.05, (0, 0, 2.75), ring, R, verts=32)
    C.cyl("whip", 0.008, 0.6, (0, 0, 3.05), pal["steel"], R, verts=8)
    for yaw, nm in ((yaw_back, "panel_back"), (yaw_fwd, "panel_fwd")):  # panel antennas along the chain
        e = C.empty(nm, (0, 0, 2.2), (0, 0, -math.radians(yaw)), parent=R)
        C.box("arm", (0.04, 0.3, 0.04), (0, 0.15, 0), pal["steel"], e)
        C.box("panel", (0.28, 0.05, 0.4), (0, 0.32, 0), pal["white"], e, bevel=0.01)
    for k, lit in enumerate((state == "lit", state == "lit")):  # adjacent-link lamps on the head
        C.cyl("link_lamp", 0.02, 0.02, (0.175, -0.06 + k * 0.12, 2.5), pal["lamp_green"] if lit else pal["lamp_off"], R, rot=(0, math.pi / 2, 0), verts=12)
    # battery bay at the foot of the mast
    C.box("bay", (0.5, 0.36, 0.38), (0, 0, 0.3), pal["white"], R, bevel=0.015)
    C.box("bay_band", (0.52, 0.38, 0.05), (0, 0, 0.47), pal["navy"], R)
    lid = C.empty("bay_lid", (0, -0.18, 0.495), (math.radians(-115 if bay_open else 0), 0, 0), parent=R)
    C.box("lid", (0.5, 0.36, 0.03), (0, 0.18, 0.015), pal["white"], lid, bevel=0.008)
    C.box("lid_handle", (0.16, 0.03, 0.03), (0, 0.33, 0.04), pal["orange"], lid)
    if bay_open:
        C.box("bay_well", (0.44, 0.3, 0.012), (0, 0, 0.5), pal["dark"], R)
    C.tube("bay_cable", [(0.0, 0.1, 0.48), (0.0, 0.05, 0.9)], 0.012, pal["rubber"], R)
    return R


def battery_module(P, at, pal, z=0.0):
    x0, y0 = at
    B = C.empty("BatteryModule", (x0, y0, z), parent=P)
    C.box("cells", (0.4, 0.26, 0.3), (0, 0, 0.15), pal["navy"], B, bevel=0.012)
    C.box("cap", (0.42, 0.28, 0.04), (0, 0, 0.32), pal["white"], B, bevel=0.008)
    C.box("handle", (0.2, 0.03, 0.06), (0, 0, 0.37), pal["orange"], B)
    return B


def guide_light(P, at, pal, lit=True):
    x0, y0 = at
    G = C.empty("GuideLight", (x0, y0, 0), parent=P)
    C.cyl("gl_post", 0.03, 0.6, (0, 0, 0.3), pal["white"], G, verts=12)
    C.cyl("gl_head", 0.05, 0.08, (0, 0, 0.64), pal["lamp_amber"] if lit else pal["lamp_off"], G, verts=16)
    C.cyl("gl_cap", 0.055, 0.02, (0, 0, 0.69), pal["navy"], G, verts=16)
    if lit:
        lt = C.point_light("gl_light", (0, 0, 0.66), 32.0, (1.0, 0.6, 0.2), 0.03)
        lt.parent = G
    return G


def slope_sign(P, at, pal, yaw=0.0):
    """Slope warning: pictogram only (orange slope wedge and chevrons on navy), no words."""
    x0, y0 = at
    S = C.empty("SlopeSign", (x0, y0, 0), (0, 0, -math.radians(yaw)), parent=P)
    C.box("sign_post", (0.06, 0.06, 1.3), (0, 0, 0.65), pal["steel"], S)
    C.box("sign_panel", (0.62, 0.03, 0.62), (0, -0.04, 1.35), pal["navy"], S, bevel=0.01, rot=(0, math.radians(45), 0))
    C.box("sign_rim", (0.66, 0.02, 0.66), (0, -0.03, 1.35), pal["white"], S, rot=(0, math.radians(45), 0))
    ang = math.radians(28)  # a vehicle on a slope steeper than the road allows
    C.box("slope_line", (0.48, 0.02, 0.07), (0.0, -0.065, 1.3), pal["reflector"], S, rot=(0, -ang, 0))
    C.box("slope_vehicle", (0.15, 0.02, 0.09), (-0.03, -0.07, 1.375), pal["reflector"], S, rot=(0, -ang, 0))
    return S


def turnback_barrier(P, at, pal, yaw=0.0, span=4.0):
    x0, y0 = at
    T = C.empty("TurnbackBarrier", (x0, y0, 0), (0, 0, -math.radians(yaw)), parent=P)
    stripe = C.mat("StripeWhite", C.srgb("#ECEEF0"), 0.5)
    for s in (-span / 2, span / 2):
        for k in range(4):
            C.cyl("bollard", 0.07, 0.25, (s, 0, 0.125 + k * 0.25), pal["orange"] if k % 2 == 0 else stripe, T, verts=16)
        C.cyl("refl", 0.075, 0.04, (s, 0, 1.02), pal["reflector"], T, verts=16)
    for k in range(int(span / 0.5)):
        x = -span / 2 + 0.25 + k * 0.5
        C.box("bar", (0.5, 0.06, 0.12), (x, 0, 0.75), pal["orange"] if k % 2 == 0 else stripe, T)
    return T


def supply_cache(P, at, pal, yaw=0.0):
    x0, y0 = at
    S = C.empty("SupplyCache", (x0, y0, 0), (0, 0, -math.radians(yaw)), parent=P)
    C.box("rack", (1.6, 0.7, 0.08), (0, 0, 0.3), pal["navy"], S)
    for s in (-0.7, 0.7):
        for t in (-0.3, 0.3):
            C.box("rack_leg", (0.05, 0.05, 0.3), (s, t, 0.15), pal["navy"], S)
    for k in range(2):
        C.box("crate", (0.7, 0.55, 0.45), (-0.38 + k * 0.76, 0, 0.57), pal["white"], S, bevel=0.03)
        for s in (-1, 1):
            C.box("latch", (0.06, 0.02, 0.08), (-0.38 + k * 0.76 + s * 0.22, -0.285, 0.6), pal["orange"], S)
    return S
