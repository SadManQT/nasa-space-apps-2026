#!/bin/bash
# Fitted EVA suit variant of an installed cast member (M3-3A, CH_<Name>_EVA), from its Tripo Mixamo rig to the GLB in
# game/assets/characters/CH_<Name>_EVA/. Same route as the v8 cast (finish_character_v7.sh), except that the clips come
# from the installed character itself (tools/transfer_clips.py), so the suit moves exactly like the approved person:
#   clips (42, the hold poses rebuilt) -> anime face layers -> sleeve patches + right-chest Aurora decal + pack paint
#   -> (Mei) ponytail bones -> hold poses.
#   tools/finish_character_eva.sh <name lower-case> <work_dir>
# work_dir holds prep/<name>.glb (prep_tripo_character.py --facing +X), trig/<name>/model_url.glb (tripo_api.py rig,
# Mixamo spec) and face/<name>.png (render_face_flat.py of the prepared model); the face boxes are the
# CH_<Name>_EVA rows of production/rigs/face_landmarks_v8.json. PONY="--ztop .. --zbottom .." for Mei's ponytail bones.
# Run production/tools/sync_to_godot.sh afterwards (or godot --import) and verify_gate.py.
set -e
n=$1; W=$2
C=CH_$(python3 -c "print('$n'.capitalize())"); N=${C}_EVA
T=$(cd "$(dirname "$0")" && pwd); R=$(cd "$T/../.." && pwd); B="/opt/homebrew/bin/blender --python-exit-code 1"
out=$W/build/$n; mkdir -p "$out" "$R/game/assets/characters/$N"
if [ -z "$SKIP_BODY" ] || [ ! -f "$out/body.glb" ]; then   # SKIP_BODY=1 reuses the transferred body
  $B -b -P "$T/transfer_clips.py" -- "$W/trig/$n/model_url.glb" "$R/game/assets/characters/$C/$C.glb" "$out/body.glb" \
    --skip CarryBox_pose,HoldRight_pose > "$out/transfer.log" 2>&1
fi
grep -E "^(SCALE|ABDUCT|TRANSFERRED)" "$out/transfer.log"
python3 "$T/make_toon_face_atlas.py" "$W/face/$n.png" "$R/production/rigs/face_landmarks_v8.json" "$N" "$out/facekit" > "$out/atlas.log" 2>&1
$B -b -P "$T/add_toon_face.py" -- "$out/body.glb" "$W/prep/$n.glb" "$out/facekit" "$out/face.glb" > "$out/face.log" 2>&1
$B -b -P "$T/add_patches.py" -- "$out/face.glb" "$R/production/concept/patches" "$out/patched.glb" --chest --pack --fabric light > "$out/patches.log" 2>&1
grep -E "^(PATCH|PAINT|PACK)" "$out/patches.log" || true
final="$out/patched.glb"
if [ -n "$PONY" ]; then
  $B -b -P "$T/add_ponytail_bones.py" -- "$final" "$out/ponytail.glb" $PONY > "$out/ponytail.log" 2>&1
  final="$out/ponytail.glb"; grep -E "PONYTAIL (vertices|DONE)" "$out/ponytail.log" || true
fi
$B -b -P "$T/add_hold_poses.py" -- "$final" "$out/$N.glb" > "$out/holds.log" 2>&1
grep -E "^POSE|HOLD POSES DONE" "$out/holds.log" || true
cp "$out/$N.glb" "$R/game/assets/characters/$N/$N.glb"
python3 - "$out/$N.glb" <<'PY'
import json, struct, sys
b = open(sys.argv[1], "rb").read(); n = struct.unpack("<I", b[12:16])[0]; j = json.loads(b[20:20 + n])
print("FINAL", sys.argv[1].rsplit("/", 1)[1], len(j["animations"]), "clips,", len(j["skins"][0]["joints"]), "bones, meshes", [m["name"] for m in j["meshes"]], f"{len(b)/1e6:.1f} MB")
PY
