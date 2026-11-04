"""One-off M1-43 post pass for CS-03-A v4 (not a pipeline tool).

  python3 fix_a.py <in.mp4> <out.mp4> [--debug <png> --at <frame>]

1. Regolith back to grey: warm, low-chroma pixels (the beige drift Seedance adds from ~4 s) are pulled
   to their own luma; saturated gold/orange (greenhouse window, module trim) is left alone.
2. Tight Sun: inside a circle of 9 disc radii round the Sun, the smooth top-connected sky (same test
   as production/tools/clear_stars.py --grade-sky) is graded toward black, so the soft glare halo
   shrinks to a tight rim; the solar blanket, mast and ridges outside the smooth sky are untouched.
Encodes 10-bit HEVC with BT.709 tags like clear_stars.py.
"""
import argparse, json, subprocess
import cv2
import numpy as np

p = argparse.ArgumentParser()
p.add_argument("src"); p.add_argument("dst"); p.add_argument("--debug"); p.add_argument("--at", type=int, default=0)
p.add_argument("--grade", type=float, default=0.45)
a = p.parse_args()

s = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                                        "stream=width,height,r_frame_rate", "-of", "json", a.src]))["streams"][0]
W, H, fps = s["width"], s["height"], s["r_frame_rate"]
grow = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
yy, xx = np.mgrid[0:H, 0:W]


def find_sun(lum):
    """Centre and radius of the brightest round blob in the upper sky that sits in a dark ring."""
    m = (lum[: int(H * 0.6), : W // 3] > 0.97).astype(np.uint8)  # ponytail: this shot keeps the Sun in the left third
    n, _, st, cen = cv2.connectedComponentsWithStats(m)
    best = None
    for i in range(1, n):
        x, y, w, h, area = st[i]
        if not 40 <= area <= 6000 or not 0.6 < w / h < 1.6 or area / (w * h) < 0.6:
            continue
        cx, cy = cen[i]; r = np.sqrt(area / np.pi)
        ring = (np.abs(np.hypot(xx - cx, yy - cy) - 3 * r) < 2)
        dark = lum[ring].mean()
        if dark < 0.6 and (best is None or dark < best[3]):
            best = (cx, cy, r, dark)
    return best



# pre-pass: track the Sun on every frame, then fill frames where the mast hides part of the disc
# (or it is still too small) by interpolation, so the grade never switches on and off between frames
track = []
pd = subprocess.Popen(["ffmpeg", "-v", "error", "-i", a.src, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
while (b := pd.stdout.read(W * H * 3)) and len(b) == W * H * 3:
    track.append(find_sun(np.frombuffer(b, np.uint8).reshape(H, W, 3).max(axis=2) / 255.0))
pd.wait()
ok = [i for i, t in enumerate(track) if t]
fill = {k: np.interp(range(len(track)), ok, [track[i][k] for i in ok]) for k in range(3)}
track = [(fill[0][i], fill[1][i], fill[2][i]) for i in range(len(track))]
print(f"sun found on {len(ok)} of {len(track)} frames; the rest interpolated")

dec = subprocess.Popen(["ffmpeg", "-v", "error", "-i", a.src, "-f", "rawvideo", "-pix_fmt", "rgb48le", "-"],
                       stdout=subprocess.PIPE)
enc = None if a.debug else subprocess.Popen(
    ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb48le", "-s", f"{W}x{H}", "-r", fps, "-i", "-",
     "-vf", "scale=out_color_matrix=bt709:out_range=tv,format=yuv420p10le", "-colorspace", "bt709",
     "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
     "-c:v", "libx265", "-crf", "12", "-preset", "slow", "-tag:v", "hvc1",
     "-x265-params", "log-level=error:colorprim=bt709:transfer=bt709:colormatrix=bt709", a.dst], stdin=subprocess.PIPE)

n = 0
while (buf := dec.stdout.read(W * H * 6)) and len(buf) == W * H * 6:
    if a.debug and n < a.at:
        n += 1; continue
    v = np.frombuffer(buf, np.uint16).reshape(H, W, 3).astype(np.float32) / 65535
    # 1. warm low-chroma -> grey (rgb order from rgb48le)
    hsv = cv2.cvtColor(v, cv2.COLOR_RGB2HSV)  # float: H 0-360, S 0-1
    hue, sat = hsv[..., 0], hsv[..., 1]
    warm = np.clip(1 - np.abs(hue - 35) / 25, 0, 1)  # beige/tan hues ~20-45 deg
    w = (warm * np.clip((0.40 - sat) / 0.12, 0, 1))[..., None]  # gold glow and orange trim (S > 0.4) kept
    luma = (v @ np.array([0.2126, 0.7152, 0.0722], np.float32))[..., None]
    v = v * (1 - w) + luma * w
    # 2. tight Sun
    lum = v.max(axis=2)
    sun = track[n]
    mask = None
    if sun:
        cx, cy, r = sun
        hp2 = lum * 255 - cv2.GaussianBlur(lum * 255, (0, 0), 2)
        smooth = (np.sqrt(np.maximum(cv2.blur(hp2 * hp2, (5, 5)), 0)) < 2.0).astype(np.uint8)
        _, lab, _, _ = cv2.connectedComponentsWithStats(smooth, connectivity=4)
        top = np.unique(lab[0]); top = top[top != 0]
        sky = cv2.dilate(np.isin(lab, top).astype(np.uint8), grow).astype(np.float32)
        circle = np.clip((9 * r - np.hypot(xx - cx, yy - cy)) / (3 * r), 0, 1)
        neutral = np.clip((0.25 - sat) / 0.1, 0, 1)  # glare is grey-white; the navy solar blanket is not
        mask = (cv2.GaussianBlur(sky, (0, 0), 3) * circle * neutral)[..., None]
        graded = np.clip((v - a.grade) / (1 - a.grade), 0, 1)
        v = v * (1 - mask) + graded * mask
    out = np.rint(np.clip(v, 0, 1) * 65535).astype(np.uint16)
    if a.debug:
        dec.kill()
        dbg = (out >> 8).astype(np.uint8)
        if mask is not None:
            edge = cv2.morphologyEx((mask[..., 0] > 0.5).astype(np.uint8), cv2.MORPH_GRADIENT, np.ones((3, 3), np.uint8)).astype(bool)
            dbg[edge] = (255, 0, 0)
        cv2.imwrite(a.debug, cv2.cvtColor(dbg, cv2.COLOR_RGB2BGR))
        print("sun", sun); break
    enc.stdin.write(out.tobytes()); n += 1
dec.stdout.close(); dec.wait()
if enc:
    enc.stdin.close(); enc.wait()
    print(f"fixed {n} frames -> {a.dst}")
