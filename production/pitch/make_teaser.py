#!/usr/bin/env python3
"""Cinematic teaser for the supervisor briefing: letterboxed 1920x1080, title cards, music build."""
import subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(sys.argv[1])
WORK = OUT.parent / "segments"
WORK.mkdir(parents=True, exist_ok=True)
FF = "/opt/homebrew/bin/ffmpeg"
BOLD = ROOT / "game/assets/fonts/ui/SairaSemiCondensed-SemiBold.ttf"
MED = ROOT / "game/assets/fonts/ui/SairaSemiCondensed-Medium.ttf"
CS = ROOT / "game/assets/cutscenes"
SCI = ROOT / "game/assets/explainers/science"
EV = ROOT / "production/qa/evidence"
FPS = 30
segs = []


def run(args):
    subprocess.run([FF, "-loglevel", "error", "-y", *args], check=True)


def fades(dur, fi=0.35, fo=0.35):
    return f"fade=t=in:st=0:d={fi},fade=t=out:st={dur - fo:.2f}:d={fo}"


def clip(src, start, dur, name):
    out = WORK / f"{len(segs):02d}_{name}.mp4"
    run(["-i", str(src), "-ss", str(start), "-t", str(dur), "-an",  # accurate seek: Theora frames need their keyframe
         "-vf", f"crop=iw:ih*0.84:0:ih*0.02,scale=1920:-2:flags=lanczos,pad=1920:1080:0:(oh-ih)/2:black,fps={FPS},{fades(dur)}", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", str(out)])  # drop burned-in subtitles
    segs.append(out)


def still(src, dur, name, zoom_to=1.10, fit=False):
    out = WORK / f"{len(segs):02d}_{name}.mp4"
    frames = int(dur * FPS)
    step = (zoom_to - 1.0) / frames
    frame = "scale=-2:1560:flags=lanczos,pad=3840:2160:(ow-iw)/2:(oh-ih)/2:color=0x05080E," if fit else ""  # UI shots sit inside the letterbox
    run(["-i", str(src), "-frames:v", str(frames),
         "-vf", f"{frame}scale=3840:2160:flags=lanczos,zoompan=z='min(zoom+{step:.6f},{zoom_to})':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={frames}:s=1920x1080:fps={FPS},{fades(dur)}",
         "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", str(out)])
    segs.append(out)


def esc(t):
    return t.replace("\\", "\\\\").replace(":", "\\:").replace("'", "’").replace("%", "\\%")


def card(kicker, line, dur, name, sub=""):
    from PIL import Image, ImageDraw, ImageFont
    img = Image.new("RGB", (1920, 1080), (5, 8, 14))
    d = ImageDraw.Draw(img)
    def centred(text, font_path, size, colour, y, tracking=0):
        if not text:
            return
        font = ImageFont.truetype(str(font_path), size)
        widths = [d.textlength(ch, font=font) for ch in text]
        total = sum(widths) + tracking * (len(text) - 1)
        x = (1920 - total) / 2
        for ch, w in zip(text, widths):
            d.text((x, y), ch, font=font, fill=colour)
            x += w + tracking
    centred(kicker, MED, 32, (245, 196, 81), 400, tracking=6)
    centred(line, BOLD, 88, (242, 239, 231), 455, tracking=3)
    centred(sub, MED, 34, (184, 196, 214), 590, tracking=1)
    png = WORK / f"card_{name}.png"
    img.save(png)
    out = WORK / f"{len(segs):02d}_{name}.mp4"
    run(["-loop", "1", "-t", str(dur), "-i", str(png), "-vf", f"fps={FPS},{fades(dur, 0.4, 0.4)}", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", str(out)])
    segs.append(out)


# --- the cut ---
card("NASA SPACE APPS CHALLENGE 2026", "", 2.2, "open")
still(EV / "M1-82_LOC06_CH04S09_earth_close.png", 3.6, "earth", 1.14)
card("2046 · LUNAR SOUTH POLE", "Light is the rarest thing here.", 2.8, "c1", "The Sun never climbs more than 1.6° above the horizon.")
clip(CS / "CS-01_Arrival.ogv", 1.0, 3.6, "arrival")
clip(CS / "CS-02_The_Horizon_Closes_One_Door.ogv", 14.0, 3.0, "crew")
card("FOUR CADETS. ONE GARDEN.", "Keep it alive.", 2.4, "c2")
clip(CS / "CS-03_Alo_Needs_a_Friend.ogv", 30.0, 2.2, "flower")
clip(CS / "CS-05_The_Garden_That_Never_Opened.ogv", 11.0, 2.2, "eva")
clip(CS / "CS-11_The_Red_Ring.ogv", 7.0, 2.2, "redring")
card("BUILT ON REAL NASA DATA", "LRO · LOLA · DIVINER · LCROSS · GOES · STEREO", 2.8, "c3")
still(EV / "M1-82_LOC06_CH04S09_wide.png", 3.0, "terrain", 1.08)
clip(SCI / "sci_polar_sun.ogv", 18.0, 2.6, "polarsun")
clip(SCI / "sci_cold_traps.ogv", 30.0, 2.6, "coldtrap")
still(EV / "M1-82_LOC11_CH08S03_wide.png", 3.0, "rover", 1.08)
card("PLAN. MEASURE. SURVIVE.", "Real science. Real trade-offs.", 2.6, "c4")
still(EV / "M4-22/06_mission_table.png", 2.6, "table", 1.04, fit=True)
still(EV / "M4-22/15_pause.png", 2.4, "pause", 1.04, fit=True)
clip(CS / "CS-15_Hello_Aurora.ogv", 6.0, 3.0, "hello")
clip(CS / "CS-17_What_We_Grew.ogv", 14.0, 3.4, "grew")
card("LAST LIGHT ACADEMY", "Learn it. Live it. Grow it.", 4.4, "title", "8 chapters · 96 scenes · real lunar science")

lst = WORK / "list.txt"
lst.write_text("".join(f"file '{p}'\n" for p in segs))
body = WORK / "body.mp4"
run(["-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(body)])
dur = float(subprocess.run(["/opt/homebrew/bin/ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(body)], capture_output=True, text=True).stdout)
music = ROOT / "game/assets/audio/music/MUS_CUE-06_BeyondHome.ogg"
# Letterbox to 2.39:1 and lay the music under it, faded at both ends.
run(["-i", str(body), "-i", str(music),
     "-filter_complex", f"[0:v]drawbox=x=0:y=0:w=iw:h=138:color=black:t=fill,drawbox=x=0:y=ih-138:w=iw:h=138:color=black:t=fill[v];[1:a]atrim=0:{dur:.2f},afade=t=in:st=0:d=1.5,afade=t=out:st={dur - 3:.2f}:d=3,volume=0.9[a]",
     "-map", "[v]", "-map", "[a]", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(OUT)])
print(f"TRAILER {OUT} {dur:.1f}s")
