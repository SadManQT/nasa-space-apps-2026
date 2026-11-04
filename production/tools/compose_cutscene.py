"""Assemble a cutscene master from its Seedance shots, voice lines, music and sound beds, with captions and cards.

  python3 compose_cutscene.py <spec.json>      (specs and sources: production/cutscenes/v7/src/, v8/src/)

spec: {"id": "CS-01", "card": ["Chapter 1 - Night One", "Arrival at Aurora"], "shots": [shot, ...],
       "music": mp3, "lines": [{"at": s, "speaker": "Kai", "text": "...", "file": mp3, "radio": false}, ...],
       "out": "<dir>/<name>", "transitions": ["cut", "dissolve", ...]}   (paths relative to the spec's folder)
Writes <out>.mp4 (1280x720, 24 fps, H.264 + AAC, captions burned in) and <out>.wav (the final mix) for the .ogv
step (ogv_writer.gd).

A shot is a file path, or an object for an edited shot (every key optional but "file"):
  {"file": mp4, "in": 0.0, "out": 12.0,                  trim to this window of the source, in seconds
   "ramp": {"hold": 2.0, "rate": 0.4},                   after "hold" seconds at normal speed the rest accelerates
                                                          smoothly: shown time = hold + ln(1 + rate * (t - hold)) / rate,
                                                          so the shot ends at (1 + rate * remaining) times speed
   "zoom": {"center": [0.5, 0.5], "from": 1.0, "to": 2.4, "start": 1.0, "end": 5.0}}
                                                          an eased push-in (smoothstep) between two shot-local
                                                          times, about a point given as fractions of the frame
"transitions" (optional, one per join) picks how each shot meets the next: "dissolve" (half-second, the default),
"cut" (hard cut, for match-on-action and continuous action) or "fadeblack" (one-second dip through black, for time
jumps); "dissolve:0.8" or "fadeblack:1.5" sets the overlap. "music" is optional; it dips under every line, and
Earth-link lines get a radio band-pass. Captions name the speaker, as the game's caption rule asks.

Optional layers, all timed in seconds of the finished cut:
  "captions": [{"at": 0.4, "until": 2.6, "text": "[no sound outside]", "speaker": ""}]   sound captions
  "texts":    [{"at": 6.6, "until": 10.6, "text": "Aurora Station ...", "chip": "Story (2046)"}]   a slate, top left
  "title":    {"at": 11.3, "until": 13.6, "text": "LAST LIGHT ACADEMY"}   the game title over the picture
  "beds":     [{"file": ogg_or_mp3, "at": 5.6, "fade_in": 2.0, "gain": 0.5}]   sound beds, looped to the end
Where no layer, line or music plays the mix is digital silence, so a vacuum exterior stays truly silent.
"""
import json, math, os, shutil, subprocess, sys, tempfile
from PIL import Image, ImageDraw, ImageFont

FONT = "/System/Library/Fonts/Avenir Next.ttc"   # faces: 0 Bold, 2 Demi Bold, 5 Medium
W, H, FPS, XF = 1280, 720, 24, 0.5
GOLD = (242, 194, 48, 255)   # the battery band and the first petal, #F2C230
ZOOM_SUPER = 4   # zoompan samples a 4x upscale so a push-in moves in quarter pixels, not whole ones

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

def slate_png(path, text, chip=None):
    """A location/date slate at the top left: a gold rule, one line of text and an optional science-label chip."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    f_text, f_chip = ImageFont.truetype(FONT, 30, index=2), ImageFont.truetype(FONT, 20, index=5)
    x, y = 84, 62
    tw = d.textlength(text, font=f_text)
    d.rounded_rectangle((x - 30, y - 16, x + tw + 26, y + 46 + (40 if chip else 0)), 12, fill=(8, 12, 22, 150))
    d.rectangle((x - 20, y - 2, x - 16, y + 36), fill=GOLD)
    d.text((x + 2, y + 2), text, font=f_text, fill=(0, 0, 0, 160))
    d.text((x, y), text, font=f_text, fill=(255, 255, 255, 255))
    if chip:
        cw = d.textlength(chip, font=f_chip)
        cy = y + 46
        d.rounded_rectangle((x - 2, cy, x + cw + 18, cy + 30), 8, fill=(31, 42, 68, 230), outline=GOLD, width=1)
        d.text((x + 8, cy + 3), chip, font=f_chip, fill=(242, 194, 48, 255))
    img.save(path)

def big_title_png(path, text):
    """The game title, letter-spaced, over a soft dark scrim at the top of the frame."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    for row in range(int(H * 0.46)):   # scrim: black fading out by mid-frame so the picture stays the subject
        d.line((0, row, W, row), fill=(0, 0, 0, int(165 * (1 - row / (H * 0.46)) ** 1.6)))
    f = ImageFont.truetype(FONT, 78, index=0)
    track = 14
    glyphs = [(ch, d.textlength(ch, font=f)) for ch in text]
    tw = sum(w for _, w in glyphs) + track * (len(glyphs) - 1)
    x, y = (W - tw) / 2, H * 0.17
    for ch, w in glyphs:
        if ch != " ":
            d.text((x + 3, y + 3), ch, font=f, fill=(0, 0, 0, 190))
            d.text((x, y), ch, font=f, fill=(255, 255, 255, 255))
        x += w + track
    img.save(path)

def alpha_fade(stream, at, until, fade=0.3):
    return f"{stream}format=rgba,fade=t=in:st={at:.3f}:d={fade:.2f}:alpha=1,fade=t=out:st={until - fade:.3f}:d={fade:.2f}:alpha=1"

def shot_filter(i, shot, length):
    """The filter chain for one input shot: trim, retime, zoom and conform to WxH at FPS on one timebase."""
    steps = [f"[{i}:v]"]
    if "in" in shot or "out" in shot:
        steps.append(f"trim=start={shot.get('in', 0.0):.3f}:end={shot.get('out', length):.3f},setpts=PTS-STARTPTS,")
    zoom = shot.get("zoom")
    if zoom:
        steps.append(f"scale={W * ZOOM_SUPER}:{H * ZOOM_SUPER}:flags=lanczos,")
    else:
        steps.append(f"scale={W}:{H},")
    ramp = shot.get("ramp")
    if ramp:
        hold, rate = float(ramp.get("hold", 0.0)), float(ramp["rate"])
        steps.append(f"setpts='if(lt(T,{hold:.3f}),T,{hold:.3f}+log(1+{rate:.4f}*(T-{hold:.3f}))/{rate:.4f})/TB',")
    steps.append(f"fps={FPS},")
    if zoom:
        cx, cy = zoom.get("center", [0.5, 0.5]); z0, z1 = float(zoom.get("from", 1.0)), float(zoom["to"])
        s, e = float(zoom["start"]), float(zoom["end"])
        ease = f"st(0,clip(((in-1)/{FPS}-{s:.3f})/{e - s:.3f},0,1))\\;{z0:.4f}+{z1 - z0:.4f}*ld(0)*ld(0)*(3-2*ld(0))"
        steps.append(f"zoompan=z='{ease}':x='iw*{cx:.4f}-iw/zoom/2':y='ih*{cy:.4f}-ih/zoom/2':d=1:s={W}x{H}:fps={FPS},")
    steps.append(f"format=yuv420p,setpts=PTS-STARTPTS,settb=AVTB[v{i}]")   # one timebase so cut (concat) and xfade can mix
    return "".join(steps)

def shown_length(shot, length):
    """Seconds the shot occupies in the cut after its trim and ramp."""
    seen = min(float(shot.get("out", length)), length) - float(shot.get("in", 0.0))
    ramp = shot.get("ramp")
    if ramp:
        hold, rate = float(ramp.get("hold", 0.0)), float(ramp["rate"])
        seen = hold + math.log(1 + rate * (seen - hold)) / rate
    return seen

spec_path = sys.argv[1]; base = os.path.dirname(os.path.abspath(spec_path)); spec = json.load(open(spec_path))
rel = lambda p: p if os.path.isabs(p) else os.path.join(base, p)
out = rel(spec["out"]); work = tempfile.mkdtemp(prefix="cutscene_")   # card and caption PNGs
shots = [s if isinstance(s, dict) else {"file": s} for s in spec["shots"]]
files = [rel(s["file"]) for s in shots]; lens = [shown_length(s, dur(f)) for s, f in zip(shots, files)]
JOIN = {"dissolve": ("fade", XF), "fadeblack": ("fadeblack", 1.0), "cut": (None, 0.0)}   # xfade kind, overlap
def join(spec_join):
    kind, _, overlap = spec_join.partition(":")
    return JOIN[kind][0], float(overlap) if overlap else JOIN[kind][1]
joins = [join(j) for j in (spec.get("transitions") or ["dissolve"] * (len(shots) - 1))]
assert len(joins) == len(shots) - 1, "transitions needs one entry per join between shots"
total = sum(lens) - sum(d for _, d in joins)

# video: scale, join shot to shot, fade from and to black, chapter card, captions
inputs, vf = [], []
for i, (s, f) in enumerate(zip(shots, files)):
    inputs += ["-i", f]
    vf.append(shot_filter(i, s, dur(f)))
cur, t = "v0", lens[0]
for i in range(1, len(shots)):
    kind, d = joins[i - 1]
    if kind:
        vf.append(f"[{cur}][v{i}]xfade=transition={kind}:duration={d}:offset={t - d:.3f}[x{i}]")
    else:
        vf.append(f"[{cur}][v{i}]concat=n=2:v=1:a=0[x{i}]")
    cur = f"x{i}"; t += lens[i] - d
vf.append(f"[{cur}]fade=t=in:st=0:d=0.8,fade=t=out:st={total - 1.0:.3f}:d=1.0[base]"); cur = "base"
n = len(shots)
def overlay(png, enable_from, enable_to, fade=None, tag=""):
    """Adds a full-frame PNG input shown between two times, with an optional alpha fade at both ends."""
    global cur, n
    inputs.extend(["-loop", "1", "-t", f"{total:.3f}", "-i", png])
    src = f"[{n}:v]"
    if fade is not None:
        vf.append(alpha_fade(src, enable_from, enable_to, fade) + f"[o{n}]"); src = f"[o{n}]"
    vf.append(f"[{cur}]{src}overlay=enable='between(t,{enable_from:.2f},{enable_to:.2f})'[{tag}{n}]"); cur = f"{tag}{n}"; n += 1
if spec.get("card"):
    title_png(f"{work}/card.png", spec["card"]); inputs += ["-loop", "1", "-t", f"{total:.3f}", "-i", f"{work}/card.png"]
    vf.append(f"[{n}:v]format=rgba,fade=t=in:st=0.6:d=0.8:alpha=1,fade=t=out:st=4.2:d=0.8:alpha=1[card]")
    vf.append(f"[{cur}][card]overlay=enable='between(t,0.5,5.1)'[c]"); cur = "c"; n += 1
lines = spec.get("lines", [])
for k, ln in enumerate(lines):
    ln["dur"] = dur(rel(ln["file"]))
    caption_png(f"{work}/cap{k}.png", ln["speaker"], ln["text"])
    overlay(f"{work}/cap{k}.png", ln["at"] - 0.15, ln["at"] + ln["dur"] + 0.5, tag="k")
for k, cap in enumerate(spec.get("captions", [])):   # sound captions: no speaker, no voice file
    caption_png(f"{work}/scap{k}.png", cap.get("speaker", ""), cap["text"])
    overlay(f"{work}/scap{k}.png", cap["at"], cap["until"], tag="s")
for k, text in enumerate(spec.get("texts", [])):
    slate_png(f"{work}/slate{k}.png", text["text"], text.get("chip"))
    overlay(f"{work}/slate{k}.png", text["at"], text["until"], fade=0.5, tag="t")
if spec.get("title"):
    big_title_png(f"{work}/title.png", spec["title"]["text"])
    overlay(f"{work}/title.png", spec["title"]["at"], spec["title"]["until"], fade=0.45, tag="g")

# audio: music under everything (ducked under speech), beds faded in on their cue, voice lines placed on their beats
af, mix = [], []
if spec.get("music"):
    inputs += ["-i", rel(spec["music"])]
    duck = "+".join(f"between(t,{ln['at'] - 0.3:.2f},{ln['at'] + ln['dur'] + 0.3:.2f})" for ln in lines) or "0"
    af.append(f"[{n}:a]atrim=0:{total:.3f},afade=t=in:d=1.5,afade=t=out:st={total - 2.5:.3f}:d=2.5,"
              f"volume='if({duck},0.28,0.55)':eval=frame[mus]"); mix.append("[mus]"); n += 1
for k, bed in enumerate(spec.get("beds", [])):
    inputs += ["-stream_loop", "-1", "-i", rel(bed["file"])]
    at, until = float(bed["at"]), float(bed.get("until", total)); ms = int(at * 1000)
    af.append(f"[{n}:a]aformat=sample_rates=48000:channel_layouts=stereo,atrim=0:{until - at:.3f},"
              f"afade=t=in:d={float(bed.get('fade_in', 1.0)):.2f},afade=t=out:st={until - at - 0.6:.3f}:d=0.6,"
              f"adelay={ms}|{ms},volume={float(bed.get('gain', 0.5)):.3f}[b{k}]"); mix.append(f"[b{k}]"); n += 1
for k, ln in enumerate(lines):
    inputs += ["-i", rel(ln["file"])]
    chain = "highpass=f=320,lowpass=f=3200,acompressor=threshold=0.2:ratio=4," if ln.get("radio") else ""
    ms = int(ln["at"] * 1000)
    af.append(f"[{n}:a]{chain}aformat=sample_rates=48000:channel_layouts=stereo,adelay={ms}|{ms},volume=1.6[l{k}]"); mix.append(f"[l{k}]"); n += 1
if mix:
    af.append(f"{''.join(mix)}amix=inputs={len(mix)}:normalize=0,atrim=0:{total:.3f},apad=whole_dur={total:.3f},alimiter=limit=0.95[aout]")
else:   # no music and no lines: a silent track keeps the .wav step working
    af.append(f"anullsrc=r=48000:cl=stereo,atrim=0:{total:.3f}[aout]")

graph = ";".join(vf + af)
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *inputs, "-filter_complex", graph, "-map", f"[{cur}]", "-map", "[aout]",
                "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart",
                "-t", f"{total:.3f}", out + ".mp4"], check=True)
shutil.rmtree(work)
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", out + ".mp4", "-vn", "-ac", "2", "-ar", "48000", out + ".wav"], check=True)
print(f"CUTSCENE {spec['id']}: {total:.1f} s, {len(shots)} shots, {len(lines)} lines -> {out}.mp4")
