"""Compose the M3-99 approval sheets and the QA contact sheet from rendered panels.

Usage: python3 compose_sheets.py <panel_dir>
Writes:
  production/concept/narrative_props/M3-99_plant_stages_v1.png
  production/concept/narrative_props/M3-99_props_v1.png
  production/qa/evidence/M3-99_contact.png
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
BG, INK, MUTED, FLAG = (236, 236, 236), (31, 42, 68), (90, 96, 108), (176, 70, 20)

PLANTS = [
    ("alo_cotyledon", "Alo: cotyledon", "12-13 Apr 2046 (day 1-2), sprout", "Purple hypocotyl, two notched heart-shaped seed leaves."),
    ("alo_trueleaf", "Alo: true leaves", "15-17 Apr (day 4-6), sprout", "First rough, toothed true leaves above the cotyledons."),
    ("alo_pods_green", "Alo: green pods (gap)", "8 May (day 27), pod_bearing", "PL_Alo_Pods is the mature look; no green-pod state existed."),
    ("alo_senescent", "Alo: senescent", "16 May (day 35), mature_pods", "PL_Alo_Pods colours + lean: straw pods, yellow leaves, purple stem."),
    ("alo_dry", "Alo: dry", "16-21 May (day 35-40), mature_dry", "Leaves brown and dry, pods brittle, deeper lean. Stem purple-brown."),
    ("tara_pods", "Tara: pods", "after the 6 May run", "Green stem and pods; mirrored mesh, never Alo's copy."),
    ("tara_senescent", "Tara: senescent", "if M3-94 approves: ~26 May", "Straw pods, yellow leaves, green stem kept."),
    ("tara_dry", "Tara: dry", "if M3-94 approves: 26-31 May", "Dry pods and leaves; faded olive stem still reads green."),
]
PROPS = [
    ("nameplates", "Alo and Tara nameplates", "CH01-S04 'two empty circles'", "Round holders, pressed-on labels. Name, seed id and stem colour in words."),
    ("n_label_holder", "'N.' label holder", "D10 option 2, CH05-S11 on", "Same holder family; 'N.' handwritten by Mei, mustard-gold band."),
    ("tool_tag", "Gear-wheel tool tag", "Clue 12, CH03-S07 annex", "Steel tag with the gear-wheel of Ferreira's old patch, stamped ENG-07."),
    ("drawer_lid_note", "Drawer-lid pencil note", "Clue 2, CH01-S03", "Pencil on the lid underside; the last line stops at 'Water at'."),
    ("working_stock_envelope", "Working-stock envelope", "CH03-S12 beat, depends on M3-94", "Kraft seed envelope, sealed, no seed count anywhere."),
    ("mugs", "Five named mugs", "CH01-S12 (four), CH04-S12 (fifth)", "PR_Mug with masking-tape labels in each role colour."),
]


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)


def tile(panel_dir, key, title, when, note, w, h):
    """One captioned tile: render on top, three caption lines below."""
    img = Image.open(os.path.join(panel_dir, key + ".png")).convert("RGB")
    cap = 118
    img.thumbnail((w, h - cap), Image.LANCZOS)
    t = Image.new("RGB", (w, h), BG)
    t.paste(img, ((w - img.width) // 2, 0))
    d = ImageDraw.Draw(t)
    y = h - cap + 10
    d.text((16, y), title, font=font(26, True), fill=INK)
    d.text((16, y + 36), when, font=font(19), fill=FLAG if "M3-94" in when or "fix" in title else MUTED)
    d.text((16, y + 64), note, font=font(17), fill=MUTED)
    return t


def header(w, title, sub):
    hd = Image.new("RGB", (w, 130), (31, 42, 68))
    d = ImageDraw.Draw(hd)
    d.text((28, 22), title, font=font(40, True), fill=(242, 194, 48))
    d.text((28, 78), sub, font=font(21), fill=(236, 238, 240))
    return hd


def sheet(rows, cols, tiles, w, h, title, sub):
    hd = header(cols * w, title, sub)
    out = Image.new("RGB", (cols * w, hd.height + rows * h), BG)
    out.paste(hd, (0, 0))
    for i, t in enumerate(tiles):
        out.paste(t, ((i % cols) * w, hd.height + (i // cols) * h))
    return out


def main(panel_dir):
    W, H = 600, 720
    plant_tiles = [tile(panel_dir, *p, W, H) for p in PLANTS]
    plants = sheet(2, 4, plant_tiles, W, H, "M3-99 for approval: Alo and Tara growth stages",
                   "Brassica rapa. Four-petal cross flowers only where flowers show (none at these stages). "
                   "No eyes, face or mouth. Alo purple stem, Tara green stem. Blender renders, no AI image, no credits.")
    plants.save(os.path.join(HERE, "M3-99_plant_stages_v1.png"), optimize=True)

    small = [tile(panel_dir, *p, W, H) for p in PROPS[:5]]
    mugs = tile(panel_dir, *PROPS[5], 5 * W, 2 * 520 // 2 + 118 + 60)
    hd = header(5 * W, "M3-99 for approval: narrative props",
                "Every word from doc 24 or STORY_FULL. English, Latin letters, no logos. Role colours from ART_BIBLE 3.")
    props = Image.new("RGB", (5 * W, hd.height + H + mugs.height), BG)
    props.paste(hd, (0, 0))
    for i, t in enumerate(small):
        props.paste(t, (i * W, hd.height))
    props.paste(mugs, (0, hd.height + H))
    props.save(os.path.join(HERE, "M3-99_props_v1.png"), optimize=True)

    # contact sheet: both sheets stacked at a common width
    cw = 2400
    a = plants.resize((cw, int(plants.height * cw / plants.width)), Image.LANCZOS)
    b = props.resize((cw, int(props.height * cw / props.width)), Image.LANCZOS)
    c = Image.new("RGB", (cw, a.height + b.height + 20), (20, 24, 32))
    c.paste(a, (0, 0)); c.paste(b, (0, a.height + 20))
    ev = os.path.join(ROOT, "production", "qa", "evidence")
    os.makedirs(ev, exist_ok=True)
    c.save(os.path.join(ev, "M3-99_contact.png"), optimize=True)


if __name__ == "__main__":
    main(sys.argv[1])
