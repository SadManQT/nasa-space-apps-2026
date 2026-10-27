# Dependency and ownership map

Use this file with the [phase board](06_EXECUTION_BOARD.md) and [complete index](99_COVERAGE_MATRIX.md). Dependencies describe integration readiness, not a need to rewrite already verified work. One owner controls each shared service; other owners publish bounded interface requests.

## Shared runtime DAG

| Owner/task | Prerequisites | Publishes | Primary consumers |
|---|---|---|---|
| SYS01 toolchain/repo | Current checkout | Actual tool paths, baseline/import report | All tasks |
| SYS02 content | SYS01 + final source | Versioned 8/32/96/385 content and predicate catalog | SYS03/06, missions, UI, QA |
| SYS03 state/director | SYS02 + interface agreement | Snapshots, commands, receipts, ordered gates | Every interactive consumer |
| SYS04 simulation | Numeric source + SYS03 contract | Pure preview/commit results and profile deltas | Puzzles, Mission Table, resources |
| SYS05 interactions | SYS03 + current player | Focus/action/transaction adapter | Props, puzzles, missions |
| SYS06 dialogue/knowledge | SYS02/03 | Lines, origin, acquired knowledge, captions | Missions, UI, voice/cinematics |
| SYS07 saves | SYS02/03/04 schema | Atomic snapshots, restore/migrate/retry | Bootstrap, missions, UI |
| SYS08 world/roster/time | SYS03/04 | Locations, anchors, dated travel/care | Environment and mission owners |
| SYS09 player/contact | Existing player + asset sockets | Movement/hold/input integration | Every playable location |
| SYS10 face/hair | Current cast + SYS06/17 | Face/gaze/hair/speech presentation | Character/voice/cinematic owners |
| SYS11 toon/lighting | Current render stack + art lock | Shared material/lighting profiles | All ASSET and world tasks |
| SYS12 collision/navigation | World kit + player capsule | Traversable/interlocked geometry | Environments and missions |
| SYS13 science | Source registry + knowledge interface | Offline labels/provenance/data products | SCIENCE tasks, journal, puzzles |
| SYS14 upgrades/logistics | SYS03/04/07 | Conserved inventory and modifier profiles | UPGRADE tasks, later missions |
| SYS15 role modes | State/dialogue/UI contracts | Same-story input/information adapters | All mission/puzzle owners |
| SYS16 performance | Representative integrated features | Measured hardware-specific budgets | Every production owner |
| SYS17 audio/cinematics | SYS03/06 + playback tools | Buses, timed media, pause/skip | VOICE/MUSIC/SFX/CUTSCENE tasks |
| SYS18 records | Actual verified outputs | Current manifests, provenance, status | Coordinator and release |
| SYS19 bootstrap | Content/state/save/UI contracts | Real application main scene and launch | Chapter 1 and export |
| SYS20 biology | Source dates + SYS03/04/14 | Plant identities/stages/viability/care | Plants, gardening puzzles, missions |
| SYS21 companions | Player/world/state/dialogue | Physical anchors and source-safe support | Every crew scene |
| SYS22 puzzle host | State/interaction/UI/save contracts | Shared lifecycle, hints, result adapter | P01..P16 |
| SYS23 test harness | Toolchain + real fixtures | Portable ordered verification runner | Every owner and QA |

Interfaces can be designed together before implementation; avoid a circular wait by publishing one small agreed fixture and then replacing it with the real service. A fixture is not a claim that production integration passed.

## Content ownership

- `ASSET_<ID>` owns the model/scene/material/part/socket/version contract for one family. It does not own resource arithmetic or mission unlocks.
- `PUZZLE_Pxx` owns its rule/presentation adapter under SYS04/SYS22. Mission owners call it; they do not create another copy of the rules.
- `MISSION_EX_Mxxxx` owns exactly three final scene compositions and their gate bindings. SYS03 owns the order and receipt mechanism.
- `UI_xx` owns a Control/view binding and sends commands. SYS03/04 own state/results; UI never commits arithmetic by itself.
- `VOICE_`, `MUSIC_`, `SFX_` and `CUTSCENE_` own media and metadata. SYS17 owns playback, while the campaign owns event eligibility.
- `SCIENCE_` owns one bounded evidence artifact. SYS13 owns common science import/labels; knowledge controls acquired visibility.
- `UPGRADE_` owns one pair's data/appearance/test packet under SYS14; `ENDING_` owns closure/predicate binding under simulation/director/outcome UI.
- `ANIMATION_` owns contact-complete motion content and source clips. SYS09 owns blending/input and the prop artist owns physical sockets.
- QA records independent evidence. It may propose a fix but must not silently redefine canon or approve an unexecuted test.

## Mandatory mission chain

For each chapter, `EX-Mxx01 → EX-Mxx02 → EX-Mxx03 → EX-Mxx04`, with three consecutive scenes per mission. The next chapter's first mission requires the previous chapter's fourth mission and its actual final narrative gate.

| Chapter | Missions | Final scenes | Puzzle services | Key downstream contract |
|---|---|---|---|---|
|1 Night One|EX-M0101..0104|EX-CH01-S01..S12|P01/P02|Successful Bloom, stored message, Tarabud; loss requires supported retry|
|2 Be the Bee|EX-M0201..0204|EX-CH02-S01..S12|P03/P04|Compatible pollen/care, archive clue, immediate quake hand off|
|3 Moon quake|EX-M0301..0304|EX-CH03-S01..S12|P05/P06|Safe leak/annex,42=12+30, generations/map|
|4 Into the Cold Trap|EX-M0401..0404|EX-CH04-S01..S12|P07/P08|Two field/twohome, sealed vault 12, scheduled December arrival|
|5 Shooting Stars|EX-M0501..0504|EX-CH05-S01..S12|P09/P10|Five occupants, consented Noor reveal, cotton 1/stored 11|
|6 The Red Ring|EX-M0601..0604|EX-CH06-S01..S12|P11/P12|Five-segment plan, qualified eclipse, safe F2 recovery|
|7 The Great Storm|EX-M0701..0704|EX-CH07-S01..S12|P13/P14|Five-person storm, local-vs-Earth failure, required preparation|
|8 The Lighthouse|EX-M0801..0804|EX-CH08-S01..S12|P15/P16|51-hour roundtrip, both links, live Noor, established garden/credits|

The [coverage matrix](99_COVERAGE_MATRIX.md) links every actual mission file and its exact scenes. Use source predicates for progression; a vague `chapter_done` or watched movie cannot replace these checks.

## Parallel work rules

1. Record owned paths before starting. Shared system files have one editor at a time.
2. Room geometry, dialogue/audio preparation, approved-asset finishing and bounded UI components can proceed independently once their contracts are frozen.
3. Use existing approved sheets/voices where their authorization applies. New approval requirements attach to the exact new design/spend; they do not block unrelated ready tasks.
4. Integrate changes in dependency order into a run n able Chapter 1 slice, then the remaining campaign. Preserve a known-good build checkpoint and user changes.
5. Every handoff includes exact service/resource/part names, input/output examples, tested revision and current blockers. Do not label an upstream stub as production-ready.
