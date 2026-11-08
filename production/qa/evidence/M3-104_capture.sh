#!/usr/bin/env bash
# M3-104: re-captures the glove-port window evidence outside a sandbox (a window is needed for the Godot screenshots).
#   production/qa/evidence/M3-104_capture.sh
# 1. game/tools/capture_m3_104.gd writes M3-104_after_{station_eye,S04_alo_glove_ports,chamber_side,far_face}.png
#    (the GLB as built, no runtime opening); M3-104_before_*.png are the same views captured on 8 Nov on main 2218919
#    before the fix (the old GLB with HabitatRoomBuilder.open_window_back: `capture_m3_104.gd -- --label before` on that
#    tree), and M3-104_before_pass_through.png is main's M3-2A_godot_pass_through.png then.
# 2. The M3-2A evidence suite refreshes the M3-2A_godot_* set from the rebuilt asset.
# 3. Composes M3-104_before_after.png (before left, after right) and M3-104_after_M3-2A.png
#    (all eight studio views, paired with the preserved M3-104_before_M3-2A.png).
# Rebuilds before capture: Blender's Metal initialization crashes before Python starts in the Codex sandbox.
# The installed GLBs were recovered from parked 8a5a257, whose builder is identical to the ported source.
# This script runs outside the sandbox; every heavy process is sequential and passes through heavy.py.
# GODOT defaults to production/tools/godot_gated, which already waits for a heavy-process slot (heavy.py).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
export GODOT=${GODOT:-/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated}
OUT="$ROOT/production/qa/evidence/M3-104_capture_output.txt"
cd "$ROOT"
python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup --threads 4 \
  --python production/tools/build_chapter2_assets.py -- --no-render \
  > production/qa/evidence/M3-104_rebuild.txt 2>&1
grep -q '^CHAPTER2_BUILD_PASS:' production/qa/evidence/M3-104_rebuild.txt
python3 - "$ROOT" <<'PY' | tee production/qa/evidence/M3-104_byte_check.txt
import hashlib, json, sys
from pathlib import Path
root = Path(sys.argv[1])
ledger = json.loads((root / "production/qa/evidence/M3-104_asset_hashes.json").read_text())
unchanged = 0
for row in ledger["assets"]:
    digest = hashlib.sha256((root / row["path"]).read_bytes()).hexdigest()
    if not row["changed"]:
        assert digest == row["before_sha256"], "Unrelated asset changed: " + row["path"]
        unchanged += 1
    print(digest, row["path"])
assert unchanged == 10
print("M3-104 BYTE CHECK: PASS (10/10 other Chapter 2 GLBs byte-identical)")
PY
"$GODOT" --headless --path "$ROOT/game" --editor --quit > production/qa/evidence/M3-104_import.txt 2>&1
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script' production/qa/evidence/M3-104_import.txt; then
  cat production/qa/evidence/M3-104_import.txt
  exit 1
fi
python3 production/tools/verify_gate.py | tee production/qa/evidence/M3-104_gate.txt
"$GODOT" --path "$ROOT/game" --resolution 1600x900 --script res://tools/capture_m3_104.gd -- --label after 2>&1 \
  | tee "$OUT"
grep -q "M3-104 CAPTURE RESULT: PASS" "$OUT" || exit 1
"$GODOT" --path "$ROOT/game" --resolution 1600x1000 --script res://tools/test_en_airlock.gd -- --evidence 2>&1 \
  | tee production/qa/evidence/M3-2A_capture_output.txt | tee -a "$OUT"
grep -q 'EN_AIRLOCK RESULT: PASS' production/qa/evidence/M3-2A_capture_output.txt
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|^FAIL ' "$OUT"; then exit 1; fi
python3 - "$ROOT" <<'EOF' | tee -a "$OUT"
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(sys.argv[1])
ev = root / "production/qa/evidence"
font = lambda size, bold=False: ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size, index=1 if bold else 0)
NAVY, WHITE, GREY = (31, 42, 68), (236, 238, 240), (150, 156, 166)
rows = [
    ("station_eye", "M3-104_before_station_eye.png", "M3-104_after_station_eye.png",
     "Glove-port station, 1.6 m eye (LOC-05, EX-CH02-S04)", "the kit glass mirrored the practicals as two discs; the pressure glazing (roughness 0.20) softens them"),
    ("S04", "M3-104_before_S04_alo_glove_ports.png", "M3-104_after_S04_alo_glove_ports.png",
     "S04 review view ch02_glove_ports (as M3-2R_S04_alo_glove_ports)", "same framing; before, the room cut the module's back plate away at runtime"),
    ("chamber", "M3-104_before_chamber_side.png", "M3-104_after_chamber_side.png",
     "Inside Alo's sealed chamber, looking back at the module (evidence only)", "before: the runtime cut left the module hollow; after: a closed far face, splayed navy reveal, sleeves"),
    ("far", "M3-104_before_far_face.png", "M3-104_after_far_face.png",
     "The module as built, far face (M3-2A studio vestibule, nothing behind the wall)", "before: a plain plate hid the window; after: the window opens through the module"),
    ("pass_through", "M3-104_before_pass_through.png", "M3-2A_godot_pass_through.png",
     "M3-2A_godot_pass_through (garden wall, M3-2A studio)", "nothing is built behind the studio's garden wall, so the pane reads grey over the dark void in both"),
]
cell_w, cell_h, pad, head = 780, 439, 14, 96
sheet = Image.new("RGB", (2 * cell_w + 3 * pad, 92 + len(rows) * (cell_h + head + pad) + pad), (18, 20, 26))
d = ImageDraw.Draw(sheet)
d.rectangle([0, 0, sheet.width, 80], fill=NAVY)
d.text((pad + 6, 14), "M3-104  EN_Airlock_GlovePort: the pressure window opens through the module", fill=WHITE, font=font(30, True))
d.text((pad + 6, 52), "Left: before (main 2218919: old GLB + HabitatRoomBuilder.open_window_back).  Right: after (GLB as built, no runtime opening).", fill=GREY, font=font(18))
y = 92
for key, before, after, title, note in rows:
    d.text((pad, y + 8), title, fill=WHITE, font=font(22, True))
    d.text((pad, y + 40), note, fill=GREY, font=font(17))
    for col, name in enumerate((before, after)):
        x = pad + col * (cell_w + pad)
        im = Image.open(ev / name).convert("RGB").resize((cell_w, cell_h), Image.LANCZOS)
        sheet.paste(im, (x, y + head - 22))
        d.rectangle([x, y + head - 22, x + 96, y + head + 4], fill=NAVY)
        d.text((x + 8, y + head - 20), "BEFORE" if col == 0 else "AFTER", fill=WHITE, font=font(18, True))
    y += cell_h + head + pad
sheet.save(ev / "M3-104_before_after.png")
print("wrote M3-104_before_after.png", sheet.size)
views = ["vestibule", "pass_through", "panel_safe", "panel_equalising", "panel_sealed", "chamber", "props", "paper_bee"]
w, h, pad = 640, 400, 16
studio = Image.new("RGB", (2*w + 3*pad, 90 + 4*(h + 36 + pad)), (18, 20, 26))
d = ImageDraw.Draw(studio)
d.text((pad, 18), "M3-104 AFTER: M3-2A studio views (rebuilt GLB, no runtime cut)", font=font(22), fill=WHITE)
for i, name in enumerate(views):
    x, y = pad + (i % 2)*(w + pad), 90 + (i // 2)*(h + 36 + pad)
    d.text((x, y), name, font=font(22), fill=WHITE)
    im = Image.open(ev / ("M3-2A_godot_" + name + ".png")).convert("RGB")
    im.thumbnail((w, h))
    studio.paste(im, (x + (w-im.width)//2, y + 30 + (h-im.height)//2))
studio.save(ev / "M3-104_after_M3-2A.png")
print("wrote M3-104_after_M3-2A.png", studio.size)
EOF
test -s "$ROOT/production/qa/evidence/M3-104_before_after.png" || { echo "missing M3-104_before_after.png"; exit 1; }
