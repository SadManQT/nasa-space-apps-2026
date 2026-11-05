#!/usr/bin/env python3
"""Adds numbered badges and a legend band to the raw habitat kit sheets (the raw sheets stay unlabelled
for image-to-3D crops). Usage: label_sheets.py <concept_dir>"""
import sys, pathlib
from PIL import Image, ImageDraw, ImageFont
D = pathlib.Path(sys.argv[1])
FONT = "/System/Library/Fonts/Helvetica.ttc"
NAVY, ORANGE, WHITE = (31, 42, 68), (242, 107, 33), (236, 238, 240)
SHEETS = {
 "A": ("Habitat kit sheet A: walls and openings", [
   ("EN_Kit_Wall_Straight", "straight wall panel, 1 m wide x 2.6 m tall, handrail, navy skirting"),
   ("EN_Kit_Wall_Corner", "inside corner, two panels at 90 deg"),
   ("EN_Kit_Wall_Window", "wall panel with pressure window, navy frame"),
   ("EN_Kit_DoorFrame", "doorway, 1.2 m x 2.1 m opening, sliding pressure door, orange handle"),
   ("EN_Kit_Hatch", "round pressure hatch ~1.2 m, bulkhead collar, locking wheel (pivot at hinge)"),
   ("EN_Kit_Wall_EquipBay", "wall panel with recessed console bay; screen is a live UI surface, no baked text")]),
 "B": ("Habitat kit sheet B: floor, ceiling, runs and corridor", [
   ("EN_Kit_FloorTile", "floor tile 1 m x 1 m, anti-slip, tie-down rings"),
   ("EN_Kit_CeilingTile", "ceiling tile 1 m x 1 m, vent grille, sensor"),
   ("EN_Kit_PipeRun", "pipe run 1 m: two water-blue coolant pipes + one air duct, flanged joint"),
   ("EN_Kit_CableRun", "cable tray 1 m, navy cover, orange latch"),
   ("EN_Kit_LightStrip", "light strip 1 m, warm-white diffuser (3200-4000 K living, 5000 K service)"),
   ("EN_Kit_BulkheadRing", "corridor bulkhead ring 2.6 m, handrails, orange pressure seal")]),
}
for key, (title, items) in SHEETS.items():
    src = D / f"01_HabitatKit_sheet_{key}.png"
    im = Image.open(src).convert("RGB")
    W, H = im.size
    band = 40 + 30 * len(items) + 16
    out = Image.new("RGB", (W, H + 56 + band), WHITE)
    out.paste(im, (0, 56))
    d = ImageDraw.Draw(out)
    f_title = ImageFont.truetype(FONT, 28); f_leg = ImageFont.truetype(FONT, 21); f_num = ImageFont.truetype(FONT, 26)
    d.rectangle((0, 0, W, 56), fill=NAVY)
    d.text((18, 13), f"LAST LIGHT ACADEMY  |  {title}  |  M1-03 concept, for approval", font=f_title, fill=WHITE)
    cols, rows = 3, 2
    for i in range(len(items)):
        cx = int((i % cols + 0.5) * W / cols); cy = int(56 + (i // cols + 0.5) * H / rows)
        bx, by = cx - int(W / cols / 2) + 28, cy - int(H / rows / 2) + 28
        d.ellipse((bx - 20, by - 20, bx + 20, by + 20), fill=ORANGE, outline=NAVY, width=3)
        n = str(i + 1); tw = d.textlength(n, font=f_num)
        d.text((bx - tw / 2, by - 15), n, font=f_num, fill=WHITE)
    y = 56 + H + 20
    d.rectangle((0, 56 + H, W, 56 + H + band), fill=WHITE)
    for i, (name, desc) in enumerate(items):
        d.ellipse((24, y - 2, 50, y + 24), fill=ORANGE, outline=NAVY, width=2)
        n = str(i + 1); tw = d.textlength(n, font=f_leg)
        d.text((37 - tw / 2, y), n, font=f_leg, fill=WHITE)
        d.text((64, y), f"{name}  -  {desc}", font=f_leg, fill=NAVY)
        y += 30
    d.text((64, y + 2), "Scale: 1 m grid snap; +Y up; pivots at base centre (doors and hatch at the hinge). Palette: ART_BIBLE.md section 3. No text baked into models.", font=ImageFont.truetype(FONT, 17), fill=(90, 90, 100))
    dst = D / f"01_HabitatKit_sheet_{key}_labelled.png"
    out.save(dst); print("wrote", dst.name, out.size)
