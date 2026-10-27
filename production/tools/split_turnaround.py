#!/usr/bin/env python3
"""Split a one-row turnaround sheet into front/left/back/right PNGs for Tripo multiview.

  split_turnaround.py <sheet.png> <out_dir> [front,right,back,left]

The optional order names the views left-to-right as they appear on the sheet
(default front,left,back,right). A "left" view shows the character's left side.
Finds the four figures by background colour (sampled from the top-left corner), not by
equal quarters, then pads each onto a square canvas of that background.
"""
import sys
from pathlib import Path
from PIL import Image, ImageChops

VIEWS = ("front", "left", "back", "right")


def figure_columns(img, threshold=25, min_gap=12):
    bg = img.getpixel((4, 4))
    mask = ImageChops.difference(img, Image.new("RGB", img.size, bg)).convert("L")
    mask = mask.point(lambda v: 255 if v > threshold else 0)
    cols = list(mask.resize((img.width, 1), Image.BOX).get_flattened_data())  # mean per column
    runs, start, gap = [], None, 0
    for x, v in enumerate(cols + [0] * (min_gap + 1)):
        if v > 2:
            start, gap = (x if start is None else start), 0
        elif start is not None:
            gap += 1
            if gap > min_gap:
                runs.append((start, x - gap + 1))
                start = None
    return bg, mask, sorted(sorted(runs, key=lambda r: r[1] - r[0])[-4:])  # 4 widest, left->right


def split(sheet, out_dir, order=",".join(VIEWS)):
    views = order.split(",")
    if sorted(views) != sorted(VIEWS):
        sys.exit(f"order must be a permutation of {','.join(VIEWS)}")
    img = Image.open(sheet).convert("RGB")
    bg, mask, runs = figure_columns(img)
    if len(runs) != 4:
        sys.exit(f"expected 4 figures, found {len(runs)}: {runs}")
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for view, (x0, x1) in zip(views, runs):
        top, bottom = mask.crop((x0, 0, x1, img.height)).getbbox()[1::2]
        fig = img.crop((x0, top, x1, bottom))
        side = int(max(fig.size) * 1.1)
        canvas = Image.new("RGB", (side, side), bg)
        canvas.paste(fig, ((side - fig.width) // 2, (side - fig.height) // 2))
        canvas.save(out / f"{view}.png")
        print(out / f"{view}.png", fig.size)


def selftest():
    img = Image.new("RGB", (400, 200), (217, 217, 217))
    for i, x in enumerate((20, 120, 220, 320)):
        img.paste((40, 40, 40), (x, 30 + i, x + 50 + i * 5, 170))
    _, _, runs = figure_columns(img)
    assert runs == [(20, 70), (120, 175), (220, 280), (320, 385)], runs
    print("selftest OK")


if __name__ == "__main__":
    selftest() if sys.argv[1:] == ["--selftest"] else split(*sys.argv[1:4])
