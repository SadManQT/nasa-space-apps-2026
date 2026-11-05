"""Offline regression checks for the LOLA terrain pipeline (board M1-34): projection, the TIFF
floating-point predictor, r16 encoding, cast shadows, slope-limited routing, the Sun frame and the
Blender detail layer's pure functions. No network, no Blender, no files written outside a temp dir.

  python3 production/tools/test_make_terrain.py
"""
import ast
import math
import struct
import sys
import tempfile
import zlib
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import make_terrain as mt  # noqa: E402

# ---- projection: IAU feature positions round-trip and land where the LOLA products put them
sx, sy = mt.latlon_to_xy(-89.67, 129.78)
assert abs(math.hypot(sx, sy) - 10005) < 30, (sx, sy)  # Shackleton centre ~10 km from the pole
assert sx > 0 and sy < 0  # 129.78E: x toward 90E positive, y toward 0E negative
mx, my = mt.latlon_to_xy(-85.98, -1.67)
assert abs(my - 121800) < 400 and abs(mx + 3550) < 100, (mx, my)  # Malapert ~122 km up the 0E axis
for lat, lon in ((-89.4389, 222.8564), (-85.98, 358.33), (-88.0, 90.0)):
    x, y = mt.latlon_to_xy(lat, lon)
    la, lo = mt.xy_to_latlon(x, y)
    assert abs(la - lat) < 1e-9 and abs(lo - lon) < 1e-9

# ---- local axes and Sun vector: north points away from the pole, east is clockwise from north
n, e = mt.local_axes(0.0, -16000.0)  # a site "below" the pole on the map (lon 180)
assert np.allclose(n, [0, -1]) and np.allclose(e, [-1, 0])
v = mt.sun_vector_map(0.0, -16000.0, 90.0, 1.5)
assert abs(v[2] - math.sin(math.radians(1.5))) < 1e-9 and v[0] < 0 and abs(v[1]) < 1e-9
assert abs(np.linalg.norm(v) - 1) < 1e-9


# ---- TIFF floating-point predictor (libtiff fpAcc layout) decodes a hand-encoded tile
def encode_fp_predictor(tile: np.ndarray) -> bytes:
    th, tw = tile.shape
    le = tile.astype("<f4").view(np.uint8).reshape(th, tw, 4)
    planes = np.empty((th, 4, tw), np.uint8)
    for b in range(4):
        planes[:, 3 - b, :] = le[:, :, b]  # plane 0 = most significant byte
    row = planes.reshape(th, tw * 4).astype(np.int16)
    diff = row.copy()
    diff[:, 1:] = (row[:, 1:] - row[:, :-1]) & 0xFF
    return zlib.compress(diff.astype(np.uint8).tobytes())


class FakeCog(mt.CogReader):
    def __init__(self, tw, th):
        self.id = "fake"
        self.h = {"compression": 8, "predictor": 3, "bits": 32, "byteorder": "<", "sample_format": 3}
        self.tw, self.th = tw, th


rng = np.random.default_rng(1)
tile = (rng.standard_normal((16, 32)) * 1000).astype(np.float32)
tile[0, 0] = np.nan
decoded = FakeCog(32, 16)._decode(encode_fp_predictor(tile))
assert decoded.shape == tile.shape and np.isnan(decoded[0, 0]) and np.array_equal(decoded[1:], tile[1:])

# ---- r16 round trip keeps heights within one quantisation step
h = rng.uniform(-2500, 1900, (64, 64)).astype(np.float32)
q, zmin, zmax = mt.encode_r16(h)
back = zmin + q.astype(np.float64) * (zmax - zmin) / 65535.0
assert q.dtype == np.dtype("<u2") and np.abs(back - h).max() <= (zmax - zmin) / 65535.0 + 1e-6

# ---- PNG writer produces files the standard decoder accepts (8-bit grey, RGB, 16-bit grey)
with tempfile.TemporaryDirectory() as tmp:
    for arr in (np.full((4, 5), 200, np.uint8), np.zeros((3, 3, 3), np.uint8), np.full((2, 2), 60000, np.uint16)):
        p = Path(tmp) / "t.png"
        mt.write_png(p, arr)
        data = p.read_bytes()
        assert data[:8] == b"\x89PNG\r\n\x1a\n"
        w, hgt, depth, ctype = struct.unpack(">IIBB", data[16:26])
        assert (w, hgt) == (arr.shape[1], arr.shape[0]) and depth == (16 if arr.dtype == np.uint16 else 8) and ctype == (2 if arr.ndim == 3 else 0)
        try:
            from PIL import Image
            im = Image.open(p)
            im.load()
            assert im.size == (arr.shape[1], arr.shape[0])
        except ImportError:
            pass

# ---- a 100 m wall at a 1.5 deg Sun throws a shadow ~3.8 km long on the side away from the Sun
field = np.zeros((200, 200), np.float32)
field[:, 100:104] = 100.0  # wall running north-south (columns 100..103), 20 m pixels
sun_from_east = mt.sun_vector_map(0.0, -16000.0, 90.0, 1.5)  # Sun in the local east
# at this site east is map -x (see local_axes above): the shadow must fall toward +x (higher columns)
shadow = mt.cast_shadow(field, 20.0, sun_from_east)
assert shadow[100, 110] and shadow[100, 250 // 2 + 60] and not shadow[100, 90], "shadow falls away from the Sun"
expected_len_px = 100.0 / math.tan(math.radians(1.5)) / 20.0  # ~191 px
lit_cols = np.nonzero(~shadow[100, 104:])[0]
assert lit_cols.size == 0 or lit_cols[0] + 104 >= 104 + expected_len_px * 0.5  # grid ends before the shadow does
assert mt.hillshade(field, 20.0, sun_from_east)[100, 50] > 0.02
# the same wall turned east-west under a Sun from the local north (map +y, up the image at this
# site): the shadow must fall south (down the image), and a diagonal Sun must not mirror it
field_ew = np.zeros((200, 200), np.float32)
field_ew[100:104, :] = 100.0
north_site = (0.0, 16000.0)  # local north = map +y, local east = map +x
for az, lit_row, dark_cell in ((0.0, 90, (110, 100)), (45.0, 90, (110, 120)), (315.0, 90, (110, 80))):
    sv = mt.sun_vector_map(*north_site, az, 1.5)
    sh = mt.cast_shadow(field_ew, 20.0, sv)
    assert sh[dark_cell] and not sh[lit_row, 100], f"Sun az {az}: shadow falls away from the Sun"
# a slope facing a low Sun stays lit end to end: no self-shadowing from the wrong side
slope = np.tile((np.arange(200) * 20.0 * 0.2)[:, None], (1, 200)).astype(np.float32)  # rises toward +row (south): faces north
sv = mt.sun_vector_map(*north_site, 0.0, 2.0)  # Sun in the north, the slope faces it
assert mt.cast_shadow(slope, 20.0, sv)[20:180, 20:180].mean() < 0.01
assert mt.cast_shadow(slope[::-1].copy(), 20.0, sv)[20:180, 20:180].mean() > 0.99  # the same slope facing away is dark

# ---- routing: the slope-limited road goes around a steep ridge instead of over it
grid = np.zeros((60, 60), np.float32)
grid[20:40, 30] = 500.0  # a knife ridge in the middle (slopes > 12 deg)
goals = np.zeros_like(grid, dtype=bool)
goals[30, 55] = True
path, length = mt.dijkstra_route(grid, 20.0, (30, 5), goals, 12.0)
assert path is not None and path[0] == (30, 5) and path[-1] == (30, 55)
assert all(not (20 <= r <= 39 and 29 <= c <= 31) for r, c in path), "road crosses the blocked ridge"
assert length > 50 * 20.0 and length < 2000.0
prof = mt.path_profile(path, grid, 20.0, {"origin_x_m": 0.0, "origin_y_m": 0.0}, 12.0)
assert prof["max_slope_deg"] <= 12.0 and prof["length_m"] == round(length, 1) and prof["length_over_limit_m"] == 0.0

# ---- a goal ringed by 13-14 deg slopes: unreachable at 12 deg, reached when 15 deg is allowed, and
# the road spends as little length as possible above 12 deg
mound = np.zeros((80, 80), np.float32)
rr, cc = np.mgrid[0:80, 0:80]
dist = np.hypot(rr - 40, cc - 60) * 20.0
mound = np.where(dist < 300, 300 * math.tan(math.radians(13.5)) - dist * math.tan(math.radians(13.5)), 0).astype(np.float32)
mound = np.maximum(mound, 0)
goal = np.zeros_like(mound, dtype=bool)
goal[40, 60] = True
assert mt.dijkstra_route(mound, 20.0, (40, 5), goal, 12.0)[0] is None
path, length = mt.dijkstra_route(mound, 20.0, (40, 5), goal, 12.0, hard_limit=15.0)
assert path is not None and path[-1] == (40, 60)
prof = mt.path_profile(path, mound, 20.0, {"origin_x_m": 0.0, "origin_y_m": 0.0}, 12.0)
assert 12.0 < prof["max_slope_deg"] <= 15.0 and 0 < prof["length_over_limit_m"] <= 400.0, prof["length_over_limit_m"]
assert prof["climb_m"] > 60 and prof["descent_m"] < 5

# ---- Blender detail layer: pure functions loaded without bpy
source = Path(__file__).with_name("build_terrain_tiles.py")
module = ast.parse(source.read_text())
scope = {"np": np, "math": math}
wanted = {"equilibrium_count", "add_craters", "normal_map", "sample_field", "curvature_drop", "godot_y", "ao_orientation_score"}
consts = [n for n in module.body if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id in ("R_MOON", "DETAIL_CRATER_MAX_M") for t in n.targets)]
exec(compile(ast.Module(body=consts + [n for n in module.body if isinstance(n, ast.FunctionDef) and n.name in wanted], type_ignores=[]), str(source), "exec"), scope)
assert scope["equilibrium_count"](0.015, 0.06, 1.0) == 159  # Trask/Gault equilibrium, 15-60 m craters per km2
flat = np.full((400, 400), 1000.0)
det = scope["add_craters"](flat, 5.0, 7)
assert det["count"] == scope["equilibrium_count"](0.015, 0.06, 4.0) and det["heights"].shape == flat.shape
assert det["heights"].min() < 1000.0 - 0.5 and det["heights"].max() > 1000.0 + 0.1  # bowls and rims
assert abs(det["heights"].mean() - 1000.0) < 0.5, "craters move little volume"
again = scope["add_craters"](flat, 5.0, 7)["heights"]
assert np.array_equal(det["heights"], again), "seeded layer is deterministic"
assert scope["add_craters"](np.full((100, 100), 0.0), 10.0, 3)["diameter_max_m"] == 60.0, "no detail crater a 10 m grid could resolve"
# curvature: 1 km from the site the sphere has dropped 1000^2 / (2 x 1,737,400) = 0.288 m
assert abs(scope["curvature_drop"](np.array([1000.0]), np.array([0.0]))[0] - 0.28779) < 1e-4
meta = {"metres_per_pixel": 5.0, "site": {"pixel_col": 200.0, "pixel_row": 200.0, "height_m": 1000.0}}
extent = (-1000.0, 995.0, -1000.0, 995.0)
assert abs(scope["godot_y"](flat, meta, np.array([0.0]), np.array([0.0]), True)[0]) < 1e-9
assert abs(scope["godot_y"](flat, meta, np.array([600.0]), np.array([800.0]), True)[0] + 0.28779) < 1e-4
# object-space normal map: flat ground points straight up (G = 255); curvature tilts the edges outward
nm = scope["normal_map"](flat, meta, extent, 64, False)
assert nm.shape == (64, 64, 3) and (nm[..., 1] == 255).all() and (abs(nm[..., 0].astype(int) - 128) <= 1).all() and (abs(nm[..., 2].astype(int) - 128) <= 1).all()
wide = {"metres_per_pixel": 500.0, "site": {"pixel_col": 200.0, "pixel_row": 200.0, "height_m": 1000.0}}  # +-100 km: 3.3 deg of tilt
nm = scope["normal_map"](flat, wide, (-100000.0, 99500.0, -100000.0, 99500.0), 64, True)
assert nm[32, 63, 0] > nm[32, 32, 0] and nm[32, 0, 0] < nm[32, 32, 0] and nm[63, 32, 2] > nm[32, 32, 2], "curved ground tilts away from the site"
ramp = np.tile(np.arange(400, dtype=np.float64) * 5.0, (400, 1))  # rises toward +X by 1 m per m (45 deg)
nm = scope["normal_map"](ramp, meta, extent, 64, False)
assert nm[32, 32, 0] < 128 and abs(int(nm[32, 32, 2]) - 128) <= 1 and abs(int(nm[32, 32, 0]) - (128 - 90)) <= 2, "normal tilts away from the rise (-X)"
ramp_z = ramp.T.copy()  # rises toward +Z (south, down the image)
nm = scope["normal_map"](ramp_z, meta, extent, 64, False)
assert nm[10, 32, 2] < 128 and abs(int(nm[10, 32, 0]) - 128) <= 1, "row 0 is the north (z_min) edge, as UV1 v = 0 in Godot"
hs = scope["sample_field"](ramp, 5.0, np.array([10.0]), np.array([0.0]), 100.0, 100.0)
assert abs(hs[0] - 102 * 5.0) < 1e-6  # 10 m = 2 px east of pixel column 100
# AO orientation score: an AO image that is dark in a bowl correlates with concavity, its flip does not
bowl = 1000.0 + 0.0005 * ((np.mgrid[0:400, 0:400][0] - 100.0) ** 2 + (np.mgrid[0:400, 0:400][1] - 200.0) ** 2)
bowl = np.minimum(bowl, 1000.0 + 0.0005 * 60.0 ** 2)
ao = np.full((64, 64), 230, np.uint8)
ao[8:24, 24:40] = 90  # the bowl's floor is around rows 100 +- 60 px of 400, columns 200 +- 60
score = scope["ao_orientation_score"](ao, bowl, meta, extent, False)
assert score["corr_with_crests"] > score["corr_if_flipped"], score

print("make_terrain checks OK")
