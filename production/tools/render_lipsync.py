"""Lip-sync review video: a character speaking a line, with a technical overlay (waveform and playhead, cue strip,
live blend-shape weights, time) and a measured closure-timing report.

  blender -b -P render_lipsync.py -- <character.glb> <cues.json> <audio> <out.mp4> [--expr exprSerious:1] [--clip Talk_loop] [--res 720]

The mouth weights come from the same coarticulation model as game/scripts/lip_sync.gd (anticipation, attack, hold to
the next cue, release; closures suppress opening shapes; loudness scales the opening; the opening total is capped),
so the video shows what the game will do. One natural blink is placed in each line. The report prints, for every
P/B/M and F/V cue, how far the full closure lands from the cue time.
"""
import argparse, json, math, os, subprocess, sys, tempfile

OPENING = ("viseme_aa", "viseme_E", "viseme_I", "viseme_O", "viseme_U", "viseme_DD", "viseme_kk", "viseme_CH",
           "viseme_SS", "viseme_nn", "viseme_RR", "viseme_TH", "jawOpen")
ANTICIPATION, ATTACK, HOLD, RELEASE = 0.04, 0.025, 0.05, 0.08   # lip_sync.gd defaults
MIN_HOLD = {"viseme_PP": 0.05, "viseme_FF": 0.04}

def prepare(data):
    cues = data["cues"]; out = []
    for i, c in enumerate(cues):
        start = max(0.0, c["t"] - ANTICIPATION); attack_end = start + ATTACK
        nxt = data["duration"] if i + 1 >= len(cues) else cues[i + 1]["t"]
        hold_end = max(nxt, attack_end + max(HOLD, MIN_HOLD.get(c["shape"], 0.0)))
        out.append((c["shape"], c["weight"], start, attack_end, hold_end, hold_end + RELEASE))
    return out

def weights_at(prep, env, t):
    w = {}
    for shape, weight, start, attack_end, hold_end, end in prep:
        if not (start <= t < end): continue
        v = (t - start) / (attack_end - start) if t < attack_end else 1.0 if t <= hold_end else 1 - (t - hold_end) / (end - hold_end)
        w[shape] = min(1.0, w.get(shape, 0.0) + v * weight)
    pp = w.get("viseme_PP", 0.0); total = sum(w.get(s, 0.0) for s in OPENING); scale = 1.0 - pp if pp else 1.0
    if env:
        p = min(max(t * 100, 0), len(env) - 1); i = int(p); e = env[i] + (env[min(i + 1, len(env) - 1)] - env[i]) * (p - i)
        scale *= 0.55 + 0.45 * e
    if total > 1: scale /= total
    for s in OPENING:
        if s in w: w[s] = max(0.0, min(1.0, w[s] * scale))
    return w

def compose(manifest):  # system python: overlay panels with PIL, then mux with the audio
    from PIL import Image, ImageDraw
    m = json.load(open(manifest)); frames, data, wave = m["frames"], m["data"], m["wave"]
    W, H = m["res"] * 16 // 9, m["res"]; panel = W - m["res"]; dur = data["duration"]
    for k, fr in enumerate(frames):
        im = Image.new("RGB", (W, H), (24, 28, 33)); im.paste(Image.open(fr["png"]).convert("RGB"), (0, 0)); d = ImageDraw.Draw(im)
        x0 = m["res"] + 16; pw = panel - 32; t = fr["t"]
        d.text((x0, 14), f"{m['label']}   t = {t:5.2f} s / {dur:.2f} s", fill=(235, 235, 235))
        wy, wh = 44, 90; d.rectangle((x0, wy, x0 + pw, wy + wh), outline=(70, 80, 90))   # waveform + playhead
        for i, a in enumerate(wave):
            x = x0 + int(pw * i / len(wave)); d.line((x, wy + wh / 2 - a * wh / 2, x, wy + wh / 2 + a * wh / 2), fill=(110, 170, 210))
        px = x0 + int(pw * min(1, t / dur)); d.line((px, wy - 4, px, wy + wh + 4), fill=(255, 210, 60), width=2)
        cy = wy + wh + 12   # cue strip
        for i, c in enumerate(data["cues"]):
            a = x0 + int(pw * c["t"] / dur); b = x0 + int(pw * (data["cues"][i + 1]["t"] if i + 1 < len(data["cues"]) else dur) / dur)
            col = (200, 90, 80) if c["shape"] in ("viseme_PP", "viseme_FF") else (80, 110, 140) if c["weight"] else (50, 55, 60)
            d.rectangle((a, cy, max(a + 1, b - 1), cy + 22), fill=col); d.text((a + 2, cy + 5), c["shape"].replace("viseme_", "")[:3], fill=(240, 240, 240))
        d.line((px, cy - 2, px, cy + 24), fill=(255, 210, 60), width=2)
        by = cy + 40; d.text((x0, by), "blend-shape weights (speech + expression)", fill=(180, 180, 180))
        for j, (s, v) in enumerate(sorted(fr["w"].items(), key=lambda kv: -kv[1])[:10]):
            y = by + 20 + j * 22; d.text((x0, y + 3), s.replace("viseme_", ""), fill=(220, 220, 220))
            d.rectangle((x0 + 110, y + 3, x0 + 110 + int((pw - 160) * v), y + 17), fill=(120, 190, 120)); d.text((x0 + pw - 40, y + 3), f"{v:.2f}", fill=(220, 220, 220))
        im.save(fr["png"].replace(".png", "_o.png"))
    tmp = os.path.dirname(frames[0]["png"])
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", "30", "-i", os.path.join(tmp, "f%04d_o.png"), "-i", m["audio"],
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-c:a", "aac", "-b:a", "160k", "-af", "apad", "-shortest",
                    "-movflags", "+faststart", m["out"]], check=True)
    print("LIPSYNC VIDEO ->", m["out"])

if len(sys.argv) == 3 and sys.argv[1] == "--compose":
    compose(sys.argv[2]); sys.exit()

import bpy
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
p = argparse.ArgumentParser(); p.add_argument("src"); p.add_argument("cues"); p.add_argument("audio"); p.add_argument("out")
p.add_argument("--expr", default=""); p.add_argument("--clip", default="Talk_loop"); p.add_argument("--res", type=int, default=720)
a = p.parse_args(argv)
data = json.load(open(a.cues)); prep = prepare(data); env = data.get("env", [])
expr = {s.split(":")[0]: float(s.split(":")[1]) for s in a.expr.split(",") if s}
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=a.src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE"); AW = arm.matrix_world
me = next(o for o in sc.objects if o.type == "MESH" and o.data.shape_keys); keys = me.data.shape_keys.key_blocks
for t in arm.animation_data.nla_tracks: t.mute = True
act = bpy.data.actions[a.clip]; arm.animation_data.action = act; f0, f1 = (int(v) for v in act.frame_range)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blender_look
sc.render.resolution_x = sc.render.resolution_y = a.res
_h = AW @ arm.data.bones["mixamorig:Head"].head_local
blender_look.setup(sc, centre=_h, scale=0.5)
cam = bpy.data.objects.new("C", bpy.data.cameras.new("C")); cam.data.lens = 70; sc.collection.objects.link(cam); sc.camera = cam
H = (AW @ arm.data.bones["mixamorig:HeadTop_End"].head_local).z - (AW @ arm.data.bones["mixamorig:Head"].head_local).z
blink_t = 0.35 * data["duration"]   # one natural blink per line, 0.12 s
FPS = 30; n = int((data["duration"] + 0.4) * FPS); tmp = tempfile.mkdtemp(); frames = []
for i in range(n):
    t = i / FPS; sc.frame_set(f0 + i % (f1 - f0 + 1))
    sw = weights_at(prep, env, t)
    bl = max(0.0, 1 - abs(t - blink_t) / 0.06) if "eyesBlink" in keys else 0.0
    allw = dict(sw); allw.update({k: min(1.0, allw.get(k, 0.0) + v) for k, v in expr.items()})
    if bl: allw["eyesBlink"] = bl
    for kb in keys: kb.value = 0.0
    for k, v in allw.items():
        if k in keys: keys[k].value = v
    bpy.context.view_layer.update()
    h = AW @ arm.pose.bones["mixamorig:Head"].head; c = h + Vector((0, -0.02, 0.10 * H))   # between mouth and eyes
    cam.location = c + Vector((0.24, -0.78, 0.03)) * (H / 0.2); cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
    png = os.path.join(tmp, f"f{i:04d}.png"); sc.render.filepath = png; bpy.ops.render.render(write_still=True)
    frames.append({"png": png, "t": t, "w": {k: round(v, 3) for k, v in allw.items() if v > 0.005}})
# closure timing: first frame at full weight after each closure cue, vs the cue time
rep = []
for c in data["cues"]:
    if c["shape"] in MIN_HOLD:
        full = [i / FPS for i in range(n) if weights_at(prep, env, i / FPS).get(c["shape"], 0) > 0.99 and i / FPS >= c["t"] - ANTICIPATION - 0.01]
        if full: rep.append(round((full[0] - c["t"]) * 1000))
print(f"CLOSURE TIMING: {len(rep)} P/B/M and F/V closures, full weight at {rep} ms from the cue (negative = before)")
# waveform for the overlay (absolute peak per bin), via ffmpeg
raw = subprocess.run(["ffmpeg", "-v", "error", "-i", a.audio, "-ac", "1", "-ar", "8000", "-f", "s16le", "-"], capture_output=True, check=True).stdout
import array
pcm = array.array("h", raw); bins = 400; per = max(1, len(pcm) // bins); peak = max(1, max(abs(v) for v in pcm))
wave = [max(abs(v) for v in pcm[k * per:(k + 1) * per] or [0]) / peak for k in range(bins)]
label = os.path.splitext(os.path.basename(a.out))[0]
man = os.path.join(tmp, "manifest.json")
json.dump({"frames": frames, "data": data, "wave": wave, "res": a.res, "audio": os.path.abspath(a.audio), "out": os.path.abspath(a.out), "label": label}, open(man, "w"))
subprocess.run(["/usr/bin/env", "-u", "PYTHONPATH", "-u", "PYTHONHOME", "python3", os.path.abspath(__file__), "--compose", man], check=True)
