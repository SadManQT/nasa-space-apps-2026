# UI13 — Outcome

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Godot UI.**



## Assignment

Implement the Outcome screen/component as a live, accessible GodotControl interface connected to the shared campaign.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [game-design/13_UI_UX_DESIGN.md](../game-design/13_UI_UX_DESIGN.md)
- [production/ART_BIBLE.md](../production/ART_BIBLE.md)
- [game/project.godot](../game/project.godot)
- The current UI_Kit asset prompt, actual SYS service APIs and the owning final mission scene; resolve equivalent existing components before adding one.


## Ownership and dependencies

Own the `Outcome` Control scene/controller, its view model binding and tests under the agreed `game/scenes/ui/` / `game/scripts/ui/` convention. Theme and shared state owners approve common-file changes.

SYS02/03/05/06/07, shared UI_Kit/theme, and the owning mission/puzzle/audio services appropriate to this screen.


## Detailed work sequence

1. Inspect the shared theme, UI_Kit, source contract and actual caller state; declare controlled inputs, display fields and outgoing commands.
2. Build readable English layout with role icon plus name, navy/ivory/gold tokens, correct focus order and controller/keyboard navigation.
3. Implement normal/empty/loading/disabled/blocked/error/confirmed states, with a visible reason for any gated action.
4. Bind displayed values and previews to shared state; on confirmation send one versioned command, never mutate resource arithmetic in the Control.
5. Support 150%text/reflow, caption-safe composition,44 px minimum targets, non colour cues, back/cancel/focus restore and pause-safe reading.
6. Gate future identities/evidence and internal debug fields; show current radio origin/location/scenario qualifiers consistently.
7. Test every edge case quoted below, duplicate click, reopened modal, save/load, language-independent English labels and assist settings.
8. Integrate the screen in an actual mission/boot flow and provide screenshots/interaction evidence at agreed resolutions.


## Task-specific source and implementation detail

### Exact source screen contract

**Layout/content:** Named local ending, crew/base/plant outcomes, decision timeline, Retry/Review

**Behaviour/feedback:** Golden/Bloom can continue; Lost/Stopped require retry to advance campaign

**Exit/edge case:** No next chapter unlocked by failure; no shaming grade

### Current overrides and review

- English only. Older Bangla shaping/localization requirements do not authorize Bangla script in runtime.
- The complete campaign uses 32 missions/96 scenes, not the legacy structure.
- No overlays expose a raw internal flag as a player objective.
- No essential instruction is baked into a 3 D texture.
- Source dimensions/contrast are targets to test, not pre-certified measurements.
- For Mission Table/puzzle HUD, show all known costs and distinguish unknown future events; prediction and commit share the same simulation.
- For journal/discovery/credits, preserve acquired knowledge, science provenance and current Noor reveal/MARS closure gates.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- Source layout/behaviour/edge case contracts below are implemented with current English-only override.
- All essential information and actions remain available by keyboard/controller and large-text/mute settings.
- UI preview and committed world results agree; modal input cannot leak into movement or physical commit.
- Back/cancel/reopen/load do not duplicate costs, lose focus or reveal future content.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
