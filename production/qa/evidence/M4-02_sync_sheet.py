"""M4-02 evidence: does the inventory lamp tick land on CS-18's four-frame blink in the film the game plays?

  python3 production/tools/heavy.py python3 production/qa/evidence/M4-02_sync_sheet.py

Reads the runtime Theora film (game/assets/cutscenes/CS-18_The_Closed_Drawer.ogv), never the master, and writes
production/qa/evidence/M4-02_CS18_tick_sync.png: frames 89-96 around the lamp with their brightness, the waveform
under exactly those frames with the detected click onset, and the whole 8 s level envelope. Prints the numbers.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "production/cutscenes/v8/src"))
import verify_staging as staging   # noqa: E402  (shares the decoders and the click detector with the gate)

FILM = ROOT / "game/assets/cutscenes/CS-18_The_Closed_Drawer.ogv"
OUT = ROOT / "production/qa/evidence/M4-02_CS18_tick_sync.png"
FPS, RATE = staging.FPS, staging.RATE
FIRST, LAST = 89, 96                       # frames shown; the blink is 91-94
LAMP = (905.5, 360.0)                      # production/cutscenes/v8/src/blink/CS-18-A.json, 1280x720 master pixels
FONT = "/System/Library/Fonts/Avenir Next.ttc"
INK, DIM, GOLD, CYAN, PAPER, PANEL = "#e8ecf3", "#8a94a6", "#f2c230", "#78dcff", "#0d1320", "#161e2e"
W, TILE, PAD = 1600, 180, 40


def font(size, bold=False):
    """Avenir Next at a size; Demi Bold for headings, Medium for text."""
    return ImageFont.truetype(FONT, size, index=2 if bold else 5)


def runtime_frames(first, last):
    """Frames first..last of the runtime film as the player shows them, scaled to master pixels.

    Movie Maker's Theora stores a held picture once (pts 65 jumps to 90 here), and resampling with ffmpeg's
    fps filter shifts such a film by a frame. Decode every stored frame at its own pts and carry the last one
    forward through a hold instead.
    """
    with tempfile.TemporaryDirectory() as work:
        subprocess.run(["ffmpeg", "-v", "error", "-i", str(FILM), "-fps_mode", "passthrough", "-frame_pts", "1",
                        "-vf", "scale=1280:720:flags=area", f"{work}/%d.png"], check=True)
        stored = sorted(int(path.stem) for path in Path(work).glob("*.png"))
        shown = {}
        for index in range(first, last + 1):
            pts = max(value for value in stored if value <= index)
            shown[index] = cv2.imread(f"{work}/{pts}.png")
        return shown


def lamp_level(picture):
    """Mean brightness of the 9x8 px lamp core used by verify_staging's four-frame check."""
    return float(picture[356:365, 902:910].mean())


def main():
    """Measure the runtime film, draw the sheet and print the proof numbers."""
    frames = runtime_frames(FIRST, LAST)
    levels = {k: lamp_level(picture) for k, picture in frames.items()}
    base = float(np.median(list(levels.values())))
    lit = [k for k, level in levels.items() if level > base + 5]
    sound = staging.mono(FILM)
    onsets = staging.clicks(sound, 0.9, 6.9)
    assert len(onsets) == 1, f"expected one tick, found {onsets}"
    onset = onsets[0]
    onset_frame = int(onset * FPS)
    envelope = staging.envelope_db(sound, 0.05)

    sheet = Image.new("RGB", (W, 1010), PAPER)
    draw = ImageDraw.Draw(sheet)
    draw.text((PAD, 28), "CS-18 The Closed Drawer: the inventory lamp tick on the four-frame blink", font=font(30, True), fill=INK)
    draw.text((PAD, 70), f"Runtime film the game plays ({FILM.name}), 24 fps. M4-02, 6 Nov 2026.",
              font=font(19), fill=DIM)

    # Row 1: frames 89-96 around the lamp, each tile exactly one frame (1/24 s) of the waveform below it.
    left, top = PAD + 70, 120
    span = W - left - PAD
    column = span / (LAST - FIRST + 1)
    for k, picture in frames.items():
        x = left + (k - FIRST) * column + (column - TILE) / 2
        crop = picture[310:410, 850:960]
        tile = Image.fromarray(cv2.cvtColor(cv2.resize(crop, (TILE, 164), interpolation=cv2.INTER_NEAREST), cv2.COLOR_BGR2RGB))
        sheet.paste(tile, (int(x), top))
        border = GOLD if k in lit else "#2a3448"
        draw.rectangle((int(x) - 3, top - 3, int(x) + TILE + 2, top + 166), outline=border, width=3)
        draw.text((int(x), top + 174), f"frame {k}", font=font(18, True), fill=GOLD if k in lit else INK)
        draw.text((int(x), top + 198), f"{k / FPS:.3f} s", font=font(16), fill=DIM)
        rise = max(0.0, levels[k] - base)
        draw.rectangle((int(x), top + 226, int(x) + TILE, top + 238), fill="#222b3d")
        draw.rectangle((int(x), top + 226, int(x) + int(TILE * min(rise / 60.0, 1.0)), top + 238), fill=GOLD)
        draw.text((int(x), top + 242), f"lamp +{rise:.0f}", font=font(15), fill=DIM)
    draw.text((PAD, top + 60), "lamp", font=font(18, True), fill=DIM)

    # Row 2: the waveform under exactly those frames, frame boundaries as a grid, the click onset in gold.
    wave_top, wave_h = top + 290, 230
    draw.rectangle((left, wave_top, left + span, wave_top + wave_h), fill=PANEL)
    start, end = FIRST / FPS, (LAST + 1) / FPS
    window = sound[int(start * RATE):int(end * RATE)]
    peak = float(np.abs(window).max()) or 1.0
    xs = np.linspace(left, left + span, len(window))
    mid = wave_top + wave_h / 2
    buckets = np.array_split(np.arange(len(window)), int(span))
    for bucket in buckets:
        values = window[bucket]
        x = float(xs[bucket[0]])
        draw.line((x, mid - values.max() / peak * (wave_h / 2 - 8), x, mid - values.min() / peak * (wave_h / 2 - 8)), fill=CYAN)
    for k in range(FIRST, LAST + 2):
        x = left + (k - FIRST) * column
        draw.line((x, wave_top, x, wave_top + wave_h), fill="#3a4660" if k not in (lit[0], lit[-1] + 1) else GOLD, width=1 if k not in (lit[0], lit[-1] + 1) else 2)
    onset_x = left + (onset - start) / (end - start) * span
    draw.line((onset_x, wave_top - 6, onset_x, wave_top + wave_h + 6), fill=GOLD, width=3)
    label = f"tick onset {onset:.4f} s (frame {onset_frame}, {(onset - lit[0] / FPS) * 1000:.1f} ms after the lamp lights)"
    box = draw.textbbox((onset_x + 10, wave_top + 10), label, font=font(17, True))
    draw.rectangle((box[0] - 6, box[1] - 4, box[2] + 6, box[3] + 4), fill=PAPER, outline=GOLD)
    draw.text((onset_x + 10, wave_top + 10), label, font=font(17, True), fill=GOLD)
    draw.text((PAD, wave_top + wave_h / 2 - 12), "sound", font=font(18, True), fill=DIM)
    draw.text((left, wave_top + wave_h + 10), f"Frames {lit[0]}-{lit[-1]} lit (gold); the waveform spans the same "
              f"{(LAST - FIRST + 1) / FPS * 1000:.0f} ms as the tiles above it.", font=font(16), fill=DIM)

    # Row 3: the whole film's level, so the single tick reads against the fan bed, the fade and the silent black.
    env_top, env_h = wave_top + wave_h + 60, 200
    draw.rectangle((left, env_top, left + span, env_top + env_h), fill=PANEL)
    floor, ceiling = -70.0, 0.0
    to_y = lambda db: env_top + env_h - (min(max(db, floor), ceiling) - floor) / (ceiling - floor) * env_h
    points = [(left + i / len(envelope) * span, to_y(db)) for i, db in enumerate(envelope)]
    draw.line(points, fill=CYAN, width=2)
    for seconds in range(0, 9):
        x = left + seconds / 8.0 * span
        draw.line((x, env_top + env_h, x, env_top + env_h + 6), fill=DIM)
        draw.text((x - 6, env_top + env_h + 8), f"{seconds} s", font=font(15), fill=DIM)
    for db in (-20, -40, -60):
        draw.text((left + span - 52, to_y(db) - 20), f"{db} dB", font=font(14), fill=DIM)
        draw.line((left, to_y(db), left + span, to_y(db)), fill="#232c40")
    tick_x = left + onset / 8.0 * span
    draw.line((tick_x, env_top, tick_x, env_top + env_h), fill=GOLD, width=2)
    notes = [(0.15, "fan bed fades in"), (onset + 0.08, "lamp tick, once"), (6.05, "picture fades"), (7.05, "black, silence")]
    for seconds, text in notes:
        draw.text((left + seconds / 8.0 * span, env_top + 6), text, font=font(15, True), fill=GOLD if "tick" in text else INK)
    draw.text((PAD, env_top + env_h / 2 - 12), "level", font=font(18, True), fill=DIM)
    bed = float(np.median(staging.envelope_db(sound[int(2.0 * RATE):int(3.5 * RATE)], 0.1)))
    tick = float(staging.envelope_db(sound[int(onset * RATE):int((onset + 0.1) * RATE)], 0.1)[0])
    film_peak = 20 * np.log10(float(np.abs(sound).max()))
    tail = float(np.abs(sound[int(7.1 * RATE):int(7.9 * RATE)]).max())
    summary = (f"One click in 0.9-6.9 s. Tick {tick - bed:.1f} dB over the fan bed (100 ms windows), "
               f"film peak {film_peak:.1f} dBFS, black tail {'digital silence' if tail < 1e-5 else f'max {tail:.2e}'}.")
    draw.text((PAD, env_top + env_h + 40), summary, font=font(18), fill=INK)
    sheet.save(OUT)

    print(f"lit frames {lit}; tick onset {onset:.4f} s = frame {onset_frame}; "
          f"{(onset - lit[0] / FPS) * 1000:.1f} ms after frame {lit[0]} starts")
    print(summary)
    print(f"wrote {OUT.relative_to(ROOT)}")
    assert lit == [91, 92, 93, 94] and onset_frame == lit[0], "the tick must land on the first lit frame"


if __name__ == "__main__":
    main()
