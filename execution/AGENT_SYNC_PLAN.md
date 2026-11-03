# Last Light Academy — agent synchronization plan

**Prepared:** 2026-11-02
**Role:** synchronization lead
**Scope:** coordination only. This file does not implement gameplay, shared runtime code, assets, audio, or UI. The existence of a prompt, proposed path, or planned handoff is never implementation evidence.

**Status (3 Nov 2026):** this plan coordinated the 2 Nov worker batch and is now history. That batch was integrated and pushed (`ff09cfd`): Godot 4.7.2 runs, the main scene boots the production campaign, and the Chapter 1–8 route fixtures pass. Coordination now runs through the team board: `production/plan/tasks.json` (readable as `production/plan/BOARD.html`), one task per "go next" as described in `production/plan/GO_NEXT.md`, with ownership in each task's *owns paths*. Status lives in `PRODUCTION_HANDBOOK.md` §10. Sections 2, 9 and 10 below describe the 2 Nov baseline before that batch.

## 1. Authority and baseline rule

- Canonical story: `full-game-story/STORY_FULL.md` and `full-game-story/story-data.json` — 8 chapters, 32 missions, 96 scenes, 385 dialogue lines, with IDs `EX-CHxx-Sxx` and `EX-Mxxxx`.
- Numeric authority: `game-design/08_PUZZLE_DESIGNS.md`, especially the P-02 appendix and P-13/P-14 upgrade/occupancy appendices.
- Runtime authority: current approved anime/cel characters and the newest dated entries in `HANDOFF.md` and `PRODUCTION_HANDBOOK.md`.
- Shared interfaces: `execution/03_SYSTEM_INTERFACES.md`. Its new module names are proposals until a real owner creates and tests them.
- Acceptance labels: use `present`, `structural-pass`, `functional-pass`, `visual-pass`, `learner-pass`, and `unverified` exactly as defined in `execution/05_ACCEPTANCE_AND_HANDOFF.md`.

The execution prompt pack, including `execution/99_COVERAGE_MATRIX.md` and its SYS/UI index, is a work specification. It does not prove that any task was executed.

## 2. Actual repository baseline

Checked from the repository root at `C:\Users\User\OneDrive\Desktop\Nasa Zonal\nasa-space-apps-2026`:

| Area | Actual evidence | Baseline status and consequence |
|---|---|---|
| Git | `HEAD=5f94bc0e8e6ffc49aea5a2ae36570b13d0bfc4c1`, commit `Add complete full-game execution prompt library`; `git status --short --branch` is clean on `main`. | `present`. The prompt documents reference `ca01433`, so every owner must recheck drift rather than assume that snapshot. |
| Engine configuration | `game/project.godot` declares Godot 4.7.2, Forward+, physics interpolation, and embedded glTF images. It has no `run/main_scene` and no autoload section. | Project metadata is `present`; launch flow is absent. Do not use a dev scene as the application entry. |
| Input map | `move_forward`, `move_back`, `move_left`, `move_right`, camera axes, `run`, `sprint`, and `interact` exist. There are no campaign/menu/pause/confirm/accessibility actions. | Player foundation is present; campaign input contract is not implemented. |
| Runtime geometry | 49 real `.glb` binaries under `game/assets/`: 5 characters, 7 plants, 31 props, 3 environment pieces, and 3 vehicles. They are not LFS pointer text files. | `present`. This is an asset inventory, not proof of collisions, sockets, movable parts, toon approval, or gameplay interaction. |
| Current cast | Independent GLB JSON inspection found 44 animations on every character; Kai, Amara, Rafi and Ferreira have 65 bones, Mei has 68. Runtime paths are `game/assets/characters/CH_*/CH_*.glb`. | `structural-pass` for the binary header/animation/bone inspection. Preserve these v7/v8 builds; do not regenerate the cast. |
| Runtime media | Three `.ogv` binaries exist: `CS-01_Arrival`, `CS-02_The_Horizon_Closes_One_Door`, and `CS-03_Alo_Needs_a_Friend`. Three portrait PNGs exist for Rao and Noor. There are zero runtime `.ogg`, `.wav`, `.mp3`, or other audio files under `game/`. | Cutscene files and portraits are `present`; playback integration and all audio are `unverified`/missing. The three OGVs do not prove all 18 current-style cutscenes are complete. |
| Scenes | Six `.tscn` files exist: player, locomotion test, asset showcase, anime look-dev, character look-dev, and character review. | `present` as dev/review foundation. No campaign room, mission, menu, or production route scene exists. |
| Scripts | 31 `.gd` files exist: 22 under `game/scripts/` and 9 under `game/tools/`. They cover player locomotion/holds/camera, character face/hair/lip-sync, toon materials, review, showcase, and asset checks. | Existing reviewed player/rendering code is reusable. No campaign state, content importer, simulation, interaction dispatcher, dialogue service, save service, world/roster service, UI family, audio runtime, or bootstrap service exists. |
| Asset gate | `game/tools/verify_assets.gd` exists, but the production gate and historical test results have not been rerun in this checkout. | Historical `49/49`, player, showcase, and review numbers remain historical evidence only. |
| Tool availability | `python 3.13.7` is discoverable. `godot`, `godot4`, and `blender` are not discoverable on `PATH` on this host. | Current Godot import, parser, headless tests, visual review, and export are `unverified`; this is the first blocker. |
| Stale text | `game/assets/README.md` still describes the older 78-bone layout, while the actual current cast and shared contract are 65/68 bones with 44 clips. | Treat current runtime files and dated handbook/shared contract as authoritative; record this drift before changing any manifest or README. |

### What is not in the actual tree

There is no `game/scripts/core/`, `simulation/`, `interactions/`, `dialogue/`, `save/`, `world/`, `audio/`, `cutscenes/`, `game/scenes/ui/`, or campaign resource tree. These are proposed ownership roots from the execution documents, not existing implementations. There is also no main scene, no bootable Chapter 1, no assembled Commons/Service Rooms/Garden/Safe Room route, and no full campaign media package.

## 3. Ownership fence for concurrent reviewers

Assign one owner to each lane. A reviewer may report a defect in another lane but must not silently edit that lane's shared files. Every owner hands off exact paths, interface names, tests, and unexecuted checks.

| Review lane | Prompt ownership | Owned target paths (new paths are proposals) | Must wait for | Handoff to |
|---|---|---|---|---|
| Toolchain, records, portability | `SYS01`, `SYS18`, `SYS23`, `QA06`, `REL01`, `REL02` | `game/tools/portable_test_runner.gd`; `production/review/execution/`; manifests, provenance, and release evidence only | Actual Godot 4.7.2 path and clean baseline | All lanes; final QA/release |
| Content and science | `SYS02`, `SYS13`, `SYS20`, all `SCIENCE_SRC_*` | `game/resources/campaign/content/`; `game/scripts/content/content_loader.gd`; `game/resources/science/`; `game/scripts/biology/plant_service.gd`; content/biology tests | SYS01; canonical source revision | State, dialogue, simulation, missions, UI, QA |
| State, simulation, persistence, upgrades, puzzle host | `SYS03`, `SYS04`, `SYS07`, `SYS14`, `SYS22`, `PUZZLE_P01`–`P16`, all `ENDING_*` | `game/scripts/core/campaign_state.gd`; `campaign_director.gd`; `command_result.gd`; `game/scripts/simulation/expedition_simulation.gd`; `game/scripts/save/save_service.gd`; `game/scripts/puzzles/puzzle_host.gd`; `game/resources/campaign/profiles/`; targeted tests | SYS02 content and frozen snapshot/command schema | Interaction, UI, missions, bootstrap, QA |
| Interaction, world, navigation, player contact | `SYS05`, `SYS08`, `SYS09`, `SYS12`, `SYS21`, all `ANIMATION_*` | `game/scripts/interactions/`; `game/scripts/world/`; `game/scripts/navigation/`; mission-owned room fixtures; bounded edits to `game/scripts/player/player_controller.gd` or `game/scenes/player/player.tscn` only when the interaction seam requires them | State command contract, current player API, approved asset sockets | Missions, UI, bootstrap, visual QA |
| Face, toon, asset and lunar presentation | `SYS10`, `SYS11`, all `ASSET_*`, `VFX01`–`VFX03` | Existing `game/scripts/face_*.gd`, `hair_springs.gd`, `head_accent.gd`, `toon_materials.gd`, `game/shaders/*` only for bounded fixes; runtime assets through `production/tools/sync_to_godot.sh`; `game/scenes/campaign/rooms/` for visual room assembly | Current v7/v8 cast, asset approvals, world socket contracts | World/missions, visual QA |
| Dialogue, UI, role/accessibility | `SYS06`, `SYS15`, `UI01`–`UI16`, `ASSET_UI_Kit`, `ASSET_UI_Fonts_Icons` | `game/scripts/dialogue/dialogue_service.gd`; `game/resources/campaign/dialogue_catalog.json`; `game/scripts/ui/`; `game/scenes/ui/`; `game/resources/ui/` | Content catalog, state/read-only query API, UI kit/theme | Missions, bootstrap, audio, accessibility QA |
| Audio and cinematics | `SYS17`, `AUDIO-MIX`, all `VOICE_*`, `MUSIC_CUE*`, `SFX_*`, `CUTSCENE_CS01`–`CS18` | `game/scripts/audio/`; `game/scripts/cutscenes/`; `game/assets/audio/`; `game/assets/cutscenes/`; media metadata and production audio/cutscene evidence | Dialogue line IDs/origins, state event contract, supported Godot media pipeline | Bootstrap, missions, QA |
| Mission composition | `MISSION_EX_M0101`–`M0804`, grouped by chapter if necessary | Mission-specific `game/scenes/campaign/missions/EX-Mxxxx.tscn` and `game/scripts/missions/EX-Mxxxx.gd`; no shared service arithmetic | State, simulation, interaction, dialogue, world, and required assets | Primary integration owner, QA |
| Independent acceptance | `QA01`–`QA06` | `production/review/execution/QA*.md` and exact captured evidence; fixes go back to the responsible owner | Integrated candidate, not prompt files | Primary and release owner |

The primary agent should keep a single owner table with `task_id | owner | status | prerequisites | owned_paths | evidence | next_consumer | blocker`. `ready`, `running`, `review`, `verified`, and `blocked` must describe actual work, not prompt existence.

## 4. Exact primary-agent edit fence

The primary agent is the integration/bootstrap owner, not the owner of every service. It should edit or add only these files for the first vertical slice:

| Exact path | Action | Allowed scope |
|---|---|---|
| `game/project.godot` | Edit | Set the real `run/main_scene`; add only frozen campaign input actions and approved display/accessibility defaults; keep Godot 4.7.2 Forward+ and embedded-image settings unchanged. Add autoloads only after service names and lifetimes are frozen. |
| `game/scenes/app/main.tscn` | Add | Application root that instantiates the service registry, menu router, audio/caption roots, and the campaign viewport. It must keep dev scenes reachable through a separate debug route, not replace the production entry with the showcase. |
| `game/scripts/app/main.gd` | Add | Cold boot, New Expedition, Continue, quit/back, service startup/shutdown, save/media error routing, and one clean scene lifecycle. It must call service APIs rather than own arithmetic or campaign predicates. |
| `game/scripts/app/service_registry.gd` | Add | One construction/injection point for the agreed content, state, simulation, interaction, dialogue, save, world, UI, and audio services; no duplicate singleton setup. |
| `game/scenes/campaign/chapter_01_slice.tscn` | Add | Composition root for the launchable Chapter 1 slice. Instance room/mission scenes owned by the world and mission reviewers; do not hide missing rooms behind showcase geometry. |
| `game/scripts/campaign/chapter_01_slice.gd` | Add | Route transitions and integration wiring only: New Expedition → commissioning → planting/care → seven-shift response → ending/retry → CH02 readiness. It must consume state events and never complete a scene on dialogue/cutscene playback alone. |
| `game/tools/test_boot_flow.gd` | Add | Headless smoke fixture for cold boot, New, Continue, corrupt/missing save handling, service teardown, and separate dev-scene access. |
| `game/tools/test_chapter1_slice.gd` | Add | Integration fixture for one real input → validation → transaction → presentation path, P-01/P-02 handoff, captions, checkpoint recovery, duplicate input, and supported loss/retry. |

The primary agent must **not** rewrite these reviewed foundations: `game/scripts/player/*`, `game/scripts/face_*.gd`, `game/scripts/hair_springs.gd`, `game/scripts/lip_sync.gd`, `game/scripts/toon_materials.gd`, `game/shaders/*`, `game/scripts/dev/asset_showcase.gd`, `game/scenes/dev/*`, or any installed GLB/OGV/portrait. If the interaction bridge truly requires a player change, `SYS05/SYS09` owns the bounded edit to `game/scripts/player/player_controller.gd` and/or `game/scenes/player/player.tscn`; the primary consumes that interface. No owner may mass-regenerate the approved asset tree to resolve a code conflict.

## 5. Interface freeze before parallel implementation

Before mission or UI work starts, the primary and SYS owners should publish one small fixture and freeze these conceptual shapes against actual GDScript types:

```text
Command = {
  command_id, issuer, owning_mission_id, owning_scene_id,
  expected_state_revision, target_id, payload
}

CommandResult = {
  accepted, input_revision, output_revision, receipt_id,
  deltas, events, warnings, unsafe_predicates, reason, next_phase
}

Snapshot = {
  schema_version, content_revision, checkpoint_id,
  chapter_id, mission_id, scene_id, scene_phase,
  receipts, knowledge, dialogue_cursor, scenario_datetime,
  actors, resources, plants, inventories, upgrades, route, settings
}
```

Required semantics:

1. Preview and commit use the same pure transition; preview emits no receipt, resource change, audio, world mutation, or save.
2. Commit validates the expected revision and returns the prior result for a duplicate `command_id`; it cannot charge or award twice.
3. UI reads snapshots/results and submits commands. UI, props, animation callbacks, and cutscene skips never mutate global arithmetic.
4. State events carry revision plus owning chapter/mission/scene IDs. Dialogue acknowledgement, animation completion, and cinematic skip remain separate from physical-operation receipts.
5. Save/load stores primitive IDs and values, not scene-tree nodes, callbacks, or secrets. Pause, cancel, retry, and reload are explicit test cases.

## 6. Integration order and dependency gates

| Order | Work | Dependencies | Exit evidence before proceeding |
|---:|---|---|---|
| 0 | Re-establish toolchain and baseline | Current checkout | Godot 4.7.2 and required media tools found; clean import and a bounded existing dev scene run; actual logs stored. |
| 1 | Freeze content revision, command/result schema, and predicate ownership | Canonical story, puzzle source, SYS01 | Runtime-readable 8/32/96/385 catalog validates IDs, ordering, dialogue references, three scenes per mission, and source revision. |
| 2 | Implement state/director, pure simulation, save/checkpoint, world/roster, interaction, dialogue, and plant service | Frozen schemas; current player API | Unit/transition fixtures cover accepted, rejected, duplicate, cancel, pause, save/reload, and loss/retry cases. No UI or mission owner invents a second service. |
| 3 | Implement UI kit plus the 16 UI families needed by the route, then bootstrap | Read-only service APIs and save service | Main menu/New/Continue and HUD/interaction/dialogue/mission-table states are keyboard/controller reachable, English-only, large-text and caption safe; modal input cannot move the player. |
| 4 | Assemble Chapter 1 rooms and physical assets | Asset/socket/collision contracts; world service | Commons, service rooms, garden, safe room, exterior context, pressure boundaries, four physical cadets, and interactable targets load in a real campaign scene. |
| 5 | Integrate P-01/P-02 and `EX-M0101`–`EX-M0104` | Steps 1–4 | New Expedition traverses all 12 Chapter 1 scenes, exact resource rules, dated care, PUMP/STACK/WAIT, alarm response, Bloom and supported loss/retry. |
| 6 | Integrate CS-01/02/03 and available media | Dialogue origins, state events, SYS17 | OGV playback, captions, pause/skip/resume, and acknowledgement are tested; skipping cannot satisfy a safety check or puzzle predicate. |
| 7 | Preserve the vertical slice, then extend Chapters 2–8 in order | Previous chapter final gate and logistics ledgers | Chapter boundaries verify roster, date, location, knowledge, evidence, inventory, and resources; no convenient state reset. |
| 8 | Independent QA, learner/accessibility review, performance, export, credits | Fully integrated candidate | Functional, visual, learner, portability, provenance, and release evidence all exist; remaining limits are explicit. |

## 7. Contest-facing priorities

The hackathon target is 13–14 November 2026. Optimize for a truthful, polished, playable demonstration rather than a wide but fake checklist:

1. **P0 — bootable Chapter 1 vertical slice:** real application launch, New Expedition, commissioning, two-seed planting, dated care, seven-shift night response, meaningful Bloom/loss/retry, save/load, captions, and CH02 readiness. This is the minimum contest-facing game route.
2. **P0 — educational clarity:** show the junior-astronaut mission-training loop, independent safety checks, resource planning, plant biology, and evidence-backed feedback. Do not substitute the asset showcase or a watched film for a playable route.
3. **P0 — current visual identity:** use the installed anime/cel cast and current toon stack; keep the Bangladesh flag on the left sleeve, Aurora patch on right shoulder/chest, English-only UI, and no NASA marks.
4. **P1 — accessibility and resilience:** captions on by default, keyboard/controller parity, readable 150% text, reduced-motion/timer alternatives, pause-safe reading, and a clean retry path. These improve the judging demo more than hidden back-end breadth.
5. **P1 — integrate the three existing anime OGVs only with correct event semantics.** A file playing in the showcase is not cutscene integration. Do not spend scarce generation credits on remaining cutscenes before the playable slice is stable.
6. **P2 — expand later chapters and media breadth** after the Chapter 1 gate. Prefer real text/caption fallback over unintegrated voice claims; never label a planned chapter, prompt, source URL, or old review as complete.

## 8. Canon and science risk register

| Risk | Required guard |
|---|---|
| Legacy 16-mission/48-scene runtime leaks into code | Validate only `EX-M0101`–`EX-M0804` and `EX-CH01-S01`–`EX-CH08-S12`; legacy IDs may appear only as provenance. |
| Dialogue/cinematic completion unlocks gameplay | Every scene gate is a tested conjunction of state/evidence/world predicates. Dialogue can be acknowledged independently; a skip never performs a repair, count, calibration, or safety check. |
| Numeric drift in UI or mission scripts | `E14/20, A6/10, H6/10, W0/6, K0/2, C8/10, R12, Z0`, seven 7.2-hour shifts, exact PUMP/STACK/WAIT exclusivity, caps, exposure-before-drain and zero/negative rules live only in the shared simulation. |
| Plant/seed ledger is simplified | Preserve Alo's 42 seeds as 12 planted + 30 reserve, vault 12 distinct specimens, cotton 1 planted + 11 stored, and CH04's 12 descendants as 7 purple/5 green. Alo dies naturally and is never revived; later plants are descendants. |
| Knowledge leak | Ferreira stays Earth-side until 12 Dec 2046; N. remains a stored recording/text clue before CH05; Noor's identity is not revealed early; first live Noor voice is CH08-S10 only. Rao/Noor are not physical lunar crew. |
| Roster teleportation | CH04 field team is Kai/Rafi with Mei/Amara at base; CH08 rover team is Ferreira/Kai/Rafi with Mei/Amara at Aurora. Role switching is restricted to co-located actors or an authored viewpoint cut. |
| Finale logistics are faked | Preserve 120 km each way, 24 h out + 3 h repair + 24 h back = 51 h, 72 h provisions, base occupancy 2 for 33 h then 5 for 3 h, three repeaters/four hops, and independent local/Earth link proofs. |
| Lunar science violations | Black sky; no fog, haze, wind, billowing dust, visible radiation, vacuum light beams, stars over sunlit ground, or airborne exterior sound. Use grounded lunar gravity and pressurized plant enclosures. |
| Visual lock regresses | Anime/cel style, natural adult proportions, current Ferreira dark-brown pixie with grey streaks, no NASA logo, no Bangla script, and no eyes/faces/mouths on plants. |
| Existing asset gate is overclaimed | 49 imported GLBs prove presence/import inventory only. Collision, live screens, sockets, movable parts, contextual toon appearance, learner clarity and interaction still require their own evidence. |
| Current/stale character contract is mixed | Actual installed 65/68-bone, 44-clip GLBs and current dated handbook win over old 78-bone README/registry descriptions. Do not change accepted models just to satisfy a stale number. |
| Cutscene status is inflated | Three OGVs are present. Remaining current-style cutscenes and the refused/slow-push motion shots are unverified until actual masters, runtime files, and playback evidence exist. |

## 9. Blockers on 2 November (historical; see the board for current ones)

1. **Godot 4.7.2 is not discoverable on this host.** Install or expose the approved executable, then rerun clean import, `verify_assets.gd`, all eight existing test scripts, and the new boot/Chapter 1 fixtures. Do not quote historical pass counts as fresh results.
2. **No application main scene or campaign implementation exists.** Complete the interface freeze, then create the primary-agent bootstrap files and wire `run/main_scene` only after a real Chapter 1 fixture loads.
3. **No runtime audio exists.** The campaign can use text/captions as a truthful fallback, but full voice/music/SFX integration remains blocked until supported media is actually generated/installed and logged.
4. **Only three runtime OGVs exist.** Treat the remaining 15 current-style cutscenes as unverified; do not let the media backlog block ready Chapter 1 code and room work.
5. **Room/interaction/collision contracts do not exist in `game/`.** Asset owners must publish named visual roots, collision roots, focus targets, sockets, movable parts, screen slots, legal visual states, and state-to-animation mappings before mission owners bind actions.
6. **Prompt snapshot drift exists.** The pack names `ca01433`, while the checkout is `5f94bc0`; SYS01 must record current source hashes/revisions before content import or status updates.

## 10. Verification matrix (2 November baseline, historical)

| Gate | Current evidence | Required verification | Current label |
|---|---|---|---|
| Repository baseline | Clean `main`, `HEAD=5f94bc0`; actual tree inspected | Record HEAD/status again before each implementation batch | `present` |
| Runtime asset inventory | 49 binary GLBs, 3 portrait PNGs, 3 OGVs; independent GLB character metadata parse | Godot importer report plus production gate against current manifest | `structural-pass` for inventory/header inspection; importer `unverified` |
| Existing player/render stack | `player.tscn`, locomotion, showcase, look-dev, review scenes and scripts exist | Godot headless: `test_player_controller.gd`, `test_asset_showcase.gd`, `test_review_scene.gd`, `test_toon_materials.gd`, `test_face_atlas.gd`, `test_face_expression.gd`, `test_hair_springs.gd`, `test_lip_sync.gd` | `unverified` because Godot is unavailable |
| Content import | Canonical story files and prompt index are present | Validate 8 chapters/32 missions/96 scenes/385 lines, IDs, ordering, predicates, source revision and 3 scenes per mission | Source `present`; runtime `unverified` |
| Shared state/simulation/save | No implementation files found | Unit/transition fixtures for preview purity, exact-once receipts, numeric witnesses, 128 upgrade combinations, corruption, migration, retry and reload | `absent` / `unverified` |
| Bootstrap | `project.godot` has no main scene | Cold boot, New, Continue, missing/corrupt save, service teardown, and separate dev-scene route | `absent` |
| UI/accessibility | No `game/scenes/ui/` or `game/scripts/ui/` exists; only procedural dev/review labels | Keyboard/controller, 150% text, non-colour cues, mute/captions, reduced motion, timer alternative, focus restore, pause/reopen/save/load | `absent` |
| Chapter 1 route | No campaign room or mission scene exists | Real New Expedition → 12 scenes → Bloom/loss/retry → CH02 readiness with P-01/P-02 and four physical cadets | `absent` |
| Cutscenes/audio | Three OGV files present; no runtime audio files | Playback/skip/pause/resume, captions, audio origin, line/cue IDs, and no fabricated state completion | Media `present`; integration `unverified` |
| Canon/science/visual | Locked documents and installed assets exist; no fresh campaign visual review | Independent GPU/context review plus QA01/QA04 and science/knowledge checks | `unverified` |
| Full campaign | Prompt files cover 32 missions but no mission implementation tree exists | All 96 scene gates, chapter handoffs, ending/credits, complete route timing 600/720/840 profiles | `absent` |
| Release | No exported candidate or current evidence package | Fresh checkout import, export/run, media/LFS check, credits, AI prompt log, source provenance, and no junk/secrets | `unverified` |

The next primary-agent handoff is therefore: unblock Godot, freeze the service fixture, implement the exact bootstrap fence above, and produce a real Chapter 1 integration trace. No implementation should be marked complete until its owner supplies the evidence required by the matrix.

## 11. Primary integration result (2 November 2026)

The primary agent added the bounded commissioning bootstrap described in `production/review/execution/BOOTSTRAP_SLICE.md`: main scene, title/briefing, hashed S01–S03 content, primitive state/save, preview/commit receipts, captions, journal, pause/retry and a compact room. The result is intentionally `structural-pass` for the inspected files and Python content checks, but remains `unverified` for Godot parsing, headless execution, visual review and export until Godot 4.7.2 is available. The full execution library remains a work specification, not a completion checklist.

## 12. Active completion batch — supervisor interface freeze (2 November 2026)

The existing commissioning slice remains the known-good baseline. The supervisor owns
`game/project.godot`, `game/scripts/main.gd`, `game/scenes/main.tscn`, and the final
integration tests. Workers must not edit those files or regenerate installed assets.

### Worker ownership fence

| Worker | Owns in this batch | Must not edit |
|---|---|---|
| A — game systems | `game/scripts/core/`, `game/scripts/simulation/`, `game/scripts/save/`, `game/scripts/biology/`, `game/scripts/puzzles/`, `game/resources/campaign/profiles/`, system tests and `production/review/execution/WORKER_A_*.md` | `main.gd`, `project.godot`, current player/render scripts, installed GLB/OGV files, Worker B/C paths |
| B — world and missions | `game/scripts/world/`, `game/scripts/navigation/`, `game/scripts/interactions/`, `game/scripts/companions/`, `game/scripts/missions/`, `game/scenes/campaign/rooms/`, `game/scenes/campaign/missions/`, world/mission tests and `production/review/execution/WORKER_B_*.md` | `main.gd`, `project.godot`, Worker A core/simulation files, Worker C content/UI files, installed assets |
| C — content and presentation | `game/resources/campaign/content/`, `game/resources/campaign/dialogue_catalog.json`, `game/scripts/content/`, `game/scripts/dialogue/`, `game/scripts/audio/`, `game/scripts/cutscenes/`, `game/scripts/ui/`, `game/scenes/ui/`, content/UI/audio tests and `production/review/execution/WORKER_C_*.md` | `main.gd`, `project.godot`, Worker A/B paths, installed media/assets unless only metadata is needed |

### Frozen runtime interfaces

All command dictionaries use primitive values and these fields:

```text
command_id, issuer, owning_mission_id, owning_scene_id,
expected_state_revision, target_id, verb, payload
```

`CampaignDirector` (`res://scripts/core/campaign_director.gd`) publishes:

```text
new_campaign(content_revision: String = "") -> Dictionary
snapshot() -> Dictionary
query() -> Dictionary
preview(command: Dictionary) -> Dictionary
commit(command: Dictionary) -> Dictionary
restore_checkpoint() -> Dictionary
```

Every result has `accepted`, `duplicate`, `input_revision`, `output_revision`,
`receipt_id`, `deltas`, `events`, `warnings`, `unsafe_predicates`, `reason`, and
`next_phase`. `preview` never mutates state; `commit` rejects stale revisions and
returns the original result for a duplicate command ID.

`ExpeditionSimulation` (`res://scripts/simulation/expedition_simulation.gd`) publishes:

```text
preview(snapshot: Dictionary, plan: Dictionary) -> Dictionary
commit(snapshot: Dictionary, command_id: String, expected_revision: int, plan: Dictionary) -> Dictionary
entry_profile(profile_id: String = "chapter1_base") -> Dictionary
```

The shared simulation owns E/A/H/W/K/C/R/Z, exact P-02 ordering, PUMP/STACK/WAIT,
ending predicates, profile modifiers and preview purity. Mission/UI code must only
submit a plan and render its result.

`PlantService` (`res://scripts/biology/plant_service.gd`) publishes pure operations:

```text
new_plant(individual_id: String, lineage_id: String, stage: String, planted_at: String, attributes: Dictionary = {}) -> Dictionary
apply_care(plant: Dictionary, care_id: String, scenario_datetime: String) -> Dictionary
advance_to(plant: Dictionary, scenario_datetime: String) -> Dictionary
harvest(plant: Dictionary, scenario_datetime: String) -> Dictionary
```

Plant identity, dates, lineage, stress, natural death and the 42/12/30, vault 12 and
cotton 1/11 ledgers stay in this service; renderers consume its returned stage only.

`CampaignContent` (`res://scripts/content/content_loader.gd`) publishes:

```text
load_full() -> Dictionary
validate_full(content: Dictionary) -> Dictionary
scene_by_id(content: Dictionary, scene_id: String) -> Dictionary
mission_by_id(content: Dictionary, mission_id: String) -> Dictionary
dialogue_by_id(content: Dictionary, line_id: String) -> Dictionary
```

The existing `CampaignContent` slice API remains backwards-compatible until the
supervisor integrates the full catalog. Full content must preserve all canonical IDs,
wording, speaker identities, order and source revision.

`WorldRoute` (`res://scripts/world/world_route.gd`) and mission scenes consume a
read-only director plus a `submit_command(command)` callback. They may present a
physical action and animation, but only a successful director result changes campaign
state. UI consumes `CampaignDirector.query()` and emits commands; it owns no arithmetic.

### Integration order for this batch

1. Workers publish owned code and handoff reports.
2. Supervisor reviews each worker's diff and runs the worker tests.
3. A separate reviewer is assigned to inspect each worker's batch without editing it.
4. Supervisor integrates content/state/world/UI seams in dependency order and adds the
   real New Expedition → route → save/reload smoke fixture.
5. Only actual passing checks are recorded in the handbook and handoff; no full-game
   completion claim is allowed until the complete 96-scene route is playable and tested.
