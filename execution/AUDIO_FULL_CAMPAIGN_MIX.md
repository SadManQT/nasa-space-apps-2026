# AUDIO-MIX — Full-campaign voice, music, SFX and caption integration

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Audio integration.**



## Assignment

Integrate all assigned voice groups,12 score cues,35 SFX and cutscene audio into a coherent complete campaign mix.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [production/audio/vo_lines.csv](../production/audio/vo_lines.csv)
- [production/audio/music_cues.csv](../production/audio/music_cues.csv)
- [production/audio/sfx_list.csv](../production/audio/sfx_list.csv)
- [game-design/15_AUDIO_AND_MUSIC_DIRECTION.md](../game-design/15_AUDIO_AND_MUSIC_DIRECTION.md)


## Ownership and dependencies

Own only this task's named implementation/content and its tests/evidence. Coordinate any shared-file change with the responsible SYS owner before editing.

SYS06/SYS10/SYS17; VOICE_*, MUSIC_*, SFX_* tasks; all owning missions/cutscenes.


## Detailed work sequence

1. Reconcile all 385 voice rows to actual delivery/takes/text-only messages,12 cuesand 35 effects; reuse existing 3 cutscene mixes and 12 voice files where valid.
2. Set voice/music/effects/UI buses and existing ducking/dynamic range priorities under SYS17.
3. Publish line/cue/event timings, origin processing, caption and visible face cue alignment without duplicated outputs.
4. Listen through representative quiet, planning, storm, rover, archive, reveal, eclipse and finale cases; check names, intelligibility and meaningful silence.
5. Runmute/headphone optional/low volume/caption/pause skip load cases; ensure text alone can finish the whole campaign.
6. Produce final audio manifest, evidence and runtime package without claiming unfinished takes are complete.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- All active audio events resolve or fallback honestly.
- No identity/reveal/date/source error in voice/caption treatment.
- Mixes are auditioned and measured with documented methods, not certified from planned numbers alone.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
