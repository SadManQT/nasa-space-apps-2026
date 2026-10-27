# VFX01 — Lunar exterior effects and restrained hazards

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Effects / independent QA / release.**



## Assignment

Create grounded lunar visual feedback for footsteps, wheels, moon quake/impact and hardware events.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md)
- [full-game-story/story-data.json](../full-game-story/story-data.json)
- [production/review/codex_readiness_report.md](../production/review/codex_readiness_report.md)
- [game-design/20_TESTING_AND_ACCEPTANCE.md](../game-design/20_TESTING_AND_ACCEPTANCE.md)
- [production/ART_BIBLE.md](../production/ART_BIBLE.md)


## Ownership and dependencies

Own only this task's named implementation/content and its tests/evidence. Coordinate any shared-file change with the responsible SYS owner before editing.

Run only when its actual inputs/dependent features are available. Independent review does not silently rewrite canon or mark untested features complete.


## Detailed work sequence

1. Use black sky, hardlow Sun and ballistic r egoli th with no cloud/fog/wind/billowing dust.
2. Represent particles and contact responses at correct grounded lunar scale; keep actual radiation instruments only.
3. Make quake/impact states readable with caption/optional shake; reduced motion preserves all information.
4. Bind one event to the validated world state and test pause/reload/quality settings/performance.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- No atmospheric meteor trail, vacuum shockwave or visible zaps.
- No effect conceals required UI, hands, plant or pressure boundary.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
