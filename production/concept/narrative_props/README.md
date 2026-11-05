# Narrative props and plant stages: 2D sheets for approval (M3-99)

Board task M3-99 (doc 24 NR-12). **Status: waiting for Sadman's approval. Nothing here is built into the game yet, and no Tripo, Meshy or ElevenLabs credit has been spent.**

| Sheet | What it shows |
|---|---|
| [M3-99_plant_stages_v1.png](M3-99_plant_stages_v1.png) | Alo cotyledon, true leaves, green pods, senescent, dry; Tara pods, senescent, dry |
| [M3-99_props_v1.png](M3-99_props_v1.png) | Alo and Tara nameplates, the "N." label holder, the gear-wheel tool tag, the drawer-lid pencil note, the working-stock envelope, five named mugs |
| [../../qa/evidence/M3-99_contact.png](../../qa/evidence/M3-99_contact.png) | Both sheets on one page |

## How the sheets were made (no AI image generation)

The sheets are Blender 5.2 Cycles renders of the planned build, not paintings, so what Sadman approves is what will ship:

- **Senescent, dry and Tara variants** reuse the existing Tripo mesh `PL_Alo_Pods` with a shader colour remap by hue class: purple stem, yellow or straw parts, green parts. The remap leaves the pot and soil alone. A stem lean grows towards the top of the plant. Tara uses the same mesh mirrored, with her stem recoloured green, so the two plants never read as copies. No new mesh, so no Tripo credits.
- **Cotyledon and true-leaf seedlings** are procedural Blender geometry: purple hypocotyl, two notched heart-shaped (obcordate) seed leaves, then toothed true leaves on petioles. Sizes follow the Fast Plants life cycle: about 2 cm on day 1–2, 3–4 cm on day 4–6. The pot is a stand-in; the runtime uses the plant cassette.
- **Props** are procedural Blender geometry with real fonts (DIN Alternate for printed labels, Bradley Hand for handwriting). The mugs are the existing `PR_Mug` mesh with wrapped masking-tape decals.

To rebuild them: `blender -b --factory-startup --python build_plant_panels.py -- <dir>`, then the same with `build_prop_panels.py`, then `python3 compose_sheets.py <dir>`. Set `M399_SAMPLES` for faster previews.

## Canon checks done

- Brassica rapa botany (ART_BIBLE §2 rule 8, §6): Alo's stem is purple and Tara's is green at every stage. No stage on this sheet has flowers, so the four-petal cross rule does not come into play here.
- No eyes, faces or mouths on any plant.
- Every word on a prop comes from canon or doc 24: "two empty circles" (STORY_FULL CH01-S04); seed ids ALO-01 and TARA-01 (`plant_service.gd`); the drawer-lid lines (doc 24 §4 clue 2); "N." (D10 option 2); "Working stock — Tara × Alo" (§7.6). The text is English in Latin letters, with no Bangla script, no logos and no seed count on the envelope.
- Role colours on the mugs come from ART_BIBLE §3. The marker ink is darkened for legibility, and Ferreira's most, because her gold is pale on tape.

## Decisions for Sadman (approve, change or decline each)

1. **Alo seedlings:** the cotyledon (12–13 Apr) and true-leaf (15–17 Apr) states.
2. **Alo green pods (8 May):** this state is new. The registry calls `PL_Alo_Pods` "mature dry pods", and its straw colour is the 16 May look, so 8 May had no art. This recolour fills the gap.
3. **Alo senescent and dry:** the lean and the colours.
4. **Tara pods, senescent and dry:** the pods and senescent states are fine by themselves. The dates on the sheet and the **dry** state depend on the Tara decision in **M3-94**, which is not approved yet: either the 31 May harvest, or the coded natural end on 22 May. Real dry Brassica stems turn straw-coloured. The sheet keeps a faded olive-green so Tara still reads as green-stemmed. Choose the olive or the true straw colour.
5. **Nameplates:** round holders, with the name, the seed id and the stem colour in words, so colour is never the only cue.
6. **"N." label holder:** the same holder family, "N." handwritten, with a mustard-gold band.
7. **Gear-wheel tool tag:** the stamped text "ENG-07" is new world text. Keep it or remove it.
8. **Drawer-lid note:** the wording follows doc 24 clue 2 exactly. It is new world text listed in the M3-94 pack.
9. **Working-stock envelope:** it exists only if M3-94 approves Tara's working stock.
10. **Five mugs:** masking tape in role-colour marker. Who writes the names, and is handwriting right?

## Still to do after approval

- Build the approved variants as runtime GLBs or material variants under `game/assets/plants/` and `game/assets/props/`, and run `production/tools/verify_gate.py`.
- **Sound effects (not generated):** the ElevenLabs connector was not authorised in the overnight session, so neither effect exists yet. Specs from doc 24 §2.11:

| Id | Description | Loop | Caption | First scene |
|---|---|---|---|---|
| `SFX_INVENTORY_LAMP_TICK` | A soft relay tick as the inventory lamp blinks | no | [inventory lamp] | EX-CH01-S02, EX-CH01-S03 (and CS-18) |
| `SFX_DHAKA_ROOFTOP_MORNING` | A city morning from a rooftop: distant traffic, birds, a kettle | yes (bed under the call) | [city morning] | EX-CH08-S10 |

  Add the `sfx_list.csv` rows in the same change as the `.ogg` files. `build_presentation_media.py` stops if a row says `loop=yes` and the file is missing.
