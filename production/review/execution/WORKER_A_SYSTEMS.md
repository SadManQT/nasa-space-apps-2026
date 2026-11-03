# Worker A systems handoff

**Task / owner:** Worker A — game systems
**Date:** 3 November 2026
**Source HEAD:** `5f94bc0e8e6ffc49aea5a2ae36570b13d0bfc4c1`
**Scope:** state/director, P-02 simulation, save service, biology ledgers, puzzle lifecycle adapter and targeted tests. No commit or push was made.

## Ownership and files

Created under the Worker A fence:

- `game/scripts/core/command_result.gd`
- `game/scripts/core/campaign_state.gd`
- `game/scripts/core/campaign_director.gd`
- `game/scripts/simulation/expedition_simulation.gd`
- `game/scripts/save/save_service.gd`
- `game/scripts/biology/plant_service.gd`
- `game/scripts/puzzles/puzzle_host.gd`
- `game/resources/campaign/profiles/chapter1_base.json`
- `game/resources/campaign/profiles/upgrade_catalog.json`
- `game/tools/test_worker_a_systems.gd`
- this report

The existing commissioning files under `game/scripts/campaign/`, the current player/rendering/assets, `game/project.godot`, `game/scripts/main.gd`, and all other owner roots were left unchanged. `CampaignState.from_slice_snapshot()` and `to_slice_like()` are bounded read-only adapters; they do not read or write the commissioning save and do not replace `SliceState`/`SliceRules`.

## Revisions and primitive schema

| Contract | Revision | Runtime file |
|---|---:|---|
| Campaign snapshot | 2 | `campaign_state.gd` |
| Save envelope | 2 | `save_service.gd` |
| P-02 profile/transition | 1 | `expedition_simulation.gd` |
| Plant record/operation | 1 | `plant_service.gd` |

`CampaignState.new_snapshot()` contains only JSON-compatible values: `schema_version`, `content_revision`, `save_id`, `checkpoint_id`, `state_revision`, chapter/mission/scene IDs and phase, completed IDs, receipts, knowledge/dialogue, scenario date and shift, actor locations, `resources`, plants, inventories, upgrades, route, settings/accessibility and presentation resume state. Nodes, scene references, callbacks and secrets are not stored.

The canonical P-02 resource keys are `E`, `A`, `H`, `W`, `K`, `C`, `R`, `Z`, with capacities in the same dictionary. `CampaignState.to_slice_like()` is the only compatibility conversion to the existing lowercase commissioning names.

## Public interfaces

### CampaignDirector

File: `res://scripts/core/campaign_director.gd`

```gdscript
new_campaign(content_revision: String = "") -> Dictionary
snapshot() -> Dictionary
query() -> Dictionary
preview(command: Dictionary) -> Dictionary
commit(command: Dictionary) -> Dictionary
restore_checkpoint() -> Dictionary
pause(reason: String = "user") -> Dictionary
resume() -> Dictionary
```

Command dictionaries require these primitive fields:

```gdscript
{
  "command_id": "shift-5-pump-01",
  "issuer": "mission_table",
  "owning_mission_id": "EX-M0102",
  "owning_scene_id": "EX-CH01-S05",
  "expected_state_revision": 4,
  "target_id": "P-02",
  "verb": "commit_shift",
  "payload": {"plan": {"shifts": [...]}}
}
```

Every director result contains the frozen fields:

```gdscript
{
  "accepted": true,
  "duplicate": false,
  "input_revision": 4,
  "output_revision": 5,
  "receipt_id": "shift-5-pump-01:5",
  "deltas": [...],
  "events": [{"type": "shift_committed", "state_revision": 5, ...}],
  "warnings": [],
  "unsafe_predicates": [],
  "reason": "P-02 transition committed once.",
  "next_phase": "planning",
  "snapshot": { ...primitive snapshot... }
}
```

`preview()` runs the same transition but leaves the authoritative snapshot, revision, receipts, resources, date and world state unchanged. `commit()` validates the expected revision, takes the pre-commit checkpoint, applies one returned transition, and records one receipt. A repeated `command_id` returns the stored result with `duplicate=true`; it does not increment the revision or spend/award again. A stale revision is rejected with the current snapshot untouched. `pause()`/`resume()` do not advance state revision, resources or scenario time. `restore_checkpoint()` restores the complete pre-commit primitive snapshot.

Observed protocol traces from the focused fixture:

```text
preview(shift-1, expected=0) -> accepted=true, duplicate=false, input=0, output=0, receipt=""
commit(shift-1, expected=0)  -> accepted=true, duplicate=false, input=0, output=1, receipt="shift-1:1"
commit(shift-1, expected=1)  -> accepted=true, duplicate=true, output=1, no second charge
commit(stale-2, expected=0) -> accepted=false, duplicate=false, input=1, output=1, state unchanged
pause("test pause")          -> accepted=true, output=1, resources/date unchanged
commit(while paused)          -> accepted=false, reason=resume before committing
restore_checkpoint()          -> accepted=true, current_shift/revision restored to pre-commit values
```

Supported director verbs in this batch are `commit_shift`, `acknowledge_line`, `advance_time`, `set_phase`, `plant_care` and `harvest_plant`; pause/resume are also exposed as methods. Unknown verbs and missing targets reject without mutation.

`new_campaign()` seeds two primitive plant records at the dated Chapter 1 entry (`ALO-01`, `TARA-01`) and attaches the biology ledgers. It is a systems fixture, not a claim that the full Chapter 1 route or campaign is complete.

### ExpeditionSimulation

File: `res://scripts/simulation/expedition_simulation.gd`

```gdscript
preview(snapshot: Dictionary, plan: Dictionary) -> Dictionary
commit(snapshot: Dictionary, command_id: String, expected_revision: int, plan: Dictionary) -> Dictionary
entry_profile(profile_id: String = "chapter1_base") -> Dictionary
```

Plan format accepts a seven-shift array or one ordered shift:

```gdscript
{
  "shifts": [
    {"heat": "DAY", "air_production": 2, "light": "FULL", "transfer": "HOLD"},
    # ...
    {"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "WAIT"},
  ],
  "upgrades": {"choices": {"1": "A", "2": "B"}}
}
```

Heat accepts `DAY`/`COLD`/`COOL`/`COZY` or numeric `0..2`; light accepts `OFF`/`DIM`/`FULL` or numeric `0..2`. Shift 5 accepts only `PUMP`, `STACK` or `WAIT`. `pump_confirmations` accepts `0..3`; `stack_slots` accepts `0..4`. `sheltered=false` is an explicit unsafe crew condition. The returned result includes the frozen result fields plus `trace`, `final_state`, `ending` and `snapshot`.

The exact transition order is:

1. Validate the one ordered transfer/alarm action; shift 5 resolves its alarm before economics.
2. Remove `K` before shift 7.
3. Add day income and clamp `E`; record overflow. Add `O` and clamp `A` before breathing.
4. Score storm exposure: shift 5 uses post-alarm shelter; shift 6 uses shelter before ordinary water transfer.
5. Apply ordinary `FILL`/`HOLD`/`DRAIN` and clamp `W`.
6. Subtract basics + heat + `O` + light from `E`. A result below zero is a blackout and applies `A-2`, `H-2`, `C-2`; exact `E=0` is not a blackout.
7. Subtract breathing, then apply light/cold/thirst to `H`/`C`; dead values do not resurrect. Consume `R` by `1.2` per sampled 7.2-hour shift.
8. Record the trace and evaluate the sunrise ending.

The four published witness outputs are tested exactly:

| Plan | Final `E/A/H/W/K/C/R/Z` | Ending |
|---|---|---|
| Bloom / WAIT | `2/1/1/0/0/3/3.6/2` | `BLOOM` |
| Golden | `0/1/5/0/0/9/3.6/2` | `GOLDEN` |
| PUMP | `0/1/1/6/0/7/3.6/2` | `BLOOM` |
| STACK | `0/3/1/0/0/6/3.6/2` | `BLOOM` |

P-02 ending rules are `MISSION_STOPPED` for an explicit shelter breach or air depletion, `ALO_LOST` for a safe seven-shift completion with `H=0`, `GOLDEN` for safe living Alo with no blackout, `Z<=3` and `H>=5`, and `BLOOM` for the other safe living-Alo completion. A blackout does not itself force a mission stop.

The seven upgrade pairs are normalized from `A`/`B` or stable IDs and applied once in chapter order. P-02-relevant modifiers include taller mast, fuel-cell capacity/entry charge, FULL-lamp discount, COOL insulation, +1 capped effective shielding, and bigger Safe Room `K=3`. Other canonical choices remain represented and deterministic for later mission systems. `upgrade_catalog.json` is the source-facing primitive mapping.

### PlantService

File: `res://scripts/biology/plant_service.gd`

```gdscript
new_plant(individual_id: String, lineage_id: String, stage: String,
          planted_at: String, attributes: Dictionary = {}) -> Dictionary
apply_care(plant: Dictionary, care_id: String,
           scenario_datetime: String) -> Dictionary
advance_to(plant: Dictionary, scenario_datetime: String) -> Dictionary
harvest(plant: Dictionary, scenario_datetime: String) -> Dictionary
```

Each operation returns a new primitive `plant`, `accepted`, `duplicate`, `reason`, `events`, operation name and scenario date. The plant record carries stable individual/lineage IDs, parents, cultivar/type, stage, planted/last-care/last-advanced dates, care receipts/history, stress, enclosure, maturity/dry-down dates, seed yield, alive/natural-death/harvest flags and death reason. No plant visual object or face is created.

Lifecycle guards include:

- Alo planted 11 April 2046, blooms 27 April, mature pods 16 May, five-day dry-down, harvest 21 May.
- Tara uses the distinct 30 April bloom date.
- Pollination is a dated care event and repeated same-day care is a duplicate with no state change.
- Maturity confirmation, dry-down and harvest are separate; an early harvest is rejected.
- Alo harvest returns 42, records natural annual completion, archives the petal state and never revives it. A later dated transition can also move an unharvested dry annual plant to `naturally_dead`.
- Cotton is a dated indoor reference specimen and does not jump to a flower/boll.
- All plants require a pressurised enclosure value.

`canonical_ledgers()` returns distinct ledgers:

```gdscript
{
  "founder_42": {"total": 42, "allocated12": 12, "reserve30": 30,
                 "reserve_compartments": [15, 15], "reconciled": true},
  "vault_12": {"total": 12, "distinct_specimens": 12, "stored": 12,
               "cotton_planted": 0, "stored_after_cotton": 12},
  "cotton_1_11": {"cotton_planted": 1, "vault_stored": 11,
                  "planted_at": "2046-12-15"}
}
```

`record_cotton_plant(vault_ledger, "2046-12-15 06:00 UTC")` is an additional pure ledger operation. It rejects other dates and duplicate planting and returns the vault ledger with `cotton_planted=1` and `stored_after_cotton=11`.

## Independent-review defect follow-up (3 November 2026)

The requested Worker A corrections are now applied only in the owned paths:

1. `insulation_blankets` now removes the declared Alo cold-damage point for COOL; the 128-mask test also runs a controlled COOL/DIM probe for every mask and checks the insulated versus uninsulated health result.
2. Direct `ExpeditionSimulation.commit()` assigns `receipt_id` and final result fields before storing the receipt. Duplicate calls return the original receipt/result.
3. Persistent upgrade `choices` and `acquisition_chapter` maps are merged in insertion/acquisition order. Partial plans preserve earlier choices, including an attempted conflicting partial choice.
4. Save replacement backs up only a valid primary. Recovery from a corrupt primary leaves an already-valid `.bak` intact, so a second primary corruption recovers from the same backup.
5. `PlantService` enforces canonical ALO-01/TARA-01/COTTON-01 identities and planting dates, rejects backward lifecycle dates, requires dated maturity confirmation before dry-down and harvest, and returns the original plant on every rejected harvest. The initial campaign ledger now represents twelve unplanted vault specimens (`stored12=12`, `stored11=0`) while retaining the separate 42 = 12 + 30 founder reserve.
6. Campaign pause/resume command payloads are type-checked before reading `reason`.
7. `PuzzleHost.commit()` uses the revision captured by its accepted preview; a new state revision rejects the stale preview while replaying the same command still returns its receipt.
8. Campaign and direct-simulation receipts no longer retain a full snapshot inside the receipt map. Duplicate replay reconstructs the caller's current snapshot, preventing recursive deep-copy growth during a long Chapter 1 route.

### SaveService

File: `res://scripts/save/save_service.gd`

```gdscript
save(snapshot: Dictionary, path: String = DEFAULT_PATH) -> Dictionary
load(path: String = DEFAULT_PATH, fallback_snapshot: Dictionary = {}) -> Dictionary
migrate(snapshot: Dictionary) -> Dictionary
recover_corrupt(path: String = DEFAULT_PATH,
                fallback_snapshot: Dictionary = {}) -> Dictionary
has_valid_save(path: String = DEFAULT_PATH) -> bool
clear(path: String = DEFAULT_PATH) -> bool
```

`save()` deep-copies the snapshot, stamps save schema 2 and format ID, validates primitive resource fields, writes and parses `path.tmp`, preserves one `.bak`, then installs the validated file. The Windows direct-write fallback is reached only after the temporary JSON has parsed and the old file has been backed up. `load()` migrates schema 1 lowercase commissioning-style resources to canonical uppercase resources. A corrupt primary is recovered from the last valid backup and rewritten; if neither is valid, the caller receives its supplied fallback without an advancement.

Representative save/recovery trace:

```text
save(first) -> accepted=true, schema_version=2
save(second) -> accepted=true, backup_path=<path>.bak
primary becomes corrupt
load(path) -> accepted=true, recovered=true,
              reason=primary_corrupt_recovered_from_backup
```

### PuzzleHost

File: `res://scripts/puzzles/puzzle_host.gd`

```gdscript
bind(director: RefCounted, puzzle_id: String,
     mission_id: String, scene_id: String) -> Dictionary
begin(director: RefCounted, puzzle_id: String,
      mission_id: String, scene_id: String) -> Dictionary
preview(plan: Dictionary) -> Dictionary
commit(command_id: String, plan: Dictionary) -> Dictionary
pause(reason: String = "user") -> Dictionary
resume() -> Dictionary
cancel() -> Dictionary
retry() -> Dictionary
complete(result: Dictionary = {}) -> Dictionary
snapshot() -> Dictionary
```

Lifecycle states are `idle`, `active`, `previewed`, `paused`, `committed`, `failed`, `completed` and `cancelled`. The host builds the frozen command and delegates all arithmetic/receipt work to the director. Pause, cancel and preview have no simulation side effects; retry delegates the director checkpoint. It is suitable for P-01/P-02 and later mission puzzle adapters without adding a second arithmetic implementation.

## Verification executed

Approved executable used:

```text
C:\Users\User\AppData\Local\Temp\opencode\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe
Godot Engine v4.7.2.stable.official.ed1daf0bf
```

| Command | Result |
|---|---|
| `Godot --headless --path game --script res://tools/test_worker_a_systems.gd` | **PASS — 97 checks, 0 failures** |
| `Godot --headless --path game --script res://tools/test_campaign_content.gd` | **PASS — 9 checks, 0 failures** |
| `Godot --headless --path game --script res://tools/test_slice_state.gd` | **PASS — 13 checks, 0 failures** |
| `Godot --headless --path game --script res://tools/test_ch01_commissioning.gd` | **PASS — 15 checks, 0 failures** |
| `Godot --headless --path game --script res://tools/test_campaign_boot.gd` | **PASS — 4 checks, 0 failures** |
| `Godot --headless --path game --editor --quit` | **PASS — project scan/class registration completed** |
| `python -m json.tool game/resources/campaign/profiles/chapter1_base.json` | **PASS — profile parses** |
| `python -m json.tool game/resources/campaign/profiles/upgrade_catalog.json` | **PASS — profile parses** |

Worker A coverage includes Bloom, Golden, PUMP and STACK witness vectors and Bloom's seven intermediate rows; zero versus negative energy; income-before-spend; air cap-before-breathing; post-alarm/pre-drain exposure; post-transfer thirst; forced STACK settings; partial/full alarm actions; water/crate caps; shift/action rejection; shelter failure; duplicate/stale/preview/pause/retry; invalid pause payloads; direct receipt replay; persistent upgrade merge/order; atomic save, two-corruption backup recovery and schema migration; all 128 upgrade masks with an explicit insulation effect; canonical dated Alo/Tara/cotton identities; backdated advance; maturity-before-dry/harvest; rejected-harvest purity; natural death/no revival; and the three biological ledgers.

## Integration dependencies and traces

1. The supervisor constructs one `CampaignDirector`, injects it into `PuzzleHost`/mission/UI callers, and keeps the existing commissioning route on `SliceState`/`SliceRules` until the bounded integration seam is deliberately selected.
2. Mission/UI callers submit frozen commands and render `snapshot()`/result data. They must not calculate P-02 values, mutate receipts, or advance scenario time from dialogue/animation/cutscene callbacks.
3. World/mission work should add plants as primitive records or use the `PlantService` operation result, then commit through the director. Renderers consume returned stage/lineage/status only.
4. Save/load integration should call `SaveService.save()` before a destructive/timed commit and on safe checkpoint/completion, then restore the returned primitive snapshot. It must not serialize nodes.
5. No project autoload, main-scene, player, asset, shader, content, world or UI edit is required by this handoff.

## Known limits / unexecuted checks

- This is not the complete Chapter 1 route and does not implement the 96-scene campaign, content importer, interaction/world systems, dialogue catalog, UI families, audio, cutscene integration, NASA source products or release export.
- P-02 arithmetic and the seven upgrade modifiers are implemented and exercised. The 128-mask test now proves the Chapter 2 insulation effect on its controlled COOL probe; it is not a full balance proof for every later mission or an executed full-campaign safe-path analysis.
- P-13/P-14 logistics and later-chapter modifiers are represented only where needed for stable upgrade normalization; their six-step/finale simulations remain unimplemented.
- Biology operations and ledgers are pure service fixtures; no production greenhouse scene, interaction socket, animation, visual plant review or final garden presentation is claimed.
- Save recovery is tested through two consecutive deliberately corrupted primaries while retaining a valid backup. Crash/power-loss testing during an OS filesystem failure, multi-slot cloud/user-profile behavior and exported-package save migration remain unexecuted.
- The headless parser and current commissioning tests pass. Visual review, learner review, performance, export and complete campaign traversal remain unverified.
- No AI or paid asset generation occurred, so no prompt-log entry was needed for this batch.

## Handoff decision

**Ready for supervisor review:** the owned systems are structurally and functionally tested behind the frozen primitive interfaces. The next concrete action is for the supervisor to inspect this diff, exercise the fixture from the integration/bootstrap seam, and decide when to bridge it into mission/UI code without editing the existing commissioning slice or claiming the complete campaign.
