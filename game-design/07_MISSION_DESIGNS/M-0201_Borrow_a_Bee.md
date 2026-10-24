# M-0201 — Borrow a Bee

## Mission identity

- **Chapter:** CH02 — Be the Bee.
- **Primary location:** LOC-03; exact movement is listed by scene below.
- **Purpose:** Cross-pollinate Alo and Tara without breaking containment.
- **Active-play target:** 14 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `first_bloom=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0201, SC-0202, SC-0203 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_02.md).
- **Characters:** Use the physical/remote/archive roster of SC-0201, SC-0202, SC-0203; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-03](../08_PUZZLE_DESIGNS.md#p-03).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07,SYS-09; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-05,A-06,A-07,A-11,A-14,A-15,A-17,A-18; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

Earth contact returns as the player looks at Tara.

Objective text: **Cross-pollinate Alo and Tara without breaking containment.** Enter through LOC-03; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0201-O1

- **Scene / time / location:** SC-0201 / Apr 30 morning / LOC-03.
- **Objective text:** Inspect Tara and collect the pollination protocol.
- **Required interactions:** Inspect both plant identity tags and request the cross-pollination protocol at the indoor bench.
- **Environmental result:** Mei moves Tara’s nameplate beside Alo’s on the board.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0201-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Both identity tags inspected AND pollination protocol opened. Set SC-0201_done once; never on mere zone entry.
- **Discovery:** Both compatible individuals are needed for the selected self-incompatible cultivar.
- **Journal copy:** Tara has flowered too. Our selected mustard plants need compatible pollen from one another.

### Objective M-0201-O2

- **Scene / time / location:** SC-0202 / Apr 30–May 6, three reciprocal bee runs / LOC-05.
- **Objective text:** Transfer pollen between Alo and Tara through sealed ports.
- **Required interactions:** Complete P-03’s three reciprocal runs, with one E1/A1 route charge per run, space-weather check and sealed glove ports; log seven care dates. Inspect Alo’s purple stem and Tara’s green stem, then record an offspring-colour prediction.
- **Environmental result:** Brush tip collects visible magnified grains; no pollen floats in lunar vacuum.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0202-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-03 three reciprocal runs validated AND seven care dates and stem prediction recorded. Set SC-0202_done once; never on mere zone entry.
- **Discovery:** Pollination is a relationship between plants, not a button that immediately produces pods.
- **Journal copy:** We used clean brushes and sealed carriers to cross-pollinate Alo and Tara.

### Objective M-0201-O3

- **Scene / time / location:** SC-0203 / May 6 afternoon / LOC-01.
- **Objective text:** Record the care visits and inspect the recorder label.
- **Required interactions:** Record pollination journal entry and inspect the recorder’s equipment label to unlock the investigation station.
- **Environmental result:** Rafi adds a small paper bee; Mei writes the actual date.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0203-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Journal pollination entry read AND recorder label inspected; commit M-0201. Set SC-0203_done once; never on mere zone entry.
- **Discovery:** Reproduction takes weeks; the recorder shares a part number with the old garden equipment.
- **Journal copy:** We logged seven pollination visits across seven days. Seeds need time to develop.

## Puzzle mechanics included in this mission

**Initial condition:** Flowers open; brush A and B clean; carrier empty; donor and recipient fields unset. Entry E14/20,A10/10,H6,C8,R18. Three sampled daylight operations use FULL/O0 and E1/A1 per reciprocal run, with ordinary basic1 and breathing1: after the three sampled operations E16,A4,H9,C10,R14.4. The dated background ledger separately covers unsampled care/consumption; planned food supply of at least14 crew-days over the seven-day interval leaves4 after total crew consumption28. No hidden refill occurs during a bee run.

**Interaction procedure:** Scan donor Tara; collect yellow grains from anthers with brush A using select/confirm; seal carrier; transfer through pressure interlock; scan recipient Alo; touch its receptive stigma through glove ports. Reverse using clean brush B from Alo to Tara. Make three reciprocal runs on days 1, 4 and 7 (April 30–May 6), with seven dated care visits. Check space weather before every run; charge E1/A1 once per whole reciprocal cycle, including its four airlock transitions. Record Alo’s purple/Tara’s green stem prediction; show the result in Chapter 4 without promising a genotype ratio.

**Accepted solution:** Tara anther → sealed A → Alo stigma; Alo anther → sealed B → Tara stigma; confirm donor≠recipient each way; repeat for three reciprocal runs across seven dated days; record the stem prediction.

**Pass predicate:** Three reciprocal runs valid, each charged E1/A1 once; seals passed, seven care visits and stem prediction logged.

**Incorrect feedback:** Touching petal shows no transfer; using own pollen explains cultivar incompatibility; dirty brush prompts replace tip. No drag precision score.

## State machine and triggers

LOCKED → AVAILABLE when `first_bloom` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0201 → OBJECTIVE_2_DONE on EV-0202 → READY_TO_COMPLETE on EV-0203 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0201-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `pollen_shared` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `pollen_shared=true`, `M-0201=COMPLETE`, and `M-0202` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** A flower needs pollen from its partner. / Take pollen from the anther to the other plant’s stigma. / Use A for Tara→Alo and clean B for Alo→Tara.
- **Journal after objective 1:** `M-0201: Tara has flowered too. Our selected mustard plants need compatible pollen from one another.`
- **Journal after objective 2:** `M-0201: We used clean brushes and sealed carriers to cross-pollinate Alo and Tara.`
- **Journal after objective 3:** `M-0201: We logged seven pollination visits across seven days. Seeds need time to develop.`
- **Completion entry:** “Cross-pollinate Alo and Tara without breaking containment. Completed. Next: M-0202.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. pollen_shared_pending; lineage_parent_pair = Alo × Tara.

Next mission: **M-0202**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
