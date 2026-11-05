"""Blink the inventory lamp once on the CS-18 still (doc 24 §7.7, M3-97).

  python3 production/tools/heavy.py python3 production/cutscenes/v8/src/lamp_blink.py <spec>
  (paths in the JSON are relative to its folder)

The accepted CS-18-A shot is a locked-off still, so the lamp sits at one pixel position for the whole shot. The
shot is held on its last frame out to "duration", and on the frames from "at" the lamp flares once: one value of
"curve" per frame (four frames at 24 fps, about 0.17 s), each the strength of a hot core, a warm halo and a wide
bounce on the cabinet, screen-blended over the frame so the lamp's own bezel and line art stay visible.

blink json: {"in": mp4, "out": mp4, "duration": 8.0, "lamp": [x, y], "at": 3.8, "curve": [0.55, 1.0, 0.7, 0.3],
             "core": 4.0, "halo": 16.0, "bounce": 55.0, "halo_gain": 0.6, "bounce_gain": 0.16}
             (radii are Gaussian sigmas in pixels; gains scale the halo and bounce against the core)
"""
import json, os, subprocess, sys
import numpy as np


def gauss(w, h, cx, cy, sigma):
    """A unit-peak radial Gaussian centred on the lamp."""
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    return np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (2 * sigma * sigma))[..., None]


def main(path):
    """Hold the accepted still and composite the configured four-frame lamp flare."""
    base = os.path.dirname(os.path.abspath(path))
    spec = json.load(open(path))
    rel = lambda p: p if os.path.isabs(p) else os.path.join(base, p)
    src, out = rel(spec["in"]), rel(spec["out"])
    w, h, rate = subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v", "-show_entries",
                                          "stream=width,height,r_frame_rate", "-of", "csv=p=0", src]).decode().strip().split(",")
    w, h = int(w), int(h)
    fps = float(rate.split("/")[0]) / float(rate.split("/")[1])
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", src, "-vf", "format=rgb24", "-f", "rawvideo", "-"])
    clip = np.frombuffer(raw, np.uint8).reshape(-1, h, w, 3)
    total = int(round(spec["duration"] * fps))
    cx, cy = spec["lamp"]
    glow = (gauss(w, h, cx, cy, spec.get("core", 4.0)) * np.float32([1.0, 0.95, 0.82])            # white-hot lens
            + gauss(w, h, cx, cy, spec.get("halo", 16.0)) * np.float32([1.0, 0.62, 0.25]) * spec.get("halo_gain", 0.6)   # warm halo
            + gauss(w, h, cx, cy, spec.get("bounce", 55.0)) * np.float32([1.0, 0.6, 0.3]) * spec.get("bounce_gain", 0.16))  # light on the cabinet
    first = int(round(spec["at"] * fps))
    enc = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{w}x{h}",
                            "-r", rate, "-i", "-", "-c:v", "libx264", "-preset", "slow", "-crf", "12", "-pix_fmt", "yuv420p",
                            "-movflags", "+faststart", out], stdin=subprocess.PIPE)
    for k in range(total):
        frame = clip[min(k, len(clip) - 1)]
        i = k - first
        if 0 <= i < len(spec["curve"]):
            f = frame.astype(np.float32) / 255.0
            g = np.clip(glow * spec["curve"][i], 0, 1)
            frame = ((1 - (1 - f) * (1 - g)) * 255 + 0.5).astype(np.uint8)   # screen blend
        enc.stdin.write(frame.tobytes())
    enc.stdin.close()
    if enc.wait() != 0:
        raise RuntimeError("lamp blink encode failed")
    print(f"BLINK {os.path.basename(out)}: {total} frames ({total / fps:.2f} s), lamp flare on frames {first}-{first + len(spec['curve']) - 1}")


if __name__ == "__main__":
    main(sys.argv[1])
