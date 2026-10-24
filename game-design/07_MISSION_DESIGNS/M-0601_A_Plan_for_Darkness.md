# M-0601 — A Plan for Darkness

## Mission identity

- **Chapter:** CH06 — The Red Ring.
- **Primary location:** LOC-02; exact movement is listed by scene below.
- **Purpose:** Prepare a protected bus and a verified eclipse power transfer.
- **Active-play target:** 13 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `noor_known=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0601, SC-0602, SC-0603 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_06.md).
- **Characters:** Use the physical/remote/archive roster of SC-0601, SC-0602, SC-0603; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-11](../08_PUZZLE_DESIGNS.md#p-11).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-10,A-11,A-12,A-42; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

Kai takes the same hand light from its locker.

Objective text: **Prepare a protected bus and a verified eclipse power transfer.** Enter through LOC-02; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0601-O1

- **Scene / time / location:** SC-0601 / Jan 12, before eclipse / LOC-02.
- **Objective text:** Charge the hand light and choose a companion for the transfer.
- **Required interactions:** Inspect Kai’s childhood storm-blackout memory, hand light charge, eclipse schedule and protected bus; select a companion to remain beside Kai during transfer.
- **Environmental result:** Rafi remains within reach; Kai checks, rather than hides, the lamp.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0601-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Hand light charged AND eclipse schedule read AND companion assigned. Set SC-0601_done once; never on mere zone entry.
- **Discovery:** Kai can name his fear and request support.
- **Journal copy:** Kai named his fear of darkness and asked for support. We can plan with that fact.

### Objective M-0601-O2

- **Scene / time / location:** SC-0602 / Jan 12 planning / LOC-02.
- **Objective text:** Verify the protected-bus schedule.
- **Required interactions:** Complete P-11 transfer planning, shed optional loads and verify the protected services remain powered across all five segments.
- **Environmental result:** Kai labels each cable route; Amara confirms aloud.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0602-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-11 outage schedule verified. Set SC-0602_done once; never on mere zone entry.
- **Discovery:** Planning includes emotional needs through low-power guide lights, not unnecessary floodlights.
- **Journal copy:** The eclipse plan keeps essentials and guide lights powered, with one return-pump operation and one camera operation.

### Objective M-0601-O3

- **Scene / time / location:** SC-0603 / Jan 12 ingress readiness / LOC-01.
- **Objective text:** Confirm readiness and enable the filtered camera.
- **Required interactions:** Confirm five segment acknowledgements and four role readiness checks and activate the external camera filter before viewing.
- **Environmental result:** Everyone occupies a working position, not a semicircle of spectators.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0603-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Five segment acknowledgements AND four role readiness confirmations AND filtered camera enabled; commit M-0601. Set SC-0603_done once; never on mere zone entry.
- **Discovery:** The eclipse observation uses instruments with protection; no unfiltered solar viewing mechanic.
- **Journal copy:** Everyone confirmed their station before the eclipse observation.

## Puzzle mechanics included in this mission

**Initial condition:** Five labelled teaching segments: precharge, ingress, totality, egress, recovery. Until a verified illumination/duration curve is integrated, use a disclosed [G] seven-unit allocation from the 14-unit jar. Essential package (circulation, minimum heat, dim grow light and guide light) costs 1 per segment, pump/camera readiness each 1 once; decorative floods 3 each activation. These totals replace elapsed-time demand in this fallback; never charge them on top of a second duration model.

**Interaction procedure:** Essentials ON in all five segments; prepare return pump in segment 1, camera in segment 2, floods OFF. Acknowledge all five segments and the return reserve. The main eclipse feed and family call occur during valid Earth contact, and egress is recorded after P-12 restoration.

**Accepted solution:** Essentials [1,1,1,1,1], pump [1,0,0,0,0], camera [0,1,0,0,0], floods all OFF; total 7 and E7 at recovery. Equivalent pump/camera placements before their deadlines are accepted. The verified-data release replaces this fallback with demand scaled by segment-hours/7.2 as specified in the source gameplay document and rebalances the forecast.

**Pass predicate:** All five essential packages scheduled, pump/camera each once before deadlines, allocation<=7 and five segment acknowledgements saved.

**Incorrect feedback:** Omitting essentials identifies the affected service. Spending more than the seven-unit protected allocation warns about the reserved recovery margin. Edit freely before commitment.

## State machine and triggers

LOCKED → AVAILABLE when `noor_known` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0601 → OBJECTIVE_2_DONE on EV-0602 → READY_TO_COMPLETE on EV-0603 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0601-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `eclipse_ready` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `eclipse_ready=true`, `M-0601=COMPLETE`, and `M-0602` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Protect essential services throughout. / Five essentials plus one pump and one camera equal seven. / Keep essentials ON, prepare pump in 1 and camera in 2, with floodlights OFF.
- **Journal after objective 1:** `M-0601: Kai named his fear of darkness and asked for support. We can plan with that fact.`
- **Journal after objective 2:** `M-0601: The eclipse plan keeps essentials and guide lights powered, with one return-pump operation and one camera operation.`
- **Journal after objective 3:** `M-0601: Everyone confirmed their station before the eclipse observation.`
- **Completion entry:** “Prepare a protected bus and a verified eclipse power transfer. Completed. Next: M-0602.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. eclipse_ready_pending; kai_plan_shared.

Next mission: **M-0602**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
