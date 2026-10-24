# M-0102 — Keep the Night

## Mission identity

- **Chapter:** CH01 — Night One.
- **Primary location:** LOC-01; exact movement is listed by scene below.
- **Purpose:** Prepare, survive and restore shared water before first light.
- **Active-play target:** 20 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `pair_planted=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0104, SC-0105, SC-0106 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_01.md).
- **Characters:** Use the physical/remote/archive roster of SC-0104, SC-0105, SC-0106; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-02](../08_PUZZLE_DESIGNS.md#p-02).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07,SYS-09; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-05,A-06,A-07,A-09,A-10,A-11,A-12,A-13,A-14,A-15,A-16,A-21,A-22,A-23,A-24,A-29,A-61; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

Ferreira calls a shelter drill while daylight still reaches the masts.

Objective text: **Prepare, survive and restore shared water before first light.** Enter through LOC-04; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0102-O1

- **Scene / time / location:** SC-0104 / Apr 25 03:36–18:00 / LOC-04.
- **Objective text:** Share all four observations and prepare before sunset.
- **Required interactions:** Deliver Kai and Amara’s private cards in shift 1 and Rafi’s card in shift 2; invite Share/discussion; acknowledge each role’s setting or Solo auto-approval; perform the no-cost drill; set and commit daylight shifts 1–2 in P-02.
- **Environmental result:** Water demonstration uses a transparent test tube; permanent resource totals change only at commit.
- **Dialogue trigger:** SC-0104 lines bind to the shift-specific triggers in CHAPTER_01; drill/warning at shift2, never all at zone entry.
- **Exact completion:** Role settings acknowledged AND drill acknowledged AND daylight shifts 1–2 committed. Set SC-0104_done once; never on mere zone entry.
- **Discovery:** Specialist observations are shared safety information, not competitive secrets.
- **Journal copy:** We rehearsed the shelter and stored oxygen while daylight power was available.

### Objective M-0102-O2

- **Scene / time / location:** SC-0105 / Apr 25 18:00–Apr 27 06:00 / LOC-01.
- **Objective text:** Protect the crew through the storm and return the garden water.
- **Required interactions:** Deliver Mei’s private card at shift 3; Earth-set occurs at shift 4. Complete dark shifts 3–7 of P-02; choose PUMP, STACK or prepared WAIT at shift 5; restore borrowed water where needed; enter shelter before committing exposed shifts.
- **Environmental result:** Kai grips and releases the hand light; water rises; shutters close; suit radios continue.
- **Dialogue trigger:** SC-0105 Earth-set line at shift4, particle alarm lines at shift5; pause input timers for each. No live Earth voice after contact closes.
- **Exact completion:** P-02 reaches sunrise with crew_safe AND plant_alive; loss outcome routes to checkpoint before this gate. Set SC-0105_done once; never on mere zone entry.
- **Discovery:** Absence of Earth contact does not disable local systems or remove the crew’s ability to act.
- **Journal copy:** The Earth link went down, but our local radios worked. Shielding water had to return to the plants.

### Objective M-0102-O3

- **Scene / time / location:** SC-0106 / Apr 27 06:00 / LOC-03.
- **Objective text:** Check the chamber and photograph Alo’s first flower.
- **Required interactions:** Open the safe viewing shutter, tag the first-bloom image, listen or read the old care message; use photo framing for the earned Bloom or Golden result.
- **Environmental result:** Alo opens; the recorder activates only on image tagging; companions lean in without obscuring the flower.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0106-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Bloom image tagged AND recording heard/read; commit M-0102 and first_bloom. Set SC-0106_done once; never on mere zone entry.
- **Discovery:** The old gardener anticipated a future bloom but did not know when or whether one would occur.
- **Journal copy:** Alo bloomed at first light. Tagging the image triggered an old recording from N.

## Puzzle mechanics included in this mission

**Initial condition:** E14/20, A6/10, Alo H6/10, W0/6, K0/2, crop C8/10, rations R12 crew-days, exposure Z0. Shifts 1–2 daylight (+8 each); 3–7 dark. Each shift is 7.2 h, so darkness totals 36 h.

**Interaction procedure:** Deliver the four role facts at their specified shifts; inspect, discuss, preview, choose physical actions and commit once. Drill at shift 2, Earth-set at shift 4, alarm at shift 5. PUMP, STACK or WAIT is one exclusive alarm choice. Resolve exposure before the shift-6 ordinary drain.

**Accepted solution:** The all-COZY Bloom witness in the numeric contract ends E2,A1,H1,W0,K0,C3,R3.6,Z2 with no blackout. The Golden witness ends E0,A1,H5,W0,K0,C9,R3.6,Z2 with no blackout. Exactly E0 is not a blackout. Additional PUMP and STACK witnesses are listed there.

**Pass predicate:** Complete seven shifts with A>0, Z<=3, all four crew sheltered during exposure, and H>0. Golden requires all three stars (safe exposure, no blackout, living Alo) plus H>=5. Other safe/loss outcomes remain viewable without unlocking Chapter 2.

**Incorrect feedback:** A negative energy balance causes the published blackout penalties; it is not an automatic mission stop. A<=0 or unsafe exposure stops operations; H0 gives Alo lost if the crew completes safely. Show the cause and offer the complete last-shift checkpoint. Invalid transfer directions do not create water.

## State machine and triggers

LOCKED → AVAILABLE when `pair_planted` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0104 → OBJECTIVE_2_DONE on EV-0105 → READY_TO_COMPLETE on EV-0106 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0102-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `first_bloom` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `first_bloom=true`, `M-0102=COMPLETE`, and `M-0201` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Store air while sunlight would overflow. / Prepare shielding before the alarm, then return the water. / Open the worked Bloom plan or Guided plan.
- **Journal after objective 1:** `M-0102: We rehearsed the shelter and stored oxygen while daylight power was available.`
- **Journal after objective 2:** `M-0102: The Earth link went down, but our local radios worked. Shielding water had to return to the plants.`
- **Journal after objective 3:** `M-0102: Alo bloomed at first light. Tagging the image triggered an old recording from N.`
- **Completion entry:** “Prepare, survive and restore shared water before first light. Completed. Next: M-0201.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. first_bloom_pending; night_score; specialist observations shared; permanent first_bloom only after SC-0106.

Next mission: **M-0201**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
