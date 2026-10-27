# VH_Zero Ascent — VH_Zero Ascent

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Asset family.**



## Assignment

Finish/verify `VH_ZeroAscent` for its actual transport/screen role and safe scene interaction.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [production/ASSET_REGISTRY.csv](../production/ASSET_REGISTRY.csv)
- [production/ART_BIBLE.md](../production/ART_BIBLE.md)
- [production/review/codex_readiness_report.md](../production/review/codex_readiness_report.md)
- [game-design/14_ASSET_PRODUCTION_LIST.md](../game-design/14_ASSET_PRODUCTION_LIST.md)
- Current runtime file: `game/assets/vehicles/VH_ZeroAscent/VH_ZeroAscent.glb`. Production editable sources may be ignored/not present on this host; inspect rather than assume.


## Ownership and dependencies

Own `VH_ZeroAscent` source/runtime asset family, variants, metadata and evidence. Coordinate shared kit/material/character changes with the responsible SYS owner; consumers own campaign logic. Do not edit unrelated models.

Core rendering/import conventions and the owning mission/world interaction contract. Existing geometry may be reused immediately; a genuinely new approved design follows the documented concept/credit gate.


## Detailed work sequence

1. Inspect the current binary/source, approved concept and owning scene requirements. Determine the exact missing function, style state or quality defect; preserve the known-good version until the replacement passes.
2. For a 3 D deliverable, establish size/pivot, texture/geometry budget, UV0/normals/tangents, separate material slots, collision, moving child parts and required grip/interaction anchors with the consuming engineer. Add UV2/light map or LOD data when the agreed rendering/import pipeline requires it. Publish names and import settings before scene integration. For a portrait/UI-only deliverable, publish its texture, layout, licensing and runtime binding contract instead.
3. Preserve cabin pressure, entry/exit clearances, seat/hand/feet anchors and clear cargo/repair mounts if players interact with this vehicle.
4. Expose wheel/hatch/light/camera/contact state sub parts and appropriate collision; keep drive/cruise/boarding logic owned by the runtime modules.
5. Tie occupants and contents to canonical roster and manifest; do not add unseen operators or consume provisions without ledger receipts.
6. For field travel, use authored survey segments/meaningful stops and explicit dated cruise; the full 51 hour final trip is fictional time, not forced waiting.
7. Test boarded/stationary/moving/braked/EVA/load/save states, camera motion assistance and contact/cabin sound.
8. Review in the correct anime world, preserve black sky/ballistic dust and provide the exact role/socket/size contract.


## Task-specific source and implementation detail

### Current checkpoint

- Registry identity: `VH_ZeroAscent`; recorded status `verified`; category `vehicles`.
- Source trace: `models/reuse/lunar_module.glb`
- Source notes: Expedition Zero ascent vehicle (archive images)
- Inspected binary metadata: `{"binary": true, "bytes": 4534364, "bones": 0, "clips": 0, "triangles": 39999, "sha256": "0067464d0a7ab2f47898251a534db3ca928345cf50907eb8af6df37fe12aa074"}`.
- Existing dimensional/budget row: `height 9.00 m, 40000 tris, 2048 px`. Confirm current manifest and permitted gate tolerance before changing it.

### Vehicle role

2034 safe ascent/evacuation evidence asset; all crew returned, no abandoned crew mate or early Noor identity.

### Reference/generation brief (use only if a new or revised asset is actually required)

Last Light Academy VH_Zero Ascent, grounded utilitarian lunar vehicle in the approved anime/cel visual system. Follow the exact vehicle role quoted here, adult scale and existing silhouette. Functional cabin/seat/hatch/cargo/service geometry where required, readable controls using separate live UI surfaces, restrained white/navy/orange hardware and correct patches. Separate movable parts/anchors; physical lunar wheels/feet on r egoli th, black sky, clean contact shadows.

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
- Occupants, supplies, route/time and return reserve match the owning chapter.
- No wheel wind, airborne vacuum engine boom or unsafe un press uri sed cabin.
- No static vehicle model is labelled completed driving/boarding gameplay.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
