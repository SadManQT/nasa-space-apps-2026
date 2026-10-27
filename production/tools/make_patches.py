#!/usr/bin/env python3
"""Draw the crew sleeve patches as clean 1024 px images (no text, no agency marks).

  make_patches.py <out_dir>

patch_bangladesh.png: the national flag, 10:6, bottle green with a red disc of radius 1/5 of the length centred at
9/20 of the length from the hoist (official proportions), with a thin stitched border. Worn on the LEFT sleeve with the
hoist toward the front.
patch_aurora.png: the round expedition patch: navy field, a yellow four-petal mustard flower with an orange centre, a
white crescent Moon, an orange stitched rim.
"""
import math, os, sys
from PIL import Image, ImageDraw

SS = 4
GREEN, RED = (0, 106, 78), (244, 42, 65)
NAVY, YELLOW, ORANGE, WHITE, STITCH = (27, 42, 74), (245, 197, 24), (232, 120, 30), (246, 244, 236), (210, 210, 200)


def flag(path, W=1024):
    H = int(W * 0.6); im = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    b = int(0.035 * H * SS)
    d.rounded_rectangle([0, 0, W * SS - 1, H * SS - 1], radius=b, fill=STITCH)
    d.rounded_rectangle([b, b, W * SS - 1 - b, H * SS - 1 - b], radius=b // 2, fill=GREEN)
    cx, cy, r = 0.45 * W * SS, 0.5 * H * SS, 0.2 * W * SS
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=RED)
    for i in range(0, W * SS, 6 * SS):                       # stitches along the border
        d.line([(i, b // 2), (i + 3 * SS, b // 2)], fill=GREEN, width=SS); d.line([(i, H * SS - b // 2), (i + 3 * SS, H * SS - b // 2)], fill=GREEN, width=SS)
    im.resize((W, H), Image.LANCZOS).save(path)


def aurora(path, W=1024):
    im = Image.new("RGBA", (W * SS, W * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(im); C = W * SS / 2
    rim = 0.06 * W * SS
    d.ellipse([0, 0, W * SS - 1, W * SS - 1], fill=ORANGE)
    d.ellipse([rim, rim, W * SS - rim, W * SS - rim], fill=NAVY)
    n = 72
    for k in range(n):                                       # stitches on the rim
        a = 2 * math.pi * k / n; r0, r1 = C - rim * 0.55, C - rim * 0.25
        d.line([(C + r0 * math.cos(a), C + r0 * math.sin(a)), (C + r1 * math.cos(a + 0.03), C + r1 * math.sin(a + 0.03))], fill=STITCH, width=SS * 2)
    # crescent Moon, upper right
    mr = 0.20 * W * SS; mx, my = C + 0.17 * W * SS, C - 0.16 * W * SS
    moon = Image.new("L", im.size, 0); md = ImageDraw.Draw(moon)        # the crescent alone: a disc minus an offset disc
    md.ellipse([mx - mr, my - mr, mx + mr, my + mr], fill=255)
    md.ellipse([mx - mr + 0.12 * W * SS, my - mr - 0.06 * W * SS, mx + mr + 0.12 * W * SS, my + mr - 0.06 * W * SS], fill=0)
    im.paste(Image.new("RGBA", im.size, WHITE + (255,)), (0, 0), moon); d = ImageDraw.Draw(im)
    # four-petal mustard flower, lower left of centre
    fx, fy, pr = C - 0.06 * W * SS, C + 0.08 * W * SS, 0.12 * W * SS
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2; px, py = fx + pr * 0.95 * math.cos(a), fy + pr * 0.95 * math.sin(a)
        d.ellipse([px - pr * 0.82, py - pr * 0.82, px + pr * 0.82, py + pr * 0.82], fill=YELLOW)
    d.ellipse([fx - pr * 0.42, fy - pr * 0.42, fx + pr * 0.42, fy + pr * 0.42], fill=ORANGE)
    im.resize((W, W), Image.LANCZOS).save(path)


def check_aurora(path):
    a = Image.open(path).convert("RGBA"); W = a.width
    for ang in range(0, 360, 5):                               # nothing but rim colour or transparency outside the navy field
        r = 0.485 * W; x, y = int(W / 2 + r * math.cos(math.radians(ang))), int(W / 2 + r * math.sin(math.radians(ang)))
        px = a.getpixel((x, y)); assert px[3] < 20 or (px[0] > 150 and px[2] < 120) or min(px[:3]) > 180, (ang, px)


if __name__ == "__main__":
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    flag(os.path.join(out, "patch_bangladesh.png")); aurora(os.path.join(out, "patch_aurora.png"))
    a = Image.open(os.path.join(out, "patch_bangladesh.png")); assert a.size == (1024, 614)
    px = a.getpixel((int(0.45 * 1024), 307)); assert px[0] > 200 and px[1] < 80, px      # disc centre is red
    px = a.getpixel((900, 307)); assert px[1] > 90 and px[0] < 40, px                  # fly side is green
    check_aurora(os.path.join(out, "patch_aurora.png"))
    print("PATCHES ->", out)
