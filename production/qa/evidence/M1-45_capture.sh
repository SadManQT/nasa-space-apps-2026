#!/usr/bin/env bash
# M1-45: the sandboxed night-shift worker cannot open a window, and Godot's Movie Maker (the only Theora
# encoder here) needs one, so this script finishes the task outside the sandbox:
#   1. encodes the recomposed masters production/cutscenes/v7/CS-01_Arrival.mp4 and
#      CS-02_The_Horizon_Closes_One_Door.mp4 to the game's .ogv files (1280x720, 24 fps, like the other
#      17 films), one Godot process at a time;
#   2. saves the frames a player sees at the exterior shot's timestamps from those .ogv files;
#   3. plays both films windowed through the campaign's cutscene player and screenshots them.
# Run from the repository root:  production/qa/evidence/M1-45_capture.sh
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
OUT="$ROOT/production/qa/evidence"
fail=0

build() {   # build <master basename> <evidence id> <frame seconds...>
  local name=$1 id=$2; shift 2
  local master="$ROOT/production/cutscenes/v7/$name.mp4" mix="$ROOT/production/cutscenes/v7/$name.wav"
  local ogv="$ROOT/game/assets/cutscenes/$name.ogv"
  local frames; frames=$(mktemp -d "${TMPDIR:-/tmp}/m145_frames.XXXXXX")
  ffmpeg -v error -y -i "$master" -vf fps=24,scale=1280:720 -q:v 2 "$frames/%05d.jpg" || { echo "M1-45: frame extraction failed for $name"; fail=1; return; }
  "$GODOT" --path "$ROOT/game" --resolution 1280x720 --write-movie "$ogv" --fixed-fps 24 \
    -s "$ROOT/production/tools/ogv_writer.gd" -- "$frames" "$mix" >"$OUT/M1-45_${id}_ogv_build.log" 2>&1
  rm -r "$frames"
  local want have
  want=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$master")
  have=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$ogv" 2>/dev/null || echo 0)
  if python3 -c "import sys; sys.exit(0 if abs(float(sys.argv[1]) - float(sys.argv[2])) <= 0.1 else 1)" "$want" "$have"; then
    echo "M1-45: $name.ogv rebuilt, ${have}s (master ${want}s)"
  else
    echo "M1-45: $name.ogv duration ${have}s differs from master ${want}s"; fail=1
  fi
  for t in "$@"; do
    ffmpeg -v error -y -ss "$t" -i "$ogv" -frames:v 1 "$OUT/M1-45_${id}_ogv_${t}s.png" || fail=1
  done
}

build CS-01_Arrival CS-01 3 6
build CS-02_The_Horizon_Closes_One_Door CS-02 2 5

"$GODOT" --path "$ROOT/game" --windowed --script res://tools/capture_cutscene_m145.gd >"$OUT/M1-45_ingame_capture.log" 2>&1
grep -q "M1-45 CAPTURE RESULT: PASS" "$OUT/M1-45_ingame_capture.log" || { echo "M1-45: in-game capture did not pass (see M1-45_ingame_capture.log)"; fail=1; }
rm -f "$OUT"/M1-45_*_ogv_build.log

ls -1 "$OUT"/M1-45_*.png 2>/dev/null
if [ "$fail" -eq 0 ]; then echo "M1-45 CAPTURE: PASS"; else echo "M1-45 CAPTURE: FAIL"; fi
exit "$fail"
