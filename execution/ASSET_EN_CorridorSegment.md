# EN_Corridor Segment — EN_Corridor Segment

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Asset family.**



## Assignment

Assemble/finish `EN_CorridorSegment` as the correct reusable world space or modular piece, with playable routes and current anime presentation.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [production/ASSET_REGISTRY.csv](../production/ASSET_REGISTRY.csv)
- [production/ART_BIBLE.md](../production/ART_BIBLE.md)
- [production/review/codex_readiness_report.md](../production/review/codex_readiness_report.md)
- [game-design/14_ASSET_PRODUCTION_LIST.md](../game-design/14_ASSET_PRODUCTION_LIST.md)
- Current runtime file: `game/assets/environment/EN_CorridorSegment/EN_CorridorSegment.glb`. Production editable sources may be ignored/not present on this host; inspect rather than assume.


## Ownership and dependencies

Own `EN_CorridorSegment` source/runtime asset family, variants, metadata and evidence. Coordinate shared kit/material/character changes with the responsible SYS owner; consumers own campaign logic. Do not edit unrelated models.

Core rendering/import conventions and the owning mission/world interaction contract. Existing geometry may be reused immediately; a genuinely new approved design follows the documented concept/credit gate.


## Detailed work sequence

1. Inspect the current binary/source, approved concept and owning scene requirements. Determine the exact missing function, style state or quality defect; preserve the known-good version until the replacement passes.
2. For a 3 D deliverable, establish size/pivot, texture/geometry budget, UV0/normals/tangents, separate material slots, collision, moving child parts and required grip/interaction anchors with the consuming engineer. Add UV2/light map or LOD data when the agreed rendering/import pipeline requires it. Publish names and import settings before scene integration. For a portrait/UI-only deliverable, publish its texture, layout, licensing and runtime binding contract instead.
3. Block out the canonical footprint, connected locations, player/companion anchors and interaction reach before decorative modelling. Keep camera/door/aisle clearance for all five adult scales.
4. Reuse existing corridor/exterior/solar/prop meshes. Build a coherent snap kit, floor/ceiling/wall/door materials, motivated lights and collision/navigation; do not make 49 imported props stand in for assembled rooms.
5. Place chapter-required machinery and live UI surfaces under the proper owners' asset/interaction contracts. Add stable entry/viewpoint/repair/safety anchors and preserve pressure boundaries.
6. Create the necessary day/dark/fault/occupied states without changing the physical layout or teleporting crew. Earth screen locations are staged backgrounds, not a new playable Earth map.
7. Traverse the route with player/camera/companion positions; test gates, door cancel, save/load and every required return path. Profile the full room lighting/material cost.
8. Handoff a usable scene set, adj ace n cy/anchor map, collision/navigation evidence and the exact asset/socket list consumed by missions.


## Task-specific source and implementation detail

### Current checkpoint

- Registry identity: `EN_CorridorSegment`; recorded status `verified`; category `environment`.
- Source trace: `models/reuse/space_tunnel.glb`
- Source notes: Corridor / airlock tube segment (A-11)
- Inspected binary metadata: `{"binary": true, "bytes": 3142132, "bones": 0, "clips": 0, "triangles": 19999, "sha256": "795e9592e0ac05dff6ab7e8caffcb6b65e4afddeffdc934b413e5a2b29acedb8"}`.
- Existing dimensional/budget row: `height 2.60 m, 20000 tris, 2048 px`. Confirm current manifest and permitted gate tolerance before changing it.

### Canonical LOC-01 source

## LOC-01 — Aurora commons / Mission Table

- **Narrative significance:** The expedition’s heart; uncertainty is discussed here.
- **Layout / appearance / landmarks:** 22×12 m common room; table at centre, Earth screen north, lockers west, galley east, greenhouse view south. Four seats become five after December.
- **Connected locations:** LOC-02,LOC-03,LOC-04,LOC-05.
- **Interactable objects:** Table, role plaques, charter, recorder dock, globe diagram, camera screen, dedication board.
- **NPC positions:** Present off-duty cadets use four table anchors; Ferreira screen before arrival, fifth seat after. Rao/Noor screen only.
- **Mission / scene usage:** SC-0101,SC-0105,SC-0203,SC-0206,SC-0502–05,SC-0603–04,SC-0701,SC-0705–06
- **Puzzles / environmental clues:** P-02,P-09,P-10,P-12; object scans enter acquired evidence only; decorative labels cannot prematurely identify Noor.
- **Exploration:** examine all listed props from the main path; no evidence hidden behind movable crates. Optional close inspection adds a journal image but never blocks progress.
- **Lighting / audio:** Warm practical lighting, fan bed, Earth a small low-angle presence; no constant dramatic music.
- **Unlock / traversal conditions:** Always after arrival; special panels unlock by mission.
- **Exit behavior:** return path stays open unless a visible pressure/radiation interlock is active; required companions rejoin at a safe anchor on exit. Use a labelled time card for cruise/airlock transitions, not invisible teleportation.

### Canonical LOC-02 source

## LOC-02 — Power and atmosphere service rooms

- **Narrative significance:** Makes invisible survival systems legible.
- **Layout / appearance / landmarks:** Two adjacent 6×5 m rooms off commons: power west, air east, protected trunk between; glass partitions allow supervision. No cable maze.
- **Connected locations:** LOC-01,LOC-04,LOC-07.
- **Interactable objects:** Battery jar, oxygen tank, electrolyser model, manual pressure taps, garden spur valve, F2 panel, hand light.
- **NPC positions:** Kai at west panel, Amara east; Rafi at safe-side clamp when assigned.
- **Mission / scene usage:** SC-0103,SC-0204–05,SC-0301–02,SC-0601–02,SC-0605
- **Puzzles / environmental clues:** P-04,P-05,P-11,P-12; object scans enter acquired evidence only; decorative labels cannot prematurely identify Noor.
- **Exploration:** examine all listed props from the main path; no evidence hidden behind movable crates. Optional close inspection adds a journal image but never blocks progress.
- **Lighting / audio:** Cool readable work light; equipment sounds differentiated but captions never require hearing them.
- **Unlock / traversal conditions:** Always; annex camera/hatch safing in active M-0301 may read leak_sealed_pending. Physical annex entry in the following mission requires committed leak_sealed and its pressure/suit checks.
- **Exit behavior:** return path stays open unless a visible pressure/radiation interlock is active; required companions rejoin at a safe anchor on exit. Use a labelled time card for cruise/airlock transitions, not invisible teleportation.

### Canonical LOC-03 source

## LOC-03 — Garden room and external Alo chamber

- **Narrative significance:** A test facility becomes a home and memorial.
- **Layout / appearance / landmarks:** 12×8 m room; indoor Tara bay left, external pressurised cassette beyond south viewing wall, quarantine glovebox right, seed archive near exit; 1.5 m clear aisles.
- **Connected locations:** LOC-01,LOC-05,LOC-07.
- **Interactable objects:** Alo/Tara ports, moisture probe, mature pods, counting tray, petal sleeve, lineage board, cotton cassette, vault glovebox.
- **NPC positions:** Mei at care bench; Amara beside monitor in harvest/finale; companions remain outside aisles.
- **Mission / scene usage:** All planting, pollination, harvest, vault-opening and final-garden scenes.
- **Puzzles / environmental clues:** P-01,P-03,P-06,P-08,P-15,P-16; object scans enter acquired evidence only; decorative labels cannot prematurely identify Noor.
- **Exploration:** examine all listed props from the main path; no evidence hidden behind movable crates. Optional close inspection adds a journal image but never blocks progress.
- **Lighting / audio:** Growth lamps warm magenta-white with neutral inspection mode; soft fans, water clicks. External flowers never in open vacuum.
- **Unlock / traversal conditions:** Always; harvest and vault tools gated by their mission.
- **Exit behavior:** return path stays open unless a visible pressure/radiation interlock is active; required companions rejoin at a safe anchor on exit. Use a labelled time card for cruise/airlock transitions, not invisible teleportation.

### Canonical LOC-05 source

## LOC-05 — Airlock and sealed transfer vestibule

- **Narrative significance:** Connects scientific touch with habitat safety.
- **Layout / appearance / landmarks:** 8×4 m double-door vestibule; suit lockers, bench, sealed carrier pass-through and glove-port access to Alo; independent pressure interlock.
- **Connected locations:** LOC-01,LOC-03,LOC-06.
- **Interactable objects:** Pressure controls, suit checks, pollen carrier, brush tips, door cycle.
- **NPC positions:** One active cadet at tools, companion at checklist; doors never trap an idle NPC.
- **Mission / scene usage:** SC-0202,SC-0401,SC-0501,SC-0801
- **Puzzles / environmental clues:** P-03 and generic EVA protocol.; object scans enter acquired evidence only; decorative labels cannot prematurely identify Noor.
- **Exploration:** examine all listed props from the main path; no evidence hidden behind movable crates. Optional close inspection adds a journal image but never blocks progress.
- **Lighting / audio:** Pump sound only while cycling; text states SEALED / EQUALISING / SAFE TO OPEN.
- **Unlock / traversal conditions:** Exterior access after suit/seal checks and current route safety pass; pollen pass-through available earlier.
- **Exit behavior:** return path stays open unless a visible pressure/radiation interlock is active; required companions rejoin at a safe anchor on exit. Use a labelled time card for cruise/airlock transitions, not invisible teleportation.

### Reference/generation brief (use only if a new or revised asset is actually required)

Last Light Academy EN_Corridor Segment environment concept and modular layout, coherent anime/cel treatment matching installed characters, grounded utilitarian lunar hardware, readable navy/ivory/orange/gold accents, metre-scale adult clearance. Use the canonical footprint and route adj ace n cy quoted in this task. Black lunar sky and hard low-sun shadows outside; motivated practical lighting and pressure-safe enclosures inside. Design functional doors, panels, aisles and interaction bays with editable layers and live-screen surfaces.

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
- All required entrances, exit locks, routes and anchors are traversable in context.
- No fog/haze/billowing dust or unsupported sky claim; local screen/rover/base viewpoints retain correct rosters.
- Imported modular pieces and a complete connected level are reported as different deliverables.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
