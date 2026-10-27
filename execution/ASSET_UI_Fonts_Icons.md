# UI_Fonts_Icons — UI_Fonts_Icons

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Asset family.**



## Assignment

Finish the shared UI art/widget kit as an engine-integrated English-only system used by the 16 screen prompts.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [production/ASSET_REGISTRY.csv](../production/ASSET_REGISTRY.csv)
- [production/ART_BIBLE.md](../production/ART_BIBLE.md)
- [production/review/codex_readiness_report.md](../production/review/codex_readiness_report.md)
- [game-design/14_ASSET_PRODUCTION_LIST.md](../game-design/14_ASSET_PRODUCTION_LIST.md)
- [production/manifest/planned_assets.csv](../production/manifest/planned_assets.csv)


## Ownership and dependencies

Own `UI_Fonts_Icons` source/runtime asset family, variants, metadata and evidence. Coordinate shared kit/material/character changes with the responsible SYS owner; consumers own campaign logic. Do not edit unrelated models.

Core rendering/import conventions and the owning mission/world interaction contract. Existing geometry may be reused immediately; a genuinely new approved design follows the documented concept/credit gate.


## Detailed work sequence

1. Inspect the current binary/source, approved concept and owning scene requirements. Determine the exact missing function, style state or quality defect; preserve the known-good version until the replacement passes.
2. For a 3 D deliverable, establish size/pivot, texture/geometry budget, UV0/normals/tangents, separate material slots, collision, moving child parts and required grip/interaction anchors with the consuming engineer. Add UV2/light map or LOD data when the agreed rendering/import pipeline requires it. Publish names and import settings before scene integration. For a portrait/UI-only deliverable, publish its texture, layout, licensing and runtime binding contract instead.
3. Read the 16 UI_* tasks and agree theme/fonts/spacing/focus/control glyph/contrast tokens with their owners.
4. Deliver scalable editable vector icons, word labels, panel states, source chips, role markers, resource widget s, diagrams and empty/error/loading/disabled variants.
5. Separate illustrations/styles from live state; numeric forecasts and acquired journal content are supplied by shared services.
6. Support keyboard/controller focus, at least 44 px interaction targets, tested 150%text reflow and caption-safe layouts.
7. Implement reusable GodotControl/theme resources rather than a disconnected marketing webpage.
8. Test the kit in an actual mission/hud/dialogue/planning screen and hand off exact components and appearance states.


## Task-specific source and implementation detail

### Current checkpoint

- Registry identity: `UI_Fonts_Icons`; recorded status `required-not-registered`; category `ui`.
- Source trace: `Additional execution family derived from current handbook and final scene actions`
- Source notes: Licensed English font files, numeral/unit glyphs, scalable role/evidence/control icons and tested large-text theme; distinct from baked texture labels.
- Reconciliation: Additional required family derived from the current handbook/scene actions; not an existing registry row. Register and scope exact child parts before claiming delivery. Licensed English font files, numeral/unit glyphs, scalable role/evidence/control icons and tested large-text theme; distinct from baked texture labels.
- First scene/dependency trace: EX-CH01-S01; intended build method: Reuse-first kit/state work under the approved pipeline.

### Reference/generation brief (use only if a new or revised asset is actually required)

Editable Last Light Academy anime mission UI kit: navy backgrounds, warm ivory text, mustard gold accent, role icon plus name, clear resource and forecast diagrams. Adult-space hardware visuals with junior learner readability; English live text separate from art; scalable focus/hover/pressed/disabled/error states and caption-safe compositions.

### Source and runtime handoff

- Preserve editable source, runtime GLB/scene, embedded or project-policy textures, approved dimensions, material slots, collision, named pivots/sockets and explicit state variants.
- Use existing `production/tools/` helpers and `game/tools/verify_assets.gd` after inspecting their current arguments; historical tool paths/versions are not live facts.
- New character/hero prop designs require the exact 2 D approval before Tripo spending; asset reuse and read-only validation do not create an approval request.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- Actual runtime import and source/provenance are verified; a filename or download-complete message alone is insufficient.
- Size/pivot/bounds/materials match current spec; collisions, moving parts and interaction sockets are demonstrated separately.
- Review the correct anime style in front/side/back and the owning gameplay context; record what was actually inspected.
- Current English-only decision overrides older Bangla UI requirements.
- No essential text baked into texture or colour-only clue.
- Each UI owner consumes the same theme/state conventions.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
