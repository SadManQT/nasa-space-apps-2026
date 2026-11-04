#!/usr/bin/env bash
# M1-51 evidence, run outside the sandbox (Godot's Movie Maker and a game window both need a desktop session):
#   production/qa/evidence/M1-51_capture.sh
# 1. Encodes the reviewed v8 master production/cutscenes/v8/CS-01_Arrival.mp4 (+ .wav mix) to the Ogg Theora
#    file the campaign plays, game/assets/cutscenes/CS-01_Arrival.ogv, exactly as build_cutscene.sh does
#    (the master is not recomposed, so the reviewed cut and its LFS object stay as committed).
# 2. Probes the .ogv: duration, hard cuts (scdet) and the exterior's audio (digital silence) -> M1-51_probe.txt.
# 3. Runs the campaign windowed (M1-51_capture.gd): screenshots of the film at three beats and of play resuming
#    with the first EX-CH01-S01 line voiced in-engine -> M1-51_film_*.png, M1-51_after_film_first_line.png.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
MASTER="$ROOT/production/cutscenes/v8/CS-01_Arrival"
OGV="$ROOT/game/assets/cutscenes/CS-01_Arrival.ogv"
PROBE="$HERE/M1-51_probe.txt"
cd "$ROOT" || exit 2

if [ ! -s "$MASTER.wav" ]; then   # the mix is gitignored; rebuild it from the committed master
  ffmpeg -loglevel error -y -i "$MASTER.mp4" -vn -ac 2 -ar 48000 "$MASTER.wav" || exit 2
fi
FRAMES=$(mktemp -d "${TMPDIR:-/tmp}/cs01_frames.XXXXXX")
ffmpeg -v error -y -i "$MASTER.mp4" -vf fps=24,scale=1152:648 -q:v 2 "$FRAMES/%05d.jpg" || exit 2
"$GODOT" --path "$ROOT/game" --resolution 1152x648 --write-movie "$OGV" --fixed-fps 24 \
  -s "$ROOT/production/tools/ogv_writer.gd" -- "$FRAMES" "$MASTER.wav" >/dev/null 2>&1
rm -r "$FRAMES"
[ -s "$OGV" ] || { echo "M1-51: Godot did not write $OGV"; exit 2; }

{
  echo "M1-51 probe, $(date '+%Y-%m-%d %H:%M')"
  echo "ogv: $OGV ($(du -h "$OGV" | cut -f1))"
  echo "duration: $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OGV") s (master $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$MASTER.mp4") s)"
  echo "hard cuts (scdet t=10): $(ffmpeg -v verbose -i "$OGV" -vf scdet=t=10:s=1 -an -f null - 2>&1 | grep -c 'lavfi.scd.time')"
  echo "exterior 0-5.4 s:"; ffmpeg -v info -i "$OGV" -vn -af "atrim=0:5.4,astats=measure_overall=Peak_level+RMS_level+Max_level:measure_perchannel=none" -f null - 2>&1 | grep -E 'Peak level|RMS level|Max level' | sed 's/^/  /'
  echo "interior 5.4 s-end:"; ffmpeg -v info -i "$OGV" -vn -af "atrim=5.4,astats=measure_overall=Peak_level+RMS_level:measure_perchannel=none" -f null - 2>&1 | grep -E 'Peak level|RMS level' | sed 's/^/  /'
} | tee "$PROBE"

"$GODOT" --headless --path "$ROOT/game" --editor --quit >/dev/null 2>&1   # import the new .ogv before the window opens
"$GODOT" --path "$ROOT/game" --windowed --resolution 1280x720 -s "$ROOT/production/qa/evidence/M1-51_capture.gd" 2>&1 | grep -E 'M1-51|PASS|FAIL|RESULT' | tee -a "$PROBE"
ls -la "$HERE"/M1-51_*.png
