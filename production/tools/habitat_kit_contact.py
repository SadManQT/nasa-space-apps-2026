#!/usr/bin/env python3
"""Compose the M1-05 habitat kit review sheets from the Cycles previews build_habitat_kit.py renders.

    python3 production/tools/habitat_kit_contact.py

Reads production/models/habitat_kit/preview/*.png and game/assets/environment/kit/kit.json, writes
  production/review/M1-05_habitat_kit_contact.png   every piece at LOD0 with id, size, triangles and file size
  production/review/M1-05_habitat_kit_lods.png      LOD0 beside LOD1 for every piece, plus the door and hatch open
"""
import json
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
PREVIEW = ROOT / "production/models/habitat_kit/preview"
KIT = ROOT / "game/assets/environment/kit"
REVIEW = ROOT / "production/review"
FONT = "/System/Library/Fonts/Helvetica.ttc"
NAVY, ORANGE, WHITE, GREY = (31, 42, 68), (242, 107, 33), (236, 238, 240), (120, 124, 130)


def font(size):
    return ImageFont.truetype(FONT, size)


def tile(path, size):
    im = Image.open(path).convert("RGB")
    im.thumbnail((size, size))
    canvas = Image.new("RGB", (size, size), (158, 160, 165))
    canvas.paste(im, ((size - im.width) // 2, (size - im.height) // 2))
    return canvas


def header(draw, width, text, sub):
    draw.rectangle((0, 0, width, 64), fill=NAVY)
    draw.text((20, 12), text, font=font(26), fill=WHITE)
    draw.text((20, 42), sub, font=font(15), fill=(200, 205, 215))


def main():
    catalog = json.loads((KIT / "kit.json").read_text(encoding="utf-8"))
    pieces = catalog["pieces"]
    cell, pad, cap = 420, 16, 106
    cols = 4
    rows = (len(pieces) + cols - 1) // cols
    width = cols * (cell + pad) + pad
    height = 64 + rows * (cell + cap + pad) + pad + 40
    sheet = Image.new("RGB", (width, height), WHITE)
    draw = ImageDraw.Draw(sheet)
    header(draw, width, "LAST LIGHT ACADEMY  |  Habitat kit, game LOD (M1-05)  |  built in Blender from the approved sheets A and B (M1-04)",
           "Cycles preview, neutral studio light. Pivots at the base centre; wall faces on z = 0 facing -Z; 1 m grid. No text baked; the bay screen is a live-UI slot.")
    for i, piece in enumerate(pieces):
        x = pad + (i % cols) * (cell + pad)
        y = 64 + pad + (i // cols) * (cell + cap + pad)
        sheet.paste(tile(PREVIEW / f"{piece['id']}_LOD0.png", cell), (x, y))
        draw.rectangle((x, y, x + cell, y + cell), outline=GREY, width=1)
        draw.ellipse((x + 8, y + 8, x + 44, y + 44), fill=ORANGE, outline=NAVY, width=2)
        n = str(i + 1)
        draw.text((x + 26 - draw.textlength(n, font=font(22)) / 2, y + 13), n, font=font(22), fill=WHITE)
        size = piece["size_m"]
        glb = KIT / (piece["id"] + "_LOD0.glb")
        draw.text((x, y + cell + 6), piece["id"], font=font(19), fill=NAVY)
        draw.text((x, y + cell + 30), f"{piece['display']}  |  {size[0]:.2f} x {size[1]:.2f} x {size[2]:.2f} m", font=font(14), fill=(60, 64, 72))
        draw.text((x, y + cell + 50), f"LOD0 {piece['triangles'][0]} tris, LOD1 {piece['triangles'][1]} tris  |  {glb.stat().st_size // 1024} KB  |  mount y {piece['mount_y']:+.2f}", font=font(14), fill=(60, 64, 72))
        for k, line in enumerate(textwrap.wrap(piece["notes"], 62)[:2]):
            draw.text((x, y + cell + 70 + 15 * k), line, font=font(12), fill=GREY)
    draw.text((pad, height - 32), "Review against production/concept/environment_v1/01_HabitatKit_sheet_A_labelled.png and _B_labelled.png; gate results in asset_verification.md.", font=font(13), fill=GREY)
    out = REVIEW / "M1-05_habitat_kit_contact.png"
    sheet.save(out)
    print("wrote", out.relative_to(ROOT), sheet.size)

    cell = 300
    cols = 6
    rows = (len(pieces) + cols - 1) // cols
    width = cols * (cell + pad) + pad
    height = 64 + rows * (2 * cell + 56 + pad) + (cell + 56 + pad) + 40
    sheet = Image.new("RGB", (width, height), WHITE)
    draw = ImageDraw.Draw(sheet)
    header(draw, width, "Habitat kit  |  LOD0 (top) against LOD1 Compatibility (bottom), then the door and hatch open states",
           "LOD1 drops the quilt relief, rivets and small controls and carries 512 px textures; the two LODs switch at 12 m in habitat_kit.gd.")
    for i, piece in enumerate(pieces):
        x = pad + (i % cols) * (cell + pad)
        y = 64 + pad + (i // cols) * (2 * cell + 56 + pad)
        sheet.paste(tile(PREVIEW / f"{piece['id']}_LOD0.png", cell), (x, y))
        sheet.paste(tile(PREVIEW / f"{piece['id']}_LOD1.png", cell), (x, y + cell + 4))
        draw.text((x, y + 2 * cell + 10), piece["id"].replace("EN_Kit_", ""), font=font(16), fill=NAVY)
        draw.text((x, y + 2 * cell + 32), f"{piece['triangles'][0]} / {piece['triangles'][1]} tris", font=font(13), fill=(60, 64, 72))
    y = 64 + pad + rows * (2 * cell + 56 + pad)
    for k, (name, caption) in enumerate((("EN_Kit_DoorFrame", "DoorFrame open: leaf slid 1.25 m into the jamb"), ("EN_Kit_Hatch", "Hatch open: leaf swung 100 deg into the room"))):
        x = pad + k * (cell + pad)
        sheet.paste(tile(PREVIEW / f"{name}_LOD0_open.png", cell), (x, y))
        draw.text((x, y + cell + 8), caption, font=font(14), fill=NAVY)
    out = REVIEW / "M1-05_habitat_kit_lods.png"
    sheet.save(out)
    print("wrote", out.relative_to(ROOT), sheet.size)


if __name__ == "__main__":
    main()
