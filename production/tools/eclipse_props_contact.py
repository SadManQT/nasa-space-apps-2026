#!/usr/bin/env python3
"""Compose the M3-6A eclipse power props review sheets from the Cycles previews build_eclipse_props.py renders.

    python3 production/tools/eclipse_props_contact.py

Reads production/models/eclipse_props/preview/*.png and game/assets/props/eclipse_power/eclipse_props.json, writes
  production/qa/evidence/M3-6A_contact.png   every prop at LOD0 (three-quarter and front) with id, size, triangles
  production/qa/evidence/M3-6A_lods.png      LOD0 beside the LOD1 Compatibility build, plus the moving-part states
(task evidence; the visual review itself is recorded by the reviewer in production/review/visual_review.md).
"""
import json
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
PREVIEW = ROOT / "production/models/eclipse_props/preview"
PROPS = ROOT / "game/assets/props/eclipse_power"
OUT = ROOT / "production/qa/evidence"
FONT = "/System/Library/Fonts/Helvetica.ttc"
NAVY, ORANGE, WHITE, GREY = (31, 42, 68), (242, 107, 33), (236, 238, 240), (120, 124, 130)
STATES = [("PR_ProtectedBusPanel", "f2_isolated", "Panel, P-12: test selector disconnected, F2 isolated, F2 breaker off"),
          ("PR_FilteredCamera", "filter_out", "Camera: solar filter swung out of the light path")]


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
    props = json.loads((PROPS / "eclipse_props.json").read_text(encoding="utf-8"))["props"]
    cell, pad, cap = 340, 16, 128
    cols = 3
    rows = (len(props) + cols - 1) // cols
    width = cols * (2 * cell + 4 + pad) + pad
    height = 64 + rows * (cell + cap + pad) + pad + 40
    sheet = Image.new("RGB", (width, height), WHITE)
    draw = ImageDraw.Draw(sheet)
    header(draw, width, "LAST LIGHT ACADEMY  |  Chapter 6 eclipse power props, game LOD (M3-6A)  |  procedural Blender, habitat kit materials",
           "Cycles preview, neutral studio light, three-quarter and front. No text baked: every word is a Label3D on a blank plate or a live screen. Viewer stands on -Z.")
    for i, entry in enumerate(props):
        x = pad + (i % cols) * (2 * cell + 4 + pad)
        y = 64 + pad + (i // cols) * (cell + cap + pad)
        sheet.paste(tile(PREVIEW / f"{entry['id']}_LOD0_34.png", cell), (x, y))
        sheet.paste(tile(PREVIEW / f"{entry['id']}_LOD0_front.png", cell), (x + cell + 4, y))
        draw.rectangle((x, y, x + 2 * cell + 4, y + cell), outline=GREY, width=1)
        draw.ellipse((x + 8, y + 8, x + 44, y + 44), fill=ORANGE, outline=NAVY, width=2)
        n = str(i + 1)
        draw.text((x + 26 - draw.textlength(n, font=font(22)) / 2, y + 13), n, font=font(22), fill=WHITE)
        size = entry["size_m"]
        glb = PROPS / (entry["id"] + "_LOD0.glb")
        draw.text((x, y + cell + 6), f"{entry['id']}  -  {entry['display']}", font=font(19), fill=NAVY)
        draw.text((x, y + cell + 30), f"{size[0]:.3f} x {size[1]:.3f} x {size[2]:.3f} m  |  anchor {entry['anchor']}, mount y {entry['mount_y']:.2f}  |  "
                  f"LOD0 {entry['triangles'][0]} / LOD1 {entry['triangles'][1]} tris  |  {glb.stat().st_size // 1024} KB", font=font(14), fill=(60, 64, 72))
        parts = ", ".join(entry.get("parts", {})) or "none"
        nodes = (f"parts: {parts}  |  lamps {len(entry.get('lamps', {}))}, screens {len(entry.get('screens', {}))}, "
                 f"labels {len(entry.get('labels', {}))}, sockets {len(entry.get('sockets', {}))}")
        wrapped = textwrap.wrap(nodes, 96)[:2]
        for k, line in enumerate(wrapped):
            draw.text((x, y + cell + 50 + 16 * k), line, font=font(13), fill=(60, 64, 72))
        for k, line in enumerate(textwrap.wrap(entry["notes"] + "  |  " + ", ".join(entry["scenes"]), 110)[:2]):
            draw.text((x, y + cell + 54 + 16 * len(wrapped) + 15 * k), line, font=font(12), fill=GREY)
    draw.text((pad, height - 32), "Gate: production/review/asset_verification.md. Godot captures in the kit-built power room: production/qa/evidence/M3-6A_*.png.",
              font=font(13), fill=GREY)
    out = OUT / "M3-6A_contact.png"
    sheet.save(out)
    print("wrote", out.relative_to(ROOT), sheet.size)

    cell = 280
    cols = len(props)
    width = max(cols * (cell + pad) + pad, 2 * (2 * cell + pad) + pad)
    height = 64 + 2 * cell + 60 + pad + cell + 60 + 40
    sheet = Image.new("RGB", (width, height), WHITE)
    draw = ImageDraw.Draw(sheet)
    header(draw, width, "Eclipse power props  |  LOD0 (top) against the LOD1 Compatibility build (bottom), then the moving-part states",
           "LOD1 drops screws, fins, clips and small detail, halves cylinder segments and uses the kit's 512 px textures; it keeps every part, lamp and screen node.")
    for i, entry in enumerate(props):
        x = pad + i * (cell + pad)
        y = 64 + pad
        sheet.paste(tile(PREVIEW / f"{entry['id']}_LOD0_34.png", cell), (x, y))
        sheet.paste(tile(PREVIEW / f"{entry['id']}_LOD1_34.png", cell), (x, y + cell + 4))
        draw.text((x, y + 2 * cell + 10), entry["id"].replace("PR_", ""), font=font(15), fill=NAVY)
        draw.text((x, y + 2 * cell + 30), f"{entry['triangles'][0]} / {entry['triangles'][1]} tris", font=font(13), fill=(60, 64, 72))
    y = 64 + pad + 2 * cell + 60 + pad
    for k, (prop_id, state, caption) in enumerate(STATES):
        x = pad + k * (2 * cell + 2 * pad)
        sheet.paste(tile(PREVIEW / f"{prop_id}_LOD0_{state}.png", cell), (x, y))
        for j, line in enumerate(textwrap.wrap(caption, 34)):
            draw.text((x + cell + 10, y + 10 + 20 * j), line, font=font(15), fill=NAVY)
    out = OUT / "M3-6A_lods.png"
    sheet.save(out)
    print("wrote", out.relative_to(ROOT), sheet.size)


if __name__ == "__main__":
    main()
