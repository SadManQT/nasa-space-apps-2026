#!/usr/bin/env python3
"""Draw the anime face atlases for one character from its flat face render.

  make_toon_face_atlas.py <face.png> <landmarks.json> <CH_Name> <out_dir>

<face.png> comes from render_face_flat.py (its <face>.json holds the camera). The painted eyes, brows and mouth stay
on the body texture as the default state; every other state is drawn on a small face layer that first covers the
painted feature with the surrounding skin colour, so the layer is transparent in its default cell.

Writes <out_dir>/face_<part>.png for eyeL, eyeR, browL, browR, mouth and face.json with each layer's rectangle in
world space (x left-right, z up, on the face's front plane) and its atlas grid. Cell orders (row-major, top-left):
  eyes  3x2: open, half, closed, happy, wide, worried
  brows 2x2: neutral, raised, lowered, worried
  mouth 3x3: X rest, A closed pressed (M B P), B slightly open, C open (E), D wide (AA), E round (O),
             F pucker (U W), G teeth on lip (F V), H tongue (L)
Run with --selftest to check the drawing on a synthetic face.
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 4  # supersampling for anti-aliased drawing
EYE_GRID, BROW_GRID, MOUTH_GRID = (3, 2), (2, 2), (3, 3)


def lum(a):
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def skin_colour(img, box, pad):
    """Median colour of the light, non-background pixels in a ring around box."""
    x0, y0, x1, y1 = box; w, h = x1 - x0, y1 - y0
    X0, Y0 = max(0, int(x0 - pad * w)), max(0, int(y0 - pad * h)); X1, Y1 = min(img.shape[1], int(x1 + pad * w)), min(img.shape[0], int(y1 + pad * h))
    ring = img[Y0:Y1, X0:X1].reshape(-1, 3).astype(float)
    inner = np.zeros((Y1 - Y0, X1 - X0), bool); inner[int(y0 - Y0):int(y1 - Y0), int(x0 - X0):int(x1 - X0)] = True
    ring = ring[~inner.reshape(-1)]
    magenta = (ring[:, 0] > 200) & (ring[:, 1] < 60) & (ring[:, 2] > 200)
    L = lum(ring)
    keep = ring[(~magenta) & (L >= np.percentile(L[~magenta], 40))]
    return tuple(int(v) for v in np.median(keep, axis=0))


def feature_mask(img, box, skin, search=(0.2, 0.1)):
    """Pixels that differ clearly from skin inside the padded box: lash lines, iris, sclera, brow, lip line."""
    x0, y0, x1, y1 = box; w, h = x1 - x0, y1 - y0
    X0, Y0 = max(0, int(x0 - search[0] * w)), max(0, int(y0 - search[1] * h)); X1, Y1 = min(img.shape[1], int(x1 + search[0] * w)), min(img.shape[0], int(y1 + search[1] * h))
    sub = img[Y0:Y1, X0:X1].astype(float)
    d = np.sqrt(((sub - np.array(skin, float)) ** 2).sum(-1))
    magenta = (sub[..., 0] > 200) & (sub[..., 1] < 60) & (sub[..., 2] > 200)
    return (d > 55) & ~magenta, (X0, Y0)


def tight_box(mask, origin, seed_box):
    ys, xs = np.nonzero(mask)
    if len(xs) < 10:
        return list(seed_box)
    # keep the component around the seed centre: drop pixels far outside the seed box
    sx0, sy0, sx1, sy1 = seed_box; cx, cy = (sx0 + sx1) / 2 - origin[0], (sy0 + sy1) / 2 - origin[1]
    w, h = sx1 - sx0, sy1 - sy0
    keep = (abs(xs - cx) < 0.62 * w) & (abs(ys - cy) < 0.75 * h)
    xs, ys = xs[keep], ys[keep]
    return [int(xs.min() + origin[0]), int(ys.min() + origin[1]), int(xs.max() + origin[0] + 1), int(ys.max() + origin[1] + 1)]


def dark_colour(img, box):
    x0, y0, x1, y1 = box; sub = img[y0:y1, x0:x1].reshape(-1, 3).astype(float)
    L = lum(sub); return tuple(int(v) for v in np.median(sub[L <= np.percentile(L, 8)], axis=0))


def feathered_fill(size, core, skin, feather):
    """RGBA skin layer: opaque over core (cell-local box), fading to 0 at feather px outside it."""
    W, H = size; yy, xx = np.mgrid[0:H, 0:W]
    cx0, cy0, cx1, cy1 = core
    dx = np.maximum(np.maximum(cx0 - xx, xx - cx1), 0); dy = np.maximum(np.maximum(cy0 - yy, yy - cy1), 0)
    a = np.clip(1 - np.sqrt(dx ** 2 + dy ** 2) / max(feather, 1), 0, 1)
    out = np.zeros((H, W, 4), np.uint8); out[..., :3] = skin; out[..., 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def curve(p0, p1, sag, n=24):
    """Quadratic curve between p0 and p1 whose middle is moved down by sag (negative = up)."""
    mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2 + 2 * sag
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * mx + t * t * p1[0], (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * my + t * t * p1[1])
            for t in (i / (n - 1) for i in range(n))]


def stroke(draw, pts, colour, width):
    """Tapered stroke: thick in the middle, thin at the ends."""
    n = len(pts)
    for i in range(n - 1):
        t = i / (n - 2) if n > 2 else 0.5
        wdt = max(1, int(width * (0.45 + 0.55 * math.sin(math.pi * t))))
        draw.line([pts[i], pts[i + 1]], fill=colour, width=wdt)
        draw.ellipse([pts[i][0] - wdt / 2, pts[i][1] - wdt / 2, pts[i][0] + wdt / 2, pts[i][1] + wdt / 2], fill=colour)


def eye_cells(img, tbox, skin, lash, inner_right):
    """Six eye cells for the eye whose tight paint box is tbox (render px)."""
    ex0, ey0, ex1, ey1 = tbox; ew, eh = ex1 - ex0, ey1 - ey0
    pad_x, pad_y = 0.14 * ew, 0.32 * eh
    W, H = int(ew + 2 * pad_x), int(eh + 2 * pad_y)
    t = max(3.0, 0.11 * eh) * SS
    core = (pad_x, pad_y * 0.7, pad_x + ew, pad_y + eh * 1.05)
    L = (pad_x * SS, (pad_y + 0.55 * eh) * SS); R = ((pad_x + ew) * SS, (pad_y + 0.5 * eh) * SS)
    inner, outer = (R, L) if inner_right else (L, R)
    cells = []
    for kind in ("open", "half", "closed", "happy", "wide", "worried"):
        if kind in ("open", "wide"):
            cells.append(Image.new("RGBA", (W, H), (0, 0, 0, 0))); continue
        fill = feathered_fill((W, H), core, skin, 0.22 * eh)
        big = fill.resize((W * SS, H * SS), Image.LANCZOS); d = ImageDraw.Draw(big)
        if kind == "half" or kind == "worried":
            # cover from the top down to the lid line, keep the painted iris below it visible
            if kind == "half":
                lid = curve((L[0], (pad_y + 0.30 * eh) * SS), (R[0], (pad_y + 0.30 * eh) * SS), -0.10 * eh * SS)
            else:
                yi, yo = (pad_y + 0.12 * eh) * SS, (pad_y + 0.48 * eh) * SS
                lid = curve((inner[0], yi), (outer[0], yo), -0.05 * eh * SS)
                if inner[0] > outer[0]: lid = lid[::-1]
            mask = Image.new("L", big.size, 0); md = ImageDraw.Draw(mask)
            md.polygon([(0, 0), (big.size[0], 0), (big.size[0], lid[-1][1])] + lid[::-1] + [(0, lid[0][1])], fill=255)
            big.putalpha(Image.fromarray(np.minimum(np.array(big.getchannel("A")), np.array(mask.filter(ImageFilter.GaussianBlur(SS))))))
            d = ImageDraw.Draw(big); stroke(d, lid, lash + (255,), t)
        elif kind == "closed":
            stroke(d, curve(L, R, 0.16 * eh * SS), lash + (255,), t)
            stroke(d, curve(outer, (outer[0] + (0.10 if outer is R else -0.10) * ew * SS, outer[1] - 0.12 * eh * SS), 0), lash + (255,), t * 0.7)
        elif kind == "happy":
            mid_y = (pad_y + 0.50 * eh) * SS
            stroke(d, curve((L[0] + 0.05 * ew * SS, mid_y + 0.18 * eh * SS), (R[0] - 0.05 * ew * SS, mid_y + 0.18 * eh * SS), -0.32 * eh * SS), lash + (255,), t)
        cells.append(big.resize((W, H), Image.LANCZOS))
    rect = (ex0 - pad_x, ey0 - pad_y, ex1 + pad_x, ey1 + pad_y)
    return cells, rect


def brow_cells(img, tbox, skin, inner_right):
    bx0, by0, bx1, by1 = tbox; bw, bh = bx1 - bx0, by1 - by0
    pad_x, pad_y = 0.18 * bw, 0.95 * bh
    W, H = int(bw + 2 * pad_x), int(bh + 2 * pad_y)
    src = img[by0:by1, bx0:bx1].astype(float)
    L = lum(src); sl = 0.299 * skin[0] + 0.587 * skin[1] + 0.114 * skin[2]
    alpha = np.clip((sl - L) / (0.45 * sl), 0, 1)
    brow = np.zeros((bh, bw, 4), np.uint8); brow[..., :3] = src.astype(np.uint8); brow[..., 3] = (alpha * 255).astype(np.uint8)
    brow = Image.fromarray(brow, "RGBA")
    core = (pad_x - 2, pad_y - 2, pad_x + bw + 2, pad_y + bh + 2)
    cells = []
    for kind, dy, rot in (("neutral", 0, 0), ("raised", -0.50, 0), ("lowered", 0.32, -7), ("worried", -0.18, 11)):
        if kind == "neutral":
            cells.append(Image.new("RGBA", (W, H), (0, 0, 0, 0))); continue
        cell = feathered_fill((W, H), core, skin, 0.35 * bh)
        r = rot if inner_right else -rot          # positive lifts the inner (nose-side) end
        b = brow.rotate(r, resample=Image.BICUBIC, expand=True)
        ox = int(pad_x - (b.width - bw) / 2); oy = int(pad_y + dy * bh - (b.height - bh) / 2)
        cell.alpha_composite(b, (max(0, ox), max(0, oy)))
        cells.append(cell)
    return cells, (bx0 - pad_x, by0 - pad_y, bx1 + pad_x, by1 + pad_y)


def mouth_rect(img, tbox, skin):
    """Cell rectangle around the mouth line, clipped where skin stops (nose, beard, chin line)."""
    mx0, my0, mx1, my1 = tbox; mw = mx1 - mx0; cx = (mx0 + mx1) // 2; cy = (my0 + my1) // 2
    sk = np.array(skin, float)
    def is_skin(x, y):
        return np.sqrt(((img[y, x].astype(float) - sk) ** 2).sum()) < 45
    cols = (cx - mw // 4, cx, cx + mw // 4)
    def reach(start, step, limit):
        """Distance from the line centre to where skin stops, past the line's own soft edge."""
        d = start
        while d < start + 20 and not all(is_skin(x, cy + step * d) for x in cols): d += 1   # a curved line sits off-centre at the side columns
        while d < limit and all(is_skin(x, cy + step * d) for x in cols): d += 1
        return d
    up = reach(cy - my0, -1, int(0.30 * mw))
    down = reach(my1 - cy, 1, int(0.40 * mw))
    left = cx - mx0 + 3
    while left < 0.62 * mw and is_skin(cx - left, cy - (my1 - my0)) and is_skin(cx - left, cy + (my1 - my0)): left += 1
    right = mx1 - cx + 3
    while right < 0.62 * mw and is_skin(cx + right, cy - (my1 - my0)) and is_skin(cx + right, cy + (my1 - my0)): right += 1
    return (cx - left + 2, cy - up + 2, cx + right - 2, cy + down - 2)


def mouth_tight(img, seed, skin):
    """Mouth line box: the measured seed's width, the painted line's own rows (beard and lips around it ignored)."""
    x0, y0, x1, y1 = seed; sub = img[y0:y1, x0:x1].astype(float)
    dark = np.sqrt(((sub - np.array(skin, float)) ** 2).sum(-1)) > 55
    rows = np.nonzero(dark[:, int(0.3 * (x1 - x0)):int(0.7 * (x1 - x0))].mean(1) > 0.5)[0]
    if len(rows) == 0: return list(seed), 3.0
    thick = float(np.median(dark[:, int(0.3 * (x1 - x0)):int(0.7 * (x1 - x0))].sum(0)))
    return [x0, y0 + int(rows.min()), x1, y0 + int(rows.max()) + 1], max(2.0, thick)


def mouth_cells(img, tbox, rect, skin, line, line_px):
    mx0, my0, mx1, my1 = tbox; mw = mx1 - mx0
    rx0, ry0, rx1, ry1 = rect; W, H = int(rx1 - rx0), int(ry1 - ry0)
    cx, cy = (mx0 + mx1) / 2 - rx0, (my0 + my1) / 2 - ry0
    room = 2 * min(cy, H - cy) * 0.92
    t = float(np.clip(line_px * 0.9, 3.0, 0.03 * mw))
    inside, teeth, tongue = (88, 24, 30), (246, 244, 238), (214, 106, 112)
    core = (mx0 - rx0 - 0.04 * mw, my0 - ry0 - t, mx1 - rx0 + 0.04 * mw, my1 - ry0 + t)
    def mouth(w, h, top_flat=False, teeth_frac=0.0, tongue_frac=0.0, tongue_up=False):
        h = min(h, room); w = min(w, 1.15 * mw)
        cell = feathered_fill((W, H), core, skin, 0.10 * mw)
        big = cell.resize((W * SS, H * SS), Image.LANCZOS); d = ImageDraw.Draw(big)
        box = [(cx - w / 2) * SS, (cy - h * (0.35 if top_flat else 0.5)) * SS, (cx + w / 2) * SS, (cy + h * (0.65 if top_flat else 0.5)) * SS]
        clip = Image.new("L", big.size, 0); ImageDraw.Draw(clip).rounded_rectangle(box, radius=min(w, h) * 0.48 * SS, fill=255)
        layer = Image.new("RGBA", big.size, inside + (255,)); ld = ImageDraw.Draw(layer)
        if teeth_frac: ld.rectangle([box[0], box[1], box[2], box[1] + (box[3] - box[1]) * teeth_frac], fill=teeth + (255,))
        if tongue_frac:
            ty = box[1] if tongue_up else box[3] - (box[3] - box[1]) * tongue_frac
            ld.ellipse([box[0] + (box[2] - box[0]) * 0.18, ty, box[2] - (box[2] - box[0]) * 0.18, ty + (box[3] - box[1]) * tongue_frac * 1.6], fill=tongue + (255,))
        big.paste(layer, (0, 0), clip)
        d.rounded_rectangle(box, radius=min(w, h) * 0.48 * SS, outline=line + (255,), width=int(t * SS * 0.8))
        return big.resize((W, H), Image.LANCZOS)
    def closed_line(width_frac, thick, teeth_strip=False):
        cell = feathered_fill((W, H), core, skin, 0.10 * mw)
        big = cell.resize((W * SS, H * SS), Image.LANCZOS); d = ImageDraw.Draw(big)
        x0, x1 = (cx - width_frac * mw / 2) * SS, (cx + width_frac * mw / 2) * SS
        if teeth_strip:
            d.rounded_rectangle([(cx - 0.22 * mw) * SS, (cy - 0.075 * mw) * SS, (cx + 0.22 * mw) * SS, cy * SS], radius=0.02 * mw * SS, fill=teeth + (255,), outline=line + (255,), width=int(t * SS * 0.6))
        stroke(d, curve((x0, cy * SS), (x1, cy * SS), 0.012 * mw * SS), line + (255,), thick * SS)
        return big.resize((W, H), Image.LANCZOS)
    cells = [Image.new("RGBA", (W, H), (0, 0, 0, 0)),                    # X: the painted mouth
             closed_line(0.80, t * 1.5),                                  # A: pressed
             mouth(0.56 * mw, 0.11 * mw, teeth_frac=0.5),                 # B
             mouth(0.62 * mw, 0.20 * mw, teeth_frac=0.32, tongue_frac=0.3),  # C
             mouth(0.60 * mw, 0.34 * mw, top_flat=True, teeth_frac=0.22, tongue_frac=0.35),  # D
             mouth(0.38 * mw, 0.28 * mw, teeth_frac=0.15),                # E
             mouth(0.22 * mw, 0.17 * mw),                                 # F
             closed_line(0.62, t * 1.1, teeth_strip=True),                # G
             mouth(0.50 * mw, 0.22 * mw, tongue_frac=0.45, tongue_up=True)]  # H
    return cells


def atlas(cells, grid):
    cols, rows = grid; W, H = cells[0].size
    out = Image.new("RGBA", (W * cols, H * rows), (0, 0, 0, 0))
    for i, c in enumerate(cells): out.paste(c.resize((W, H)), ((i % cols) * W, (i // cols) * H))
    return out


def build(face_png, marks, out_dir):
    img = np.array(Image.open(face_png).convert("RGB")); cam = json.load(open(face_png.rsplit(".", 1)[0] + ".json"))
    res, size = cam["res"], cam["size"]
    to_world = lambda px, py: (cam["cx"] + (px / res - 0.5) * size, cam["cz"] - (py / res - 0.5) * size)
    os.makedirs(out_dir, exist_ok=True); layers = {}
    parts = ("eyeL", "eyeR", "mouth") if marks.get("no_brows") else ("eyeL", "eyeR", "browL", "browR", "mouth")
    for part in parts:
        seed = marks[part]; skin = skin_colour(img, seed, 0.45 if part.startswith("eye") else 0.6)
        if part == "mouth":
            tb, line_px = mouth_tight(img, seed, skin)
        else:
            m, o = feature_mask(img, seed, skin, (0.2, 0.1) if part.startswith("eye") else (0.15, 0.04)); tb = tight_box(m, o, seed)
        inner_right = part.endswith("R")          # the character's right eye is on the viewer's left: its inner corner is to the right
        if part.startswith("eye"):
            cells, rect = eye_cells(img, tb, skin, dark_colour(img, tb), inner_right); grid = EYE_GRID
        elif part.startswith("brow"):
            cells, rect = brow_cells(img, tb, skin, inner_right); grid = BROW_GRID
        else:
            rect = mouth_rect(img, tb, skin); cells = mouth_cells(img, tb, rect, skin, dark_colour(img, tb), line_px); grid = MOUTH_GRID
        atlas(cells, grid).save(os.path.join(out_dir, f"face_{part}.png"))
        (x0, z1), (x1, z0) = to_world(rect[0], rect[1]), to_world(rect[2], rect[3])
        layers[part] = {"rect_world": [x0, z0, x1, z1], "grid": list(grid), "tight_px": tb, "rect_px": [round(v, 1) for v in rect], "skin": skin}
        print(f"{part}: tight {tb} cell {rect[2]-rect[0]:.0f}x{rect[3]-rect[1]:.0f}px skin {skin}")
    json.dump(layers, open(os.path.join(out_dir, "face.json"), "w"), indent=1)


def selftest():
    import tempfile
    d = tempfile.mkdtemp(); W = 2048
    im = Image.new("RGB", (W, W), (240, 190, 150)); dr = ImageDraw.Draw(im)
    for cx in (780, 1260):
        dr.ellipse([cx - 110, 1260, cx + 110, 1360], fill=(250, 250, 250), outline=(20, 20, 20), width=10); dr.ellipse([cx - 45, 1270, cx + 45, 1355], fill=(30, 20, 20))
        dr.rectangle([cx - 120, 1140, cx + 120, 1170], fill=(25, 20, 20))
    dr.line([(860, 1750), (1180, 1750)], fill=(60, 30, 30), width=8)
    im.save(f"{d}/face.png"); json.dump({"cx": 0, "cz": 1.6, "size": 0.32, "res": W}, open(f"{d}/face.json", "w"))
    marks = {"eyeR": [650, 1240, 910, 1380], "eyeL": [1130, 1240, 1390, 1380], "browR": [640, 1120, 920, 1190], "browL": [1120, 1120, 1400, 1190], "mouth": [840, 1735, 1200, 1765]}
    build(f"{d}/face.png", marks, f"{d}/out")
    f = json.load(open(f"{d}/out/face.json"))
    assert abs(f["eyeR"]["tight_px"][0] - 660) < 25 and abs(f["eyeR"]["tight_px"][2] - 900) < 25, f["eyeR"]
    assert f["mouth"]["rect_world"][0] < f["mouth"]["rect_world"][2] and f["mouth"]["rect_world"][1] < f["mouth"]["rect_world"][3]
    a = np.array(Image.open(f"{d}/out/face_eyeR.png")); W3 = a.shape[1] // 3
    assert a[: a.shape[0] // 2, :W3, 3].max() == 0, "open cell must be transparent"
    assert a[: a.shape[0] // 2, 2 * W3:, 3].mean() > 40, "closed cell must cover the eye"
    print("SELFTEST PASS", d)


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        selftest()
    else:
        face_png, marks_json, name, out_dir = sys.argv[1:5]
        build(face_png, json.load(open(marks_json))[name], out_dir)
