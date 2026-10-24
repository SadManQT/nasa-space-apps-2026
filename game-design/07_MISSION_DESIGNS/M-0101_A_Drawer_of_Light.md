# M-0101 — A Drawer of Light

## Mission identity

- **Chapter:** CH01 — Night One.
- **Primary location:** LOC-01; exact movement is listed by scene below.
- **Purpose:** Commission the habitat and plant the recovered pair.
- **Active-play target:** 8 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `arrival_accepted=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0101, SC-0102, SC-0103 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_01.md).
- **Characters:** Use the physical/remote/archive roster of SC-0101, SC-0102, SC-0103; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-01](../08_PUZZLE_DESIGNS.md#p-01).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-05,A-06,A-07,A-10,A-11,A-12,A-14,A-15,A-20,A-61; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

Control begins behind Mei at the mission table; no menu lecture.

Objective text: **Commission the habitat and plant the recovered pair.** Enter through LOC-01; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0101-O1

- **Scene / time / location:** SC-0101 / 2046-04-11 06:00 / LOC-01.
- **Objective text:** Read the charter and check all four crew roles.
- **Required interactions:** Walk to four role plaques; inspect the mission charter and emergency capsule card; select Accept assignment.
- **Environmental result:** Companions pin their colour labels; Rafi straightens his oversized helmet.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0101-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** All four plaques inspected AND charter accepted AND emergency card acknowledged. Set SC-0101_done once; never on mere zone entry.
- **Discovery:** The player controls the four named cadets, selected through specialist and team assessment.
- **Journal copy:** We accepted an assignment across the polar season cycle. Crew safety comes before every experiment.

### Objective M-0101-O2

- **Scene / time / location:** SC-0102 / Apr 11 10:00 / LOC-03.
- **Objective text:** Calibrate the probe and plant Alo and Tara.
- **Required interactions:** Complete P-01: verify storage seal, calibrate moisture probe, plant one seed per cassette, label independent test and reference.
- **Environmental result:** Mei places the seed with tweezers; Kai holds a work light without comment.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0102-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-01 passed AND both labels confirmed; set pair_planted_pending, not mission completion. Set SC-0102_done once; never on mere zone entry.
- **Discovery:** Only N. identifies the packet owner; the exterior unit is a sealed experiment.
- **Journal copy:** Two dry seeds were marked আলো and N. Alo is our external test plant; Tara is the indoor reference.

### Objective M-0101-O3

- **Scene / time / location:** SC-0103 / Apr 11 evening → Apr 25 03:36 / LOC-02.
- **Objective text:** Hang the hand light and record the first care photo.
- **Required interactions:** As Kai, hang the hand light at the locker and record a plant photo; confirm the labelled fourteen-day care montage.
- **Environmental result:** Rafi offers the lamp handle-first; dated thumbnails grow roots, stems and buds.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0103-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Hand light hung AND photo recorded AND time-advance confirmed; commit M-0101. Set SC-0103_done once; never on mere zone entry.
- **Discovery:** Kai’s attachment to light precedes the crisis; plants have been cared for between playable dates.
- **Journal copy:** Kai wanted a backup light. Rafi left one within reach. Two weeks of care brought the first buds.

## Puzzle mechanics included in this mission

**Initial condition:** Both cassettes empty; probe offset +10 displayed units; references read dry=10, wet=110.

**Interaction procedure:** Set zero using dry reference, span using wet reference; recheck dry=0 and wet=100. Scan packet seal, place one seed in each cassette, add water until 40–60 on the calibrated scale, select EXTERNAL TEST for Alo and INDOOR REFERENCE for Tara, close both seals.

**Accepted solution:** Order: dry zero → wet span → recheck → packet scan → one seed each → water 50 → distinct labels → seals. Accept any final moisture 40–60 inclusive; extra water can be removed to waste before sealing.

**Pass predicate:** Both calibrated moisture values in band, seed count 1+1, labels distinct, seals closed.

**Incorrect feedback:** Sealing is blocked until calibration; duplicate seed/label assignment is blocked with the occupied cassette named. Flooding prompts drain rather than kills the seed.

## State machine and triggers

LOCKED → AVAILABLE when `arrival_accepted` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0101 → OBJECTIVE_2_DONE on EV-0102 → READY_TO_COMPLETE on EV-0103 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0101-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `pair_planted` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `pair_planted=true`, `M-0101=COMPLETE`, and `M-0102` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Check the instrument before trusting it. / Use the two reference cups. / Dry must read 0, wet 100, then fill both to 50.
- **Journal after objective 1:** `M-0101: We accepted an assignment across the polar season cycle. Crew safety comes before every experiment.`
- **Journal after objective 2:** `M-0101: Two dry seeds were marked আলো and N. Alo is our external test plant; Tara is the indoor reference.`
- **Journal after objective 3:** `M-0101: Kai wanted a backup light. Rafi left one within reach. Two weeks of care brought the first buds.`
- **Completion entry:** “Commission the habitat and plant the recovered pair. Completed. Next: M-0102.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. pair_planted_pending; packet_initial_seen; unlock dated care montage.

Next mission: **M-0102**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
