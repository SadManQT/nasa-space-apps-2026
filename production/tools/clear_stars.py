#!/usr/bin/env python3
"""Remove stars from the black sky of a cutscene shot (art bible: no stars over a sunlit surface).

  python3 tools/clear_stars.py <in.mp4> <out.mp4> [--rows 0.62] [--grade-sky 0.3] [--debug <frame.png> --at <frame no.>]

Per frame: a morphological opening wipes every bright speck smaller than the kernel; the result is
used only inside large smooth, darkish regions (the sky, even where the Sun's glare lifts it), so
regolith, plant, suit and screen detail elsewhere is untouched; --rows limits it to the top fraction of the frame when dark props share the shot.
Decodes and re-encodes 10-bit HEVC like the Seedance masters. --debug writes frame --at with the
replaced area tinted red, or the graded sky with its mask outlined when --grade-sky is used.
"""
import argparse, json, subprocess
import cv2
import numpy as np

p = argparse.ArgumentParser()
p.add_argument("src"); p.add_argument("dst"); p.add_argument("--debug"); p.add_argument("--at", type=int, default=0)
p.add_argument("--rows", type=float, default=1.0, help="only the top fraction of the frame holds sky")
p.add_argument("--black", type=int, default=110, help="brightest sky, 0-255 (after the opening)")
p.add_argument("--smooth", type=float, default=2.0, help="most local texture the sky may have, 0-255")
p.add_argument("--kernel", type=int, default=9, help="largest star to remove, px")
p.add_argument("--min-area", type=int, default=4000, help="smallest sky region, px")
p.add_argument("--grade-sky", type=float, help="pull the top-connected smooth sky toward black, 0-1")
a = p.parse_args()
if a.kernel < 0 or a.grade_sky is not None and not 0 <= a.grade_sky < 1:
    p.error("--kernel must be non-negative and --grade-sky must be in [0, 1)")

s = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                                        "stream=width,height,r_frame_rate", "-of", "json", a.src]))["streams"][0]
W, H, fps = s["width"], s["height"], s["r_frame_rate"]
dec = subprocess.Popen(["ffmpeg", "-v", "error", "-i", a.src, "-f", "rawvideo", "-pix_fmt", "rgb48le", "-"],
                       stdout=subprocess.PIPE)
enc = None if a.debug else subprocess.Popen(
    ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb48le", "-s", f"{W}x{H}", "-r", fps, "-i", "-",
     "-vf", "scale=out_color_matrix=bt709:out_range=tv,format=yuv420p10le", "-colorspace", "bt709",
     "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
     "-c:v", "libx265", "-crf", "12", "-preset", "slow", "-tag:v", "hvc1",
     "-x265-params", "log-level=error:colorprim=bt709:transfer=bt709:colormatrix=bt709", a.dst], stdin=subprocess.PIPE)
k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (a.kernel, a.kernel)) if a.kernel else None
grow = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
edge = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
n = 0
while (buf := dec.stdout.read(W * H * 6)) and len(buf) == W * H * 6:
    if a.debug and n < a.at:
        n += 1; continue
    f = np.frombuffer(buf, np.uint16).reshape(H, W, 3)
    opened = cv2.morphologyEx(f, cv2.MORPH_OPEN, k) if k is not None else f
    lum = opened.max(axis=2).astype(np.float32) / 257
    hp = lum - cv2.GaussianBlur(lum, (0, 0), 6)  # texture, without the Sun's smooth glare gradient
    std = np.sqrt(np.maximum(cv2.blur(hp * hp, (15, 15)), 0))  # box-filter rounding can dip below 0
    sky = ((lum < a.black) & (std < a.smooth)).astype(np.uint8)
    sky[int(H * a.rows):] = 0
    cnt, lab, stats, _ = cv2.connectedComponentsWithStats(sky, connectivity=4)
    keep = np.flatnonzero(stats[1:, cv2.CC_STAT_AREA] >= a.min_area) + 1  # label 0 is "not sky"
    sky = cv2.dilate(np.isin(lab, keep).astype(np.uint8), grow).astype(bool)  # catch each star's soft halo at the region edge
    out = f.copy(); out[sky] = opened[sky]
    grade_mask = None
    if a.grade_sky is not None:
        # finer texture measure than the star mask, so the sky reaches right up to masts and the horizon
        hp2 = lum - cv2.GaussianBlur(lum, (0, 0), 2)
        smooth = (np.sqrt(np.maximum(cv2.blur(hp2 * hp2, (5, 5)), 0)) < a.smooth).astype(np.uint8)
        _, grade_lab, _, _ = cv2.connectedComponentsWithStats(smooth, connectivity=4)
        labels = np.unique(grade_lab[0])
        labels = labels[labels != 0]
        grade_mask = cv2.dilate(np.isin(grade_lab, labels).astype(np.uint8), grow)
        # the band reaches past the smooth sky so edge pixels lit by the glow go dark too; a black sky hides it
        feather = cv2.GaussianBlur(grade_mask.astype(np.float32), (0, 0), 3)[..., None]
        v = out.astype(np.float32) / 65535
        graded = np.clip((v - a.grade_sky) / (1 - a.grade_sky), 0, 1)
        out = np.rint((v * (1 - feather) + graded * feather) * 65535).astype(np.uint16)
    if a.debug:
        dec.kill()
        dbg = (out >> 8).astype(np.uint8)
        if grade_mask is None:
            dbg[sky] = dbg[sky] // 2 + np.array([110, 0, 0], np.uint8)
        else:
            outline = cv2.morphologyEx(grade_mask, cv2.MORPH_GRADIENT, edge).astype(bool)
            dbg[outline] = np.array([255, 0, 0], np.uint8)
        cv2.imwrite(a.debug, cv2.cvtColor(dbg, cv2.COLOR_RGB2BGR)); break
    enc.stdin.write(out.tobytes()); n += 1
dec.stdout.close(); dec.wait()
if enc:
    enc.stdin.close(); enc.wait()
    print(f"cleared {n} frames -> {a.dst}")
