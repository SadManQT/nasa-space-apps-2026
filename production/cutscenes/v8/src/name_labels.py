"""Print names onto blank labels in a generated shot, tracked through the camera move (M3-97).

  python3 production/tools/heavy.py python3 production/cutscenes/v8/src/name_labels.py <spec> [track_log.json]
  (paths in the JSON are relative to its folder)

The art bible keeps readable text out of generated frames ("every label, number and screen is a UI layer"),
so the names on Tara's nameplate, the lineage label and the five mugs are composited here instead of being
asked of the image model. Each label is a quad on its blank surface in frame 0; corner features in a tracking
box around it are followed with pyramidal Lucas-Kanade optical flow (forward-backward checked), a robust
similarity or homography per frame carries the quad, and ECC alignment against the label's frame-0 surface
removes drift; the surface's defocus is measured each frame so the print blurs with it. The name is set in Avenir Next, optionally wrapped round
a cylinder (mugs), and printed with a multiply blend so the surface's own shading and line art show through.

label json: {"in": mp4, "out": mp4, "labels": [{"text": "KAI", "quad": [[x,y] x4, clockwise from top-left],
             "track": [x0, y0, x1, y1], "model": "similarity" | "homography", "ink": "#rrggbb",
             "face": 2, "fill": 0.8, "height": 0.62, "cylinder": 0.0, "tracking": 0.08, "opacity": 0.92,
             "refine": [x0, y0, x1, y1] (ECC template box; default: the quad's bounds plus 12 px)}, ...]}
"""
import json, os, subprocess, sys, tempfile
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

FONT = "/System/Library/Fonts/Avenir Next.ttc"   # faces: 0 Bold, 2 Demi Bold, 5 Medium
SS = 4                                            # label canvas supersampling per frame pixel


def probe(path):
    """Return (width, height, fps, frame count) of a video."""
    out = subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v", "-count_frames", "-show_entries",
                                   "stream=width,height,r_frame_rate,nb_read_frames", "-of", "csv=p=0", path]).decode()
    w, h, rate, n = out.strip().split(",")
    num, den = rate.split("/")
    return int(w), int(h), float(num) / float(den), int(n)


def frames(raw, w, h):
    """Yield predecoded BGR frames, keeping the decoder and encoder strictly sequential."""
    size = w * h * 3
    while True:
        buf = raw.read(size)
        if not buf:
            break
        if len(buf) != size:
            raise RuntimeError("truncated decoded frame")
        yield np.frombuffer(buf, np.uint8).reshape(h, w, 3).copy()


def label_canvas(spec, qw, qh):
    """Render the label's text as an alpha mask sized to its frame-0 quad (supersampled)."""
    cw, ch = max(8, int(qw * SS)), max(8, int(qh * SS))
    img = Image.new("L", (cw, ch), 0)
    d = ImageDraw.Draw(img)
    text, fill, spacing = spec["text"], spec.get("fill", 0.8), spec.get("tracking", 0.08)
    size = int(ch * spec.get("height", 0.62))
    while size > 6:   # largest size whose tracked width fits fill x width
        font = ImageFont.truetype(FONT, size, index=spec.get("face", 2))
        adv = [d.textlength(c, font=font) for c in text]
        width = sum(adv) + size * spacing * (len(text) - 1)
        if width <= cw * fill:
            break
        size -= 2
    asc, desc = font.getmetrics()
    box = d.textbbox((0, 0), "H", font=font)   # centre on cap height, not on descenders
    x, y = (cw - width) / 2, (ch - (box[3] - box[1])) / 2 - box[1]
    for c, a in zip(text, adv):
        d.text((x, y), c, font=font, fill=255)
        x += a + size * spacing
    mask = np.asarray(img, np.float32) / 255.0
    bend = spec.get("cylinder", 0.0)   # half-angle (degrees) of the visible print on a cylinder
    if bend:
        t = np.radians(bend)
        u = np.linspace(-1, 1, cw, dtype=np.float32)
        src = (np.arcsin(np.clip(u * np.sin(t), -1, 1)) / t + 1) * 0.5 * (cw - 1)   # screen x -> print x
        mapx = np.tile(src, (ch, 1)).astype(np.float32)
        mapy = np.tile(np.arange(ch, dtype=np.float32)[:, None], (1, cw))
        mask = cv2.remap(mask, mapx, mapy, cv2.INTER_LINEAR)
    return cv2.GaussianBlur(mask, (0, 0), SS * 0.35)


class Tracker:
    """Carries one label's quad from frame 0 through the shot with LK flow inside a tracking box."""

    def __init__(self, spec, gray):
        self.quad0 = np.float32(spec["quad"])
        x0, y0, x1, y1 = spec["track"]
        self.box0 = np.float32([[x0, y0], [x1, y0], [x1, y1], [x0, y1]])
        self.model = spec.get("model", "similarity")
        self.M = np.eye(3, dtype=np.float64)
        self.lost = False
        self.pts = self.seed(gray)
        # drift-free refinement: the label's own surface in frame 0 (outline included) is the ECC template
        qx, qy = self.quad0[:, 0], self.quad0[:, 1]
        rx0, ry0, rx1, ry1 = spec.get("refine") or [int(qx.min()) - 12, int(qy.min()) - 12, int(qx.max()) + 12, int(qy.max()) + 12]
        self.T = np.array([[1, 0, rx0], [0, 1, ry0], [0, 0, 1]], np.float64)
        self.tmpl = gray[ry0:ry1, rx0:rx1].astype(np.float32)
        self.sigma = 0.0   # defocus of the surface relative to frame 0, in frame-0 pixels

    def region(self, shape):
        """Mask of the tracking box carried to the current frame."""
        m = np.zeros(shape, np.uint8)
        cv2.fillConvexPoly(m, np.int32(self.warp(self.box0)), 255)
        return m

    def seed(self, gray):
        """Find fresh tracking corners within the moving surface."""
        p = cv2.goodFeaturesToTrack(gray, 300, 0.005, 4, mask=self.region(gray.shape), blockSize=5)
        return p if p is not None else np.empty((0, 1, 2), np.float32)

    def warp(self, pts):
        """Project reference points through the current surface transform."""
        return cv2.perspectiveTransform(pts.reshape(-1, 1, 2).astype(np.float64), self.M).reshape(-1, 2)

    def step(self, prev, cur):
        """Advance one frame using checked optical flow and planar refinement."""
        if self.lost or len(self.pts) < 6:
            self.lost = True
            return
        lk = dict(winSize=(21, 21), maxLevel=4, criteria=(cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 30, 0.01))
        nxt, st, _ = cv2.calcOpticalFlowPyrLK(prev, cur, self.pts, None, **lk)
        back, st2, _ = cv2.calcOpticalFlowPyrLK(cur, prev, nxt, None, **lk)
        fb = np.linalg.norm((back - self.pts).reshape(-1, 2), axis=1)
        h, w = cur.shape
        inside = (nxt[:, 0, 0] > 2) & (nxt[:, 0, 0] < w - 2) & (nxt[:, 0, 1] > 2) & (nxt[:, 0, 1] < h - 2)
        good = (st[:, 0] == 1) & (st2[:, 0] == 1) & (fb < 0.5) & inside
        a, b = self.pts[good], nxt[good]
        if len(a) < 6:
            self.lost = True
            return
        if self.model == "homography":
            S, inl = cv2.findHomography(a, b, cv2.RANSAC, 1.0)
        else:
            A, inl = cv2.estimateAffinePartial2D(a, b, method=cv2.RANSAC, ransacReprojThreshold=1.0)
            S = None if A is None else np.vstack([A, [0, 0, 1]])
        if S is None:
            self.lost = True
            return
        self.M = S @ self.M
        self.pts = b[inl[:, 0] == 1].reshape(-1, 1, 2)
        if len(self.pts) < 60:   # top up with fresh corners inside the carried box
            fresh = self.seed(cur)
            if len(fresh):
                self.pts = np.concatenate([self.pts, fresh]).astype(np.float32)
        self.refine(cur)

    def refine(self, cur):
        """Snap the flow estimate onto the frame-0 surface with ECC, then measure how defocused the surface is."""
        th, tw = self.tmpl.shape
        W = self.M @ self.T
        rect = cv2.perspectiveTransform(np.float64([[[0, 0]], [[tw, 0]], [[tw, th]], [[0, th]]]), W).reshape(-1, 2)
        h, w = cur.shape
        if rect[:, 0].min() < 0 or rect[:, 1].min() < 0 or rect[:, 0].max() > w or rect[:, 1].max() > h:
            return   # surface leaving the frame: keep the flow estimate
        homog = self.model == "homography"
        warp = W.astype(np.float32) if homog else (W / W[2, 2])[:2].astype(np.float32)
        try:
            cc, warp = cv2.findTransformECC(self.tmpl, cur.astype(np.float32), warp,
                                            cv2.MOTION_HOMOGRAPHY if homog else cv2.MOTION_AFFINE,
                                            (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 60, 1e-5), None, 5)
        except cv2.error:
            return
        W2 = warp.astype(np.float64) if homog else np.vstack([warp, [0, 0, 1]]).astype(np.float64)
        moved = cv2.perspectiveTransform(np.float64([[[0, 0]], [[tw, 0]], [[tw, th]], [[0, th]]]), W2).reshape(-1, 2)
        if cc < 0.5 or np.abs(moved - rect).max() > 12:
            return   # implausible jump: trust the flow for this frame
        self.M = W2 @ np.linalg.inv(self.T)
        patch = cv2.warpPerspective(cur, W2, (tw, th), flags=cv2.INTER_LINEAR | cv2.WARP_INVERSE_MAP).astype(np.float32)
        core = (slice(4, th - 4), slice(4, tw - 4))
        errs = {s: np.abs((cv2.GaussianBlur(self.tmpl, (0, 0), s) if s else self.tmpl)[core] - patch[core]).mean()
                for s in (0, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 8)}   # no 0.5 step: codec noise alone scores there
        self.sigma = min(errs, key=errs.get)

    def zoom(self):
        """Current scale of the surface relative to frame 0."""
        A = (self.M / self.M[2, 2])[:2, :2]
        return float(np.sqrt(abs(np.linalg.det(A))))


def hex_bgr(s):
    """Convert a hex ink colour to an OpenCV BGR vector."""
    s = s.lstrip("#")
    return np.float32([int(s[4:6], 16), int(s[2:4], 16), int(s[0:2], 16)])


def main(path):
    """Composite a shot and optionally save its per-frame tracking evidence."""
    base = os.path.dirname(os.path.abspath(path))
    spec = json.load(open(path))
    rel = lambda p: p if os.path.isabs(p) else os.path.join(base, p)
    src, out = rel(spec["in"]), rel(spec["out"])
    w, h, fps, n = probe(src)
    raw = tempfile.TemporaryFile()
    subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-vf", "scale=in_color_matrix=bt709:in_range=tv,format=bgr24",
                    "-f", "rawvideo", "-"], stdout=raw, check=True)
    raw.seek(0)
    enc = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "bgr24", "-s", f"{w}x{h}", "-r", f"{fps}",
                            "-i", "-", "-vf", "scale=out_color_matrix=bt709:out_range=tv,format=yuv420p", "-c:v", "libx264",
                            "-preset", "slow", "-crf", "12", "-colorspace", "bt709", "-color_primaries", "bt709",
                            "-color_trc", "bt709", "-movflags", "+faststart", out], stdin=subprocess.PIPE)
    labels, trackers, track_log, prev = spec["labels"], [], [], None   # track_log: each label's quad and blur per frame (None once lost)
    for k, frame in enumerate(frames(raw, w, h)):
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        if prev is None:
            for lb in labels:
                q = np.float32(lb["quad"])
                qw = (np.linalg.norm(q[1] - q[0]) + np.linalg.norm(q[2] - q[3])) / 2
                qh = (np.linalg.norm(q[3] - q[0]) + np.linalg.norm(q[2] - q[1])) / 2
                lb["_mask"] = label_canvas(lb, qw, qh)
                trackers.append(Tracker(lb, gray))
        else:
            for t in trackers:
                t.step(prev, gray)
        img = frame.astype(np.float32)
        row = []
        for lb, t in zip(labels, trackers):
            if t.lost:
                row.append(None)
                continue
            quad = t.warp(t.quad0).astype(np.float32)
            row.append(quad.round(1).tolist() + [round(t.sigma * t.zoom(), 2)])   # four corners, then print blur
            mh, mw = lb["_mask"].shape
            H = cv2.getPerspectiveTransform(np.float32([[0, 0], [mw, 0], [mw, mh], [0, mh]]), quad)
            a = cv2.warpPerspective(lb["_mask"], H, (w, h), flags=cv2.INTER_LINEAR)
            if t.sigma:   # match the lens: the print is as soft as the surface it sits on
                a = cv2.GaussianBlur(a, (0, 0), t.sigma * t.zoom())
            a = (a * lb.get("opacity", 0.92))[..., None]
            ink = hex_bgr(lb.get("ink", "#2a2f3a")) / 255.0
            img = img * (1 - a + a * ink)   # multiply: the print takes the surface's light and shade
        track_log.append(row)
        enc.stdin.write(np.clip(img + 0.5, 0, 255).astype(np.uint8).tobytes())
        prev = gray
    enc.stdin.close()
    if enc.wait() != 0:
        raise RuntimeError("label encode failed")
    raw.close()
    if len(sys.argv) > 2:   # optional: write the per-frame quads for review
        json.dump({"frames": len(track_log), "quads": track_log}, open(sys.argv[2], "w"))
    lost = [lb["text"] for lb, t in zip(labels, trackers) if t.lost]
    if lost or len(track_log) != n:
        raise RuntimeError(f"incomplete label tracking: {len(track_log)}/{n} frames, lost {lost}")
    print(f"LABELS {os.path.basename(out)}: {len(track_log)}/{n} frames, {len(labels)} labels"
          + (f", tracking ended early for {lost}" if lost else ""))


if __name__ == "__main__":
    main(sys.argv[1])
