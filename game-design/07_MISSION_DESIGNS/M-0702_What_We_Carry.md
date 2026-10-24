# M-0702 — What We Carry

## Mission identity

- **Chapter:** CH07 — The Great Storm.
- **Primary location:** LOC-04; exact movement is listed by scene below.
- **Purpose:** Execute the storm plan, save the reserve and diagnose the failed link.
- **Active-play target:** 20 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `storm_prepared=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0704, SC-0705, SC-0706 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_07.md).
- **Characters:** Use the physical/remote/archive roster of SC-0704, SC-0705, SC-0706; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-14](../08_PUZZLE_DESIGNS.md#p-14).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07,SYS-09; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-09,A-10,A-11,A-19,A-22,A-23,A-28,A-29,A-42,A-43; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

A restored local recorder entry becomes available during the lull.

Objective text: **Execute the storm plan, save the reserve and diagnose the failed link.** Enter through LOC-04; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0702-O1

- **Scene / time / location:** SC-0704 / Feb 14 06:00–Feb 16 01:12 / LOC-04.
- **Objective text:** Run the storm steps and read Noor’s final log in the lull.
- **Required interactions:** Continue P-14 waves; listen/read final log once safely sheltered; compare plant and reserve telemetry before last wave.
- **Environmental result:** Mei rests a glove beside the seed case; Ferreira watches without interrupting Noor.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0704-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Log heard/read AND second storm step committed AND reserve telemetry checked. Set SC-0704_done once; never on mere zone entry.
- **Discovery:** Noor named the seed hope before evacuation; her full personal arc is now available.
- **Journal copy:** Noor called the seeds Alo so someone could bring light back. Her recording is old; the reserve beside us is alive with possibility.

### Objective M-0702-O2

- **Scene / time / location:** SC-0705 / Feb 16 01:12, then two clear readings / LOC-01.
- **Objective text:** Diagnose the external branch and verify route clearance.
- **Required interactions:** Finish P-14 diagnostics, identify external branch failure, confirm two consecutive safe-rate readings and inspect the relay bypass diagram.
- **Environmental result:** Ferreira lays the relief-flight replacement controller on the table.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0705-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-14 all waves complete AND two clear readings AND relay bypass inspected. Set SC-0705_done once; never on mere zone entry.
- **Discovery:** A replacement was delivered in December; both relay links and route repeaters are required.
- **Journal copy:** The external uplink feedthrough failed. Local radios survived. Two safe readings cleared travel to the relay.

### Objective M-0702-O3

- **Scene / time / location:** SC-0706 / Feb 16 03:00 → Apr 8 00:00 / LOC-01.
- **Objective text:** Confirm the rover and home-team handover.
- **Required interactions:** Confirm team roster, spare controller, local repeater plan and minimum home reserves; sign the departure board. Confirm the dated February-to-April stable-care, route-survey and fabrication montage before final departure.
- **Environmental result:** Two teams exchange duplicate route and shelter checklists.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0706-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Roster and cargo confirmed AND home reserve checks passed AND dated preparation montage accepted; commit M-0702 and route_clear. Set SC-0706_done once; never on mere zone entry.
- **Discovery:** There is no unassigned cadet or absent base operator in the finale.
- **Journal copy:** Ferreira,Kai and Rafi travel. Mei and Amara keep Aurora safe. We have the spare controller and a repeater route.

## Puzzle mechanics included in this mission

**Initial condition:** Six storm steps; game multipliers [1,1,2,2,1,1]. Use P-02 energy, plant and shelter rules, Chapter 7 reserves and five-person air/food rates. Chapter 7’s Z<=6 limit overrides Chapter 1’s Z<=3 limit; its six storm multipliers are explicit. K remains installed through step 6 and is cleared only after the storm; P-02’s shift-7 removal belongs to Chapter 1.

**Interaction procedure:** Confirm five occupants. Execute all six steps; dose is sampled before an ordinary transfer, using the P-02 shelter table times the current multiplier. Play Noor’s last log after step 2 in the lull; it explains Alo and the Last Light Academy name. Keep hatch closed during exposure. After step 6 verify local network PASS, direct dish path FAIL and external feedthrough FAIL; select F-EXT. Two route readings below the game threshold 1, ten scenario minutes apart, clear later exterior preparation.

**Accepted solution:** P-13 witness ends E6,A2.5,H1,C3,R9,Z0,W2,K2, reserve30 safe. Diagnose the external feedthrough; safe readings 0.4 then 0.3 clear the route. A 1.2 reading does not. The February-to-April preparation montage maintains the stable base before the final trip.

**Pass predicate:** Six steps complete, A>0,Z<=6,H>0,C>0,founder reserve30 safe,F-EXT identified and two clear readings.

**Incorrect feedback:** The hatch interlock prevents storm EVA. Unsafe committed dose/air or lost mandatory garden/seed objectives offer a pre-step retry. One safe reading is insufficient. The direct uplink failure is a scripted incident, not a hidden penalty for a correct plan.

## State machine and triggers

LOCKED → AVAILABLE when `storm_prepared` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0704 → OBJECTIVE_2_DONE on EV-0705 → READY_TO_COMPLETE on EV-0706 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0702-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `route_clear` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `route_clear=true`, `M-0702=COMPLETE`, and `M-0801` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Finish all three waves before going outside. / A working local radio isolates the failure to the Earth path. / Keep the six-step witness, select F-EXT and record two below-threshold readings.
- **Journal after objective 1:** `M-0702: Noor called the seeds Alo so someone could bring light back. Her recording is old; the reserve beside us is alive with possibility.`
- **Journal after objective 2:** `M-0702: The external uplink feedthrough failed. Local radios survived. Two safe readings cleared travel to the relay.`
- **Journal after objective 3:** `M-0702: Ferreira,Kai and Rafi travel. Mei and Amara keep Aurora safe. We have the spare controller and a repeater route.`
- **Completion entry:** “Execute the storm plan, save the reserve and diagnose the failed link. Completed. Next: M-0801.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. route_clear_pending; radio_external_failed; final_log_heard; all_crew_safe.

Next mission: **M-0801**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
