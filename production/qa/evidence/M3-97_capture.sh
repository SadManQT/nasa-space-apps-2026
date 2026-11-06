#!/usr/bin/env bash
# Outside-sandbox handoff: encode the verified masters whose runtime films no longer match them in
# picture or sound (all three with M3_97_REENCODE=1), check runtime parity, then capture the actual
# campaign player with its window always on top. No credits or network.
# Godot's Movie Maker needs a window; godot_gated already invokes heavy.py (do not double-lock it).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$ROOT"
GODOT=${GODOT:-/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/m397_capture.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
exec > >(tee "$OUT/M3-97_capture_output.txt") 2>&1

# The OGVs are LFS binaries: re-encoding films that already match their masters only churns the repository.
# --stale compares frames and sound per film, so an audio-only rebuild (M4-02's lamp tick) is re-encoded too.
if [ "${M3_97_REENCODE:-0}" = 1 ]; then
  stale="CS-15_Hello_Aurora CS-17_What_We_Grew CS-18_The_Closed_Drawer"
else
  stale=$(python3 production/tools/heavy.py python3 production/cutscenes/v8/src/verify_staging.py --stale)
fi
if [ -z "$stale" ]; then
  python3 production/tools/heavy.py python3 production/cutscenes/v8/src/verify_staging.py --runtime
  echo "M3-97 runtime films already match their masters; not re-encoded (M3_97_REENCODE=1 forces it)"
else
  echo "M3-97 runtime films to re-encode: "$stale
  # Never replace an LFS film from a master that fails its own checks.
  python3 production/tools/heavy.py python3 production/cutscenes/v8/src/verify_staging.py
  for name in $stale; do
    master="$ROOT/production/cutscenes/v8/$name.mp4"
    mkdir "$WORK/frames"
    python3 production/tools/heavy.py ffmpeg -v error -y -i "$master" -vf fps=24,scale=1152:648 -q:v 2 "$WORK/frames/%05d.jpg"
    # Mix WAVs are intentionally gitignored: regenerate from the reviewed master, not a stale local mix.
    python3 production/tools/heavy.py ffmpeg -v error -y -i "$master" -vn -ar 48000 -ac 2 "$WORK/mix.wav"
    "$GODOT" --path game --windowed --resolution 1152x648 --write-movie "$WORK/raw.ogv" --fixed-fps 24 \
      --script "$ROOT/production/tools/ogv_writer.gd" -- "$WORK/frames" "$WORK/mix.wav" > "$WORK/writer.log" 2>&1
    if rg -q 'SCRIPT ERROR|Parse Error|Failed to load script' "$WORK/writer.log"; then cat "$WORK/writer.log"; exit 1; fi
    # Movie Maker writes one extra terminal frame. Remux to the master's exact duration, including CS-18's 8 s.
    # Theora holds can be sparse in a decoder; verify the stream clock, not nb_read_frames.
    count=$(find "$WORK/frames" -type f -name '*.jpg' | wc -l | tr -d ' ')
    seconds=$(python3 -c 'import sys; print(int(sys.argv[1]) / 24)' "$count")
    python3 production/tools/heavy.py ffmpeg -v error -y -i "$WORK/raw.ogv" -map 0:v:0 -map 0:a:0 -c copy \
      -frames:v "$count" -t "$seconds" "$WORK/final.ogv"
    mv "$WORK/final.ogv" "$ROOT/game/assets/cutscenes/$name.ogv"
    rm -rf "$WORK/frames"
    echo "M3-97 encoded $name: $count frames ($seconds seconds)"
  done
  python3 production/tools/heavy.py python3 production/cutscenes/v8/src/verify_staging.py --runtime
fi
"$GODOT" --headless --path game --editor --quit > "$WORK/import.log" 2>&1
if rg -q 'SCRIPT ERROR|Parse Error|Failed to load script' "$WORK/import.log"; then cat "$WORK/import.log"; exit 1; fi
"$GODOT" --path game --windowed --script res://tools/capture_m3_97.gd > "$WORK/capture.log" 2>&1
cat "$WORK/capture.log"
rg -q 'M3-97 CAPTURE RESULT: PASS' "$WORK/capture.log"
if rg -q 'SCRIPT ERROR|Parse Error|Failed to load script' "$WORK/capture.log"; then exit 1; fi
python3 production/tools/build_presentation_media.py --check
echo 'M3-97 CAPTURE: PASS'
