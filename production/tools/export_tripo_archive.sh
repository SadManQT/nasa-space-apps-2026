#!/bin/sh
# Download every project on the active Tripo account that is not yet local (export is free).
# Rigged projects are exported from their rigging operation with the skeleton (--with-animation).
#   tools/export_tripo_archive.sh <projects.jsonl> <out_dir>
set -u
T=~/.npm-global/bin/tripo
python3 -I - "$1" "$2" <<'PY' | while IFS='	' read -r kind pid name; do
import json, os, re, sys
out = sys.argv[2]
have = " ".join(os.listdir(out)) + " " + " ".join(os.listdir("models/reuse"))
skip = {"f5ef8924-e339-426b-8723-7fd5d762d256", "1a95d27d-eb69-4dcc-9015-1b24764e87cf"}  # Kai, Amara: made by make_character.sh
seen = set()
for line in open(sys.argv[1]):
    if not line.strip(): continue
    for p in json.loads(line)["projects"]:
        pid, kind = p["project_id"], p["operator"]["type"]
        if pid in seen or pid in skip or kind in ("pbr", "image_to_model"): continue  # image_to_model props already in models/reuse
        seen.add(pid)
        name = re.sub(r"[^a-z0-9]+", "_", p["project_name"].lower().replace(" 3d model", "")).strip("_") + "_" + pid[:8]
        if pid[:8] in have: continue
        print(kind, pid, name, sep="\t")
PY
  if [ "$kind" = rigging ]; then
    op=$($T project history "$pid" 2>/dev/null | awk '$2=="rigging" {print $1; exit}')
    $T export "$pid" --operator-id "$op" --with-animation --format glb -o "$2/$name.glb" --timeout 10m >/dev/null 2>&1
  else
    $T export "$pid" --format glb -o "$2/$name.glb" --timeout 10m >/dev/null 2>&1
  fi && echo "ok $name" || echo "FAIL $name"
done
