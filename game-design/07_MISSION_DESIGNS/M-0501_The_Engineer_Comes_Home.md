# M-0501 — The Engineer Comes Home

## Mission identity

- **Chapter:** CH05 — Shooting Stars.
- **Primary location:** LOC-08; exact movement is listed by scene below.
- **Purpose:** Welcome Ferreira and assemble a factual evacuation sequence.
- **Active-play target:** 12 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `vault_recovered=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0501, SC-0502, SC-0503 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_05.md).
- **Characters:** Use the physical/remote/archive roster of SC-0501, SC-0502, SC-0503; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-09](../08_PUZZLE_DESIGNS.md#p-09).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-08,A-09,A-10,A-11,A-19,A-38,A-39,A-61; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

A scheduled lander arrives at the existing pad; the player waits behind the marked line.

Objective text: **Welcome Ferreira and assemble a factual evacuation sequence.** Enter through LOC-08; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0501-O1

- **Scene / time / location:** SC-0501 / Dec 12 arrival / LOC-08.
- **Objective text:** Wait for landing clearance and welcome Ferreira inside.
- **Required interactions:** After landing-clear indication, inspect cargo seal and escort Ferreira through the airlock; put her mug on the table.
- **Environmental result:** Ferreira removes gloves only inside; tired shoulders soften at the mug.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0501-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Landing clear AND cargo seal inspected AND Ferreira entered habitat. Set SC-0501_done once; never on mere zone entry.
- **Discovery:** Ferreira is now physically at Aurora; Rao remains on Earth.
- **Journal copy:** Ferreira arrived at Aurora with relief cargo and a replacement relay controller. Rao remains on Earth.

### Objective M-0501-O2

- **Scene / time / location:** SC-0502 / Dec 14 afternoon / LOC-01.
- **Objective text:** Reconstruct the evacuation and verify the boarding record.
- **Required interactions:** Complete P-09 evidence chronology; compare boarding count with expedition roster and select the supported conclusion.
- **Environmental result:** Ferreira stands beside, not over, the player’s board.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0502-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-09 supported chronology committed AND all crew boarding conclusion selected. Set SC-0502_done once; never on mere zone entry.
- **Discovery:** No one died or was abandoned; Noor’s identity awaits consented personal context.
- **Journal copy:** The 2034 fault preceded the evacuation. All four crew members boarded. Nobody was abandoned.

### Objective M-0501-O3

- **Scene / time / location:** SC-0503 / Dec 14 dusk / LOC-01.
- **Objective text:** Ask Ferreira about the order and the seeds.
- **Required interactions:** Choose Ask about the order or Ask about the seeds; both exact responses remain available and both return to the same supported facts.
- **Environmental result:** Ferreira sits at the cadets’ eye level; no authority pose.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0503-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Both factual question topics read/heard OR accessible Read all selected; commit M-0501. Set SC-0503_done once; never on mere zone entry.
- **Discovery:** Ferreira’s withholding was avoidant communication; she admits it rather than being excused by a fake secret rule.
- **Journal copy:** Ferreira regretted avoiding the personal story. Retreat was the safe order, and she helped the gardener return.

## Puzzle mechanics included in this mission

**Initial condition:** Cards unplaced: seedling chart Apr 3, relay/power fault Apr 4 12:00, evacuation order 12:10, all crew boarding 12:40.

**Interaction procedure:** Place chart→fault→order→boarding; match the two highlighted personal signatures to FER and gardener N.R.; compare entire crew count 4 departed/4 boarded; select all crew returned, trial stopped before flowers.

**Accepted solution:** Chronological order chart/fault/order/boarding; supported conclusion ALL FOUR RETURNED. Do not identify the gardener’s full name from initials alone.

**Pass predicate:** Four cards in timestamp order and supported conclusion selected.

**Incorrect feedback:** Abandoned gardener conclusion highlights contradictory boarding evidence. Reordering remains free; no antagonist accusation score.

## State machine and triggers

LOCKED → AVAILABLE when `vault_recovered` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0501 → OBJECTIVE_2_DONE on EV-0502 → READY_TO_COMPLETE on EV-0503 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0501-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `zero_sequence` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `zero_sequence=true`, `M-0501=COMPLETE`, and `M-0502` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Use the timestamps. / Boarding happened after the retreat order. / All four signatures boarded; the garden, not a person, was left behind.
- **Journal after objective 1:** `M-0501: Ferreira arrived at Aurora with relief cargo and a replacement relay controller. Rao remains on Earth.`
- **Journal after objective 2:** `M-0501: The 2034 fault preceded the evacuation. All four crew members boarded. Nobody was abandoned.`
- **Journal after objective 3:** `M-0501: Ferreira regretted avoiding the personal story. Retreat was the safe order, and she helped the gardener return.`
- **Completion entry:** “Welcome Ferreira and assemble a factual evacuation sequence. Completed. Next: M-0502.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. zero_sequence_pending; zero_all_returned; ferreira_admission_ready.

Next mission: **M-0502**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
