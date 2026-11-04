#!/bin/sh
# Build one cutscene end to end: compose the master from its spec, then encode the Ogg Theora file Godot plays.
#
#   production/tools/build_cutscene.sh production/cutscenes/v8/src/CS-10.json
#
# 1. compose_cutscene.py writes <out>.mp4 (captions burned in) and <out>.wav (final mix), next to the spec's "out".
# 2. ffmpeg extracts 24 fps frames at 1152x648; Godot's Movie Maker (the only Theora encoder here) writes
#    game/assets/cutscenes/<name>.ogv via ogv_writer.gd. Run one at a time: both steps are heavy.
set -eu
SPEC=$1
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
python3 "$ROOT/production/tools/compose_cutscene.py" "$SPEC"
OUT=$(python3 -c "import json,os,sys; s=sys.argv[1]; print(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(s)), json.load(open(s))['out'])))" "$SPEC")
NAME=$(basename "$OUT")
FRAMES=$(mktemp -d "${TMPDIR:-/tmp}/cutscene_frames.XXXXXX")
ffmpeg -v error -y -i "$OUT.mp4" -vf fps=24,scale=1152:648 -q:v 2 "$FRAMES/%05d.jpg"
"$GODOT" --path "$ROOT/game" --resolution 1152x648 --write-movie "$ROOT/game/assets/cutscenes/$NAME.ogv" \
  --fixed-fps 24 -s "$ROOT/production/tools/ogv_writer.gd" -- "$FRAMES" "$OUT.wav" >/dev/null 2>&1
rm -r "$FRAMES"
echo "built game/assets/cutscenes/$NAME.ogv ($(du -h "$ROOT/game/assets/cutscenes/$NAME.ogv" | cut -f1))"
