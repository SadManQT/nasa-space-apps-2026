#!/bin/bash
# Character rebuild v3, from the Tripo Mixamo rig and the Meshy clips to the finished GLB, plus review sheets.
#   tools/build_character_v3.sh <CH_Name> <height_m> <tripo_rig.glb> <meshy_dir> <out_dir>
# meshy_dir holds mrig/walking.glb, mrig/running.glb and clips/<clips1|clips2|Pollinate|Water|Inspect|Type|Repair>/animation.glb.
set -e
name=$1; h=$2; rig=$3; md=$4; out=$5
cd "$(dirname "$0")/.."
B=/Applications/Blender.app/Contents/MacOS/Blender
mkdir -p "$out"
if [ -n "$FORCE_FACE" ] || [ ! -f "$out/${name}_face.glb" ]; then   # the face rig only changes when add_mouth_rig.py does
  $B -b -P tools/add_mouth_rig.py -- "$rig" "$out/${name}_face.glb" --landmarks rigs/face_landmarks.json --name "$name" > "$out/face.log" 2>&1
fi
grep -E "^(MOUTH 2D|CUT|PARTS|SHAPES)" "$out/face.log"
c=$md/clips
$B -b -P tools/retarget_clips.py -- "$out/${name}_face.glb" "$h" "$out/${name}.glb" "$md/mrig/walking.glb" "$md/mrig/running.glb" \
  "$c/clips1/animation.glb" "$c/clips2/animation.glb" Pollinate="$c/Pollinate/animation.glb" Water="$c/Water/animation.glb" \
  Inspect="$c/Inspect/animation.glb" Type="$c/Type/animation.glb" Repair="$c/Repair/animation.glb" > "$out/retarget.log" 2>&1
grep -E "^RETARGETED|HAND .* error ([1-9]|0\.[5-9])" "$out/retarget.log" || true
$B -b -P tools/render_face.py -- "$out/${name}.glb" "$out/review_mouth.jpg" --res 260 > /dev/null 2>&1
$B -b -P tools/render_face.py -- "$out/${name}.glb" "$out/review_eyes.jpg" --wide --res 260 --keys Basis,eyesBlink,browUp,browDown,exprSerious > /dev/null 2>&1
$B -b -P tools/render_hands.py -- "$out/${name}.glb" "$out/review_hands.jpg" --res 220 > /dev/null 2>&1
echo "BUILT $name -> $out/${name}.glb ($(du -h "$out/${name}.glb" | cut -f1))"
