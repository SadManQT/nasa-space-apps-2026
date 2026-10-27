# CS-15 — "Hello, Aurora. This is Noor." Cuts between the summit cabin, Aurora and the Dhaka rooftop

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Final cutscene.**



## Assignment

Finish/integrate `CS-15` for `EX-CH08-S10` using current approved anime production, preserving player agency and exact narrative facts.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md)
- [full-game-story/STORY_FULL.md](../full-game-story/STORY_FULL.md)
- [production/cutscenes/shots.csv](../production/cutscenes/shots.csv)
- [production/tools/compose_cutscene.py](../production/tools/compose_cutscene.py)
- [game-design/12_CINEMATIC_DIRECTION.md](../game-design/12_CINEMATIC_DIRECTION.md)
- Current v 7 source/master/OGV files and the owning mission prompt; legacy cinematic text is subordinate to final canon.


## Ownership and dependencies

Own this cutscene's source frames/shots/spec/master/runtime media and its cue integration fixture. Campaign/puzzle gates and shared playback code remain owned by their modules.

Approved current cast/world presentation; owning mission `EX-CH08-S10`; SYS06 dialogue; SYS17 audio/cinematic runtime; appropriate VOICE/MUSIC/SFX tasks. Check existing authorization before generation.


## Detailed work sequence

1. Inspect current runtime/master/spec; retain the already passing material in CS01..03; inspect and complete their specifically documented fallback-motion or integration gaps instead of regenerating whole cuts. Identify exact missing integration or quality defect.
2. Write a shot/beat plan from the owning final scene: correct participants, physical positions, camera, source of the voice, reveal state and the world operation that remains interactive.
3. Reuse approved 3 D references/start frames; verify any genuinely new hero/character concept approval before credit spend. Check live tool/model/cost availability and log generations.
4. Create/review source frames and motion for identity/limbs/hands/patches/plant biology/lighting/science; use in-engine performance where appropriate to the interactive beat.
5. Record/render exact voices separately, edit music/sound/captions with clear origin and intelligibility; lip-sync visible mouths or stage a justified cutaway.
6. Assemble master with source JSON/captions, convert to verified Theora OGV and test actual playback/audio on the export target.
7. Bind the film at its declared event/predicate; pause/skip/resume safely and restore camera/focus/NPC anchors without completing an un performed puzzle.
8. Review start/middle/end plus moving critical moments, verify exact line/reveal/timing and hand off source/runtime/provenance/test evidence.


## Task-specific source and implementation detail

### Cutscene brief

- ID:`CS-15`; final scene:`EX-CH08-S10`; legacy: CIN-13.
- Beat:"Hello, Aurora. This is Noor." Cuts between the summit cabin, Aurora and the Dhaka rooftop
- Historical duration: 35–50 s; current anime edition uses longer~40–50 second cuts where approved. Reuse exact approved timing for CS01..03 and agree any new timing against story/actions; do not pad play time with film.
- Proposed source production method: See dance (rooftop fully generated) plus in-engine. Current tool availability and permissions must be checked.
- Existing runtime files: No current runtime file observed at preparation.
- Specific review/backlog: No current anime runtime cut was observed in the preparation snapshot; inspect for later delivery before generating.

### Exact owning-scene dialogue

- `EX-CH08-S10-L01` Noor (first live Earth voice): Hello, Aurora. This is Noor.
- `EX-CH08-S10-L02` Mei: We kept a place for you.
- `EX-CH08-S10-L03` Ferreira: You brought us the seeds.
- `EX-CH08-S10-L04` Amara: The garden has more than one gardener.

### World gate remains separate

Both voices and telemetry acknowledged; Noor's first live call complete; return starts 03:00.

### Direction and science

Maintain current anime faces, outfits, heights, role colours and patches; correct physical/remote/archive participants; black lunar sky; no atmosphere, visible radiation or vacuum airborne sound. Store readable UI/captions as edited/runtime layers. New Noor identity or voice cannot appear before its gate.

### Source assembly

Existing anime examples:`production/cutscenes/v7/src/CS-01.json`, CS-02.json, CS-03.json. Inspect the actual schema and`compose_cutscene.py`before extending it. Publish source frame/shot/voice/music/caption metadata and provenance. Runtime OGV may use existing Godot Movie Maker pipeline when FF mpeg lacks Theora; discover actual host tools first.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- Current anime identity/science/cast correct; no old-style master is automatically approved.
- Caption/VO line IDs match the owning scene and evidence origin.
- Runtime OGV plays with correct audio and supported skip/pause/load behaviour.
- Cinematic acknowledgement cannot unlock missing safety/world predicates.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
