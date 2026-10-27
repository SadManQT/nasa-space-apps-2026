# QA05 — Accessible controls, reading, modes and learner UX

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Effects / independent QA / release.**



## Assignment

Verify whole-story access with keyboard/controller, mute, large-text, reduced motion and timer assistance.

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

1. Complete Chapter 1 and representative each later mechanic using keyboard only/controller only and assisted inputs.
2. Inspect focus order, modal capture, back/cancel, caption parity, text size 150%, colour-independent clues and target size.
3. Verify Solo/Family/Cadet/Engineer/Class same fictional crew, all role facts and same ending access.
4. Observe junior learners stating current objective, predicting a consequence and explaining evidence without coaching all answers.
5. Record real resolution/device/hardware conditions and issues; iterate actual UI and required content without inventing success metrics.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- No essential information depends solely on audio/colour/speed/pixel precision.
- No assistance penalty or compulsory timer blocks story.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
