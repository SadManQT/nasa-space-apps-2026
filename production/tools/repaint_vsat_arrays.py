#!/usr/bin/env python3
"""M1-45 post pass for the CS-01-A and CS-02-A exterior shots (a one-off, not a pipeline tool).

  python3 production/tools/repaint_vsat_arrays.py CS-01-A <in.mp4> <out.mp4> [--debug-dir <dir> --every 24]

What it changes (science review M1-40, findings S5 and N7):
- The four small square panels on short poles become the NASA relocatable 10 kW vertical solar array the game
  cites (NASA/TM-20210011743): a 16 m slender telescoping mast on a tripod base, a horizontal cross arm at the top,
  and two 3 m wide solar-cell blankets hanging from the arm from 16 m down to 10 m above the surface (36 m2 in all).
  The whole unit is turned so the blanket plane faces the low Sun, as the azimuth drive at the base of the real
  design does. Because the Sun is ahead-left of the camera in both shots, the camera sees the shaded back of the
  blankets; the Sun side of the mast, arms and blanket edges carries the light.
- In CS-01-A the Sun's roughly 2 degree glowing disc becomes a hard disc of 0.53 degrees with no halo, at the same
  place in the frame. CS-02-A has no Sun in frame.
- Everything else in the frame is left as it was (black sky, hard shadows, grey regolith, no Earth, no dust).

How. The generated shot is a forward dolly, but its old panels are not rigid (they turn as the shot goes on), so the
camera move is read from the habitat modules instead: pyramidal Lucas-Kanade on the module faces gives a similarity
per frame, from which the dolly distance follows for a pinhole camera (60 degree horizontal field of view, level with
the horizon, scale from the 5 m habitat modules). Each old pole's column is then found directly in every frame (it is
the only bright vertical stripe against the sky near its predicted place) and the point where it meets the foreground
is found along that column. The old panels are whatever stands against the sky disconnected from the ground once the
pole is cut: they are blacked out; the old pole is blacked against the sky and inpainted where it crosses the far
ridge. The new array is projected into frame 0 and carried by the dolly model, drawn at 2x and down-sampled, so the
blanket pair keeps one consistent perspective and clean cel lines. Per-shot measurements (frame 0) are in SHOTS.
"""
import argparse, math, os, subprocess
import cv2
import numpy as np

HFOV_DEG = 60.0            # assumed lens of the shot; the Sun's size and the array's perspective follow from it
SUN_DIAM_DEG = 0.53        # mean apparent diameter of the Sun seen from the Moon
MODULE_HEIGHT_M = 5.0      # the habitat modules in the plate, used only to scale the array to the scene
MAST_M = 16.0              # NASA/TM-20210011743: 16 m telescoping mast
ARM_HALF_M = 3.0           # two 3 m blanket canisters make a 6 m cross arm
BLANKET_TOP_M, BLANKET_BOTTOM_M = 16.0, 10.0   # blankets hang from the arm, bottom raised 10 m above the surface
BLANKET_GAP_M = 0.22       # gap each side of the mast between the two blankets
FOLD_M = 0.6               # Z-fold pitch drawn on the blanket backs
MAST_D = ((0.0, 5.5, 0.42), (5.5, 11.0, 0.34), (11.0, MAST_M, 0.27))  # telescoping sections (from, to, drawn width)

SHOTS = {
    "CS-01-A": {
        "horizon_y": 328, "module_px_per_m": 120.0 / MODULE_HEIGHT_M, "module_ground_y": 445,
        "habitat_bbox": (420, 335, 780, 445),
        "sun": {"search": (0, 200, 420, 450)}, "sun_x0": 163,
        "masts": [
            {"name": "left", "pole_x": 308, "pole_w": 12, "pole_top": 300, "junction": 430, "ground_y": 430, "foot_visible": True},
            {"name": "right", "pole_x": 977, "pole_w": 9, "pole_top": 300, "junction": 338, "ground_y": 425, "foot_visible": False},
        ],
        "lit": ((0.0, 1.0), (99.0, 1.0)), "ambient": "const", "ambient0": 1.0,
    },
    "CS-02-A": {
        "horizon_y": 328, "module_px_per_m": 120.0 / MODULE_HEIGHT_M, "module_ground_y": 445,
        "habitat_bbox": (420, 335, 780, 445),
        "sun": None, "sun_x0": 163,     # the Sun has just set at the same azimuth as in CS-01
        "masts": [
            {"name": "left", "pole_x": 313, "pole_w": 9, "pole_top": 300, "junction": 415, "ground_y": 415, "foot_visible": True},
            {"name": "right", "pole_x": 970, "pole_w": 9, "pole_top": 298, "junction": 345, "ground_y": 425, "foot_visible": False},
        ],
        # last light: the top of the array keeps the Sun for a while after the ground has gone dark, then fades
        "lit": ((0.0, 1.0), (3.0, 1.0), (5.5, 0.0), (99.0, 0.0)), "ambient": "track", "ambient0": 0.49,
    },
}

SH = 4                      # fixed-point bits for sub-pixel drawing
SS = 2                      # super-sampling factor of the array layer
ERASE_HALF_W = 300          # how far either side of a pole the old panels may wander (px, frame 0 scale)

# anime cel palette (BGR, daylight)
C_OUTLINE = (36, 33, 32)
C_MAST = (150, 140, 134); C_MAST_SHADE = (96, 90, 86); C_MAST_LIT = (238, 228, 214)
C_ARM = (168, 160, 154); C_ARM_LIT = (240, 232, 220)
C_BLANKET = (74, 58, 50); C_FOLD = (92, 74, 64); C_BLANKET_RIM = (236, 226, 210)
C_SUN = (200, 238, 255)

LK = dict(winSize=(21, 21), maxLevel=4, criteria=(cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 40, 0.01))


def probe(path):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                                   "stream=width,height,r_frame_rate,nb_frames", "-of", "csv=p=0", path]).decode().strip()
    w, h, fps, n = out.split(",")
    return int(w), int(h), fps, int(n)


def decode(path, W, H):
    dec = subprocess.Popen(["ffmpeg", "-v", "error", "-i", path, "-f", "rawvideo", "-pix_fmt", "bgr24", "-"],
                           stdout=subprocess.PIPE)
    while (buf := dec.stdout.read(W * H * 3)) and len(buf) == W * H * 3:
        yield np.frombuffer(buf, np.uint8).reshape(H, W, 3).copy()
    dec.stdout.close(); dec.wait()


def mix(a, b, t):
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def scale_col(c, k):
    return tuple(max(0.0, min(255.0, v * k)) for v in c)


class Dolly:
    """Camera move read from the habitat: a similarity per frame on the module faces, smoothed."""

    def __init__(self, bbox, W, H):
        self.bbox, self.W, self.H = bbox, W, H
        self.A = np.eye(3); self.pts = None; self.s = 1.0; self.t = np.zeros(2)

    def init(self, gray):
        x0, y0, x1, y1 = self.bbox
        mask = np.zeros_like(gray); mask[y0:y1, x0:x1] = 255
        self.pts = cv2.goodFeaturesToTrack(gray, 400, 0.01, 6, mask=mask)

    def step(self, prev_gray, gray):
        if self.pts is None or len(self.pts) < 8:
            return
        nxt, st, _ = cv2.calcOpticalFlowPyrLK(prev_gray, gray, self.pts, None, **LK)
        back, st2, _ = cv2.calcOpticalFlowPyrLK(gray, prev_gray, nxt, None, **LK)
        good = (st[:, 0] == 1) & (st2[:, 0] == 1) & (np.linalg.norm((self.pts - back)[:, 0], axis=1) < 0.6)
        good &= (nxt[:, 0, 0] > 2) & (nxt[:, 0, 0] < self.W - 3) & (nxt[:, 0, 1] > 2) & (nxt[:, 0, 1] < self.H - 3)
        src, dst = self.pts[good], nxt[good]
        if len(src) >= 8:
            M, inl = cv2.estimateAffinePartial2D(src, dst, method=cv2.RANSAC, ransacReprojThreshold=1.0)
            if M is not None and inl is not None and inl.sum() >= 8:
                s = math.hypot(M[0, 0], M[1, 0])           # drop the roll: the horizon stays level in the plate
                inc = np.array([[s, 0, M[0, 2]], [0, s, M[1, 2]], [0, 0, 1]])
                self.A = inc @ self.A
                keep = inl[:, 0].astype(bool); src, dst = src[keep], dst[keep]
        self.pts = dst.reshape(-1, 1, 2).astype(np.float32) if len(dst) else None
        if self.pts is None or len(self.pts) < 120:
            x0, y0, x1, y1 = self.bbox
            c = np.array([[x0, y0, 1], [x1, y0, 1], [x1, y1, 1], [x0, y1, 1]], float) @ self.A.T
            mask = np.zeros_like(gray)
            cv2.fillPoly(mask, [np.round(c[:, :2]).astype(np.int32).reshape(-1, 1, 2)], 255)
            fresh = cv2.goodFeaturesToTrack(gray, 300, 0.01, 6, mask=mask)
            if fresh is not None:
                self.pts = fresh if self.pts is None else np.concatenate([self.pts, fresh])
        # light smoothing of the cumulative move
        self.s = 0.6 * self.s + 0.4 * self.A[0, 0]
        self.t = 0.6 * self.t + 0.4 * self.A[:2, 2]


class Mast:
    """One old mast found in each frame, and the new array drawn in its place."""

    def __init__(self, cfg, shot, W, H):
        self.cfg, self.W, self.H = cfg, W, H
        self.name = cfg["name"]
        f = W / (2 * math.tan(math.radians(HFOV_DEG / 2)))
        cx, cy = W / 2, shot["horizon_y"]
        self.f, self.cx, self.cy = f, cx, cy
        pxm_mod = shot["module_px_per_m"]
        self.h_cam = (shot["module_ground_y"] - cy) / pxm_mod           # camera height above the plain
        self.pxm = pxm_mod * (cfg["ground_y"] - cy) / (shot["module_ground_y"] - cy)
        self.Z0 = f / self.pxm
        self.Z_hab = f / pxm_mod
        self.X0 = (cfg["pole_x"] - cx) / self.pxm
        phi = math.atan2(shot["sun_x0"] - cx, f)                          # Sun azimuth from the view axis (left < 0)
        self.w = np.array([math.cos(phi), 0.0, -math.sin(phi)])           # blanket width direction (faces the Sun)
        self.lit_sign = -1 if phi < 0 else 1                              # which side of things the Sun lights
        self.A = np.eye(3)
        self.alive = True
        self.x = float(cfg["pole_x"]); self.junction = float(cfg["junction"]); self.pred_prev = self.junction
        self.pred_x_prev = self.x; self.jx = self.x; self.prev_gray = None; self.gray = None
        self.ambient = 1.0; self.amb_ref = None

    # ---- projection ----
    def P(self, X, Y, Z):
        """World (metres: X right, Y up from the plain, Z along the view) -> frame-0 pixels."""
        return np.array([self.cx + self.f * X / Z, self.cy + self.f * (self.h_cam - Y) / Z])

    def mast_pt(self, Y, dx_m=0.0):
        return self.P(self.X0 + dx_m, Y, self.Z0)

    def arm_pt(self, s_m, Y):
        p = np.array([self.X0, Y, self.Z0]) + self.w * s_m
        return self.P(*p)

    # ---- per-frame placement ----
    def update(self, dolly, lum, sky_i, valid):
        """Scale and vertical move from the dolly model; the pole's column measured; the foreground junction found."""
        s_h = max(dolly.s, 1e-3)
        d = self.Z_hab * (1 - 1 / s_h)                                   # distance the camera has come forward
        if d >= self.Z0 - 1:
            self.alive = False
            return
        s_m = self.Z0 / (self.Z0 - d)
        t_m = dolly.t * (self.Z_hab - d) / (self.Z0 - d)
        pred_x = s_m * self.cfg["pole_x"] + t_m[0]
        self.A = np.array([[s_m, 0, t_m[0]], [0, s_m, t_m[1]], [0, 0, 1]])
        top = (self.A @ np.array([self.cfg["pole_x"], self.cfg["pole_top"], 1.0]))[1]
        pred_j = (self.A @ np.array([self.cfg["pole_x"], self.cfg["junction"], 1.0]))[1]
        centre_x = self.x + (pred_x - self.pred_x_prev)      # last measurement carried by the model's change
        self.pred_x_prev = pred_x
        x_meas = self.measure_pole(lum, centre_x, top, sky_i, valid, s_m)
        x_new = x_meas if x_meas is not None else centre_x
        self.x = x_new if self.x is None else 0.3 * self.x + 0.7 * x_new
        self.A[0, 2] = self.x - s_m * self.cfg["pole_x"]
        if self.x < -ERASE_HALF_W * s_m or self.x > self.W + ERASE_HALF_W * s_m or top > self.H:
            self.alive = False
            return
        centre = self.junction + (pred_j - self.pred_prev); self.pred_prev = pred_j
        j = self.track_junction(centre)
        self.junction = 0.5 * self.junction + 0.5 * j
        if self.cfg.get("foot_visible"):              # the mast stands on its foot: anchor the drawing there
            self.A[1, 2] = self.junction - s_m * self.cfg["ground_y"]

    def measure_pole(self, lum, pred_x, top, sky_i, valid, s):
        """Centre of the bright vertical stripe (the old pole) against the sky nearest the predicted column:
        the median over rows of each row's nearest bright run, so a panel edge in some rows does not pull it."""
        x0, x1 = int(max(0, pred_x - 40)), int(min(self.W, pred_x + 41))
        if x1 - x0 < 20:
            return None
        band = sky_i[x0:x1][valid[x0:x1]]                 # the skyline beside the pole, not under it
        ridge = int(band.min()) if len(band) else int(sky_i[x0:x1].min())
        y0, y1 = int(max(0, top + 8, ridge - 45)), int(min(self.H, ridge - 10))
        if y1 - y0 < 12:
            return None
        max_w = 2.0 * self.cfg["pole_w"] * s
        centres = []
        for y in range(y0, y1):
            row = lum[y, x0:x1]
            if row.max() < 0.15:
                continue
            on = row > 0.25 * row.max()
            edges = np.diff(np.concatenate([[0], on.astype(int), [0]]))
            starts, ends = np.nonzero(edges == 1)[0], np.nonzero(edges == -1)[0]
            best = None
            for a, b in zip(starts, ends):
                if a == 0 or b == len(on) or b - a > max_w:
                    continue
                c = x0 + (a + b - 1) / 2
                if best is None or abs(c - pred_x) < abs(best - pred_x):
                    best = c
            if best is not None:
                centres.append(best)
        if len(centres) < 8:
            return None
        return float(np.median(centres))

    def track_junction(self, centre):
        """The point where the old pole meets the foreground, followed as a corner with Lucas-Kanade."""
        if self.prev_gray is None or self.gray is None:
            return centre
        p0 = np.array([[[self.jx, self.junction]]], np.float32)
        p1, st, _ = cv2.calcOpticalFlowPyrLK(self.prev_gray, self.gray, p0, None, **LK)
        p2, st2, _ = cv2.calcOpticalFlowPyrLK(self.gray, self.prev_gray, p1, None, **LK)
        ok = st[0, 0] == 1 and st2[0, 0] == 1 and np.linalg.norm(p0[0, 0] - p2[0, 0]) < 1.0
        if ok and abs(p1[0, 0, 1] - centre) < 25:
            self.jx = float(p1[0, 0, 0])
            return float(p1[0, 0, 1])
        self.jx = self.x
        return centre

    # ---- drawing ----
    def T(self, p):
        q = self.A @ np.array([p[0], p[1], 1.0])
        return q[:2]

    def poly(self, canvas, alpha, pts, color):
        q = np.array([self.T(p) for p in pts]) * SS * (1 << SH)
        q = np.round(q).astype(np.int32).reshape(-1, 1, 2)
        cv2.fillPoly(canvas, [q], color, lineType=cv2.LINE_AA, shift=SH)
        cv2.fillPoly(alpha, [q], 255, lineType=cv2.LINE_AA, shift=SH)

    def bar(self, canvas, alpha, a, b, width_px, color, outline=None):
        """A bar from frame-0 point a to b with the given width (frame-0 px), optional outline."""
        a, b = np.array(a, float), np.array(b, float)
        d = b - a
        n = np.array([-d[1], d[0]]) / (np.linalg.norm(d) + 1e-9)
        if outline:
            o = width_px / 2 + 1.0
            self.poly(canvas, alpha, [a + n * o, b + n * o, b - n * o, a - n * o], outline)
        h = width_px / 2
        self.poly(canvas, alpha, [a + n * h, b + n * h, b - n * h, a - n * h], color)

    def draw(self, canvas, alpha, lit, amb):
        """Draw the new array (frame-0 geometry carried by the dolly model) into the 2x layer."""
        k = amb
        outline = scale_col(C_OUTLINE, max(k, 0.5))
        mast_c, shade_c = scale_col(C_MAST, k), scale_col(C_MAST_SHADE, k)
        mast_lit = mix(mast_c, C_MAST_LIT, lit)                  # sunlight is not dimmed with the ambient
        arm_c, arm_lit = scale_col(C_ARM, k), mix(scale_col(C_ARM, k), C_ARM_LIT, lit)
        blanket_c, fold_c = scale_col(C_BLANKET, k), scale_col(C_FOLD, k)
        rim_c = mix(blanket_c, C_BLANKET_RIM, lit)
        pxm = self.pxm
        ls = self.lit_sign
        # blankets (behind everything else): two hanging sheets either side of the mast
        for side in (-1, 1):
            s_in, s_out = side * BLANKET_GAP_M, side * ARM_HALF_M
            tl, tr = self.arm_pt(s_in, BLANKET_TOP_M), self.arm_pt(s_out, BLANKET_TOP_M)
            bl, br = self.arm_pt(s_in, BLANKET_BOTTOM_M), self.arm_pt(s_out, BLANKET_BOTTOM_M)
            self.poly(canvas, alpha, [tl, tr, br, bl], outline)
            inset = 0.07 * pxm
            e = np.array([inset, 0]); v = np.array([0, inset])
            self.poly(canvas, alpha, [tl + e * side + v, tr - e * side + v, br - e * side - v, bl + e * side - v], blanket_c)
            y = BLANKET_TOP_M - FOLD_M
            while y > BLANKET_BOTTOM_M + 0.2:       # Z-fold lines on the back
                self.bar(canvas, alpha, self.arm_pt(s_in, y), self.arm_pt(s_out, y), 0.05 * pxm, fold_c)
                y -= FOLD_M
            s_rim = s_out if side == ls else s_in    # the Sun-side edge of each sheet catches the light
            self.bar(canvas, alpha, self.arm_pt(s_rim, BLANKET_TOP_M - 0.1), self.arm_pt(s_rim, BLANKET_BOTTOM_M + 0.1),
                     0.09 * pxm, rim_c)
        # lower support member
        self.bar(canvas, alpha, self.arm_pt(-ARM_HALF_M, BLANKET_BOTTOM_M), self.arm_pt(ARM_HALF_M, BLANKET_BOTTOM_M),
                 0.16 * pxm, arm_c, outline)
        # mast: telescoping sections, lit on the Sun side
        for y0, y1, d in MAST_D:
            a, b = self.mast_pt(y0), self.mast_pt(y1 + 0.05)
            wpx = d * pxm
            self.bar(canvas, alpha, a, b, wpx, mast_c, outline)
            off = np.array([wpx * 0.28 * ls, 0])
            self.bar(canvas, alpha, a + off, b + off, wpx * 0.34, mast_lit)
            off = np.array([-wpx * 0.33 * ls, 0])
            self.bar(canvas, alpha, a + off, b + off, wpx * 0.22, shade_c)
        # base drum (azimuth drive) at the foot; hidden by the foreground when the foot is
        self.bar(canvas, alpha, self.mast_pt(0.0), self.mast_pt(0.6), 0.8 * pxm, mast_c, outline)
        # top cross arm (the two blanket canisters) with end caps and a hub on the mast
        self.bar(canvas, alpha, self.arm_pt(-ARM_HALF_M - 0.1, MAST_M), self.arm_pt(ARM_HALF_M + 0.1, MAST_M),
                 0.36 * pxm, arm_c, outline)
        self.bar(canvas, alpha, self.arm_pt(-ARM_HALF_M - 0.1, MAST_M + 0.12), self.arm_pt(ARM_HALF_M + 0.1, MAST_M + 0.12),
                 0.1 * pxm, arm_lit)
        for s in (-ARM_HALF_M - 0.1, ARM_HALF_M + 0.1):
            self.bar(canvas, alpha, self.arm_pt(s, MAST_M - 0.25), self.arm_pt(s, MAST_M + 0.25), 0.3 * pxm, arm_c, outline)
        self.bar(canvas, alpha, self.mast_pt(MAST_M - 0.35), self.mast_pt(MAST_M + 0.35), 0.62 * pxm, mast_c, outline)
        self.bar(canvas, alpha, self.mast_pt(MAST_M - 0.3, 0.18 * ls), self.mast_pt(MAST_M + 0.3, 0.18 * ls), 0.16 * pxm, mast_lit)


def find_sun(lum, box):
    """Centre of the brightest round blob in the search box that sits in a dark ring (the Sun may touch the ridge)."""
    x0, y0, x1, y1 = box
    H, W = lum.shape
    m = np.zeros((H, W), np.uint8)
    m[y0:y1, x0:x1] = (lum[y0:y1, x0:x1] > 0.97)
    n, _, st, cen = cv2.connectedComponentsWithStats(m)
    best = None
    yy, xx = np.mgrid[0:H, 0:W]
    for i in range(1, n):
        x, y, w, h, area = st[i]
        if not 40 <= area <= 6000 or not 0.5 < w / h < 2.0 or area / (w * h) < 0.45:
            continue
        cx, cy = cen[i]
        r = math.sqrt(area / math.pi)
        ring = np.abs(np.hypot(xx - cx, yy - cy) - 3 * r) < 2
        dark = lum[ring].mean()
        if dark < 0.6 and (best is None or dark < best[3]):
            best = (cx, cy, r, dark, area / (w * h))
    return best


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("shot", choices=sorted(SHOTS))
    ap.add_argument("src"); ap.add_argument("dst")
    ap.add_argument("--debug-dir"); ap.add_argument("--every", type=int, default=24)
    a = ap.parse_args()
    shot = SHOTS[a.shot]
    W, H, fps, nframes = probe(a.src)
    fps_f = eval(fps)
    f = W / (2 * math.tan(math.radians(HFOV_DEG / 2)))
    sun_r = f * math.tan(math.radians(SUN_DIAM_DEG / 2))
    print(f"{a.shot}: {W}x{H} {fps} fps, {nframes} frames; f={f:.0f}px, Sun disc {2 * sun_r:.1f}px ({SUN_DIAM_DEG} deg)")
    masts = [Mast(m, shot, W, H) for m in shot["masts"]]
    for m in masts:
        print(f"  mast {m.name}: {m.pxm:.1f} px/m at frame 0, mast top at y={m.mast_pt(MAST_M)[1]:.0f}, "
              f"blanket x {m.arm_pt(-ARM_HALF_M, 13)[0]:.0f}..{m.arm_pt(ARM_HALF_M, 13)[0]:.0f}")
    lit_t = np.array(shot["lit"])
    if a.debug_dir:
        os.makedirs(a.debug_dir, exist_ok=True)

    # the Sun is at infinity: only the camera's pan moves it, so between clean detections it is carried by the
    # pan read from the habitat similarity (translation minus what the dolly's expansion about the principal
    # point explains); the disc is only drawn where the old Sun showed, so the foreground still hides it
    yy, xx = np.mgrid[0:H, 0:W]
    c_pp = np.array([W / 2, shot["horizon_y"]])
    sun = None; sun_pan_ref = np.zeros(2); halo = None; r_sun = None; sun_seen = 0

    enc = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "bgr24", "-s", f"{W}x{H}",
                            "-r", fps, "-i", "-", "-c:v", "libx264", "-crf", "12", "-preset", "slow",
                            "-pix_fmt", "yuv420p", "-movflags", "+faststart", a.dst], stdin=subprocess.PIPE)
    dolly = Dolly(shot["habitat_bbox"], W, H)
    prev_gray = None
    n = 0
    for frame in decode(a.src, W, H):
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        lum = frame.max(axis=2) / 255.0
        t = n / fps_f
        lit = float(np.interp(t, lit_t[:, 0], lit_t[:, 1]))
        prev_gray_for_masts = prev_gray
        if prev_gray is None:
            dolly.init(gray)
        else:
            dolly.step(prev_gray, gray)
        prev_gray = gray
        if shot["sun"]:
            pan = dolly.t - c_pp * (1 - dolly.s)
            found = find_sun(lum, shot["sun"]["search"])
            bridged = None if sun is None else sun + (pan - sun_pan_ref)
            if found and found[4] >= 0.55 and (bridged is None or np.hypot(found[0] - bridged[0], found[1] - bridged[1]) < 40):
                meas = np.array(found[:2])
                sun = meas if bridged is None else 0.3 * bridged + 0.7 * meas
                sun_pan_ref = pan.copy(); sun_seen += 1
            elif bridged is not None:
                sun = bridged; sun_pan_ref = pan.copy()
            if sun is not None:
                r_sun = np.hypot(xx - sun[0], yy - sun[1])
                B, G, R = frame[..., 0].astype(int), frame[..., 1].astype(int), frame[..., 2].astype(int)
                mx, mn = frame.max(axis=2).astype(int), frame.min(axis=2).astype(int)
                sat = (mx - mn) / np.maximum(mx, 1)
                warm = (R - B >= 10) & (R >= G - 2) & (G >= B - 4) & (sat < 0.45)
                tint = (R - B >= 5) & (R >= G - 2) & (G >= B - 4) & (sat < 0.45) & (lum < 0.5)
                halo = (r_sun < 140) & ((lum < 0.15) | warm | ((r_sun < 60) & tint))

        # cut each old pole out (a wide band round its last known column), then what touches the bottom of the
        # frame is the ground with the habitat and mounds on it; its first row per column is the skyline
        nb = lum > 0.03
        if halo is not None:
            nb &= ~halo
        cut = nb.copy()
        valid = np.ones(W, bool)
        for m in masts:
            if m.alive:
                hw = int(math.ceil((m.cfg["pole_w"] + 4) * m.A[0, 0] / 2)) + 7   # pole plus its outlines, generous
                xa, xb = int(max(0, m.x - hw)), int(max(0, min(W, m.x + hw + 1)))
                if xb > xa:
                    cut[:int(min(H, m.junction + 6)), xa:xb] = False; valid[xa:xb] = False
        ncomp, lab, st, cen = cv2.connectedComponentsWithStats(cut.astype(np.uint8), connectivity=8)
        hz = shot["horizon_y"]
        ground_ids = [i for i in range(1, ncomp) if st[i][1] + st[i][3] >= hz - 10]   # reaches the horizon or below
        ground = np.isin(lab, ground_ids)

        sky = np.where(ground.any(axis=0), ground.argmax(axis=0), H).astype(float)
        xs = np.arange(W)
        sky_i = np.interp(xs, xs[valid], sky[valid]) if valid.any() and not valid.all() else sky
        for m in masts:
            if m.alive:
                m.prev_gray, m.gray = prev_gray_for_masts, gray
                m.update(dolly, lum, sky_i, valid)

        out = frame.copy()
        # --- old panels: anything against the sky that no longer touches the ground once the poles are cut ---
        erase = np.zeros((H, W), bool)
        amb_pixels = []
        for i in range(1, ncomp):
            if i in ground_ids:
                continue
            x, y, w, h, area = st[i]
            cxi = int(min(W - 1, max(0, cen[i][0])))
            if not any(m.alive and abs(cxi - m.x) < ERASE_HALF_W * m.A[0, 0] for m in masts):
                continue
            comp = lab == i
            erase |= comp
            amb_pixels.append(lum[comp])
        erase = cv2.dilate(erase.astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
        if sun is not None:
            erase &= r_sun > 20
        out[erase] = 0
        if amb_pixels:
            v = np.concatenate(amb_pixels); v = v[(v > 0.05) & (v < 0.85)]
            if len(v) > 200:
                med = float(np.median(v))
                for m in masts:
                    if m.amb_ref is None:
                        m.amb_ref = med
                    m.ambient = 0.8 * m.ambient + 0.2 * max(0.08, min(1.2, med / m.amb_ref))
        # --- old poles: black against the sky, inpainted across the ridge down to the foreground junction ---
        for m in masts:
            if not m.alive:
                continue
            s = m.A[0, 0]
            hw = int(math.ceil(m.cfg["pole_w"] * s / 2)) + 2
            x0, x1 = int(max(0, m.x - hw)), int(max(0, min(W, m.x + hw + 1)))
            if x1 <= x0:
                continue
            ridge = int(sky_i[x0:x1].min())
            ytop, ybot = max(0, ridge - 27), int(min(H, m.junction + 3))
            out[:ytop, x0:x1] = 0
            if ybot > ytop:
                cx0, cx1 = max(0, x0 - 40), min(W, x1 + 40); cy0, cy1 = max(0, ytop - 20), min(H, ybot + 20)
                crop = out[cy0:cy1, cx0:cx1]
                mk = np.zeros(crop.shape[:2], np.uint8)
                mk[ytop - cy0:ybot - cy0, x0 - cx0:x1 - cx0] = 255
                out[cy0:cy1, cx0:cx1] = cv2.inpaint(crop, mk, 4, cv2.INPAINT_TELEA)
        # --- the Sun: halo to black, a hard 0.53 degree disc where the old core was ---
        if sun is not None:
            sx, sy = sun
            out[halo] = 0
            stray = (r_sun < 60) & ~cv2.dilate(ground.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool)
            out[stray] = 0
            ss = 4
            y0, y1 = int(max(0, sy - 12)), int(min(H, sy + 13)); x0, x1 = int(max(0, sx - 12)), int(min(W, sx + 13))
        if sun is not None and x1 > x0 and y1 > y0:
            disc = np.zeros(((y1 - y0) * ss, (x1 - x0) * ss), np.uint8)
            cv2.circle(disc, (int(round((sx - x0) * ss)), int(round((sy - y0) * ss))), int(round(sun_r * ss)), 255, -1, cv2.LINE_AA)
            disc = cv2.resize(disc, (x1 - x0, y1 - y0), interpolation=cv2.INTER_AREA).astype(float) / 255
            disc *= (lum[y0:y1, x0:x1] > 0.9)      # only where the old Sun showed (the foreground may hide it)
            patch = out[y0:y1, x0:x1].astype(float)
            out[y0:y1, x0:x1] = np.clip(patch * (1 - disc[..., None]) + np.array(C_SUN) * disc[..., None], 0, 255).astype(np.uint8)
        # --- the new arrays ---
        live = [m for m in masts if m.alive]
        if live:
            canvas = np.zeros((H * SS, W * SS, 3), np.uint8); alpha = np.zeros((H * SS, W * SS), np.uint8)
            for m in live:
                m.draw(canvas, alpha, lit, shot["ambient0"] * (m.ambient if shot["ambient"] == "track" else 1.0))
            col = cv2.resize(canvas, (W, H), interpolation=cv2.INTER_AREA).astype(float)
            al = cv2.resize(alpha, (W, H), interpolation=cv2.INTER_AREA).astype(float) / 255
            for m in live:                             # nothing below the point where the foreground hides the mast
                yj = int(round(m.junction)) + 2
                x0, x1 = int(max(0, m.x - 1.2 * m.pxm * m.A[0, 0])), int(max(0, min(W, m.x + 1.2 * m.pxm * m.A[0, 0])))
                if yj < H and x1 > x0:
                    al[yj:, x0:x1] = 0; col[yj:, x0:x1] = 0
            out = np.clip(out.astype(float) * (1 - al[..., None]) + col, 0, 255).astype(np.uint8)
        enc.stdin.write(out.tobytes())
        if a.debug_dir and n % a.every == 0:
            dbg = out.copy()
            if dolly.pts is not None:
                for p in dolly.pts[:, 0]:
                    cv2.circle(dbg, (int(p[0]), int(p[1])), 2, (255, 128, 0), -1)
            for m in live:
                cv2.line(dbg, (int(m.x), 0), (int(m.x), int(m.junction)), (255, 0, 255), 1)
                cv2.circle(dbg, (int(m.x), int(m.junction)), 5, (255, 0, 255), 1)
            dbg[erase] = (0, 0, 160)
            cv2.polylines(dbg, [np.array([[x, int(v)] for x, v in enumerate(sky_i)], np.int32).reshape(-1, 1, 2)], False, (255, 255, 0), 1)
            cv2.imwrite(os.path.join(a.debug_dir, f"{a.shot}_{n:04d}.png"), np.concatenate([frame, dbg], axis=0))
            info = ", ".join(f"{m.name}: s={m.A[0, 0]:.3f} x={m.x:.1f} junction={m.junction:.0f} amb={m.ambient:.2f}" for m in live)
            print(f"frame {n:4d} t={t:5.2f}s dolly s={dolly.s:.3f} t=({dolly.t[0]:.1f},{dolly.t[1]:.1f}) "
                  f"pts={0 if dolly.pts is None else len(dolly.pts)} lit={lit:.2f} "
                  f"sun={None if sun is None else (round(float(sun[0]), 1), round(float(sun[1]), 1))} | {info}")
        n += 1
    enc.stdin.close(); enc.wait()
    if shot["sun"]:
        print(f"Sun measured on {sun_seen} of {n} frames, carried by the pan on the rest")
    print(f"wrote {n} frames -> {a.dst}")


if __name__ == "__main__":
    main()
