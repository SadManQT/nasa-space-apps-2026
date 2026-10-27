#!/usr/bin/env python3
"""Bake a uniformly scaled skeleton root into the joints, so a rigged GLB is in metres throughout.

  python3 tools/glb_unscale_armature.py <in.glb> <out.glb>

Meshy exports rigs as an "Armature" node scaled 0.01 with bones in centimetres. Skinning draws the right
size, but Godot sees the mesh 100x too small for bounds, and anything attached to a bone shrinks.
With root scale s: joint translations and their animation keys become s*t, inverse bind matrices become
diag(s,s,s,1)*IBM, and the root scale goes; the skinned result is unchanged.
"""
import json, struct, sys
import numpy as np

src, dst = sys.argv[1:3]
b = open(src, "rb").read()
jlen = struct.unpack_from("<I", b, 12)[0]
j = json.loads(b[20:20 + jlen])
bin_off = 20 + jlen + 8
data = bytearray(b[bin_off:bin_off + struct.unpack_from("<I", b, 20 + jlen)[0]])

skin = j["skins"][0]
joints = set(skin["joints"])
root = next(i for i in j["scenes"][0]["nodes"] if j["nodes"][i].get("scale"))
s = j["nodes"][root]["scale"][0]
assert all(abs(v - s) < 1e-6 for v in j["nodes"][root]["scale"]), "root scale must be uniform"

def view(acc_i, comps):
    acc = j["accessors"][acc_i]; bv = j["bufferViews"][acc["bufferView"]]
    assert acc["componentType"] == 5126 and bv.get("byteStride", comps * 4) == comps * 4
    off = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    return np.frombuffer(data, np.float32, acc["count"] * comps, off).reshape(acc["count"], comps), acc

done = set()
def scale_acc(acc_i, comps, rows=None):
    if acc_i in done: return
    done.add(acc_i)
    a, acc = view(acc_i, comps)
    a = a.copy()
    if rows is None:
        a *= s
    else:  # column-major MAT4: scale rows 0-2 of every matrix
        m = a.reshape(-1, 4, 4); m[:, :, :3] *= s; a = m.reshape(-1, 16)
    off = j["bufferViews"][acc["bufferView"]].get("byteOffset", 0) + acc.get("byteOffset", 0)
    data[off:off + a.nbytes] = a.astype(np.float32).tobytes()
    if "min" in acc and rows is None:
        acc["min"] = [v * s for v in acc["min"]]; acc["max"] = [v * s for v in acc["max"]]

for i in joints:
    if "translation" in j["nodes"][i]:
        j["nodes"][i]["translation"] = [v * s for v in j["nodes"][i]["translation"]]
scale_acc(skin["inverseBindMatrices"], 16, rows=True)
for anim in j.get("animations", []):
    for ch in anim["channels"]:
        if ch["target"]["path"] == "translation" and ch["target"].get("node") in joints:
            scale_acc(anim["samplers"][ch["sampler"]]["output"], 3)
del j["nodes"][root]["scale"]

js = json.dumps(j, separators=(",", ":")).encode()
js += b" " * (-len(js) % 4)
data += b"\0" * (-len(data) % 4)
out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(data))
out += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(data), 0x004E4942) + bytes(data)
open(dst, "wb").write(out)
print(f"unscaled root '{j['nodes'][root].get('name')}' (x{s}) in {src} -> {dst}: {len(done)} accessors")
