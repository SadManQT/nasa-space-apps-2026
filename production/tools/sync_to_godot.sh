#!/bin/sh
# Copy finished GLBs from production/models/final into the Godot project, one folder per asset
# (game/assets/<category>/<Name>/<Name>.glb, with Godot's extracted textures beside it),
# import headless, then run the quality gate.
#   production/tools/sync_to_godot.sh
# A changed GLB gets a fresh folder so stale extracted textures never linger.
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
for f in "$ROOT"/production/models/final/*/*.glb; do
  n=$(basename "$f" .glb)
  case $n in
    CH_*) c=characters ;; PL_*) c=plants ;; PR_*) c=props ;; VH_*) c=vehicles ;; EN_*) c=environment ;; *) c=misc ;;
  esac
  d="$ROOT/game/assets/$c/$n"
  if [ ! -f "$d/$n.glb" ] || ! cmp -s "$f" "$d/$n.glb"; then
    rm -rf "$d"; mkdir -p "$d"; cp -p "$f" "$d/$n.glb"; echo "updated $c/$n"
  fi
done
# In the model categories only, remove loose files and asset folders whose final GLB is gone.
# (audio/, cutscenes/, ui/ and README.md are never touched.)
for c in characters plants props vehicles environment misc; do
  [ -d "$ROOT/game/assets/$c" ] || continue
  find "$ROOT/game/assets/$c" -mindepth 1 -maxdepth 1 -type f -delete
  for d in "$ROOT/game/assets/$c"/*/; do
    [ -d "$d" ] || continue
    n=$(basename "$d"); [ -f "$ROOT/production/models/final/$n/$n.glb" ] || { rm -rf "$d"; echo "removed stale $c/$n"; }
  done
done
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
python3 -I "$ROOT/production/tools/verify_gate.py"
