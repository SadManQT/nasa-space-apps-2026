#!/usr/bin/env python3
"""Compose the M3-3A review sheets from the Cycles previews build_ch03_assets.py renders.

    python3 production/tools/ch03_contact.py

Reads production/models/ch03/preview/*.png, game/assets/environment/EN_ZeroAnnex/annex.json and the five EVA
turnaround sheets, writes
  production/review/M3-3A_ch03_assets_contact.png        helmet colourways and states, descendant rack, pressed petal
  production/review/M3-3A_annex_contact.png               every annex piece at LOD0 (and the hatch and archive open)
  production/concept/turnarounds_eva_v1/00_Approval_Sheet.png   the five EVA sheets with the helmet colourways,
                                                          the one page Sadman approves (CH_Cadet_EVA)
"""
import json
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
PREVIEW = ROOT / "production/models/ch03/preview"
ANNEX = ROOT / "game/assets/environment/EN_ZeroAnnex"
EVA = ROOT / "production/concept/turnarounds_eva_v1"
REVIEW = ROOT / "production/review"
FONT = "/System/Library/Fonts/Helvetica.ttc"
NAVY, ORANGE, WHITE, GREY = (31, 42, 68), (242, 107, 33), (236, 238, 240), (120, 124, 130)


def font(size):
    return ImageFont.truetype(FONT, size)


def tile(path, size, fill=(158, 160, 165)):
    canvas = Image.new("RGB", size if isinstance(size, tuple) else (size, size), fill)
    if path.exists():
        im = Image.open(path).convert("RGB")
        im.thumbnail(canvas.size)
        canvas.paste(im, ((canvas.width - im.width) // 2, (canvas.height - im.height) // 2))
    return canvas


def header(draw, width, text, sub):
    draw.rectangle((0, 0, width, 64), fill=NAVY)
    draw.text((20, 12), text, font=font(26), fill=WHITE)
    draw.text((20, 42), sub, font=font(15), fill=(200, 205, 215))


def grid_sheet(out, title, sub, cells, cols, cell=360, cap=70):
    pad = 16
    rows = (len(cells) + cols - 1) // cols
    width = cols * (cell + pad) + pad
    height = 64 + rows * (cell + cap + pad) + pad
    sheet = Image.new("RGB", (width, height), WHITE)
    draw = ImageDraw.Draw(sheet)
    header(draw, width, title, sub)
    for i, (path, caption, detail) in enumerate(cells):
        x = pad + (i % cols) * (cell + pad)
        y = 64 + pad + (i // cols) * (cell + cap + pad)
        sheet.paste(tile(path, cell), (x, y))
        draw.rectangle((x, y, x + cell, y + cell), outline=GREY, width=1)
        draw.text((x, y + cell + 6), caption, font=font(16), fill=NAVY)
        for k, line in enumerate(textwrap.wrap(detail, 52)[:2]):
            draw.text((x, y + cell + 28 + 16 * k), line, font=font(12), fill=(60, 64, 72))
    sheet.save(out)
    print("wrote", out.relative_to(ROOT), sheet.size)


def main():
    cells = [(PREVIEW / f"PR_Helmet_Roles_{n}.png", f"PR_Helmet_Roles: {n}", d) for n, d in (
        ("Kai", "orange stripe (back-left view: stripe and flag), fit scale from helmet_roles.json"), ("Amara", "cyan stripe"), ("Mei", "green stripe"),
        ("Rafi", "purple stripe, the largest fit (head 0.36 m wide)"), ("Ferreira", "gold stripe (commander)"))]
    cells += [(PREVIEW / "PR_Helmet_Roles_visor_closed.png", "PR_Helmet_Roles: visor lowered", "Visor child rotated 78 deg about its hinge; the crown stays closed under it"),
              (PREVIEW / "PR_Helmet_Roles_left.png", "PR_Helmet_Roles: wearer's left", "Bangladesh flag decal (approved patch art) on the left cheek"),
              (PREVIEW / "PR_Helmet_Roles_right.png", "PR_Helmet_Roles: wearer's right", "Aurora mission patch decal on the right cheek"),
              (PREVIEW / "PR_Helmet_Roles_back.png", "PR_Helmet_Roles: from behind", "the role stripe runs down the back of the shell so it reads from behind"),
              (PREVIEW / "PL_Descendants_34.png", "PL_Descendants (21 Oct 2046)", "7 purple-stem and 5 green-stem descendants on the 12-position rack, grow lamp, label plates, dedication card slot"),
              (PREVIEW / "PL_Descendants_front.png", "PL_Descendants: front", "instanced from the installed Alo and Tara bloom models, decimated to 2.7k tris each"),
              (PREVIEW / "PL_Descendants_closeup.png", "PL_Descendants: close", "lobed leaves, four-petal yellow crosses, purple or green stems; no faces"),
              (PREVIEW / "PL_Descendants_Planted_34.png", "PL_Descendants_Planted (21 May 2046)", "twelve filled cassettes on planting day: levelled soil, nothing sprouted yet"),
              (PREVIEW / "PR_PressedPetal_34.png", "PR_PressedPetal", "Alo's dried petal on an archival card inside a clear sleeve; the date label is a live-UI slot"),
              (PREVIEW / "PR_PressedPetal_closeup.png", "PR_PressedPetal: close", "a real-size Brassica rapa petal, about 13 mm with its claw, pressed flat"),
              (PREVIEW / "PR_PressedPetal_Mounted_34.png", "PR_PressedPetal_Mounted", "the sleeve standing in a navy board clip for the lineage board"),
              (PREVIEW / "PR_PressedPetal_Mounted_closeup.png", "PR_PressedPetal_Mounted: close", "leans back 8 degrees in its spring clips")]
    grid_sheet(REVIEW / "M3-3A_ch03_assets_contact.png", "LAST LIGHT ACADEMY  |  Chapter 3 assets (M3-3A): helmet role variants, descendant rack, pressed petal",
               "Cycles previews, neutral studio light. Blender derivations of installed, visually approved assets; no generation credits. Gate results in asset_verification.md.", cells, 4)
    catalog = json.loads((ANNEX / "annex.json").read_text(encoding="utf-8"))
    cells = []
    for piece in catalog["pieces"]:
        cells.append((PREVIEW / f"{piece['id']}_LOD0.png", piece["id"].replace("EN_ZeroAnnex_", "") + f"  |  {piece['triangles'][0]} / {piece['triangles'][1]} tris", piece["notes"]))
    cells += [(PREVIEW / "EN_ZeroAnnex_FloorHatch_LOD0_displaced.png", "FloorHatch: the quake pose", "the 0.30 m service cover hood slid 1.2 m aside along the deck (annex.json Cover pose), the N.R. leaf still closed"),
              (PREVIEW / "EN_ZeroAnnex_FloorHatch_LOD0_open.png", "FloorHatch: leaf open", "HatchLeaf swung 100 deg about its hinge; the 0.9 m opening and the camera port clear"),
              (PREVIEW / "EN_ZeroAnnex_ChartArchive_LOD0_open.png", "ChartArchive: sealed cover open", "the route sheet exposed under its hinged clear cover; map pouch on the front")]
    grid_sheet(REVIEW / "M3-3A_annex_contact.png", "LAST LIGHT ACADEMY  |  Expedition Zero annex pieces (M3-3A), game LOD, built in Blender in the habitat kit conventions",
               "2034 generation hardware under frost; pivots at the base centre, wall faces on z = 0 facing -Z, 1 m grid; every label, chart and screen is a live-UI slot.", cells, 4)
    # the approval page: five EVA sheets stacked, the helmet colourways across the bottom
    sheets = [EVA / f"{n}_eva_sheet.png" for n in ("kai", "amara", "mei", "rafi", "ferreira")]
    w = 1376
    sh = 768
    pad = 14
    helmets = [PREVIEW / f"PR_Helmet_Roles_{n}.png" for n in ("Kai", "Amara", "Mei", "Rafi", "Ferreira")]
    hcell = (w - 4 * pad) // 5
    height = 64 + pad + 5 * (sh + 30 + pad) + hcell + 60 + pad
    page = Image.new("RGB", (w + 2 * pad, height), WHITE)
    draw = ImageDraw.Draw(page)
    header(draw, page.width, "CH_Cadet_EVA: fitted EVA suits for approval (M3-3A)  |  Tripo image / gemini_3_pro_image_preview from the v8 sheets",
           "Approve, change or decline per sheet (README.md lists the five decisions). Nothing is built from these yet; no 3D credit spent.")
    y = 64 + pad
    names = ("Kai (orange)", "Amara (cyan): braids coiled low for the helmet", "Mei (green)", "Rafi (purple)", "Ferreira (faded gold): gear-wheel patch kept on the left chest")
    for path, name in zip(sheets, names):
        im = Image.open(path).convert("RGB")
        im.thumbnail((w, sh))  # full size: Sadman approves from this page
        page.paste(im, (pad, y))
        draw.text((pad + 4, y + im.height + 6), name, font=font(16), fill=NAVY)
        y += im.height + 30 + pad
    draw.text((pad, y), "PR_Helmet_Roles: the installed helmet with the role stripe per cadet (reuse, no approval needed; shown for the complete EVA look)", font=font(15), fill=(60, 64, 72))
    y += 24
    for i, path in enumerate(helmets):
        page.paste(tile(path, hcell), (pad + i * (hcell + pad), y))
    page.save(EVA / "00_Approval_Sheet.png")
    print("wrote", (EVA / "00_Approval_Sheet.png").relative_to(ROOT), page.size)


if __name__ == "__main__":
    main()
