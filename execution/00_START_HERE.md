# Last Light Academy — complete execution prompt library

**Prepared: 27 October 2026. Repository snapshot: `ca01433`.**

এই folder-এর প্রতিটি কাজের আলাদা Markdown prompt আছে। অন্য AI-কে repository access দিয়ে একটি task file দিন। AI-টি shared contract পড়ে actual deliverables তৈরি করবে, যাচাই করবে এবং handoff লিখবে। শুধু এই prompt library তৈরি হয়েছে; নিচের implementation tasks এই কাজের মাধ্যমে executed হয়েছে—এমন দাবি করা হচ্ছে না।

## Start with these files

1. [01_MASTER_EXECUTOR.md](01_MASTER_EXECUTOR.md): complete-project coordinator prompt; use this when one AI will own the entire delivery.
2. [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md): canon, locked decisions, science, numeric boundaries and permissions that apply to every task.
3. [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md): one shared state model, ownership boundaries and cross-team event contracts.
4. [04_CURRENT_STATE.md](04_CURRENT_STATE.md): what actually exists, stale records and the remaining implementation gap.
5. [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md): required evidence, verification and completion report.
6. [06_EXECUTION_BOARD.md](06_EXECUTION_BOARD.md): phased execution order and the Chapter 1 critical path.
7. [07_DEPENDENCY_AND_OWNERSHIP_MAP.md](07_DEPENDENCY_AND_OWNERSHIP_MAP.md): exact shared-service dependencies, ownership and the mission chain.
8. [08_SOURCE_REVISION_RECEIPT.md](08_SOURCE_REVISION_RECEIPT.md): fingerprints of the source documents used to prepare the pack.
9. [99_COVERAGE_MATRIX.md](99_COVERAGE_MATRIX.md): complete clickable index and source-to-prompt coverage.

## How to assign one task

Copy this instruction and attach the selected Markdown file:

> Work in the Last Light Academy repository. Execute the attached task prompt completely. First read `AGENTS.md`, `PRODUCTION_HANDBOOK.md`, the latest entries in `HANDOFF.md`, `execution/02_SHARED_CONTRACT.md`, `execution/03_SYSTEM_INTERFACES.md`, and `execution/05_ACCEPTANCE_AND_HANDOFF.md`. Recheck the current repository state because this prompt was prepared against commit `ca01433`. Reuse work that is already delivered and approved. Implement only your declared ownership area, demonstrate the specified acceptance evidence, and hand off exact files, tests, remaining blockers and integration interfaces. Commit or push only if the user has explicitly requested it. Where a documented approval is already present, use it; request a new approval only for the specific action that still requires one.

## Task families

| Prefix | Assignment unit |
|---|---|
| `SYS_` | Shared runtime systems and production foundations |
| `ASSET_` | One of the 75 registry entries: an installed asset to finish/verify or a planned family to build |
| `MISSION_` | One of 32 mandatory missions; includes its three final scene snapshots and exact dialogue |
| `PUZZLE_` | One of 16 numeric/scientific puzzle implementations |
| `UI_` | One screen/component family and its interaction/accessibility states |
| `CUTSCENE_` | One of 18 final cutscenes; reuse the three existing anime masters |
| `VOICE_` | One canonical speaker/delivery group with all assigned line IDs and text |
| `MUSIC_` | One of 12 score cues |
| `SFX_` | One of 35 sound-effect specifications |
| `AUDIO_` | Playback, buses, voice/caption synchronisation and mixing |
| `SCIENCE_` | One primary-source evidence card and its genuinely required data/illustration |
| `UPGRADE_` | One earned upgrade pair, its modifier, appearance and acquisition tests |
| `ENDING_` | One canonical ending with predicate, closure and retry/advance semantics |
| `ANIMATION_` | Care/science, repair/vehicle or narrative performance contact family |
| `VFX_` | A coherent effects/lighting family with lunar-science boundaries |
| `QA_` | Independent functional, narrative, visual, accessibility and learner verification |
| `RELEASE_` | Portable export and evidence/attribution package |

## Keep multiple AIs in sync

- Assign one owner per shared runtime service. Other task owners call that interface instead of creating another implementation.
- The coordinator records task ownership, dependency readiness and exact interfaces before concurrent edits.
- Asset models, materials and interaction code have different owners; agree sockets and named movable parts first.
- Scene, mission and dialogue IDs come from the final 96-scene source. Never use the older 48-scene list as the runtime campaign.
- Imported geometry passing the asset gate does not establish completed collision, interactions, toon appearance, or playable missions.
- The first milestone is a launchable Chapter 1 slice. The final milestone remains all eight chapters and the same 10–14-hour main route.

The prompts are written in English for precise AI/studio execution. This index includes Bangla reading guidance. The **game itself is English-only**, following the current locked decision.
