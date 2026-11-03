# Current state and drift register

## 3 November 2026 implementation addendum

**Where work is tracked now:** the ordered list of remaining work, each task with a full prompt, is the team board
(`production/plan/tasks.json`, readable as `production/plan/BOARD.html`), picked up through
`production/plan/GO_NEXT.md`. Current status is `PRODUCTION_HANDBOOK.md` §10. Where a prompt in this library
disagrees with its board task or the current code, the board task and the code win. The 3 Nov bug hunt
(`production/review/BUGHUNT_2026-11-03.md`) found Chapter 2 not yet playable from the real Chapter 1 handoff
(B01–B03, board task M0-02) although its fixture passes. Run suites with `game/tools/run_tests.sh`.

The supervisor has now integrated a systems/content/world foundation on top of the
commissioning slice. Worker A's authoritative state, P-02 simulation, save/retry,
plant biology and puzzle host pass 101 focused checks. Worker C's full canonical
catalog/presentation layer validates 8 chapters, 32 missions, 96 scenes and 385
dialogue lines and passes 577 focused checks. Worker B's room, navigation,
interaction, roster and Chapter 1 mission route passes 187 checks across the complete
12-scene traversal and CH02 readiness. This is a release checkpoint, not a full-game
completion claim.

The production boot is now wired to `game/scenes/campaign/chapter1_campaign.tscn`.
`main.gd` injects the full content/director/route/save stack, and the production
session smoke passes with exit code 0. The old commissioning scene and
legacy save adapter remain available for compatibility. The later route batch now
passes Chapter 2 **94/94**, Chapters 3–8 **452/452**, later runtime **7/7** and
production session **8/8**. Chapter 1 flow/UI/logic pass **90/90**, **32/32** and
**34/34**; save recovery passes **34/34**. The visual/learner/device review,
Windows export, runtime audio and final credits presentation are still open. This
batch was committed and pushed in `ff09cfd`.

The earlier 27 October snapshot below remains a historical baseline. The current
implementation has advanced beyond that bounded bootstrap; retain its older claims
only as history and use the dated addendum above for current status.

Checked locally on 27 October 2026 against `ca01433`, which matched fetched `origin/main`. Recheck before executing a task.

## Verified presence

- Final story: 8 chapters,32 missions,96 scenes,385 dialogue lines,720 target minutes. All 24 files listed by its existing package manifest matched their fingerprints.
- 49 actual binary GLBs under `game/assets/`, approximately 197 MB: 5 characters,7 plants,31 props,3 environment pieces,3 vehicles. They are not LFS-pointer text files.
- Current character JSON inspection: Kai/Amara/Rafi/Ferreira 65 bones; Mei 68; 44 animation clips each. The approved current heights are 1.74/1.72/1.84/1.68/1.60m respectively.
- Six Godot scenes: player, locomotion test, character review, character look-dev, anime look-dev, asset showcase. Existing 31 GDScript files cover player, character rendering/face/hair/review/showcase and tests.
- Three actual Ogg Theora files under `game/assets/cutscenes/`: CS-01 Arrival, CS-02 The Horizon Closes One Door, CS-03 Alo Needs A Friend. New anime masters/specs exist under `production/cutscenes/v7/`.
- Twelve individual dialogue MP3s for final scenes EX-CH01-S01/S09/S12, plus three cutscene mixes. This is not a complete campaign voice/music/effects library.
- Production CSVs contain 75 asset entries: 49 verified and 26 planned; 385 voice rows; 12 music cues; 35 SFX specs; 23 historical shot rows. The master list has 18 cutscenes.
- Headless asset reports record 49/49 passes. The latest handbook entry records 105 player checks,369 showcase checks and 447 review checks. These are prior recorded outcomes; rerun relevant tests after code/assets change and do not present an old test as a fresh execution.
- Existing CS-02-C, CS-03-B and CS-03-C use slow push-ins over their start frames because the corresponding Seedance motion jobs were refused when credits ran out. The three composed OGVs play, but that does not prove those missing motion shots were generated. Recheck the live tool/account state and the documented shot backlog before spending or declaring the cuts fully finished.

## Major remaining integration

The current project has a configured production main scene and verified Chapter 1–8
route contracts. Remaining release work is visual/learner/device review, runtime
audio and cutscene integration, final credits presentation, performance checks,
Windows export and release QA. The commissioning-only path remains as compatibility
coverage.

The full 32-mission progression is functionally traversable in the current route
fixtures, but it still requires the release reviews listed above; do not infer visual
or platform acceptance from headless functional checks.

## Conflicts every executor must resolve correctly

| Historical record | Current interpretation |
|---|---|
| Registry character heights 1.68/1.62/1.78/1.70 and 50k budgets; 24 bones/25 clips in old notes | Current approved models/manifests and latest handoff win; actual 65/68 bones and 44 clips |
| Old handbook pipeline says 78 bones or Meshy-only 24 | Historical work flow, not current cast acceptance |
| Some art-bible sections still discuss realistic/MetaHuman or pending style choice | Current locked direction is approved anime/cel, current v8-built cast |
| Older game docs require Bangla UI or plant faces | Current handbook explicitly requires English-only in-game text and natural faceless plants |
| Earlier technical blueprint has 16 missions/48 scenes/~4h | Expanded source has 32 missions/96 scenes/10–14h; puzzle mathematics remain unchanged |
| Older cinematic says unopened buds in 2034 annex | Only curled young unflowered seedlings; no flower buds |
| Historical 29 planned assets | Current CSV has 26 rows, with some semantic overlaps with delivered portraits/coveralls |
| Morning readiness report says no integrated OGV or automatic face/toon player setup | Later handoff/code and three actual OGV files supersede those particular gaps; check integration, not mere existence |
| Historical 23 reviewed old-style shots | These are not 18 approved new-style cutscenes; three anime cuts are present, remaining cuts need current-style production/integration |
| A claim that FFmpeg lacks Theora means conversion is impossible | Existing Godot Movie Maker OGV pipeline and three valid OGV outputs demonstrate a working route |
| A green technical asset gate means full gameplay/visual approval | Gate does not prove collision, moving parts, contacts, room assembly, target GPU appearance, learning or chapter completion |
| Old asset-manifest introduction says every production source is missing | Current checkout contains 49 real runtime GLBs. Reuse and inspect actual files; an absent ignored editable source does not make the installed runtime model nonexistent. |
| Original asset-document wording says not to generate during that documentation task | That sentence described the earlier document-writing scope. A new explicit implementation assignment follows its own authorization and current approval/credit rules; it does not inherit an indefinite ban on completing assets. |

Do not add paid tools, regenerate approved characters, replace source dialogue, copy expired account balances, or use Mac scratch pad paths as required inputs. If the current checkout lacks an optional production source, the installed binary and canonical metadata remain a usable starting point; document any irreversible-edit limitation before replacing it.

## What this execution library changes

It supplies detailed task instructions, dependencies and acceptance gates. It does not generate models, consume credits, implement gameplay, re-approve art or certify a release. Task completion must be recorded separately from the existence of a prompt file.
