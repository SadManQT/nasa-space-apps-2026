#!/usr/bin/env python3
"""Review contact sheet for M1-03: all candidate frames and the two alternates on one page."""
import sys, pathlib
from PIL import Image, ImageDraw, ImageFont
D = pathlib.Path(sys.argv[1]); OUT = pathlib.Path(sys.argv[2])
F = "/System/Library/Fonts/Helvetica.ttc"
cells = [("01_HabitatKit_sheet_A_labelled.png", "Kit sheet A: walls and openings"),
         ("01_HabitatKit_sheet_B_labelled.png", "Kit sheet B: floor, ceiling, runs, bulkhead"),
         ("02_Commons_mood.png", "LOC-01 Commons (candidate)"), ("03_ServiceRooms_mood.png", "LOC-02 Service rooms (candidate)"),
         ("04_Garden_mood.png", "LOC-03 Garden + Alo chamber (candidate)"), ("05_SafeRoom_mood.png", "LOC-04 Safe Room (candidate)"),
         ("06_Exterior_mood.png", "LOC-06 Exterior (candidate; 3 masts, canon twin)"), ("02_Commons_mood_alt_anime.png", "Commons alternate (illustrated)"),
         ("04_Garden_mood_alt_anime.png", "Garden alternate (illustrated)")]
W, cols, pad, cap = 640, 3, 16, 34
rows = (len(cells) + cols - 1) // cols
thumbs = []
for f, t in cells:
    im = Image.open(D / f).convert("RGB"); h = int(im.height * W / im.width); thumbs.append((im.resize((W, h)), t))
rh = [max(th.height for th, _ in thumbs[r*cols:(r+1)*cols]) + cap for r in range(rows)]
sheet = Image.new("RGB", (cols * (W + pad) + pad, 70 + sum(rh) + pad * rows), (24, 26, 32))
d = ImageDraw.Draw(sheet)
d.text((pad, 18), "Last Light Academy — M1-03 habitat kit and Chapter 1 room concepts — for Sadman's approval (M1-04)", font=ImageFont.truetype(F, 30), fill=(236, 238, 240))
y = 70
for r in range(rows):
    for c in range(cols):
        i = r * cols + c
        if i >= len(thumbs): break
        th, t = thumbs[i]; x = pad + c * (W + pad)
        sheet.paste(th, (x, y)); d.text((x, y + th.height + 6), t, font=ImageFont.truetype(F, 22), fill=(242, 194, 48))
    y += rh[r] + pad
sheet.save(OUT); print("wrote", OUT, sheet.size)
