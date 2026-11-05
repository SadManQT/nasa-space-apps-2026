"""Build the modular habitat kit (board M1-05) with Blender alone: no generation service, no credits.

    blender --background --factory-startup --python production/tools/build_habitat_kit.py [-- --no-render | --only ID,ID [--cpu]]

--only re-renders the previews of the listed pieces without touching the published files; --cpu avoids the Metal path.

Every piece follows the sheets Sadman approved on 5 Nov 2026 (production/concept/environment_v1/
01_HabitatKit_sheet_A.png and _B.png, board M1-04). Image-to-3D services cannot return grid-exact,
pivot-exact modular geometry with clean LODs and collision, so the kit is authored procedurally
(the route the M1-35 lunar rock kit took) and the approved sheets are the design reference.

Output (deterministic, seed 20261105):
  game/assets/environment/kit/<Piece>_LOD0.glb   visual mesh + Godot collision nodes (-convcolonly / -colonly)
  game/assets/environment/kit/<Piece>_LOD1.glb   simplified mesh, half-size textures (Compatibility build)
  game/assets/environment/kit/textures/*.png     the tileable PBR sets (quilt, paint, steel, floor) for reuse
  game/assets/environment/kit/materials/*.tres   Godot materials bound to those textures
  game/assets/environment/kit/kit.json           catalogue: sizes, pivots, mount offsets, sockets, LODs, triangles
  production/manifest/habitat_kit.csv            gate specs for production/tools/verify_gate.py
  production/models/habitat_kit/preview/*.png    Cycles previews for production/tools/habitat_kit_contact.py

Conventions (metres, +Y up, Godot -Z forward; the script authors in that frame and bakes the axis swap):
  * every pivot is at the base centre (lowest point y = 0, the asset gate's floor rule);
  * wall pieces: finished face on the plane z = 0 facing -Z, body behind it (z in [0, 0.15]), 2.6 m tall,
    1 m grid widths (door module 3 m, hatch bulkhead 2 m, corner legs 0.5 m);
  * ceiling pieces are authored hanging: the visible face is the base (y = 0), the body above it;
  * floor tile: walking surface at y = 0.06 (mount at y = -0.06); bulkhead ring: inner sill 0.14 above its base;
  * moving parts are child nodes with their own pivots: DoorLeaf (slides +X by 1.25 m), HatchLeaf (hinge at
    the left collar, opens by a positive Y rotation into the room);
  * no text on any surface; the equipment bay screen is a separate material slot "Screen" for a live UI texture.
"""
import csv
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/environment/kit"
STAGE = ROOT / "production/models/habitat_kit"
SEED = 20261105
TASK = "M1-05"
SOURCE = "tools/build_habitat_kit.py (seed 20261105) from approved sheets 01_HabitatKit_sheet_A/B (M1-04)"
WALL_H, WALL_D = 2.6, 0.15
LOD_DISTANCE_M = 12.0
RENDER = "--no-render" not in sys.argv
ONLY = sys.argv[sys.argv.index("--only") + 1].split(",") if "--only" in sys.argv else []  # render previews for these ids only
CPU_RENDER = "--cpu" in sys.argv
GODOT_TO_BLENDER = Matrix.Rotation(math.radians(90), 4, "X")  # (x, y, z) -> (x, -z, y); det +1
COL_SUFFIXES = ("-colonly", "-convcolonly")

# ----------------------------------------------------------------------------------------------- textures

def fractal(rng, size, low, high, beta=1.6):
    """Periodic fractal noise: white noise filtered to a 1/f^beta band between the two frequencies (cycles/tile)."""
    f = np.fft.fftfreq(size) * size
    r = np.sqrt(f[:, None] ** 2 + f[None, :] ** 2)
    spec = rng.standard_normal((size, size)) + 1j * rng.standard_normal((size, size))
    filt = np.where((r >= low) & (r <= high), 1.0 / np.maximum(r, 1) ** (beta / 2), 0.0)
    out = np.real(np.fft.ifft2(spec * filt))
    return out / (out.std() + 1e-9)


def streaks(rng, size):
    """Brushed-metal grain: noise kept long along x and fine along y, periodic by construction."""
    f = np.fft.fftfreq(size) * size
    fx, fy = f[None, :], f[:, None]
    spec = rng.standard_normal((size, size)) + 1j * rng.standard_normal((size, size))
    filt = np.exp(-(fx / 6.0) ** 2) * (np.abs(fy) > 4) / np.maximum(np.abs(fy), 1) ** 0.3
    out = np.real(np.fft.ifft2(spec * filt))
    return out / (out.std() + 1e-9)


def normal_map(height_m, tile_m):
    """OpenGL/glTF tangent-space normal (+Y = up in the picture) from a periodic height field in metres."""
    size = height_m.shape[0]
    px = tile_m / size
    dx = (np.roll(height_m, -1, axis=1) - np.roll(height_m, 1, axis=1)) / (2 * px)
    dy = (np.roll(height_m, 1, axis=0) - np.roll(height_m, -1, axis=0)) / (2 * px)  # up = towards row 0
    n = np.stack([-dx, -dy, np.ones_like(dx)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return (n + 1) / 2


def renormalise(encoded):
    n = encoded * 2 - 1
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return (n + 1) / 2


def save_image(name, rgb, directory, srgb=True):
    """Writes an RGB float array (row 0 = top of the picture) as PNG and returns the Blender image block."""
    h, w = rgb.shape[:2]
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[:, :, :3] = np.clip(rgb[:, :, :3], 0, 1)
    im = bpy.data.images.new(name, width=w, height=h, float_buffer=False)
    im.colorspace_settings.name = "sRGB" if srgb else "Non-Color"
    im.pixels.foreach_set(np.ascontiguousarray(np.flipud(rgba)).ravel())
    im.filepath_raw = str(directory / (name + ".png"))
    im.file_format = "PNG"
    im.save()
    return im


def half(arr):
    return 0.25 * (arr[0::2, 0::2] + arr[1::2, 0::2] + arr[0::2, 1::2] + arr[1::2, 1::2])


def quilt_cell(u, v, p=0.55):
    return (np.sin(np.pi * u) ** p) * (np.sin(np.pi * v) ** p)


def make_textures():
    """Tileable PBR sets (quilt 1024, floor 1024, paint 512, steel 512 px at LOD0; halves at LOD1).
    Returns {lod: {set: {base, normal, orm, tile}}}."""
    rng = np.random.default_rng(SEED)
    sets = {}

    def grid(size):
        y, x = np.mgrid[0:size, 0:size] / size
        return x, 1 - y  # v up

    # Quilt: 2 x 2 puffed MLI cells per 0.5 m tile, stitched seams, fabric weave, light grime in the seams.
    size = 1024
    x, y = grid(size)
    cu, cv = (x * 2) % 1, (y * 2) % 1
    puff = quilt_cell(cu, cv)
    seam = np.minimum(np.minimum(cu, 1 - cu), np.minimum(cv, 1 - cv))
    groove = np.exp(-(seam / 0.018) ** 2)
    weave = 0.5 * (np.sin(2 * np.pi * x * 110) * np.sin(2 * np.pi * y * 110))
    wrinkle = fractal(rng, size, 3, 30, 1.9)
    stitch = (np.sin(2 * np.pi * x * 64) ** 8 + np.sin(2 * np.pi * y * 64) ** 8) * (seam < 0.012)
    height = 0.016 * puff - 0.007 * groove + 0.0004 * weave + 0.0015 * wrinkle * puff - 0.0004 * stitch
    grime = fractal(rng, size, 2, 20, 1.8)
    tone = 0.985 + 0.010 * weave - 0.09 * groove + 0.012 * grime - 0.02 * (1 - puff) * (0.5 + 0.5 * grime)
    base = np.stack([tone * 0.925, tone * 0.933, tone * 0.941], axis=-1)
    ao = np.clip(1 - 0.45 * groove - 0.10 * (1 - puff), 0, 1)
    rough = np.clip(0.70 + 0.05 * weave + 0.05 * grime, 0, 1)
    sets["Quilt"] = dict(tile=0.5, base=base, normal=normal_map(height, 0.5), orm=np.stack([ao, rough, 0 * ao], -1))

    # Paint: neutral powder-coated metal with orange peel and faint scuffs, tinted per colour.
    size = 512
    x, y = grid(size)
    peel = fractal(rng, size, 20, 120, 1.2)
    scuff = fractal(rng, size, 3, 40, 2.2)
    height = 0.00010 * peel + 0.00025 * np.clip(scuff - 1.6, 0, None)
    tone = 1 - 0.030 * np.clip(scuff - 1.2, 0, None) - 0.012 * (fractal(rng, size, 2, 10, 2.0) > 1.0)
    rough = np.clip(0.42 + 0.08 * fractal(rng, size, 3, 30, 1.8) + 0.25 * np.clip(scuff - 1.4, 0, None), 0, 1)
    ao = np.ones_like(tone)
    paint_normal = normal_map(height, 0.5)
    paint_orm = np.stack([ao, rough, 0 * ao], -1)
    tints = {"Grey": (0.84, 0.85, 0.87), "White": (0.925, 0.933, 0.941), "Navy": (0.122, 0.165, 0.267),
             "Orange": (0.949, 0.420, 0.129), "Blue": (0.180, 0.545, 0.753), "Dark": (0.20, 0.205, 0.215)}
    for name, c in tints.items():
        base = np.stack([tone * c[0], tone * c[1], tone * c[2]], -1)
        sets["Paint" + name] = dict(tile=0.5, base=base, normal=paint_normal, orm=paint_orm, shared="Paint")

    # Steel: brushed stainless for handrails, the hatch wheel, tie-down rings and pipe flanges.
    size = 512
    grain = streaks(rng, size)
    height = 0.00004 * grain
    tone = 0.80 + 0.035 * grain
    base = np.stack([tone, tone * 1.005, tone * 1.01], -1)
    rough = np.clip(0.33 + 0.07 * grain, 0.1, 0.8)
    sets["Steel"] = dict(tile=0.25, base=base, normal=normal_map(height, 0.25), orm=np.stack([np.ones_like(tone), rough, np.ones_like(tone)], -1))

    # Floor: dark anti-slip deck, raised domes on a 25 mm pitch, grit, light wear lanes.
    size = 1024
    x, y = grid(size)
    pitch = 40
    du, dv = (x * pitch) % 1 - 0.5, (y * pitch) % 1 - 0.5
    d = np.sqrt(du ** 2 + dv ** 2) / 0.36
    dome = np.clip(1 - d ** 2, 0, 1)
    grit = fractal(rng, size, 30, 200, 1.0)
    wear = fractal(rng, size, 2, 10, 2.0)
    height = 0.0012 * dome + 0.00004 * grit
    tone = 0.26 + 0.015 * grit + 0.03 * np.clip(wear, 0, None) + 0.04 * dome
    base = np.stack([tone * 0.95, tone * 0.97, tone * 1.0], -1)
    rough = np.clip(0.86 - 0.05 * dome + 0.03 * grit - 0.1 * np.clip(wear, 0, None), 0, 1)
    ao = np.clip(1 - 0.12 * (1 - dome) * (d < 1.4), 0, 1)
    sets["Floor"] = dict(tile=1.0, base=base, normal=normal_map(height, 1.0), orm=np.stack([ao, rough, 0 * ao], -1))

    images = {0: {}, 1: {}}
    (OUT / "textures").mkdir(parents=True, exist_ok=True)
    (STAGE / "textures_lod1").mkdir(parents=True, exist_ok=True)
    for name, s in sets.items():
        shared = s.get("shared", name)
        for lod, directory in ((0, OUT / "textures"), (1, STAGE / "textures_lod1")):
            suffix = "_LOD1" if lod else ""
            shrink = (lambda a: a) if lod == 0 else half
            maps = {"base": save_image(f"T_Kit_{name}_BaseColor{suffix}", shrink(s["base"]), directory)}
            for key, label in (("normal", "Normal"), ("orm", "ORM")):
                img_name = f"T_Kit_{shared}_{label}{suffix}"
                if img_name not in bpy.data.images:
                    arr = shrink(s[key])
                    if key == "normal" and lod:
                        arr = renormalise(arr)
                    save_image(img_name, arr, directory, srgb=False)
                maps[key] = bpy.data.images[img_name]
            images[lod][name] = dict(maps, tile=s["tile"])
    return images


# ----------------------------------------------------------------------------------------------- materials

_gltf_group = None


def gltf_output_group():
    """The node group Blender's glTF exporter reads the occlusion channel from."""
    global _gltf_group
    if _gltf_group is None:
        _gltf_group = bpy.data.node_groups.new("glTF Material Output", "ShaderNodeTree")
        _gltf_group.interface.new_socket("Occlusion", in_out="INPUT", socket_type="NodeSocketFloat")
        _gltf_group.nodes.new("NodeGroupInput")
    return _gltf_group


def pbr_material(name, maps, roughness=0.5, color=None, emission=None, alpha=None):
    mat = bpy.data.materials.new(name)
    if bpy.app.version < (5, 0, 0):
        mat.use_nodes = True
    tree = mat.node_tree
    bsdf = tree.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = roughness
    if color is not None:
        bsdf.inputs["Base Color"].default_value = (*color, 1)
    if maps is not None:
        tex = tree.nodes.new("ShaderNodeTexImage")
        tex.image = maps["base"]
        tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        orm = tree.nodes.new("ShaderNodeTexImage")
        orm.image = maps["orm"]
        split = tree.nodes.new("ShaderNodeSeparateColor")
        tree.links.new(orm.outputs["Color"], split.inputs["Color"])
        tree.links.new(split.outputs["Green"], bsdf.inputs["Roughness"])
        tree.links.new(split.outputs["Blue"], bsdf.inputs["Metallic"])
        group = tree.nodes.new("ShaderNodeGroup")
        group.node_tree = gltf_output_group()
        tree.links.new(split.outputs["Red"], group.inputs["Occlusion"])
        nrm = tree.nodes.new("ShaderNodeTexImage")
        nrm.image = maps["normal"]
        bump = tree.nodes.new("ShaderNodeNormalMap")
        tree.links.new(nrm.outputs["Color"], bump.inputs["Color"])
        tree.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission[0], 1)
        bsdf.inputs["Emission Strength"].default_value = emission[1]
    if alpha is not None:
        bsdf.inputs["Alpha"].default_value = alpha
        mat.surface_render_method = "BLENDED"
        mat.use_backface_culling = False
    return mat


MATERIAL_KEYS = ("Quilt", "PaintGrey", "PaintWhite", "PaintNavy", "PaintOrange", "PaintBlue", "PaintDark", "Steel", "Floor")


def make_materials(images):
    """Material table per LOD: key -> (material, tile metres). Image blocks are shared so GLBs stay small."""
    mats = {}
    for lod in (0, 1):
        suffix = "" if lod == 0 else "_LOD1"
        table = {key: (pbr_material("M_Kit_" + key + suffix, images[lod][key]), images[lod][key]["tile"]) for key in MATERIAL_KEYS}
        table["Diffuser"] = (pbr_material("M_Kit_Diffuser" + suffix, None, 0.6, (1.0, 0.86, 0.70), emission=((1.0, 0.86, 0.70), 4.0)), 1.0)
        table["Screen"] = (pbr_material("Screen" + suffix, None, 0.12, (0.02, 0.025, 0.03)), 1.0)
        table["Glass"] = (pbr_material("M_Kit_Glass" + suffix, None, 0.05, (0.75, 0.85, 0.95), alpha=0.22), 1.0)
        mats[lod] = table
    return mats


# ----------------------------------------------------------------------------------------------- geometry

AX = {"X": Vector((1, 0, 0)), "Y": Vector((0, 1, 0)), "Z": Vector((0, 0, 1))}
# (normal, tangent, bitangent) per box face, tangent x bitangent = normal
BOX_FACES = [((1, 0, 0), (0, 1, 0), (0, 0, 1)), ((-1, 0, 0), (0, 0, 1), (0, 1, 0)),
             ((0, 1, 0), (0, 0, 1), (1, 0, 0)), ((0, -1, 0), (1, 0, 0), (0, 0, 1)),
             ((0, 0, 1), (1, 0, 0), (0, 1, 0)), ((0, 0, -1), (0, 1, 0), (1, 0, 0))]


def polygon_normal(pts):
    n = Vector((0, 0, 0))
    for a, b in zip(pts, pts[1:] + pts[:1]):
        n += a.cross(b)
    return n


def planar_uv(pts, tile):
    pts = [Vector(p) for p in pts]
    n = polygon_normal(pts)
    ax = [abs(n.x), abs(n.y), abs(n.z)]
    a_i, b_i = {0: (2, 1), 1: (0, 2), 2: (0, 1)}[ax.index(max(ax))]
    return [(p[a_i] / tile, p[b_i] / tile) for p in pts]


class Builder:
    """Accumulates faces with UVs and material keys, then becomes one Blender mesh object."""

    def __init__(self, table):
        self.table = table
        self.keys = list(table)
        self.verts, self.faces, self.uvs, self.mats, self.smooth = [], [], [], [], []

    def tile(self, key):
        return self.table[key][1]

    def add_verts(self, pts):
        base = len(self.verts)
        self.verts.extend(Vector(p) for p in pts)
        return base

    def add_face(self, idx, uvs, key, smooth=False, outward=None):
        idx, uvs = list(idx), list(uvs)
        if outward is not None and polygon_normal([self.verts[i] for i in idx]).dot(Vector(outward)) < 0:
            idx, uvs = idx[::-1], uvs[::-1]
        self.faces.append(idx); self.uvs.append(uvs); self.mats.append(self.keys.index(key)); self.smooth.append(smooth)

    def quad(self, pts, key, uvs=None, smooth=False, outward=None):
        base = self.add_verts(pts)
        self.add_face([base + i for i in range(len(pts))], uvs or planar_uv(pts, self.tile(key)), key, smooth, outward)

    def box(self, center, size, key, skip=()):
        c, s = Vector(center), Vector(size)
        t = self.tile(key)
        for n, ta, bi in BOX_FACES:
            if n in skip:
                continue
            n, ta, bi = Vector(n), Vector(ta), Vector(bi)
            face_c = c + Vector((n.x * s.x, n.y * s.y, n.z * s.z)) / 2
            ea = Vector((ta.x * s.x, ta.y * s.y, ta.z * s.z)) / 2
            eb = Vector((bi.x * s.x, bi.y * s.y, bi.z * s.z)) / 2
            pts = [face_c - ea - eb, face_c + ea - eb, face_c + ea + eb, face_c - ea + eb]
            self.quad(pts, key, [(p.dot(ta) / t, p.dot(bi) / t) for p in pts])

    def recess(self, x0, x1, y0, y1, z0, z1, key):
        """A pocket in a wall seen from -Z: four inward-facing side walls and a back face at z1."""
        self.quad([(x0, y0, z0), (x0, y1, z0), (x0, y1, z1), (x0, y0, z1)], key, outward=(1, 0, 0))
        self.quad([(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)], key, outward=(-1, 0, 0))
        self.quad([(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)], key, outward=(0, 1, 0))
        self.quad([(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)], key, outward=(0, -1, 0))
        self.quad([(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], key, outward=(0, 0, -1))

    def cylinder(self, p0, p1, radius, key, segs=16, caps=True, smooth=True, radius1=None):
        p0, p1 = Vector(p0), Vector(p1)
        axis = (p1 - p0).normalized()
        u = AX["Y"] if abs(axis.dot(AX["Y"])) < 0.9 else AX["X"]
        u = (u - axis * u.dot(axis)).normalized()
        v = axis.cross(u)
        r1 = radius if radius1 is None else radius1
        t = self.tile(key)
        angles = [2 * math.pi * i / segs for i in range(segs)]
        ring0 = [p0 + (u * math.cos(a) + v * math.sin(a)) * radius for a in angles]
        ring1 = [p1 + (u * math.cos(a) + v * math.sin(a)) * r1 for a in angles]
        b0, b1 = self.add_verts(ring0), self.add_verts(ring1)
        length = (p1 - p0).length
        arc = 2 * math.pi * radius / segs
        for i in range(segs):
            j = (i + 1) % segs
            uvs = [(i * arc / t, 0), ((i + 1) * arc / t, 0), ((i + 1) * arc / t, length / t), (i * arc / t, length / t)]
            self.add_face([b0 + i, b0 + j, b1 + j, b1 + i], uvs, key, smooth, outward=(ring0[i] + ring0[j]) / 2 - p0)
        if caps:
            self.add_face([b1 + i for i in range(segs)], [(p.dot(u) / t, p.dot(v) / t) for p in ring1], key, False, outward=axis)
            self.add_face([b0 + i for i in range(segs)], [(p.dot(u) / t, p.dot(v) / t) for p in ring0], key, False, outward=-axis)

    def torus(self, center, axis, R, r, key, segs=24, rings=8):
        c, axis = Vector(center), Vector(axis).normalized()
        u = AX["X"] if abs(axis.dot(AX["X"])) < 0.9 else AX["Y"]
        u = (u - axis * u.dot(axis)).normalized()
        v = axis.cross(u)
        t = self.tile(key)
        grid = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            radial = u * math.cos(a) + v * math.sin(a)
            grid.append(self.add_verts([c + radial * (R + r * math.cos(2 * math.pi * j / rings)) + axis * (r * math.sin(2 * math.pi * j / rings)) for j in range(rings)]))
        for i in range(segs):
            i2 = (i + 1) % segs
            a = 2 * math.pi * (i + 0.5) / segs
            ring_c = c + (u * math.cos(a) + v * math.sin(a)) * R
            for j in range(rings):
                j2 = (j + 1) % rings
                idx = [grid[i] + j, grid[i2] + j, grid[i2] + j2, grid[i] + j2]
                uvs = [(i / segs * 2 * math.pi * R / t, j / rings * 2 * math.pi * r / t), ((i + 1) / segs * 2 * math.pi * R / t, j / rings * 2 * math.pi * r / t),
                       ((i + 1) / segs * 2 * math.pi * R / t, (j + 1) / rings * 2 * math.pi * r / t), (i / segs * 2 * math.pi * R / t, (j + 1) / rings * 2 * math.pi * r / t)]
                mid = sum((self.verts[k] for k in idx), Vector()) / 4
                self.add_face(idx, uvs, key, True, outward=mid - ring_c)

    def quilt(self, origin, ea, eb, normal, width, height, cols, rows, sub, amp, key="Quilt"):
        """Puffed quilt grid: origin at one corner, ea/eb unit axes along width/height, normal outward."""
        o, ea, eb, n = Vector(origin), Vector(ea), Vector(eb), Vector(normal)
        nx, ny = cols * sub, rows * sub
        grid = []
        for j in range(ny + 1):
            row = []
            for i in range(nx + 1):
                cu, cv = (i % sub) / sub, (j % sub) / sub
                h = amp * quilt_cell(cu, cv) if 0 < i < nx and 0 < j < ny else 0.0
                row.append(o + ea * (width * i / nx) + eb * (height * j / ny) + n * h)
            grid.append(self.add_verts(row))
        for j in range(ny):
            for i in range(nx):
                idx = [grid[j] + i, grid[j] + i + 1, grid[j + 1] + i + 1, grid[j + 1] + i]
                uvs = [(i / sub / 2, j / sub / 2), ((i + 1) / sub / 2, j / sub / 2), ((i + 1) / sub / 2, (j + 1) / sub / 2), (i / sub / 2, (j + 1) / sub / 2)]
                self.add_face(idx, uvs, key, True, outward=n)

    def ring_prism(self, inner, outer, depth, key, front_normal, closed=True, centre=None, smooth_inner=False):
        """Solid between two parallel loops (front face at the given points), extruded by the depth vector."""
        inner, outer, d = [Vector(p) for p in inner], [Vector(p) for p in outer], Vector(depth)
        n = len(inner)
        centre = Vector(centre) if centre is not None else sum(inner, Vector()) / n
        fi, fo = self.add_verts(inner), self.add_verts(outer)
        bi, bo = self.add_verts([p + d for p in inner]), self.add_verts([p + d for p in outer])
        t = self.tile(key)
        for i in range(n if closed else n - 1):
            j = (i + 1) % n
            q = [inner[i], inner[j], outer[j], outer[i]]
            self.add_face([fi + i, fi + j, fo + j, fo + i], planar_uv(q, t), key, False, outward=front_normal)
            self.add_face([bi + i, bi + j, bo + j, bo + i], planar_uv([p + d for p in q], t), key, False, outward=-Vector(front_normal))
            self.add_face([fi + i, fi + j, bi + j, bi + i], planar_uv([inner[i], inner[j], inner[j] + d, inner[i] + d], t), key, smooth_inner, outward=centre - (inner[i] + inner[j]) / 2)
            self.add_face([fo + i, fo + j, bo + j, bo + i], planar_uv([outer[i], outer[j], outer[j] + d, outer[i] + d], t), key, False, outward=(outer[i] + outer[j]) / 2 - centre)
        if not closed:
            for a, nb in ((0, 1), (n - 1, n - 2)):
                q = [fi + a, fo + a, bo + a, bi + a]
                self.add_face(q, planar_uv([self.verts[k] for k in q], t), key, False, outward=inner[a] - inner[nb])

    def to_object(self, name):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([tuple(v) for v in self.verts], [], self.faces)
        for key in self.keys:
            mesh.materials.append(self.table[key][0])
        uv = mesh.uv_layers.new(name="UVMap")
        loop = 0
        for face, uvs, m, s in zip(mesh.polygons, self.uvs, self.mats, self.smooth):
            face.material_index = m
            face.use_smooth = s
            for k, value in enumerate(uvs):
                uv.data[loop + k].uv = value
            loop += len(uvs)
        mesh.validate(clean_customdata=False)
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def rounded_rect(w, h, r, n_arc=6):
    """CCW outline (x, y) of a rounded rectangle centred at the origin."""
    pts = []
    for cx, cy, a0 in ((w / 2 - r, -h / 2 + r, -90), (w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90), (-w / 2 + r, -h / 2 + r, 180)):
        for k in range(n_arc + 1):
            a = math.radians(a0 + 90 * k / n_arc)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def arch(w, h, r, n_arc=6):
    """Open outline of a doorway: up the right jamb, round the two top corners, down the left jamb (CCW)."""
    pts = [(w / 2, 0)]
    for cx, cy, a0 in ((w / 2 - r, h - r, 0), (-w / 2 + r, h - r, 90)):
        for k in range(n_arc + 1):
            a = math.radians(a0 + 90 * k / n_arc)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    pts.append((-w / 2, 0))
    return pts


def loop_to_wall(pts2, z):
    return [(x, y, z) for x, y in pts2]


def hole_loops(radius, rect, cx, cy, segs=32):
    """Matching loops for a round hole in a rectangle (x0, x1, y0, y1): the circle and its radial projection."""
    x0, x1, y0, y1 = rect
    corners = {math.atan2(y - cy, x - cx) % (2 * math.pi) for x in (x0, x1) for y in (y0, y1)}
    inner, outer = [], []
    for a in sorted({2 * math.pi * i / segs for i in range(segs)} | corners):
        c, s = math.cos(a), math.sin(a)
        inner.append((cx + radius * c, cy + radius * s))
        k = min([(x1 - cx) / c if c > 1e-9 else math.inf, (x0 - cx) / c if c < -1e-9 else math.inf,
                 (y1 - cy) / s if s > 1e-9 else math.inf, (y0 - cy) / s if s < -1e-9 else math.inf])
        outer.append((cx + k * c, cy + k * s))
    return inner, outer


def octagon(apothem, cy, z=None):
    pts = [(apothem / math.cos(math.pi / 8) * math.cos(a), cy + apothem / math.cos(math.pi / 8) * math.sin(a)) for a in (math.pi / 8 + k * math.pi / 4 for k in range(8))]
    return pts if z is None else loop_to_wall(pts, z)


# ----------------------------------------------------------------------------------------------- pieces

RAIL = 0.04


def wall_frame(b, width, x0=None, skirting=True):
    """Frame rails, back body and navy skirting shared by the quilted wall pieces (front face left open)."""
    x0 = -width / 2 if x0 is None else x0
    xc = x0 + width / 2
    b.box((xc, WALL_H / 2, WALL_D / 2 + 0.02), (width, WALL_H, WALL_D - 0.04), "PaintGrey", skip=((0, 0, -1),))
    b.box((x0 + RAIL / 2, WALL_H / 2, 0.025), (RAIL, WALL_H, 0.05), "PaintGrey")
    b.box((x0 + width - RAIL / 2, WALL_H / 2, 0.025), (RAIL, WALL_H, 0.05), "PaintGrey")
    b.box((xc, WALL_H - RAIL / 2, 0.025), (width - 2 * RAIL, RAIL, 0.05), "PaintGrey")
    if skirting:
        b.box((xc, 0.15, 0.03), (width - 2 * RAIL, 0.30, 0.06), "PaintNavy")
        b.box((xc, 0.315, 0.02), (width - 2 * RAIL, 0.03, 0.04), "PaintGrey")


def quilt_region(b, x0, y0, w, h, lod, z=0.04):
    cols, rows = max(1, round(w / 0.23)), max(1, round(h / 0.25))
    b.quilt((x0 + w, y0, z), (-1, 0, 0), (0, 1, 0), (0, 0, -1), w, h, cols, rows, 5 if lod == 0 else 2, 0.028 if lod == 0 else 0.0)


def handrail(b, p0, p1, lod, radius=0.016, stand=0.06):
    segs = 12 if lod == 0 else 6
    b.cylinder(p0, p1, radius, "Steel", segs=segs)
    for p in (Vector(p0), Vector(p1)):
        b.cylinder(p + Vector((0, 0, stand)), p, radius * 0.75, "Steel", segs=segs)
        b.box(p + Vector((0, 0, stand + 0.01)), (0.05, 0.05, 0.02), "PaintGrey")


def handle(b, center, height, lod, key="PaintOrange", stand=0.07, radius=0.016, direction=(0, 0, -1)):
    """Grab handle standing off a surface: bar parallel to Y, legs along -direction back to the surface."""
    c, d = Vector(center), Vector(direction)
    segs = 12 if lod == 0 else 6
    top, bottom = c + Vector((0, height / 2, 0)) + d * stand, c - Vector((0, height / 2, 0)) + d * stand
    b.cylinder(bottom, top, radius, key, segs=segs)
    for end in (top, bottom):
        b.cylinder(end, end - d * stand, radius, key, segs=segs)
        b.box(end - d * (stand + 0.006), (0.05, 0.05, 0.012) if abs(d.z) > 0.5 else (0.012, 0.05, 0.05), "PaintGrey")


def piece_wall_straight(b, lod):
    wall_frame(b, 1.0)
    quilt_region(b, -0.46, 0.33, 0.92, WALL_H - RAIL - 0.33, lod)
    handrail(b, (-0.42, 1.0, -0.04), (0.42, 1.0, -0.04), lod)
    return [("WallStraight_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D))]


def piece_wall_corner(b, lod):
    """Leg A along X (x in [-0.5, 0], face z = 0 facing -Z) and leg B along Z (z in [-0.5, 0], face x = 0 facing -X)."""
    wall_frame(b, 0.5, x0=-0.5)
    quilt_region(b, -0.46, 0.33, 0.42, WALL_H - RAIL - 0.33, lod)
    # corner column, leg B body, rails, skirting and quilt (leg A rotated 90 degrees)
    b.box((WALL_D / 2, WALL_H / 2, WALL_D / 2 + 0.02), (WALL_D, WALL_H, WALL_D - 0.04), "PaintGrey")
    b.box((0.025, WALL_H / 2, 0.02), (0.05, WALL_H, RAIL), "PaintGrey")
    b.box((WALL_D / 2 + 0.02, WALL_H / 2, -0.25), (WALL_D - 0.04, WALL_H, 0.5), "PaintGrey", skip=((-1, 0, 0),))
    b.box((0.025, WALL_H / 2, -0.02), (0.05, WALL_H, RAIL), "PaintGrey")
    b.box((0.025, WALL_H / 2, -0.5 + RAIL / 2), (0.05, WALL_H, RAIL), "PaintGrey")
    b.box((0.025, WALL_H - RAIL / 2, -0.25), (0.05, RAIL, 0.5 - 2 * RAIL), "PaintGrey")
    b.box((0.03, 0.15, -0.25), (0.06, 0.30, 0.5 - 2 * RAIL), "PaintNavy")
    b.box((0.02, 0.315, -0.25), (0.04, 0.03, 0.5 - 2 * RAIL), "PaintGrey")
    rows = round((WALL_H - RAIL - 0.33) / 0.25)
    b.quilt((0.04, 0.33, -0.04), (0, 0, -1), (0, 1, 0), (-1, 0, 0), 0.42, WALL_H - RAIL - 0.33, 2, rows, 5 if lod == 0 else 2, 0.028 if lod == 0 else 0.0)
    return [("WallCornerA_Col-convcolonly", (-0.175, WALL_H / 2, WALL_D / 2), (0.65, WALL_H, WALL_D)),
            ("WallCornerB_Col-convcolonly", (WALL_D / 2, WALL_H / 2, -0.25), (WALL_D, WALL_H, 0.5))]


def piece_wall_window(b, lod):
    wall_frame(b, 1.0)
    w, h, cy, lip = 0.56, 0.42, 1.55, 0.08
    quilt_region(b, -0.46, 0.33, 0.92, cy - h / 2 - lip - 0.33, lod)
    quilt_region(b, -0.46, cy + h / 2 + lip, 0.92, WALL_H - RAIL - (cy + h / 2 + lip), lod)
    side = (0.92 - w - 2 * lip) / 2
    for sx in (-1, 1):
        b.box((sx * (w / 2 + lip + side / 2), cy, 0.03), (side, h + 2 * lip, 0.02), "PaintGrey")
    n_arc = 6 if lod == 0 else 2
    inner, outer = rounded_rect(w, h, 0.10, n_arc), rounded_rect(w + 2 * lip, h + 2 * lip, 0.18, n_arc)
    b.ring_prism([(x, cy + y, -0.05) for x, y in inner], [(x, cy + y, -0.05) for x, y in outer], (0, 0, 0.12), "PaintNavy", (0, 0, -1), centre=(0, cy, -0.05), smooth_inner=True)
    pane = [(x * 0.98, cy + y * 0.98, 0.03) for x, y in inner]
    base = b.add_verts(pane)
    b.add_face([base + i for i in range(len(pane))], [(x, y) for x, y, _ in pane], "Glass", False, outward=(0, 0, -1))
    if lod == 0:
        for x, y in rounded_rect(w + lip, h + lip, 0.14, 3):
            b.cylinder((x, cy + y, -0.05), (x, cy + y, -0.056), 0.009, "Steel", segs=8)
    return [("WallWindow_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D))]


def piece_wall_equipbay(b, lod):
    bay_w, bay_h, bay_y0, depth = 0.70, 0.90, 1.00, 0.11
    b.box((0, WALL_H / 2, WALL_D / 2 + 0.02), (1.0, WALL_H, WALL_D - 0.04), "PaintGrey", skip=((0, 0, -1),))
    b.box((-0.5 + RAIL / 2, WALL_H / 2, 0.025), (RAIL, WALL_H, 0.05), "PaintGrey")
    b.box((0.5 - RAIL / 2, WALL_H / 2, 0.025), (RAIL, WALL_H, 0.05), "PaintGrey")
    b.box((0, WALL_H - RAIL / 2, 0.025), (1.0 - 2 * RAIL, RAIL, 0.05), "PaintGrey")
    b.box((0, 0.15, 0.03), (1.0 - 2 * RAIL, 0.30, 0.06), "PaintNavy")
    # plain painted panel plates around the recessed bay (front face at z = 0.01)
    b.box((0, (0.30 + bay_y0) / 2, 0.02), (1.0 - 2 * RAIL, bay_y0 - 0.30, 0.02), "PaintGrey")
    b.box((0, (bay_y0 + bay_h + WALL_H - RAIL) / 2, 0.02), (1.0 - 2 * RAIL, WALL_H - RAIL - bay_y0 - bay_h, 0.02), "PaintGrey")
    side_w = (1.0 - 2 * RAIL - bay_w) / 2
    for sx in (-1, 1):
        b.box((sx * (bay_w / 2 + side_w / 2), bay_y0 + bay_h / 2, 0.02), (side_w, bay_h, 0.02), "PaintGrey")
    b.recess(-bay_w / 2, bay_w / 2, bay_y0, bay_y0 + bay_h, 0.01, 0.01 + depth, "PaintGrey")
    # navy console body inside the recess, screen (live UI slot), toggles, lamps, gauge
    b.box((0, bay_y0 + bay_h / 2, 0.075), (bay_w - 0.06, bay_h - 0.06, 0.06), "PaintNavy")
    b.box((0, 1.65, 0.04425), (0.52, 0.32, 0.0015), "PaintDark")
    b.quad([(-0.25, 1.50, 0.043), (0.25, 1.50, 0.043), (0.25, 1.80, 0.043), (-0.25, 1.80, 0.043)], "Screen", [(0, 0), (1, 0), (1, 1), (0, 1)], outward=(0, 0, -1))
    if lod == 0:
        for k in range(4):
            x = -0.18 + k * 0.07
            b.cylinder((x, 1.24, 0.045), (x, 1.24, 0.015), 0.012, "PaintDark", segs=10)
            b.cylinder((x, 1.24, 0.015), (x, 1.258, -0.005), 0.005, "Steel", segs=8)
        b.cylinder((0.16, 1.24, 0.045), (0.16, 1.24, 0.035), 0.009, "PaintOrange", segs=10)
        b.cylinder((0.21, 1.24, 0.045), (0.21, 1.24, 0.035), 0.009, "PaintBlue", segs=10)
        b.cylinder((0.10, 1.11, 0.045), (0.10, 1.11, 0.030), 0.055, "PaintDark", segs=16)
        b.torus((0.10, 1.11, 0.030), (0, 0, 1), 0.055, 0.006, "Steel", segs=16, rings=6)
        b.box((-0.10, 1.11, 0.040), (0.14, 0.05, 0.01), "PaintDark")
    for sx in (-1, 1):
        handle(b, (sx * 0.43, 1.45, 0.01), 0.5, lod)
    return [("WallEquipBay_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D))]


DOOR_CX, DOOR_W, DOOR_H, DOOR_DEPTH, DOOR_Z0 = -0.5, 1.2, 2.1, 0.30, -0.075


def piece_door_frame(b, lod):
    """3 m module, 1.2 x 2.1 m opening centred at x = -0.5; the leaf parks inside the wide +X jamb."""
    cx, ow, oh, depth, z0 = DOOR_CX, DOOR_W, DOOR_H, DOOR_DEPTH, DOOR_Z0
    for x_a, x_b in ((-1.5, cx - ow / 2), (cx + ow / 2, 1.5)):
        w, xm = x_b - x_a, (x_a + x_b) / 2
        b.box((xm, WALL_H / 2, z0 + depth / 2), (w, WALL_H, depth), "PaintGrey")
        b.box((xm, 0.15, z0 - 0.02), (w - 0.06, 0.30, 0.04), "PaintNavy")
        b.box((xm, 0.15, z0 + depth + 0.02), (w - 0.06, 0.30, 0.04), "PaintNavy")
    b.box((cx, (oh + WALL_H) / 2, z0 + depth / 2), (ow, WALL_H - oh, depth), "PaintGrey")
    if lod == 0:
        for x in (-1.3, 0.5, 0.9, 1.3):
            for zz in (z0 - 0.015, z0 + depth + 0.015):
                b.box((x, 1.45, zz), (0.06, 2.2, 0.03), "PaintGrey")
    n_arc = 6 if lod == 0 else 2
    inner2 = arch(ow, oh, 0.18, n_arc)
    outer2 = arch(ow + 0.20, oh + 0.10, 0.28, n_arc)
    inner = [(cx + x, y, z0 - 0.03) for x, y in inner2]
    outer = [(cx + x, y, z0 - 0.03) for x, y in outer2]
    b.ring_prism(inner, outer, (0, 0, depth + 0.06), "PaintGrey", (0, 0, -1), closed=False, centre=(cx, oh / 2, z0 + depth / 2))
    b.box((cx, 0.01, z0 + depth / 2), (ow, 0.02, depth), "PaintDark")
    handle(b, (-1.3, 1.25, z0), 0.45, lod)
    handle(b, (-1.3, 1.25, z0 + depth), 0.45, lod, direction=(0, 0, 1))
    return [("DoorJambA_Col-convcolonly", (-1.3, WALL_H / 2, z0 + depth / 2), (0.4, WALL_H, depth)),
            ("DoorJambB_Col-convcolonly", (0.8, WALL_H / 2, z0 + depth / 2), (1.4, WALL_H, depth)),
            ("DoorLintel_Col-convcolonly", (cx, (oh + WALL_H) / 2, z0 + depth / 2), (ow, WALL_H - oh, depth))]


def door_leaf(b, lod):
    """The sliding leaf around its own pivot (base centre of the closed leaf at the module's mid-depth)."""
    w, h, t = 1.30, 2.20, 0.08
    yc = h / 2 + 0.03
    b.box((0, yc, 0), (w, h, t), "PaintGrey")
    n_arc = 6 if lod == 0 else 2
    for face in (-1, 1):
        dz = face * t / 2
        inner, outer = rounded_rect(w - 0.30, h - 0.36, 0.12, n_arc), rounded_rect(w - 0.10, h - 0.16, 0.18, n_arc)
        b.ring_prism([(x, y + yc, dz) for x, y in inner], [(x, y + yc, dz) for x, y in outer], (0, 0, face * 0.02), "PaintGrey", (0, 0, face), centre=(0, yc, dz))
        handle(b, (-0.45, 1.15, dz + face * 0.02), 0.40, lod, direction=(0, 0, face))
    return [("DoorLeaf_Col-convcolonly", (0, yc, 0), (w, h, t + 0.04))]


HATCH_R, HATCH_CY, COLLAR = 0.60, 1.20, 0.08


def piece_hatch(b, lod):
    """2 m bulkhead with a 1.2 m round pressure hatch centred 1.2 m up, collar and rivets on the room side."""
    r, cy, collar = HATCH_R, HATCH_CY, COLLAR
    segs = 32 if lod == 0 else 16
    inner, outer = hole_loops(r, (-1.0, 1.0, 0.0, WALL_H), 0, cy, segs)
    b.ring_prism(loop_to_wall(inner, 0), loop_to_wall(outer, 0), (0, 0, WALL_D), "PaintGrey", (0, 0, -1), centre=(0, cy, 0), smooth_inner=True)
    circle = lambda rad, z: [(rad * math.cos(a), cy + rad * math.sin(a), z) for a in (2 * math.pi * i / segs for i in range(segs))]
    b.ring_prism(circle(r - 0.012, -collar), circle(r + 0.12, -collar), (0, 0, WALL_D + 2 * collar), "PaintGrey", (0, 0, -1), centre=(0, cy, 0), smooth_inner=True)
    b.ring_prism(circle(r + 0.01, -collar - 0.004), circle(r + 0.05, -collar - 0.004), (0, 0, 0.004), "PaintNavy", (0, 0, -1), centre=(0, cy, 0))
    if lod == 0:
        for k in range(24):
            a = 2 * math.pi * (k + 0.5) / 24
            p = Vector(((r + 0.095) * math.cos(a), cy + (r + 0.095) * math.sin(a), -collar))
            b.cylinder(p, p + Vector((0, 0, -0.007)), 0.011, "Steel", segs=8)
    for x in (-0.9, 0.9):
        b.box((x, WALL_H / 2, -0.015), (0.06, WALL_H - 0.1, 0.03), "PaintGrey")
    b.box((0, 0.15, -0.02), (1.7, 0.30, 0.04), "PaintNavy")
    b.box((0, WALL_H - 0.03, -0.015), (1.7, 0.06, 0.03), "PaintGrey")
    hx, hz = -(r + 0.12), -collar - 0.04
    for yy in (cy - 0.35, cy + 0.35):
        b.cylinder((hx, yy - 0.06, hz), (hx, yy + 0.06, hz), 0.03, "Steel", segs=12 if lod == 0 else 6)
        b.box((hx + 0.05, yy, hz + 0.02), (0.10, 0.10, 0.04), "PaintGrey")

    def collision(cb):
        ci, co = hole_loops(r, (-1.0, 1.0, 0.0, WALL_H), 0, cy, 16)
        cb.ring_prism(loop_to_wall(ci, 0), loop_to_wall(co, 0), (0, 0, WALL_D), "PaintGrey", (0, 0, -1), centre=(0, cy, 0))
    return [("HatchBulkhead_Col-colonly", collision)]


def hatch_leaf(b, lod):
    """Round leaf around its hinge pivot: the leaf centre is +0.72 m along X from the pivot, in front of the seal."""
    r = 0.655
    c = Vector((0.72, 0, -0.01))
    segs = 32 if lod == 0 else 16
    b.cylinder(c + Vector((0, 0, 0.04)), c + Vector((0, 0, -0.04)), r, "PaintGrey", segs=segs)
    b.cylinder(c + Vector((0, 0, -0.04)), c + Vector((0, 0, -0.07)), r * 0.86, "PaintGrey", segs=segs, radius1=r * 0.78)
    b.torus(c + Vector((0, 0, -0.042)), (0, 0, 1), r * 0.92, 0.012, "PaintNavy", segs=segs, rings=6)
    wheel_c = c + Vector((0, 0, -0.14))
    b.torus(wheel_c, (0, 0, 1), 0.17, 0.017, "Steel", segs=segs, rings=8)
    b.cylinder(c + Vector((0, 0, -0.07)), c + Vector((0, 0, -0.17)), 0.035, "Steel", segs=12 if lod == 0 else 6)
    for k in range(3):
        a = 2 * math.pi * k / 3 + math.pi / 2
        b.cylinder(wheel_c, wheel_c + Vector((0.17 * math.cos(a), 0.17 * math.sin(a), 0)), 0.011, "Steel", segs=8 if lod == 0 else 6)
    for sx in (-1, 1):
        handle(b, c + Vector((sx * 0.40, 0.02, -0.07)), 0.26, lod, stand=0.06)
    b.cylinder(c + Vector((0, 0.42, -0.04)), c + Vector((0, 0.42, -0.085)), 0.06, "PaintNavy", segs=16 if lod == 0 else 8)
    b.cylinder(c + Vector((0, 0.42, -0.085)), c + Vector((0, 0.42, -0.086)), 0.045, "Glass", segs=16 if lod == 0 else 8)
    if lod == 0:
        for k in range(4):
            a = math.pi / 4 + k * math.pi / 2
            b.cylinder(c + Vector((0.24 * math.cos(a), 0.24 * math.sin(a), -0.082)), c + Vector((0.50 * math.cos(a), 0.50 * math.sin(a), -0.082)), 0.014, "PaintGrey", segs=8)
    return [("HatchLeaf_Col-convcolonly", c + Vector((0, 0, -0.02)), (2 * r, 2 * r, 0.14))]


def piece_floor_tile(b, lod):
    t = 0.06
    b.box((0, (t - 0.004) / 2, 0), (1.0, t - 0.004, 1.0), "PaintNavy")
    b.box((0, t - 0.004, 0), (0.94, 0.008, 0.94), "Floor", skip=((0, -1, 0),))
    for sx in (-1, 1):
        for sz in (-1, 1):
            c = Vector((sx * 0.36, t, sz * 0.36))
            b.cylinder(c + Vector((0, -0.005, 0)), c + Vector((0, 0.002, 0)), 0.065, "PaintNavy", segs=16 if lod == 0 else 8)
            b.torus(c + Vector((0, 0.006, 0)), (0, 1, 0), 0.040, 0.007, "Steel", segs=16 if lod == 0 else 8, rings=6 if lod == 0 else 4)
    return [("FloorTile_Col-convcolonly", (0, t / 2, 0), (1.0, t, 1.0))]


def piece_ceiling_tile(b, lod):
    t, rail = 0.06, 0.03
    b.box((0, t / 2, 0), (1.0, t, 1.0), "PaintGrey", skip=((0, -1, 0),))
    for sx in (-1, 1):
        b.box((sx * (0.5 - rail / 2), 0.004, 0), (rail, 0.008, 1.0), "PaintGrey")
        b.box((0, 0.004, sx * (0.5 - rail / 2)), (1.0 - 2 * rail, 0.008, rail), "PaintGrey")
    b.quilt((-0.47, 0.03, 0.47), (1, 0, 0), (0, 0, -1), (0, -1, 0), 0.94, 0.94, 4, 4, 5 if lod == 0 else 2, 0.022 if lod == 0 else 0.0)
    vc = Vector((0.25, 0.03, -0.22))
    segs = 24 if lod == 0 else 10
    b.cylinder(vc + Vector((0, 0.03, 0)), vc + Vector((0, -0.02, 0)), 0.11, "PaintGrey", segs=segs, caps=False)
    b.torus(vc + Vector((0, -0.02, 0)), (0, 1, 0), 0.11, 0.01, "PaintGrey", segs=segs, rings=6)
    b.cylinder(vc + Vector((0, 0.031, 0)), vc + Vector((0, 0.03, 0)), 0.11, "PaintDark", segs=segs)
    if lod == 0:
        for k in range(-3, 4):
            b.box(vc + Vector((0, 0.01, k * 0.028)), (0.21 if abs(k) < 3 else 0.12, 0.004, 0.012), "PaintGrey")
    sc = Vector((-0.28, 0.03, 0.25))
    b.cylinder(sc, sc + Vector((0, -0.028, 0)), 0.035, "PaintDark", segs=16 if lod == 0 else 8, radius1=0.02)
    return [("CeilingTile_Col-convcolonly", (0, t / 2, 0), (1.0, t, 1.0))]


def piece_pipe_run(b, lod):
    segs = 16 if lod == 0 else 8
    for z, y, rad, key in ((0.11, 0.16, 0.04, "PaintBlue"), (0.00, 0.16, 0.04, "PaintBlue"), (-0.14, 0.17, 0.085, "PaintWhite")):
        b.cylinder((-0.5, y, z), (0.5, y, z), rad, key, segs=segs)
        if key == "PaintBlue":
            b.cylinder((-0.5, y, z), (-0.47, y, z), rad + 0.03, "Steel", segs=segs)
            b.cylinder((0.47, y, z), (0.5, y, z), rad + 0.03, "Steel", segs=segs)
            if lod == 0:
                for k in range(6):
                    a = 2 * math.pi * k / 6
                    p = Vector((-0.47, y + (rad + 0.018) * math.cos(a), z + (rad + 0.018) * math.sin(a)))
                    b.cylinder(p, p + Vector((-0.012, 0, 0)), 0.006, "Steel", segs=6)
        else:
            b.cylinder((-0.08, y, z), (0.08, y, z), rad + 0.012, "PaintGrey", segs=segs)
    for x in (-0.35, 0.35):
        b.box((x, 0.02, -0.02), (0.06, 0.04, 0.34), "PaintGrey")
        b.box((x, 0.10, 0.055), (0.05, 0.16, 0.02), "PaintGrey")
        b.box((x, 0.10, -0.245), (0.05, 0.16, 0.02), "PaintGrey")
    return [("PipeRun_Col-convcolonly", (0, 0.13, -0.03), (1.0, 0.26, 0.40))]


def piece_cable_run(b, lod):
    w, h = 0.25, 0.10
    b.box((0, h / 2, 0), (1.0, h, w), "PaintNavy", skip=((0, 1, 0),))
    b.box((-0.375, h - 0.004, 0), (0.25, 0.008, w), "PaintNavy")
    b.box((0.375, h - 0.004, 0), (0.25, 0.008, w), "PaintNavy")
    b.box((0, h - 0.004, w / 2 - 0.03), (0.5, 0.008, 0.06), "PaintNavy")
    b.box((0, h - 0.004, -(w / 2 - 0.03)), (0.5, 0.008, 0.06), "PaintNavy")
    segs = 8 if lod == 0 else 6
    for k, key in enumerate(("PaintOrange", "PaintBlue", "PaintWhite", "PaintDark", "PaintOrange")):
        z, yy = -0.06 + k * 0.03, 0.05 + (k % 2) * 0.02
        b.cylinder((-0.5, yy, z), (0.5, yy, z), 0.011, key, segs=segs, caps=False)
    b.box((0, h - 0.0045, 0), (0.5, 0.001, 0.13), "Glass")
    b.box((0, h + 0.01, 0), (0.06, 0.02, w + 0.02), "PaintOrange")
    b.box((0, h / 2 + 0.01, w / 2 + 0.008), (0.06, h, 0.016), "PaintOrange")
    for x in (-0.49, 0.49):
        b.box((x, h / 2 + 0.01, 0), (0.02, h + 0.02, w + 0.02), "PaintGrey")
    return [("CableRun_Col-convcolonly", (0, h / 2 + 0.01, 0), (1.0, h + 0.02, w + 0.02))]


def piece_light_strip(b, lod):
    w, h = 0.10, 0.08
    b.box((0, 0.012 + (h - 0.012) / 2, 0), (1.0, h - 0.012, w), "Steel", skip=((0, -1, 0),))
    b.box((0, 0.006, 0), (0.96, 0.012, w - 0.02), "Diffuser")
    for sz in (-1, 1):
        b.box((0, 0.006, sz * (w / 2 - 0.005)), (1.0, 0.012, 0.01), "Steel")
    for sx in (-1, 1):
        b.box((sx * 0.49, 0.006, 0), (0.02, 0.012, w - 0.02), "Steel")
    for x in (-0.3, 0.3):
        b.box((x, h + 0.006, 0), (0.04, 0.012, w + 0.04), "Steel")
    return [("LightStrip_Col-convcolonly", (0, h / 2, 0), (1.0, h, w))]


def piece_bulkhead_ring(b, lod):
    """Octagonal corridor bulkhead: 2.6 m across the flats, 0.14 m frame bars, 0.30 m along the corridor."""
    cy, bar = 1.3, 0.14
    b.ring_prism(octagon(1.3 - bar, cy, -0.15), octagon(1.3, cy, -0.15), (0, 0, 0.30), "PaintGrey", (0, 0, -1), centre=(0, cy, 0))
    for z, dz in ((-0.152, -0.012), (0.152, 0.012)):
        b.ring_prism(octagon(1.3 - 0.06, cy, z), octagon(1.3, cy, z), (0, 0, dz), "PaintOrange", (0, 0, -1 if dz < 0 else 1), centre=(0, cy, z))
    inner = octagon(1.3 - bar, cy)
    sub = 4 if lod == 0 else 2
    for k in range(8):
        p0, p1 = Vector((*inner[k], 0.13)), Vector((*inner[(k + 1) % 8], 0.13))
        ea = (p1 - p0).normalized()
        a_mid = math.pi / 8 + (k + 0.5) * math.pi / 4
        inward = Vector((-math.cos(a_mid), -math.sin(a_mid), 0))
        side = (p1 - p0).length
        if k == 5:  # bottom flat: steel-grey tread on the sill instead of quilt
            b.box(((p0.x + p1.x) / 2, bar + 0.006, 0), (side - 0.02, 0.012, 0.26), "PaintDark")
            continue
        b.quilt(p0 + ea * 0.02 + inward * 0.01, ea, (0, 0, -1), inward, side - 0.04, 0.26, 4, 1, sub, 0.018 if lod == 0 else 0.0)
    segs = 12 if lod == 0 else 6
    for sx in (-1, 1):
        x = sx * (1.3 - bar - 0.01)
        b.cylinder((x - sx * 0.06, 0.95, 0), (x - sx * 0.06, 1.65, 0), 0.016, "Steel", segs=segs)
        for yy in (0.95, 1.65):
            b.cylinder((x, yy, 0), (x - sx * 0.06, yy, 0), 0.012, "Steel", segs=segs)
    if lod == 0:
        for k in range(32):
            a = 2 * math.pi * (k + 0.5) / 32
            delta = abs(((a + math.pi / 8) % (math.pi / 4)) - math.pi / 8)
            rr = (1.3 - bar / 2) / math.cos(delta)
            p = Vector((rr * math.cos(a), cy + rr * math.sin(a), -0.15))
            b.cylinder(p, p + Vector((0, 0, -0.007)), 0.011, "Steel", segs=8)

    def collision(cb):
        cb.ring_prism(octagon(1.3 - bar, cy, -0.15), octagon(1.3, cy, -0.15), (0, 0, 0.30), "PaintGrey", (0, 0, -1), centre=(0, cy, 0))
    return [("BulkheadRing_Col-colonly", collision)]


PIECES = [
    dict(id="EN_Kit_Wall_Straight", build=piece_wall_straight, flag="--height", size=WALL_H, footprint=(1.0, WALL_D), mount_y=0.0,
         display="Straight wall panel", notes="1 x 2.6 m quilted panel, handrail at 1.0 m, navy skirting; face on z=0 facing -Z"),
    dict(id="EN_Kit_Wall_Corner", build=piece_wall_corner, flag="--height", size=WALL_H, footprint=(0.65, 0.65), mount_y=0.0,
         display="Inside corner", notes="two 0.5 m legs at 90 deg; pivot at the inside corner; the room lies towards -X and -Z"),
    dict(id="EN_Kit_Wall_Window", build=piece_wall_window, flag="--height", size=WALL_H, footprint=(1.0, WALL_D), mount_y=0.0,
         display="Window wall panel", notes="0.56 x 0.42 m pressure window at 1.55 m, navy frame, glass material M_Kit_Glass"),
    dict(id="EN_Kit_DoorFrame", build=piece_door_frame, flag="--height", size=WALL_H, footprint=(3.0, 0.30), mount_y=0.0,
         display="Sliding pressure door", notes="3 m two-sided module, 1.2 x 2.1 m opening centred at x=-0.5; child DoorLeaf slides +X by 1.25 m"),
    dict(id="EN_Kit_Hatch", build=piece_hatch, flag="--height", size=WALL_H, footprint=(2.0, WALL_D), mount_y=0.0,
         display="Round pressure hatch", notes="2 m bulkhead, 1.2 m hatch centred 1.2 m up (sill 0.6 m); child HatchLeaf hinged at the left collar"),
    dict(id="EN_Kit_Wall_EquipBay", build=piece_wall_equipbay, flag="--height", size=WALL_H, footprint=(1.0, WALL_D), mount_y=0.0,
         display="Equipment bay panel", notes="recessed navy console 0.7 x 0.9 m from 1.0 m up; 'Screen' material slot 0.5 x 0.3 m for a live UI"),
    dict(id="EN_Kit_FloorTile", build=piece_floor_tile, flag="--longest", size=1.0, footprint=(1.0, 1.0), mount_y=-0.06,
         display="Floor tile", notes="1 x 1 m anti-slip deck 0.06 m thick with four tie-down rings; mount at y=-0.06 so the deck is y=0"),
    dict(id="EN_Kit_CeilingTile", build=piece_ceiling_tile, flag="--longest", size=1.0, footprint=(1.0, 1.0), mount_y=WALL_H,
         display="Ceiling tile", notes="1 x 1 m quilted tile with vent grille and sensor; the visible face is the base, mount at y=2.6"),
    dict(id="EN_Kit_PipeRun", build=piece_pipe_run, flag="--longest", size=1.0, footprint=(1.0, 0.40), mount_y=0.0,
         display="Pipe run", notes="two coolant pipes and an air duct on brackets, 1 m along X; rotate to mount on a wall or ceiling"),
    dict(id="EN_Kit_CableRun", build=piece_cable_run, flag="--longest", size=1.0, footprint=(1.0, 0.27), mount_y=0.0,
         display="Cable tray", notes="1 m navy tray with an inspection window and orange latch, along X"),
    dict(id="EN_Kit_LightStrip", build=piece_light_strip, flag="--longest", size=1.0, footprint=(1.0, 0.14), mount_y=WALL_H - 0.08,
         display="Light strip", notes="1 m luminaire along X; the emissive diffuser is the base face; mount at y=2.52 under a ceiling"),
    dict(id="EN_Kit_BulkheadRing", build=piece_bulkhead_ring, flag="--height", size=WALL_H, footprint=(2.6, 0.30), mount_y=-0.14,
         display="Corridor bulkhead ring", notes="octagon 2.6 m across the flats, 0.3 m deep along Z; inner sill 0.14 m above the base (mount at y=-0.14)"),
]


# ----------------------------------------------------------------------------------------------- assembly

def make_empty(name, location=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    obj.location = location
    obj.parent = parent
    bpy.context.scene.collection.objects.link(obj)
    return obj


def collision_objects(specs, parent, table):
    """Collision nodes for Godot: boxes become -convcolonly; a callable builds a custom -colonly trimesh."""
    out = []
    for spec in specs:
        b = Builder(table)
        if callable(spec[1]):
            spec[1](b)
        else:
            b.box(spec[1], spec[2], "PaintGrey")
        obj = b.to_object(spec[0])
        obj.data.materials.clear()
        obj.parent = parent.parent
        obj.display_type = "WIRE"
        out.append(obj)
    return out


def visual(objs):
    return [o for o in objs if o.type == "MESH" and not o.name.endswith(COL_SUFFIXES)]


def triangles(objs):
    return sum(len(p.vertices) - 2 for o in visual(objs) for p in o.data.polygons)


def bounds(objs):
    pts = [o.matrix_world @ Vector(c) for o in visual(objs) for c in o.bound_box]
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])


def build_piece(spec, lod, table):
    """Returns (root, objects) for one piece at one LOD, authored in Godot's frame."""
    root = make_empty(spec["id"] + f"_LOD{lod}")
    b = Builder(table)
    cols = spec["build"](b, lod)
    body = b.to_object(spec["id"] + f"_Mesh_LOD{lod}")
    body.parent = root
    objs = [body] + (collision_objects(cols, body, table) if lod == 0 else [])
    for leaf_name, pivot, fn in (("DoorLeaf", (DOOR_CX, 0, DOOR_Z0 + DOOR_DEPTH / 2), door_leaf), ("HatchLeaf", (-(HATCH_R + 0.12), HATCH_CY, -COLLAR - 0.04), hatch_leaf)):
        if (leaf_name == "DoorLeaf") != (spec["id"] == "EN_Kit_DoorFrame") or (leaf_name == "HatchLeaf") != (spec["id"] == "EN_Kit_Hatch"):
            continue
        taken = bpy.data.objects.get(leaf_name)
        if taken is not None:  # the other LOD's leaf keeps its exported name only until this one is exported
            taken.name = leaf_name + "_prev"
        leaf = make_empty(leaf_name, pivot, root)
        lb = Builder(table)
        lcols = fn(lb, lod)
        lmesh = lb.to_object(leaf_name + f"_Mesh_LOD{lod}")
        lmesh.parent = leaf
        objs += [leaf, lmesh] + (collision_objects(lcols, lmesh, table) if lod == 0 else [])
    return root, objs


def bake_blender_space(objs):
    """Pieces are authored Y-up; rotate mesh data and pivots so Blender holds them Z-up and exports Y-up again."""
    for o in objs:
        if o.type == "MESH":
            o.data.transform(GODOT_TO_BLENDER)
            o.data.update()
        o.location = GODOT_TO_BLENDER @ o.location


def export_glb(root, objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_animations=False, export_cameras=False, export_lights=False,
                              export_extras=False, export_image_format="AUTO", export_texcoords=True, export_normals=True)


def set_visible(objs, visible):
    for o in objs:
        o.hide_render = not visible
        o.hide_viewport = not visible


# ----------------------------------------------------------------------------------------------- previews

def setup_render():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    try:
        if CPU_RENDER:
            raise RuntimeError("--cpu requested")
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "METAL"
        prefs.get_devices()
        for device in prefs.devices:
            device.use = True
        scene.cycles.device = "GPU"
    except Exception as error:  # CPU fallback
        print("cycles GPU unavailable:", error)
    scene.cycles.samples = 96
    scene.cycles.use_denoising = True
    scene.render.resolution_x = scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Base Contrast"
    bg = scene.world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.50, 0.51, 0.53, 1)
    bg.inputs["Strength"].default_value = 0.55
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    camera.data.clip_end = 200
    scene.camera = camera
    bpy.ops.object.light_add(type="SUN", location=(3, 5, 8))
    sun = bpy.context.object
    sun.data.energy = 2.2
    sun.data.angle = math.radians(4)
    sun.rotation_euler = (Vector((0, 0, 0)) - sun.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.light_add(type="AREA", location=(-4, 5, 4))
    fill = bpy.context.object
    fill.data.energy = 250
    fill.data.size = 5
    fill.rotation_euler = (Vector((0, 0, 1.2)) - fill.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, -0.002))
    floor = bpy.context.object
    floor.name = "PreviewFloor"
    mat = bpy.data.materials.new("PreviewFloor")
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.42, 0.43, 0.45, 1)
    mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    floor.data.materials.append(mat)
    return camera, [camera, sun, fill, floor]


def render_piece(camera, objs, path, direction=(0.7, 1.0, 0.55), pad=1.25):
    bpy.context.view_layer.update()
    lo, hi = bounds(objs)
    centre = (lo + hi) / 2
    extent = max(hi - lo)
    camera.location = centre + Vector(direction).normalized() * (extent * 4 + 3)
    camera.rotation_euler = (centre - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.ortho_scale = extent * pad
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def render_previews(built):
    camera, rig = setup_render()
    set_visible(bpy.context.scene.objects, False)
    set_visible(rig, True)
    for spec in PIECES:
        if ONLY and spec["id"] not in ONLY:
            continue
        for lod in (0, 1):
            root, objs = built[(spec["id"], lod)]
            hanging = spec["id"] in ("EN_Kit_CeilingTile", "EN_Kit_LightStrip")
            if hanging:  # show the visible face: flip the piece over for the picture only
                root.rotation_euler = (0, math.radians(180), 0)
                root.location.z = 0.08 if spec["id"] == "EN_Kit_LightStrip" else 0.06
            set_visible([root] + objs, True)
            set_visible([o for o in objs if o.name.endswith(COL_SUFFIXES)], False)
            direction = (-0.7, 1.0, 0.55) if spec["id"] == "EN_Kit_Wall_Corner" else (0.7, 1.0, 0.55)
            render_piece(camera, objs, STAGE / "preview" / f"{spec['id']}_LOD{lod}.png", direction)
            if lod == 0 and spec["id"] in ("EN_Kit_DoorFrame", "EN_Kit_Hatch"):
                leaf = next(o for o in objs if o.type == "EMPTY" and o.name.startswith(("DoorLeaf", "HatchLeaf")))
                if leaf.name == "DoorLeaf":
                    leaf.location.x += 1.25
                else:
                    leaf.rotation_euler = (0, 0, math.radians(100))  # Blender Z = Godot Y
                render_piece(camera, objs, STAGE / "preview" / f"{spec['id']}_LOD0_open.png", direction)
                if leaf.name == "DoorLeaf":
                    leaf.location.x -= 1.25
                else:
                    leaf.rotation_euler = (0, 0, 0)
            if hanging:
                root.rotation_euler = (0, 0, 0)
                root.location.z = 0
            set_visible([root] + objs, False)


# ----------------------------------------------------------------------------------------------- main

def write_material_resources(images):
    materials = []
    for key in MATERIAL_KEYS:
        shared = "Paint" if key.startswith("Paint") else key
        tile = images[0][key]["tile"]
        tres = OUT / "materials" / f"M_Kit_{key}.tres"
        tres.write_text(
            '[gd_resource type="StandardMaterial3D" load_steps=4 format=3]\n\n'
            f'[ext_resource type="Texture2D" path="res://assets/environment/kit/textures/T_Kit_{key}_BaseColor.png" id="1"]\n'
            f'[ext_resource type="Texture2D" path="res://assets/environment/kit/textures/T_Kit_{shared}_Normal.png" id="2"]\n'
            f'[ext_resource type="Texture2D" path="res://assets/environment/kit/textures/T_Kit_{shared}_ORM.png" id="3"]\n\n'
            '[resource]\n'
            'albedo_texture = ExtResource("1")\n'
            f'metallic = {1.0 if key == "Steel" else 0.0}\n'
            'metallic_texture = ExtResource("3")\n'
            'metallic_texture_channel = 2\n'
            'roughness_texture = ExtResource("3")\n'
            'roughness_texture_channel = 1\n'
            'normal_enabled = true\n'
            'normal_texture = ExtResource("2")\n'
            'ao_enabled = true\n'
            'ao_texture = ExtResource("3")\n'
            'ao_texture_channel = 0\n'
            f'uv1_scale = Vector3({1 / tile}, {1 / tile}, 1)\n', encoding="utf-8")
        materials.append(dict(id=f"M_Kit_{key}", path=f"res://assets/environment/kit/materials/M_Kit_{key}.tres", tile_m=tile))
    return materials


def main():
    for sub in ("textures", "materials"):
        (OUT / sub).mkdir(parents=True, exist_ok=True)
    (STAGE / "preview").mkdir(parents=True, exist_ok=True)
    if not ONLY:
        for old in list(OUT.glob("*.glb")) + list((OUT / "textures").glob("*.png")) + list((OUT / "materials").glob("*.tres")):
            old.unlink()
    images = make_textures()
    mats = make_materials(images)
    rows, catalogue, built = [], [], {}
    for spec in PIECES:
        entry = dict(id=spec["id"], display=spec["display"], notes=spec["notes"], footprint_m=list(spec["footprint"]),
                     mount_y=spec["mount_y"], lods=[], triangles=[], lod_distance_m=LOD_DISTANCE_M, collision=True)
        for lod in (0, 1):
            root, objs = build_piece(spec, lod, mats[lod])
            bpy.context.view_layer.update()
            lo, hi = bounds(objs)
            tris = triangles(objs)
            assert abs(lo.y) < 0.005, f"{spec['id']} LOD{lod} lowest point {lo.y:.4f} is not on the floor"
            measured = (hi.y - lo.y) if spec["flag"] == "--height" else max(hi - lo)
            assert abs(measured - spec["size"]) <= 0.02 * spec["size"], f"{spec['id']} LOD{lod} measures {measured:.3f}, spec {spec['size']}"
            assert tris <= 8000, f"{spec['id']} LOD{lod} has {tris} triangles, over the art bible's 8k"
            name = spec["id"] + f"_LOD{lod}"
            path = OUT / (name + ".glb")
            bake_blender_space(objs)
            bpy.context.view_layer.update()
            if not ONLY:
                export_glb(root, objs, path)
            rows.append(dict(name=name, concept_or_source=SOURCE, size_flag=spec["flag"], size_m=spec["size"], tris=tris,
                             tex=1024 if lod == 0 else 512, game_path=path.relative_to(ROOT).as_posix(), art_status="approved_sheet_m1-04",
                             notes=f"{TASK} {spec['display']}; " + ("game LOD with collision" if lod == 0 else "Compatibility LOD, no collision")))
            entry["lods"].append("res://assets/environment/kit/" + name + ".glb")
            entry["triangles"].append(tris)
            if lod == 0:
                entry["size_m"] = [round(v, 3) for v in (hi - lo)]
                entry["bounds_min_m"] = [round(v, 3) for v in lo]
            built[(spec["id"], lod)] = (root, objs)
            print(f"KIT {name}: {tris} tris, size {[round(v, 3) for v in (hi - lo)]}, {path.stat().st_size // 1024} KB")
        if spec["id"] == "EN_Kit_DoorFrame":
            entry["sockets"] = dict(opening_centre=[DOOR_CX, 0, 0], opening_size=[DOOR_W, DOOR_H], leaf_node="DoorLeaf", leaf_travel_m=1.25, leaf_axis="+X")
        if spec["id"] == "EN_Kit_Hatch":
            entry["sockets"] = dict(opening_centre=[0, HATCH_CY, 0], opening_diameter=2 * (HATCH_R - 0.012), leaf_node="HatchLeaf",
                                    hinge=[-(HATCH_R + 0.12), HATCH_CY, -COLLAR - 0.04], open_rotation_deg_y=100)
        if spec["id"] == "EN_Kit_Wall_EquipBay":
            entry["sockets"] = dict(screen_material="Screen", screen_centre=[0, 1.65, 0.043], screen_size=[0.5, 0.3])
        catalogue.append(entry)
    if ONLY:
        render_previews(built)
        print(f"HABITAT_KIT_PREVIEWS_PASS: {ONLY}")
        return
    with (ROOT / "production/manifest/habitat_kit.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    materials = write_material_resources(images)
    (OUT / "kit.json").write_text(json.dumps(dict(
        task=TASK, seed=SEED, approved_sheets=["production/concept/environment_v1/01_HabitatKit_sheet_A.png", "production/concept/environment_v1/01_HabitatKit_sheet_B.png"],
        conventions=dict(units="metres", up="+Y", front="-Z (Godot forward); wall faces lie on z=0 and face -Z, bodies extend to +z",
                         pivot="base centre; the corner at its inside vertex; door and hatch leaves on their own child pivots",
                         grid_m=1.0, wall_height_m=WALL_H, wall_depth_m=WALL_D, door_opening_m=[DOOR_W, DOOR_H], hatch_clear_m=round(2 * (HATCH_R - 0.012), 3),
                         lod_distance_m=LOD_DISTANCE_M, textures="tileable PBR sets embedded in each GLB; 1024 px at LOD0, 512 px at LOD1"),
        pieces=catalogue, materials=materials), indent=1), encoding="utf-8")
    if RENDER:
        render_previews(built)
    print(f"HABITAT_KIT_BUILD_PASS: {len(PIECES)} pieces, {len(rows)} GLBs, {len(materials)} materials")


if __name__ == "__main__":
    main()
