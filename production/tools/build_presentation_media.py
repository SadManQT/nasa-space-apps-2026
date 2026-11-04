"""Refresh game/resources/campaign/content/presentation_media.json from the files actually present (M1-10, M1-11).

Computed here, never typed by hand:
- cutscenes: media_present/status from game/assets/cutscenes, caption_cues (when each scene line is spoken)
  from the cutscene specs in production/cutscenes/v7/src and v8/src, matched to catalog line ids by text;
- audio: presence flags, file lists and counts from game/assets/audio; music cues and their scenes from
  production/audio/music_cues.csv; effects, loops and captions from production/audio/sfx_list.csv; every
  loop flag is read from the file's .import (the flag Godot actually uses).
Hand-authored design keys (cutscene trigger, mix, room_beds, scene_beds, scene_sfx, operation_sfx, line_sfx,
ui_sfx, music_variant_by_scene, cutscene_controls) are kept exactly as they are in the JSON.

Run from the repository root:  python3 -I production/tools/build_presentation_media.py [--check]
--check exits 1 if the JSON on disk differs from what the files say (nothing is written).
"""
import csv, json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / "game"
OUT = GAME / "resources/campaign/content/presentation_media.json"
CATALOG = json.loads((GAME / "resources/campaign/content/campaign_catalog.json").read_text())
SPEC_DIRS = [ROOT / "production/cutscenes/v8/src", ROOT / "production/cutscenes/v7/src"]   # the newest edition of a cutscene wins


def res(path):
    """'game/x' or 'res://x' -> 'res://x'."""
    return path if path.startswith("res://") else "res://" + path.removeprefix("game/")


def present(res_path):
    return (GAME / res_path.removeprefix("res://")).is_file()


def import_loop(res_path):
    imp = GAME / (res_path.removeprefix("res://") + ".import")
    match = re.search(r"^loop=(\w+)", imp.read_text(), re.M) if imp.is_file() else None
    return bool(match) and match.group(1) == "true"


def scene_list(text):
    """'EX-CH01-S06..S09, EX-CH08-S05' -> ['EX-CH01-S06', ..., 'EX-CH01-S09', 'EX-CH08-S05']."""
    result = []
    for item in [part.strip() for part in text.split(",") if part.strip()]:
        match = re.fullmatch(r"(EX-CH\d\d-S)(\d\d)(?:\.\.S(\d\d))?", item)
        if not match:
            raise SystemExit(f"unreadable scene range: {item!r}")
        first = int(match.group(2))
        last = int(match.group(3) or first)
        result += [f"{match.group(1)}{n:02d}" for n in range(first, last + 1)]
    return result


def norm(text):
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


def caption_cues(cutscene_id, scene_id):
    spec = next((d / f"{cutscene_id}.json" for d in SPEC_DIRS if (d / f"{cutscene_id}.json").is_file()), None)
    if spec is None:
        return []
    by_text = {norm(l["text"]): l["id"] for l in CATALOG["dialogue"] if l["scene_id"] == scene_id}
    cues = []
    for line in json.loads(spec.read_text()).get("lines", []):
        line_id = by_text.get(norm(line["text"]))
        if line_id is None:
            raise SystemExit(f"{cutscene_id}: spec line not in {scene_id}: {line['text']!r}")
        cues.append({"at": round(float(line["at"]), 3), "line_id": line_id})
    return cues


def build(current):
    media = json.loads(json.dumps(current))
    for item in media["available_cutscenes"]:
        item["media_present"] = present(item["runtime_path"])
        item["status"] = "present" if item["media_present"] else "missing"
        item.setdefault("trigger", "scene_enter")
        item["caption_cues"] = caption_cues(item["id"], item["scene_id"])
    media["not_installed_cutscene_ids"] = [i["id"] for i in media["available_cutscenes"] if not i["media_present"]]

    voice_lines = [l for l in CATALOG["dialogue"] if l.get("voice_file")]
    voice_present = [l for l in voice_lines if present(res(l["voice_file"]))]
    cues, music_files = [], []
    with open(ROOT / "production/audio/music_cues.csv", newline="") as handle:
        rows = list(csv.DictReader(handle))
        for row in rows:
            game_file = row["game_file"]
            variants = {}
            stems = re.search(r"\{([^}]+)\}", game_file)
            if stems:
                for stem in stems.group(1).split("|"):
                    variants[stem] = res(game_file.replace(stems.group(0), stem))
                path = variants.get("mid") or next(iter(variants.values()))
            else:
                path = res(game_file)
            extra = dict(re.findall(r"(sting|credits) file (\S+\.ogg)", row["elevenlabs_ids"]))
            cue = {"id": row["cue"], "title": row["title"], "runtime_path": path, "loop": import_loop(path),
                   "media_present": present(path), "scenes": scene_list(row["final_scenes"])}
            if variants:
                cue["variants"] = variants
            for kind, name in extra.items():
                cue[f"{kind}_path"] = f"res://assets/audio/music/{name}"
            sting_scene = re.search(r"sting at (EX-CH\d\d-S\d\d)", row["entry_exit"])
            if sting_scene:
                cue["sting_scene"] = sting_scene.group(1)
            for p in [path, *variants.values(), *[cue.get(k) for k in ("sting_path", "credits_path") if cue.get(k)]]:
                if present(p) and p not in music_files:
                    music_files.append(p)
            cues.append(cue)
    # A scene named on its own beats one covered by another cue's range (CUE-03 at EX-CH08-S05 inside CUE-10's S01..S06).
    by_scene, explicit = {}, {}
    for cue, row in zip(cues, rows):
        singles = {item.strip() for item in row["final_scenes"].split(",") if ".." not in item}
        for scene in cue["scenes"]:
            if scene in by_scene and explicit[scene] and scene in singles:
                raise SystemExit(f"{scene} is named by both {by_scene[scene]} and {cue['id']}")
            if scene not in by_scene or (scene in singles and not explicit[scene]):
                by_scene[scene], explicit[scene] = cue["id"], scene in singles
    effects = []
    with open(ROOT / "production/audio/sfx_list.csv", newline="") as handle:
        for row in csv.DictReader(handle):
            path = res(row["game_file"])
            loop = import_loop(path)
            if loop != (row["loop"] == "yes"):
                raise SystemExit(f"{row['id']}: .import loop={loop} but sfx_list.csv says loop={row['loop']}")
            effects.append({"id": row["id"], "runtime_path": path, "media_present": present(path), "loop": loop,
                            "caption": row["caption"], "bus": "UI" if row["id"].startswith("SFX_UI_") else "SFX",
                            "first_scenes": [] if row["first_scenes"] == "all" else scene_list(row["first_scenes"])})
    audio = media.setdefault("audio", {})
    audio.update({
        "voice_runtime_files_present": len(voice_present) > 0,
        "voice_lines_total": len(CATALOG["dialogue"]),
        "voice_lines_with_file": len(voice_lines),
        "voice_files_present": len(voice_present),
        "music_runtime_files_present": len(music_files) > 0,
        "music_runtime_files": music_files,
        "sfx_runtime_files_present": any(e["media_present"] for e in effects),
        "sfx_runtime_files": [e["runtime_path"] for e in effects if e["media_present"]],
        "music_cues": cues,
        "music_by_scene": dict(sorted(by_scene.items())),
        "sfx": effects,
        "fallback_mode": "captions_only",
        "source": "production/audio/vo_lines.csv, music_cues.csv, sfx_list.csv",
        "note": "Generated by production/tools/build_presentation_media.py from the files actually present. "
                "A missing voice, music or effect file falls back to its exact caption text.",
    })
    return media


def main():
    current = json.loads(OUT.read_text())
    result = build(current)
    text = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    audio = result["audio"]
    print(f"cutscenes {sum(i['media_present'] for i in result['available_cutscenes'])}/{len(result['available_cutscenes'])}, "
          f"voice {audio['voice_files_present']}/{audio['voice_lines_with_file']} ({audio['voice_lines_total']} lines), "
          f"music files {len(audio['music_runtime_files'])}, effects {len(audio['sfx_runtime_files'])}/{len(audio['sfx'])}, "
          f"looping effects {sum(e['loop'] for e in audio['sfx'])}")
    if "--check" in sys.argv:
        same = text == OUT.read_text()
        print("presentation_media.json is current" if same else "presentation_media.json is STALE: rerun without --check")
        sys.exit(0 if same else 1)
    OUT.write_text(text)


if __name__ == "__main__":
    main()
