#!/bin/bash
# Character build v7 (anime style): retarget every Meshy clip onto the Tripo Mixamo rig, with hand poses and floor contact.
#   tools/build_character_v7.sh <CH_Name> <height_m> <tripo_rig.glb> <meshy_rig_dir> <clips_dir> <out_dir>
# meshy_rig_dir holds walking.glb and running.glb; clips_dir holds clips1..3/, personal/ and the five story motions
# (<Name>/animation.glb). Walk_loop is the rig's own walk for everyone.
set -e
name=$1; h=$2; rig=$3; mr=$4; c=$5; out=$6
B=/opt/homebrew/bin/blender
cd "$(dirname "$0")"
mkdir -p "$out"
# Everyone walks with their own rig's plain walk ("walking_man"): the library's personal walks (a swagger, posed hands,
# a glitchy cycle, a brisk walk with odd knees) all read wrong on these bodies. It comes first, so a personal walk is skipped.
walk=("Walk_loop=$mr/walking.glb")
$B -b -P retarget_clips.py -- "$rig" "$h" "$out/${name}_body.glb" "$mr/walking.glb" "$mr/running.glb" "${walk[@]}" \
  "$c/clips1/animation.glb" "$c/clips2/animation.glb" "$c/clips3/animation.glb" "$c/personal/animation.glb" "$c/Carry/animation.glb" \
  Pollinate="$c/Pollinate/animation.glb" Water="$c/Water/animation.glb" Inspect="$c/Inspect4/animation.glb" \
  Type="$c/Type/animation.glb" Repair="$c/Repair/animation.glb" > "$out/retarget.log" 2>&1
grep -E "^RETARGETED|^HANG|^POSTURE|^ROLL|HAND .* error ([1-9]|0\.[5-9])" "$out/retarget.log" || true
echo "BODY $name -> $out/${name}_body.glb ($(du -h "$out/${name}_body.glb" | cut -f1))"
