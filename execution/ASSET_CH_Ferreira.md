# CH_Ferreira — CH_Ferreira

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Asset family.**



## Assignment

Finish/verify `CH_Ferreira` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [production/ASSET_REGISTRY.csv](../production/ASSET_REGISTRY.csv)
- [production/ART_BIBLE.md](../production/ART_BIBLE.md)
- [production/review/codex_readiness_report.md](../production/review/codex_readiness_report.md)
- [game-design/14_ASSET_PRODUCTION_LIST.md](../game-design/14_ASSET_PRODUCTION_LIST.md)
- Current runtime file: `game/assets/characters/CH_Ferreira/CH_Ferreira.glb`. Production editable sources may be ignored/not present on this host; inspect rather than assume.


## Ownership and dependencies

Own `CH_Ferreira` source/runtime asset family, variants, metadata and evidence. Coordinate shared kit/material/character changes with the responsible SYS owner; consumers own campaign logic. Do not edit unrelated models.

Core rendering/import conventions and the owning mission/world interaction contract. Existing geometry may be reused immediately; a genuinely new approved design follows the documented concept/credit gate.


## Detailed work sequence

1. Inspect the current binary/source, approved concept and owning scene requirements. Determine the exact missing function, style state or quality defect; preserve the known-good version until the replacement passes.
2. For a 3 D deliverable, establish size/pivot, texture/geometry budget, UV0/normals/tangents, separate material slots, collision, moving child parts and required grip/interaction anchors with the consuming engineer. Add UV2/light map or LOD data when the agreed rendering/import pipeline requires it. Publish names and import settings before scene integration. For a portrait/UI-only deliverable, publish its texture, layout, licensing and runtime binding contract instead.
3. For an installed full body, inspect approved face/height/silhouette, clip names, bone mappings, patch placement, fingers/shoulders/feet and face atlas layers. Use current renderer/runtime; do not overwrite the character merely because a historical row calls it planned.
4. For Rao/Noor, inspect the existing 3 screen portraits first. Build the missing screen/talking/background state only; preserve Earth-only presence and Noor knowledge/live voice gates. For duty/EVA variants, fit the current body and maintain distinct role silhouette.
5. Where a genuinely new design is needed, prepare matching A-pose multi view/concept sheets and obtain the exact required approval before credit-consuming model generation. Use existing authorized tools/credits; log prompts and results.
6. Validate neutral/idle/walk/run/turn/hold/talk and actual prop contacts, including repeat setup, camera distance, pause and speech fallback. Restore Kai/Meibrow exceptions and Meihair rig as applicable.
7. Install only an approved passing build through the existing source/runtime pipeline; rerun affected player/face/asset checks and update current manifest fields, not historical source snapshots.


## Task-specific source and implementation detail

### Current checkpoint

- Registry identity: `CH_Ferreira`; recorded status `verified`; category `characters`.
- Source trace: `concept/turnarounds/ferreira/views`
- Source notes: commander (gold); baked name-tag letters painted out after clean-up: tools/blank_texture_region.py <glb> 830 549 882 564 --res 1600; Meshy rig (24 bones) + 25 clips, see production/models/meshy/ and tools/assemble_character.py
- Inspected binary metadata: `{"binary": true, "bytes": 15849444, "bones": 65, "clips": 44, "triangles": 57965, "sha256": "d69e6381cb85d65bb8ae3d001b1d62004a3230568ee31c07eb20d6bb7345f951"}`.
- Historical registry size/bone/clip fields can be stale. Use current handbook heights and the actual 65/68 bone 44 clip build; do not restore old 50k/24 bone specifications.

### Reference/generation brief (use only if a new or revised asset is actually required)

Approved Last Light Academy anime/cel character or outfit reference for CH_Ferreira. Adult human proportions, current approved identity and height, navy duty coverall or specifically required fitted EVA variant, clear role silhouette, correct Bangladesh LEFT-sleeve flag and Aurora right-side patches. Match the existing approved face and hair; stable A-pose in every view on flat neutral background. Face/eye/mouth runtime layers remain separate. Inspect current concept first; this prompt does not authorize spending before a missing design approval.

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
- No extra limbs, claw hands, backward palms, shoulder shrug/hip-forward regression, broken patches or face seams.
- Current approved base characters retain 44 clips and expected 65/68 bones unless a documented approved pipeline change is required.
- Screen characters never spawn physically at Aurora or expose a future identity.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
