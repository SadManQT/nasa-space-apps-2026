# Current state and drift register

Checked locally on 27 October 2026 against `ca01433`, which matched fetched `origin/main`. Recheck before executing a task.

## Verified presence

- Final story: 8 chapters,32 missions,96 scenes,385 dialogue lines,720 target minutes. All 24 files listed by its existing package manifest matched their fingerprints.
- 49 actual binary GLBs under `game/assets/`, approximately 197 MB: 5 characters,7 plants,31 props,3 environment pieces,3 vehicles. They are not LFS-pointer text files.
- Current character JSON inspection: Kai/Amara/Rafi/Ferreira 65 bones; Mei 68; 44 animation clips each. The approved current heights are 1.74/1.72/1.84/1.68/1.60m respectively.
- Six Godot scenes: player, locomotion test, character review, character look-dev, anime look-dev, asset showcase. Existing 31 GDS cript files cover player, character rendering/face/hair/review/showcase and tests.
- Three actual Ogg Theora files under `game/assets/cutscenes/`: CS-01 Arrival, CS-02 The Horizon Closes One Door, CS-03 Alo Needs AF riend. New anime masters/specs exist under `production/cutscenes/v7/`.
- Twelve individual dialogue MP3s for final scenes EX-CH01-S01/S09/S12, plus three cutscene mixes. This is not a complete campaign voice/music/effects library.
- Production CSVs contain 75 asset entries: 49 verified and 26 planned; 385 voice rows; 12 music cues; 35 SFX specs; 23 historical shot rows. The master list has 18 cutscenes.
- Headless asset reports record 49/49 passes. The latest handbook entry records 105 player checks,369 showcase checks and 447 review checks. These are prior recorded outcomes; rerun relevant tests after code/assets change and do not present an old test as a fresh execution.
- Existing CS-02-C, CS-03-B and CS-03-C use slow push-ins over their start frames because the corresponding See dance motion jobs were refused when credits ran out. The three composed OGVs play, but that does not prove those missing motion shots were generated. Recheck the live tool/account state and the documented shot backlog before spending or declaring the cuts fully finished.

## Major remaining integration

`game/project.godot` has no configured application main scene. There are no completed campaign mission scripts or assembled Chapter 1 rooms. The imported props are geometry inventory, not finished world interactions. The first priority is a bootable Chapter 1 route connecting room assembly, state, simulation, planting/care, planning UI, exclusive storm response, debrief and checkpoint recovery.

Complete campaign UI, plant lifecycle/stress coverage, remaining environments, fitted EVA/outfit variants, full audio, remaining anime cutscenes, save/load and the full 32 mission progression still require implementation and verification. Some items may have advanced since this snapshot: inspect before creating duplicates.

## Conflicts every executor must resolve correctly

| Historical record | Current interpretation |
|---|---|
| Registry character heights 1.68/1.62/1.78/1.70 and 50k budgets; 24 bones/25 clips in old notes | Current approved models/manifests and latest handoff win; actual 65/68 bones and 44 clips |
| Old handbook pipeline says 78 bones or Meshy-only 24 | Historical work flow, not current cast acceptance |
| Some art-bible sections still discuss realistic/MetaHuman or pending style choice | Current locked direction is approved anime/cel, current v 8-built cast |
| Older game docs require Bangla UI or plant faces | Current handbook explicitly requires English-only in-game text and natural faceless plants |
| Earlier technical blueprint has 16 missions/48 scenes/~4h | Expanded source has 32 missions/96 scenes/10–14h; puzzle mathematics remain unchanged |
| Older cinematic says unopened buds in 2034 annex | Only curled young unflowered seedlings; no flower buds |
| Historical 29 planned assets | Current CSV has 26 rows, with some semantic overlaps with delivered portraits/coveralls |
| Morning readiness report says no integrated OGV or automatic face/toon player setup | Later handoff/code and three actual OGV files supersede those particular gaps; check integration, not mere existence |
| Historical 23 reviewed old-style shots | These are not 18 approved new-style cutscenes; three anime cuts are present, remaining cuts need current-style production/integration |
| A claim that FF mpeg lacks Theora means conversion is impossible | Existing Godot Movie Maker OGV pipeline and three valid OGV outputs demonstrate a working route |
| A green technical asset gate means full gameplay/visual approval | Gate does not prove collision, moving parts, contacts, room assembly, target GPU appearance, learning or chapter completion |
| Old asset-manifest introduction says every production source is missing | Current checkout contains 49 real runtime GLBs. Reuse and inspect actual files; an absent ignored editable source does not make the installed runtime model nonexistent. |
| Original asset-document wording says not to generate during that documentation task | That sentence described the earlier document-writing scope. A new explicit implementation assignment follows its own authorization and current approval/credit rules; it does not inherit an indefinite ban on completing assets. |

Do not add paid tools, regenerate approved characters, replace source dialogue, copy expired account balances, or use Mac scratch pad paths as required inputs. If the current checkout lacks an optional production source, the installed binary and canonical metadata remain a usable starting point; document any irreversible-edit limitation before replacing it.

## What this execution library changes

It supplies detailed task instructions, dependencies and acceptance gates. It does not generate models, consume credits, implement gameplay, re-approve art or certify a release. Task completion must be recorded separately from the existence of a prompt file.
