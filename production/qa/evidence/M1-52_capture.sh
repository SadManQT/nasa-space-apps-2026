#!/usr/bin/env bash
# M1-52 evidence (Godot's Movie Maker and a game window both need a desktop session, so not inside a sandbox):
#   production/qa/evidence/M1-52_capture.sh
# 1. Encodes the reviewed v8 master (with the M1-52 field beat) production/cutscenes/v8/CS-01_Arrival.mp4 (+ .wav mix) to the Ogg Theora
#    file the campaign plays, game/assets/cutscenes/CS-01_Arrival.ogv, as build_cutscene.sh does but at the master's
#    own 1280x720 like the other 17 films (the master is not recomposed, so the reviewed cut and its LFS object stay
#    as committed).
# 2. Probes the .ogv: duration, hard cuts (scdet) and the exterior's audio (digital silence while only the exterior
#    is on screen, 6.0-11.13 s: after the hard cut from the M1-52 field, before the dissolve into the commons)
#    and the field's wind-and-birds level -> M1-52_probe.txt.
# 3. Stills of the master at the beats, either side of the hard cut -> M1-52_master_*.png (the reference for the in-game frames).
# 4. Runs the campaign windowed (M1-52_capture.gd): screenshots of the film at four beats and of play resuming
#    with the first EX-CH01-S01 line voiced in-engine -> M1-52_film_*.png, M1-52_after_film_first_line.png.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}   # Godot through the machine-wide two-at-a-time gate
[ -x "$GODOT" ] || GODOT=/Applications/Godot.app/Contents/MacOS/Godot
HEAVY="python3 $ROOT/production/tools/heavy.py"   # every encode waits its turn (at most two heavy jobs on this Mac)
FIELD_END=6.0     # hard cut from the field to the Moon
EXTERIOR_END=11.13   # the dissolve into the commons starts here (6.0 + shot A's 6.03 s on screen - the 0.9 s overlap)
MASTER="$ROOT/production/cutscenes/v8/CS-01_Arrival"
OGV="$ROOT/game/assets/cutscenes/CS-01_Arrival.ogv"
PROBE="$HERE/M1-52_probe.txt"
cd "$ROOT" || exit 2

if [ ! -s "$MASTER.wav" ]; then   # the mix is gitignored; rebuild it from the committed master
  $HEAVY ffmpeg -loglevel error -y -i "$MASTER.mp4" -vn -ac 2 -ar 48000 "$MASTER.wav" || exit 2
fi
FRAMES=$(mktemp -d "${TMPDIR:-/tmp}/cs01_frames.XXXXXX")
$HEAVY ffmpeg -v error -y -i "$MASTER.mp4" -vf fps=24,scale=1280:720 -q:v 2 "$FRAMES/%05d.jpg" || exit 2
"$GODOT" --path "$ROOT/game" --resolution 1280x720 --write-movie "$OGV" --fixed-fps 24 \
  -s "$ROOT/production/tools/ogv_writer.gd" -- "$FRAMES" "$MASTER.wav" >/dev/null 2>&1
rm -r "$FRAMES"
[ -s "$OGV" ] || { echo "M1-52: Godot did not write $OGV"; exit 2; }

{
  echo "M1-52 probe, $(date '+%Y-%m-%d %H:%M')"
  echo "ogv: $OGV ($(du -h "$OGV" | cut -f1))"
  echo "picture: $(ffprobe -v error -select_streams v -show_entries stream=codec_name,width,height,r_frame_rate -of csv=p=0 "$OGV")"
  echo "duration: $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OGV") s (master $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$MASTER.mp4") s)"
  echo "hard cuts (scdet t=10): $(ffmpeg -v verbose -i "$OGV" -vf scdet=t=10:s=1 -an -f null - 2>&1 | grep -c 'lavfi.scd.time')"
  echo "exterior on screen, $FIELD_END-$EXTERIOR_END s (must be digital silence):"
  ffmpeg -v info -i "$OGV" -vn -af "atrim=$FIELD_END:$EXTERIOR_END,astats=measure_overall=Peak_level+RMS_level+Max_level:measure_perchannel=none" -f null - 2>&1 | grep -E 'Peak level|RMS level|Max level' | sed 's/^/  /'
  echo "first non-zero 16-bit sample after the cut: $(ffmpeg -v error -i "$OGV" -vn -ar 48000 -f s16le - | python3 -c 'import sys, array; a = array.array("h", sys.stdin.buffer.read()); s = int(float(sys.argv[1]) * 48000) * 2; print(next(("%.3f s" % (i // 2 / 48000) for i, v in enumerate(a[s:], s) if v), "none"))' "$FIELD_END")"
  echo "field, 0-$FIELD_END s (wind and birds):"; ffmpeg -v info -i "$OGV" -vn -af "atrim=0:$FIELD_END,astats=measure_overall=Peak_level+RMS_level:measure_perchannel=none" -f null - 2>&1 | grep -E 'Peak level|RMS level' | sed 's/^/  /'
  echo "interior, 11.4 s-end (the fan bed):"; ffmpeg -v info -i "$OGV" -vn -af "atrim=11.4,astats=measure_overall=Peak_level+RMS_level:measure_perchannel=none" -f null - 2>&1 | grep -E 'Peak level|RMS level' | sed 's/^/  /'
} | tee "$PROBE"

for beat in field_wind:3.0 field_last:5.95 exterior_first:6.05 exterior_silent:7.2 slate_fans:14.0 title_gold_band:18.5; do
  ffmpeg -v error -y -ss "${beat#*:}" -i "$MASTER.mp4" -frames:v 1 "$HERE/M1-52_master_${beat%%:*}.png" || exit 2
done
"$GODOT" --headless --path "$ROOT/game" --editor --quit >/dev/null 2>&1   # import the new .ogv before the window opens
"$GODOT" --path "$ROOT/game" --windowed --resolution 1280x720 -s "$ROOT/production/qa/evidence/M1-52_capture.gd" 2>&1 | grep -E '^(M1-52|PASS|FAIL|CS-01 COLD OPEN)' | tee -a "$PROBE"
ls -la "$HERE"/M1-52_*.png
