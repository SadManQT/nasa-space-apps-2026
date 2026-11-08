#!/usr/bin/env python3
"""Real south-pole terrain from NASA LRO LOLA elevation data (board M1-34).

Reads production/terrain/regions.json, fetches only the parts of the NASA products it needs
(HTTP range requests into the cloud-optimised GeoTIFFs of PGDA product 90, whole 5 m site GeoTIFFs
of PGDA product 78, and PDS LOLA GDR rows for a cross-check), picks the story sites on the real
terrain, computes slope-limited routes, the local horizon of each site, the Sun and Earth positions
for every story date (JPL Horizons), and writes:

  game/assets/environment/terrain/lola/<region>/heightmap_<mpp>m.r16 + .json   16-bit heightmaps
  game/assets/environment/terrain/lola/lola_terrain.json                        manifest for Godot
  game/assets/environment/terrain/lola/sun_positions.json                       ephemeris tables
  game/resources/data/nasa/lro_lola_south_pole_terrain.json                     Data Card fixture
  production/terrain/provenance.json, sites.json, routes.json, preview/*.png    provenance + review

Standard library + numpy. scipy (optional) speeds up two steps; Pillow is only used by `review`.

  python3 production/tools/make_terrain.py all          # everything, in order
  python3 production/tools/make_terrain.py sites        # pin the site coordinates (needs network)
  python3 production/tools/make_terrain.py routes       # slope-limited roads (the corridor crop follows them)
  python3 production/tools/make_terrain.py heightmaps   # crop + encode the regions
  python3 production/tools/make_terrain.py sun          # JPL Horizons + local horizon masks
  python3 production/tools/make_terrain.py preview      # hillshades with cast shadows, PSR crops
  python3 production/tools/make_terrain.py fixture      # provenance + Data Card fixture + manifest
  python3 production/tools/make_terrain.py review       # side-by-side LOLA hillshade vs in-game capture
  python3 production/tools/make_terrain.py check        # offline validation of everything written

Downloads are untrusted data: they are decoded as numbers in memory and never executed. The cache
(production/terrain/cache/, gitignored) keeps decoded tiles so re-runs are offline.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import heapq
import json
import math
import re
import struct
import sys
import time
import urllib.parse
import urllib.request
import zlib
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np

try:  # optional accelerators
    from scipy import ndimage as _ndimage
except Exception:  # pragma: no cover - scipy is optional
    _ndimage = None

ROOT = Path(__file__).resolve().parents[2]
TERRAIN = ROOT / "production" / "terrain"
CACHE = TERRAIN / "cache"
PREVIEW = TERRAIN / "preview"
GAME_LOLA = ROOT / "game" / "assets" / "environment" / "terrain" / "lola"
NASA = ROOT / "game" / "resources" / "data" / "nasa"
REVIEW = ROOT / "production" / "review"
EVIDENCE = ROOT / "production" / "qa" / "evidence"
HORIZONS = "https://ssd.jpl.nasa.gov/api/horizons.api"
UA = "Mozilla/5.0 (LastLightAcademy terrain pipeline; NASA Space Apps 2026)"
TODAY = dt.date.today().isoformat()
SUN_RADIUS_DEG = 0.2665  # mean apparent solar radius from the Moon

CFG = json.loads((TERRAIN / "regions.json").read_text(encoding="utf-8"))
R_MOON = float(CFG["moon_radius_m"])


# ---------------------------------------------------------------- small helpers

def log(msg: str) -> None:
    print(msg, flush=True)


def write_json(path: Path, obj) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def latlon_to_xy(lat_deg: float, lon_deg: float) -> tuple[float, float]:
    """South polar stereographic (spherical, PDS/GMT convention): x = r sin(lon), y = r cos(lon)."""
    r = 2.0 * R_MOON * math.tan(math.radians(90.0 + lat_deg) / 2.0)
    return r * math.sin(math.radians(lon_deg)), r * math.cos(math.radians(lon_deg))


def xy_to_latlon(x: float, y: float) -> tuple[float, float]:
    r = math.hypot(x, y)
    lat = -90.0 + math.degrees(2.0 * math.atan(r / (2.0 * R_MOON)))
    lon = math.degrees(math.atan2(x, y)) % 360.0
    return lat, lon


def local_axes(x: float, y: float) -> tuple[np.ndarray, np.ndarray]:
    """Unit vectors (in map x, y) of local north (away from the pole) and east (clockwise from north)."""
    n = np.array([x, y], dtype=float)
    n /= np.linalg.norm(n)
    e = np.array([n[1], -n[0]])
    return n, e


def sun_vector_map(x: float, y: float, az_deg: float, el_deg: float) -> np.ndarray:
    """Unit vector toward a body in (map x, map y, up) for a site at map (x, y)."""
    n, e = local_axes(x, y)
    az, el = math.radians(az_deg), math.radians(el_deg)
    h = math.cos(el) * (math.cos(az) * n + math.sin(az) * e)
    return np.array([h[0], h[1], math.sin(el)])


# ---------------------------------------------------------------- network

def http_get(url: str, byte_range: tuple[int, int] | None = None, tries: int = 4) -> bytes:
    headers = {"User-Agent": UA}
    if byte_range is not None:
        headers["Range"] = f"bytes={byte_range[0]}-{byte_range[1]}"
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=180) as r:
                data = r.read()
            if byte_range is not None and r.status != 206:
                raise RuntimeError(f"server ignored the range request ({r.status})")
            return data
        except Exception as exc:  # retry, then fail loudly with the URL
            if attempt == tries - 1:
                raise RuntimeError(f"download failed: {url} {byte_range}: {exc}") from exc
            time.sleep(2 + 3 * attempt)
    raise AssertionError


def download_whole(url: str, dest: Path) -> Path:
    if dest.exists():
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    log(f"  fetch {url}")
    data = http_get(url)
    tmp = dest.with_suffix(dest.suffix + ".part")
    tmp.write_bytes(data)
    tmp.rename(dest)
    return dest


# ---------------------------------------------------------------- TIFF readers

TIFF_TYPES = {1: ("B", 1), 2: ("c", 1), 3: ("H", 2), 4: ("I", 4), 5: ("II", 8), 11: ("f", 4), 12: ("d", 8), 16: ("Q", 8), 17: ("q", 8)}


def parse_tiff_header(head: bytes, fetch_more) -> dict:
    """Parse the first IFD of a classic or BigTIFF file. fetch_more(a, b) returns bytes a..b when the
    header buffer is too short for an out-of-line array (tile offsets, GeoTIFF doubles)."""
    bo = "<" if head[:2] == b"II" else ">"
    magic = struct.unpack(bo + "H", head[2:4])[0]
    big = magic == 43
    buf = bytearray(head)

    def need(upto: int):
        if upto > len(buf):
            buf.extend(fetch_more(len(buf), upto + 65536))

    if big:
        off = struct.unpack(bo + "Q", buf[8:16])[0]
        need(off + 8)
        n = struct.unpack(bo + "Q", bytes(buf[off:off + 8]))[0]
        esize, base = 20, off + 8
    else:
        off = struct.unpack(bo + "I", buf[4:8])[0]
        need(off + 2)
        n = struct.unpack(bo + "H", bytes(buf[off:off + 2]))[0]
        esize, base = 12, off + 2
    need(base + n * esize)
    tags = {}
    for i in range(n):
        e = bytes(buf[base + i * esize: base + (i + 1) * esize])
        if big:
            tag, typ, cnt = struct.unpack(bo + "HHQ", e[:12])
            val = e[12:20]
        else:
            tag, typ, cnt = struct.unpack(bo + "HHI", e[:8])
            val = e[8:12]
        fmt, size = TIFF_TYPES.get(typ, ("B", 1))
        total = size * cnt
        inline = 8 if big else 4
        if total <= inline:
            raw = val[:total]
        else:
            o = struct.unpack(bo + ("Q" if big else "I"), val)[0]
            need(o + total)
            raw = bytes(buf[o:o + total])
        if typ == 2:
            tags[tag] = raw.rstrip(b"\0").decode("latin-1")
        elif typ == 5:
            tags[tag] = [a / b for a, b in struct.iter_unpack(bo + "II", raw)]
        else:
            tags[tag] = list(struct.unpack(bo + fmt * cnt, raw))
    return {"byteorder": bo, "bigtiff": big, "tags": tags}


class CogReader:
    """Tiled GeoTIFF read through HTTP range requests; decoded tiles are cached on disk."""

    def __init__(self, product_id: str):
        self.id = product_id
        self.p = CFG["products"][product_id]
        self.url = self.p["url"]
        self.dir = CACHE / product_id
        self.dir.mkdir(parents=True, exist_ok=True)
        hp = self.dir / "header.json"
        if hp.exists():
            self.h = read_json(hp)
        else:
            head = http_get(self.url, (0, 131071))
            parsed = parse_tiff_header(head, lambda a, b: http_get(self.url, (a, b)))
            t = parsed["tags"]
            self.h = {
                "byteorder": parsed["byteorder"], "width": t[256][0], "height": t[257][0],
                "bits": t[258][0], "compression": t.get(259, [1])[0], "predictor": t.get(317, [1])[0],
                "sample_format": t.get(339, [1])[0], "tile_w": t[322][0], "tile_h": t[323][0],
                "tile_offsets": t[324], "tile_bytes": t[325], "pixel_scale": t[33550],
                "tiepoint": t[33922], "nodata": t.get(42113, ""), "retrieved": TODAY,
                "content_length": None,
            }
            write_json(hp, self.h)
        h = self.h
        self.w, self.ht = h["width"], h["height"]
        self.tw, self.th = h["tile_w"], h["tile_h"]
        self.mpp = float(h["pixel_scale"][0])
        self.x0 = float(h["tiepoint"][3]) - float(h["tiepoint"][0]) * self.mpp  # top-left corner of pixel (0,0)
        self.y0 = float(h["tiepoint"][4]) + float(h["tiepoint"][1]) * self.mpp
        self.tiles_across = math.ceil(self.w / self.tw)
        self.fetched_bytes = 0

    def col_of(self, x: float) -> float:
        """Fractional column whose integer part is the pixel containing x (pixel centres at .0)."""
        return (x - self.x0) / self.mpp - 0.5

    def row_of(self, y: float) -> float:
        return (self.y0 - y) / self.mpp - 0.5

    def pixel_center(self, col: int, row: int) -> tuple[float, float]:
        return self.x0 + (col + 0.5) * self.mpp, self.y0 - (row + 0.5) * self.mpp

    def _tile(self, ty: int, tx: int) -> np.ndarray:
        cp = self.dir / f"t_{ty:04d}_{tx:04d}.npy"
        if cp.exists():
            return np.load(cp)
        idx = ty * self.tiles_across + tx
        off, nbytes = self.h["tile_offsets"][idx], self.h["tile_bytes"][idx]
        if nbytes == 0:
            arr = np.full((self.th, self.tw), np.nan, np.float32)
        else:
            raw = http_get(self.url, (off, off + nbytes - 1))
            self.fetched_bytes += len(raw)
            arr = self._decode(raw)
        np.save(cp, arr)
        return arr

    def _decode(self, raw: bytes) -> np.ndarray:
        comp = self.h["compression"]
        data = zlib.decompress(raw) if comp == 8 else raw if comp == 1 else None
        if data is None:
            raise RuntimeError(f"{self.id}: unsupported TIFF compression {comp}")
        bps = self.h["bits"] // 8
        a = np.frombuffer(data, dtype=np.uint8)
        if a.size != self.tw * self.th * bps:
            raise RuntimeError(f"{self.id}: tile has {a.size} bytes, expected {self.tw * self.th * bps}")
        a = a.reshape(self.th, self.tw * bps)
        if self.h["predictor"] == 3:  # floating-point horizontal differencing, byte planes MSB first
            a = np.cumsum(a, axis=1, dtype=np.uint8).reshape(self.th, bps, self.tw)
            out = np.empty((self.th, self.tw, bps), np.uint8)
            for b in range(bps):
                out[:, :, b] = a[:, bps - 1 - b, :]
            return out.view("<f4").reshape(self.th, self.tw)
        if self.h["predictor"] != 1:
            raise RuntimeError(f"{self.id}: unsupported predictor {self.h['predictor']}")
        dtype = ("<" if self.h["byteorder"] == "<" else ">") + ("f4" if self.h["sample_format"] == 3 else "i4")
        return a.reshape(-1).view(dtype).astype("<f4").reshape(self.th, self.tw)

    def window_px(self, c0: int, r0: int, ncols: int, nrows: int) -> np.ndarray:
        """Float32 block of ncols x nrows pixels starting at column c0, row r0 (NaN outside the image)."""
        out = np.full((nrows, ncols), np.nan, np.float32)
        ty0, ty1 = max(0, r0 // self.th), min(self.ht - 1, r0 + nrows - 1) // self.th
        tx0, tx1 = max(0, c0 // self.tw), min(self.w - 1, c0 + ncols - 1) // self.tw
        wanted = [(ty, tx) for ty in range(ty0, ty1 + 1) for tx in range(tx0, tx1 + 1)]
        missing = [t for t in wanted if not (self.dir / f"t_{t[0]:04d}_{t[1]:04d}.npy").exists()]
        if missing:
            log(f"  {self.id}: fetching {len(missing)} tiles of {self.tw}x{self.th} px")
            with ThreadPoolExecutor(max_workers=6) as pool:
                list(pool.map(lambda t: self._tile(*t), missing))
        for ty, tx in wanted:
            tile = self._tile(ty, tx)
            tr0, tc0 = ty * self.th, tx * self.tw
            a0, a1 = max(r0, tr0), min(r0 + nrows, tr0 + self.th, self.ht)
            b0, b1 = max(c0, tc0), min(c0 + ncols, tc0 + self.tw, self.w)
            if a1 > a0 and b1 > b0:
                out[a0 - r0:a1 - r0, b0 - c0:b1 - c0] = tile[a0 - tr0:a1 - tr0, b0 - tc0:b1 - tc0]
        nodata = self.h.get("nodata", "")
        if nodata and nodata.strip() not in ("", "nan"):
            try:
                out[out == float(nodata)] = np.nan
            except ValueError:
                pass
        return out


class StripTiffReader:
    """Whole-file uncompressed strip GeoTIFF (PGDA 5 m site DEMs), memory-mapped."""

    def __init__(self, product_id: str):
        self.id = product_id
        self.p = CFG["products"][product_id]
        self.url = self.p["url"]
        self.path = download_whole(self.url, CACHE / product_id / Path(self.url).name)
        head = self.path.read_bytes()[:262144]
        parsed = parse_tiff_header(head, lambda a, b: self.path.read_bytes()[a:b])
        t = parsed["tags"]
        self.w, self.ht = t[256][0], t[257][0]
        if t.get(259, [1])[0] != 1 or t.get(339, [1])[0] != 3 or t[258][0] != 32:
            raise RuntimeError(f"{product_id}: expected uncompressed float32 strips")
        offsets = t[273]
        rows_per_strip = t.get(278, [self.ht])[0]
        if any(offsets[i + 1] - offsets[i] != self.w * 4 * rows_per_strip for i in range(len(offsets) - 1)):
            raise RuntimeError(f"{product_id}: strips are not contiguous")
        self.mpp = float(t[33550][0])
        self.x0 = float(t[33922][3]) - float(t[33922][0]) * self.mpp
        self.y0 = float(t[33922][4]) + float(t[33922][1]) * self.mpp
        dtype = ("<" if parsed["byteorder"] == "<" else ">") + "f4"
        self.data = np.memmap(self.path, dtype=dtype, mode="r", offset=offsets[0], shape=(self.ht, self.w))
        self.fetched_bytes = self.path.stat().st_size

    col_of = CogReader.col_of
    row_of = CogReader.row_of
    pixel_center = CogReader.pixel_center

    def contains(self, x0: float, x1: float, y0: float, y1: float) -> bool:
        return (self.col_of(x0) >= 0 and self.col_of(x1) <= self.w - 1 and
                self.row_of(y0) >= 0 and self.row_of(y1) <= self.ht - 1)

    def window_px(self, c0: int, r0: int, ncols: int, nrows: int) -> np.ndarray:
        out = np.full((nrows, ncols), np.nan, np.float32)
        a0, a1 = max(r0, 0), min(r0 + nrows, self.ht)
        b0, b1 = max(c0, 0), min(c0 + ncols, self.w)
        if a1 > a0 and b1 > b0:
            out[a0 - r0:a1 - r0, b0 - c0:b1 - c0] = np.asarray(self.data[a0:a1, b0:b1], dtype="<f4")
        return out


class PdsImgReader:
    """PDS3 LOLA GDR polar IMG (16-bit integers, 0.5 m per DN) read as row blocks through ranges."""

    def __init__(self, product_id: str):
        self.id = product_id
        self.p = CFG["products"][product_id]
        self.url = self.p["url"]
        self.dir = CACHE / product_id
        self.dir.mkdir(parents=True, exist_ok=True)
        lbl = self.dir / "label.lbl"
        if not lbl.exists():
            lbl.write_bytes(http_get(self.p["label"]))
        text = lbl.read_text(encoding="latin-1")

        def kv(key):
            m = re.search(rf"^\s*{key}\s*=\s*([-\d.]+)", text, re.M)
            return float(m.group(1)) if m else None

        self.w, self.ht = int(kv("LINE_SAMPLES")), int(kv("LINES"))
        self.scale = kv("SCALING_FACTOR")
        self.mpp = kv("MAP_SCALE")
        self.offset_px = kv("LINE_PROJECTION_OFFSET")
        self.record_bytes = int(kv("RECORD_BYTES"))
        self.product_version = re.search(r'PRODUCT_VERSION_ID\s*=\s*"([^"]+)"', text).group(1)
        self.dataset_id = re.search(r'DATA_SET_ID\s*=\s*"([^"]+)"', text).group(1)
        self.fetched_bytes = 0

    def col_of(self, x: float) -> float:
        return x / self.mpp + self.offset_px

    def row_of(self, y: float) -> float:
        return self.offset_px - y / self.mpp

    def window_px(self, c0: int, r0: int, ncols: int, nrows: int) -> np.ndarray:
        cp = self.dir / f"rows_{r0}_{nrows}.npy"
        if cp.exists():
            rows = np.load(cp)
        else:
            raw = http_get(self.url, (r0 * self.record_bytes, (r0 + nrows) * self.record_bytes - 1))
            self.fetched_bytes += len(raw)
            rows = np.frombuffer(raw, dtype="<i2").reshape(nrows, self.w)
            np.save(cp, rows)
        return rows[:, c0:c0 + ncols].astype(np.float32) * self.scale


_READERS: dict[str, object] = {}


def reader(product_id: str):
    if product_id not in _READERS:
        kind = CFG["products"][product_id]["kind"]
        _READERS[product_id] = {"cog": CogReader, "strip_tiff": StripTiffReader, "pds_img": PdsImgReader}[kind](product_id)
    return _READERS[product_id]


def window_m(product_id: str, cx: float, cy: float, size_m: float, mpp: float | None = None) -> tuple[np.ndarray, dict]:
    """Square window of the product centred on the pixel containing (cx, cy). Returns the array and
    a geo dict: origin (top-left pixel centre), mpp, the centre pixel (col,row) and its map coords."""
    rd = reader(product_id)
    if mpp is not None and abs(rd.mpp - mpp) > 1e-6:
        raise RuntimeError(f"{product_id} is {rd.mpp} m/px, region asks {mpp}")
    n = int(round(size_m / rd.mpp))
    cc, cr = int(math.floor(rd.col_of(cx) + 0.5)), int(math.floor(rd.row_of(cy) + 0.5))
    c0, r0 = cc - n // 2, cr - n // 2
    arr = rd.window_px(c0, r0, n, n)
    ox, oy = rd.pixel_center(c0, r0) if hasattr(rd, "pixel_center") else ((c0 - rd.offset_px) * rd.mpp, (rd.offset_px - r0) * rd.mpp)
    geo = {"product": product_id, "mpp": rd.mpp, "cols": n, "rows": n, "col0": c0, "row0": r0,
           "origin_x_m": ox, "origin_y_m": oy, "center_col": n // 2, "center_row": n // 2,
           "center_x_m": ox + (n // 2) * rd.mpp, "center_y_m": oy - (n // 2) * rd.mpp}
    return arr, geo


# ---------------------------------------------------------------- raster maths

def fill_nan(a: np.ndarray) -> np.ndarray:
    """Replace NaN by the nearest valid value (small gaps only; LOLA grids are already interpolated)."""
    if not np.isnan(a).any():
        return a
    if _ndimage is not None:
        idx = _ndimage.distance_transform_edt(np.isnan(a), return_distances=False, return_indices=True)
        return a[tuple(idx)]
    out = a.copy()
    out[np.isnan(out)] = np.nanmean(a)
    return out


def slope_deg(h: np.ndarray, mpp: float) -> np.ndarray:
    gy, gx = np.gradient(h.astype(np.float64), mpp)
    return np.degrees(np.arctan(np.hypot(gx, gy))).astype(np.float32)


def normals(h: np.ndarray, mpp: float) -> np.ndarray:
    """Unit normals (map x, map y, up) per pixel."""
    gy, gx = np.gradient(h.astype(np.float64), mpp)
    n = np.dstack([-gx, gy, np.ones_like(gx)])  # row axis points -y, so dh/drow = -dh/dy
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return n


def resample(a: np.ndarray, rows: np.ndarray, cols: np.ndarray) -> np.ndarray:
    """Bilinear sample at fractional (rows, cols); outside -> NaN."""
    if _ndimage is not None:
        return _ndimage.map_coordinates(a, [rows, cols], order=1, mode="constant", cval=np.nan)
    r0 = np.clip(np.floor(rows).astype(int), 0, a.shape[0] - 2)
    c0 = np.clip(np.floor(cols).astype(int), 0, a.shape[1] - 2)
    fr, fc = rows - r0, cols - c0
    v = (a[r0, c0] * (1 - fr) * (1 - fc) + a[r0 + 1, c0] * fr * (1 - fc) +
         a[r0, c0 + 1] * (1 - fr) * fc + a[r0 + 1, c0 + 1] * fr * fc)
    v[(rows < 0) | (cols < 0) | (rows > a.shape[0] - 1) | (cols > a.shape[1] - 1)] = np.nan
    return v


def cast_shadow(h: np.ndarray, mpp: float, sun_xyz: np.ndarray) -> np.ndarray:
    """True where the terrain blocks the Sun. Scan lines are run in a frame rotated so the Sun lies
    along +columns; the shadow test is a running maximum of (height - distance * tan(elevation))."""
    sx, sy, sz = sun_xyz
    el = math.atan2(sz, math.hypot(sx, sy))
    if el < -math.radians(10.0):  # far below any lunar horizon
        return np.ones_like(h, dtype=bool)
    if h.shape[0] != h.shape[1]:  # pad a rectangle to a square; NaN never casts a shadow
        n = max(h.shape)
        sq = np.full((n, n), np.nan, np.float32)
        sq[:h.shape[0], :h.shape[1]] = h
        return cast_shadow(sq, mpp, sun_xyz)[:h.shape[0], :h.shape[1]]
    # the Sun's direction in (col, row) space is (sx, -sy) (rows grow toward -y); the resampling
    # below maps the rotated grid's +column axis to (cos ang, -sin ang), so ang = atan2(sy, sx)
    ang = math.atan2(sy, sx)
    n = h.shape[0]
    d = int(math.ceil(n * math.sqrt(2)))
    cc, rr = np.meshgrid(np.arange(d) - d / 2, np.arange(d) - d / 2)
    cosa, sina = math.cos(ang), math.sin(ang)
    # rotated frame coords -> source pixel coords (rows grow downward = -y)
    src_c = cc * cosa + rr * sina + n / 2
    src_r = -cc * sina + rr * cosa + n / 2
    hr = resample(h, src_r.ravel(), src_c.ravel()).reshape(d, d)
    valid = ~np.isnan(hr)
    hr = np.where(valid, hr, -1e9)
    drop = np.tan(el) * mpp
    # walk from the Sun side (+x, i.e. high column index) toward the surface
    ramp = np.arange(d)[::-1] * drop  # subtract distance along the ray: point at column j is lit if
    rel = hr + ramp[None, :]  # no earlier (higher-column) sample has rel >= rel_here
    cum = np.maximum.accumulate(rel[:, ::-1], axis=1)[:, ::-1]
    shadow_r = np.zeros_like(rel, dtype=bool)
    shadow_r[:, :-1] = cum[:, 1:] > rel[:, :-1] + 1e-6
    # back to the source frame
    cols, rows = np.meshgrid(np.arange(n), np.arange(n))
    dc, dr = cols - n / 2, rows - n / 2
    rc = dc * cosa - dr * sina + d / 2
    rrr = dc * sina + dr * cosa + d / 2
    s = resample(shadow_r.astype(np.float32), rrr.ravel(), rc.ravel()).reshape(n, n)
    return np.nan_to_num(s, nan=0.0) > 0.5


def curved(h: np.ndarray, mpp: float, site_col: float, site_row: float) -> np.ndarray:
    """Heights in the site's tangent frame: h minus the sphere's drop (r^2 / 2R) at each pixel's
    distance r from the site, the same bend the Godot tiles carry, so a Sun given by its elevation
    above the site's horizontal (JPL Horizons) lights the grid as it lights the Moon."""
    rows, cols = h.shape
    xx = (np.arange(cols) - site_col) * mpp
    zz = (np.arange(rows) - site_row) * mpp
    return h - (xx[None, :] ** 2 + zz[:, None] ** 2) / (2.0 * R_MOON)


def hillshade(h: np.ndarray, mpp: float, sun_xyz: np.ndarray, shadows: bool = True, ambient: float = 0.0) -> np.ndarray:
    """0..1 Lambert shade with hard cast shadows (black sky: no ambient unless asked)."""
    nrm = normals(h, mpp)
    lam = np.clip(nrm @ (sun_xyz / np.linalg.norm(sun_xyz)), 0, 1)
    if shadows:
        lam = np.where(cast_shadow(h, mpp, sun_xyz), 0.0, lam)
    return np.clip(ambient + (1 - ambient) * lam, 0, 1)


def hillshade_45(h: np.ndarray, mpp: float) -> np.ndarray:
    """Same convention as the PGDA _HILL product (45 deg altitude, 45 deg azimuth, no cast shadows)."""
    s = np.array([math.cos(math.radians(45)) * math.sin(math.radians(45)), math.cos(math.radians(45)) * math.cos(math.radians(45)), math.sin(math.radians(45))])
    return hillshade(h, mpp, s, shadows=False)


# ---------------------------------------------------------------- PNG writer (stdlib)

def write_png(path: Path, img: np.ndarray) -> None:
    """8-bit grey (H,W), 8-bit RGB (H,W,3) or 16-bit grey (H,W uint16)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if img.dtype == np.uint16:
        ctype, depth, raw = 0, 16, img.astype(">u2").tobytes()
        stride = img.shape[1] * 2
    elif img.ndim == 2:
        ctype, depth, raw = 0, 8, img.astype(np.uint8).tobytes()
        stride = img.shape[1]
    else:
        ctype, depth, raw = 2, 8, img.astype(np.uint8).tobytes()
        stride = img.shape[1] * 3
    rows = b"".join(b"\0" + raw[i * stride:(i + 1) * stride] for i in range(img.shape[0]))

    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", img.shape[1], img.shape[0], depth, ctype, 0, 0, 0)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(rows, 6)) + chunk(b"IEND", b""))


def to_u8(a: np.ndarray) -> np.ndarray:
    return np.clip(np.nan_to_num(a) * 255 + 0.5, 0, 255).astype(np.uint8)


# ---------------------------------------------------------------- sites

def sites_path() -> Path:
    return TERRAIN / "sites.json"


def load_sites() -> dict:
    p = sites_path()
    if not p.exists():
        sys.exit("sites.json missing: run `make_terrain.py sites` first")
    return read_json(p)


def pick_highest(product_id: str, cx: float, cy: float, radius_m: float) -> dict:
    rd = reader(product_id)
    size = 2 * radius_m + 4 * rd.mpp
    a, geo = window_m(product_id, cx, cy, size)
    n = a.shape[0]
    cols, rows = np.meshgrid(np.arange(n), np.arange(n))
    x = geo["origin_x_m"] + cols * rd.mpp
    y = geo["origin_y_m"] - rows * rd.mpp
    inside = np.hypot(x - cx, y - cy) <= radius_m
    a = np.where(inside, a, np.nan)
    r, c = np.unravel_index(np.nanargmax(a), a.shape)
    lat, lon = xy_to_latlon(float(x[r, c]), float(y[r, c]))
    return {"x_m": float(x[r, c]), "y_m": float(y[r, c]), "height_m": float(a[r, c]), "lat_deg": lat, "lon_deg_east": lon, "product": product_id}


def label_components(mask: np.ndarray) -> tuple[np.ndarray, int]:
    if _ndimage is not None:
        lab, n = _ndimage.label(mask)
        return lab, int(n)
    lab = np.zeros(mask.shape, np.int32)
    n = 0
    for r, c in zip(*np.nonzero(mask)):
        if lab[r, c]:
            continue
        n += 1
        stack = [(r, c)]
        lab[r, c] = n
        while stack:
            a, b = stack.pop()
            for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                aa, bb = a + da, b + db
                if 0 <= aa < mask.shape[0] and 0 <= bb < mask.shape[1] and mask[aa, bb] and not lab[aa, bb]:
                    lab[aa, bb] = n
                    stack.append((aa, bb))
    return lab, n


def dijkstra_route(h: np.ndarray, mpp: float, start: tuple[int, int], goals: np.ndarray, slope_limit: float,
                   hard_limit: float | None = None, steep_penalty: float = 25.0):
    """Least-cost path on an 8-connected grid; the cost of a step grows mildly with slope so the road
    prefers gentle ground. Cells steeper than slope_limit are impassable, unless hard_limit is given:
    then cells up to hard_limit are passable at steep_penalty times the cost, so the road leaves the
    preferred limit only where no gentler way exists. goals: bool array.
    Returns (path [(row, col)...], length_m) to the first goal reached, or (None, inf)."""
    n_rows, n_cols = h.shape
    slope = slope_deg(h, mpp)
    blocked = slope > (hard_limit if hard_limit is not None else slope_limit)
    weight = 1.0 + (slope / slope_limit) ** 2
    if hard_limit is not None:
        weight = np.where(slope > slope_limit, weight * steep_penalty, weight)
    dist = np.full(h.shape, np.inf)
    prev = np.full(h.shape + (2,), -1, np.int32)
    dist[start] = 0.0
    pq = [(0.0, start)]
    steps = [(dr, dc, math.hypot(dr, dc) * mpp) for dr in (-1, 0, 1) for dc in (-1, 0, 1) if dr or dc]
    goal_hit = None
    while pq:
        d, (r, c) = heapq.heappop(pq)
        if d > dist[r, c]:
            continue
        if goals[r, c]:
            goal_hit = (r, c)
            break
        for dr, dc, step in steps:
            rr, cc = r + dr, c + dc
            if rr < 0 or cc < 0 or rr >= n_rows or cc >= n_cols or blocked[rr, cc]:
                continue
            nd = d + step * 0.5 * (weight[r, c] + weight[rr, cc])
            if nd < dist[rr, cc]:
                dist[rr, cc] = nd
                prev[rr, cc] = (r, c)
                heapq.heappush(pq, (nd, (rr, cc)))
    if goal_hit is None:
        return None, math.inf
    path = []
    cur = goal_hit
    while cur != start:
        path.append(cur)
        cur = tuple(prev[cur])
    path.append(start)
    path.reverse()
    length = sum(math.hypot(a[0] - b[0], a[1] - b[1]) * mpp for a, b in zip(path, path[1:]))
    return path, length


def path_profile(path, h: np.ndarray, mpp: float, geo: dict, slope_limit: float = 90.0) -> dict:
    """Polyline of a grid path in map metres with height, distance and slope per point, plus totals:
    length, steepest cell, total climb and descent, and the length over slope_limit."""
    slope = slope_deg(h, mpp)
    pts = []
    dist = 0.0
    over = 0.0
    for i, (r, c) in enumerate(path):
        if i:
            pr, pc = path[i - 1]
            step = math.hypot(r - pr, c - pc) * mpp
            dist += step
            if max(slope[r, c], slope[pr, pc]) > slope_limit:
                over += step
        pts.append([round(geo["origin_x_m"] + c * mpp, 1), round(geo["origin_y_m"] - r * mpp, 1), round(float(h[r, c]), 1), round(dist, 1), round(float(slope[r, c]), 2)])
    return {"columns": ["x_m", "y_m", "height_m", "distance_m", "slope_deg"], "points": pts,
            "length_m": round(dist, 1), "max_slope_deg": round(max(p[4] for p in pts), 2),
            "climb_m": round(sum(max(0.0, b[2] - a[2]) for a, b in zip(pts, pts[1:])), 1),
            "descent_m": round(sum(max(0.0, a[2] - b[2]) for a, b in zip(pts, pts[1:])), 1),
            "length_over_limit_m": round(over, 1)}


def cmd_sites() -> None:
    S = CFG["sites"]
    out = {"about": "Story sites pinned on the real LOLA terrain by make_terrain.py sites; rules in regions.json. Coordinates: south polar stereographic metres (MOON_ME/DE421), heights above the 1,737.4 km sphere.", "computed": TODAY, "sites": {}}
    # Aurora: ridge crest near the PGDA Site01 centre
    a = S["aurora"]
    au = pick_highest("pgda78_site01", *a["search_center_xy_m"], a["search_radius_m"])
    au.update({"name": a["name"], "rule": a["rule"], "mast_height_m": a["mast_height_m"]})
    out["sites"]["aurora"] = au
    log(f"aurora: x={au['x_m']:.0f} y={au['y_m']:.0f} h={au['height_m']:.1f} lat={au['lat_deg']:.4f} lon={au['lon_deg_east']:.4f}")
    # Malapert: highest point of the massif near the IAU centre
    m = S["malapert_summit"]
    mx, my = latlon_to_xy(*m["search_center_latlon"])
    ms = pick_highest("pgda78_site23", mx, my, m["search_radius_m"])
    ms.update({"name": m["name"], "rule": m["rule"], "iau_center_xy_m": [mx, my]})
    out["sites"]["malapert_summit"] = ms
    log(f"malapert_summit: x={ms['x_m']:.0f} y={ms['y_m']:.0f} h={ms['height_m']:.1f} lat={ms['lat_deg']:.4f} lon={ms['lon_deg_east']:.4f}")
    # Cold trap: PSR candidates around Aurora on the 20 m grid, reached by a slope-limited road
    c = S["cold_trap"]
    box = 2 * c["max_route_km"] * 1000 + 4000
    psr, geo = window_m("pgda90_20mpp_psr", au["x_m"], au["y_m"], box)
    dem, _ = window_m("pgda90_20mpp", au["x_m"], au["y_m"], box)
    dem = fill_nan(dem)
    mpp = geo["mpp"]
    mask = np.nan_to_num(psr) > 0.5
    lab, ncomp = label_components(mask)
    n = dem.shape[0]
    cols, rows = np.meshgrid(np.arange(n), np.arange(n))
    x = geo["origin_x_m"] + cols * mpp
    y = geo["origin_y_m"] - rows * mpp
    sx, sy = c["shackleton_center_xy_m"]
    near_shackleton = np.hypot(x - sx, y - sy) < c["shackleton_exclude_radius_m"]
    start = (geo["center_row"], geo["center_col"])
    candidates = []
    areas = np.bincount(lab.ravel())
    for k in range(1, ncomp + 1):
        area_km2 = areas[k] * mpp * mpp / 1e6
        if not (c["min_area_km2"] <= area_km2 <= c["max_area_km2"]):
            continue
        comp = lab == k
        if near_shackleton[comp].any():
            continue
        rr, cc = np.nonzero(comp)
        dmin = np.hypot(x[rr, cc] - au["x_m"], y[rr, cc] - au["y_m"]).min()
        if dmin > c["max_route_km"] * 1000:
            continue
        candidates.append((k, area_km2, float(dmin)))
    candidates.sort(key=lambda t: t[2])
    log(f"cold trap: {len(candidates)} PSR candidates of {c['min_area_km2']}-{c['max_area_km2']} km2 within {c['max_route_km']} km straight-line")
    # route to each candidate (grid downsampled 2x for speed), keep the one closest to the story's 12 km
    ds = 2
    dem2 = dem[::ds, ::ds]
    best = None
    for k, area_km2, dmin in candidates[:12]:
        goals = (lab == k)[::ds, ::ds]
        path, length = dijkstra_route(dem2, mpp * ds, (start[0] // ds, start[1] // ds), goals, c["slope_limit_deg"])
        if path is None:
            log(f"  PSR #{k}: {area_km2:.2f} km2, {dmin / 1000:.1f} km away: no road within {c['slope_limit_deg']} deg")
            continue
        score = abs(length / 1000 - c["target_route_km"])
        log(f"  PSR #{k}: {area_km2:.2f} km2, {dmin / 1000:.1f} km away: road {length / 1000:.1f} km")
        if best is None or score < best[0]:
            best = (score, k, area_km2, dmin, path, length)
    if best is None:
        sys.exit("no reachable PSR candidate; relax the rule in regions.json")
    _, k, area_km2, dmin, path, length = best
    comp = lab == k
    rr, cc = np.nonzero(comp)
    low = np.argmin(dem[rr, cc])
    r, cidx = int(rr[low]), int(cc[low])
    lat, lon = xy_to_latlon(float(x[r, cidx]), float(y[r, cidx]))
    ct = {"name": c["name"], "rule": c["rule"], "x_m": float(x[r, cidx]), "y_m": float(y[r, cidx]), "height_m": float(dem[r, cidx]),
          "lat_deg": lat, "lon_deg_east": lon, "product": "pgda90_20mpp + pgda90_20mpp_psr", "psr_component": int(k),
          "psr_area_km2": round(area_km2, 3), "straight_line_from_aurora_m": round(dmin, 0), "selection_road_length_m": round(length, 0),
          "selection_grid_mpp": mpp * ds,
          "psr_centroid_xy_m": [float(x[rr, cc].mean()), float(y[rr, cc].mean())],
          "psr_bbox_xy_m": [float(x[rr, cc].min()), float(x[rr, cc].max()), float(y[rr, cc].min()), float(y[rr, cc].max())]}
    out["sites"]["cold_trap"] = ct
    log(f"cold_trap: PSR #{k} {area_km2:.2f} km2 at x={ct['x_m']:.0f} y={ct['y_m']:.0f} h={ct['height_m']:.1f}, road {length / 1000:.1f} km")
    write_json(sites_path(), out)
    log(f"wrote {sites_path().relative_to(ROOT)}")


# ---------------------------------------------------------------- heightmaps

def region_source(region: dict, site: dict) -> str:
    half = region["size_m"] / 2
    for pid in region["sources"]:
        p = CFG["products"][pid]
        if p["mpp"] != region["mpp"]:
            continue
        if p["kind"] == "strip_tiff":
            rd = reader(pid)
            if rd.contains(site["x_m"] - half, site["x_m"] + half, site["y_m"] + half, site["y_m"] - half):
                return pid
        else:
            return pid
    # fall back to the first coarser product and record the change
    for pid in region["sources"]:
        if CFG["products"][pid]["kind"] == "cog":
            return pid
    raise RuntimeError(f"{region['id']}: no source covers the window")


def encode_r16(h: np.ndarray) -> tuple[np.ndarray, float, float]:
    zmin, zmax = float(np.nanmin(h)), float(np.nanmax(h))
    span = max(zmax - zmin, 1e-6)
    q = np.clip(np.round((h - zmin) / span * 65535.0), 0, 65535).astype("<u2")
    return q, zmin, zmax


def region_dir(region_id: str) -> Path:
    return GAME_LOLA / region_id


def corridor_bounds(region: dict, a: dict, b: dict, routes: dict) -> tuple[float, float, float, float]:
    """(along_min, along_max, across_min, across_max) in metres from site a along the straight line
    to b: the region's half width around the line, widened to hold every point of the computed road
    between the same sites plus a 4 km margin, so the road always lies on the heightmap."""
    hw = float(region["half_width_m"])
    length = math.hypot(b["x_m"] - a["x_m"], b["y_m"] - a["y_m"])
    lo_a, hi_a, lo_c, hi_c = -hw, length + hw, -hw, hw
    ux, uy = (b["x_m"] - a["x_m"]) / length, (b["y_m"] - a["y_m"]) / length
    for r in routes.values():
        if r.get("from") != region["from"] or r.get("to") != region["to"]:
            continue
        for p in r["points"]:
            al = (p[0] - a["x_m"]) * ux + (p[1] - a["y_m"]) * uy
            ac = -(p[0] - a["x_m"]) * uy + (p[1] - a["y_m"]) * ux
            lo_a, hi_a = min(lo_a, al - 4000.0), max(hi_a, al + 4000.0)
            lo_c, hi_c = min(lo_c, ac - 4000.0), max(hi_c, ac + 4000.0)
    return lo_a, hi_a, lo_c, hi_c


def cmd_heightmaps() -> None:
    sites = load_sites()["sites"]
    routes = read_json(TERRAIN / "routes.json").get("routes", {}) if (TERRAIN / "routes.json").exists() else {}
    manifest = {"regions": {}}
    for region in CFG["regions"]:
        rid = region["id"]
        if region["kind"] == "corridor":
            a, b = sites[region["from"]], sites[region["to"]]
            length = math.hypot(b["x_m"] - a["x_m"], b["y_m"] - a["y_m"])
            ux, uy = (b["x_m"] - a["x_m"]) / length, (b["y_m"] - a["y_m"]) / length
            lo_a, hi_a, lo_c, hi_c = corridor_bounds(region, a, b, routes)
            # a square window around the centre of the along/across rectangle that holds all of it
            ma, mc = (lo_a + hi_a) / 2, (lo_c + hi_c) / 2
            cx, cy = a["x_m"] + ma * ux - mc * uy, a["y_m"] + ma * uy + mc * ux
            size = 2 * math.hypot((hi_a - lo_a) / 2, (hi_c - lo_c) / 2) + 4 * region["mpp"]
            pid = region["sources"][0]
            h, geo = window_m(pid, cx, cy, size, region["mpp"])
            # trim to the rectangle (keeps the file small)
            rd = reader(pid)
            n = h.shape[0]
            cols, rows = np.meshgrid(np.arange(n), np.arange(n))
            x = geo["origin_x_m"] + cols * rd.mpp
            y = geo["origin_y_m"] - rows * rd.mpp
            along = (x - a["x_m"]) * ux + (y - a["y_m"]) * uy
            across = -(x - a["x_m"]) * uy + (y - a["y_m"]) * ux
            keep = (along >= lo_a) & (along <= hi_a) & (across >= lo_c) & (across <= hi_c)
            rr, cc = np.nonzero(keep)
            r0, r1, c0, c1 = rr.min(), rr.max() + 1, cc.min(), cc.max() + 1
            h = h[r0:r1, c0:c1]
            geo.update({"rows": int(r1 - r0), "cols": int(c1 - c0), "col0": geo["col0"] + int(c0), "row0": geo["row0"] + int(r0),
                        "origin_x_m": geo["origin_x_m"] + c0 * rd.mpp, "origin_y_m": geo["origin_y_m"] - r0 * rd.mpp})
            site = a
        else:
            site = sites[region["site"]]
            pid = region_source(region, site)
            h, geo = window_m(pid, site["x_m"], site["y_m"], region["size_m"], CFG["products"][pid]["mpp"])
        nan_frac = float(np.isnan(h).mean())
        h = fill_nan(h)
        q, zmin, zmax = encode_r16(h)
        d = region_dir(rid)
        d.mkdir(parents=True, exist_ok=True)
        mpp = geo["mpp"]
        name = f"heightmap_{int(mpp)}m"
        (d / f"{name}.r16").write_bytes(q.tobytes())
        # site position inside the window (pixel) and in Godot metres relative to the site
        sc = (site["x_m"] - geo["origin_x_m"]) / mpp
        sr = (geo["origin_y_m"] - site["y_m"]) / mpp
        meta = {
            "region": rid, "kind": region["kind"], "story": region["story"], "source_product": pid,
            "source_title": CFG["products"][pid]["title"], "source_url": CFG["products"][pid]["url"],
            "retrieved": TODAY, "format": "r16: little-endian uint16, row-major, top row first (north = toward 0 deg E is up); height_m = z_min_m + value * (z_max_m - z_min_m) / 65535",
            "columns": int(geo["cols"]), "rows": int(geo["rows"]), "metres_per_pixel": mpp,
            "z_min_m": round(zmin, 3), "z_max_m": round(zmax, 3), "height_datum": "metres above the 1,737.4 km reference sphere (LOLA)",
            "projection": "south polar stereographic, MOON_ME (DE421); x toward 90E, y toward 0E, pole at (0,0)",
            "origin_x_m": geo["origin_x_m"], "origin_y_m": geo["origin_y_m"], "origin_note": "map coordinates of the centre of pixel (column 0, row 0)",
            "source_window": {"col0": int(geo["col0"]), "row0": int(geo["row0"])}, "interpolated_nan_fraction": round(nan_frac, 5),
            "site": {"id": region.get("site", region.get("from")), "x_m": site["x_m"], "y_m": site["y_m"], "height_m": site["height_m"],
                     "lat_deg": site["lat_deg"], "lon_deg_east": site["lon_deg_east"], "pixel_col": round(sc, 3), "pixel_row": round(sr, 3)},
            "godot": {"frame": "X = map x - site x; Z = -(map y - site y); Y = height - site height (site at the origin, metres)",
                      "x_of_col": "origin_x_m + col * metres_per_pixel - site.x_m", "z_of_row": "-(origin_y_m - row * metres_per_pixel - site.y_m)"},
            "sha256_r16": sha256(d / f"{name}.r16"),
        }
        write_json(d / f"{name}.json", meta)
        manifest["regions"][rid] = {"heightmap": f"{rid}/{name}.r16", "meta": f"{rid}/{name}.json", "mpp": mpp, "columns": meta["columns"], "rows": meta["rows"]}
        log(f"{rid}: {pid} {meta['columns']}x{meta['rows']} @ {mpp} m, z {zmin:.0f}..{zmax:.0f} m, nan {nan_frac:.4%}")
    write_json(TERRAIN / "heightmaps_index.json", manifest)


# ---------------------------------------------------------------- routes

def cmd_routes() -> None:
    sites = load_sites()["sites"]
    out = {"about": "Slope-limited least-cost roads on the LOLA grids (Computed; the game's P-07 and P-15 numbers are unchanged canon).", "computed": TODAY, "routes": {}}
    for route in CFG["routes"]:
        a, b = sites[route["from"]], sites[route["to"]]
        pid = route["grid"]
        rd = reader(pid)
        length = math.hypot(b["x_m"] - a["x_m"], b["y_m"] - a["y_m"])
        cx, cy = (a["x_m"] + b["x_m"]) / 2, (a["y_m"] + b["y_m"]) / 2
        # keep the search inside a corridor around the straight line: a full-window search on the
        # relay road's ~200 km square would take minutes for no gain
        margin = float(route.get("corridor_half_width_m", 6000.0))
        size = length + 2 * margin
        h, geo = window_m(pid, cx, cy, size)
        h = fill_nan(h)
        mpp = geo["mpp"]
        ds = max(1, int(round(float(route.get("route_mpp", mpp)) / mpp)))  # route grid; 1 = the product's own grid
        hs = h[::ds, ::ds]
        gm = mpp * ds

        def px(site):
            return int(round((geo["origin_y_m"] - site["y_m"]) / gm)), int(round((site["x_m"] - geo["origin_x_m"]) / gm))

        start, goal = px(a), px(b)
        cols, rows = np.meshgrid(np.arange(hs.shape[1]), np.arange(hs.shape[0]))
        xg = geo["origin_x_m"] + cols * gm
        yg = geo["origin_y_m"] - rows * gm
        ux, uy = (b["x_m"] - a["x_m"]) / length, (b["y_m"] - a["y_m"]) / length
        across = -(xg - a["x_m"]) * uy + (yg - a["y_m"]) * ux
        hs = np.where(np.abs(across) <= margin, hs, 1.0e6)  # a cliff outside the corridor
        goals = np.zeros(hs.shape, bool)
        goals[max(0, goal[0] - 1):goal[0] + 2, max(0, goal[1] - 1):goal[1] + 2] = True
        if route["id"] == "cold_trap_road":  # the road ends at the PSR edge, not the floor
            psr, _ = window_m("pgda90_20mpp_psr", cx, cy, size)
            goals = (np.nan_to_num(psr) > 0.5)[::ds, ::ds]
            bb = sites["cold_trap"]["psr_bbox_xy_m"]
            goals &= (xg >= bb[0] - gm) & (xg <= bb[1] + gm) & (yg >= bb[2] - gm) & (yg <= bb[3] + gm)
        t0 = time.time()
        limit, hard = route["slope_limit_deg"], route.get("hard_limit_deg")
        path, plen = dijkstra_route(hs, gm, start, goals, limit)
        used_hard = False
        if path is None and hard is not None:
            log(f"{route['id']}: no road within {limit} deg; allowing up to {hard} deg where no gentler way exists")
            path, plen = dijkstra_route(hs, gm, start, goals, limit, hard_limit=hard)
            used_hard = True
        if path is None:
            log(f"{route['id']}: no road within {hard if used_hard else limit} deg")
            continue
        geo_s = dict(geo, mpp=gm)
        prof = path_profile(path, hs, gm, geo_s, limit)
        prof.update({"from": route["from"], "to": route["to"], "grid_product": pid, "grid_mpp_used": gm, "slope_limit_deg": limit,
                     "hard_limit_deg": hard if used_hard else None, "corridor_half_width_m": margin,
                     "straight_line_m": round(length, 1), "story": route["story"], "seconds": round(time.time() - t0, 1)})
        # thin the polyline for the data file to about 320 m spacing (always keeping the last point)
        keep = max(1, int(round(320.0 / gm)))
        prof["points"] = prof["points"][::keep] + ([prof["points"][-1]] if (len(prof["points"]) - 1) % keep else [])
        out["routes"][route["id"]] = prof
        log(f"{route['id']}: {prof['length_m'] / 1000:.1f} km on {gm:.0f} m (straight {length / 1000:.1f} km), max slope {prof['max_slope_deg']:.1f} deg, "
            f"{prof['length_over_limit_m'] / 1000:.2f} km over {limit} deg, climb {prof['climb_m']:.0f} m, descent {prof['descent_m']:.0f} m, {prof['seconds']} s")
    # midpoint of the relay road for the Chapter 8 road scenes
    if "relay_road" in out["routes"]:
        pts = out["routes"]["relay_road"]["points"]
        half = out["routes"]["relay_road"]["length_m"] / 2
        mid = min(pts, key=lambda p: abs(p[3] - half))
        lat, lon = xy_to_latlon(mid[0], mid[1])
        out["relay_road_mid"] = {"x_m": mid[0], "y_m": mid[1], "height_m": mid[2], "lat_deg": lat, "lon_deg_east": lon, "distance_m": mid[3]}
    write_json(TERRAIN / "routes.json", out)
    log(f"wrote {(TERRAIN / 'routes.json').relative_to(ROOT)}")


# ---------------------------------------------------------------- horizon and Sun

def horizon_mask(x: float, y: float, h0: float, n_az: int = 360, eye_m: float = 2.0) -> np.ndarray:
    """Elevation angle (deg) of the terrain horizon for each azimuth (from local north through east),
    sampled on the 40 m data to 32 km and the 80 m data to 100 km, with the sphere's curvature
    subtracted (horizon_mask_hero adds the 5/10 m hero data). The eye is eye_m above the surface."""
    eye = h0 + eye_m
    legs = [("hero", 4000.0, None), ("pgda90_40mpp", 32000.0, 40.0), ("pgda90_80mpp", 100000.0, 80.0)]
    az = np.radians(np.arange(n_az) * 360.0 / n_az)
    n, e = local_axes(x, y)
    dirs = np.outer(np.cos(az), n) + np.outer(np.sin(az), e)  # (n_az, 2) map direction per azimuth
    best = np.full(n_az, -90.0)
    for name, reach, mpp in legs:
        if name == "hero":
            continue  # the hero grids are sampled by the caller through sample_horizon_leg
        rd = reader(name)
        h, geo = window_m(name, x, y, 2 * reach + 4 * rd.mpp)
        h = fill_nan(h)
        step = rd.mpp
        d = np.arange(step, reach + step, step)
        px = x + dirs[:, 0:1] * d[None, :]
        py = y + dirs[:, 1:2] * d[None, :]
        rows = (geo["origin_y_m"] - py) / rd.mpp
        cols = (px - geo["origin_x_m"]) / rd.mpp
        hs = resample(h, rows.ravel(), cols.ravel()).reshape(px.shape)
        drop = d ** 2 / (2 * R_MOON)
        ang = np.degrees(np.arctan2(hs - eye - drop[None, :], d[None, :]))
        ang = np.where(np.isnan(ang), -90.0, ang)
        best = np.maximum(best, np.nanmax(ang, axis=1))
    return best


def horizon_mask_hero(x: float, y: float, h0: float, hero_h: np.ndarray, geo: dict, n_az: int = 360, eye_m: float = 2.0) -> np.ndarray:
    """Terrain horizon (deg per azimuth) from the hero heightmap around the site, to its edge."""
    eye = h0 + eye_m
    mpp = geo["mpp"]
    reach = min(geo["cols"], geo["rows"]) * mpp / 2 - 2 * mpp
    az = np.radians(np.arange(n_az) * 360.0 / n_az)
    n, e = local_axes(x, y)
    dirs = np.outer(np.cos(az), n) + np.outer(np.sin(az), e)
    d = np.arange(mpp, reach, mpp)
    px = x + dirs[:, 0:1] * d[None, :]
    py = y + dirs[:, 1:2] * d[None, :]
    rows = (geo["origin_y_m"] - py) / mpp
    cols = (px - geo["origin_x_m"]) / mpp
    hs = resample(hero_h, rows.ravel(), cols.ravel()).reshape(px.shape)
    drop = d ** 2 / (2 * R_MOON)
    ang = np.degrees(np.arctan2(hs - eye - drop[None, :], d[None, :]))
    ang = np.where(np.isnan(ang), -90.0, ang)
    return np.nanmax(ang, axis=1)


def horizons(target: int, lon: float, lat: float, alt_km: float, start: str, stop: str, step: str):
    q = {"format": "json", "COMMAND": f"'{target}'", "OBJ_DATA": "'NO'", "MAKE_EPHEM": "'YES'",
         "EPHEM_TYPE": "'OBSERVER'", "CENTER": "'coord@301'", "COORD_TYPE": "'GEODETIC'",
         "SITE_COORD": f"'{lon:.5f},{lat:.5f},{alt_km:.4f}'", "START_TIME": f"'{start}'", "STOP_TIME": f"'{stop}'",
         "STEP_SIZE": f"'{step}'", "QUANTITIES": "'4'", "ANG_FORMAT": "'DEG'", "CSV_FORMAT": "'YES'"}
    url = HORIZONS + "?" + urllib.parse.urlencode(q)
    cache = CACHE / "horizons" / (hashlib.sha1(url.encode()).hexdigest() + ".json")
    cache.parent.mkdir(parents=True, exist_ok=True)
    if cache.exists():
        res = read_json(cache)["result"]
    else:
        res = json.loads(http_get(url).decode("utf-8"))
        write_json(cache, res)
        res = res["result"]
    body = res[res.index("$$SOE") + 5:res.index("$$EOE")].strip().splitlines()
    rows = []
    for ln in body:
        c = [v.strip() for v in ln.split(",")]
        t = dt.datetime.strptime(c[0], "%Y-%b-%d %H:%M")
        rows.append((t, float(c[3]), float(c[4])))
    return url, rows


def heightmap_for_site(site_id: str) -> tuple[np.ndarray, dict] | tuple[None, None]:
    for region in CFG["regions"]:
        if region["kind"] == "hero" and region.get("site") == site_id:
            d = region_dir(region["id"])
            metas = sorted(d.glob("heightmap_*m.json"))
            if not metas:
                return None, None
            meta = read_json(metas[0])
            q = np.frombuffer((d / (metas[0].stem + ".r16")).read_bytes(), dtype="<u2").reshape(meta["rows"], meta["columns"])
            h = meta["z_min_m"] + q.astype(np.float32) * (meta["z_max_m"] - meta["z_min_m"]) / 65535.0
            geo = {"mpp": meta["metres_per_pixel"], "cols": meta["columns"], "rows": meta["rows"], "origin_x_m": meta["origin_x_m"], "origin_y_m": meta["origin_y_m"]}
            return h, geo
    return None, None


def longest_runs(flags: list, stamps: list) -> dict:
    """Longest run of consecutive True flags in an hourly series: {"hours", "from", "to"} (UTC of the
    first and last hour in the run), or hours 0 when there is none."""
    best = (0, None, None)
    start, n = None, 0
    for flag, t in zip(flags, stamps):
        if flag:
            start = t if n == 0 else start
            n += 1
            if n > best[0]:
                best = (n, start, t)
        else:
            n = 0
    return {"hours": best[0], "from": best[1], "to": best[2]}


def cmd_sun() -> None:
    sites = dict(load_sites()["sites"])
    routes = read_json(TERRAIN / "routes.json") if (TERRAIN / "routes.json").exists() else {}
    if "relay_road_mid" in routes:
        sites["relay_road_mid"] = dict(routes["relay_road_mid"], name="Relay road midpoint (computed road)")
    windows = list(CFG["sun_windows"])
    if "relay_road_mid" in sites:
        windows.append({"id": "ch08_road_mid", "site": "relay_road_mid", "start": "2047-04-07 00:00", "stop": "2047-04-11 00:00", "step": "1 h", "scenes": "EX-CH08-S03..S04 road scenes"})
    out = {"about": "Sun and Earth azimuth/elevation from JPL Horizons (DE441; airless apparent, i.e. light-time and aberration corrected, no refraction; site in the MEAN_ME frame on the 1,737.4 km sphere like LOLA) at the pinned story sites, hourly, plus whether each body's centre clears the local LOLA terrain horizon seen from a 2 m eye (Computed). Azimuth is degrees from local north through east; elevation is degrees above the local horizontal. Use sun_direction() in terrain_heightfield.gd to turn a row into a Godot light direction.",
           "retrieved": TODAY, "citation": "JPL Horizons On-Line Ephemeris System, https://ssd.jpl.nasa.gov/horizons/ ; LOLA horizon from PGDA products 78 and 90",
           "columns": ["utc", "sun_az_deg", "sun_el_deg", "earth_az_deg", "earth_el_deg", "sun_above_terrain", "earth_above_terrain"],
           "sites": {}, "windows": {}, "scene_lighting": []}
    masks = {}
    mast_masks = {}
    for sid, site in sites.items():
        hero_h, geo = heightmap_for_site(sid)
        mask = horizon_mask(site["x_m"], site["y_m"], site["height_m"])
        if hero_h is not None:
            mask = np.maximum(mask, horizon_mask_hero(site["x_m"], site["y_m"], site["height_m"], hero_h, geo))
        masks[sid] = mask
        if "mast_height_m" in site and hero_h is not None:  # the solar array's lower edge, for power
            mh = float(site["mast_height_m"])
            mast_masks[sid] = np.maximum(horizon_mask(site["x_m"], site["y_m"], site["height_m"], eye_m=mh),
                                         horizon_mask_hero(site["x_m"], site["y_m"], site["height_m"], hero_h, geo, eye_m=mh))
        out["sites"][sid] = {"name": site.get("name", sid), "lat_deg": round(site["lat_deg"], 5), "lon_deg_east": round(site["lon_deg_east"], 5), "height_m": round(site["height_m"], 1),
                             "x_m": round(site["x_m"], 1), "y_m": round(site["y_m"], 1),
                             "terrain_horizon_deg_by_azimuth": [round(float(v), 2) for v in mask],
                             "horizon_note": "elevation of the LOLA terrain horizon at 1 deg azimuth steps from a 2 m eye height; hero data to 4 km, 40 m data to 32 km, 80 m data to 100 km, curvature removed"}
        if sid in mast_masks:
            out["sites"][sid]["mast_height_m"] = site["mast_height_m"]
            out["sites"][sid]["mast_horizon_deg_by_azimuth"] = [round(float(v), 2) for v in mast_masks[sid]]
        log(f"{sid}: terrain horizon {mask.min():.2f}..{mask.max():.2f} deg" + (f"; at the {site['mast_height_m']} m mast {mast_masks[sid].min():.2f}..{mast_masks[sid].max():.2f} deg" if sid in mast_masks else ""))

    def above(mask, az, el):
        i = int(round(az)) % 360
        return bool(el > mask[i])

    for w in windows:
        site = sites[w["site"]]
        u1, sun = horizons(10, site["lon_deg_east"], site["lat_deg"], site["height_m"] / 1000.0, w["start"], w["stop"], w["step"])
        u2, earth = horizons(399, site["lon_deg_east"], site["lat_deg"], site["height_m"] / 1000.0, w["start"], w["stop"], w["step"])
        mask = masks[w["site"]]
        rows = []
        for (t, saz, sel), (t2, eaz, eel) in zip(sun, earth):
            assert t == t2
            rows.append([t.strftime("%Y-%m-%dT%H:%MZ"), round(saz, 3), round(sel, 3), round(eaz, 3), round(eel, 3), above(mask, saz, sel), above(mask, eaz, eel)])
        lit = sum(1 for r in rows if r[5])
        dark_runs = longest_runs([not r[5] for r in rows], [r[0] for r in rows])
        out["windows"][w["id"]] = {"site": w["site"], "scenes": w["scenes"], "request_urls": [u1, u2], "rows": rows,
                                   "sun_above_terrain_hours": lit, "hours": len(rows), "longest_sun_below_terrain": dark_runs}
        if w["site"] in mast_masks:
            mm = mast_masks[w["site"]]
            mast_lit = [above(mm, r[1], r[2]) for r in rows]
            out["windows"][w["id"]]["mast"] = {"height_m": sites[w["site"]]["mast_height_m"], "sun_above_terrain_hours": sum(mast_lit),
                                               "longest_sun_below_terrain": longest_runs([not v for v in mast_lit], [r[0] for r in rows])}
        log(f"{w['id']}: {len(rows)} rows, Sun el {min(r[2] for r in rows):.2f}..{max(r[2] for r in rows):.2f}, lit {lit}/{len(rows)} h; Earth el {min(r[4] for r in rows):.2f}..{max(r[4] for r in rows):.2f}")
    for s in CFG["scene_lighting"]:
        if s["site"] not in sites:
            continue
        site = sites[s["site"]]
        t = dt.datetime.strptime(s["utc"], "%Y-%m-%d %H:%M")
        u1, sun = horizons(10, site["lon_deg_east"], site["lat_deg"], site["height_m"] / 1000.0, s["utc"], (t + dt.timedelta(minutes=1)).strftime("%Y-%m-%d %H:%M"), "1 m")
        u2, earth = horizons(399, site["lon_deg_east"], site["lat_deg"], site["height_m"] / 1000.0, s["utc"], (t + dt.timedelta(minutes=1)).strftime("%Y-%m-%d %H:%M"), "1 m")
        mask = masks[s["site"]]
        hp = s.get("horizon_from")  # a scene staged away from its ephemeris site (M1-88: the CH04-S04 ridge, 146 m above the
        if hp:                      # cold-trap floor) takes its terrain horizon where it stands; Sun/Earth directions stay the site's
            hero_h, geo = heightmap_for_site(s["site"])
            mask = horizon_mask(hp["x_m"], hp["y_m"], hp["height_m"])
            if hero_h is not None:
                mask = np.maximum(mask, horizon_mask_hero(hp["x_m"], hp["y_m"], hp["height_m"], hero_h, geo))
        saz, sel = sun[0][1], sun[0][2]
        eaz, eel = earth[0][1], earth[0][2]
        hz = float(mask[int(round(saz)) % 360])
        state = "lit" if sel - SUN_RADIUS_DEG > hz else "dark" if sel + SUN_RADIUS_DEG < hz else "partial"
        out["scene_lighting"].append({"scene": s["scene"], "site": s["site"], "utc": s["utc"], "note": s["note"], "sun_az_deg": round(saz, 3), "sun_el_deg": round(sel, 3),
                                      "terrain_horizon_deg": round(hz, 2), "sun_state": state, "earth_az_deg": round(eaz, 3), "earth_el_deg": round(eel, 3),
                                      "earth_above_terrain": above(mask, eaz, eel), "request_urls": [u1, u2]})
        if hp:
            out["scene_lighting"][-1]["horizon_from"] = hp
        if s.get("segment"):  # M3-106: one row per playable segment of a scene (LOC-09 B1, B2, B3), horizon where it stands
            out["scene_lighting"][-1]["segment"] = s["segment"]
        log(f"{s['scene']}{' ' + s['segment'] if s.get('segment') else ''} {s['site']} {s['utc']}: Sun az {saz:.1f} el {sel:+.2f} (horizon {hz:+.2f}) -> {state}; Earth el {eel:+.2f}")
    write_json(GAME_LOLA / "sun_positions.json", out)
    log(f"wrote {(GAME_LOLA / 'sun_positions.json').relative_to(ROOT)}")


# ---------------------------------------------------------------- previews

def load_region(rid: str) -> tuple[np.ndarray, dict]:
    d = region_dir(rid)
    meta_path = next(d.glob("heightmap_*m.json"))
    meta = read_json(meta_path)
    q = np.frombuffer((d / (meta_path.stem + ".r16")).read_bytes(), dtype="<u2").reshape(meta["rows"], meta["columns"])
    h = meta["z_min_m"] + q.astype(np.float32) * (meta["z_max_m"] - meta["z_min_m"]) / 65535.0
    return h, meta


def story_sun_for(site_id: str, sun: dict) -> dict | None:
    """The scene_lighting row that lights a site in previews and captures: regions.json
    preview_scenes first, else the site's first scene with the Sun up, else its first scene."""
    want = CFG.get("preview_scenes", {}).get(site_id)
    for s in sun.get("scene_lighting", []):
        if s["site"] == site_id and s["scene"] == want:
            return s
    for s in sun.get("scene_lighting", []):
        if s["site"] == site_id and s["sun_state"] != "dark":
            return s
    for s in sun.get("scene_lighting", []):
        if s["site"] == site_id:
            return s
    return None


def cmd_preview() -> None:
    sun = read_json(GAME_LOLA / "sun_positions.json") if (GAME_LOLA / "sun_positions.json").exists() else {}
    report = {}
    for region in CFG["regions"]:
        rid = region["id"]
        h, meta = load_region(rid)
        mpp = meta["metres_per_pixel"]
        site_id = meta["site"]["id"]
        s = story_sun_for(site_id, sun)
        if s is None:
            raise RuntimeError(f"{rid}: no dated Sun for site {site_id}; run `make_terrain.py sun` first")
        az, el = s["sun_az_deg"], s["sun_el_deg"]
        label = f"{s['scene']} {s['utc']} UTC: Sun az {az:.1f} deg, el {el:+.2f} deg (JPL Horizons, {s['sun_state']} at the site)"
        sv = sun_vector_map(meta["site"]["x_m"], meta["site"]["y_m"], az, el)
        # the hero and vista grids are big: shade a downsampled copy for the vista/corridor previews
        ds = 1 if region["kind"] == "hero" else 2
        hh = h[::ds, ::ds]
        hc = curved(h, mpp, meta["site"]["pixel_col"], meta["site"]["pixel_row"])[::ds, ::ds]
        shade = hillshade(hc, mpp * ds, sv, shadows=True)
        write_png(PREVIEW / f"{rid}_hillshade_story.png", to_u8(shade))
        write_png(PREVIEW / f"{rid}_hillshade_45.png", to_u8(hillshade_45(hh, mpp * ds)))
        # official PGDA hillshade and PSR crops (20 m) over the same window; hero regions only, the
        # vistas would need ~50 tiles each from a throttled server and are compared by our own 45/45 shade
        if region["kind"] == "hero":
            cx = meta["origin_x_m"] + (meta["columns"] / 2) * mpp
            cy = meta["origin_y_m"] - (meta["rows"] / 2) * mpp
            size = max(meta["columns"], meta["rows"]) * mpp
            hill, _ = window_m("pgda90_20mpp_hill", cx, cy, size)
            hill = np.nan_to_num(hill)
            write_png(PREVIEW / f"{rid}_pgda_hill_20m.png", to_u8(hill / max(float(hill.max()), 1e-6)))
            psr, _ = window_m("pgda90_20mpp_psr", cx, cy, size)
            write_png(PREVIEW / f"{rid}_psr_20m.png", to_u8(np.nan_to_num(psr) > 0.5))
        shadow_frac = float(np.mean(shade <= 0.001))
        report[rid] = {"sun_az_deg": az, "sun_el_deg": el, "label": label, "shadow_fraction": round(shadow_frac, 4)}
        log(f"{rid}: preview with {label}; {shadow_frac:.1%} in shadow")
    write_json(PREVIEW / "preview_index.json", report)


# ---------------------------------------------------------------- provenance, fixture, manifest

def cross_check_pds(sites: dict) -> dict:
    """Compare a 10 km window of the PDS GDR LDEM_80S_20M (V2.0) with the PGDA 2023 adjusted 20 m DEM around Aurora."""
    a = sites["aurora"]
    pgda, geo = window_m("pgda90_20mpp", a["x_m"], a["y_m"], 10000)
    pds = reader("pds_ldem_80s_20m")
    n = geo["cols"]
    # same map window on the PDS grid
    c0 = int(math.floor(pds.col_of(geo["origin_x_m"]) + 0.5))
    r0 = int(math.floor(pds.row_of(geo["origin_y_m"]) + 0.5))
    block = pds.window_px(c0, r0, n, n)
    diff = block - fill_nan(pgda)
    return {"product": "pds_ldem_80s_20m", "dataset_id": pds.dataset_id, "product_version": pds.product_version, "window_px": n,
            "rms_difference_m": round(float(np.sqrt(np.nanmean(diff ** 2))), 2), "mean_difference_m": round(float(np.nanmean(diff)), 2),
            "max_abs_difference_m": round(float(np.nanmax(np.abs(diff))), 2),
            "note": "PDS GDR V2.0 (2017, unadjusted tracks) against PGDA 2023 adjusted DEM over a 10 km window at Aurora; small residuals confirm the grids, datum and projection convention"}


def product_uses(index: dict) -> dict:
    """Every configured NASA product with what the pipeline uses it for (from the config and the
    written heightmaps, so the record does not depend on which step ran last) and its local cache."""
    used = {pid: [] for pid in CFG["products"]}
    for rid, r in index["regions"].items():
        used[read_json(GAME_LOLA / r["meta"])["source_product"]].append(f"heightmap {rid}")
    for route in CFG["routes"]:
        used[route["grid"]].append(f"road {route['id']}")
    used["pgda78_site01"].append("Aurora site pick (highest pixel near the Site01 centre)")
    used["pgda78_site23"].append("Malapert summit pick")
    used["pgda90_20mpp"] += ["cold trap pick (road search)", "PDS cross-check"]
    used["pgda90_20mpp_psr"] += ["cold trap pick (permanently shadowed regions)", "preview PSR crops"]
    used["pgda90_20mpp_hill"].append("review sheets: NASA's own hillshade beside ours")
    used["pgda90_40mpp"].append("terrain horizon 4-32 km from each site")
    used["pgda90_80mpp"].append("terrain horizon 32-100 km from each site")
    used["pds_ldem_80s_20m"].append("independent cross-check of the PGDA grid, datum and projection at Aurora")
    out = {}
    for pid, p in CFG["products"].items():
        rec = {k: v for k, v in p.items() if k != "kind"}
        rec["used_for"] = used[pid] or ["opened only to test 5 m coverage; the site lies outside it, so the 10 m grid is used"]
        cdir = CACHE / pid
        files = [f for f in cdir.glob("*") if f.is_file()] if cdir.exists() else []
        rec["cache_bytes"] = sum(f.stat().st_size for f in files)
        hp = cdir / "header.json"
        if hp.exists():
            hdr = read_json(hp)
            rec.update({k: hdr[k] for k in ("width", "height", "compression", "tile_w", "retrieved") if k in hdr})
        elif files:
            rec["retrieved"] = dt.date.fromtimestamp(min(f.stat().st_mtime for f in files)).isoformat()
        out[pid] = rec
    return out


def cmd_fixture() -> None:
    sites = load_sites()["sites"]
    routes = read_json(TERRAIN / "routes.json")["routes"] if (TERRAIN / "routes.json").exists() else {}
    sun = read_json(GAME_LOLA / "sun_positions.json")
    index = read_json(TERRAIN / "heightmaps_index.json")
    log("cross-checking the PDS GDR grid")
    xc = cross_check_pds(sites)
    log(f"  PDS vs PGDA: rms {xc['rms_difference_m']} m, mean {xc['mean_difference_m']} m")
    products = product_uses(index)
    regions = {}
    for rid, r in index["regions"].items():
        meta = read_json(GAME_LOLA / r["meta"])
        regions[rid] = {k: meta[k] for k in ("source_product", "columns", "rows", "metres_per_pixel", "z_min_m", "z_max_m", "origin_x_m", "origin_y_m", "sha256_r16", "interpolated_nan_fraction")}
    prov = {
        "about": "Provenance of every NASA elevation product behind the game's south-pole terrain (board M1-34). Written by production/tools/make_terrain.py.",
        "retrieved": TODAY, "licence": "NASA data: U.S. Government work, no copyright; free to use with credit. Credit line below.",
        "credit_line": CREDIT_LINE, "credit_line_short": CREDIT_SHORT,
        "citations": CITATIONS, "products": products, "sites": sites, "regions": regions, "routes": {k: {kk: vv for kk, vv in v.items() if kk != "points"} for k, v in routes.items()},
        "pds_cross_check": xc, "ephemeris": {"service": "JPL Horizons (DE441)", "windows": {k: v["request_urls"] for k, v in sun["windows"].items()}},
    }
    write_json(TERRAIN / "provenance.json", prov)
    log(f"wrote {(TERRAIN / 'provenance.json').relative_to(ROOT)}")
    # Data Card fixture (ScienceData schema)
    scene_rows = [[f"Chapter {int(s['scene'][5:7])}" + (f" {s['segment']}" if s.get("segment") else ""), s["sun_el_deg"], s["sun_az_deg"], s["terrain_horizon_deg"], s["sun_state"], s["site"], s["utc"], s["earth_el_deg"]] for s in sun["scene_lighting"]]
    ch01 = sun["windows"].get("ch01_april_2046", {})
    scene = {s["scene"]: s for s in sun["scene_lighting"] if not s.get("segment")}  # a scene's own row, not its segments' (M3-106)
    summit_mask = sun["sites"]["malapert_summit"]["terrain_horizon_deg_by_azimuth"]
    s08 = scene.get("EX-CH08-S08", {})
    s08_hz = summit_mask[int(round(s08.get("earth_az_deg", 0.0))) % 360] if s08 else None
    ch08s = sun["windows"].get("ch08_summit", {})
    eclipse = scene.get("EX-CH06-S07", {})
    derived = [
        {"name": "aurora_site_height", "value": round(sites["aurora"]["height_m"], 1), "unit": "m", "formula": "highest LOLA 5 m pixel within 1.5 km of PGDA Site01 (Connecting ridge) centre", "drives": "where Aurora stands; the mast courtyard outside"},
        {"name": "malapert_summit_height", "value": round(sites["malapert_summit"]["height_m"], 1), "unit": "m", "formula": "highest LOLA 5 m pixel within 6 km of the IAU Mons Malapert centre", "drives": "P-16 why the summit sees Earth; the summit relay"},
        {"name": "cold_trap_psr_area", "value": sites["cold_trap"]["psr_area_km2"], "unit": "km2", "formula": "area of the chosen permanently shadowed region in LPSR_80S_20MPP_ADJ", "drives": "P-07 cold trap site; the cold-trap approach and the vault shelf"},
        {"name": "cold_trap_road_length", "value": round(routes.get("cold_trap_road", {}).get("length_m", 0) / 1000, 1), "unit": "km", "formula": "least-cost road from Aurora on the 20 m DEM with every cell <= 12 deg", "drives": "P-07 route B (game keeps 12 km / 12 deg)"},
        {"name": "cold_trap_road_max_slope", "value": routes.get("cold_trap_road", {}).get("max_slope_deg", 0), "unit": "deg", "formula": "steepest cell on that road", "drives": "P-07 slope card (rover limit 15 deg from VIPER)"},
        {"name": "relay_road_length", "value": round(routes.get("relay_road", {}).get("length_m", 0) / 1000, 1), "unit": "km", "formula": "least-cost road Aurora -> Malapert summit on the 80 m DEM, every cell <= 12 deg", "drives": "P-15 '120 km each way' (game number unchanged; the real road is longer)"},
        {"name": "relay_road_max_slope", "value": routes.get("relay_road", {}).get("max_slope_deg", 0), "unit": "deg", "formula": "steepest cell on that road; cells over 12 deg are allowed up to the 15 deg VIPER design incline only where no gentler way exists", "drives": "P-15 road slope card"},
        {"name": "relay_road_length_over_12_deg", "value": round(routes.get("relay_road", {}).get("length_over_limit_m", 0) / 1000, 2), "unit": "km", "formula": "length of that road on cells steeper than 12 deg (the summit plateau is ringed by 12-15 deg slopes on the 80 m grid)", "drives": "P-15 'slope warnings' on the last summit approach"},
        {"name": "aurora_sun_above_terrain_april_2046", "value": [ch01.get("sun_above_terrain_hours", 0), ch01.get("hours", 0)], "unit": "h", "formula": "hours 10 Apr - 1 May 2046 when the Sun's centre is above the LOLA horizon seen from 2 m at Aurora (Horizons + horizon mask)", "drives": "P-02 night length context (the 36 h night stays an authored training scenario)"},
        {"name": "aurora_longest_sun_below_terrain_april_2046", "value": ch01.get("longest_sun_below_terrain", {}).get("hours", 0), "unit": "h", "formula": "longest unbroken run of hours 10 Apr - 1 May 2046 with the Sun's centre behind the terrain seen from 2 m at Aurora; from " + str(ch01.get("longest_sun_below_terrain", {}).get("from")) + " to " + str(ch01.get("longest_sun_below_terrain", {}).get("to")), "drives": "science note for P-02: the real ridge point had a longer darkness earlier that month than the authored 36 h night"},
        {"name": "aurora_mast_sun_above_terrain_april_2046", "value": [ch01.get("mast", {}).get("sun_above_terrain_hours", 0), ch01.get("hours", 0)], "unit": "h", "formula": "same hours seen from the solar array's lower edge, " + str(sites["aurora"].get("mast_height_m")) + " m up (the NASA VSAT relocatable array's blankets span 10-16 m); longest darkness there " + str(ch01.get("mast", {}).get("longest_sun_below_terrain", {}).get("hours", 0)) + " h", "drives": "P-02 power context: why Aurora stores energy (Mazarico 2011)"},
        {"name": "earth_elevation_malapert_summit_9_apr_2047", "value": s08.get("earth_el_deg"), "unit": "deg", "formula": "Horizons Earth elevation from the pinned summit at 01:15 UT", "drives": "P-16 Earth bearing E3"},
        {"name": "malapert_terrain_horizon_toward_earth", "value": s08_hz, "unit": "deg", "formula": "LOLA terrain horizon at Earth's azimuth from the summit (2 m eye, curvature removed); Earth's centre clears it by " + (f"{s08.get('earth_el_deg', 0) - s08_hz:.2f}" if s08_hz is not None else "?") + " deg, and in every hour of 8-10 Apr 2047 (" + str(sum(1 for r in ch08s.get("rows", []) if r[6])) + " of " + str(len(ch08s.get("rows", []))) + ")", "drives": "P-16: the real summit sees Earth over the real terrain, which the pole cannot"},
        {"name": "eclipse_12_jan_2047_sun_and_earth_above_aurora_terrain", "value": bool(eclipse.get("sun_state") == "lit" and eclipse.get("earth_above_terrain")), "unit": "", "formula": f"at 01:00 UT the Sun (el {eclipse.get('sun_el_deg')}) and Earth (el {eclipse.get('earth_el_deg')}) both clear Aurora's terrain horizon ({eclipse.get('terrain_horizon_deg')} deg toward the Sun)", "drives": "P-11/P-12 the eclipse is in view from Aurora's ridge (SCIENCE_AND_DATA E20 asked for this check)"},
    ]
    fixture = {
        "source_id": "lro_lola_south_pole_terrain", "retrieved": TODAY,
        "title": "The real south-pole terrain: LRO LOLA elevation models of the connecting ridge, a cold trap and Mons Malapert",
        "agency": "NASA Goddard Space Flight Center, Planetary Geodynamics Data Archive (PGDA); LRO LOLA team; NASA PDS Geosciences Node",
        "dataset_id": "PGDA product 90 (LDEM_80S_20MPP_ADJ, LDEM_80S_40MPP_ADJ, LDEM_80S_80MPP_ADJ, LPSR_80S_20MPP_ADJ; data DOI 10.60903/gsfcpgda-lola-spole), PGDA product 78 (Site01, Site04, Site23 5 m/px), PDS LRO-L-LOLA-4-GDR-V1.0 LDEM_80S_20M (cross-check)",
        "url": "https://pgda.gsfc.nasa.gov/products/90",
        "request_urls": [CFG["products"][p]["url"] for p in ("pgda78_site01", "pgda78_site23", "pgda90_20mpp", "pgda90_40mpp", "pgda90_20mpp_psr", "pds_ldem_80s_20m")],
        "licence": "U.S. Government work (no U.S. copyright); free to use with credit",
        "citation": "; ".join(CITATIONS),
        "credit_line": CREDIT_LINE, "credit_line_short": CREDIT_SHORT,
        "fields_used": ["surface height (m) above the 1,737.4 km sphere, south polar stereographic 5/20/40/80 m per pixel", "permanently shadowed region mask", "JPL Horizons Sun and Earth azimuth/elevation"],
        "values": {
            "sites": {k: {kk: (round(vv, 4) if isinstance(vv, float) else vv) for kk, vv in v.items() if kk in ("name", "lat_deg", "lon_deg_east", "height_m", "x_m", "y_m", "psr_area_km2", "rule")} for k, v in sites.items()},
            "heightmaps": {rid: {"metres_per_pixel": r["metres_per_pixel"], "columns": r["columns"], "rows": r["rows"], "z_min_m": r["z_min_m"], "z_max_m": r["z_max_m"], "source": r["source_product"]} for rid, r in regions.items()},
            "columns": ["chapter", "sun_el_deg", "sun_az_deg", "terrain_horizon_deg", "sun_state", "site", "utc", "earth_el_deg"],   # scene ids stay in sun_positions.json
            "scene_lighting": scene_rows,
            "pds_cross_check_rms_m": xc["rms_difference_m"],
        },
        "evidence_label": "Computed",
        "derived": derived,
        "boundary": "Aurora, the vault shelf and the relay platform are authored places set on real LOLA terrain; the heights, slopes, shadows and Sun/Earth angles are computed from NASA data, the buildings, roads and the 36-hour night are not measurements. Game numbers (12 km, 12 deg, 120 km) stay as in game-design/08_PUZZLE_DESIGNS.md; the computed road lengths are shown beside them, never instead of them.",
        "src_card": "SRC-MOON",
    }
    write_json(NASA / "lro_lola_south_pole_terrain.json", fixture)
    size = (NASA / "lro_lola_south_pole_terrain.json").stat().st_size
    log(f"wrote fixture ({size} bytes)")
    # Godot manifest
    manifest = {
        "about": "Index of the LOLA terrain for Godot (board M1-34). Heightmaps are r16 (see each region's .json); tiles are GLB LODs built by production/tools/build_terrain_tiles.py; sun_positions.json holds the dated light directions.",
        "credit_line": CREDIT_LINE, "credit_line_short": CREDIT_SHORT, "retrieved": TODAY,
        "sites": {k: {"lat_deg": v["lat_deg"], "lon_deg_east": v["lon_deg_east"], "height_m": v["height_m"], "x_m": v["x_m"], "y_m": v["y_m"], "name": v["name"],
                      "godot_offset_from_aurora_m": [round(v["x_m"] - sites["aurora"]["x_m"], 2), round(v["height_m"] - sites["aurora"]["height_m"], 2), round(-(v["y_m"] - sites["aurora"]["y_m"]), 2)]}
                  for k, v in sites.items()},
        "regions": {}, "routes": {k: v for k, v in routes.items()},
        "preview_scenes": {k: v for k, v in CFG.get("preview_scenes", {}).items() if k != "about"},
        "frame": "Godot X = map x - site x; Z = -(map y - site y); Y = height - site height. Azimuth 0 = local north (away from the pole), 90 = east (clockwise seen from above).",
    }
    for rid, r in index["regions"].items():
        meta = read_json(GAME_LOLA / r["meta"])
        tiles = GAME_LOLA / rid / "tiles.json"
        manifest["regions"][rid] = {"kind": meta["kind"], "story": meta["story"], "site": meta["site"]["id"], "heightmap": f"res://assets/environment/terrain/lola/{r['heightmap']}", "meta": f"res://assets/environment/terrain/lola/{r['meta']}",
                                    "metres_per_pixel": meta["metres_per_pixel"], "columns": meta["columns"], "rows": meta["rows"],
                                    "tiles": f"res://assets/environment/terrain/lola/{rid}/tiles.json" if tiles.exists() else None}
    write_json(GAME_LOLA / "lola_terrain.json", manifest)
    log(f"wrote {(GAME_LOLA / 'lola_terrain.json').relative_to(ROOT)}")


CREDIT_LINE = ("Terrain made from NASA data: Lunar Reconnaissance Orbiter, Lunar Orbiter Laser Altimeter (LOLA) elevation models "
               "from NASA Goddard's Planetary Geodynamics Data Archive (Barker et al. 2021, 2023) and the NASA PDS; "
               "Sun and Earth positions from NASA JPL Horizons. NASA does not endorse this game.")
CREDIT_SHORT = "Terrain made from NASA LRO LOLA data (GSFC PGDA / PDS); sky geometry from JPL Horizons."
CITATIONS = [
    "Barker, M. K., Mazarico, E., Neumann, G. A., Smith, D. E., Zuber, M. T., Head, J. W. (2021). Improved LOLA elevation maps for south pole landing sites: error estimates and their impact on illumination conditions. Planetary and Space Science 203, 105119. https://doi.org/10.1016/j.pss.2020.105119",
    "Barker, M. K., Mazarico, E., Neumann, G. A., Smith, D. E., Zuber, M. T., Head, J. W. (2023). A New View of the Lunar South Pole from LOLA. The Planetary Science Journal 4, 183. https://doi.org/10.3847/PSJ/acf3e1 ; data https://doi.org/10.60903/gsfcpgda-lola-spole",
    "Smith, D. E. et al. (2010). The Lunar Orbiter Laser Altimeter investigation on the Lunar Reconnaissance Orbiter mission. Space Science Reviews 150, 209-241; LRO-L-LOLA-4-GDR-V1.0, NASA PDS Geosciences Node",
    "Mazarico, E., Neumann, G. A., Smith, D. E., Zuber, M. T., Torrence, M. H. (2011). Illumination conditions of the lunar polar regions using LOLA topography. Icarus 211, 1066-1081. https://doi.org/10.1016/j.icarus.2010.10.030",
    "JPL Horizons On-Line Ephemeris System (DE441), https://ssd.jpl.nasa.gov/horizons/",
]


# ---------------------------------------------------------------- review sheet

def cmd_review() -> None:
    """Side-by-side: official PGDA hillshade | our hillshade at the story Sun | in-game capture (if present)."""
    from PIL import Image, ImageDraw, ImageFont  # Pillow only here
    REVIEW.mkdir(parents=True, exist_ok=True)
    prev = read_json(PREVIEW / "preview_index.json")
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 22) if Path("/System/Library/Fonts/Supplemental/Arial.ttf").exists() else ImageFont.load_default()
    small = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 16) if Path("/System/Library/Fonts/Supplemental/Arial.ttf").exists() else ImageFont.load_default()
    for region in CFG["regions"]:
        rid = region["id"]
        panels = [(PREVIEW / f"{rid}_pgda_hill_20m.png", "NASA PGDA LDEM_80S_20MPP_ADJ_HILL (official hillshade, 45/45)"),
                  (PREVIEW / f"{rid}_hillshade_45.png", f"LOLA {region['mpp']} m heightmap, same 45/45 shading") if region["kind"] != "hero" else (Path("/nonexistent"), ""),
                  (PREVIEW / f"{rid}_hillshade_story.png", f"LOLA {region['mpp']} m heightmap, story Sun with cast shadows"),
                  (EVIDENCE / f"M1-34_{rid}_topdown.png", "Godot 4.7 Forward+, same tiles and Sun (top-down)")]
        imgs = []
        for path, cap in panels:
            if not path.exists():
                continue
            im = Image.open(path).convert("RGB")
            im = im.resize((900, int(900 * im.height / im.width)))
            imgs.append((im, cap))
        if len(imgs) < 2:
            continue
        hgt = max(i.height for i, _ in imgs)
        sheet = Image.new("RGB", (900 * len(imgs) + 20 * (len(imgs) + 1), hgt + 120), (12, 12, 14))
        d = ImageDraw.Draw(sheet)
        d.text((20, 14), f"M1-34 {rid}: {region['story']}", fill=(240, 240, 240), font=font)
        d.text((20, 44), prev.get(rid, {}).get("label", ""), fill=(200, 200, 200), font=small)
        for i, (im, cap) in enumerate(imgs):
            x = 20 + i * 920
            sheet.paste(im, (x, 80))
            d.text((x, 86 + hgt), cap, fill=(220, 220, 220), font=small)
        sheet.save(REVIEW / f"M1-34_{rid}_lola_vs_game.png")
        log(f"wrote production/review/M1-34_{rid}_lola_vs_game.png ({len(imgs)} panels)")


# ---------------------------------------------------------------- check

def cmd_check() -> int:
    problems = []
    sites = load_sites()["sites"]
    index = read_json(TERRAIN / "heightmaps_index.json")
    for rid, r in index["regions"].items():
        meta = read_json(GAME_LOLA / r["meta"])
        raw = GAME_LOLA / r["heightmap"]
        if not raw.exists():
            problems.append(f"{rid}: missing {raw.name}")
            continue
        if raw.stat().st_size != meta["columns"] * meta["rows"] * 2:
            problems.append(f"{rid}: r16 size {raw.stat().st_size} != {meta['columns']}x{meta['rows']}x2")
        if sha256(raw) != meta["sha256_r16"]:
            problems.append(f"{rid}: r16 checksum changed")
        if not (0 <= meta["site"]["pixel_col"] < meta["columns"] and 0 <= meta["site"]["pixel_row"] < meta["rows"]):
            problems.append(f"{rid}: site outside the window")
        h, _ = load_region(rid)
        s = meta["site"]
        hs = float(h[int(round(s["pixel_row"])), int(round(s["pixel_col"]))])
        # exact when the site was picked on this region's own product; a few metres apart when the
        # site comes from a finer or coarser LOLA grid (all regions share the site's absolute height)
        same = sites.get(s["id"], {}).get("product") == meta["source_product"]
        tol = (meta["z_max_m"] - meta["z_min_m"]) / 65535 * 2 + 0.05 if same else 5.0
        if abs(hs - s["height_m"]) > tol and meta["kind"] != "corridor":
            problems.append(f"{rid}: site height {s['height_m']} vs heightmap {hs:.2f} (tolerance {tol:.2f} m)")
    sun = read_json(GAME_LOLA / "sun_positions.json")
    for w in sun["windows"].values():
        for row in w["rows"]:
            if not (0 <= row[1] < 360 and -3 < row[2] < 3 and -10 < row[4] < 10):
                problems.append(f"sun window row out of range: {row}")
                break
    # two independent shadow methods must agree at each hero site: the ray-marched horizon mask
    # (sun_positions.json) and the scan-line cast shadow on the curved hero grid (previews)
    for region in CFG["regions"]:
        if region["kind"] != "hero":
            continue
        h, meta = load_region(region["id"])
        mpp = meta["metres_per_pixel"]
        r, c = int(round(meta["site"]["pixel_row"])), int(round(meta["site"]["pixel_col"]))
        hc = curved(h, mpp, meta["site"]["pixel_col"], meta["site"]["pixel_row"])
        hc[r, c] += 2.0  # the mask's eye height
        for row in sun["scene_lighting"]:
            if row["site"] != meta["site"]["id"] or row["sun_state"] == "partial":
                continue
            shaded = bool(cast_shadow(hc, mpp, sun_vector_map(meta["site"]["x_m"], meta["site"]["y_m"], row["sun_az_deg"], row["sun_el_deg"]))[r, c])
            if shaded != (row["sun_state"] == "dark"):
                problems.append(f"{region['id']} {row['scene']}: horizon mask says {row['sun_state']}, cast shadow says {'dark' if shaded else 'lit'}")
    fx = read_json(NASA / "lro_lola_south_pole_terrain.json")
    for k in ("source_id", "title", "agency", "dataset_id", "url", "retrieved", "licence", "citation", "fields_used", "values", "derived", "evidence_label", "boundary", "credit_line"):
        if k not in fx or fx[k] in ("", [], {}):
            problems.append(f"fixture lacks {k}")
    if (NASA / "lro_lola_south_pole_terrain.json").stat().st_size >= 200_000:
        problems.append("fixture is 200 KB or more")
    print("\n".join(problems) or f"check OK: {len(index['regions'])} regions, {len(sun['windows'])} sun windows, {len(sites)} sites")
    return 1 if problems else 0


# ---------------------------------------------------------------- CLI

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("step", choices=["all", "sites", "heightmaps", "routes", "sun", "preview", "fixture", "review", "check"])
    a = ap.parse_args()
    CACHE.mkdir(parents=True, exist_ok=True)
    steps = {"sites": cmd_sites, "heightmaps": cmd_heightmaps, "routes": cmd_routes, "sun": cmd_sun, "preview": cmd_preview, "fixture": cmd_fixture, "review": cmd_review}
    if a.step == "check":
        return cmd_check()
    order = ["sites", "routes", "heightmaps", "sun", "preview", "fixture", "review"] if a.step == "all" else [a.step]
    for s in order:
        t0 = time.time()
        log(f"== {s}")
        steps[s]()
        log(f"== {s} done in {time.time() - t0:.0f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
