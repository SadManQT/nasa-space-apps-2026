#!/usr/bin/env bash
# M3-99: re-captures the evidence for the Alo/Tara stage variants and the narrative props (a window is needed).
# Renders every built asset in Godot (runtime words included) and the garden close-ups at each dated stage, then
# composes production/qa/evidence/M3-99_contact.png and M3-99_garden_stages.png and prints the suite's result line.
# Run from anywhere:  production/qa/evidence/M3-99_capture.sh
# GODOT defaults to production/tools/godot_gated, which already waits for a heavy-process slot (heavy.py).
set -u
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
GODOT=${GODOT:-$ROOT/production/tools/godot_gated}
EVIDENCE="$ROOT/production/qa/evidence"
OUT="$EVIDENCE/M3-99_capture_output.txt"
CELLS=$(mktemp -d "${TMPDIR:-/tmp}/m399_cells.XXXXXX")
trap 'rm -rf "$CELLS"' EXIT
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --path "$ROOT/game" --resolution 1280x720 --script res://tools/test_narrative_props.gd -- --evidence "$CELLS" 2>&1 \
  | grep -E "NARRATIVE PROPS RESULT|FAIL|SCRIPT ERROR|Parse Error" | tee "$OUT"
grep -q "NARRATIVE PROPS RESULT: PASS" "$OUT" || exit 1
python3 - "$CELLS" "$EVIDENCE" "$ROOT/game/assets/props/narrative/narrative_props.json" <<'PY'
import json, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
cells, out, catalog = Path(sys.argv[1]), Path(sys.argv[2]), json.load(open(sys.argv[3]))
def font(size, bold=False):
    for p in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
              "/Library/Fonts/Arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()
NAVY, GOLD, INK, GREY = "#1F2A44", "#F2C230", "#1F2A44", "#5A6070"
def cell(img_path, w, h):
    im = Image.open(img_path).convert("RGB")
    im.thumbnail((w, h), Image.LANCZOS)
    pad = Image.new("RGB", (w, h), "#d9d9da")
    pad.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    return pad
def header(sheet, title, sub):
    d = ImageDraw.Draw(sheet)
    d.rectangle((0, 0, sheet.width, 92), fill=NAVY)
    d.text((24, 14), title, fill=GOLD, font=font(34, True))
    d.text((24, 58), sub, fill="white", font=font(17))
def caption(d, x, y, w, title, lines):
    d.text((x + 10, y + 8), title, fill=INK, font=font(19, True))
    for i, t in enumerate(lines):
        d.text((x + 10, y + 34 + i * 20), t, fill=GREY, font=font(14))
plants = {p["id"]: p for p in catalog["plants"]}
stage_words = {"PL_Alo_PodsGreen": "green pods, purple stem", "PL_Alo_Senescent": "straw pods, yellow leaves, lean 18°",
               "PL_Alo_Dry": "dry leaves, brittle pods, lean 28°", "PL_Tara_Pods": "green stem to the soil, mirrored mesh",
               "PL_Tara_Senescent": "straw pods, green stem, lean 16°", "PL_Tara_Dry": "dry pods, faded olive stem, lean 25°"}
W, CAP = 400, 96
sheet = Image.new("RGB", (6 * W, 92 + 2 * (W + CAP) + 500 + CAP), "#eeeeee")
header(sheet, "M3-99 built: Alo and Tara stage variants and the narrative props",
       "Godot 4.7 Forward+ renders of the runtime GLBs; every word is drawn at runtime (no baked text). Approved sheets: production/concept/narrative_props/ (Sadman, 5 Nov 2026).")
d = ImageDraw.Draw(sheet)
y = 92
for i, pid in enumerate(plants):
    sheet.paste(cell(cells / f"cell_{pid}.png", W, W), (i * W, y))
    caption(d, i * W, y + W, W, pid, [plants[pid]["stage"], stage_words[pid], f'{plants[pid]["triangles"]} tris, {plants[pid]["texture_px"]} px'])
y += W + CAP
row2 = [("PR_LabelHolder", "Label holders: alo, tara, n", ["EX-CH01-S04 'two empty circles'; N. (D10)", "band colour and words at runtime"]),
        ("PR_ToolTag_Gear", "Gear-wheel tool tag", ["clue 12, EX-CH03-S07 annex", "stamp ENG-07 at runtime"]),
        ("PR_DrawerLidNote", "Drawer-lid pencil note", ["clue 2, EX-CH01-S03, word for word", "the last line stops at 'Water at'"]),
        ("PR_WorkingStockEnvelope", "Working-stock envelope", ["EX-CH03-S12, 31 May 2046", "Tara × Alo, no count anywhere"]),
        ("PR_Mug_Named_FERREIRA", "Named mug, close", ["letters follow the mug wall", "fifth mug, EX-CH04-S12"])]
for i, (name, title, lines) in enumerate(row2):
    sheet.paste(cell(cells / f"cell_{name}.png", W, W), (i * W, y))
    caption(d, i * W, y + W, W, title, lines)
x = 5 * W
d.text((x + 12, y + 12), "Canon checks (suite)", fill=INK, font=font(19, True))
for i, t in enumerate(["No flower at these stages; no plant", "has eyes, a face or a mouth.", "Alo purple stem, Tara green stem.",
                       "English, Latin letters only; no logos.", "Words are canon word for word.", "Fonts: Gochi Hand, Barlow Semi",
                       "Condensed (SIL OFL 1.1, bundled)."]):
    d.text((x + 12, y + 44 + i * 22), t, fill=GREY, font=font(15))
y += W + CAP
sheet.paste(cell(cells / "cell_PR_Mug_Named.png", 1200, 500), ((sheet.width - 1200) // 2, y))
caption(d, (sheet.width - 1200) // 2, y + 500, 1200, "Five named mugs (PR_Mug_Named)",
        ["KAI, AMARA, MEI, RAFI on the table at the end of EX-CH01-S12; FERREIRA's fifth mug in EX-CH04-S12. Role-colour marker on masking tape."])
sheet.save(out / "M3-99_contact.png")
g = Image.new("RGB", (3 * 640, 92 + 2 * (360 + 70)), "#eeeeee")
header(g, "M3-99 garden (LOC-03): dated stages in the room's own light",
       "CampaignRoom.apply_plant_state reads assets/plants/plant_stage_models.json; dates from doc 24 §3.8-3.9 and plant_service.gd (M3-96).")
d = ImageDraw.Draw(g)
words = {("ALO-01", "pod_bearing"): "Alo, 8 May 2046: green pods", ("ALO-01", "mature_pods"): "Alo, 16 May: senescent, dry-down approved",
         ("ALO-01", "mature_dry"): "Alo, 16-21 May: the vigil", ("TARA-01", "pod_bearing"): "Tara, 8-26 May: pods in the cooler bay",
         ("TARA-01", "mature_pods"): "Tara, 26 May: watering stops", ("TARA-01", "mature_dry"): "Tara, 26-31 May: dry-down to harvest"}
for r, ind in enumerate(["ALO-01", "TARA-01"]):
    for c, st in enumerate(["pod_bearing", "mature_pods", "mature_dry"]):
        x, y = c * 640, 92 + r * 430
        g.paste(cell(cells / f"garden_{ind}_{st}.png", 640, 360), (x, y))
        caption(d, x, y + 360, 640, words[(ind, st)], [f"code stage {st}"])
g.save(out / "M3-99_garden_stages.png")
print("composed M3-99_contact.png and M3-99_garden_stages.png")
PY
for name in contact garden_stages; do
  test -s "$EVIDENCE/M3-99_$name.png" || { echo "missing M3-99_$name.png"; exit 1; }
done
