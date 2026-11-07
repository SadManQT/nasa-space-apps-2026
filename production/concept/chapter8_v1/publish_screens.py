#!/usr/bin/env python3
"""Publish the M3-8A 2D screen assets (system Python, Pillow + numpy + SciPy; no generation, no credits).

    python3 production/concept/chapter8_v1/publish_screens.py

Sadman, 7 Nov 2026: "Approve all" (EN_NoorRooftop as built) and "2D portraits only" (Noor and Rao stay screen
portraits; the approved turnarounds are reference). Writes:
  game/assets/ui/screens/EN_NoorRooftop.png        the S10 backdrop, 9 Apr 2047 08:15 Dhaka, painted grade
  game/assets/ui/screens/EN_NoorRooftop_noon.png   the S12 backdrop, 10 Apr 12:00 Dhaka, painted grade
  game/assets/ui/portraits/CH_Noor_live.png        Noor's cel-shaded live-call cut-out (transparent), drawn over the
                                                   rooftop backdrop like Ferreira's cut-out over EN_EarthDesk
from build_rooftop.py's Cycles renders (production/models/chapter8/render/rooftop_B/C_*.png, 1536 x 864) and the
approved three-quarter take (characters/noor_34_take2.png).
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

from compose_ch08 import CH, R, ROOT, painted

SCREENS = ROOT / "game/assets/ui/screens"
PORTRAITS = ROOT / "game/assets/ui/portraits"


def cutout_soft(path):
    """Figure on a transparent background: the white backdrop connected to the border becomes alpha 0, with a
    one-pixel feathered edge so the cel outline stays crisp on any backdrop."""
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(np.int16)
    white = a.min(axis=2) > 236
    lab, _ = ndimage.label(white)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    fg = ~np.isin(lab, list(border))
    alpha = ndimage.gaussian_filter(fg.astype(np.float32), 0.7)
    alpha = np.clip((alpha - 0.15) / 0.7, 0, 1)
    rgba = np.dstack([np.asarray(im), (alpha * 255).astype(np.uint8)])
    out = Image.fromarray(rgba, "RGBA")
    box = out.getbbox()
    pad = 12
    out = out.crop((max(0, box[0] - pad), max(0, box[1] - pad), min(out.width, box[2] + pad), min(out.height, box[3] + pad)))
    return out


def main():
    SCREENS.mkdir(parents=True, exist_ok=True)
    for src, dst in (("rooftop_B_backdrop_S10.png", "EN_NoorRooftop.png"), ("rooftop_C_backdrop_S12.png", "EN_NoorRooftop_noon.png")):
        im = Image.open(R / src).convert("RGB")
        assert im.size == (1536, 864), (src, im.size)
        painted(im).save(SCREENS / dst, optimize=True)
        print("wrote", (SCREENS / dst).relative_to(ROOT))
    cut = cutout_soft(CH / "noor_34_take2.png")
    target_h = 1376  # about the take's own figure height: no upscaling
    cut = cut.resize((int(cut.width * target_h / cut.height), target_h), Image.LANCZOS)
    cut.save(PORTRAITS / "CH_Noor_live.png", optimize=True)
    print("wrote", (PORTRAITS / "CH_Noor_live.png").relative_to(ROOT), cut.size)


if __name__ == "__main__":
    main()
