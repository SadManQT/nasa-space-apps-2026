#!/bin/sh
# Save a generated cutscene shot and prepare it for review.
#
#   tools/intake_shot.sh <shot_id> <video_url>        e.g. tools/intake_shot.sh CS-01-A 'https://...'
#
# Writes production/cutscenes/masters/<shot_id>.mp4 (Git LFS), prints its resolution, fps and
# length, and writes start / middle / end frames to production/cutscenes/review/<shot_id>_*.png
# plus a single strip <shot_id>_strip.png for the visual check.
# Converting to Godot's .ogv happens later (needs an ffmpeg build with libtheora).
set -eu
SHOT=$1; URL=$2
cd "$(dirname "$0")/.."
mkdir -p cutscenes/masters cutscenes/review
OUT=cutscenes/masters/$SHOT.mp4
curl -sfL --retry 3 -o "$OUT" "$URL"
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate:format=duration \
  -of default=nw=1 "$OUT" | tr '\n' ' '; echo
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
for p in start mid end; do
  case $p in start) t=0.1 ;; mid) t=$(echo "$DUR / 2" | bc -l) ;; end) t=$(echo "$DUR - 0.15" | bc -l) ;; esac
  ffmpeg -v error -y -ss "$t" -i "$OUT" -frames:v 1 -vf scale=640:-1 "cutscenes/review/${SHOT}_$p.png"
done
ffmpeg -v error -y -i "cutscenes/review/${SHOT}_start.png" -i "cutscenes/review/${SHOT}_mid.png" \
  -i "cutscenes/review/${SHOT}_end.png" -filter_complex hstack=inputs=3 "cutscenes/review/${SHOT}_strip.png"
rm "cutscenes/review/${SHOT}_start.png" "cutscenes/review/${SHOT}_mid.png" "cutscenes/review/${SHOT}_end.png"
echo "saved $OUT and cutscenes/review/${SHOT}_strip.png"
