#!/usr/bin/env python3
"""Pick the best take of each voice line and master it for Godot.

    uv run --with soundfile --with mlx-whisper --with num2words \
        python production/tools/master_vo.py batch.json

batch.json is a list of {"line_id": "EX-CH01-S01-L01", "takes": [url_or_path, ...], "prompt": "..."}.
For every line (text, speaker, delivery and game path come from production/audio/vo_lines.csv):
  1. download each take, transcribe it with Whisper and score it against the script (word match);
  2. keep the best take as the dry master production/audio/vo_masters/VO_<line_id>.mp3;
  3. write the game file (voice_file column): silence trimmed to 120 ms, the delivery's post treatment
     (earth_link / radio band-pass, recording = aged recorder), two-pass loudness to -16 LUFS,
     mono 44.1 kHz Ogg Vorbis;
  4. write production/audio/vo_takes/<line_id>.json (scores, transcripts, chosen take, prompt).
Prints one line per line id; WARN when the best take's word match is under 0.85 (listen to it).
"""
import csv, difflib, json, re, subprocess, sys, tempfile, urllib.request
from pathlib import Path

import mlx_whisper
import soundfile as sf
from num2words import num2words

ROOT = Path(__file__).resolve().parents[2]
LINES = {r["line_id"]: r for r in csv.DictReader(open(ROOT / "production/audio/vo_lines.csv"))}
MASTERS, TAKES = ROOT / "production/audio/vo_masters", ROOT / "production/audio/vo_takes"
WHISPER = "mlx-community/whisper-small.en-mlx"
TRIM = "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.12"
TREATMENT = {  # same Earth-link chain as the v7 cutscene mixer (compose_cutscene.py)
    "live": "",
    "earth_link": "highpass=f=320,lowpass=f=3200,acompressor=threshold=0.2:ratio=4,",
    "radio": "highpass=f=450,lowpass=f=2800,acompressor=threshold=0.2:ratio=4,",
    "recording": "highpass=f=150,lowpass=f=5500,acompressor=threshold=0.25:ratio=3,",
}


def words(s):
    s = re.sub(r"\d+", lambda m: " " + num2words(int(m.group())) + " ", s.lower())
    return re.sub(r"[^a-z ]+", " ", s.replace("-", " ")).split()


def score(text, heard):
    return round(difflib.SequenceMatcher(None, words(text), words(heard)).ratio(), 3)


def ff(*args):
    return subprocess.run(["ffmpeg", "-v", "error", "-y", *args], capture_output=True, text=True, check=True)


def master(src, dst, delivery):
    pre = f"{TRIM},areverse,{TRIM},areverse,{TREATMENT[delivery]}"
    probe = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(src), "-af",
                            pre + "loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json", "-f", "null", "-"],
                           capture_output=True, text=True, check=True).stderr
    m = json.JSONDecoder().raw_decode(probe[probe.rindex("{"):])[0]  # ffmpeg prints more after the JSON
    norm = (f"loudnorm=I=-16:TP=-1.5:LRA=11:measured_I={m['input_i']}:measured_TP={m['input_tp']}:"
            f"measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:offset={m['target_offset']}:linear=true")
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "x.wav"
        if delivery == "recording":  # faint tape hiss under the aged recorder
            ff("-i", str(src), "-filter_complex",
               f"[0:a]{pre}{norm},aresample=44100[v];anoisesrc=c=pink:a=0.0025:r=44100[n];"
               "[v][n]amix=inputs=2:duration=first:normalize=0", "-ac", "1", "-c:a", "pcm_f32le", str(wav))
        else:
            ff("-i", str(src), "-af", pre + norm + ",aresample=44100", "-ac", "1", "-c:a", "pcm_f32le", str(wav))
        data, rate = sf.read(wav)
        dst.parent.mkdir(parents=True, exist_ok=True)
        sf.write(dst, data, rate, format="OGG", subtype="VORBIS", compression_level=0.2)  # ~q8 Vorbis
    return round(len(data) / rate, 2)


def main(batch):
    MASTERS.mkdir(parents=True, exist_ok=True)
    TAKES.mkdir(parents=True, exist_ok=True)
    for job in json.load(open(batch)):
        lid, row = job["line_id"], LINES[job["line_id"]]
        if row["delivery"] == "text":
            print(f"{lid} SKIP text-only line"); continue
        with tempfile.TemporaryDirectory() as tmp:
            takes = []
            for i, src in enumerate(job["takes"], 1):
                local = Path(tmp) / f"t{i}.mp3"
                if src.startswith("http"):
                    urllib.request.urlretrieve(src, local)
                else:
                    local.write_bytes((ROOT / src if not Path(src).is_absolute() else Path(src)).read_bytes())
                heard = mlx_whisper.transcribe(str(local), path_or_hf_repo=WHISPER)["text"].strip()
                takes.append({"take": i, "source": src.split("?")[0], "heard": heard,
                              "score": score(row["text"], heard), "file": local})
            best = max(takes, key=lambda t: t["score"])  # ties keep the first take
            dry = MASTERS / f"VO_{lid}.mp3"
            dry.write_bytes(best["file"].read_bytes())
            secs = master(dry, ROOT / row["voice_file"], row["delivery"])
        for t in takes:
            t.pop("file")
        (TAKES / f"{lid}.json").write_text(json.dumps({
            "line_id": lid, "speaker": row["speaker"], "text": row["text"], "delivery": row["delivery"],
            "prompt": job.get("prompt", ""), "chosen_take": best["take"], "seconds": secs, "takes": takes,
            "dry_master": str(dry.relative_to(ROOT)), "game_file": row["voice_file"]}, indent=1) + "\n")
        flag = "" if best["score"] >= 0.85 else f"  WARN heard: {best['heard']!r}"
        print(f"{lid} take{best['take']} match={best['score']} {secs}s -> {row['voice_file']}{flag}")


if __name__ == "__main__":
    main(sys.argv[1])
