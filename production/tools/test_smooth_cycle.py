"""Check retarget_clips.smooth_cycle on a sine swing: a closed loop keeps equal ends, the swing keeps ~97.6 % of its peak.

  blender -b --python-exit-code 1 -P test_smooth_cycle.py
"""
import math, os
from mathutils import Quaternion, Vector
src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "retarget_clips.py")).read()
fn = src[src.index("def smooth_cycle(frames):"):src.index("# hands per clip (left, right):")]
P = "mixamorig:"; ARM_CHAIN = ["b"]
exec(fn)
for closed in (True, False):
    n = 21 if closed else 20
    angs = [10 * math.sin(2 * math.pi * i / 20) for i in range(n)]
    frames = [{"b": (Quaternion(Vector((0, 0, 1)), math.radians(a)), None)} for a in angs]
    smooth_cycle(frames)
    out = [math.degrees(fr["b"][0].angle) * (1 if fr["b"][0].axis.z > 0 else -1) for fr in frames]
    print("closed" if closed else "open  ", "ends", round(out[0], 3), round(out[-1], 3), "peak", round(max(out), 2), "of 10")
    assert abs(max(out) - 10 * (1 + math.cos(2 * math.pi / 20)) / 2) < 0.05
    if closed: assert abs(out[0] - out[-1]) < 1e-6
print("SMOOTH OK")
