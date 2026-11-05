# M3-97 finale staging — evidence (port round, 6 Nov 2026)

Sadman/night-claude2 (Claude Opus 5.5 night shift) ported the parked `origin/night/M3-97` work (commit 5051d64, staged 5 Nov by Sadman/night-codex-main) onto main fc72c90. The 54 content files had no conflict with main; only `PRODUCTION_HANDBOOK.md`, `BOARD.html` and `tasks.json` did, and those were rewritten on main's current versions. No AI generation, network or credits this round.

## What the player sees

| Film | Staging (doc 24 §7.5–§7.7) |
|---|---|
| CS-15 Hello, Aurora (29.75 s) | Rao's channel opens (`SFX_RADIO_EARTH_IN`, cabin hum); hard cut into the Dhaka rooftop at 5.042 s; **2.600 s of digital silence** before Noor's first words at 7.642 s, captioned with **EARTH LINK · LIVE**; **CUE-11** waits until 13.083 s (1.5 s after her line) and is muted through Mei's 2.6 s round trip; one ambience per picture (rover cabin, Aurora low-power fans, silent Dhaka slot) and never under one another; no Moon in Dhaka's sky; "Return departs 03:00 · UTC · 9 April 2047" carries S10 into S11. The approved Rao and Noor lines (M3-94) show as captions word for word from `vo_lines.csv` until M3-94R records them. |
| CS-17 What We Grew (30.71 s) | Tracked UI-layer names (art bible: readable text is a UI layer, never generated): **TARA** beside Alo's pressed petal, an **Alo × Tara** lineage card instead of the blank one, five named mugs **KAI, AMARA, MEI, RAFI, FERREIRA**. Canon line order kept. |
| CS-18 The Closed Drawer (8.0 s) | The accepted still, the inventory lamp blinks once on frames 91–94 (3.79–3.96 s), picture fades 6–7 s, black and silence 7–8 s. |

`SFX_DHAKA_ROOFTOP_MORNING` (CS-15, 5.04–13.71 s) and `SFX_INVENTORY_LAMP_TICK` (CS-18, 3.8 s) keep explicit `pending` cue slots that the composer reports as silent; M3-94R generates them (board note, 5 Nov). How to install them: `production/cutscenes/v8/notes_C.md`, M3-97 section.

## Checks

- `M3-97_staging_checks.txt` — `verify_staging.py --runtime` on this checkout: exact captions against `vo_lines.csv`, the two 2.6 s round trips, CUE-11's 1.5 s room, beds that never overlap, hard cuts, ffmpeg **scdet** finds only the planned cuts (`M3-97_CS-15_scdet.txt`, `_CS-17_`, `_CS-18_`), audio covers every film, digital silence in the open-channel pause, the four-frame blink, silent black tail, and runtime OGV / master parity (mean error 2.5–4.4 of 255). Last line: `M3-97 STAGING RESULT: PASS (masters + runtime)`.
- `M3-97_port_provenance.txt` — the blink shot, both named shots and the three masters rebuild **byte-identically** from the ported sources.
- `M3-97_composer_compatibility.txt` — main's and the extended `compose_cutscene.py` render CS-01 (beds, ramps, slate, title) and CS-08 (music, voices) with identical video frames and bit-identical decoded audio.
- `M3-97_tests.txt` — full `game/tools/run_tests.sh` transcript on this checkout; last line **38/38 suites passed** (the 5 Nov copy was empty).
- `M3-97_capture_output.txt` — `M3-97_capture.sh` re-run on this checkout, 6 Nov: runtime parity holds (films not re-encoded), ten window captures through the real `CampaignCutscenePlayer`, `M3-97 CAPTURE RESULT: PASS (0 failures)`, `presentation_media.json is current`, `M3-97 CAPTURE: PASS`.

## Fixed this round

`production/cutscenes/v8/src/name_labels.py` failed CS-17-C with "incomplete label tracking ... lost ['TARA']", so the shot could not be rebuilt. The shot itself is right: the TARA plate is last on screen at frame 184 and its optical-flow track only ends at frame 189, when all four corners are off the left edge. The tracker now notes whether a lost label had already left the frame; only a label lost while on screen fails. The rebuild prints `off screen before the track ended: TARA (track ended at frame 189)` and is byte-identical.

`M3-97_capture.sh` re-encoded all three OGVs on every run, churning three LFS films that already matched. It now checks runtime parity first and re-encodes only when parity fails or `M3_97_REENCODE=1`.

## Screenshots

Window captures through the game's cutscene player (1280×720): `M3-97_CS15_ingame_{rao_channel,pause,noor_live,noor_reply,return}.png`, `M3-97_CS17_ingame_{tara_lineage,five_named_mugs}.png`, `M3-97_CS18_ingame_{hold,blink,black}.png`. Master frames from `verify_staging.py` (no player chrome): the same names without `ingame`, plus `M3-97_CS18_blink_frames89-96.png` (frames 89–96 around the lamp).

ART_BIBLE §2, checked on the frames: black sky through every lunar window; the Earth-facing summit window shows Earth and no sky colour; Dhaka's sky has no Moon; mustard flowers have four petals and no plant has a face; English captions and labels only (no Bangla script); no NASA logos; no airborne exterior sound (the beds are the pressurised cabin, the habitat and Earth).

## Joins (doc 24 §2.9)

- CH08 S09→S10 and S10→S11: Rao's open channel invites Noor's voice; "Return departs 03:00" hands off to the return.
- CH08 S11→S12: the five named mugs, Ferreira's beside the others.
- CH08→credits→CS-18 (Fix): the inventory lamp is in the film, which plays on `campaign_complete`. The chosen dedication ("For the gardens we leave for others", D13) depends on the save, so a pre-rendered film cannot carry it; **M4-01** (new board task) draws it over CS-18's closing 6.0–8.0 s at runtime.

## For Sadman

1. Listen to CS-15: CUE-11's entrance at 13.1 s and the cabin and fan bed levels.
2. Check TARA, Alo × Tara and the five mug names at gameplay size (`M3-97_CS17_ingame_*.png`).
3. Run M3-94R in an ElevenLabs session: Rao's and Noor's lines and the two effects. Then follow the install steps in notes_C.md and rebuild CS-15 and CS-18.
