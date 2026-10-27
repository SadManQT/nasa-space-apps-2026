"""Assemble a cutscene master from its Seedance shots, voice lines and music, with captions and a chapter card.

  python3 compose_cutscene.py <spec.json>      (specs and sources: production/cutscenes/v7/src/)

spec: {"id": "CS-01", "card": ["Chapter 1 - Night One", "Arrival at Aurora"], "shots": [mp4, ...],
       "music": mp3, "lines": [{"at": s, "speaker": "Kai", "text": "...", "file": mp3, "radio": false}, ...],
       "out": "<dir>/<name>"}   (paths relative to the spec's folder)
Writes <out>.mp4 (1280x720, 24 fps, H.264 + AAC, captions burned in) and <out>.wav (the final mix) for the .ogv
step (ogv_writer.gd). Shots join with half-second dissolves; the music dips under every line; Earth-link lines get
a radio band-pass. Captions name the speaker, as the game's caption rule asks.
"""
import json, os, shutil, subprocess, sys, tempfile
from PIL import Image, ImageDraw, ImageFont

FONT = "/System/Library/Fonts/Avenir Next.ttc"   # faces: 0 Bold, 2 Demi Bold, 5 Medium
W, H, FPS, XF = 1280, 720, 24, 0.5

def dur(path):
    return float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path]))

def caption_png(path, speaker, text):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    f_name, f_text = ImageFont.truetype(FONT, 26, index=2), ImageFont.truetype(FONT, 34, index=5)
    line = f"{speaker}:  " if speaker else ""
    lead = d.textlength(line, font=f_name)
    rows = [""]   # wrap long lines; the first row carries the speaker
    for word in text.split():
        trial = f"{rows[-1]} {word}".strip()
        if rows[-1] and d.textlength(trial, font=f_text) + (lead if len(rows) == 1 else 0) > W - 200:
            rows.append(word)
        else:
            rows[-1] = trial
    widths = [d.textlength(r, font=f_text) + (lead if i == 0 else 0) for i, r in enumerate(rows)]
    tw, y = max(widths), H - 92 - 46 * (len(rows) - 1)
    x = (W - tw) / 2
    d.rounded_rectangle((x - 22, y - 12, x + tw + 22, y + 50 + 46 * (len(rows) - 1)), 12, fill=(8, 12, 22, 170))
    d.text((x, y + 6), line, font=f_name, fill=(255, 214, 120, 255))
    for i, r in enumerate(rows):
        d.text((x + (lead if i == 0 else 0), y + 46 * i), r, font=f_text, fill=(255, 255, 255, 255))
    img.save(path)

def title_png(path, lines):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    fonts = [ImageFont.truetype(FONT, 54, index=0), ImageFont.truetype(FONT, 30, index=5)]
    y = H * 0.40
    for t, f in zip(lines, fonts):
        w = d.textlength(t, font=f)
        d.text(((W - w) / 2 + 2, y + 2), t, font=f, fill=(0, 0, 0, 160))
        d.text(((W - w) / 2, y), t, font=f, fill=(255, 255, 255, 255))
        y += f.size * 1.5
    img.save(path)

spec_path = sys.argv[1]; base = os.path.dirname(os.path.abspath(spec_path)); spec = json.load(open(spec_path))
rel = lambda p: p if os.path.isabs(p) else os.path.join(base, p)
out = rel(spec["out"]); work = tempfile.mkdtemp(prefix="cutscene_")   # card and caption PNGs
shots = [rel(s) for s in spec["shots"]]; lens = [dur(s) for s in shots]
total = sum(lens) - XF * (len(shots) - 1)

# video: scale, dissolve shot to shot, fade from and to black, chapter card, captions
inputs, vf = [], []
for i, s in enumerate(shots):
    inputs += ["-i", s]
    vf.append(f"[{i}:v]scale={W}:{H},fps={FPS},format=yuv420p,setpts=PTS-STARTPTS[v{i}]")
cur, t = "v0", lens[0]
for i in range(1, len(shots)):
    vf.append(f"[{cur}][v{i}]xfade=transition=fade:duration={XF}:offset={t - XF:.3f}[x{i}]"); cur = f"x{i}"; t += lens[i] - XF
vf.append(f"[{cur}]fade=t=in:st=0:d=0.8,fade=t=out:st={total - 1.0:.3f}:d=1.0[base]"); cur = "base"
n = len(shots)
if spec.get("card"):
    title_png(f"{work}/card.png", spec["card"]); inputs += ["-loop", "1", "-t", f"{total:.3f}", "-i", f"{work}/card.png"]
    vf.append(f"[{n}:v]format=rgba,fade=t=in:st=0.6:d=0.8:alpha=1,fade=t=out:st=4.2:d=0.8:alpha=1[card]")
    vf.append(f"[{cur}][card]overlay=enable='between(t,0.5,5.1)'[c]"); cur = "c"; n += 1
lines = spec.get("lines", [])
for k, ln in enumerate(lines):
    ln["dur"] = dur(rel(ln["file"]))
    caption_png(f"{work}/cap{k}.png", ln["speaker"], ln["text"])
    inputs += ["-loop", "1", "-t", f"{total:.3f}", "-i", f"{work}/cap{k}.png"]
    vf.append(f"[{cur}][{n}:v]overlay=enable='between(t,{ln['at'] - 0.15:.2f},{ln['at'] + ln['dur'] + 0.5:.2f})'[k{k}]"); cur = f"k{k}"; n += 1

# audio: music under everything (ducked under speech), voice lines placed on their beats
af, mix = [], []
if spec.get("music"):
    inputs += ["-i", rel(spec["music"])]
    duck = "+".join(f"between(t,{ln['at'] - 0.3:.2f},{ln['at'] + ln['dur'] + 0.3:.2f})" for ln in lines) or "0"
    af.append(f"[{n}:a]atrim=0:{total:.3f},afade=t=in:d=1.5,afade=t=out:st={total - 2.5:.3f}:d=2.5,"
              f"volume='if({duck},0.28,0.55)':eval=frame[mus]"); mix.append("[mus]"); n += 1
for k, ln in enumerate(lines):
    inputs += ["-i", rel(ln["file"])]
    chain = "highpass=f=320,lowpass=f=3200,acompressor=threshold=0.2:ratio=4," if ln.get("radio") else ""
    ms = int(ln["at"] * 1000)
    af.append(f"[{n}:a]{chain}aformat=sample_rates=48000:channel_layouts=stereo,adelay={ms}|{ms},volume=1.6[l{k}]"); mix.append(f"[l{k}]"); n += 1
af.append(f"{''.join(mix)}amix=inputs={len(mix)}:normalize=0,atrim=0:{total:.3f},alimiter=limit=0.95[aout]")

graph = ";".join(vf + af)
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *inputs, "-filter_complex", graph, "-map", f"[{cur}]", "-map", "[aout]",
                "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart",
                "-t", f"{total:.3f}", out + ".mp4"], check=True)
shutil.rmtree(work)
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", out + ".mp4", "-vn", "-ac", "2", "-ar", "48000", out + ".wav"], check=True)
print(f"CUTSCENE {spec['id']}: {total:.1f} s, {len(shots)} shots, {len(lines)} lines -> {out}.mp4")
