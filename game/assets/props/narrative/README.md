# Narrative props — M3-99

Sadman/night-claude2 (Claude Opus 5.5, night shift), 6 November 2026. Built from the 2D sheets Sadman approved on
5 November 2026 ([production/concept/narrative_props/](../../../../production/concept/narrative_props/README.md)) by
[`production/concept/narrative_props/build_runtime_assets.py`](../../../../production/concept/narrative_props/build_runtime_assets.py)
(Blender 5.2, procedural geometry and baked PBR maps; no generation service, no credits). The Alo and Tara stage variants
built by the same script live in `../../plants/` (see "Plants" below).

**No text, numbers or logos are modelled or baked (ART_BIBLE §7).** Every word is drawn at runtime by `narrative_props.gd`
from `narrative_props_content.json`, as lit, single-sided `Label3D` ink on the props' `Text_*` anchors, or letter by
letter around a mug's `NameArc`. Words are canon (STORY_FULL.md) or approved doc 24 world text, English in Latin letters.

| Prop | Variants | Where it belongs | What it is |
|---|---|---|---|
| `PR_LabelHolder` | `alo`, `tara`, `n` | EX-CH01-S04 (Mei presses both names on: "two empty circles"); Tara's moves to the lineage board on 31 May (EX-CH03-S12); `n` is D10 option 2 (EX-CH05-S11 on) | 38 mm holder ring, pressed-on paper label, printed colour band (Alo purple, Tara green, N. mustard gold); name, seed id and stem colour in words, so colour is never the only cue |
| `PR_Mug_Named` | `unnamed`, `KAI`, `AMARA`, `MEI`, `RAFI`, `FERREIRA` | the four mugs gain names at the end of EX-CH01-S12; Ferreira's fifth mug EX-CH04-S12 / EX-CH05-S01 | `PR_Mug` unchanged (so `unnamed` is a drop-in for it) plus one blank masking-tape strip per name, a quarter turn from the handle; role-colour marker |
| `PR_ToolTag_Gear` | `default` | clue 12, the annex warm-side bench (EX-CH03-S07) | steel tag with the gear-wheel emblem of Ferreira's old patch, split ring; stamp "ENG-07" |
| `PR_DrawerLidNote` | `default` | clue 2, the dry-storage drawer lid seen with the inspection camera (EX-CH01-S03) | brushed aluminium lid; N.'s pencil: "Seed 1: outer chamber." / "Seed 2: inside, for comparison." / "Water at" (the line stops) |
| `PR_WorkingStockEnvelope` | `default` | Tara's harvest, 31 May 2046 (EX-CH03-S12) | kraft seed envelope sealed with clear tape: "Working stock" / "Tara × Alo"; no count anywhere |

## Files

- `PR_*.glb` — the props (pivot at the base centre, metres, +Y up; small-prop budget: ≤ 3600 triangles, 512–1024 px maps).
- `narrative_props.json` — generated catalogue: path, triangles, size, anchors, the mug's arc radius, tape widths and
  handle/tape directions, and the six plant stage variants. Rebuilt by the Blender script.
- `narrative_props_content.json` — authored: words, fonts, sizes, ink colours, band colours, variants. Edit words here;
  no rebuild needed.
- `narrative_props.gd` — the helper (below).
- `fonts/` — Gochi Hand (handwriting) and Barlow Semi Condensed SemiBold (print), both SIL Open Font License 1.1
  (licence files beside them). The approval sheet used two macOS system fonts that cannot ship in a game; these are the
  closest open fonts.

## Using them

```gdscript
const NarrativeProps = preload("res://assets/props/narrative/narrative_props.gd")
var holder := NarrativeProps.instance("PR_LabelHolder", "tara")       # loads through AssetGeometry, draws the words
var mug := NarrativeProps.instance("PR_Mug_Named")                     # nameless, exactly like PR_Mug
NarrativeProps.apply_variant(mug, "KAI")                               # end of EX-CH01-S12: the tape and the name appear
var note := NarrativeProps.instance("PR_DrawerLidNote")                # mount it under the drawer lid, writing side down
```

The helper only dresses props; scenes and rooms decide where they stand and when a variant changes.

## Plants

`../../plants/PL_Alo_PodsGreen`, `PL_Alo_Senescent`, `PL_Alo_Dry`, `PL_Tara_Pods`, `PL_Tara_Senescent`, `PL_Tara_Dry`: the
approved recolour and lean of the `PL_Alo_Pods` Tripo mesh, baked into new 2048 px base-colour maps (no new mesh, no
Tripo credits). Tara's variants mirror the mesh, and her stem is green to the soil (Brassica rapa's green-stem form has
no anthocyanin; the approval panel had left a purple stem foot inside the tray). No flower exists at these stages; no
plant has eyes, a face or a mouth. `../../plants/plant_stage_models.json` maps each dated code stage to its model;
`CampaignRoom.apply_plant_state` reads it.

## Rebuild and verify

1. `python3 production/tools/heavy.py /opt/homebrew/bin/blender -b --factory-startup -t 4 --python production/concept/narrative_props/build_runtime_assets.py -- [--only ID ...] [--preview DIR]`
   (about a minute; `--preview DIR` also renders each plant variant in the approval sheet's studio for comparison).
   Ten of the eleven GLBs rebuild byte-identically; `PR_ToolTag_Gear` keeps the same triangle set and winding but Blender's
   boolean may emit it in another order.
2. Godot `--headless --path game --import`, then `python3 production/tools/verify_gate.py`
   (reads `production/manifest/narrative_props.csv`).
3. `game/tools/run_tests.sh narrative_props`; with a window, `production/qa/evidence/M3-99_capture.sh` writes
   `M3-99_contact.png` and `M3-99_garden_stages.png`.
