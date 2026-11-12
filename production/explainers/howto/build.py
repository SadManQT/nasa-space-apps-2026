#!/usr/bin/env python3
"""How-to clips (M1-59, doc 25 §7): short, silent, captioned clips recorded from the game's own screens.

    python3 production/explainers/howto/build.py check                 # every spec: length, captions, cards, English only
    python3 production/explainers/howto/build.py dump  specs/<id>.json # headless: the visible named controls at the stage
    python3 production/explainers/howto/build.py render specs/<id>.json [more specs...]   (or: render all)
    python3 production/explainers/howto/build.py pending               # list unrendered clips in the registry

render: Godot Movie Maker records director.gd driving the real campaign/trainer screens to PNG frames (1152x648,
24 fps), the clip's last length_s x 24 frames are kept, production/tools/ogv_writer.gd turns them into
game/assets/explainers/<id>.ogv, the entry is written to game/resources/campaign/content/explainers.json (kind
"how_to"; never edit it by hand) and a contact sheet of stills lands in build/<id>/sheet.jpg for review.
Godot runs through production/tools/godot_gated, one job at a time.
"""
import json, os, re, shutil, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = ROOT / "production/explainers/howto"
SPECS = HERE / "specs"
BUILD = HERE / "build"
GODOT = ROOT / "production/tools/godot_gated"
REGISTRY = ROOT / "game/resources/campaign/content/explainers.json"
HOW_TO = ROOT / "game/resources/campaign/content/how_to.json"
OUT_DIR = ROOT / "game/assets/explainers"
SIZE, FPS = (1280, 720), 24   # the project film size: cutscenes and science explainers are 1280x720 (the window override pins it)
BANGLA = re.compile("[ঀ-৿]")


def fail(msg):
    sys.exit(f"build.py: {msg}")


def load(path):
    path = Path(path) if Path(path).is_absolute() else (SPECS / Path(path).name)
    spec = json.loads(path.read_text())
    problems = []
    if spec.get("id") != path.stem:
        problems.append("id must match the file name")
    length = spec.get("length_s", 0)
    if not 8 <= length <= 20:
        problems.append("length_s must be 8-20 s")
    cards = json.loads(HOW_TO.read_text())["cards"]
    for card in spec.get("cards", []):
        if card not in cards:
            problems.append(f"card {card} is not in how_to.json")
    last = 0.0
    for start, end, text in spec.get("captions", []):
        if start < last or end <= start or end > length or end - start < 1.8:
            problems.append(f"caption at {start}s must follow the last, last 1.8 s or more and end inside the clip")
        if len(text.split()) > 16:
            problems.append(f"caption at {start}s has more than 16 words")
        last = end
    for text in [spec.get("title", "")] + [c[2] for c in spec.get("captions", [])] + [s[3] for s in spec.get("steps", []) if len(s) > 3 and isinstance(s[3], str)]:
        if BANGLA.search(text):
            problems.append("English only")
    if not spec.get("captions"):
        problems.append("a clip needs captions")
    if problems:
        fail(f"{path.name}: " + "; ".join(problems))
    spec["_spec"] = path
    return spec


def run(cmd, **kw):
    return subprocess.run([str(c) for c in cmd], check=True, text=True, capture_output=True, **kw).stdout


def godot(*args, log=None):
    # HOWTO_BACKGROUND=1: park the recording window mostly off-screen so it does not cover the user's work.
    park = ["--position", "6000,6000"] if os.environ.get("HOWTO_BACKGROUND") and "--headless" not in args else []
    out = subprocess.run([str(GODOT), "--path", str(ROOT / "game"), *park, *map(str, args)], text=True, capture_output=True)
    if log:
        Path(log).write_text(out.stdout + out.stderr)
    return out


def cmd_dump(path):
    spec = load(path)
    out = godot("--headless", "-s", HERE / "director.gd", "--", "--spec", spec["_spec"], "--dump")
    print("\n".join(l for l in (out.stdout + out.stderr).splitlines() if not l.startswith("ROOT ")))


def cmd_render(path):
    spec = load(path)
    work = BUILD / spec["id"]
    shutil.rmtree(work, ignore_errors=True)
    raw, jpg = work / "raw", work / "jpg"
    raw.mkdir(parents=True)
    jpg.mkdir()
    out = godot("--resolution", f"{SIZE[0]}x{SIZE[1]}", "--fixed-fps", FPS, "--write-movie", raw / "f.png",
                "-s", HERE / "director.gd", "--", "--spec", spec["_spec"], log=work / "director.log")
    frames = sorted(raw.glob("f*.png"))
    total = round(spec["length_s"] * FPS)
    if "HOWTO_END" not in out.stdout or len(frames) < total:
        fail(f"{spec['id']}: the director did not finish (see {work / 'director.log'})")
    # Movie Maker writes one frame per engine frame; the timeline is the last `total` frames before quit.
    keep = frames[len(frames) - total - 1:len(frames) - 1]
    for i, frame in enumerate(keep):
        frame.rename(raw / f"k{i:05d}.png")
    run(["ffmpeg", "-v", "error", "-y", "-framerate", FPS, "-i", raw / "k%05d.png", "-q:v", 2, jpg / "%05d.jpg"])
    shutil.rmtree(raw)
    run(["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo", "-t", spec["length_s"], work / "silence.wav"])
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    ogv = OUT_DIR / f"{spec['id']}.ogv"
    godot("--resolution", f"{SIZE[0]}x{SIZE[1]}", "--write-movie", ogv, "--fixed-fps", FPS,
          "-s", ROOT / "production/tools/ogv_writer.gd", "--", jpg, work / "silence.wav", log=work / "ogv.log")
    info = json.loads(run(["ffprobe", "-v", "error", "-show_entries", "format=duration:stream=width,height", "-of", "json", ogv]))
    length = float(info["format"]["duration"])
    video = [s for s in info["streams"] if s.get("width")]
    if not video or (video[0]["width"], video[0]["height"]) != SIZE or abs(length - spec["length_s"]) > .25:
        fail(f"{ogv.name}: unexpected encode {info}")
    shutil.rmtree(jpg)
    rows = -(-int(length) // 3)
    run(["ffmpeg", "-v", "error", "-y", "-i", ogv, "-vf", f"fps=1,scale=640:-1,tile=3x{rows}:padding=4:color=black",
         "-frames:v", 1, work / "sheet.jpg"])   # one still a second, for the frame-by-frame review
    register(spec, ogv, length)
    print(f"{ogv.relative_to(ROOT)}: {length:.2f} s, {ogv.stat().st_size / 1e6:.1f} MB; sheet {(work / 'sheet.jpg').relative_to(ROOT)}")


def register(spec, ogv, length):
    reg = json.loads(REGISTRY.read_text())
    entry = {
        "id": spec["id"], "kind": "how_to", "level": "method", "title": spec["title"],
        "path": "res://" + str(ogv.relative_to(ROOT / "game")), "length_s": round(length, 2),
        "labels": [], "sources": [], "used_by": spec.get("cards", []),
        "captions": [{"start": a, "end": b, "text": c} for a, b, c in spec["captions"]],
        "ends_on": spec["captions"][-1][2], "spec": str(Path(spec["_spec"]).relative_to(ROOT)),
    }
    reg["explainers"] = sorted([e for e in reg["explainers"] if e["id"] != spec["id"]] + [entry], key=lambda e: e["id"])
    reg["pending_render"] = [i for i in reg.get("pending_render", []) if i != spec["id"]]
    REGISTRY.write_text(json.dumps(reg, indent=1, ensure_ascii=False) + "\n")


def cmd_pending():
    """Lists every spec whose clip is not rendered yet, so the coverage test knows it is awaiting its render."""
    reg = json.loads(REGISTRY.read_text())
    rendered = {e["id"] for e in reg["explainers"] if e.get("kind") == "how_to"}
    reg["pending_render"] = sorted(p.stem for p in SPECS.glob("*.json") if p.stem not in rendered)
    REGISTRY.write_text(json.dumps(reg, indent=1, ensure_ascii=False) + "\n")
    print("pending render:", ", ".join(reg["pending_render"]) or "none")


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in ("check", "dump", "render", "pending"):
        fail(__doc__)
    if sys.argv[1] == "check":
        for p in sys.argv[2:] or sorted(SPECS.glob("*.json")):
            load(p)
            print(f"ok   {Path(p).name}")
    elif sys.argv[1] == "dump":
        cmd_dump(sys.argv[2])
    elif sys.argv[1] == "pending":
        cmd_pending()
    else:
        for p in (sorted(SPECS.glob("*.json")) if sys.argv[2:] == ["all"] else sys.argv[2:]):
            cmd_render(p)
