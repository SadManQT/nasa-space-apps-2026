"""Godot-ready terrain tiles from the LOLA heightmaps (board M1-34). Runs inside Blender 5.2:

  python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup \
      --python production/tools/build_terrain_tiles.py -- [--region aurora_ridge] [--no-ao] [--ao-size 1024]

For every region in game/assets/environment/terrain/lola/ it
  1. reads heightmap_<mpp>m.r16 + .json (LOLA data, untouched),
  2. for hero regions adds the authored detail layer: small craters below the LOLA grid's effective
     resolution (at most 60 m across), placed by a seeded equilibrium size-frequency law (Trask 1966
     / Gault 1970: N(>D) = 10^-1.1 D_km^-1.83 per km2), written as heightmap_<mpp>m_detail.r16
     (+ .json) so the collision heightfield matches what the player sees; no invented mountains, no
     boulders (boulders come from the runtime scatter in lunar_scatter.gd with the M1-35 kit),
  3. writes T_Terrain_<Region>_Normal.png, an OBJECT-SPACE normal map in the region's Godot frame
     (R = X, G = Y up, B = Z; curvature included) that terrain_lola.gdshader reads on UV1, so every
     LOD shades the same and the macro slope is never applied twice, and bakes
     T_Terrain_<Region>_AO.png with Cycles (it only darkens the faint Earthshine/bounce fill; the
     Sun is a single hard light with no sky light, Art Bible section 2),
  4. builds 2 km tiles with LOD0..LOD3 meshes (hero) or one mesh with three LODs (vista, corridor),
     with skirts against cracks, UV1 = region 0..1 (v = 0 at the region's north edge, as Godot
     reads it after the glTF V flip) and UV2 = metres / 4 for the regolith detail textures,
  5. bends every mesh with the Moon's curvature, Y = height - site height - (X^2 + Z^2) / (2 R), so
     a Sun or Earth a degree below the site's horizontal lights and hides the far terrain as on the
     real Moon (JPL Horizons elevations are relative to that horizontal; the Sun is one parallel
     direction in this frame). Over the 170 km relay corridor the surface falls 5.6 km below the
     site's horizontal; each playable road segment later gets its own local frame (M1-36),
  6. exports each LOD as its own GLB (+Y up, metres, pivot at the tile centre, Y = 0 at the site's
     height) and writes tiles.json with positions, LOD ranges, triangle counts and texture notes.

Deterministic: the same inputs and seed give the same meshes.
"""
import argparse
import hashlib
import json
import math
import struct
import sys
import time
import zlib
from pathlib import Path

import bpy
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
LOLA = ROOT / "game" / "assets" / "environment" / "terrain" / "lola"
REGOLITH_GREY = (0.478, 0.463, 0.447, 1.0)  # #7A7672 Art Bible regolith grey
R_MOON = 1737400.0  # m, the LOLA reference sphere
DETAIL_CRATER_MAX_M = 60.0  # never add craters a LOLA grid could already resolve
TILE_M = 2000.0
# vertex spacing (m) per LOD for hero tiles; LOD0 only on the central 2x2 tiles
HERO_LODS = [10.0, 20.0, 40.0, 80.0]
CURVED_KINDS = ("hero", "vista", "corridor")
AO_SPACING_M = {"hero": 20.0, "vista": 100.0, "corridor": 200.0}  # bake mesh spacing per region kind
AO_DISTANCE_M = {"hero": 250.0, "vista": 1500.0, "corridor": 3000.0}  # occlusion search distance
HERO_LOD_RANGES_M = [0.0, 1500.0, 4000.0, 9000.0, 1.0e9]  # visibility range begin/end per LOD
VISTA_LODS = [200.0, 400.0, 800.0]
VISTA_LOD_RANGES_M = [0.0, 12000.0, 30000.0, 1.0e9]
SKIRT_M = 25.0


# ---------------------------------------------------------------- io

def read_json(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def write_json(p: Path, obj) -> None:
    p.write_text(json.dumps(obj, indent=1) + "\n", encoding="utf-8")


def load_r16(path: Path, meta: dict) -> np.ndarray:
    q = np.frombuffer(path.read_bytes(), dtype="<u2").reshape(meta["rows"], meta["columns"])
    return meta["z_min_m"] + q.astype(np.float64) * (meta["z_max_m"] - meta["z_min_m"]) / 65535.0


def save_r16(path: Path, h: np.ndarray) -> tuple[float, float]:
    zmin, zmax = float(h.min()), float(h.max())
    q = np.clip(np.round((h - zmin) / max(zmax - zmin, 1e-6) * 65535.0), 0, 65535).astype("<u2")
    path.write_bytes(q.tobytes())
    return zmin, zmax


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_png(path: Path, img: np.ndarray) -> None:
    """8-bit grey (H,W) or RGB (H,W,3), standard library only (Blender's image writer is slower)."""
    if img.ndim == 2:
        ctype, raw, stride = 0, img.astype(np.uint8).tobytes(), img.shape[1]
    else:
        ctype, raw, stride = 2, img.astype(np.uint8).tobytes(), img.shape[1] * 3
    rows = b"".join(b"\0" + raw[i * stride:(i + 1) * stride] for i in range(img.shape[0]))

    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", img.shape[1], img.shape[0], 8, ctype, 0, 0, 0)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(rows, 6)) + chunk(b"IEND", b""))


# ---------------------------------------------------------------- detail layer

def equilibrium_count(d_min_km: float, d_max_km: float, area_km2: float) -> int:
    """Craters with d_min <= D < d_max per Trask/Gault equilibrium: N(>D) = 10^-1.1 * D^-1.83 per km2."""
    n = 10 ** -1.1 * (d_min_km ** -1.83 - d_max_km ** -1.83)
    return int(round(n * area_km2))


def add_craters(h: np.ndarray, mpp: float, seed: int) -> dict:
    """Stamp sub-resolution craters (3 to 12 pixels across) with bowl floors and raised rims."""
    rows, cols = h.shape
    d_min, d_max = 3.0 * mpp, min(12.0 * mpp, DETAIL_CRATER_MAX_M)
    area_km2 = rows * cols * mpp * mpp / 1e6
    count = equilibrium_count(d_min / 1000, d_max / 1000, area_km2)
    rng = np.random.default_rng(seed)
    # sample diameters from the power law N(>D) ~ D^-1.83 (pdf ~ D^-2.83) by inverse transform
    u = rng.random(count)
    a = 1.83
    diam = (d_min ** -a - u * (d_min ** -a - d_max ** -a)) ** (-1 / a)
    cx = rng.random(count) * (cols - 1)
    cy = rng.random(count) * (rows - 1)
    depth_ratio = rng.uniform(0.04, 0.16, count)  # degraded equilibrium population, not fresh 0.2
    rim_ratio = rng.uniform(0.015, 0.04, count)
    out = h.copy()
    for i in range(count):
        R = diam[i] / 2.0 / mpp  # px
        reach = int(math.ceil(1.6 * R)) + 1
        c0, c1 = max(0, int(cx[i]) - reach), min(cols, int(cx[i]) + reach + 1)
        r0, r1 = max(0, int(cy[i]) - reach), min(rows, int(cy[i]) + reach + 1)
        if c1 <= c0 or r1 <= r0:
            continue
        yy, xx = np.mgrid[r0:r1, c0:c1]
        r = np.hypot(xx - cx[i], yy - cy[i]) / R  # in crater radii
        d = depth_ratio[i] * diam[i]
        rim = rim_ratio[i] * diam[i]
        bowl = -d * (1.0 - r * r) + rim * r * r  # parabola reaching +rim at r = 1
        ejecta = rim * np.clip(r, 1.0, None) ** -3.0  # rim decays outward
        fade = np.clip((1.6 - r) / 0.6, 0, 1) ** 0.5  # ejecta blends back into the LOLA surface by 1.6 R
        dz = np.where(r < 1.0, bowl, ejecta * fade)
        out[r0:r1, c0:c1] += dz
    return {"heights": out, "count": count, "diameter_min_m": d_min, "diameter_max_m": d_max, "seed": seed,
            "law": "Trask (1966) / Gault (1970) equilibrium, N(>D) = 10^-1.1 D_km^-1.83 per km2; depth/diameter 0.04-0.16, rim 0.015-0.04 D"}


def curvature_drop(xs: np.ndarray, zs: np.ndarray) -> np.ndarray:
    """Metres the Moon's sphere falls below the site's tangent plane at Godot (x, z): r^2 / (2 R)."""
    return (xs * xs + zs * zs) / (2.0 * R_MOON)


def godot_y(h: np.ndarray, meta: dict, xs: np.ndarray, zs: np.ndarray, curved: bool) -> np.ndarray:
    """Godot Y at site-frame (x, z): the heightfield minus the site's height, minus the curvature drop
    when the region is bent (every kind in CURVED_KINDS)."""
    y = sample_field(h, meta["metres_per_pixel"], xs, zs, meta["site"]["pixel_col"], meta["site"]["pixel_row"]) - meta["site"]["height_m"]
    return y - curvature_drop(xs, zs) if curved else y


def normal_map(h: np.ndarray, meta: dict, extent: tuple[float, float, float, float], size: int, curved: bool) -> np.ndarray:
    """Object-space normal map of a region in its Godot frame, size x size texels over
    extent = (x_min, x_max, z_min, z_max). Texel (row i, column j) sits at u = (j + 0.5) / size,
    v = (i + 0.5) / size, i.e. X = x_min + u (x_max - x_min), Z = z_min + v (z_max - z_min), which is
    where the tiles' UV1 points in Godot. RGB = (n.x, n.y, n.z) * 0.5 + 0.5 with Y up."""
    x_min, x_max, z_min, z_max = extent
    xs = x_min + (np.arange(size) + 0.5) / size * (x_max - x_min)
    zs = z_min + (np.arange(size) + 0.5) / size * (z_max - z_min)
    X, Z = np.meshgrid(xs, zs)
    Y = godot_y(h, meta, X, Z, curved)
    dydz, dydx = np.gradient(Y, zs[1] - zs[0], xs[1] - xs[0])
    n = np.dstack([-dydx, np.ones_like(dydx), -dydz])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return np.clip((n * 0.5 + 0.5) * 255 + 0.5, 0, 255).astype(np.uint8)


def ao_orientation_score(ao: np.ndarray, h: np.ndarray, meta: dict, extent: tuple[float, float, float, float], curved: bool) -> dict:
    """Correlation between the baked AO texels and terrain concavity (a 3-texel-wide Laplacian) at
    the same UVs, and the same for the AO flipped top-to-bottom. Bowls are darker than crests, so a
    correctly oriented bake correlates clearly better than its flip."""
    size = ao.shape[0]
    x_min, x_max, z_min, z_max = extent
    xs = x_min + (np.arange(size) + 0.5) / size * (x_max - x_min)
    zs = z_min + (np.arange(size) + 0.5) / size * (z_max - z_min)
    X, Z = np.meshgrid(xs, zs)
    Y = godot_y(h, meta, X, Z, curved)
    k = 3
    pad = np.pad(Y, k, mode="edge")
    lap = (pad[:-2 * k, k:-k] + pad[2 * k:, k:-k] + pad[k:-k, :-2 * k] + pad[k:-k, 2 * k:]) / 4.0 - Y  # > 0 in bowls
    a = ao.astype(np.float64)

    def corr(img):
        return float(np.corrcoef(img.ravel(), -lap.ravel())[0, 1])

    return {"corr_with_crests": round(corr(a), 3), "corr_if_flipped": round(corr(a[::-1, :]), 3)}


# ---------------------------------------------------------------- meshes

def sample_field(h: np.ndarray, mpp: float, xs: np.ndarray, zs: np.ndarray, site_col: float, site_row: float) -> np.ndarray:
    """Bilinear heights at Godot (x, z) metres relative to the site; outside -> edge clamp."""
    cols = xs / mpp + site_col
    rows = zs / mpp + site_row
    c0 = np.clip(np.floor(cols).astype(int), 0, h.shape[1] - 2)
    r0 = np.clip(np.floor(rows).astype(int), 0, h.shape[0] - 2)
    fc = np.clip(cols - c0, 0, 1)
    fr = np.clip(rows - r0, 0, 1)
    return (h[r0, c0] * (1 - fr) * (1 - fc) + h[r0 + 1, c0] * fr * (1 - fc) +
            h[r0, c0 + 1] * (1 - fr) * fc + h[r0 + 1, c0 + 1] * fr * fc)


def grid_mesh(name: str, h: np.ndarray, meta: dict, x0: float, z0: float, size_x: float, size_z: float, spacing: float,
              hole: tuple | None, skirt: float, region_size: tuple[float, float], region_origin: tuple[float, float], curved: bool):
    """Build a Blender mesh for the rectangle [x0, x0+size_x] x [z0, z0+size_z] (Godot metres, site at
    the origin), vertex spacing `spacing`, optional rectangular hole (x0,x1,z0,z1), with a skirt.
    Vertices are relative to the patch centre; heights relative to the site (see godot_y). Blender's
    glTF exporter writes v = 1 - v_blender, so v_blender is stored flipped and Godot reads
    UV1 v = (Z - z_min) / depth. Returns (object, triangle_count)."""
    nx, nz = int(round(size_x / spacing)), int(round(size_z / spacing))
    xs = x0 + np.arange(nx + 1) * spacing
    zs = z0 + np.arange(nz + 1) * spacing
    X, Z = np.meshgrid(xs, zs)
    Y = godot_y(h, meta, X, Z, curved)
    cx, cz = x0 + size_x / 2, z0 + size_z / 2
    verts = np.column_stack([(X - cx).ravel(), -(Z - cz).ravel(), Y.ravel()])  # Blender: x, y=-z_godot, z=y_godot
    rw, rh = region_size
    ox, oz = region_origin
    uv1 = np.column_stack([((X - ox) / rw).ravel(), 1.0 - ((Z - oz) / rh).ravel()])
    uv2 = np.column_stack([(X / 4.0).ravel(), -(Z / 4.0).ravel()])  # Godot: v2 = 1 + Z / 4, one repeat per 4 m
    faces = []
    idx = np.arange((nz + 1) * (nx + 1)).reshape(nz + 1, nx + 1)
    for j in range(nz):
        for i in range(nx):
            if hole is not None:
                qx, qz = xs[i] + spacing / 2, zs[j] + spacing / 2
                if hole[0] <= qx <= hole[1] and hole[2] <= qz <= hole[3]:
                    continue
            a, b, c, d = idx[j, i], idx[j, i + 1], idx[j + 1, i + 1], idx[j + 1, i]
            faces.append((a, d, c))  # counter-clockwise seen from +Z (Blender up)
            faces.append((a, c, b))
    verts = verts.tolist()
    uvs = np.vstack([uv1]).tolist()
    uvs2 = np.vstack([uv2]).tolist()
    if skirt > 0:
        base = len(verts)
        ring = list(idx[0, :]) + list(idx[1:, -1]) + list(idx[-1, -2::-1]) + list(idx[-2:0:-1, 0])
        for k in ring:
            v = verts[k]
            verts.append([v[0], v[1], v[2] - skirt])
            uvs.append(uvs[k])
            uvs2.append(uvs2[k])
        m = len(ring)
        for t in range(m):
            a, b = ring[t], ring[(t + 1) % m]
            a2, b2 = base + t, base + (t + 1) % m
            faces.append((a, b, b2))
            faces.append((a, b2, a2))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.validate(verbose=False)
    for uv_name, data in (("UVMap", uvs), ("UVMap2", uvs2)):
        layer = mesh.uv_layers.new(name=uv_name)
        flat = np.zeros(len(mesh.loops) * 2, dtype=np.float32)
        loop_v = np.zeros(len(mesh.loops), dtype=np.int32)
        mesh.loops.foreach_get("vertex_index", loop_v)
        arr = np.asarray(data, dtype=np.float32)[loop_v]
        flat[:] = arr.ravel()
        layer.data.foreach_set("uv", flat)
    mesh.shade_smooth()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj, len(faces)


def flat_material(name: str):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = REGOLITH_GREY
        bsdf.inputs["Roughness"].default_value = 0.94
        bsdf.inputs["Metallic"].default_value = 0.0
    return mat


def export_glb(obj, path: Path) -> None:
    """One mesh as a GLB (+Y up, metres). Tangents are left out: Godot's importer rebuilds them
    (meshes/ensure_tangents), which keeps every file about a third smaller."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_normals=True, export_tangents=False, export_texcoords=True,
                              export_materials="EXPORT", export_image_format="NONE", export_animations=False,
                              export_skins=False, export_morph=False, export_cameras=False, export_lights=False,
                              export_extras=False)


def bake_ao(h: np.ndarray, meta: dict, region_w: float, region_h: float, origin: tuple[float, float], size: int, samples: int,
            spacing: float, distance: float, curved: bool) -> np.ndarray:
    """Cycles ambient-occlusion bake of the whole region (mesh at `spacing` metres, occluders searched
    to `distance` metres) onto a size x size image, rows ordered like the normal map (top = north)."""
    scene = bpy.context.scene
    obj, _ = grid_mesh("AO_bake", h, meta, origin[0], origin[1], region_w, region_h, spacing, None, 0.0, (region_w, region_h), origin, curved)
    mat = bpy.data.materials.new("AO_bake_mat")
    mat.use_nodes = True
    img = bpy.data.images.new("AO_bake_img", size, size, alpha=False, float_buffer=False)
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = img
    mat.node_tree.nodes.active = tex
    obj.data.materials.append(mat)
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = False
    scene.render.bake.use_selected_to_active = False
    scene.render.bake.margin = 4
    scene.world.light_settings.distance = distance
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.bake(type="AO")
    px = np.empty(size * size * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    ao = px.reshape(size, size, 4)[:, :, 0]
    ao = ao[::-1, :]  # Blender image rows start at v_blender = 0, which is Godot v = 1 (south); PNG row 0 is north
    bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.images.remove(img)
    bpy.data.materials.remove(mat)
    return np.clip(ao * 255 + 0.5, 0, 255).astype(np.uint8)


# ---------------------------------------------------------------- per region

def build_region(rid: str, args) -> dict:
    """Build one region's detail layer, textures, LOD meshes and tiles.json (see the module doc)."""
    d = LOLA / rid
    meta_path = next(p for p in sorted(d.glob("heightmap_*m.json")) if not p.stem.endswith("_detail"))
    meta = read_json(meta_path)
    kind = meta["kind"]
    curved = kind in CURVED_KINDS
    mpp = meta["metres_per_pixel"]
    h = load_r16(d / meta_path.with_suffix(".r16").name, meta)
    sc, sr, sh = meta["site"]["pixel_col"], meta["site"]["pixel_row"], meta["site"]["height_m"]
    region_name = "".join(p.capitalize() for p in rid.split("_"))
    tiles_dir = d / "tiles"
    tiles_dir.mkdir(exist_ok=True)
    for old in tiles_dir.glob("*.glb"):
        old.unlink()
    # Godot extents of the region
    x_min, x_max = -sc * mpp, (meta["columns"] - 1 - sc) * mpp
    z_min, z_max = -sr * mpp, (meta["rows"] - 1 - sr) * mpp
    extent = (x_min, x_max, z_min, z_max)
    region_size, region_origin = (x_max - x_min, z_max - z_min), (x_min, z_min)
    info = {"region": rid, "kind": kind, "built": time.strftime("%Y-%m-%d"), "metres_per_pixel": mpp, "tiles": [], "vista": None,
            "frame": "Godot metres; X = east column direction, Z = south row direction, Y up; the site is at the origin at Y = 0",
            "curvature": curved,
            "curvature_note": ("Y = height - site height - (X^2 + Z^2) / (2 x 1,737,400 m): the meshes follow the Moon's sphere, so the "
                               "Horizons Sun/Earth elevations (relative to the site's horizontal) light the far terrain correctly"
                               if curved else "flat frame (Y = height - site height): overview only; cut a local frame per playable segment"),
            "site_height_m": sh, "skirt_m": SKIRT_M, "uv1": "region 0..1, v = 0 at the north (z_min) edge: normal and AO maps",
            "uv2": "metres / 4 (one repeat per 4 m like the M1-35 regolith kit)",
            "collision": "terrain_heightfield.gd to_height_map_shape() on heightmap_<mpp>m_detail.r16 (hero) or heightmap_<mpp>m.r16; never the visual mesh",
            "material": "res://assets/environment/terrain/lola/terrain_lola.gdshader via lola_region.gd (object-space normal map, lunar-Lambert regolith)"}
    seed = int(hashlib.sha256(rid.encode()).hexdigest()[:8], 16)
    mat = flat_material("EN_Terrain_Regolith")
    field_detail = h
    if kind == "hero":
        det = add_craters(h, mpp, seed)
        field_detail = det["heights"]
        dpath = d / f"heightmap_{int(mpp)}m_detail.r16"
        zmin, zmax = save_r16(dpath, field_detail)
        dmeta = dict(meta)
        dmeta.update({"format": meta["format"], "z_min_m": round(zmin, 3), "z_max_m": round(zmax, 3), "sha256_r16": sha256(dpath),
                      "detail_layer": {k: v for k, v in det.items() if k != "heights"},
                      "about": "LOLA heightmap plus the authored sub-resolution crater layer (not NASA data at these scales); use for collision so it matches the tiles"})
        write_json(dpath.with_suffix(".json"), dmeta)
        # the collision copy is quantised; build the meshes from exactly what collision will read
        field_detail = load_r16(dpath, dmeta)
        info["detail_heightmap"] = dpath.name
        info["detail_layer"] = dmeta["detail_layer"]
        print(f"{rid}: {det['count']} detail craters {det['diameter_min_m']:.0f}-{det['diameter_max_m']:.0f} m stamped", flush=True)
    # textures (object-space normals from the field the near LODs show; AO from the same field)
    nm = normal_map(field_detail, meta, extent, args.normal_size, curved)
    write_png(d / f"T_Terrain_{region_name}_Normal.png", nm)
    info["normal_map"] = f"T_Terrain_{region_name}_Normal.png"
    info["normal_map_space"] = "object space in this region's Godot frame (R = X, G = Y up, B = Z), curvature included; not a tangent-space map"
    if not args.no_ao:
        t0 = time.time()
        ao = bake_ao(field_detail, meta, region_size[0], region_size[1], region_origin, args.ao_size, args.ao_samples,
                     AO_SPACING_M[kind], AO_DISTANCE_M[kind], curved)
        write_png(d / f"T_Terrain_{region_name}_AO.png", ao)
        info["ao_map"] = f"T_Terrain_{region_name}_AO.png"
        info["ao_bake"] = {"mesh_spacing_m": AO_SPACING_M[kind], "distance_m": AO_DISTANCE_M[kind], "samples": args.ao_samples, "size_px": args.ao_size,
                           "orientation_check": ao_orientation_score(ao, field_detail, meta, extent, curved),
                           "use": "darkens only the faint Earthshine/bounce fill; the Sun's light is never multiplied by AO"}
        print(f"{rid}: AO baked {args.ao_size}px in {time.time() - t0:.0f} s, {info['ao_bake']['orientation_check']}", flush=True)
    if kind == "hero":
        # tiles: 2 km, 4x4 starting at the region's -4 km corner (site at the centre corner of the 2x2 middle tiles)
        n_tiles = int(round((x_max - x_min) / TILE_M))
        tx0 = -n_tiles / 2 * TILE_M
        tz0 = -n_tiles / 2 * TILE_M
        for tj in range(n_tiles):
            for ti in range(n_tiles):
                x0, z0 = tx0 + ti * TILE_M, tz0 + tj * TILE_M
                central = (n_tiles // 2 - 1) <= ti <= n_tiles // 2 and (n_tiles // 2 - 1) <= tj <= n_tiles // 2
                lods = []
                for li, spacing in enumerate(HERO_LODS):
                    if li == 0 and not central:
                        continue
                    name = f"EN_Terrain_{region_name}_T{tj}{ti}_LOD{li}"
                    field = field_detail if li <= 1 else h
                    obj, tris = grid_mesh(name, field, meta, x0, z0, TILE_M, TILE_M, spacing, None, SKIRT_M, region_size, region_origin, curved)
                    obj.data.materials.append(mat)
                    path = tiles_dir / f"{name}.glb"
                    export_glb(obj, path)
                    lods.append({"lod": li, "path": f"res://assets/environment/terrain/lola/{rid}/tiles/{name}.glb", "vertex_spacing_m": spacing,
                                 "field": "detail" if li <= 1 else "lola", "triangles": tris, "visible_from_m": HERO_LOD_RANGES_M[li],
                                 "visible_to_m": HERO_LOD_RANGES_M[li + 1], "bytes": path.stat().st_size})
                    bpy.data.objects.remove(obj, do_unlink=True)
                if lods and lods[0]["lod"] != 0:
                    lods[0]["visible_from_m"] = 0.0
                info["tiles"].append({"id": f"T{tj}{ti}", "center_x_m": x0 + TILE_M / 2, "center_z_m": z0 + TILE_M / 2, "size_m": TILE_M, "lods": lods})
                print(f"{rid}: tile T{tj}{ti} {[l['triangles'] for l in lods]} tris", flush=True)
    else:
        # vista / corridor: one mesh per LOD over the whole window; vistas carve the hero 8 km hole
        hole = (-4000.0, 4000.0, -4000.0, 4000.0) if kind == "vista" else None
        lods = []
        for li, spacing in enumerate(VISTA_LODS):
            name = f"EN_Terrain_{region_name}_LOD{li}"
            obj, tris = grid_mesh(name, h, meta, x_min, z_min, region_size[0], region_size[1], spacing, hole, SKIRT_M * 4, region_size, region_origin, curved)
            obj.data.materials.append(mat)
            path = tiles_dir / f"{name}.glb"
            export_glb(obj, path)
            lods.append({"lod": li, "path": f"res://assets/environment/terrain/lola/{rid}/tiles/{name}.glb", "vertex_spacing_m": spacing, "field": "lola",
                         "triangles": tris, "visible_from_m": VISTA_LOD_RANGES_M[li], "visible_to_m": VISTA_LOD_RANGES_M[li + 1], "bytes": path.stat().st_size})
            bpy.data.objects.remove(obj, do_unlink=True)
            print(f"{rid}: vista LOD{li} {tris} tris", flush=True)
        info["vista"] = {"center_x_m": (x_min + x_max) / 2, "center_z_m": (z_min + z_max) / 2, "size_x_m": region_size[0], "size_z_m": region_size[1], "hole_m": hole, "lods": lods}
    info["extent_godot_m"] = {"x_min": x_min, "x_max": x_max, "z_min": z_min, "z_max": z_max}
    write_json(d / "tiles.json", info)
    return info


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--region", default="", help="one region id; default all")
    ap.add_argument("--no-ao", action="store_true")
    ap.add_argument("--ao-size", type=int, default=1024)
    ap.add_argument("--ao-samples", type=int, default=24)
    ap.add_argument("--normal-size", type=int, default=2048)
    args = ap.parse_args(argv)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    if bpy.context.scene.world is None:
        bpy.context.scene.world = bpy.data.worlds.new("World")
    regions = [args.region] if args.region else sorted(p.name for p in LOLA.iterdir() if p.is_dir() and list(p.glob("heightmap_*m.json")))
    total = time.time()
    for rid in regions:
        t0 = time.time()
        info = build_region(rid, args)
        n = len(info["tiles"]) or 1
        print(f"== {rid}: {n} tiles, {sum(l['bytes'] for t in info['tiles'] for l in t['lods']) + (sum(l['bytes'] for l in info['vista']['lods']) if info['vista'] else 0)} bytes in {time.time() - t0:.0f} s", flush=True)
    print(f"TERRAIN TILES DONE: {len(regions)} regions in {time.time() - total:.0f} s", flush=True)


if __name__ == "__main__":
    main()
