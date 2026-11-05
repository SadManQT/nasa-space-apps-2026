#!/usr/bin/env python3
"""Claude Motion explainer pipeline (M1-63): one spec -> one science explainer the game plays.

    python3 production/tools/motion/build.py check [spec ...]          # validate every spec (default: all)
    python3 production/tools/motion/build.py stills <spec> [t ...]      # PNG stills + contact sheet (default: mid-beat times)
    python3 production/tools/motion/build.py render <spec>              # master MP4, game OGV, registry entry

Spec format and house style: production/explainers/motion/STYLE.md. Every number a player reads comes from a NASA
fixture through a {token}; any other digit in on-screen text fails the check unless the spec lists it in "literals"
with a reason. Needs: node + `npm install` in this folder (playwright-core, uses the installed Google Chrome),
ffmpeg, python3 + numpy, and Godot 4.7 (its Movie Maker is the only Theora encoder here; see ogv_writer.gd).
"""
import datetime as dt
import fcntl
import hashlib
import json
import re
import shutil
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
EXPL = ROOT / "production/explainers/motion"
FIXTURES = ROOT / "game/resources/data/nasa"
REGISTRY = ROOT / "game/resources/campaign/content/explainers.json"
OUT_DIR = ROOT / "game/assets/explainers/science"
GODOT = ROOT / "production/tools/godot_gated"   # the machine-wide two-heavy-processes gate
LEVELS = {"concept", "explainer", "method"}
LABELS = {"measured", "model", "diagram"}
FRAMING = {"title", "takeaway"}                   # shared beats that carry no data, so no honest label
TOKEN = re.compile(r"\{(\w+)\}")


def fail(msg):
    raise SystemExit(f"motion: {msg}")


# ---- fixture values -------------------------------------------------------------------------------------------
def lookup(ref):
    """'fixture:derived.name[1]' -> value. A name inside a list of {name, value} dicts selects that item's value."""
    fixture, _, path = ref.partition(":")
    f = FIXTURES / f"{fixture}.json"
    if not f.exists():
        fail(f"no fixture {fixture}")
    cur = json.loads(f.read_text())
    for part in re.findall(r"\[-?\d+\]|[^.\[\]]+", path):
        if part.startswith("["):
            cur = cur[int(part[1:-1])]
        elif isinstance(cur, list):
            hit = [x for x in cur if isinstance(x, dict) and x.get("name") == part]
            if not hit:
                fail(f"{ref}: no item named {part}")
            cur = hit[0]["value"]
        else:
            if part not in cur:
                fail(f"{ref}: no field {part}")
            cur = cur[part]
    return cur


def fmt(value, how):
    if how == "time":                       # 2017-09-10T15:35Z -> 15:35 UTC
        return value[11:16] + " UTC"
    if how == "date":                       # 2017-09-10... -> 10 September 2017
        d = dt.date.fromisoformat(value[:10])
        return f"{d.day} {d.strftime('%B %Y')}"
    if how == "year":
        return value[:4]
    if how == "day":                        # 2017-09-10... -> 10 September
        d = dt.date.fromisoformat(value[:10])
        return f"{d.day} {d.strftime('%B')}"
    if how == "words":                      # 70 -> seventy (captions read better in words below 100)
        ones = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen".split()
        tens = "_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()
        n = int(value)
        return ones[n] if n < 20 else tens[n // 10] + ("" if n % 10 == 0 else "-" + ones[n % 10])
    out = (how or "{}").format(value)
    return out.replace("-", "\u2212") if how and "+" in how else out   # a true minus sign for signed values


def texts(spec):
    """Every on-screen string the spec carries, with where it sits."""
    yield "title", spec["title"]
    yield "ends_on", spec["ends_on"]
    for i, (_, _, c) in enumerate(spec["captions"]):
        yield f"captions[{i}]", c
    for i, b in enumerate(spec["beats"]):
        for k, v in b.items():
            if isinstance(v, str) and k not in ("scene", "label"):
                yield f"beats[{i}].{k}", v
            if isinstance(v, list):
                for j, s in enumerate(v):
                    if isinstance(s, str):
                        yield f"beats[{i}].{k}[{j}]", s


def resolve(spec):
    """Return (resolved spec, problems). Resolution replaces {tokens}; the checks run on the unresolved text."""
    problems = []
    if not re.fullmatch(r"[a-z0-9_]+", spec.get("id", "")):
        problems.append("id: lower-case letters, digits and _ only")
    if spec.get("level") not in LEVELS:
        problems.append(f"level must be one of {sorted(LEVELS)}")
    length = spec.get("length_s", 0)
    if not 8 <= length <= 45:
        problems.append(f"length_s {length}: explainers run 8-45 s")
    if spec.get("fps") != 24:
        problems.append("fps must be 24 (the game's films are 24 fps)")
    for s in spec.get("sources", []):
        if not (FIXTURES / f"{s}.json").exists():
            problems.append(f"source {s}: no fixture in game/resources/data/nasa/")
    beats = spec.get("beats", [])
    if not beats or beats[0]["from"] != 0 or beats[-1]["to"] != length:
        problems.append("beats must run from 0 to length_s")
    for a, b in zip(beats, beats[1:]):
        if a["to"] != b["from"]:
            problems.append(f"beats {a['scene']} -> {b['scene']}: gap or overlap at {a['to']}/{b['from']}")
    for b in beats:
        if b["scene"] not in FRAMING and b.get("label") not in LABELS:
            problems.append(f"beat {b['scene']}: needs an honest label {sorted(LABELS)}")
    last = 0
    for a, b, c in spec.get("captions", []):
        if not (last <= a < b <= length):
            problems.append(f"caption at {a}: out of order, overlapping or past the end")
        if b - a < 1.8:
            problems.append(f"caption at {a}: on screen under 1.8 s")
        last = b
    values = {}
    for name, v in spec.get("values", {}).items():
        if v["from"].partition(":")[0] not in spec.get("sources", []):
            problems.append(f"value {name}: fixture not listed in sources")
        values[name] = fmt(lookup(v["from"]), v.get("fmt"))
    literals = [x["text"] for x in spec.get("literals", [])]
    if any(not x.get("why") for x in spec.get("literals", [])):
        problems.append("every literal needs a 'why'")
    for where, s in texts(spec):
        for tok in TOKEN.findall(s):
            if tok not in values:
                problems.append(f"{where}: unknown token {{{tok}}}")
        bare = TOKEN.sub("", s)
        for lit in literals:
            bare = bare.replace(lit, "")
        if re.search(r"\d", bare):
            problems.append(f"{where}: a number not taken from a fixture token or listed literal: {s!r}")
        if re.search(r"[ঀ-৿]", s):
            problems.append(f"{where}: Bangla script is not allowed in the game")
    out = json.loads(TOKEN.sub(lambda m: values.get(m.group(1), m.group(0)), json.dumps(spec)))
    out["v"] = values                                  # scenes draw data numbers from SPEC.v, never from literals
    for a, b, c in out.get("captions", []):
        if len(c) > 120 or len(c) / (b - a) > 20:
            problems.append(f"caption at {a}: {len(c)} characters in {b - a:.1f} s is too much to read")
        if len(c.split()) > 16:                       # every age reads it (STYLE.md §2): short sentences
            problems.append(f"caption at {a}: {len(c.split())} words; keep captions to 16 words or fewer")
    return out, problems


def load(path):
    spec, problems = resolve(json.loads(Path(path).read_text()))
    if problems:
        fail(f"{path}:\n  " + "\n  ".join(problems))
    return spec


# ---- stage page -----------------------------------------------------------------------------------------------
def stage(spec):
    ui = json.loads((ROOT / "game/resources/ui/ui_design.json").read_text())["colour"]
    style = {
        "colour": {**ui, "water": "#2E8BC0", "regolith": "#7A7672", "signal": "#F26B21", "space": "#05060A"},
        "font": '"Avenir Next", "Segoe UI", "Helvetica Neue", sans-serif',
        "mono": '"SF Mono", Menlo, Consolas, monospace',
    }
    series = {k: lookup(v) for k, v in spec.get("series", {}).items()}
    work = EXPL / "build" / spec["id"]
    work.mkdir(parents=True, exist_ok=True)
    html = (
        "<!doctype html><meta charset=utf-8><style>html,body{margin:0;background:#000}canvas{display:block}</style>"
        '<canvas id="c"></canvas>'
        f"<script>const SPEC={json.dumps(spec)};const D={json.dumps(series)};const STYLE={json.dumps(style)};</script>"
        f"<script>{(HERE / 'engine.js').read_text()}</script>"
        f"<script>{(EXPL / 'scenes' / spec['scenes']).read_text()}</script>"
    )
    (work / "stage.html").write_text(html)
    return work


def run(cmd, **kw):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, **kw)
    if r.returncode != 0:
        fail(f"{Path(str(cmd[0])).name} failed:\n{(r.stdout + r.stderr)[-2500:]}")
    return r.stdout


def node(*args):
    if not (HERE / "node_modules/playwright-core").exists():
        run(["npm", "install", "--no-audit", "--no-fund"], cwd=HERE)
    return run(["node", HERE / "render.mjs", *args])


# ---- sound bed: a quiet synthesized pad, a soft chime on each beat and a pop per caption; nothing spoken (STYLE.md) ----
def sound_bed(spec, path, rate=44100):
    n = int(spec["length_s"] * rate)
    t = np.arange(n) / rate
    out = np.zeros(n)
    for f, a in [(146.83, .30), (220.0, .22), (329.63, .14), (369.99, .10), (554.37, .05)]:   # D3 A3 E4 F#4 C#5
        out += a * np.sin(2 * np.pi * f * t + np.sin(2 * np.pi * .07 * t) * 1.5) * (.75 + .25 * np.sin(2 * np.pi * .05 * t + f))
    for i, b in enumerate(spec["beats"][1:]):
        s = int(b["from"] * rate)
        k = np.arange(n - s) / rate
        f = [880.0, 659.25, 739.99, 987.77][i % 4]
        out[s:] += .18 * np.sin(2 * np.pi * f * k) * np.exp(-k * 2.2) * (1 - np.exp(-k * 120))
    for c0, _, _ in spec["captions"]:                                                          # a soft "pop" as each idea appears
        s = int(c0 * rate)
        k = np.arange(min(n - s, int(.12 * rate))) / rate
        out[s:s + len(k)] += .22 * np.sin(2 * np.pi * (1300 - 4200 * k) * k) * np.exp(-k * 38)
    out *= np.minimum(1, t / 2.0) * np.minimum(1, (spec["length_s"] - t) / 2.5)
    out *= 10 ** (-30 / 20) / np.sqrt(np.mean(out ** 2))                                         # about -30 dBFS RMS
    pcm = (np.clip(out, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(rate)
        w.writeframes(np.repeat(pcm[:, None], 2, axis=1).tobytes())


# ---- registry -------------------------------------------------------------------------------------------------
def register(spec, ogv, length):
    with open(EXPL / "build" / ".registry.lock", "w") as lock:   # two render chains may finish at once
        fcntl.flock(lock, fcntl.LOCK_EX)
        _register(spec, ogv, length)


def _register(spec, ogv, length):
    reg = json.loads(REGISTRY.read_text()) if REGISTRY.exists() else {
        "schema_version": 1,
        "about": "Explainer clips the hint player, data cards and Journal play (MASTER_PLAN.md section 5). Science "
                 "explainers are built by production/tools/motion/build.py from production/explainers/motion/specs/; "
                 "do not edit their entries by hand.",
        "explainers": [],
    }
    entry = {
        "id": spec["id"], "kind": "science", "level": spec["level"], "title": spec["title"],
        "path": "res://" + str(ogv.relative_to(ROOT / "game")), "length_s": round(length, 2),
        "labels": sorted({b["label"] for b in spec["beats"] if b.get("label")}),
        "sources": spec["sources"], "used_by": spec.get("used_by", []),
        "captions": [{"start": a, "end": b, "text": c} for a, b, c in spec["captions"]],
        "ends_on": spec["ends_on"], "spec": str(Path(spec["_spec"]).relative_to(ROOT)),
    }
    reg["explainers"] = sorted([e for e in reg["explainers"] if e["id"] != spec["id"]] + [entry], key=lambda e: e["id"])
    REGISTRY.write_text(json.dumps(reg, indent=1, ensure_ascii=False) + "\n")


def probe(path):
    out = run(["ffprobe", "-v", "error", "-show_entries", "format=duration:stream=codec_name,width,height", "-of", "json", path])
    return json.loads(out)


# ---- commands -------------------------------------------------------------------------------------------------
def cmd_check(paths):
    paths = paths or sorted((EXPL / "specs").glob("*.json"))
    for p in paths:
        load(p)
        print(f"ok   {Path(p).relative_to(ROOT)}")


def cmd_stills(path, times):
    spec = load(path)
    work = stage(spec)
    times = times or [round((b["from"] + b["to"]) / 2, 2) for b in spec["beats"]] + [c[0] + 1 for c in spec["captions"]]
    stills = work / "stills"
    shutil.rmtree(stills, ignore_errors=True)
    node(work / "stage.html", "stills", stills, *sorted(times))
    cols = 4
    run(["ffmpeg", "-v", "error", "-y", "-i", stills / "%02d.png", "-vf", f"scale=480:-1,tile={cols}x{-(-len(times) // cols)}:padding=8:color=black",
         "-frames:v", "1", work / "contact_sheet.jpg"])
    print(f"stills: {stills} ({len(times)})\ncontact sheet: {work / 'contact_sheet.jpg'}")


def cmd_render(path):
    spec = load(path)
    spec["_spec"] = str(Path(path).resolve())
    work = stage(spec)
    frames, small = work / "frames", work / "small"
    page = hashlib.sha1((work / "stage.html").read_bytes()).hexdigest()
    if (frames / ".stage").exists() and (frames / ".stage").read_text() == page:
        print("resuming: keeping the frames already rendered for this exact page")
    else:
        shutil.rmtree(frames, ignore_errors=True)
        frames.mkdir(parents=True)
        (frames / ".stage").write_text(page)
    shutil.rmtree(small, ignore_errors=True)
    node(work / "stage.html", "frames", frames)
    sound_bed(spec, work / "bed.wav")
    master = EXPL / "masters" / f"{spec['id']}.mp4"                                 # 1920x1080, gitignored, rebuildable
    master.parent.mkdir(exist_ok=True)
    run(["ffmpeg", "-v", "error", "-y", "-framerate", 24, "-i", frames / "%05d.jpg", "-i", work / "bed.wav",
         "-c:v", "libx264", "-crf", 16, "-preset", "slow", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-shortest", master])
    small.mkdir()
    run(["ffmpeg", "-v", "error", "-y", "-i", frames / "%05d.jpg", "-vf", "scale=1280:720:flags=lanczos", "-q:v", 2, small / "%05d.jpg"])
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    ogv = OUT_DIR / f"{spec['id']}.ogv"
    run([GODOT, "--path", ROOT / "game", "--resolution", "1280x720", "--write-movie", ogv, "--fixed-fps", 24,
         "-s", ROOT / "production/tools/ogv_writer.gd", "--", small, work / "bed.wav"])
    info = probe(ogv)
    length = float(info["format"]["duration"])
    video = [s for s in info["streams"] if s.get("width")]
    if not video or (video[0]["width"], video[0]["height"]) != (1280, 720) or abs(length - spec["length_s"]) > .25:   # 1280x720: the project's film size
        fail(f"{ogv.name}: unexpected encode {info}")
    register(spec, ogv, length)
    shutil.rmtree(frames); shutil.rmtree(small)
    print(f"master: {master.relative_to(ROOT)}\ngame:   {ogv.relative_to(ROOT)} ({ogv.stat().st_size / 1e6:.1f} MB, {length:.2f} s)\n"
          f"registered in {REGISTRY.relative_to(ROOT)}")


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in ("check", "stills", "render"):
        print(__doc__); sys.exit(2)
    mode, rest = sys.argv[1], sys.argv[2:]
    if mode == "check":
        cmd_check(rest)
    elif mode == "stills":
        cmd_stills(rest[0], [float(x) for x in rest[1:]])
    else:
        cmd_render(rest[0])
