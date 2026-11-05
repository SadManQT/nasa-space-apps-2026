"""Verify M3-97's rendered masters; --runtime also checks the window-encoded OGVs (frames and audio).

Run sequentially through production/tools/heavy.py. Writes master-frame evidence and a blink strip;
the separate M3-97_capture.sh captures the actual campaign player with its window on top.
--stale prints only the names of runtime films whose picture or sound no longer matches the master
(M3-97_capture.sh re-encodes just those, so an audio-only fix such as M4-02's lamp tick is not missed).
"""
import argparse
import csv
import json
import re
import subprocess
from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[4]
SRC = Path(__file__).resolve().parent
EVIDENCE = ROOT / "production/qa/evidence"
FPS = 24
RATE = 48000   # decode rate for every audio check
FILMS = {
    "CS-15": ("CS-15_Hello_Aurora", 29.75, [5.041667, 13.708333, 18.75]),
    "CS-17": ("CS-17_What_We_Grew", 30.708333, [6.041667, 22.625]),
    "CS-18": ("CS-18_The_Closed_Drawer", 8.0, []),
}
KEYS = {
    "CS-15": [(2.2, "rao_channel"), (6.0, "pause"), (8.5, "noor_live"), (19.5, "noor_reply"), (29.0, "return")],
    "CS-17": [(15.5, "tara_lineage"), (27.5, "five_named_mugs")],
    "CS-18": [(2.0, "hold"), (92 / FPS, "blink"), (7.5, "black")],
}


def check(condition, message):
    """Fail immediately with a useful proof label; never infer success from a tool exit alone."""
    if not condition:
        raise AssertionError(message)
    print("PASS", message, flush=True)


def duration(path):
    """Return the video stream's duration, avoiding audio padding in container duration."""
    return float(subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=duration", "-of", "csv=p=0", str(path)
    ]))


def frame(path, seconds):
    """Decode one BGR frame at a timestamp for evidence and runtime comparisons."""
    if path.suffix == ".ogv":
        # Theora's held frames are sparse in the decoder. Fill their timeline before sampling by time.
        # Carry the last coded frame through a sparse terminal hold as the real player does.
        filters = f"fps=24,tpad=stop_mode=clone:stop_duration={duration(path):.6f}"
        png = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(path), "-ss", str(seconds),
            "-vf", filters, "-frames:v", "1", "-c:v", "png", "-f", "image2pipe", "-"])
        if not png:
            raise AssertionError(f"missing runtime frame {path} at {seconds}")
        picture = cv2.imdecode(np.frombuffer(png, np.uint8), cv2.IMREAD_COLOR)
        if picture is None:
            raise AssertionError(f"missing runtime frame {path} at {seconds}")
        return picture
    clip = cv2.VideoCapture(str(path))
    clip.set(cv2.CAP_PROP_POS_MSEC, seconds * 1000)
    ok, picture = clip.read()
    clip.release()
    if not ok:
        raise AssertionError(f"missing frame {path} at {seconds}")
    return picture


def samples(path, start, end):
    """Decode a bounded stereo audio window for a numerical silence check."""
    raw = subprocess.check_output([
        "ffmpeg", "-v", "error", "-i", str(path), "-ss", str(start), "-t", str(end - start),
        "-vn", "-ar", "48000", "-ac", "2", "-f", "f32le", "-"
    ])
    return np.frombuffer(raw, np.float32)


def mono(path):
    """Decode a film's whole audio track as 48 kHz mono for timing and parity checks."""
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(path), "-vn", "-ac", "1", "-ar", str(RATE), "-f", "f32le", "-"])
    return np.frombuffer(raw, np.float32)


def envelope_db(signal, window=0.05):
    """RMS level of each consecutive `window`-second block (50 ms by default), in dBFS."""
    size = int(RATE * window)
    count = len(signal) // size
    return 20 * np.log10(np.sqrt((signal[:count * size].reshape(count, size) ** 2).mean(axis=1)) + 1e-9)


def clicks(signal, start, end):
    """Onsets (s) of clicks: 1 ms high-passed energy 20 dB above the window's median after 50 ms of quiet.

    A click's own decaying ring stays one event; a second relay tick or a double trigger would be two.
    """
    segment = signal[int(start * RATE):int(end * RATE)]
    energy = np.sqrt(np.convolve(np.diff(segment, prepend=segment[:1]) ** 2, np.ones(48) / 48, "same"))
    quiet, onsets, last = int(0.05 * RATE), [], None
    for index in np.flatnonzero(energy > 10 * np.median(energy)):
        if last is None or index - last > quiet:
            onsets.append(start + index / RATE)
        last = index
    return onsets


def runtime_parity(key, name, expected_length, master):
    """Yield (ok, proof) pairs comparing the game's Theora film with its master: clock, key frames and sound."""
    ogv = ROOT / f"game/assets/cutscenes/{name}.ogv"
    # Held/duplicate Theora frames are not all returned by -count_frames; validate the stream's clock.
    probe = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "stream=duration,r_frame_rate,codec_name", "-of", "json", str(ogv)]))["streams"][0]
    yield (probe["codec_name"] == "theora" and probe["r_frame_rate"] == "24/1"
           and abs(float(probe["duration"]) - expected_length) < 0.001,
           f"{key} runtime Theora covers the complete 24 fps timeline")
    for at, label in KEYS[key]:
        actual = frame(ogv, at)
        reference = cv2.resize(frame(master, at), (actual.shape[1], actual.shape[0]))
        error = float(np.abs(actual.astype(float) - reference).mean())
        yield error < 16, f"{key} runtime/master frame {label}: mean error {error:.3f}"
    # Vorbis against AAC differs by at most ~1.2 dB per 50 ms window on matching films; a missing or
    # moved cue (the old silent lamp slot against the M4-02 master: 12.7 dB) is far outside that.
    runtime_level, master_level = envelope_db(mono(ogv)), envelope_db(mono(master))
    count = min(len(runtime_level), len(master_level))
    audible = np.maximum(runtime_level[:count], master_level[:count]) > -60
    drift = float(np.abs(runtime_level[:count] - master_level[:count])[audible].max()) if audible.any() else 0.0
    yield drift < 3.0, f"{key} runtime/master sound: largest 50 ms level difference {drift:.2f} dB"


def stale_films():
    """Print the runtime films whose picture or sound no longer matches the master (nothing else on stdout)."""
    for key, (name, expected_length, _) in FILMS.items():
        try:
            stale = not all(ok for ok, _ in runtime_parity(key, name, expected_length, SRC.parent / f"{name}.mp4"))
        except (AssertionError, subprocess.CalledProcessError, KeyError, IndexError, ValueError, cv2.error):
            stale = True   # a missing, truncated or undecodable runtime film is stale too
        if stale:
            print(name, flush=True)


def main(runtime=False):
    """Check exact canon captions, timing, scdet cuts, source blink, silence, and optional OGV parity."""
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    with (ROOT / "production/audio/vo_lines.csv").open() as handle:
        canon = {(row["scene"], row["speaker"], row["text"]) for row in csv.DictReader(handle)}
    specs = {key: json.loads((SRC / f"{key}.json").read_text()) for key in FILMS}
    for key, scene in [("CS-15", "EX-CH08-S10"), ("CS-17", "EX-CH08-S12")]:
        for line in specs[key]["lines"]:
            check((scene, line["speaker"], line["text"]) in canon, f"{key} exact canon: {line['text']}")
    lines = specs["CS-15"]["lines"]
    check(specs["CS-15"]["transitions"] == ["cut"] * 3, "CS-15 picture changes are hard cuts")
    check(abs(lines[1]["at"] - 5.041667 - 2.6) < 1e-6, "CS-15 2.600 s hold begins at cut into B")
    noor_end = lines[1]["at"] + 3.92
    check(specs["CS-15"]["music_at"] >= noor_end + 1.5, "CUE-11 gives Noor's first words 1.5 s of room")
    check(abs(lines[3]["at"] - (lines[2]["at"] + 2.08) - 2.6) < 1e-6, "Mei's reply waits another 2.600 s round trip")
    check([line["recording_task"] for line in lines if not line.get("file")] == ["M3-94R", "M3-94R"],
          "approved Rao/Noor lines are caption-only pending M3-94R")
    spans = [(b["at"], b["until"]) for b in specs["CS-15"]["beds"]]
    check(all(abs(a[1] - b[0]) < 1e-6 for a, b in zip(spans, spans[1:])), "ambience beds never overlap across pictures")
    dhaka, tick = specs["CS-15"]["beds"][1], specs["CS-18"]["sfx"][0]
    check(dhaka["file"].endswith("SFX_DHAKA_ROOFTOP_MORNING.ogg")
          and bool(dhaka.get("pending")) == any(not line.get("file") for line in lines),
          "CS-15 Dhaka bed goes in with M3-94R's Rao/Noor recordings, so the film is encoded once (M4-02)")
    check(tick["file"].endswith("SFX_INVENTORY_LAMP_TICK.ogg") and not tick.get("pending")
          and (SRC / tick["file"]).resolve().is_file(), "CS-18 inventory lamp tick is installed (M4-02)")
    labels = [json.loads((SRC / "labels" / f"CS-17-{letter}.json").read_text()) for letter in "CD"]
    check([label["text"] for label in labels[0]["labels"]] == ["TARA", "Alo × Tara"], "Tara and parent lineage are named")
    check([label["text"] for label in labels[1]["labels"]] == ["KAI", "AMARA", "MEI", "RAFI", "FERREIRA"], "five named mugs")
    for key, (name, expected_length, expected_cuts) in FILMS.items():
        master = SRC.parent / f"{name}.mp4"
        check(abs(duration(master) - expected_length) < 0.001, f"{key} video duration {expected_length:.6f} s")
        audio_length = float(subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "a:0",
            "-show_entries", "stream=duration", "-of", "csv=p=0", str(master)]))
        check(abs(audio_length - expected_length) < 0.06, f"{key} mixed audio covers the whole film ({audio_length:.6f} s)")
        scan = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(master), "-vf", "scdet=threshold=12", "-an", "-f", "null", "-"],
                              capture_output=True, text=True, check=True)
        cuts = [float(value) for value in re.findall(r"lavfi\.scd\.time: ([0-9.]+)", scan.stderr)]
        # Drop ffmpeg's filter address ("@ 0x...") so the evidence only changes when the cuts do.
        (EVIDENCE / f"M3-97_{key}_scdet.txt").write_text("\n".join(
            re.sub(r" @ 0x[0-9a-f]+", "", row) for row in scan.stderr.splitlines() if "scdet" in row) + "\n")
        check(len(cuts) == len(expected_cuts) and all(abs(a - b) < 1 / FPS for a, b in zip(cuts, expected_cuts)),
              f"{key} scdet only planned cuts: {cuts}")
        for at, label in KEYS[key]:
            picture = frame(master, at)
            check(cv2.imwrite(str(EVIDENCE / f"M3-97_{key.replace('-', '')}_{label}.png"), picture), f"{key} master evidence {label}")
        if runtime:
            for ok, proof in runtime_parity(key, name, expected_length, master):
                check(ok, proof)
    silent = samples(SRC.parent / "CS-15_Hello_Aurora.mp4", 5.2, 7.5)
    check(silent.size > 0 and float(np.abs(silent).max()) < 1e-5, "CS-15 open-channel pause is digital silence (no music/cabin bleed)")
    source = SRC / "shots/CS-18-A_blink.mp4"
    signal = np.array([frame(source, k / FPS)[356:365, 902:910].mean() for k in range(88, 98)])
    raised = (np.where(signal > np.median(signal) + 5)[0] + 88).tolist()
    check(raised == [91, 92, 93, 94], f"inventory lamp rises on exactly four frames: {raised}")
    strip = np.hstack([cv2.resize(frame(source, k / FPS)[310:410, 850:960], (220, 200)) for k in range(89, 97)])
    cv2.imwrite(str(EVIDENCE / "M3-97_CS18_blink_frames89-96.png"), strip)
    # The relay tick sounds once and lands on the first lit frame of the blink (doc 24 section 7.7 beat 2).
    first_lit = (raised[0] / FPS, (raised[0] + 1) / FPS)
    films = [("master", SRC.parent / "CS-18_The_Closed_Drawer.mp4")]
    films += [("runtime", ROOT / "game/assets/cutscenes/CS-18_The_Closed_Drawer.ogv")] if runtime else []
    for label, film in films:
        sound = mono(film)
        onsets = [round(float(at), 4) for at in clicks(sound, 0.9, 6.9)]   # inside the fade-in and the bed's fade-out
        check(len(onsets) == 1 and first_lit[0] <= onsets[0] < first_lit[1],
              f"CS-18 {label}: one lamp tick at {onsets} s, on blink frame {raised[0]} "
              f"({first_lit[0]:.4f}-{first_lit[1]:.4f} s)")
        bed = envelope_db(sound[int(2.0 * RATE):int(3.5 * RATE)], 0.1)
        tick = envelope_db(sound[int(onsets[0] * RATE):int((onsets[0] + 0.1) * RATE)], 0.1)[0]
        peak = 20 * np.log10(float(np.abs(sound).max()))
        check(tick - np.median(bed) >= 6 and peak < -1,
              f"CS-18 {label}: tick {tick - np.median(bed):.1f} dB over the fan bed (100 ms), film peak {peak:.1f} dBFS")
    black = frame(SRC.parent / "CS-18_The_Closed_Drawer.mp4", 7.5)
    check(float(black.max()) <= 2, "CS-18 ends on black")
    tail = samples(SRC.parent / "CS-18_The_Closed_Drawer.mp4", 7.1, 7.9)
    check(tail.size > 0 and float(np.abs(tail).max()) < 1e-5, "CS-18 black tail is silent")
    print("M3-97 STAGING RESULT: PASS" + (" (masters + runtime)" if runtime else " (masters; windowed runtime capture deferred)"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", action="store_true")
    parser.add_argument("--stale", action="store_true", help="list runtime films that need re-encoding, then exit")
    arguments = parser.parse_args()
    if arguments.stale:
        stale_films()
    else:
        main(arguments.runtime)
