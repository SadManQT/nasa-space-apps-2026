# Narrative props and plant stages: 2D sheets for approval (M3-99)

Board task M3-99 (doc 24 NR-12). **Status: approved by Sadman on 5 Nov 2026 ("all are approved", PRODUCTION_HANDBOOK.md §3) and built on 6 Nov 2026.** The runtime assets are in [game/assets/props/narrative/](../../../game/assets/props/narrative/README.md) and `game/assets/plants/`; no Tripo or Meshy credit was spent.

| Sheet | What it shows |
|---|---|
| [M3-99_plant_stages_v1.png](M3-99_plant_stages_v1.png) | Alo cotyledon, true leaves, green pods, senescent, dry; Tara pods, senescent, dry |
| [M3-99_props_v1.png](M3-99_props_v1.png) | Alo and Tara nameplates, the "N." label holder, the gear-wheel tool tag, the drawer-lid pencil note, the working-stock envelope, five named mugs |
| [../../qa/evidence/M3-99_contact.png](../../qa/evidence/M3-99_contact.png) | The built assets in Godot, words drawn at runtime (6 Nov) |
| [../../qa/evidence/M3-99_bake_vs_approved.png](../../qa/evidence/M3-99_bake_vs_approved.png) | Each approved plant panel above its built GLB |

## How the sheets were made (no AI image generation)

The sheets are Blender 5.2 Cycles renders of the planned build, not paintings, so what Sadman approves is what will ship:

- **Senescent, dry and Tara variants** reuse the existing Tripo mesh `PL_Alo_Pods` with a shader colour remap by hue class: purple stem, yellow or straw parts, green parts. The remap leaves the pot and soil alone. A stem lean grows towards the top of the plant. Tara uses the same mesh mirrored, with her stem recoloured green, so the two plants never read as copies. No new mesh, so no Tripo credits.
- **Cotyledon and true-leaf seedlings** are procedural Blender geometry: purple hypocotyl, two notched heart-shaped (obcordate) seed leaves, then toothed true leaves on petioles. Sizes follow the Fast Plants life cycle: about 2 cm on day 1–2, 3–4 cm on day 4–6. The pot is a stand-in; the runtime uses the plant cassette.
- **Props** are procedural Blender geometry with real fonts (DIN Alternate for printed labels, Bradley Hand for handwriting). The mugs are the existing `PR_Mug` mesh with wrapped masking-tape decals.

To rebuild them: `blender -b --factory-startup --python build_plant_panels.py -- <dir>`, then the same with `build_prop_panels.py`, then `python3 compose_sheets.py <dir>`. Set `M399_SAMPLES` for faster previews.

**Runtime build (6 Nov 2026):** [`build_runtime_assets.py`](build_runtime_assets.py) imports these sheet scripts and builds the approved look into the game: the six plant stage GLBs (bake of the same remap and lean) and the five props (same geometry, baked PBR maps, no baked text). Usage and verification: [game/assets/props/narrative/README.md](../../../game/assets/props/narrative/README.md).

## Canon checks done

- Brassica rapa botany (ART_BIBLE §2 rule 8, §6): Alo's stem is purple and Tara's is green at every stage. No stage on this sheet has flowers, so the four-petal cross rule does not come into play here.
- No eyes, faces or mouths on any plant.
- Every word on a prop comes from canon or doc 24: "two empty circles" (STORY_FULL CH01-S04); seed ids ALO-01 and TARA-01 (`plant_service.gd`); the drawer-lid lines (doc 24 §4 clue 2); "N." (D10 option 2); "Working stock — Tara × Alo" (§7.6). The text is English in Latin letters, with no Bangla script, no logos and no seed count on the envelope.
- Role colours on the mugs come from ART_BIBLE §3. The marker ink is darkened for legibility, and Ferreira's most, because her gold is pale on tape.

## Decisions (approved as shown on 5 Nov 2026) and how they were built

1. **Alo seedlings:** approved; the cotyledon and true-leaf states were built by M1-07 (`PL_Alo_Sprout`, `PL_Tara_Sprout`, parked on `night/M1-07` until Sadman approves that task's two other sheets), so M3-99 does not build a second version.
2. **Alo green pods (8 May):** `PL_Alo_PodsGreen`.
3. **Alo senescent and dry:** `PL_Alo_Senescent` (lean 18°), `PL_Alo_Dry` (lean 28°).
4. **Tara pods, senescent and dry:** `PL_Tara_Pods`, `PL_Tara_Senescent`, `PL_Tara_Dry`; dates from M3-94 (watering stops 26 May, harvest 31 May 2046). The dry stem keeps the approved faded olive. One correction: Tara's stem is now green down to the soil; the approval remap had left a purple stem foot inside the tray, which a green-stem Brassica rapa cannot have.
5. **Nameplates** and 6. **"N." label holder:** one holder model, `PR_LabelHolder`, with variants `alo`, `tara`, `n`. The id line is 2.7 mm instead of 2.8 mm and sits 0.4 mm higher, so it stays inside the printed band in the bundled font.
7. **Gear-wheel tool tag:** `PR_ToolTag_Gear`, stamp "ENG-07" kept.
8. **Drawer-lid note:** `PR_DrawerLidNote`, word for word.
9. **Working-stock envelope:** `PR_WorkingStockEnvelope` (M3-94 approved the working stock).
10. **Five mugs:** `PR_Mug_Named`, handwritten names in role-colour marker on masking tape.

The words are drawn at runtime (ART_BIBLE §7: no text baked into models) in two SIL OFL fonts that ship with the game: Gochi Hand for handwriting and Barlow Semi Condensed for print. The sheets' Bradley Hand and DIN Alternate are macOS system fonts that cannot be redistributed.

## Sound effects (M3-99, 6 Nov 2026)

`SFX_INVENTORY_LAMP_TICK` ([inventory lamp], EX-CH01-S02, S03 and CS-18) and `SFX_DHAKA_ROOFTOP_MORNING` ([city morning], looping bed, EX-CH08-S10 and CS-15) were generated with ElevenLabs Sound Effects v2 and are listed in `production/audio/sfx_list.csv` (AI log rows of 6 Nov). The cutscene slots in CS-15 and CS-18 that still say `pending` are filled when the films are next rebuilt (board task filed by M3-99).
