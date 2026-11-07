# Fitted EVA suits (CH_Cadet_EVA): 2D turnaround sheets for approval (M3-3A)

**Status: approved by Sadman in chat, 6 Nov 2026 about 10:58 ("Approve all five": decisions 1–5 below), built and installed 7 Nov (M3-3A): `game/assets/characters/CH_<Name>_EVA/`.**

**One page to approve from:** [00_Approval_Sheet.png](00_Approval_Sheet.png) stacks the five sheets at full size with the five helmet colourways underneath (`production/tools/ch03_contact.py`, 6 Nov).

Everything else in M3-3A (the helmet role variants, the descendant rack, the pressed petal and the Expedition Zero annex pieces) is a Blender derivation of installed, visually approved assets and needed no 2D approval; it is built and gated already.

| Sheet | Cadet | Role tabs | Notes to check |
|---|---|---|---|
| [kai_eva_sheet.png](kai_eva_sheet.png) | Kai, 1.74 m | orange | lean build kept; right-chest Aurora patch present |
| [amara_eva_sheet.png](amara_eva_sheet.png) | Amara, 1.72 m | cyan | **her braids are coiled low at the nape** so the helmet fits (her duty-coverall high bun is 41 cm above the neck; the helmet's interior is 35 cm); decide whether that is her EVA look |
| [mei_eva_sheet.png](mei_eva_sheet.png) | Mei, 1.60 m | green | low ponytail kept (it would be tucked inside the suit collar under a helmet); no right-chest patch on this take |
| [rafi_eva_sheet.png](rafi_eva_sheet.png) | Rafi, 1.84 m | purple | heavy-set silhouette kept; no right-chest patch on this take |
| [ferreira_eva_sheet.png](ferreira_eva_sheet.png) | Ferreira, 1.68 m | faded gold | **her frayed gear-wheel engineering patch is kept on the left chest** (continuity with the warm-side tool tag, doc 24 clue 12); the suit is faded and worn; decide whether the patch belongs on her EVA suit |

Design (ART_BIBLE §5 "EVA suit"): an original realistic soft-goods suit, quilted off-white outer layer, deep navy trim panels, signal-orange wrist rings, waist bearing and boot cuffs, rigid navy neck ring, chest control pack with no screen text, white gloves and over-boots, compact navy backpack. Patches as locked on 25 Oct: Bangladesh flag on the upper LEFT sleeve, round Aurora patch on the upper RIGHT sleeve and the right chest; role-colour tabs on both shoulders. No helmet on the sheet: the helmet is the separate prop `PR_Helmet_Roles` (its role stripe and fit are in `game/assets/props/PR_Helmet_Roles/helmet_roles.json`). No text, no logos, no agency marks.

## How the sheets were made

Tripo CLI 0.8.1 `image` with `gemini_3_pro_image_preview`, image-to-image from each cadet's approved v8 turnaround sheet (`production/concept/turnarounds_v8/<name>/sheet_upscaled.png`, downscaled to 2752 px for upload), one take each, 16:9 at 1376x768. Prompts are beside each sheet (`<name>_prompt.txt`) and in `provenance.json` with task ids and hashes; the rows are in `production/AI_PROMPT_LOG.md`. The Tripo balance read 1,325 credits before and after the five generations (the image tool did not charge the web account).

## Decisions for Sadman (approve, change or decline each)

1. **The suit design** on all five sheets (one design, five fits), or changes to the trim, colours or pack.
2. **Amara's low coil** instead of the high bun for EVA.
3. **Ferreira's gear-wheel patch** on the EVA suit's left chest (keep or remove).
4. **Mei's and Rafi's missing right-chest patch:** accept as is (the 3D build adds the patch decal procedurally with `tools/add_patches.py`, as for the coveralls) or ask for a retake.
5. **Resolution:** the sheets are 1376x768. Before `multiview_to_model` they need the same 4x upscale the v8 sheets had (Topaz on Sadman's machine) or a second pass at higher resolution.

## Built (6–7 Nov 2026)

- **Upscale (decision 5), free route:** no Topaz on this Mac, so each sheet view was redrawn once more by Tripo `image`
  (gemini_3_pro_image_preview, 9:16, 2x the figure's pixels; Kai's and Amara's fronts also lose the badge the sheets drew on
  the wrong, left, chest) and Lanczos-scaled to a 2,600 px figure on a 2,900 px square: `<name>/views/`. The sheets in this
  folder run front, LEFT side, back, RIGHT side.
- **Models:** Kai and Rafi from all four views (side views with the near arm removed, as for v8); Amara, Mei and Ferreira from
  the front and back views only (`<name>/views/` holds just those), because the arm-free side views made Tripo put a white
  shoulder dome and stray marks on their arms and tie Mei's ponytail behind her ear in every four-view take.
- **Rig and clips:** Tripo Mixamo rig (65 bones, Mei 68 with her ponytail bones); the 44 clips are copied from the installed
  coverall character (`production/tools/transfer_clips.py`), so every suit moves exactly like its wearer.
- **Patches (decision 4):** crisp flag (left sleeve), Aurora (right sleeve) and right-chest Aurora layers on all five; Tripo's
  painted placeholders and their copies are painted back to the suit fabric (`add_patches.py --chest --pack --fabric light`).
  Ferreira's gear-wheel patch stays on the left chest (decision 3); Amara's braids are in the low coil (decision 2).
- **Helmet fit:** measured on these suits by `production/tools/fit_helmets_eva.py` (the 1.16–1.63 coverall estimates replaced):
  Kai 1.17, Amara 1.28, Mei 1.35, Rafi 1.29, Ferreira 1.16; the helmet sits on the suit's neck ring at rest and the Head bone
  carries it (so the face never leaves the shell), and Mei's ponytail tucks away while it is on (`helmet_roles.json`, `helmet_roles.gd equip()`).
- Every generation, prompt, task id and credit: [production/ai_log_parts/M3-3A.md](../../ai_log_parts/M3-3A.md). Evidence:
  `production/qa/evidence/M3-3A_eva_*.png`.

## Original plan (before approval)

Per cadet, the v8 pipeline: `split_turnaround.py` → `build_character_v7.sh` (Tripo multiview quad model ~55 credits, Tripo Mixamo rig 20, re-export with animation, 42 Meshy clips retargeted) → `finish_character_v7.sh` (toon face, sleeve patches, hold poses) → the side-view mirrored-arm check and the 65/68-bone, 44-clip gate → `CH_<Name>_EVA` rows in `production/manifest/characters.csv`. Budget about 75 Tripo credits per cadet (375 for five) plus Meshy clips; the balance was 1,325 on 5 Nov 2026.
