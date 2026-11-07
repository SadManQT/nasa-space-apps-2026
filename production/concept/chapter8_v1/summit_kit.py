"""EN_MalapertSummit pieces for the M3-8A sheet: procedural Blender geometry, metres, in the platform frame
(x = local east, y = local north, z = up from the graded pad). Each builder takes a parent empty and returns it, so the
same code places the pieces on the real terrain (build_summit.py) and on the studio turntable (build_pieces.py)."""
import math

import bpy
from mathutils import Vector

import ch08_common as C


def aim_vector(az, el):
    a, e = math.radians(az), math.radians(el)
    return Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e)))


def railing(name, pts, h, P, m, posts=True):
    for k, (x, y) in enumerate(pts):
        if posts:
            C.cyl(f"{name}_post{k}", 0.025, h, (x, y, h / 2), m, P, verts=12)
    C.tube(f"{name}_top", [(x, y, h) for x, y in pts], 0.022, m, P)
    C.tube(f"{name}_mid", [(x, y, h * 0.5) for x, y in pts], 0.018, m, P)


def relay_deck(P, at, pal, z0=0.0):
    """Legacy 2034 relay: 4 x 4 m truss deck at 1.2 m, Earth dish and local antenna (PR_MalapertRelay design language)."""
    x0, y0 = at
    D = C.empty("RelayDeck", (x0, y0, z0), parent=P)
    h = 1.2
    for sx in (-1, 1):
        for sy in (-1, 1):
            C.box("leg", (0.14, 0.14, h), (sx * 1.9, sy * 1.9, h / 2), pal["navy"], D, bevel=0.01)
            C.box("foot", (0.45, 0.45, 0.05), (sx * 1.9, sy * 1.9, 0.025), pal["steel"], D)
    for side in range(4):  # X-bracing on every face
        for s in (-1, 1):
            ang = math.atan2(h - 0.2, 3.8) * s
            if side < 2:
                y = 1.9 if side == 0 else -1.9
                C.box("brace", (3.95, 0.05, 0.07), (0, y, h / 2), pal["navy"], D, rot=(ang, 0, 0) if False else (0, -ang, 0))
            else:
                x = 1.9 if side == 2 else -1.9
                C.box("brace", (0.05, 3.95, 0.07), (x, 0, h / 2), pal["navy"], D, rot=(ang, 0, 0))
    C.box("ring_beam", (4.0, 4.0, 0.16), (0, 0, h - 0.08), pal["navy"], D, bevel=0.01)
    C.box("deck_plate", (3.96, 3.96, 0.05), (0, 0, h + 0.025), pal["steel"], D, bevel=0.005)
    rp = [(-1.95, -1.95), (-1.95, 1.95), (1.95, 1.95), (1.95, -1.95), (0.45, -1.95)]
    railing("rail", rp, 1.0, C.empty("rails", (0, 0, h + 0.05), parent=D), pal["orange"])
    lad = C.empty("ladder", (-0.15, -2.05, 0), parent=D)
    for s in (-0.22, 0.22):
        C.box("stile", (0.04, 0.05, h + 1.0), (s, 0, (h + 1.0) / 2), pal["orange"], lad)
    for k in range(5):
        C.cyl("rung", 0.015, 0.44, (0, 0, 0.25 + k * 0.24), pal["steel"], lad, rot=(0, math.pi / 2, 0), verts=8)
    # RF electronics box on the deck (not the serviced controller: that is the ground housing)
    C.box("rf_box", (0.9, 0.55, 0.75), (1.1, 1.2, h + 0.43), pal["white"], D, bevel=0.02)
    C.box("rf_door_line", (0.005, 0.5, 0.6), (1.1 - 0.455, 1.2, h + 0.45), pal["navy"], D)
    # Earth dish on an az-el positioner
    ped = C.empty("dish_ped", (0, 0.8, h + 0.05), parent=D)
    C.cyl("ped_base", 0.32, 0.12, (0, 0, 0.06), pal["navy"], ped)
    C.cyl("ped_col", 0.18, 1.0, (0, 0, 0.6), pal["white"], ped)
    C.cyl("az_ring", 0.24, 0.1, (0, 0, 1.12), pal["dark"], ped)
    aim = aim_vector(358.7, -2.3)
    yaw = math.atan2(aim.x, aim.y)
    yoke = C.empty("yoke", (0, 0, 1.25), (0, 0, -yaw), parent=ped)
    for s in (-1, 1):
        C.box("yoke_arm", (0.08, 0.16, 0.55), (s * 0.42, 0, 0.27), pal["white"], yoke, bevel=0.01)
    C.box("yoke_base", (0.92, 0.2, 0.08), (0, 0, 0.0), pal["white"], yoke)
    el_ax = C.empty("el_axis", (0, 0, 0.5), (math.radians(90 - (-2.3)), 0, 0), parent=yoke)  # +Z of el_axis -> aim
    C.cyl("el_shaft", 0.06, 0.98, (0, 0, 0), pal["steel"], el_ax, rot=(0, math.pi / 2, 0), verts=16)
    C.box("dish_back", (0.5, 0.5, 0.2), (0, 0, -0.05), pal["white"], el_ax, bevel=0.02)
    refl, f = C.dish("earth_dish", 2.0, 0.32, pal["white"], el_ax)
    refl.location = (0, 0, 0.1)
    for k in range(4):  # feed struts to the feed horn at the focus
        a = k * math.pi / 2 + math.pi / 4
        p0 = (0.82 * math.cos(a), 0.82 * math.sin(a), 0.1 + 0.82 ** 2 / (4 * f))
        C.tube("strut", [p0, (0, 0, 0.1 + f - 0.06)], 0.012, pal["steel"], el_ax)
    C.cyl("feed", 0.06, 0.18, (0, 0, 0.1 + f), pal["white"], el_ax, verts=16)
    C.cyl("feed_cap", 0.065, 0.02, (0, 0, 0.1 + f - 0.09), pal["navy"], el_ax, verts=16)
    # local repeater antenna mast on the south-west corner, aimed at R3
    mast = C.empty("local_mast", (-1.6, -1.5, h + 0.05), parent=D)
    C.cyl("mast", 0.045, 4.2, (0, 0, 2.1), pal["steel"], mast, verts=12)
    for k in range(3):
        a = k * 2 * math.pi / 3
        C.tube("guy", [(0, 0, 3.6), (0.9 * math.cos(a), 0.9 * math.sin(a), 0.02)], 0.004, pal["steel"], mast)
    aim2 = aim_vector(216.7, -4.8)
    yaw2 = math.atan2(aim2.x, aim2.y)
    head = C.empty("local_head", (0, 0, 4.1), (0, 0, -yaw2), parent=mast)
    tilt = C.empty("local_tilt", (0, 0.12, 0), (math.radians(90 + 4.8), 0, 0), parent=head)
    C.box("bracket", (0.08, 0.2, 0.08), (0, -0.06, 0), pal["steel"], head)
    loc_dish, f2 = C.dish("local_dish", 0.7, 0.12, pal["white"], tilt)
    C.cyl("local_feed", 0.03, 0.1, (0, 0, f2), pal["navy"], tilt, verts=12)
    C.tube("local_strut", [(0.3, 0, 0.08), (0, 0, f2 - 0.04)], 0.008, pal["steel"], tilt)
    C.tube("local_strut2", [(-0.3, 0, 0.08), (0, 0, f2 - 0.04)], 0.008, pal["steel"], tilt)
    C.tube("mast_cable", [(0.05, 0, 3.9), (0.08, 0, 0.1), (1.0, 1.0, 0.0)], 0.012, pal["rubber"], mast)
    return D


def controller_housing(P, at, pal, door_open_deg=0.0, state="dark", controller=True):
    """Ground-level controller housing, service door on the east (+x) face, hinged on its north edge."""
    x0, y0 = at
    H = C.empty("ControllerHousing", (x0, y0, 0), parent=P)
    w, d, h = 0.7, 1.4, 1.6  # x depth, y width, height
    C.box("plinth", (0.85, 1.55, 0.12), (0, 0, 0.06), pal["navy"], H, bevel=0.01)
    body = C.box("body", (w, d, h), (0, 0, 0.12 + h / 2), pal["white"], H, bevel=0.025)
    cut = C.box("bay_cut", (0.5, 1.02, 1.2), (w / 2 - 0.2, 0, 0.12 + 0.82), None, None)
    mod = body.modifiers.new("bay", "BOOLEAN"); mod.object = cut; mod.operation = "DIFFERENCE"
    cut.hide_render = True; cut.hide_viewport = True
    cut.parent = H
    C.box("bay_back", (0.02, 1.0, 1.18), (w / 2 - 0.44, 0, 0.12 + 0.82), pal["dark"], H)
    for s in (-1, 1):  # navy frame round the opening
        C.box("frame_v", (0.03, 0.06, 1.3), (w / 2 + 0.005, s * 0.54, 0.12 + 0.82), pal["navy"], H)
    for zz in (0.12 + 0.82 - 0.63, 0.12 + 0.82 + 0.63):
        C.box("frame_h", (0.03, 1.14, 0.06), (w / 2 + 0.005, 0, zz), pal["navy"], H)
    C.box("roof", (0.82, 1.52, 0.06), (0, 0, 0.12 + h + 0.03), pal["navy"], H, bevel=0.01)
    # rails and the controller module (PR_RelayController design: finned grey box)
    for zz in (0.62, 0.98):
        C.box("rail", (0.42, 0.9, 0.02), (w / 2 - 0.22, 0, zz), pal["steel"], H)
    if controller:
        cm = C.empty("controller", (w / 2 - 0.2, -0.1, 0.64), parent=H)
        C.box("ctl_body", (0.34, 0.42, 0.24), (0, 0, 0.12), pal["steel"], cm, bevel=0.01)
        for k in range(9):
            C.box("fin", (0.3, 0.012, 0.06), (0, -0.19 + k * 0.0475, 0.27), pal["steel"], cm)
        C.box("ctl_face", (0.01, 0.4, 0.2), (0.172, 0, 0.12), pal["dark"], cm)
        for k in range(3):
            C.cyl("conn", 0.022, 0.03, (0.18, -0.12 + k * 0.12, 0.1), pal["navy"], cm, rot=(0, math.pi / 2, 0), verts=12)
    C.box("conn_panel", (0.02, 0.9, 0.16), (w / 2 - 0.42, 0, 1.2), pal["navy"], H)
    for k in range(4):
        C.tube("bay_cable", [(w / 2 - 0.4, -0.3 + k * 0.2, 1.2), (w / 2 - 0.3, -0.3 + k * 0.2, 1.0), (w / 2 - 0.05, -0.2 + k * 0.08, 0.8)], 0.012, pal["rubber"], H)
    # test point: two shrouded sockets inside the frame, south side
    tp = C.empty("test_point", (w / 2 - 0.02, -0.42, 1.3), parent=H)
    C.box("tp_plate", (0.02, 0.16, 0.12), (0, 0, 0), pal["orange"], tp)
    for s in (-1, 1):
        C.cyl("tp_socket", 0.018, 0.04, (0.02, s * 0.04, 0), pal["dark"], tp, rot=(0, math.pi / 2, 0), verts=12)
    # status lamps above the door: three positions, state-driven
    lamp = {"dark": ["lamp_off"] * 3, "amber": ["lamp_amber", "lamp_amber", "lamp_off"], "green": ["lamp_green"] * 3}[state]
    for k in range(3):
        C.cyl("status", 0.022, 0.02, (w / 2 + 0.02, -0.12 + k * 0.12, 1.66), pal[lamp[k]], H, rot=(0, math.pi / 2, 0), verts=16)
    # door, hinged on the north edge of the opening
    hinge = C.empty("door_hinge", (w / 2 + 0.02, 0.56, 0.12 + 0.82), (0, 0, math.radians(door_open_deg)), parent=H)
    C.box("door", (0.035, 1.1, 1.24), (0.0, -0.55, 0), pal["white"], hinge, bevel=0.01)
    C.box("door_gasket", (0.01, 1.04, 1.18), (-0.022, -0.55, 0), pal["navy"], hinge)
    for zz in (-0.35, 0.35):
        C.box("latch", (0.05, 0.04, 0.16), (0.04, -1.0, zz), pal["orange"], hinge, bevel=0.005)
    C.box("brace_handle", (0.06, 0.5, 0.04), (0.05, -0.55, 0.0), pal["orange"], hinge, bevel=0.005)
    for zz in (-0.5, 0.5):
        C.cyl("hinge_pin", 0.02, 0.12, (0, 0.0, zz), pal["steel"], hinge, verts=12)
    # thermal radiator fins on the back (west) face
    for k in range(6):
        C.box("radiator", (0.04, 1.2, 0.02), (-w / 2 - 0.02, 0, 0.5 + k * 0.18), pal["white"], H)
    return H


def power_isolator(P, at, pal, isolated=True):
    x0, y0 = at
    I = C.empty("PowerIsolator", (x0, y0, 0), parent=P)
    C.box("post", (0.07, 0.07, 1.25), (0, 0, 0.625), pal["steel"], I)
    C.box("base", (0.35, 0.35, 0.04), (0, 0, 0.02), pal["steel"], I)
    C.box("iso_box", (0.2, 0.32, 0.42), (0.03, 0, 1.05), pal["white"], I, bevel=0.015)
    C.box("iso_face", (0.01, 0.28, 0.38), (0.135, 0, 1.05), pal["navy"], I)
    knob = C.empty("handle", (0.15, 0, 1.05), (math.radians(90 if isolated else 0), 0, 0), parent=I)
    C.cyl("hub", 0.05, 0.05, (0.0, 0, 0), pal["orange"], knob, rot=(0, math.pi / 2, 0), verts=24)
    C.box("bar", (0.04, 0.05, 0.24), (0.03, 0, 0.06), pal["orange"], knob, bevel=0.008)
    if isolated:  # lock-out hasp and tag (blank; the words are UI)
        C.box("hasp", (0.03, 0.012, 0.09), (0.18, 0.06, 0.93), pal["steel"], I)
        C.box("tag", (0.004, 0.07, 0.11), (0.2, 0.08, 0.84), pal["lamp_red"] if False else C.mat("TagRed", C.srgb("#C8352B"), 0.6), I)
    C.tube("iso_cable_in", [(-0.05, 0.1, 0.85), (-0.05, 0.1, 0.05), (-0.6, 0.1, 0.02)], 0.016, pal["rubber"], I)
    C.tube("iso_cable_out", [(-0.05, -0.1, 0.85), (-0.05, -0.12, 0.05), (-0.5, 0.6, 0.02), (-0.75, 0.9, 0.02)], 0.016, pal["rubber"], I)
    return I


def control_pedestal(P, at, pal, lit=False):
    x0, y0 = at
    S = C.empty("ControlPedestal", (x0, y0, 0), parent=P)
    C.box("ped_base", (0.5, 0.6, 0.06), (0, 0, 0.03), pal["navy"], S)
    C.box("ped_col", (0.24, 0.3, 0.9), (0, 0, 0.5), pal["white"], S, bevel=0.015)
    top = C.empty("console", (0.04, 0, 1.0), (0, math.radians(30), 0), parent=S)  # face tilted toward +x (the operator)
    C.box("console_box", (0.42, 0.96, 0.12), (0, 0, 0), pal["white"], top, bevel=0.015)
    C.box("console_face", (0.38, 0.92, 0.01), (0, 0, 0.062), pal["navy"], top)
    scr = pal["lamp_green"] if lit else pal["screen"]
    C.box("screen_L", (0.12, 0.2, 0.006), (-0.08, -0.3, 0.068), scr, top)
    C.box("screen_E", (0.12, 0.2, 0.006), (-0.08, 0.3, 0.068), scr, top)
    C.box("screen_check", (0.16, 0.26, 0.006), (-0.06, 0.0, 0.068), C.mat("ScreenBlue", (0.01, 0.02, 0.04, 1), 0.1, emit=(0.2, 0.55, 1.0, 1), emit_strength=3.0) if lit else pal["screen"], top)
    for s in (-0.3, 0.3):
        C.cyl("dial", 0.05, 0.04, (0.09, s, 0.08), pal["orange"], top, verts=24)
        C.box("dial_pointer", (0.04, 0.008, 0.01), (0.11, s, 0.1), pal["white"], top)
    for k in range(4):
        C.box("key", (0.03, 0.04, 0.012), (0.1, -0.06 + k * 0.04, 0.072), pal["white"], top)
    C.box("hood", (0.05, 0.98, 0.18), (-0.2, 0, 0.1), pal["white"], top)
    C.tube("ped_cable", [(0, 0, 0.05), (-0.4, -0.3, 0.02), (-1.6, -0.9, 0.02)], 0.016, pal["rubber"], S)
    return S


def solar_mast(P, at, pal, face_az=18.1):
    x0, y0 = at
    M = C.empty("SolarMast", (x0, y0, 0), parent=P)
    C.box("pad", (1.0, 1.0, 0.08), (0, 0, 0.04), pal["navy"], M)
    C.cyl("pole", 0.09, 4.4, (0, 0, 2.2), pal["steel"], M, verts=20)
    C.cyl("drive", 0.16, 0.22, (0, 0, 4.1), pal["navy"], M, verts=20)
    yaw = math.radians(face_az)
    wing = C.empty("wing", (0, 0, 2.6), (0, 0, -yaw), parent=M)
    C.box("frame", (2.25, 0.07, 3.65), (0, 0.12, 0), pal["navy"], wing)
    C.box("cells", (2.17, 0.02, 3.57), (0, 0.16, 0), pal["cell"], wing)
    for k in range(1, 6):
        C.box("cell_gap", (2.17, 0.004, 0.012), (0, 0.172, -1.785 + k * 0.595), pal["steel"], wing)
    for k in range(1, 3):
        C.box("cell_gap_v", (0.012, 0.004, 3.57), (-1.085 + k * 0.723, 0.172, 0), pal["steel"], wing)
    C.box("arm", (0.1, 0.25, 0.1), (0, 0.0, 1.4), pal["steel"], wing)
    C.box("arm2", (0.1, 0.25, 0.1), (0, 0.0, -1.4), pal["steel"], wing)
    C.box("battery", (0.8, 0.5, 0.9), (0.0, -1.3, 0.45), pal["white"], M, bevel=0.02)
    C.box("battery_band", (0.82, 0.52, 0.08), (0.0, -1.3, 0.8), pal["navy"], M)
    for k in range(5):
        C.box("bat_fin", (0.8, 0.02, 0.5), (0, -1.56 - 0.0 * k, 0.15 + 0.0 * k), pal["white"], M) if k == 0 else None
    C.tube("bat_cable", [(0.0, -0.2, 2.0), (0.05, -0.12, 0.1), (0.1, -1.0, 0.05)], 0.018, pal["rubber"], M)
    return M


def tether_anchor(P, at, pal, name="TetherAnchor"):
    x0, y0 = at
    A = C.empty(name, (x0, y0, 0), parent=P)
    C.cyl("plate", 0.16, 0.03, (0, 0, 0.015), pal["steel"], A, verts=24)
    C.cyl("stake", 0.035, 0.65, (0, 0, 0.33), pal["orange"], A, verts=16)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.07, minor_radius=0.012, location=(0, 0, 0.7), rotation=(math.pi / 2, 0, 0))
    t = bpy.context.object; t.name = "ring"; t.parent = A; t.data.materials.append(pal["steel"])
    return A


def perimeter_marker(P, at, pal):
    x0, y0 = at
    M = C.empty("Marker", (x0, y0, 0), parent=P)
    C.box("post", (0.06, 0.06, 0.5), (0, 0, 0.25), pal["white"], M)
    C.box("cap", (0.08, 0.08, 0.08), (0, 0, 0.53), pal["reflector"], M)
    return M


def umbilical_post(P, at, pal, rover_port=None):
    x0, y0 = at
    U = C.empty("UmbilicalPost", (x0, y0, 0), parent=P)
    C.box("u_base", (0.4, 0.4, 0.05), (0, 0, 0.025), pal["navy"], U)
    C.box("u_post", (0.16, 0.16, 0.9), (0, 0, 0.47), pal["white"], U, bevel=0.01)
    C.box("u_head", (0.24, 0.28, 0.22), (0, 0, 0.98), pal["navy"], U, bevel=0.015)
    C.cyl("u_socket", 0.05, 0.05, (0.13, 0, 0.98), pal["orange"], U, rot=(0, math.pi / 2, 0), verts=20)
    if rover_port:
        rx, ry, rz = rover_port
        C.tube("umbilical", [(0.15, 0, 0.98), (0.6, -0.2, 0.3), (1.2, -0.5, 0.08), (rx - x0 - 0.4, ry - y0, 0.25), (rx - x0, ry - y0, rz)], 0.03, pal["rubber"], U)
    return U


def viewpoint(P, at, pal):
    x0, y0 = at
    V = C.empty("EarthViewpoint", (x0, y0, 0), parent=P)
    railing("view_rail", [(-1.5, 0.3), (0, 0.3), (1.5, 0.3)], 1.0, V, pal["orange"])
    C.box("view_plate", (1.0, 0.8, 0.02), (0, -0.4, 0.01), pal["navy"], V)
    return V


def cable_tray(P, pts, pal, name="tray"):
    T = C.empty(name, (0, 0, 0), parent=P)
    for (a, b) in zip(pts[:-1], pts[1:]):
        ax, ay = a; bx, by = b
        L = math.hypot(bx - ax, by - ay)
        ang = math.atan2(by - ay, bx - ax)
        C.box("tray_seg", (L, 0.16, 0.05), ((ax + bx) / 2, (ay + by) / 2, 0.025), pal["navy"], T, rot=(0, 0, ang))
        C.box("tray_lid", (L, 0.12, 0.012), ((ax + bx) / 2, (ay + by) / 2, 0.056), pal["steel"], T, rot=(0, 0, ang))
    return T
