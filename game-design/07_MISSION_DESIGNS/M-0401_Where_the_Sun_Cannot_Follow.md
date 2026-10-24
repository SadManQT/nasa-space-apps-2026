# M-0401 — Where the Sun Cannot Follow

## Mission identity

- **Chapter:** CH04 — Into the Cold Trap.
- **Primary location:** LOC-09; exact movement is listed by scene below.
- **Purpose:** Plan the cold-trap route, survey ice and retain a return reserve.
- **Active-play target:** 18 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `seed_legacy=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0401, SC-0402, SC-0403 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_04.md).
- **Characters:** Use the physical/remote/archive roster of SC-0401, SC-0402, SC-0403; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-07](../08_PUZZLE_DESIGNS.md#p-07).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-06,SYS-07; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-08,A-14,A-31,A-32,A-33,A-34,A-35,A-36; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

Rafi stands beside the pressurised rover checklist.

Objective text: **Plan the cold-trap route, survey ice and retain a return reserve.** Enter through LOC-08; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0401-O1

- **Scene / time / location:** SC-0401 / Oct 21 06:00 / LOC-08.
- **Objective text:** Check the rover, carrier and base handover.
- **Required interactions:** Compare the saved stem prediction with the twelve descendants (seven purple, five green [F], no promised genetic ratio). Check rover seal, take scanner and closed carrier, leave Mei and Amara’s base handover and open P-07 route planning.
- **Environmental result:** Rafi checks each passenger harness without a joke at his expense.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0401-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Seal, scanner, carrier and base handover checks complete. Set SC-0401_done once; never on mere zone entry.
- **Discovery:** Rafi’s caution is recognised as leadership.
- **Journal copy:** Rafi and Kai take the field trip. Mei and Amara remain at Aurora. Our route must include a safe return.

### Objective M-0401-O2

- **Scene / time / location:** SC-0402 / Oct 21 morning / LOC-09.
- **Objective text:** Choose the safe ridge and verify the ice-bearing sample.
- **Required interactions:** Complete P-07 route B, reference scan and three-point ice-bearing sample comparison; place and test all three beacons before the blind corners. The base team’s slope map and rover team’s headlight view are separate role cards.
- **Environmental result:** Wheels grip slowly; scanner contacts soil; sample remains in a sealed cup.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0402-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-07 safe route and calibrated sample completed; ice_survey_pending. Set SC-0402_done once; never on mere zone entry.
- **Discovery:** The survey supports ice-bearing soil, not instantly drinkable water or a complete mining system.
- **Journal copy:** The surveyed ridge meets our slope and reserve limits. Calibrated readings support ice-bearing soil.

### Objective M-0401-O3

- **Scene / time / location:** SC-0403 / Oct 21 10:30 / LOC-10.
- **Objective text:** Photograph the vault and secure the closed carrier.
- **Required interactions:** Photograph marker and case; tether the carrier beside it; inspect intact outer latch without opening the biological seal.
- **Environmental result:** Rafi clips a tether; Kai brushes only the external identification window.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0403-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Marker and case photographed AND carrier tethered AND seal visually intact; commit M-0401. Set SC-0403_done once; never on mere zone entry.
- **Discovery:** The vault was deliberately deposited on an earlier authorised route.
- **Journal copy:** A human-made vault matches the old map. We will keep its biological seal closed until home.

## Puzzle mechanics included in this mission

**Initial condition:** Base E14/20,A8/10,H6,C8,R18; two daylight base shifts use DIM/O0, cost E2 each and breathe A0.5 for two home cadets, ending E18,A7,H6,C8,R16.8. The two rover occupants have an independent 48-hour consumables manifest covering the dated round trip; never charge them again at base. Rover resource 100, mandatory return reserve 30. Routes: A short 8 km cost 35 each way, slope 24°; B ridge 12 km cost 30 each way, max 12°; C shadow 10 km cost 40 each way, slope 18°. Rover design limit 15°.

**Interaction procedure:** Inspect route cards; choose a route satisfying slope AND roundtrip reserve. Use the base-only slope card and rover-only headlight card to agree on the route. Place/test three beacons before blind corners. Drive three 100 m playable segments separated by labelled cruise. On route B stop at reference and sample points: dry reference signal 2; samples 2, 18, 19. Set threshold reference+10=12 and tag the two above threshold; collect one sealed sample.

**Accepted solution:** B is the only valid route:100−30−30=40>=30 and 12°<=15°. Calibrate at 2, threshold 12; tag 18 and 19; retain 2 as negative control; collect one positive sample.

**Pass predicate:** Valid route chosen, three beacons linked, three stops reached, reference recorded, two positives tagged, one sample sealed, return reserve forecast>=30.

**Incorrect feedback:** Route A fails slope regardless of energy; C fails slope and reserve. Uncalibrated positive reports are marked unverified. Off-road driving stops at a warning boundary, never tumbles into an unwinnable pit.

## State machine and triggers

LOCKED → AVAILABLE when `seed_legacy` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0401 → OBJECTIVE_2_DONE on EV-0402 → READY_TO_COMPLETE on EV-0403 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0401-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `ice_survey` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `ice_survey=true`, `M-0401=COMPLETE`, and `M-0402` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** A short road may be too steep. / Check both the return cost and slope. / Choose B, use dry 2, then tag 18 and 19.
- **Journal after objective 1:** `M-0401: Rafi and Kai take the field trip. Mei and Amara remain at Aurora. Our route must include a safe return.`
- **Journal after objective 2:** `M-0401: The surveyed ridge meets our slope and reserve limits. Calibrated readings support ice-bearing soil.`
- **Journal after objective 3:** `M-0401: A human-made vault matches the old map. We will keep its biological seal closed until home.`
- **Completion entry:** “Plan the cold-trap route, survey ice and retain a return reserve. Completed. Next: M-0402.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. ice_survey_pending; return_route_B; sample_verified. Resource units are game abstractions.

Next mission: **M-0402**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
