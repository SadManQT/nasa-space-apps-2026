#!/bin/bash
# Full v7 character build, from the Tripo rig and the Meshy clips to the finished GLB in production/models/v7 and final:
# body and clips -> anime face layers -> crisp sleeve patches -> (Mei) ponytail bones -> hold poses.
#   tools/finish_character_v7.sh <name lower-case> <height_m> <work_dir>
# work_dir holds prep/<name>.glb, trig/<name>/model_url.glb, mrig/<name>/, clips/<name>/ and facekit/<name>/
# (see HANDOFF.md, "READ THIS FIRST"). Run production/tools/sync_to_godot.sh afterwards.
set -e
n=$1; h=$2; W=$3
N=CH_$(python3 -c "print('$n'.capitalize())")
T=$(cd "$(dirname "$0")" && pwd); R=$(cd "$T/../.." && pwd); B="/opt/homebrew/bin/blender --python-exit-code 1"   # a failed step stops the build
out=$W/build/$N; mkdir -p "$out" "$R/production/models/v7/$N" "$R/production/models/final/$N"
if [ -z "$SKIP_BODY" ] || [ ! -f "$out/${N}_body.glb" ]; then   # SKIP_BODY=1 reuses the retargeted body
  "$T/build_character_v7.sh" "$N" "$h" "$W/trig/$n/model_url.glb" "$W/mrig/$n" "$W/clips/$n" "$out" | grep -E "^BODY|error ([1-9])" || true
fi
$B -b -P "$T/add_toon_face.py" -- "$out/${N}_body.glb" "$W/prep/$n.glb" "$W/facekit/$n" "$out/${N}_face.glb" > "$out/face.log" 2>&1
$B -b -P "$T/add_patches.py" -- "$out/${N}_face.glb" "$R/production/concept/patches" "$out/${N}_patched.glb" > "$out/patches.log" 2>&1
grep -E "^(PATCH|PAINT)" "$out/patches.log" || true
final="$out/${N}_patched.glb"
if [ "$n" = mei ]; then
  $B -b -P "$T/add_ponytail_bones.py" -- "$final" "$out/${N}_ponytail.glb" --ztop 1.56 --zbottom 1.10 --ztie 1.42 --xmax 0.11 > "$out/ponytail.log" 2>&1
  final="$out/${N}_ponytail.glb"; grep -E "PONYTAIL (vertices|DONE)" "$out/ponytail.log" || true
fi
$B -b -P "$T/add_hold_poses.py" -- "$final" "$out/${N}_holds.glb" > "$out/holds.log" 2>&1
final="$out/${N}_holds.glb"; grep -E "^POSE|HOLD POSES DONE" "$out/holds.log" || true
cp "$final" "$R/production/models/v7/$N/$N.glb"; cp "$final" "$R/production/models/final/$N/$N.glb"
python3 - "$final" <<'PY'
import json, struct, sys
b = open(sys.argv[1], "rb").read(); n = struct.unpack("<I", b[12:16])[0]; j = json.loads(b[20:20 + n])
print("FINAL", sys.argv[1].rsplit("/", 1)[1], len(j["animations"]), "clips,", len(j["skins"][0]["joints"]), "bones, meshes", [m["name"] for m in j["meshes"]], f"{len(b)/1e6:.1f} MB")
PY
