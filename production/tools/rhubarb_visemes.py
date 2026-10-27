#!/usr/bin/env python3
"""Turn a voice line into lip-sync cues for the characters' viseme blend shapes, using Rhubarb Lip Sync.

  python3 tools/rhubarb_visemes.py <line.wav|mp3|ogg> <out.json> [--text "the spoken line"]

Rhubarb (~/.local/bin/rhubarb, v1.14) gives timed mouth shapes A-H and X; each is mapped to the viseme
blend shapes added by add_mouth_rig.py. Passing the line's text improves the timing. Output, read by
game/scripts/lip_sync.gd:
  {"duration": 2.88, "cues": [{"t": 0.06, "shape": "viseme_E", "weight": 1.0}, ...]}
"""
import argparse, json, math, os, struct, subprocess, tempfile

RHUBARB = os.path.expanduser("~/.local/bin/rhubarb")
SHAPES = {  # Rhubarb mouth shape -> (viseme blend shape, weight)
    "X": ("viseme_sil", 0.0),   # rest
    "A": ("viseme_PP", 1.0),    # closed: M, B, P
    "B": ("viseme_SS", 1.0),    # slightly open, teeth together: K, S, T, EE
    "C": ("viseme_E", 1.0),     # open: EH, AE
    "D": ("viseme_aa", 1.0),    # wide open: AA
    "E": ("viseme_O", 0.8),     # slightly rounded: AO, ER
    "F": ("viseme_U", 1.0),     # puckered: UW, OW, W
    "G": ("viseme_FF", 1.0),    # upper teeth on lower lip: F, V
    "H": ("viseme_nn", 1.0),    # tongue up: L
}

def _decode_pcm(audio):
    process = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", audio, "-f", "s16le", "-ar", "16000", "-ac", "1", "pipe:1"],
        check=True, stdout=subprocess.PIPE,
    )
    return process.stdout


def _percentile(values, percentile):
    if not values:
        return 0.0
    position = (len(values) - 1) * percentile
    lower = int(position)
    upper = min(lower + 1, len(values) - 1)
    fraction = position - lower
    return values[lower] + (values[upper] - values[lower]) * fraction


def rms_envelope(pcm, sample_rate=16000):
    frame_size = sample_rate // 100
    samples = struct.unpack("<%dh" % (len(pcm) // 2), pcm[: len(pcm) - (len(pcm) % 2)])
    raw = []
    for start in range(0, len(samples), frame_size):
        frame = samples[start : start + frame_size]
        if not frame:
            continue
        raw.append(math.sqrt(sum(sample * sample for sample in frame) / len(frame)) / 32768.0)
    if not raw:
        return []
    smoothed = []
    for index in range(len(raw)):
        first = max(0, index - 1)
        last = min(len(raw), index + 2)
        smoothed.append(sum(raw[first:last]) / (last - first))
    scale = _percentile(sorted(smoothed), 0.95)
    if scale <= 1e-12:
        return [0.0 for _value in smoothed]
    return [round(min(1.0, value / scale), 3) for value in smoothed]


def _selftest():
    quiet = [0] * 160
    loud = [12000] * 320
    pcm = struct.pack("<%dh" % len(quiet + loud), *(quiet + loud))
    envelope = rms_envelope(pcm)
    assert len(envelope) == 3, envelope
    assert envelope[0] < envelope[-1], envelope
    assert all(0.0 <= value <= 1.0 for value in envelope), envelope
    assert all(round(value, 3) == value for value in envelope), envelope
    print("PASS rhubarb_visemes selftest")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("audio", nargs="?")
    parser.add_argument("out", nargs="?")
    parser.add_argument("--text")
    parser.add_argument("--selftest", action="store_true")
    args = parser.parse_args()
    if args.selftest:
        _selftest()
        return
    if not args.audio or not args.out:
        parser.error("audio and out are required unless --selftest is used")
    tmp = tempfile.mkdtemp()
    wav = os.path.join(tmp, "line.wav")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", args.audio, "-ar", "16000", "-ac", "1", wav], check=True)
    cmd = [RHUBARB, "-q", "-f", "json", "--extendedShapes", "GHX", "-o", os.path.join(tmp, "cues.json")]
    if args.text:
        with open(os.path.join(tmp, "line.txt"), "w") as text_file:
            text_file.write(args.text)
        cmd += ["-d", os.path.join(tmp, "line.txt")]
    subprocess.run(cmd + [wav], check=True)
    with open(os.path.join(tmp, "cues.json")) as cues_file:
        result = json.load(cues_file)
    cues = [{"t": round(c["start"], 3), "shape": SHAPES[c["value"]][0], "weight": SHAPES[c["value"]][1]} for c in result["mouthCues"]]
    envelope = rms_envelope(_decode_pcm(args.audio))
    with open(args.out, "w") as output_file:
        json.dump({"duration": result["metadata"]["duration"], "cues": cues, "env": envelope}, output_file, indent=1)
    print(f"{args.out}: {len(cues)} cues over {result['metadata']['duration']:.2f} s")


if __name__ == "__main__":
    main()
