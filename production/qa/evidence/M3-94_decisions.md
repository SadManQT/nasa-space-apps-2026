# M3-94 — Canon proposal pack from the narrative revision: decisions and what changed

Night shift, 5 Nov 2026 (Sadman/night-fable, Claude Fable 5.1). Step (1), the asking, was done by Sadman
earlier the same day (AskUserQuestion, one question per item); the answers below are quoted from the board
note and PRODUCTION_HANDBOOK.md §3. Nothing was declined, so no §7 alternative of doc 24 is in use.

## Sadman's decisions (quoted)

| Item | Sadman's answer | Applied |
|---|---|---|
| Tara's dated resolution (watering stops 26 May, harvest 31 May 2046, working stock "Tara × Alo" with no headline count, nameplate on the lineage board, her name on cotton's bay) | **"Approve dated end"** | yes |
| Ferreira's margin note on the back of the evacuation order | **"Approve the note"** | yes |
| Amara "Forty-two." (EX-CH03-S10) | ticked: **'Amara: "Forty-two."'** | yes, `EX-CH03-S10-L05` |
| Rao "Aurora, Earth. We hear you. Go ahead." (EX-CH08-S10) | ticked: **'Rao: "Aurora, Earth..."'** | yes, `EX-CH08-S10-L05` |
| Noor "You finished what we could not." (EX-CH08-S10) | ticked: **'Noor: "You finished..."'** | yes, `EX-CH08-S10-L06` |
| Drawer-lid note, cotton manifest note, Rao's listening log, three tray dedications (review) | **"Ship as written"** | yes, as `TEXT` in the scene prose |

Recording the three lines in the speakers' existing ElevenLabs voices is split out to **M3-94R** (unattended
sessions have no ElevenLabs access). Until then the three `vo_lines.csv` rows carry their captions, an empty
`voice_file` and status `text-only (M3-94R records it)`; the runtime shows the caption with no audio, the same
contract as the two on-screen Noor text lines (test `_test_audio_and_cutscenes` exercises the missing-file fallback).

## Canon edits (story source → generated story and catalog)

Source of truth for the story is `full-game-story/content/*.json`; `build_story.py` regenerates
`story-data.json`, `STORY_FULL.md`, `index.html`, `app.compiled.js` and `audit-results.json`
(2702/2702 assertions; one pacing warning: EX-CH03-S12 prose is 331 words because Tara's farewell opens it).

| Scene | Change |
|---|---|
| EX-CH01-S03 | Drawer-lid note in the prose (clue 2), same wording as `journal_text.json` |
| EX-CH03-S10 | Prose: Amara reads the total after three seconds of fans; new line L05 "Forty-two." |
| EX-CH03-S11 | Prose names the three tray dedications (D6): Light and Star / For Alo and Tara / The Next Small Thing |
| EX-CH03-S12 | Opens on 31 May in the reference bay: Tara's dry pods, watering stopped 26 May (20 days after the last run), last photo, envelope "Working stock: Tara × Alo" with no count, founder ledger still 30, nameplate level with Alo's petal, Mei's card text, her name left on the bay; location updated; new first player action; later generations' seeds go to the working stock |
| CH03 continuity lock | Tara's 26 May / 31 May dates, working stock never mixed with the founder 30, nameplate and bay name |
| EX-CH04-S10 | Cotton manifest note (clue 14): "Cotton sprouted in a sealed experiment on the Moon in 2019. Let one grow further. — N." |
| EX-CH05-S05 | Ferreira turns the evacuation order over only after her confession; her 2034 margin note (clue 18) |
| EX-CH05-S12 | Cotton is cleared for Tara's bay, her name on the frame, the manifest note pinned |
| EX-CH08-S09 | When the Earth leg locks: the queued outbox sends and Rao's listening log arrives, "Aurora, Earth. Listening." for 52 days (clue 22) |
| EX-CH08-S10 | Rao L05 opens the channel before Noor's hello; Noor L06 "You finished what we could not." after Mei; prose quotes both |
| EX-CH08-S12 | Tara's nameplate level with the petal; board reads Alo × Tara and Tara × Alo; cotton in Tara's bay with her name beneath it |
| learning package | LOCK-06 extended with Tara's harvest and the working-stock rule; canon-change record ED-06 |

Two Chapter 1 fixes from 4 Nov (M1-40: "Earth-link cutoff" in EX-CH01-S09/S11 and the Latin-letter packet in
EX-CH01-S03) had been applied only to the generated files; they are now ported into `content/chapters-1-4.json`
so a rebuild no longer regresses them (verified: no unintended scene field differs from the committed story-data.json).

## Catalog and code

- `production/audio/vo_lines.csv`: 388 rows (385 + 3 text-only rows with captions).
- `game/scripts/content/build_catalog.py`: expects 388 VO rows; `order` is now the play position in the scene
  (ids are stable keys, so EX-CH08-S10-L05 plays first without renumbering the four recorded lines); every live
  Earth-link line in EX-CH08-S10/S12 (Rao's too) waits for both relay flags.
- `game/scripts/content/content_loader.gd`: counts 385 → 388 and the six frozen hashes re-frozen
  (`campaign-content-1-dc4e79f2208c7126`). `game/tools/test_worker_c_content.gd`: counts, the relay-gate
  expectation (3 before / 6 after) and the narrative order of EX-CH08-S10. Both files are outside the task's
  owned paths; the change is the minimum a catalog rebuild requires.
- Regenerated: `campaign_catalog.json`, `dialogue_catalog.json`, `presentation_media.json`
  (voice 383/383 files present, 388 lines), `PACKAGE_MANIFEST.json` and the story zip.

## Docs

- PRODUCTION_HANDBOOK.md: §3 already held the decision; §4 Tara row and a working-stock ledger line; §8.2 PL_Tara range; §12 bible conflict cleared; §10 status line.
- game-design/04_CHARACTER_BIBLE.md: Tara's outcome; Alo and Tara have no eyes or faces (the "stylised facial animation" and "stylised eyes" wording removed); Amara, Ferreira, Rao and Noor entries note the approved lines and the margin note.
- game-design/24_NARRATIVE_REVISION.md §8: approval record table, every item marked approved; §3.9, §4, §7.3, §7.5, §7.6 and §2.9 tagged.

## Not done here, on purpose

- No audio generated (M3-94R).
- Tara's lifecycle in code (`mature_days`, working-stock ledger, `archived_nameplate`) is M3-96, now unblocked.

## Fix round (Sadman/night-claude3, Claude Opus 5.5)

- **What stopped the first attempt:** `test_campaign_later_runtime.gd`, `test_chapter2_route.gd` and
  `test_extended_campaign_route.gd` started their campaigns with the old content revision literal
  `campaign-content-1-f06dab44691238c6`. After the catalog rebuild the restored snapshot no longer matches, and
  `test_campaign_later_runtime` idled in its main loop until the 20-minute suite timeout (seen again in this
  round: 11 minutes at 0.3% CPU). All three now read `CampaignContentFull.EXPECTED_CONTENT_REVISION`, as
  `test_campaign_knowledge`, `test_story_log` and `test_save_service_recovery` already did, so the next catalog
  rebuild cannot strand them (files outside the owned paths; minimum change).
- Rebuild check: `build_story.py` and `build_catalog.py` rerun on the committed sources reproduce every
  generated file byte for byte (same md5 for story-data.json, STORY_FULL.md and the three catalogs).
- Screenshots: the extended route does reach EX-CH03-S10 and EX-CH08-S10 (`_start_extended`), so the new
  captions are player-visible in the campaign HUD caption bar. `game/tools/capture_m3_94_lines.gd` puts each
  of the three lines in the caption bar, checks the text, speaker and on-screen rect, checks that the Earth-link
  lines are hidden before the relay legs are verified, and saves `M3-94_ch03_s10_amara_forty_two.png`,
  `M3-94_ch08_s10_rao_channel_open.png` and `M3-94_ch08_s10_noor_reply.png` with `M3-94_capture_probes.json`.
  `M3-94_capture.sh` runs it (and the headless probe, which writes `M3-94_catalog_probe.txt`).
- Typo fixed on the rewritten Tara line of the character bible ("Alo's42" → "Alo's 42").
