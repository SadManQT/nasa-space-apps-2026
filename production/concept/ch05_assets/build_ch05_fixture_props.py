"""M4-09: real models for the Chapter 5 staging stand-ins M3-5R left as boxes and cards. Blender 5.2, procedural,
no credits (the M3-5A pattern: simple hard-shell hardware reads as well as a Tripo mesh at game scale and fits the
staged labels and live text to the millimetre).

Usage:
  blender -b --factory-startup --python build_ch05_fixture_props.py -- <game/assets/props> [crate cleaning patch tablet page desk]

Each model is the size of the fixture it replaces, so the room's labels, signs and prints keep their places.
Pivot at the base centre, metres, Y up in the GLB, front towards +Z in Godot (-Y here). No logos, flags, words or numbers.

  * PR_RelayCrate - the replacement relay-controller crate (CH05 S02-S12). White hard case 0.60 x 0.46 m, 0.50 m
    tall closed: body 0.42 m with navy corner bumpers, two orange draw latches, end handles; `Lid` 0.08 m with its
    pivot on the rear hinge line (rotation_degrees [-90, 0, 0] in Godot stands it open behind the case). Inside: grey
    pick-and-pluck foam with the controller (finned housing, two connectors) and its coiled cable.
  * PR_CleaningKit - panel-cleaning kit (CH05-S08): a 0.30 x 0.20 x 0.14 m light-grey case, soft anti-static brush in
    a front clip, a pack of lint-free wipes on the end; flat lid for the room's printed name.
  * PR_SpurPatchKit - spur patch kit (CH05-S08): a 0.36 x 0.26 x 0.20 m signal-orange case with navy bumpers, two
    latches, an end handle; flat lid for the printed name.
  * PR_Tablet - the message composer (S11) and the report-receipt tablet (S10): a 0.26 x 0.18 x 0.012 m rugged
    tablet, navy bumper frame, `Screen` slot (dark anti-glare; the room draws the live words over it).
  * PR_SignedPage - Noor's signed identity page (S10): one A4 sheet, a blank portrait frame where the room lays the
    2034 portrait, faint rules, and her pen signature as a scribble mark above the signature line (no letters).
  * PR_WatchDesk - the corridor watch desk (LOC-02): stand-up desk, 0.80 x 0.45 m top at 1.02 m on a 0.30 x 0.22 m
    pedestal set 0.10 m towards the back, base plate, front edge guard.
"""
import math, os, sys
import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_impact_monitor as hw   # noqa: E402  (materials, boxes, cylinders, handles)
import build_ch05_bridge_props as bp  # noqa: E402  (paper textures, A4 sheet, ring, finish_and_export)


def paint(key):
    return bpy.data.materials.get("M_Kit_" + key) or hw.kit_material(key, 0.5)


def corner_bumpers(prefix, w, d, z0, h, mat, t=0.006, leg=0.06):
    """Moulded L-shaped corner guards, one at each vertical edge, standing proud of the shell by `t`."""
    out = []
    for i, (sx, sy) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
        a = hw.box(f"{prefix}_{i}a", (leg, t, h), (sx * (w / 2 - leg / 2 + t), sy * (d / 2 + t / 2), z0), mat, bevel=0.002)
        b = hw.box(f"{prefix}_{i}b", (t, leg, h), (sx * (w / 2 + t / 2), sy * (d / 2 - leg / 2 + t), z0), mat, bevel=0.002)
        out += [a, b]
    return out


def latch(name, x, y, z, steel, orange):
    plate = hw.box(name, (0.034, 0.006, 0.060), (x, y - 0.003, z), orange, bevel=0.002)
    keeper = hw.box(name + "_Keeper", (0.020, 0.006, 0.018), (x, y - 0.003, z + 0.060), steel, bevel=0.0015)
    return [plate, keeper]


def crate():
    white, navy, orange, steel = paint("PaintWhite"), paint("PaintNavy"), paint("PaintOrange"), paint("Steel")
    foam = hw.material("Foam", hw.lin("#5C626C"), rough=0.95)
    housing = hw.material("ControllerHousing", hw.lin("#8A9099"), rough=0.45, metal=0.6)
    cable = hw.material("Cable", hw.lin("#15171B"), rough=0.6)
    W, D, H, LH, t = 0.60, 0.46, 0.42, 0.08, 0.012
    objs = [hw.box("Body_Floor", (W, D, t), (0, 0, 0), white, bevel=0.004),
            hw.box("Body_Front", (W, t, H - t), (0, -D / 2 + t / 2, t), white, bevel=0.003),
            hw.box("Body_Back", (W, t, H - t), (0, D / 2 - t / 2, t), white, bevel=0.003),
            hw.box("Body_West", (t, D - 2 * t, H - t), (-W / 2 + t / 2, 0, t), white, bevel=0.003),
            hw.box("Body_East", (t, D - 2 * t, H - t), (W / 2 - t / 2, 0, t), white, bevel=0.003),
            hw.box("Foam", (W - 2 * t, D - 2 * t, H - t - 0.03), (0, 0, t), foam, bevel=0.0),
            hw.box("Rim_Gasket_F", (W - 2 * t, 0.006, 0.004), (0, -D / 2 + t + 0.003, H - 0.004), navy, bevel=0.0),
            hw.box("Rim_Gasket_B", (W - 2 * t, 0.006, 0.004), (0, D / 2 - t - 0.003, H - 0.004), navy, bevel=0.0)]
    objs += corner_bumpers("Bumper", W, D, 0.0, H, navy)
    objs += latch("Latch_W", -0.255, -D / 2, H - 0.075, steel, orange) + latch("Latch_E", 0.255, -D / 2, H - 0.075, steel, orange)
    for sx in (-1, 1):
        objs.append(hw.handle(f"Handle_{'E' if sx > 0 else 'W'}", (sx * (W / 2 + 0.006), 0, H * 0.62), 0.16, navy, rot=(90, 0, sx * 90)))
    # the controller and its cable seated in the foam (only seen with the lid up)
    fz = H - 0.03
    ctl = hw.box("Controller", (0.20, 0.15, 0.055), (-0.12, 0.02, fz - 0.035), housing, bevel=0.004)
    objs.append(ctl)
    for i in range(7):
        objs.append(hw.box(f"Controller_Fin_{i}", (0.006, 0.15, 0.006), (-0.05 + i * 0.012 - 0.02, 0.02, fz + 0.02), housing, bevel=0.0))
    for i, x in enumerate((-0.18, -0.12)):
        objs.append(hw.cylinder(f"Connector_{i}", 0.014, 0.012, (x, -0.055 - 0.006, fz - 0.008), steel, axis="Y", verts=20, bevel=0.001))
    objs.append(bp.ring("Cable_Coil", 0.055, 0.085, 0.014, (0.14, 0.0, fz - 0.002), cable))
    objs.append(bp.ring("Cable_Coil2", 0.04, 0.06, 0.012, (0.14, 0.0, fz + 0.01), cable))
    # lid: origin on the rear hinge line at the rim, geometry towards the front (-Y)
    lid = hw.box("Lid", (W, D, LH), (0, 0, 0), white, bevel=0.005)
    for v in lid.data.vertices:
        v.co.y -= D / 2
    lid.location = (0, D / 2, H)
    parts = [hw.box("Lid_Rib_W", (0.03, D - 0.08, 0.006), (-0.15, D / 2, H + LH), white, bevel=0.002),
             hw.box("Lid_Rib_E", (0.03, D - 0.08, 0.006), (0.15, D / 2, H + LH), white, bevel=0.002)]
    for p in parts:
        for v in p.data.vertices:
            v.co.y -= D / 2
    parts += corner_bumpers("Lid_Bumper", W, D, H, LH, navy)
    for p in parts:
        bp.parent_keep(p, lid)
    return "PR_RelayCrate", objs + [lid] + parts


def cleaning_kit():
    grey, navy, steel = paint("PaintGrey"), paint("PaintNavy"), paint("Steel")
    bristle = hw.material("Bristle", hw.lin("#2A2D33"), rough=0.95)
    wipes = hw.material("Wipes", hw.lin("#E8ECEF"), rough=0.9)
    W, D, H = 0.30, 0.20, 0.14
    objs = [hw.box("Body", (W, D, H - 0.03), (0, 0, 0), grey, bevel=0.006),
            hw.box("Lid", (W + 0.004, D + 0.004, 0.03), (0, 0, H - 0.03), grey, bevel=0.005),
            hw.box("Lid_Seam", (W + 0.006, D + 0.006, 0.006), (0, 0, H - 0.033), navy, bevel=0.002)]
    for x in (-0.09, 0.09):
        objs.append(hw.box(f"Clip_{x:+.2f}", (0.014, 0.012, 0.04), (x, -D / 2 - 0.006, 0.05), navy, bevel=0.002))
    # soft anti-static brush held in the two clips: wooden-free polymer handle, dark bristle block
    objs.append(hw.cylinder("Brush_Handle", 0.009, 0.20, (0.0, -D / 2 - 0.014, 0.065), navy, axis="X", verts=20))
    objs.append(hw.box("Brush_Head", (0.07, 0.022, 0.03), (0.13, -D / 2 - 0.014, 0.05), steel, bevel=0.003))
    objs.append(hw.box("Brush_Bristles", (0.066, 0.02, 0.024), (0.13, -D / 2 - 0.014, 0.026), bristle, bevel=0.0))
    # a soft pack of lint-free wipes strapped to the east end
    objs.append(hw.box("Wipes_Pack", (0.03, 0.15, 0.08), (W / 2 + 0.016, 0, 0.012), wipes, bevel=0.01))
    objs.append(hw.box("Wipes_Strap", (0.034, 0.02, 0.084), (W / 2 + 0.016, 0, 0.010), navy, bevel=0.002))
    return "PR_CleaningKit", objs


def spur_patch_kit():
    orange, navy, steel = paint("PaintOrange"), paint("PaintNavy"), paint("Steel")
    W, D, H = 0.36, 0.26, 0.20
    objs = [hw.box("Body", (W, D, H - 0.045), (0, 0, 0), orange, bevel=0.006),
            hw.box("Lid", (W, D, 0.045), (0, 0, H - 0.045), orange, bevel=0.006),
            hw.box("Lid_Seam", (W + 0.002, D + 0.002, 0.004), (0, 0, H - 0.047), navy, bevel=0.0)]
    objs += corner_bumpers("Bumper", W, D, 0.0, H, navy, t=0.005, leg=0.045)
    objs += latch("Latch_W", -0.09, -D / 2, H - 0.09, steel, navy) + latch("Latch_E", 0.09, -D / 2, H - 0.09, steel, navy)
    objs.append(hw.handle("Handle", (W / 2 + 0.005, 0, H * 0.55), 0.12, navy, rot=(90, 0, 90)))
    return "PR_SpurPatchKit", objs


def tablet():
    navy, dark = paint("PaintNavy"), paint("PaintDark")
    screen = hw.material("Screen", hw.lin("#0B1220"), rough=0.3)
    W, D, H = 0.26, 0.18, 0.011
    objs = [hw.box("Body", (W, D, H), (0, 0, 0), navy, bevel=0.004),
            hw.box("Screen", (W - 0.02, D - 0.02, 0.0008), (0, 0, H - 0.0002), screen, bevel=0.0)]
    for i, (sx, sy) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
        objs.append(hw.box(f"Bumper_{i}", (0.024, 0.024, H + 0.001), (sx * (W / 2 - 0.009), sy * (D / 2 - 0.009), 0), dark, bevel=0.004))
    return "PR_Tablet", objs


def page_texture(name, w=724, h=1024):
    """Noor's signed page: aged paper, a thin frame where the room lays her portrait, faint rules for the live text
    and a ballpoint signature scribble (a mark, not letters) over the signature line at the foot."""
    rng = np.random.default_rng(2046)
    img = bp.paper_base(rng, w, h)
    m = 40
    bp.frame(img, m, m, w - m, h - m, bp.INK * 1.8, 1)
    pw, ph = int(0.085 / 0.21 * w), int(0.11 / 0.297 * h)            # portrait 85 x 110 mm, centred 75 mm above mid
    cy = int(h * (0.5 - 0.075 / 0.297))
    bp.frame(img, w // 2 - pw // 2 - 6, cy - ph // 2 - 6, w // 2 + pw // 2 + 6, cy + ph // 2 + 6, bp.INK, 2)
    for i in range(9):
        y = int(h * 0.56) + i * 26
        bp.rect(img, m + 60, y, w - m - 60, y + 1, bp.INK * 2.2, 0.35)
    line_y = int(h * 0.915)
    bp.rect(img, w // 2 - 170, line_y, w // 2 + 170, line_y + 2, bp.INK)
    ink = np.array([0.10, 0.17, 0.36])
    t = np.linspace(0, 1, 900)
    xs = w // 2 - 140 + 280 * t
    ys = line_y - 22 - 16 * np.sin(t * 2 * math.pi * 3.2) * np.exp(-t * 1.2) - 10 * np.sin(t * 2 * math.pi * 7.1 + 1)
    for x, y in zip(xs.astype(int), ys.astype(int)):
        bp.rect(img, x, y, x + 3, y + 3, ink)
    return bp.to_image(name, img)


def signed_page():
    front = bp.textured("Page_Signed", page_texture("T_Page_Signed"))
    back = bp.textured("Paper_Back", bp.back_texture("T_Paper_Back", None))
    return "PR_SignedPage", [bp.sheet("Page", (0, 0, 0), 0.0, front, back, curl=0.0006)]


def watch_desk():
    white, navy, grey, dark = paint("PaintWhite"), paint("PaintNavy"), paint("PaintGrey"), paint("PaintDark")
    top_z = 1.02
    objs = [hw.box("Base", (0.50, 0.34, 0.02), (0, 0.10, 0), dark, bevel=0.004),
            hw.box("Pedestal", (0.30, 0.22, top_z - 0.06), (0, 0.10, 0.02), grey, bevel=0.006),
            hw.box("Pedestal_Door", (0.24, 0.006, 0.60), (0, 0.10 - 0.113, 0.18), navy, bevel=0.002),
            hw.box("Top_Frame", (0.72, 0.38, 0.02), (0, 0.0, top_z - 0.04), navy, bevel=0.003),
            hw.box("Top", (0.80, 0.45, 0.02), (0, 0, top_z - 0.02), white, bevel=0.004),
            hw.box("Edge_Guard", (0.80, 0.012, 0.03), (0, -0.225 + 0.006, top_z - 0.03), navy, bevel=0.003)]
    objs.append(hw.handle("Door_Pull", (0, 0.10 - 0.118, 0.62), 0.08, dark, rot=(90, 0, 0)))
    return "PR_WatchDesk", objs


BUILDERS = {"crate": crate, "cleaning": cleaning_kit, "patch": spur_patch_kit, "tablet": tablet,
            "page": signed_page, "desk": watch_desk}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = argv[0]
    for key in (argv[1:] or list(BUILDERS)):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        hw._gltf_group = None
        name, objs = BUILDERS[key]()
        bp.finish_and_export(name, objs, out)


if __name__ == "__main__":
    main()
