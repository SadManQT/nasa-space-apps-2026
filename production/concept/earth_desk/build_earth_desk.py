"""Build EN_EarthDesk, the Earth control room behind an Earth-side caller, as a 2D screen render (M1-07; no AI
generation, no credits).

Usage:
  blender -b --factory-startup --python build_earth_desk.py -- [<out.png>]
then  python3 production/concept/earth_desk/compose_earth_desk.py  (the painted grade, the archive variant, the sheet).

What it is: the staged background behind an Earth-side speaker on the station's Earth screen (Rao always; Ferreira
until she arrives on 12 Dec 2046). It is the same room as the installed Rao portrait
(game/assets/ui/portraits/CH_Rao_screen.png), rebuilt in 3D so a caller without a painted background (Ferreira's
transparent portrait) sits in Rao's room: a dark blue-teal operations room, a wall of four large displays (telemetry
charts, an orbit ground track, a lunar route map, the near side of the full Moon), two rows of workstations with low
divider panels and glowing monitors, and the warm desk lamp at the left. The camera stands where the caller's call
camera would be, at seated eye height, focused on the caller at 0.9 m, so the room falls softly out of focus like the
portrait's background.

No text, no logos, no flags: every readout is an abstract trace, so nothing on it can contradict a dated fact. The
Moon display shows the real near side as seen from Earth with north up (maria, Tycho and its rays at their true
positions), so it agrees with ART_BIBLE §2.

Palette (ART_BIBLE §3): navy and blue-teal room, green and water-blue screen traces, one warm lamp, mustard-gold
route. Eevee at 1536 x 864 (16:9), 64 samples: light enough for a laptop. Deterministic: fixed seeds, no random
placement.
"""
import bpy, math, os, sys
import numpy as np
from mathutils import Euler, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv and len(sys.argv) > sys.argv.index("--") + 1 \
    else os.path.join(HERE, "EN_EarthDesk_render.png")


def lin(hexstr):
    """sRGB hex to linear RGBA."""
    h = hexstr.lstrip("#")
    return tuple(((int(h[i:i + 2], 16) / 255.0) / 12.92 if int(h[i:i + 2], 16) / 255.0 <= 0.04045
                  else ((int(h[i:i + 2], 16) / 255.0 + 0.055) / 1.055) ** 2.4) for i in (0, 2, 4)) + (1.0,)


def rgb(hexstr, gain=1.0):
    return np.array(lin(hexstr)[:3]) * gain


def material(name, hexstr, rough=0.6, metal=0.0, emit=None, strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = lin(hexstr)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit is not None:
        b.inputs["Emission Color"].default_value = lin(emit)
        b.inputs["Emission Strength"].default_value = strength
    return m


def box(name, at, size, mat, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=at, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    o.data.materials.append(mat)
    return o


def cylinder(name, at, radius, depth, mat, rot=(0, 0, 0), verts=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=at, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(mat)
    return o


# --- screen content: abstract readouts drawn with numpy (no text) ----------------------------------------------

def _panel(w, h):
    img = np.zeros((h, w, 3), dtype=np.float32)
    img[...] = rgb("#0C1C2A")
    return img


def _grid(img, step, colour):
    img[::step, :, :] = colour
    img[:, ::step, :] = colour


def _line(img, xs, ys, colour, width=1):
    h, w = img.shape[:2]
    for i in range(len(xs) - 1):
        n = int(max(abs(xs[i + 1] - xs[i]), abs(ys[i + 1] - ys[i]))) + 2
        lx = np.linspace(xs[i], xs[i + 1], n)
        ly = np.linspace(ys[i], ys[i + 1], n)
        for dx in range(-width, width + 1):
            for dy in range(-width, width + 1):
                img[np.clip((ly + dy).astype(int), 0, h - 1), np.clip((lx + dx).astype(int), 0, w - 1)] = colour


def _readout_lines(img, x0, y0, x1, rows, rng, colours):
    """Short horizontal bars that stand in for text lines (nothing readable)."""
    for i in range(rows):
        y = y0 + i * 18
        length = int((x1 - x0) * (0.35 + 0.6 * rng.random()))
        img[y:y + 5, x0:x0 + length] = colours[i % len(colours)]


def moon_disc(size, seed=1):
    """The near side of the full Moon as seen from Earth, north up: maria at their real positions, bright Tycho,
    Copernicus, Kepler and Aristarchus, Tycho's rays. Returns (rgb, alpha) arrays of size x size."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    r = size * 0.5 - 1
    u = (xx - size * 0.5) / r
    v = -(yy - size * 0.5) / r
    d = np.hypot(u, v)
    alpha = np.clip((1.0 - d) * r * 0.8, 0.0, 1.0)
    maria = [(-0.62, 0.25, 0.22), (-0.55, -0.05, 0.22), (-0.70, 0.45, 0.15), (-0.45, 0.05, 0.15),  # Procellarum
             (-0.28, 0.45, 0.22), (-0.12, 0.52, 0.12),                                             # Imbrium
             (-0.20, 0.78, 0.07), (0.0, 0.80, 0.07), (0.2, 0.78, 0.06), (0.38, 0.74, 0.05),        # Frigoris
             (0.22, 0.42, 0.14),                                                                   # Serenitatis
             (0.38, 0.12, 0.15), (0.30, 0.02, 0.10), (0.48, 0.18, 0.08),                           # Tranquillitatis
             (0.73, 0.30, 0.10),                                                                   # Crisium
             (0.62, -0.12, 0.12), (0.58, -0.28, 0.08),                                             # Fecunditatis
             (0.38, -0.28, 0.08),                                                                  # Nectaris
             (0.04, 0.24, 0.07),                                                                   # Vaporum
             (-0.18, -0.38, 0.13), (-0.28, -0.30, 0.09),                                           # Nubium
             (-0.50, -0.40, 0.08),                                                                 # Humorum
             (-0.30, -0.10, 0.12)]                                                                 # Cognitum / Insularum
    mare = np.zeros_like(u)
    for cx, cy, cr in maria:
        for _ in range(3):  # a few offset lobes per mare so the shores are irregular
            ox, oy = rng.normal(0, cr * 0.25, 2)
            rr = cr * (0.95 + 0.35 * rng.random())
            mare = np.maximum(mare, 1.0 / (1.0 + np.exp((np.hypot(u - cx - ox, v - cy - oy) - rr) / 0.025)))
    fine = rng.random((size, size)).astype(np.float32)
    albedo = 0.80 - 0.42 * mare + 0.06 * (fine - 0.5)
    for _ in range(140):  # small highland craters, faint rims
        a, b = rng.random() * 2 * math.pi, math.sqrt(rng.random()) * 0.95
        cu, cv, cr = b * math.cos(a), b * math.sin(a), 0.008 + 0.03 * rng.random() ** 2
        ring = np.exp(-((np.hypot(u - cu, v - cv) - cr) / 0.006) ** 2)
        albedo += 0.05 * ring * (1.0 - mare)
    for cu, cv, cr, gain in [(-0.12, -0.68, 0.025, 0.35), (-0.30, 0.17, 0.02, 0.25), (-0.52, 0.14, 0.012, 0.22),
                             (-0.68, 0.42, 0.012, 0.35)]:  # Tycho, Copernicus, Kepler, Aristarchus
        albedo += gain * np.exp(-(np.hypot(u - cu, v - cv) / cr) ** 2)
    ang = np.arctan2(v + 0.68, u + 0.12)
    dist = np.hypot(u + 0.12, v + 0.68)
    rays = np.zeros_like(u)
    for k in range(16):  # Tycho's ray system, fading with distance
        a0 = rng.random() * 2 * math.pi
        rays += np.exp(-((np.angle(np.exp(1j * (ang - a0)))) / 0.035) ** 2) * np.exp(-dist / (0.4 + 0.5 * rng.random()))
    albedo += 0.10 * np.clip(rays, 0, 1) * (dist > 0.04)
    albedo *= 0.92 + 0.08 * np.sqrt(np.clip(1.0 - d * d, 0, 1))  # the full Moon shows almost no limb darkening
    colour = np.clip(albedo, 0, 1)[..., None] * np.array([1.0, 0.985, 0.95], dtype=np.float32)
    return colour, alpha


def _put_disc(img, colour, alpha, cx, cy, gain=1.0):
    s = colour.shape[0]
    x0, y0 = int(cx - s / 2), int(cy - s / 2)
    region = img[y0:y0 + s, x0:x0 + s]
    a = alpha[..., None]
    region[...] = region * (1 - a) + colour * gain * a


def screen_image(name, kind, w=1024, h=576, seed=3):
    """An abstract readout as a packed image texture: navy field, faint grid, traces, bars (no text)."""
    rng = np.random.default_rng(seed)
    img = _panel(w, h)
    cyan, green, gold, grid = rgb("#2E8BC0", 2.0), rgb("#68C78B", 1.9), rgb("#F2C230", 1.5), rgb("#1A3346")
    x = np.arange(w, dtype=np.float32)
    if kind == "telemetry":  # a filled green area chart, a gold trend line and three level bars
        _grid(img, 48, grid)
        top = h * 0.48 - (60 * np.sin(x / 55.0) + 35 * np.sin(x / 17.0 + 1.0) + 70 * (x / w)) * 0.8
        yy = np.arange(h)[:, None]
        fill = (yy > top[None, :w]) & (yy < h * 0.5)
        img[:, : int(w * 0.62)][fill[:, : int(w * 0.62)]] = green * 0.55
        _line(img, x[: int(w * 0.62)], top[: int(w * 0.62)], green, 1)
        xs = np.linspace(20, w * 0.6, 12)
        _line(img, xs, h * 0.86 - np.cumsum(rng.normal(6, 10, 12)), gold, 1)
        for i in range(3):
            level = int(h * (0.25 + 0.3 * rng.random()))
            img[h - 50 - level:h - 50, int(w * 0.7) + i * 70:int(w * 0.7) + i * 70 + 34] = green
        _readout_lines(img, int(w * 0.68), 40, w - 30, 6, rng, (cyan, green))
    elif kind == "track":  # an orbit ground track over a latitude-longitude grid
        _grid(img, 64, grid)
        for k, colour in enumerate((cyan, cyan * 0.6, green)):
            _line(img, x, h * 0.5 - h * 0.3 * np.sin(x / w * 2 * math.pi + k * 0.9), colour, 1)
        _readout_lines(img, 30, h - 120, int(w * 0.4), 5, rng, (cyan, green))
    elif kind == "route":  # contour bands of a lunar ridge and a gold route with waypoints
        yy, xx = np.mgrid[0:h, 0:w]
        ridge = np.sin(xx / 90.0) * 40 + np.sin(xx / 37.0 + 1.0) * 18
        for level in range(7):
            img[np.abs((yy - h * 0.5 - ridge) - (level - 3) * 50) < 1.3] = rgb("#2A4A62", 1.6)
        px = np.linspace(w * 0.1, w * 0.9, 7)
        py = h * 0.5 + np.sin(px / 90.0) * 40 + np.sin(px / 37.0 + 1.0) * 18 - 30
        _line(img, px, py, gold, 2)
        for x0, y0 in zip(px, py):
            dd = np.hypot(yy - y0, xx - x0)
            img[(dd < 9) & (dd > 5)] = cyan
    elif kind == "moon":  # the near side of the full Moon, a small thumbnail and readout bars
        colour, alpha = moon_disc(int(h * 0.82), seed)
        _put_disc(img, colour, alpha, w * 0.36, h * 0.5, 0.3)
        small, small_alpha = moon_disc(int(h * 0.2), seed)
        _put_disc(img, small, small_alpha, w * 0.84, h * 0.2, 0.26)
        _readout_lines(img, int(w * 0.72), int(h * 0.42), w - 30, 8, rng, (cyan, green, cyan))
    elif kind == "trace":  # three waveforms and a bar column
        _grid(img, 48, grid)
        for k, colour in enumerate((cyan, green, cyan)):
            phase = rng.random() * 6.0
            y = h * (0.25 + 0.25 * k) + 22 * np.sin(x / 70.0 + phase) + 9 * np.sin(x / 23.0 + phase * 2)
            _line(img, x, y, colour, 1)
        for i in range(10):
            level = int(h * (0.12 + 0.5 * rng.random()))
            img[h - 40 - level:h - 40, int(w * 0.8) + i * 18:int(w * 0.8) + i * 18 + 10] = green if i % 3 else gold
    elif kind == "radar":  # concentric range rings and a sweep
        yy, xx = np.mgrid[0:h, 0:w]
        dd = np.hypot(yy - h * 0.5, xx - w * 0.5)
        for ring in range(1, 6):
            img[np.abs(dd - ring * h * 0.09) < 1.4] = green * 0.8
        sweep = np.angle(np.exp(1j * (np.arctan2(yy - h * 0.5, xx - w * 0.5) - 0.6)))
        img[(sweep < 0) & (sweep > -0.9) & (dd < h * 0.45)] += green * 0.35 * (1 + sweep[(sweep < 0) & (sweep > -0.9) & (dd < h * 0.45)] / 0.9)[:, None]
    elif kind == "chart":  # a rising line chart over a grid
        _grid(img, 40, grid)
        xs = np.linspace(30, w - 30, 16)
        _line(img, xs, h * 0.8 - np.cumsum(np.abs(rng.normal(18, 14, 16))), green, 2)
        _readout_lines(img, 30, 30, int(w * 0.5), 3, rng, (cyan,))
    rgba = np.concatenate([np.clip(img, 0, 8), np.ones((h, w, 1), dtype=np.float32)], axis=2)
    tex = bpy.data.images.new(name, w, h, alpha=True, float_buffer=True)
    tex.pixels.foreach_set(np.ascontiguousarray(rgba[::-1]).ravel())
    tex.pack()
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    t = m.node_tree.nodes.new("ShaderNodeTexImage")
    t.image = tex
    t.interpolation = 'Linear'
    m.node_tree.links.new(t.outputs[0], b.inputs["Base Color"])
    m.node_tree.links.new(t.outputs[0], b.inputs["Emission Color"])
    b.inputs["Emission Strength"].default_value = 2.2
    b.inputs["Roughness"].default_value = 0.3
    return m


def rod(name, a, b, radius, mat):
    """A thin cylinder from point a to point b."""
    mid, axis = (a + b) / 2, b - a
    o = cylinder(name, mid, radius, axis.length, mat, verts=12)
    o.rotation_euler = axis.to_track_quat('Z', 'Y').to_euler()
    return o


def screen_plane(name, at, size, mat):
    """A plane facing -Y (towards the camera) whose 0..1 UVs show the whole image."""
    bpy.ops.mesh.primitive_plane_add(size=1, location=at, rotation=(math.radians(90), 0, 0))
    o = bpy.context.object
    o.name = name
    o.scale = (size[0], size[1], 1)
    o.data.materials.append(mat)
    return o


def monitor(name, at, size, screen_mat, bezel, stand=True):
    """A thin monitor facing the camera, on a stand whose foot rests at at.z - h/2 - 0.12."""
    w, h = size
    box(name + "_Bezel", (at[0], at[1] + 0.018, at[2]), (w + 0.04, 0.03, h + 0.04), bezel)
    screen_plane(name + "_Screen", at, (w, h), screen_mat)
    if stand:
        box(name + "_Stand", (at[0], at[1] + 0.06, at[2] - h / 2 - 0.06), (0.06, 0.04, 0.12), bezel)
        box(name + "_Foot", (at[0], at[1] + 0.05, at[2] - h / 2 - 0.12), (0.26, 0.16, 0.012), bezel)


def workstation_row(prefix, y, xs, desk_top, mats, screens, divider_h, chairs=True):
    """A row of desks at depth y (back edge at y + 0.35) with monitors facing the camera and a low divider behind."""
    desk, divider, trim, bezel, chair = mats
    for i, (x0, x1) in enumerate(xs):
        cx, width = (x0 + x1) / 2, x1 - x0
        box(f"{prefix}Desk{i}", (cx, y, desk_top), (width, 0.75, 0.035), desk)
        box(f"{prefix}DeskFront{i}", (cx, y + 0.3, desk_top / 2), (width, 0.04, desk_top), divider)
        box(f"{prefix}Divider{i}", (cx, y + 0.42, divider_h / 2), (width, 0.05, divider_h), divider)
        box(f"{prefix}DividerTrim{i}", (cx, y + 0.42, divider_h + 0.01), (width, 0.06, 0.02), trim)
        n = max(1, int(width / 0.75))
        for k in range(n):
            mx = x0 + (k + 0.5) * width / n
            monitor(f"{prefix}Mon{i}_{k}", (mx, y + 0.12, desk_top + 0.12 + 0.2), (0.5, 0.3), screens[(i * 3 + k) % len(screens)], bezel)
            if not chairs:
                continue
            # an empty chair on the camera side, its back towards the camera
            box(f"{prefix}ChairBack{i}_{k}", (mx + 0.05, y - 0.62, 0.78), (0.44, 0.06, 0.5), chair, (math.radians(-8), 0, 0))
            box(f"{prefix}ChairSeat{i}_{k}", (mx + 0.05, y - 0.45, 0.48), (0.46, 0.44, 0.06), chair)


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    try:
        sc.render.engine = 'BLENDER_EEVEE'
    except TypeError:
        sc.render.engine = 'BLENDER_EEVEE_NEXT'
    sc.render.resolution_x, sc.render.resolution_y = 1536, 864
    sc.render.resolution_percentage = 100
    if hasattr(sc.eevee, "taa_render_samples"):
        sc.eevee.taa_render_samples = 64
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    sc.view_settings.exposure = 0.35
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = lin("#0B1826")
    bg.inputs[1].default_value = 0.9
    sc.world = world

    wall = material("Wall", "#1A2A3A", 0.9)
    floor = material("Floor", "#151C26", 0.85)
    ceiling = material("Ceiling", "#243243", 0.9, 0.0, "#243243", 0.08)
    seam = material("Seam", "#0A1018", 0.9)
    desk = material("Desk", "#5C5852", 0.6)
    divider = material("Divider", "#5E5A54", 1.0)
    trim = material("Trim", "#8A9099", 0.35, 0.8)
    bezel = material("Bezel", "#0A0E15", 0.4)
    chair = material("Chair", "#10151D", 0.7)
    lamp_metal = material("LampMetal", "#22262C", 0.4, 0.6)
    lamp_inner = material("LampInner", "#FFE2B0", 0.5, 0.0, "#FFC37A", 5.0)

    # room shell: back wall at y = 6.4 (the display wall), ceiling at 3.1 with recessed tiles
    box("Floor", (0, 3.2, -0.02), (8, 7, 0.04), floor)
    box("BackWall", (0, 6.45, 1.55), (8, 0.1, 3.1), wall)
    box("WallLeft", (-3.6, 3.2, 1.55), (0.1, 7, 3.1), wall)
    box("WallRight", (3.6, 3.2, 1.55), (0.1, 7, 3.1), wall)
    box("Ceiling", (0, 3.2, 3.12), (8, 7, 0.04), seam)
    for ix in range(-6, 6):
        for iy in range(0, 11):
            lit = (ix in (-3, 2)) and iy in (3, 7)
            box(f"Tile{ix}_{iy}", (ix * 0.6 + 0.3, iy * 0.6 + 0.3, 3.09), (0.57, 0.57, 0.02),
                material(f"TileLit{ix}{iy}", "#C8D6E6", 0.8, 0.0, "#C8D6E6", 0.25) if lit else ceiling)

    # the display wall: four large screens like the installed Rao portrait (charts, ground track, route, Moon)
    walls = [screen_image("WallTelemetry", "telemetry", seed=4), screen_image("WallTrack", "track", seed=6),
             screen_image("WallRoute", "route", seed=8), screen_image("WallMoon", "moon", seed=12)]
    for i, mat in enumerate(walls):
        x = -1.98 + i * 1.32
        box(f"WallDisplay{i}_Bezel", (x, 6.37, 2.22), (1.3, 0.05, 0.8), bezel)
        screen_plane(f"WallDisplay{i}", (x, 6.34, 2.22), (1.24, 0.74), mat)
        bpy.ops.object.light_add(type='AREA', location=(x, 6.1, 2.2), rotation=(math.radians(-90), 0, 0))
        glow = bpy.context.object  # the display's spill on the dividers and desks
        glow.data.energy = 26
        glow.data.size = 1.2
        glow.data.color = (0.55, 0.85, 0.85) if i != 3 else (0.85, 0.88, 0.92)

    # two rows of workstations with low dividers; an aisle in the middle of the near row
    small = [screen_image("DeskChart", "chart", 512, 320, 21), screen_image("DeskTrace", "trace", 512, 320, 23),
             screen_image("DeskMoon", "moon", 512, 320, 25), screen_image("DeskRadar", "radar", 512, 320, 27),
             screen_image("DeskTelemetry", "telemetry", 512, 320, 29)]
    mats = (desk, divider, trim, bezel, chair)
    workstation_row("RowB", 4.4, [(-3.3, -0.3), (0.3, 3.3)], 0.76, mats, small[3:] + small[:3], 1.0)
    workstation_row("RowA", 2.6, [(-3.0, -0.45), (0.45, 3.0)], 0.76, mats, small, 0.95, chairs=False)

    # the right edge: a tall status monitor and a shelf of binders, as in the portrait
    monitor("SideStatus", (2.75, 2.2, 1.18), (0.62, 0.42), screen_image("SideRadar", "radar", 512, 340, 31), bezel)
    for k in range(6):
        box(f"Binder{k}", (1.6 + k * 0.07, 2.85, 0.76 + 0.16), (0.05, 0.25, 0.3), material(f"BinderMat{k}", ("#2B3A4E", "#3A3F47", "#26313F")[k % 3], 0.8))

    # the desk lamp at the left: an articulated arm, a cone shade lit inside, warm light on the desk and divider
    cylinder("LampBase", (-1.25, 2.72, 0.785), 0.085, 0.02, lamp_metal)
    elbow = Vector((-1.31, 2.8, 1.21))
    rod("LampArmA", Vector((-1.25, 2.72, 0.795)), elbow, 0.009, lamp_metal)
    rod("LampArmB", elbow, Vector((-1.06, 2.7, 1.31)), 0.009, lamp_metal)
    aim = (math.radians(-25), math.radians(-25), 0)  # the shade's axis: down, towards the camera, to the right
    head = Vector((-1.02, 2.66, 1.27))
    down = Vector((0, 0, -1))
    down.rotate(Euler(aim))
    bpy.ops.mesh.primitive_cone_add(vertices=40, radius1=0.11, radius2=0.035, depth=0.15, end_fill_type='NOTHING',
                                    location=head, rotation=aim)
    shade = bpy.context.object
    shade.name = "LampShade"
    shade.data.materials.append(lamp_metal)
    opening = head + down * 0.07
    bpy.ops.mesh.primitive_circle_add(vertices=40, radius=0.1, fill_type='NGON', location=opening, rotation=aim)
    bulb = bpy.context.object
    bulb.name = "LampOpening"
    bulb.data.materials.append(lamp_inner)
    bpy.ops.object.light_add(type='SPOT', location=opening + down * 0.01, rotation=aim)
    spot = bpy.context.object
    spot.data.energy = 120
    spot.data.color = (1.0, 0.66, 0.36)
    spot.data.spot_size = math.radians(110)
    spot.data.spot_blend = 0.8
    spot.data.shadow_soft_size = 0.05
    bpy.ops.object.light_add(type='POINT', location=(-1.1, 2.9, 1.1))
    warm = bpy.context.object  # warm bounce off the divider behind the lamp
    warm.data.energy = 18
    warm.data.color = (1.0, 0.7, 0.45)
    warm.data.shadow_soft_size = 0.4
    box("Paper", (-0.82, 2.5, 0.781), (0.21, 0.29, 0.004), material("Paper", "#E8E4DA", 0.9), (0, 0, math.radians(12)))

    # cool ceiling light and a soft fill from the camera side keep the room readable but dark
    for i, (x, y) in enumerate([(-1.5, 2.1), (1.5, 2.1), (-1.5, 4.5), (1.5, 4.5)]):
        bpy.ops.object.light_add(type='AREA', location=(x, y, 3.0))
        down = bpy.context.object
        down.data.energy = 36
        down.data.size = 0.6
        down.data.color = (0.72, 0.84, 1.0)
    bpy.ops.object.light_add(type='AREA', location=(0, -0.5, 1.8), rotation=(math.radians(80), 0, 0))
    fill = bpy.context.object
    fill.data.energy = 40
    fill.data.size = 3.0
    fill.data.color = (0.6, 0.75, 0.95)

    # the caller's call camera: seated eye height, focused on the caller at 0.9 m, the room softly out of focus
    bpy.ops.object.camera_add(location=(0.0, 0.0, 1.27))
    cam = bpy.context.object
    cam.data.lens = 30
    cam.data.sensor_width = 36
    cam.data.dof.use_dof = True
    cam.data.dof.focus_distance = 0.9
    cam.data.dof.aperture_fstop = 5.0
    target = Vector((0.0, 6.4, 1.62))
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.camera = cam
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    sc.render.filepath = OUT
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGB'
    bpy.ops.render.render(write_still=True)
    print(f"RENDERED {OUT} {sc.render.resolution_x}x{sc.render.resolution_y} engine={sc.render.engine}")


if __name__ == "__main__":
    build()
