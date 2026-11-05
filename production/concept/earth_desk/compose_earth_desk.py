#!/usr/bin/env python3
"""Grade EN_EarthDesk, derive its archive variant and compose its approval sheet (M1-07; numpy, SciPy and Pillow,
no credits).

  python3 production/concept/earth_desk/compose_earth_desk.py

Reads production/concept/earth_desk/EN_EarthDesk_render.png (the Blender render from build_earth_desk.py) and writes:
  game/assets/ui/screens/EN_EarthDesk.png           live Earth link and queued text: the render with a painted grade
      (Kuwahara brush filter, a soft screen glow, a teal-and-warm grade, a vignette) so it sits beside the painted
      background of the installed Rao portrait
  game/assets/ui/screens/EN_EarthDesk_archive.png   stored recordings: desaturated, dimmer, cooler
  production/concept/earth_desk/EN_EarthDesk_sheet_v1.png   the sheet for Sadman's approval
Deterministic: the same render always gives the same files.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFont
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
SCREENS = os.path.join(ROOT, "game", "assets", "ui", "screens")
PORTRAITS = os.path.join(ROOT, "game", "assets", "ui", "portraits")
RENDER = os.path.join(HERE, "EN_EarthDesk_render.png")
BASE = os.path.join(SCREENS, "EN_EarthDesk.png")
ARCHIVE = os.path.join(SCREENS, "EN_EarthDesk_archive.png")
SHEET = os.path.join(HERE, "EN_EarthDesk_sheet_v1.png")


def kuwahara(rgb, radius=4):
    """Classic Kuwahara filter: each pixel takes the mean colour of the least varied of its four quadrant windows,
    which flattens shading into brush-like patches while keeping edges."""
    size = radius + 1
    half = radius // 2
    lum = rgb.mean(axis=2)
    mean = np.stack([ndimage.uniform_filter(rgb[..., c], size, mode="reflect") for c in range(3)], axis=2)
    mean_l = ndimage.uniform_filter(lum, size, mode="reflect")
    var = ndimage.uniform_filter(lum * lum, size, mode="reflect") - mean_l * mean_l
    best_var = np.full(lum.shape, np.inf, dtype=np.float32)
    out = np.zeros_like(rgb)
    for dy in (-half, half):
        for dx in (-half, half):
            v = np.roll(var, (dy, dx), axis=(0, 1))
            m = np.roll(mean, (dy, dx), axis=(0, 1))
            pick = v < best_var
            best_var[pick] = v[pick]
            out[pick] = m[pick]
    return out


def grade(img):
    """The painted grade for the live backdrop."""
    rgb = np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0
    rgb = kuwahara(rgb, 4)
    lum = rgb.mean(axis=2, keepdims=True)
    bright = rgb * np.clip((lum - 0.55) / 0.35, 0, 1)
    glow = np.stack([ndimage.gaussian_filter(bright[..., c], 9) for c in range(3)], axis=2)
    rgb = rgb + 0.35 * glow
    shadows = np.clip(1.0 - lum / 0.35, 0, 1)
    rgb = rgb + shadows * np.array([-0.004, 0.010, 0.016], dtype=np.float32)  # teal in the shadows, like the portrait
    h, w = lum.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    r2 = ((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2
    rgb = rgb * (1.0 - 0.22 * np.clip(r2 / 2.0, 0, 1))[..., None]
    return Image.fromarray((np.clip(rgb, 0, 1) * 255.0 + 0.5).astype(np.uint8))


def archive(img):
    """Stored recording: 45 % colour, 70 % brightness, a cool cast."""
    out = ImageEnhance.Color(img).enhance(0.45)
    out = ImageEnhance.Brightness(out).enhance(0.7)
    cool = Image.new("RGB", out.size, (16, 28, 52))
    return Image.blend(out, cool, 0.18)


def over(backdrop, portrait_path):
    """A portrait over the backdrop, scaled to the screen height like CampaignCrew does."""
    frame = backdrop.convert("RGBA")
    p = Image.open(portrait_path).convert("RGBA")
    scale = frame.height / p.height
    p = p.resize((round(p.width * scale), frame.height), Image.LANCZOS)
    frame.alpha_composite(p, ((frame.width - p.width) // 2, 0))
    return frame


def font(size):
    try:
        return ImageFont.truetype("/System/Library/Fonts/Supplemental/DIN Alternate Bold.ttf", size)
    except OSError:
        return ImageFont.load_default(size)


def main():
    base = grade(Image.open(RENDER))
    base.save(BASE)
    archive(base).save(ARCHIVE)
    tiles = [("EN_EarthDesk - live Earth link and queued text", base),
             ("EN_EarthDesk_archive - stored recordings", Image.open(ARCHIVE).convert("RGB")),
             ("Reference: the installed Rao portrait (its painted room)", Image.open(os.path.join(PORTRAITS, "CH_Rao_screen.png")).convert("RGB")),
             ("Ferreira over EN_EarthDesk: she calls from Rao's room", over(base, os.path.join(PORTRAITS, "CH_Ferreira_screen.png")).convert("RGB"))]
    w, h = 760, 428
    sheet = Image.new("RGB", (2 * w + 60, 2 * h + 150), (5, 6, 10))
    d = ImageDraw.Draw(sheet)
    d.text((20, 16), "EN_EarthDesk: the Earth control room behind a caller (screen backdrop), v1 for approval", fill=(242, 194, 48), font=font(28))
    d.text((20, 54), "Blender Eevee render of Rao's room with a painted grade; no AI image generation, no credits. No text or logos on any readout; the Moon display shows the real near side.", fill=(168, 180, 200), font=font(17))
    for i, (title, img) in enumerate(tiles):
        x, y = 20 + (i % 2) * (w + 20), 90 + (i // 2) * (h + 30)
        sheet.paste(img.resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), title, fill=(236, 238, 240), font=font(18))
    sheet.save(SHEET)
    print("wrote", os.path.relpath(BASE, ROOT), os.path.relpath(ARCHIVE, ROOT), "and", os.path.relpath(SHEET, ROOT))


if __name__ == "__main__":
    main()
