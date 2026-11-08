#!/usr/bin/env python3
"""M4-05 post pass for CS-15-A and CS-15-D: repaint Earth as the true 1.90 deg, ~3%-lit crescent.

Usage:
  uv run --with numpy --with opencv-python-headless python production/tools/repaint_cs15_earth.py --all
  uv run --with numpy --with opencv-python-headless python production/tools/repaint_cs15_earth.py CS-15-A <in.mp4> <out.mp4>

Bundled JPL Horizons ephemeris for EX-CH08-S10 (malapert_summit, 2047-04-09 02:00 UTC):
- Sun: azimuth 18.107 deg, elevation +2.313 deg (sun_state: "full").
- Earth: azimuth 358.694 deg, elevation -2.320 deg; local terrain horizon toward Earth is -4.4 deg, so Earth's
  centre stands ~2.1 deg above the Malapert skyline (lower limb ~1.15 deg above the skyline).
- Angular diameter of Earth from the Moon: 1.90 deg (~3.6x the Sun's 0.53 deg disc).
- Sun-Earth angular separation: 19.95 deg (phase angle ~160.05 deg -> illuminated fraction k = (1 + cos 160.05 deg)/2 = 3.0%).
- Relative to Earth on the sky, the Sun stands 19.413 deg to the right and 4.633 deg higher (direction angle +13.43 deg
  above the +x rightward horizontal), so the thin lit crescent sits on the right-upper limb facing the Sun, and the
  night side is nearly black with no city lights.
"""
import argparse
import math
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import cv2
import numpy as np

HFOV_DEG = 60.0
EARTH_DIAM_DEG = 1.90
EARTH_ABOVE_SKYLINE_DEG = 2.10
SUN_DAZ_DEG = 18.107 - (358.694 - 360.0)   # +19.413 deg (to the right of Earth)
SUN_DEL_DEG = 2.313 - (-2.320)             # +4.633 deg (higher than Earth)
PHASE_ANGLE_DEG = 160.05                   # 3.0% illuminated crescent

SHOTS = {
    "CS-15-A": {
        "old_box_norm": (0.47, 0.03, 0.59, 0.27),
        "cx0": 942.0,
        "cx1": 945.0,
        "zoom0": 1.000,
        "zoom1": 1.045,
    },
    "CS-15-D": {
        "old_box_norm": (0.47, 0.03, 0.60, 0.25),
        "cx0": 630.0,
        "cx1": 612.0,
        "zoom0": 1.000,
        "zoom1": 1.055,
    },
}


def probe(path: str):
    out = subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "stream=width,height,r_frame_rate,nb_frames",
        "-of", "csv=p=0", path,
    ]).decode().strip()
    w, h, fps, n = out.split(",")
    return int(w), int(h), fps, int(n)


def decode(path: str, w: int, h: int):
    dec = subprocess.Popen(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "rawvideo", "-pix_fmt", "bgr24", "-"],
        stdout=subprocess.PIPE,
    )
    while (buf := dec.stdout.read(w * h * 3)) and len(buf) == w * h * 3:
        yield np.frombuffer(buf, np.uint8).reshape(h, w, 3).copy()
    dec.stdout.close()
    dec.wait()


def erase_old_earth(frame: np.ndarray, old_box_norm: tuple[float, float, float, float]) -> np.ndarray:
    """Black out the old oversized (~4 deg, left-lit) Earth disc and its atmospheric halo in the sky box."""
    h, w = frame.shape[:2]
    x0 = int(round(w * old_box_norm[0]))
    y0 = int(round(h * old_box_norm[1]))
    x1 = int(round(w * old_box_norm[2]))
    y1 = int(round(h * old_box_norm[3]))
    out = frame.copy()
    roi = out[y0:y1, x0:x1]
    # Find the bright/blue core of the old Earth to locate its centre and radius
    b, g, r = roi[..., 0].astype(int), roi[..., 1].astype(int), roi[..., 2].astype(int)
    core = (b - r > 12) & (b > 30)
    ys, xs = np.nonzero(core)
    if len(xs) > 20:
        # The old Earth's left half is lit; its full disc extends ~0.65 * height to the right of the left limb
        left_x = float(xs.min())
        top_y = float(ys.min())
        bot_y = float(ys.max())
        rad = 0.5 * (bot_y - top_y + 1.0)
        cx = left_x + rad
        cy = 0.5 * (top_y + bot_y)
        yy, xx = np.mgrid[0:(y1 - y0), 0:(x1 - x0)]
        dist = np.hypot(xx - cx, yy - cy)
        # Erase the disc plus its faint glow halo (up to 1.45 * rad) where pixels belong to the sky/disc
        # (protecting Amara's hair in the lower-right corner of the ROI if it ever enters).
        hair_protect = (yy > cy + rad * 0.85) & (r >= b) & (roi.max(axis=2) > 28)
        kill = (dist <= rad * 1.45) & (~hair_protect)
        roi[kill] = 0
    else:
        roi[:] = 0
    out[y0:y1, x0:x1] = roi
    return out


def measure_skyline_y(frame: np.ndarray, cx: float) -> float:
    """Return the y pixel coordinate of the Malapert northern mountain skyline directly below cx."""
    h, w = frame.shape[:2]
    ix = int(round(cx))
    y_start = int(round(h * 0.28))
    y_end = int(round(h * 0.54))
    band = frame[y_start:y_end, max(0, ix - 4):min(w, ix + 5)]
    row_lum = np.median(band.max(axis=2), axis=1)
    hits = np.nonzero(row_lum > 22)[0]
    if len(hits) == 0:
        return float(h * 0.45)
    return float(y_start + hits[0])


def render_earth_crescent(frame: np.ndarray, cx: float, cy: float, radius_px: float) -> np.ndarray:
    """Draw the 1.90 deg Earth with a ~3%-lit crescent facing the Sun (+19.4 deg right, +4.6 deg up) and dark night side."""
    h, w = frame.shape[:2]
    ss = 4
    pad = int(math.ceil(radius_px)) + 4
    x0, x1 = max(0, int(math.floor(cx)) - pad), min(w, int(math.ceil(cx)) + pad + 1)
    y0, y1 = max(0, int(math.floor(cy)) - pad), min(h, int(math.ceil(cy)) + pad + 1)
    if x1 <= x0 or y1 <= y0:
        return frame

    pw, ph = (x1 - x0) * ss, (y1 - y0) * ss
    yy, xx = np.mgrid[0:ph, 0:pw].astype(np.float32)
    # Subpixel coordinates relative to Earth centre in original pixel units
    dx = (xx + 0.5) / ss + x0 - cx
    dy = (yy + 0.5) / ss + y0 - cy
    r_norm = np.hypot(dx, dy) / radius_px

    inside = r_norm <= 1.0
    # Sun direction in image plane (+x right, -y up): Sun is 19.413 deg right and 4.633 deg up
    sun_angle = math.atan2(SUN_DEL_DEG, SUN_DAZ_DEG)  # +13.43 deg above +x
    ux, uy = math.cos(sun_angle), -math.sin(sun_angle)
    vx, vy = -uy, ux

    # Normalized disc coordinates (xi along Sun direction, eta perpendicular, zeta out of screen)
    xi = (dx * ux + dy * uy) / radius_px
    eta = (dx * vx + dy * vy) / radius_px
    zeta = np.sqrt(np.maximum(0.0, 1.0 - xi * xi - eta * eta))

    # Spherical illumination for a thin crescent facing the Sun:
    # Physical phase angle is 160.05 deg (3.0% lit: terminator at xi = 0.940 * sqrt(1 - eta^2)).
    # At 1080p/720p (radius 18.5..28 px), a 160 deg / 152 deg cel threshold produces a crisp 2.5-3.5 px
    # razor-thin crescent along the right-upper limb (~3-5% of disc pixels lit) matching M3-8A's reference sheet.
    alpha_outer = math.radians(152.0)   # inner edge of the cel crescent (cyan-blue band)
    alpha_core = math.radians(158.5)    # outer sunlit limb highlight (pale ice-white)
    ndotl_outer = xi * math.sin(alpha_outer) + zeta * math.cos(alpha_outer)
    ndotl_core = xi * math.sin(alpha_core) + zeta * math.cos(alpha_core)

    canvas = np.zeros((ph, pw, 3), dtype=np.float32)
    alpha = np.zeros((ph, pw), dtype=np.float32)

    # 1. Nearly black night side (no city lights; subtle dark earthshine silhouette #030405)
    night_col = np.array([5.0, 4.0, 3.0], dtype=np.float32)       # BGR
    night_rim = np.array([8.0, 6.0, 4.0], dtype=np.float32)       # barely perceptible unlit limb
    canvas[inside] = night_col
    rim_mask = inside & (r_norm > 0.93) & (xi < 0.2)
    canvas[rim_mask] = night_rim
    alpha[inside] = 1.0

    # 2. Lit thin crescent on the right-upper limb facing the Sun
    crescent_band = inside & (ndotl_outer > 0.0)
    crescent_core = inside & (ndotl_core > 0.0)
    col_band = np.array([228.0, 174.0, 102.0], dtype=np.float32)  # BGR cel ocean/atmosphere cyan-blue
    col_core = np.array([252.0, 246.0, 232.0], dtype=np.float32)  # BGR bright sunlit cloud limb
    canvas[crescent_band] = col_band
    canvas[crescent_core] = col_core

    # Downsample 4x supersampled patch back to target resolution
    patch_col = cv2.resize(canvas, (x1 - x0, y1 - y0), interpolation=cv2.INTER_AREA)
    patch_al = cv2.resize(alpha, (x1 - x0, y1 - y0), interpolation=cv2.INTER_AREA)[..., None]

    out = frame.copy()
    bg = out[y0:y1, x0:x1].astype(np.float32)
    out[y0:y1, x0:x1] = np.clip(bg * (1.0 - patch_al) + patch_col, 0, 255).astype(np.uint8)
    return out


def process_shot(shot_id: str, src_path: str, dst_path: str) -> None:
    cfg = SHOTS[shot_id]
    w, h, fps, nframes = probe(src_path)
    f0 = w / (2.0 * math.tan(math.radians(HFOV_DEG * 0.5)))

    with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        enc = subprocess.Popen(
            [
                "ffmpeg", "-v", "error", "-y",
                "-f", "rawvideo", "-pix_fmt", "bgr24", "-s", f"{w}x{h}", "-r", fps, "-i", "-",
                "-c:v", "libx264", "-crf", "12", "-preset", "slow",
                "-pix_fmt", "yuv420p", "-movflags", "+faststart", tmp_path,
            ],
            stdin=subprocess.PIPE,
        )
        raw_skyline = []
        frames = list(decode(src_path, w, h))
        cleaned_frames = []
        for idx, frame in enumerate(frames):
            t = idx / max(1, len(frames) - 1)
            cx = cfg["cx0"] * (1.0 - t) + cfg["cx1"] * t
            cleaned = erase_old_earth(frame, cfg["old_box_norm"])
            cleaned_frames.append(cleaned)
            raw_skyline.append(measure_skyline_y(cleaned, cx))

        # Fit a smooth linear trajectory to skyline_y so Earth never jitters by 1 px between frames
        xs_t = np.linspace(0.0, 1.0, len(frames))
        slope, intercept = np.polyfit(xs_t, np.array(raw_skyline, dtype=float), 1)

        for idx, cleaned in enumerate(cleaned_frames):
            t = idx / max(1, len(cleaned_frames) - 1)
            zoom = cfg["zoom0"] * (1.0 - t) + cfg["zoom1"] * t
            f_eff = f0 * zoom
            r_earth = f_eff * math.tan(math.radians(EARTH_DIAM_DEG * 0.5))
            dy_centre = f_eff * math.tan(math.radians(EARTH_ABOVE_SKYLINE_DEG))
            cx = cfg["cx0"] * (1.0 - t) + cfg["cx1"] * t
            skyline_y = float(intercept + slope * t)
            cy = skyline_y - dy_centre
            out = render_earth_crescent(cleaned, cx, cy, r_earth)
            enc.stdin.write(out.tobytes())

        enc.stdin.close()
        if enc.wait() != 0:
            raise RuntimeError(f"ffmpeg encode failed for {shot_id}")
        shutil.move(tmp_path, dst_path)
        print(
            f"{shot_id}: repainted {len(frames)} frames ({w}x{h} @ {fps} fps) -> {dst_path} "
            f"(Earth diam {2 * f0 * math.tan(math.radians(EARTH_DIAM_DEG * 0.5)):.1f}px = {EARTH_DIAM_DEG} deg, "
            f"centre {f0 * math.tan(math.radians(EARTH_ABOVE_SKYLINE_DEG)):.1f}px = {EARTH_ABOVE_SKYLINE_DEG} deg above skyline)"
        )
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("shot", nargs="?", choices=sorted(SHOTS))
    ap.add_argument("src", nargs="?")
    ap.add_argument("dst", nargs="?")
    ap.add_argument("--all", action="store_true", help="repaint CS-15-A and CS-15-D in place")
    args = ap.parse_args()

    root = Path(__file__).resolve().parents[2]
    shots_dir = root / "production/cutscenes/v8/src/shots"
    if args.all:
        for shot_id in ["CS-15-A", "CS-15-D"]:
            p = str(shots_dir / f"{shot_id}.mp4")
            process_shot(shot_id, p, p)
    else:
        if not (args.shot and args.src and args.dst):
            ap.error("provide SHOT SRC DST or --all")
        process_shot(args.shot, args.src, args.dst)


if __name__ == "__main__":
    main()
