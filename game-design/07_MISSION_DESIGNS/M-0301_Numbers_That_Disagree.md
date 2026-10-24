# M-0301 — Numbers That Disagree

## Mission identity

- **Chapter:** CH03 — Moonquake.
- **Primary location:** LOC-02; exact movement is listed by scene below.
- **Purpose:** Find and repair the leak through independent observations.
- **Active-play target:** 14 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `recorder_context=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0301, SC-0302, SC-0303 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_03.md).
- **Characters:** Use the physical/remote/archive roster of SC-0301, SC-0302, SC-0303; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-05](../08_PUZZLE_DESIGNS.md#p-05).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-10,A-11,A-25,A-26; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

Alarm panel marks the oxygen tank red.

Objective text: **Find and repair the leak through independent observations.** Enter through LOC-02; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0301-O1

- **Scene / time / location:** SC-0301 / May 6 22:05 / LOC-02.
- **Objective text:** Read all three pressure taps with the manual gauge.
- **Required interactions:** Collect the manual gauge and inspect three pressure taps before touching isolation controls.
- **Environmental result:** Amara steadies her hand on the gauge; Kai lights the markings.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0301-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Manual gauge equipped AND three taps read. Set SC-0301_done once; never on mere zone entry.
- **Discovery:** The protected plant atmosphere remains separate from the leaking room line.
- **Journal copy:** Independent pressure readings can test the electronic diagnosis.

### Objective M-0301-O2

- **Scene / time / location:** SC-0302 / May 6 22:10 → May 8 03:00 / LOC-02.
- **Objective text:** Isolate the garden spur, clamp the leak and verify pressure.
- **Required interactions:** Complete P-05: isolate garden spur, confirm mechanical pressure hold, apply clamp, reopen slowly and run five checks.
- **Environmental result:** Hands turn a labelled valve; pressure loss stops before patching.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0302-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-05 stable verification passed; set leak_sealed_pending. Set SC-0302_done once; never on mere zone entry.
- **Discovery:** The mechanical test proves the diagnosis; no blind faith in a HUD colour.
- **Journal copy:** The garden spur leaked; the main tank did not. Five stable checks confirmed our repair.

### Objective M-0301-O3

- **Scene / time / location:** SC-0303 / May 7 morning / LOC-07.
- **Objective text:** Isolate the annex and inspect its hatch safely.
- **Required interactions:** Use camera inspection, disconnect annex utility feed and confirm zero differential before opening the safe viewing hatch; physical entry waits for suit check.
- **Environmental result:** Rafi fits a warning marker; camera crawls through an existing port.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0303-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Utility feed isolated AND zero differential confirmed AND hatch view inspected; commit M-0301. Set SC-0303_done once; never on mere zone entry.
- **Discovery:** Ferreira acknowledges her involvement and shares all safety facts promptly.
- **Journal copy:** Ferreira served on Expedition Zero. She shared the safety report and repair diagrams.

## Puzzle mechanics included in this mission

**Initial condition:** Entry E14/20,A10/10,H6,C8,R18. Four daylight investigation phases of7.2h use DIM/O0, with basic E1 and light E1. Normal breathing A1 per phase; unresolved leak A1 in phases1–3, sealed before phase4 consumption. Witness ends E18,A3,H6,C8,R13.2. At most two location inspections per phase. Six candidates: main tank, habitat trunk, garden feedthrough, return line, airlock seal, annex branch. Initial panel uncertainty means location labels are candidates, not proof. At phase 2 an aftershock opens the annex branch; its automatic isolation must be verified before reopening the garden. Mechanical readings at t0/t10: MAIN 100/100, GARDEN 82/74, RETURN 100/100, relative test units.

**Interaction procedure:** Compare all six candidates using the three trunk taps and two location checks per phase; verify the aftershock annex isolation. Read all taps; close GARDEN isolation valve; recheck MAIN remains 100 and isolated GARDEN stays 74; fit clamp to GARDEN feedthrough from pressurised safe side; reopen slowly; run five 2-second checks.

**Accepted solution:** Compare the six candidates within four investigation phases, verify the aftershock annex isolation, then isolate GARDEN only → verify stable trunk → apply clamp → open GARDEN slowly → five readings 100/100/100. Clamp cannot seat on a pressurised leaking connection.

**Pass predicate:** Six candidates investigated within four phases, aftershock annex isolation verified, and five consecutive stable readings after correct clamp and reopening.

**Incorrect feedback:** Closing MAIN produces a protected reserve warning and can be reopened immediately; wrong clamp location cannot latch; recheck explains remaining pressure fall.

## State machine and triggers

LOCKED → AVAILABLE when `recorder_context` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0301 → OBJECTIVE_2_DONE on EV-0302 → READY_TO_COMPLETE on EV-0303 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0301-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `leak_sealed` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `leak_sealed=true`, `M-0301=COMPLETE`, and `M-0302` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Which reading changes over time? / Compare the manual garden reading. / Close GARDEN, clamp its feedthrough, reopen and verify five steady readings.
- **Journal after objective 1:** `M-0301: Independent pressure readings can test the electronic diagnosis.`
- **Journal after objective 2:** `M-0301: The garden spur leaked; the main tank did not. Five stable checks confirmed our repair.`
- **Journal after objective 3:** `M-0301: Ferreira served on Expedition Zero. She shared the safety report and repair diagrams.`
- **Completion entry:** “Find and repair the leak through independent observations. Completed. Next: M-0302.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. leak_sealed_pending; manual_gauge_trusted.

Next mission: **M-0302**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
