# M-0701 — Your Call, Cadets

## Mission identity

- **Chapter:** CH07 — The Great Storm.
- **Primary location:** LOC-04; exact movement is listed by scene below.
- **Purpose:** Make the integrated three-wave survival plan.
- **Active-play target:** 18 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `kai_supported=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0701, SC-0702, SC-0703 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_07.md).
- **Characters:** Use the physical/remote/archive roster of SC-0701, SC-0702, SC-0703; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-13](../08_PUZZLE_DESIGNS.md#p-13).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07,SYS-09; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-10,A-11,A-12,A-13,A-14,A-16,A-22,A-23,A-28,A-29,A-42,A-61; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

A new forecast interrupts breakfast.

Objective text: **Make the integrated three-wave survival plan.** Enter through LOC-01; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0701-O1

- **Scene / time / location:** SC-0701 / Feb 14, before 06:00 / LOC-01.
- **Objective text:** Share the new warning and review the three-wave plan.
- **Required interactions:** Share current observations, inspect three-wave forecast and open P-13 integrated plan; photograph reserve seal.
- **Environmental result:** No one keeps the warning private; each cadet places an observation card.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0701-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** All current observations shared AND wave model inspected AND reserve photographed. Set SC-0701_done once; never on mere zone entry.
- **Discovery:** The labelled 2012 counterfactual preserves the historical data source; lunar doses and damage are game/fiction values.
- **Journal copy:** A historical replay warning reached all four specialists. We planned together before the first wave.

### Objective M-0701-O2

- **Scene / time / location:** SC-0702 / Feb 14 preparation / LOC-04.
- **Objective text:** Stage shielding, protect the reserve and verify the return schedule.
- **Required interactions:** Complete P-13 six-step schedule; load protected seed container; set base electronics isolation and return-pump priority.
- **Environmental result:** Seed container latches inside the crew shelter; tools are stowed.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0702-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-13 valid schedule verified AND seed reserve latched. Set SC-0702_done once; never on mere zone entry.
- **Discovery:** Old water-return failure informs a practical improvement.
- **Journal copy:** Our plan keeps essential loads running, protects the founder seeds and returns water after exposure.

### Objective M-0701-O3

- **Scene / time / location:** SC-0703 / Feb 14, first wave readiness / LOC-04.
- **Objective text:** Account for five people and seal the shelter.
- **Required interactions:** Account for all five occupants and close shelter hatch; preview the first verified step of P-14 after presence lock; execution starts in the next mission.
- **Environmental result:** Companions sit; no NPC remains walking outside during wave damage.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0703-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Five occupants present AND hatch closed AND first wave step preview confirmed; commit M-0701. Set SC-0703_done once; never on mere zone entry.
- **Discovery:** The mature team checks people before systems.
- **Journal copy:** All five of us are inside. The first wave has not been committed until we confirm the plan.

## Puzzle mechanics included in this mission

**Initial condition:** Chapter 7 logistics snapshot after preparation costs, not Chapter 1 carryover. Six dark 7.2 h steps, multipliers [1,1,2,2,1,1]. Five lunar occupants (including Ferreira) consume A1.25 and R1.5 crew-days per step. Three waves span steps 1–2, 3–4 and 5–6.

**Interaction procedure:** Two allowed preparation transfers put W4 in shelter; stage full K2 supply bundles and latch both founder-reserve compartments (15+15=30) before peak step 3. Schedule COZY heat, DIM light, O0 throughout. HOLD W in 1–5; DRAIN to W2 in step 6 after that step’s exposure. Isolate the exposed uplink before the peak. No free solar income during the storm.

**Accepted solution:** W [4,4,4,4,4,2], K2 throughout exposure, COZY/DIM/O0 in all six steps. Shield S6 gives zero game dose even in peak steps. Costs 6*(1+2+1)=24, ending E6,A2.5,H1,C3,R9,Z0; seed reserve30 stays protected. All five crew are sheltered.

**Pass predicate:** Feasible six-step plan, both seed compartments latched, five-person roster acknowledged, uplink isolation scheduled.

**Incorrect feedback:** Early drain reduces shelter before a later exposure. Missing seed compartment prevents readiness. Alternative plans are accepted when they meet the same safety and living-garden goals; owned upgrades apply once.

## State machine and triggers

LOCKED → AVAILABLE when `kai_supported` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0701 → OBJECTIVE_2_DONE on EV-0702 → READY_TO_COMPLETE on EV-0703 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0701-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `storm_prepared` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `storm_prepared=true`, `M-0701=COMPLETE`, and `M-0702` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Put the seeds inside before the peak. / Water and cargo share the shielding job. / Prepare W4 and K2; COZY/DIM throughout; drain in step 6 after exposure.
- **Journal after objective 1:** `M-0701: A historical replay warning reached all four specialists. We planned together before the first wave.`
- **Journal after objective 2:** `M-0701: Our plan keeps essential loads running, protects the founder seeds and returns water after exposure.`
- **Journal after objective 3:** `M-0701: All five of us are inside. The first wave has not been committed until we confirm the plan.`
- **Completion entry:** “Make the integrated three-wave survival plan. Completed. Next: M-0702.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. storm_prepared_pending; protected_founder_seeds30; plan hash recorded for P-14.

Next mission: **M-0702**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
