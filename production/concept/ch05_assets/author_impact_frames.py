#!/usr/bin/env python3
"""M3-5A: the authored impact-camera frame set for PR_ImpactMonitor (EX-CH05-S07, P-10). No AI generation.

Usage:
  python3 author_impact_frames.py <game/assets/ui/impact_monitor>

Writes
  frames/<candidate>_<cam>_<k>.png   three consecutive frames (k = 0 before, 1 event, 2 after) from the Aurora mast
                                     camera (cam a) and the synchronized second camera (cam b) for each of the ten
                                     candidates
  impact_frames.json                 the candidate set, its detector and map coordinates, the truth of each
                                     candidate, the monitor's display states and the P-10 counts

Science and canon (08_PUZZLE_DESIGNS P-10; SRC-IMPACTS; STORY_FULL EX-CH05-S07)
  * Lunar impact flashes are brief point-like flashes on the night side of a surface with no atmosphere: there is no
    streak, trail or glow around them. A real flash has a distinct onset, lasts a frame or two, lies at a mapped
    surface location and is seen by both synchronized cameras (NASA's monitoring uses two telescopes so that noise and
    cosmic-ray hits are told apart from impacts).
  * A persistent detector artifact (a hot pixel) stays at the same detector coordinate in every frame and in one
    camera only; it is sharp and does not move with the surface map.
  * The set is authored teaching content: eight genuine transients, two fixed artifacts; six verified flashes satisfy
    the mission; all eight with no false report is the Golden criterion. It is never presented as an imported
    historical observation. No text is drawn into the frames: timestamps, coordinates and reason chips are live UI.
"""
import json, math, os, sys
import numpy as np
from PIL import Image

W, H = 320, 200            # detector size in pixels; the monitor's Screen slot shows them enlarged
SEED = 20461214            # fixed: the set must be identical on every machine


def plain(rng):
    """Earthshine-lit dark plain: faint large-scale albedo variation, a few crater rims, read noise added per frame."""
    y, x = np.mgrid[0:H, 0:W].astype(np.float64)
    base = np.full((H, W), 0.055)
    for _ in range(14):                                     # soft albedo patches
        cx, cy, r, a = rng.uniform(0, W), rng.uniform(0, H), rng.uniform(25, 90), rng.uniform(-0.012, 0.016)
        base += a * np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (2 * r * r))
    for _ in range(9):                                      # crater rims: a bright arc on the Earth-lit side, dark bowl
        cx, cy, r = rng.uniform(20, W - 20), rng.uniform(15, H - 15), rng.uniform(5, 16)
        d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2)
        rim = np.exp(-((d - r) ** 2) / (2 * (0.9 + r * 0.08) ** 2))
        lit = 0.5 + 0.5 * np.cos(np.arctan2(y - cy, x - cx) - math.radians(-150))
        base += 0.045 * rim * lit - 0.02 * rim * (1 - lit) - 0.012 * np.exp(-(d ** 2) / (2 * (r * 0.6) ** 2))
    base += 0.006 * np.sin(x / 23.0) * np.cos(y / 31.0)     # gentle ridges
    # vignetting of the intensified camera
    vx, vy = (x - W / 2) / (W / 2), (y - H / 2) / (H / 2)
    base *= 1.0 - 0.28 * (vx * vx + vy * vy)
    return np.clip(base, 0.02, 0.2)


def psf(x, y, cx, cy, sigma):
    return np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (2 * sigma * sigma))


def frame(base, rng, flash=None, hot=None, cam_gain=1.0):
    """One exposure: base plain + read noise + optional flash (soft PSF) + optional hot pixel (sharp, fixed)."""
    yv, xv = np.mgrid[0:H, 0:W].astype(np.float64)
    img = base * cam_gain + rng.normal(0.0, 0.009, (H, W))
    img += 0.004 * rng.random((H, W)) ** 6                   # sparse faint speckle, like cosmic-ray hits
    if flash is not None:
        cx, cy, amp, sigma = flash
        img += amp * psf(xv, yv, cx, cy, sigma) + 0.25 * amp * psf(xv, yv, cx, cy, sigma * 2.6)
    if hot is not None:
        hx, hy, amp = hot
        img[hy, hx] += amp
        img[hy, hx + 1] += amp * 0.22                        # charge bleed to the readout neighbours, every frame
        img[hy + 1, hx] += amp * 0.10
    return np.clip(img, 0.0, 1.0)


def to_png(img, path):
    g = (img ** (1 / 1.9) * 255).astype(np.uint8)            # display gamma of the amplified view
    rgb = np.stack([g * 0.86, g * 0.92, g], axis=2).astype(np.uint8)   # slightly cool monochrome
    Image.fromarray(rgb, "RGB").save(path, optimize=True)


def main(out_dir):
    rng = np.random.default_rng(SEED)
    frames_dir = os.path.join(out_dir, "frames")
    os.makedirs(frames_dir, exist_ok=True)
    base_a = plain(rng)
    # camera b looks at the same plain from the second mast: same surface, slightly different framing and gain
    shift = (3, -2)
    pad = np.pad(base_a, 4, mode="edge")
    base_b = pad[4 - shift[1]:4 - shift[1] + H, 4 - shift[0]:4 - shift[0] + W]
    # the two fixed artifacts live on camera a only, at detector coordinates that never move
    hots = [(214, 61, 0.78), (77, 142, 0.70)]
    candidates = []
    # eight genuine transients: mapped surface positions (authored), short, seen by both cameras
    genuine_xy = [(118, 92), (248, 57), (63, 38), (196, 151), (151, 118), (287, 123), (34, 171), (229, 24)]
    order = ["C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C10"]
    # candidate order on the monitor mixes artifacts in: C01 is the persistent point the story opens on
    kinds = ["artifact", "genuine", "genuine", "genuine", "artifact", "genuine", "genuine", "genuine", "genuine", "genuine"]
    g_i = 0
    a_i = 0
    t0 = 14 * 3600 * 24  # seconds offset is live UI business; frames carry an index only
    for cid, kind in zip(order, kinds):
        c = {"id": cid, "kind": kind, "frames": {}}
        if kind == "genuine":
            gx, gy = genuine_xy[g_i]
            g_i += 1
            amp = float(rng.uniform(0.32, 0.62))
            sigma = float(rng.uniform(1.25, 1.9))
            c["detector_xy"] = [gx, gy]
            c["map_xy"] = [gx, gy]                       # camera a is the map reference
            c["onset_frame"] = 1
            c["peak_amplitude"] = round(amp, 3)
            c["duration_frames"] = 1
            for k in range(3):
                fa = frame(base_a, rng, flash=(gx, gy, amp, sigma) if k == 1 else None, hot=None)
                fb = frame(base_b, rng, flash=(gx + shift[0], gy + shift[1], amp * 0.9, sigma * 1.05) if k == 1 else None, cam_gain=0.95)
                for cam, im in (("a", fa), ("b", fb)):
                    for hx, hy, hamp in (hots if cam == "a" else []):
                        im[hy, hx] = min(1.0, im[hy, hx] + hamp)
                        im[hy, hx + 1] = min(1.0, im[hy, hx + 1] + hamp * 0.22)
                        im[hy + 1, hx] = min(1.0, im[hy + 1, hx] + hamp * 0.10)
                    name = f"{cid}_{cam}_{k}.png"
                    to_png(im, os.path.join(frames_dir, name))
                    c["frames"].setdefault(cam, []).append("frames/" + name)
        else:
            hx, hy, hamp = hots[a_i]
            a_i += 1
            c["detector_xy"] = [hx, hy]
            c["map_xy"] = None                           # nothing on the surface map: it is the detector
            c["onset_frame"] = None
            c["persistent"] = True
            for k in range(3):
                fa = frame(base_a, rng)
                fb = frame(base_b, rng, cam_gain=0.95)
                for hx2, hy2, hamp2 in hots:
                    fa[hy2, hx2] = min(1.0, fa[hy2, hx2] + hamp2)
                    fa[hy2, hx2 + 1] = min(1.0, fa[hy2, hx2 + 1] + hamp2 * 0.22)
                    fa[hy2 + 1, hx2] = min(1.0, fa[hy2 + 1, hx2] + hamp2 * 0.10)
                for cam, im in (("a", fa), ("b", fb)):
                    name = f"{cid}_{cam}_{k}.png"
                    to_png(im, os.path.join(frames_dir, name))
                    c["frames"].setdefault(cam, []).append("frames/" + name)
        candidates.append(c)
    data = {
        "schema_version": 1,
        "source": "authored teaching set (M3-5A); not an imported observation. Method: NASA Meteoroid Environment Office lunar impact monitoring, two synchronized cameras (SRC-IMPACTS).",
        "numbers_from": "game-design/08_PUZZLE_DESIGNS.md P-10",
        "detector_size": [W, H],
        "cameras": {"a": "Aurora mast camera (map reference)", "b": "second synchronized camera"},
        "camera_b_offset_px": list(shift),
        "frame_roles": ["before", "event", "after"],
        "counts": {"genuine": 8, "artifacts": 2, "verified_required": 6, "mastery_all": 8},
        "artifact_detector_xy": [[hx, hy] for hx, hy, _ in hots],
        "states": {
            "candidate": "one frame of one candidate from camera a, enlarged",
            "paired_reference": "the same frame index from camera b beside camera a (a real flash is in both; a hot pixel is in a only)",
            "artifact_rejection": "frames 0, 1 and 2 of camera a side by side (a real flash has an onset; a hot pixel is in all three)",
            "verified_six": "the supported-event list reaches six with a reason on every row: mission exit gate",
            "mastery_eight": "all eight genuine events verified and no false report: Golden criterion",
        },
        "candidates": candidates,
    }
    with open(os.path.join(out_dir, "impact_frames.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1)
    print(f"wrote {len(candidates)} candidates, {len(candidates) * 6} frames to {out_dir}")


if __name__ == "__main__":
    main(sys.argv[1])
