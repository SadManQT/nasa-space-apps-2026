# PR_Battery Jar — PR_Battery Jar

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Asset family.**



## Assignment

Finish/verify `PR_BatteryJar` as a reusable story-correct interactable prop.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [production/ASSET_REGISTRY.csv](../production/ASSET_REGISTRY.csv)
- [production/ART_BIBLE.md](../production/ART_BIBLE.md)
- [production/review/codex_readiness_report.md](../production/review/codex_readiness_report.md)
- [game-design/14_ASSET_PRODUCTION_LIST.md](../game-design/14_ASSET_PRODUCTION_LIST.md)
- Current runtime file: `game/assets/props/PR_BatteryJar/PR_BatteryJar.glb`. Production editable sources may be ignored/not present on this host; inspect rather than assume.


## Ownership and dependencies

Own `PR_BatteryJar` source/runtime asset family, variants, metadata and evidence. Coordinate shared kit/material/character changes with the responsible SYS owner; consumers own campaign logic. Do not edit unrelated models.

Core rendering/import conventions and the owning mission/world interaction contract. Existing geometry may be reused immediately; a genuinely new approved design follows the documented concept/credit gate.


## Detailed work sequence

1. Inspect the current binary/source, approved concept and owning scene requirements. Determine the exact missing function, style state or quality defect; preserve the known-good version until the replacement passes.
2. For a 3 D deliverable, establish size/pivot, texture/geometry budget, UV0/normals/tangents, separate material slots, collision, moving child parts and required grip/interaction anchors with the consuming engineer. Add UV2/light map or LOD data when the agreed rendering/import pipeline requires it. Publish names and import settings before scene integration. For a portrait/UI-only deliverable, publish its texture, layout, licensing and runtime binding contract instead.
3. Readable shared battery/energy reservoir visual tied to E/cap, not a second currency. Establish a usable silhouette, access direction, handle/control arrangement and separate live-screen area where applicable.
4. Expose every required state and moving child: Normal, preview delta, capacity/spill, low reserve, blackout response. Publish the state→part/material/animation mapping to the interaction owner.
5. Implement or coordinate the physical focus/collider/socket fixture and accessible steps. The shared state/simulation owns resource/knowledge/inventory mutations.
6. Check the constraint: Live values come from the simulation; no baked readout or free refill. Exercise valid, invalid, cancelled, partial and reloaded states in the consuming scene.
7. Review current anime appearance, hand/tool contacts, text readability and world placement; fix local geometry/material parts before deciding regeneration is necessary.
8. Deliver source/runtime, exports, metadata, state/contact demo and update registry/provenance only after the actual task gate passes.


## Task-specific source and implementation detail

### Current checkpoint

- Registry identity: `PR_BatteryJar`; recorded status `verified`; category `props`.
- Source trace: `models/reuse/energy_capsule.glb`
- Source notes: Battery jar with sun-drops (A-12)
- Inspected binary metadata: `{"binary": true, "bytes": 4362124, "bones": 0, "clips": 0, "triangles": 19999, "sha256": "82cee279d5274eb7c727b76e424ce709982b896d952f12b85926607284be9c65"}`.
- Existing dimensional/budget row: `height 1.40 m, 20000 tris, 2048 px`. Confirm current manifest and permitted gate tolerance before changing it.

### Prop identity and functional state contract

- Purpose: Readable shared battery/energy reservoir visual tied to E/cap, not a second currency.
- Required states: Normal, preview delta, capacity/spill, low reserve, blackout response.
- Continuity/engineering boundary: Live values come from the simulation; no baked readout or free refill.

### Reference/generation brief (use only if a new or revised asset is actually required)

One production-reference PR_Battery Jar for Last Light Academy, approved anime/cel hardware style on neutral background, adult metre scale and the documented size. Readable shared battery/energy reservoir visual tied to E/cap, not a second currency. Design usable handles, clear controls and separate functional parts. Surface palette white/navy/grey with role/hazard accents; English text and readouts are separate live UI, with no NASA marks. Show the complete object in a clean three quarter view and provide needed orthographic/detail views for model cleanup.

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
- All named functional states/parts/anchors are usable in the owning mission.
- Baked fake text/readings are replaced by live UI or verified authored documents.
- The prop cannot duplicate resource/inventory/knowledge transactions.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
