# SFX_DOOR_LATCH — Interior door latch

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Sound effect.**



## Assignment

Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [production/audio/sfx_list.csv](../production/audio/sfx_list.csv)
- [game-design/15_AUDIO_AND_MUSIC_DIRECTION.md](../game-design/15_AUDIO_AND_MUSIC_DIRECTION.md)
- [production/ART_BIBLE.md](../production/ART_BIBLE.md)
- The owning interactable/location/scene and its actual trigger state.


## Ownership and dependencies

Own this effect'ssource/runtime variants, caption event mapping and metadata. Shared bus/playback code is SYS17 owned.

Owning interaction/world event and SYS17 audio interface; source art/physics context.


## Detailed work sequence

1. Inspect source first scene, event caption, loop and planned runtime path; locate the actual physics/listener context.
2. Define interior, cabin, suit/contact or UI perspective. Exterior vacuum does not carry wind, engine boom or ambient explosions.
3. Record/generate authorized clean wav masters and needed normal/low power/fault or partial variants; avoid musical or voice contamination.
4. Edit transients/tails, seamless loop where applicable, clear levels and variation without startling or humiliating error buzzers.
5. Bind one validated state change to one audio event and the corresponding caption; do not spam one alarm per every frame or play new information during pause.
6. Test mute, low volume, ducking, dynamic range, pause/save/load and repeated interaction; export project-supported runtime OGG/WAV and metadata.


## Task-specific source and implementation detail

### Exact SFXCSV contract

- **id:** SFX_DOOR_LATCH
- **description:** Interior door latch
- **loop:** no
- **caption:**
- **first_scenes:** EX-CH01-S02
- **game_file:** game/assets/audio/sfx/SFX_DOOR_LATCH.ogg
- **status:** todo

### Generator/recording brief

Create the described discrete sound or loop in the specified perspective, clean and isolated, with editable tail/loop markers. Match a grounded spacecraft/habitat instrument or physical tool event rather than cinematic magic. Supply normal/alternative versions only where the source event needs them; every meaningful hazard has readable caption parity.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- The source event has a matching caption/textcue and remains understandable on mute.
- Physical listening context and lunar vacuum rules are correct.
- No duplicate/stuck loop, harsh peak or essential voice masking in context.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
