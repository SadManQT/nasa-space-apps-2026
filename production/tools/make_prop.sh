#!/bin/sh
# Concept image or existing GLB -> game-ready prop/plant GLB.
#
#   tools/make_prop.sh <manifest.csv>    columns: name,concept_or_source,size_flag,size_m,tris,tex,notes
#
# concept_or_source: a .png concept is generated with Tripo image-to-3D (web plan CLI, ~55 credits)
# into models/raw/<name>/; a .glb source (e.g. a reused Tripo export) is only cleaned up.
# Resumable: an existing raw GLB is never regenerated. Generation stops before the balance drops
# below $RESERVE (default 0) + 55. Waits while the active profile is not $TRIPO_PROFILE_WANT.
# Clean-up and previews always re-run, so changing tris/tex/size in the manifest rebuilds finals.
set -u
T=~/.npm-global/bin/tripo
WANT=${TRIPO_PROFILE_WANT:-default}; RESERVE=${RESERVE:-0}; COST=55
cd "$(dirname "$0")/.."
guard() { while [ "$($T config show 2>/dev/null | awk '/current_profile/ {print $2}')" != "$WANT" ]; do sleep 20; done; }
balance() { $T account balance 2>/dev/null | awk '/Credits/ {print int($2)}'; }

tail -n +2 "$1" | while IFS=, read -r name src flag size tris tex notes; do
  FIN=models/final/$name; mkdir -p "$FIN/preview"
  case $src in
    *.glb) RAWGLB=$src ;;
    *)
      RAW=models/raw/$name; RAWGLB=$RAW/${name}_raw.glb; mkdir -p "$RAW"
      if [ ! -s "$RAWGLB" ]; then
        guard; b=$(balance)
        if [ "${b:-0}" -lt $((COST + RESERVE)) ]; then echo "STOP $name: balance $b < $((COST + RESERVE))"; break; fi
        echo "[$(date +%H:%M:%S)] $name: generate (balance $b)"
        $T generate image "$src" --model-version v3.1-20260211 --geometry-quality detailed \
          --texture-quality detailed --pbr --visibility private --timeout 20m \
          -o "$RAWGLB" >"$RAW/generate.log" 2>&1 || { echo "FAIL $name (see $RAW/generate.log)"; continue; }
      fi ;;
  esac
  [ -s "$RAWGLB" ] || { echo "MISSING $RAWGLB"; continue; }
  blender -b -P tools/blender_cleanup.py -- "$RAWGLB" "$FIN/$name.glb" \
    --tris "$tris" "$flag" "$size" --yaw -90 --tex "$tex" 2>&1 | grep CLEANUP | sed "s/^/$name /"
  blender -b -P tools/render_preview.py -- "$FIN/$name.glb" "$FIN/preview/final" --res 512 --views front,34,top34 >/dev/null 2>&1
done
echo "balance now: $(balance)"
