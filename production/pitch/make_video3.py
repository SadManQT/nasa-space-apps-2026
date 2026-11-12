#!/usr/bin/env python3
"""Cinematic teaser for the supervisor briefing: letterboxed 1920x1080, title cards, music build."""
import subprocess, sys
from pathlib import Path

ROOT = Path("/Users/sadmansakib/nasa-space-apps-2026")
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


def fades(dur, fi=0.12, fo=0.12):
    return f"fade=t=in:st=0:d={fi},fade=t=out:st={dur - fo:.2f}:d={fo}"


def clip(src, start, dur, name):
    out = WORK / f"{len(segs):02d}_{name}.mp4"
    run(["-i", str(src), "-an",  # trim in the filter: frame-accurate on Theora and time restarts at 0 for the fades
         "-vf", f"trim=start={start:.3f}:duration={dur},setpts=PTS-STARTPTS,crop=iw:ih*0.84:0:ih*0.02,scale=1920:-2:flags=lanczos,pad=1920:1080:0:(oh-ih)/2:black,fps={FPS},{fades(dur)}", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", str(out)])  # drop burned-in subtitles
    segs.append(out)


def still(src, dur, name, zoom_to=1.10, fit=False):
    out = WORK / f"{len(segs):02d}_{name}.mp4"
    frames = int(dur * FPS)
    step = (zoom_to - 1.0) / frames
    frame = "scale=-2:1560:flags=lanczos,pad=3840:2160:(ow-iw)/2:(oh-ih)/2:color=0x05080E," if fit else ""  # UI shots sit inside the letterbox
    run(["-i", str(src), "-frames:v", str(frames),
         "-vf", f"{frame}scale=3840:2160:flags=lanczos,zoompan=z='min(zoom+{step:.6f},{zoom_to})':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={frames}:s=1920x1080:fps={FPS},{fades(dur)}",
         "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", str(out)])
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
    run(["-loop", "1", "-t", str(dur), "-i", str(png), "-vf", f"fps={FPS},{fades(dur, 0.4, 0.4)}", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", str(out)])
    segs.append(out)


# --- the cut (fast: ~1 s shots, many places) ---
import subprocess as _sp
def _len(src):
    return float(_sp.run(["/opt/homebrew/bin/ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(src)], capture_output=True, text=True).stdout)
def clipf(src, frac, dur, name):
    clip(src, max(0.0, _len(src) * frac), dur, name)
QA = EV / "qa_campaign"
card("NASA SPACE APPS 2026", "Build a Junior Astronaut Mission Trainer", 2.0, "open")
still(EV / "M1-82_LOC06_CH04S09_earth_close.png", 1.4, "earth", 1.12)
card("2046 · THE MOON'S SOUTH POLE", "Light is the rarest thing here.", 2.0, "c1")
for cs, frac in [("CS-02_The_Horizon_Closes_One_Door", 0.4), ("CS-03_Alo_Needs_a_Friend", 0.75), ("CS-05_The_Garden_That_Never_Opened", 0.5), ("CS-11_The_Red_Ring", 0.4)]:
    clipf(CS / f"{cs}.ogv", frac, 0.95, cs[:5])
card("RUN THE BASE", "Power · Air · Shielding · Food", 2.0, "c2")
for sci in ["sci_polar_sun", "sci_proton_flux_chart", "sci_storms_2012_2017", "sci_water_evidence", "sci_cold_traps"]:
    clipf(SCI / f"{sci}.ogv", 0.45, 1.0, sci)
still(EV / "M1-82_LOC06_CH04S09_wide.png", 1.0, "terrain", 1.05)
still(EV / "M1-82_LOC11_CH08S03_wide.png", 1.0, "rover", 1.05)
card("REAL NASA DATA", "Real decisions. Real consequences.", 1.8, "c3", "LRO LOLA · DONKI · GOES · Diviner · LCROSS · BVAD")
still(QA / "ch04/EX-CH04-S05_start.png", 1.0, "eva_play", 1.05)
still(EV / "M4-22/06_mission_table.png", 1.0, "table", 1.03, fit=True)
still(QA / "ch05/EX-CH05-S12_end.png", 1.0, "garden_play", 1.05)
clipf(CS / "CS-15_Hello_Aurora.ogv", 0.3, 1.0, "hello")
clipf(CS / "CS-17_What_We_Grew.ogv", 0.5, 1.2, "grew")
card("TEAM THE LAST BRAINCELL · DHAKA", "LAST LIGHT ACADEMY", 3.4, "title", "Keep the crew alive. Help the first flower bloom.")

lst = WORK / "list.txt"
lst.write_text("".join(f"file '{p}'\n" for p in segs))
body = WORK / "body.mp4"
run(["-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(body)])
dur = float(subprocess.run(["/opt/homebrew/bin/ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(body)], capture_output=True, text=True).stdout)
music = ROOT / "game/assets/audio/music/MUS_CUE-06_BeyondHome.ogg"
# Letterbox to 2.39:1 and lay the music under it, faded at both ends.
run(["-i", str(body), "-i", str(music),
     "-filter_complex", f"[0:v]drawbox=x=0:y=0:w=iw:h=138:color=black:t=fill,drawbox=x=0:y=ih-138:w=iw:h=138:color=black:t=fill[v];[1:a]atrim=0:{dur:.2f},afade=t=in:st=0:d=1.5,afade=t=out:st={dur - 3:.2f}:d=3,volume=0.9[a]",
     "-map", "[v]", "-map", "[a]", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(OUT)])
print(f"TRAILER {OUT} {dur:.1f}s")
