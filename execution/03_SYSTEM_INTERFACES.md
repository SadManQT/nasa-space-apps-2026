# Shared interfaces, data ownership and integration contract

These are **proposed implementation boundaries**, not a claim that the named new modules already exist. First inspect current `game/scripts/` and reuse an equivalent implementation if present. Preserve the existing public player/rendering APIs. The coordinator freezes concrete method signatures in an interface note before multiple owners edit dependent systems.

## Runtime ownership

| Service | Single owner | Responsibilities | Consumers must not do |
|---|---|---|---|
| Canon/content import | SYS campaign-content owner | Validate/import8chapters,32missions,96scenes,385lines; resolve source/evidence refs | Invent duplicate scene IDs or replace final IDs with legacy SC IDs |
| Campaign state/director | SYS campaign-state owner | Current mission/scene phase, predicates, ordered unlocks, roster/locations/time, idempotent receipts | Unlock chapters from animation/caption completion alone |
| Numeric simulation | SYS simulation owner | Entry profiles, preview/commit transition, conserved resources, upgrade application | Reimplement arithmetic in a UI, prop or mission script |
| Interaction dispatcher | SYS interaction owner | Target, verb, range/line of sight, prerequisite, transaction, feedback/cancel | Mutate global flags from a model's animation callback |
| Dialogue and knowledge | SYS dialogue owner | Exact line ID/text, delivery origin, knowledge gates, transcript, VO/caption sync | Read future journal/portrait content before acquisition |
| Save/checkpoint | SYS save owner | Versioned atomic state, rollback boundary, recovery, migration | Serialize scene-tree references or advance on load |
| World/roster | SYS location owner | Spawn anchors, actor placement, route transitions, local/remote separation | Teleport a switched cadet between rover/base |
| UI | UI component owners | Read shared state, issue explicit commands, display results/accessibility | Spend resources, duplicate a commit, or expose debug flags |
| Character runtime | Current player owner | Movement, camera, animation/holds, face/hair/gaze, prop sockets | Rewrite current locomotion in an unrelated controller |
| Audio/cinematics | Audio/cutscene owners | Playback, bus priority, origin treatment, pause/skip/resume | Fabricate puzzle completion to match the video's ending |

Suggested new file roots are `game/scripts/core/`, `simulation/`, `interactions/`, `dialogue/`, `save/`, `world/`, `audio/`, `cutscenes/` and `game/resources/campaign/`. The specific task owner chooses a coherent existing-compatible layout and documents it before consumers implement against it.

## Authoritative snapshot

Use a serializable snapshot with, at minimum:

```text
schema_version; content_revision; save_id; checkpoint_id
chapter_id; mission_id; scene_id; scene_phase; completed_scene_ids
mission_receipts; interaction_receipts; acquired_evidence_ids
knowledge_flags; dialogue_cursor; acknowledged_line_ids
scenario_datetime; current_shift; travel_segment; explicit_time_receipts
actors { actor_id: physical_location_id, anchor_id, team_id }
resources { E,A,H,W,K,C,R,Z, capacities, entry_profile_id }
plants { individual_id,lineage_id,parents,stage,dated_care,stress }
inventories { founder_seed42,allocated12,reserve30,vault12,cotton_planted,stored11 }
upgrades { acquisition_chapter: choice_id, applied_profile_revision }
route { trip_id,roster,local_hops,earth_leg,provisions,departure,elapsed,return }
settings_revision; accessibility; presentation_resume
```

This schema is conceptual. Reconcile it with the actual source profile fields and typed GDScript resources before implementation. Keep founder, vault and album inventories distinct. Store stable IDs and primitive values, not nodes, callbacks or user secrets.

## Commands and results

1. A command carries `command_id`, issuer/role, owning mission/scene, expected state revision, target and payload.
2. The state owner validates prerequisites and conflicts before mutating anything.
3. A preview returns a result derived from the same transition as commit: input revision, deltas, warnings, unsafe predicates and expected next phase. It does not emit completion, inventory, audio or save side effects.
4. Commit validates the revision again. If the command already has a receipt, return the recorded result; never charge or award twice.
5. An accepted command produces one new state revision and typed events. Rejected commands preserve state and return an actionable reason. A partial minigame result is a valid explicit payload under its numeric contract, not an unknown half-commit.
6. Presentation acknowledges events independently. Rendering, replaying audio or opening a journal does not run the command again.

Suggested conceptual command families: `inspect_evidence`, `submit_role_fact`, `preview_plan`, `commit_shift`, `confirm_action_step`, `commit_transfer`, `acknowledge_line`, `request_scene_exit`, `accept_time_transition`, `confirm_roster`, `commit_route_segment`, `save_checkpoint`, `restore_checkpoint`. These are contract labels until the owner publishes exact code signatures.

## Event ordering

`interaction requested → prerequisite/result preview → explicit user confirmation → simulation/state transaction → receipt → UI/world update → checkpoint → next scene eligibility`.

Publish events with state revision and owning IDs, such as resource delta, evidence acquired, knowledge unlocked, actor moved, plant stage changed, time advanced, scene completed and mission completed. UI subscribers can re-render safely after reload. Unsubscribe listeners when their scene closes. Do not depend on emission order between unrelated nodes to enforce safety.

## Scene and mission gates

- Exactly three final scene IDs belong to each expansion mission. Their English exit conditions appear in its mission prompt; convert them into explicit tested conjuncts, not text matching at runtime.
- Each predicate names its responsible evidence/state field. Store provisional subchecks inside the active mission transaction until committed.
- A scene completes only once; all required conjuncts must be true. The third scene's completed gate commits that mission and permits the next mission.
- Do not conflate delivered dialogue with the world operation it describes. Skipping speech can acknowledge a transcript, but cannot calibrate a probe, repair a valve, count a seed or prove a radio link.
- Stable illustrative gate IDs can use `<scene_id>:<meaningful_predicate>`. The coordinator keeps one predicate registry; do not invent synonymous flags in different owners' modules.

## Asset ↔ interaction contract

Each interactable asset handoff includes asset ID, version, size, visual root, collision root, focus target, interaction sockets, grip/hand anchors, movable child names, material/screen slots, legal visual states and state-to-animation mapping.

An artist names and exposes a shutter, valve, door, connector, battery or compartment; a gameplay owner owns its logical state and transition. The asset does not implement hidden campaign arithmetic. A screen uses current localized English UI content rather than a baked fake reading. A held case uses the existing BOX/RIGHT/NONE hold API and an explicit prop-specific offset; no permanently attached mesh is baked into a character.

## Time, location and radio

Keep active play time separate from fictional scenario time. A dated transition records one explicit cost/logistics operation and is idempotent on save/reload. UI reading is pause-safe. Both branches of a cross-team sequence retain their own location snapshots; role switch is constrained to the correct co-located group or an authored viewpoint cut.

Radio origin is a structured field: local suit/base link, direct Earth, relay local leg, relay Earth leg, stored archive, queued text. A completed local acknowledgement never repairs the Earth leg. A stored future-facing line cannot know an untransmitted outcome. Time/date displays and source data labels reflect these fields, not a convenient cinematic assumption.

## Required cross-owner handshake

Before handing an implementation to the next owner, provide: exact API/resource names; a minimal integration scene; example state/command/result; input and output schema version; an error and a successful trace; pause/load/duplicate-input behaviour; tests and known limits. Consumers exercise that fixture before changing production scenes.

If two owners need the same file, pause conflicting edits, let the coordinator select one owner, and deliver the other change as a bounded patch or interface request. Preserve unrelated edits and never mass-regenerate approved assets or content as a merge-conflict shortcut.
