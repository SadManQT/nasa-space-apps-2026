# M-0302 — Forty-Two

## Mission identity

- **Chapter:** CH03 — Moonquake.
- **Primary location:** LOC-07; exact movement is listed by scene below.
- **Purpose:** Make the annex safe, recover the map and harvest Alo’s legacy.
- **Active-play target:** 11 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `leak_sealed=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0304, SC-0305, SC-0306 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_03.md).
- **Characters:** Use the physical/remote/archive roster of SC-0304, SC-0305, SC-0306; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-06](../08_PUZZLE_DESIGNS.md#p-06).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07,SYS-09; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-05,A-06,A-07,A-14,A-15,A-19,A-27,A-28,A-30; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

Suited cadets enter the cold annex after the safety check.

Objective text: **Make the annex safe, recover the map and harvest Alo’s legacy.** Enter through LOC-07; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0302-O1

- **Scene / time / location:** SC-0304 / May 8 → May 16 / LOC-07.
- **Objective text:** Scan the old growth chart and vault map.
- **Required interactions:** Scan growth chart and vault route; exit and confirm the dated eight-day care montage to pod maturity to pod maturity.
- **Environmental result:** Mei leaves the frozen plants undisturbed; photographs become journal overlays.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0304-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Chart and map scanned AND suits cleared on exit AND maturity montage accepted. Set SC-0304_done once; never on mere zone entry.
- **Discovery:** The vault is a future objective; current biological care takes priority.
- **Journal copy:** The annex held frozen seedlings, not flowers. Its map points to an old cold-trap vault.

### Objective M-0302-O2

- **Scene / time / location:** SC-0305 / May 16 → May 21 / LOC-03.
- **Objective text:** Harvest and label all forty-two mature seeds.
- **Required interactions:** Complete P-06 maturity checks on May 16, confirm the dated five-day dry-down, then harvest on May 21, count groups and allocate twelve planting seeds plus thirty reserve; sleeve the petal.
- **Environmental result:** No exaggerated death collapse; the plant has naturally senesced. Hands pause before opening pods.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0305-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-06 inventory totals exactly 42 AND pressed petal stored. Set SC-0305_done once; never on mere zone entry.
- **Discovery:** Alo’s life continues through descendants, not through resurrection.
- **Journal copy:** Alo finished her life cycle. Twelve seeds go to planting; thirty stay protected. We kept a pressed petal.

### Objective M-0302-O3

- **Scene / time / location:** SC-0306 / May 21 → Oct 21 / LOC-03.
- **Objective text:** Plant the next generation and seal the reserve.
- **Required interactions:** Plant the allocated twelve; select a dedication for the seed tray; confirm five-month dated maintenance montage including repeated pollen care and backup checks.
- **Environmental result:** Player sets first seed; later photos show twelve current descendants, not five-month-old original annuals.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0306-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Twelve slots planted AND reserve sealed AND montage confirmed; commit M-0302. Set SC-0306_done once; never on mere zone entry.
- **Discovery:** The expedition becomes a family of plants; the mapped reserve expedition now has purpose.
- **Journal copy:** We planted twelve founder seeds. Later care records follow their descendants across five months.

## Puzzle mechanics included in this mission

**Initial condition:** On May 16 (plant day 35) pods mature; initial moisture 70; drying valve open; 42 seeds in six pods of 7. Hatch map has been scanned in preceding scene.

**Interaction procedure:** Confirm brown mature pods on camera and maturity chart; close irrigation to Alo only, never the whole greenhouse; run the dated May 16–21 dry-down to moisture 20; open six pods into six wells; count 7 each; allocate two wells (14), move two seeds back so planting 12 and reserve 30; sleeve petal and seal.

**Accepted solution:** Maturity confirmed → irrigation OFF for mature Alo → dry to<=20 → six×7=42 → planting 12/reserve 30 → seal and lineage label. Two allocation buttons can directly choose 12/30; arithmetic dragging not required.

**Pass predicate:** 42 total, 12 allocated, 30 sealed reserve, map scanned and petal stored.

**Incorrect feedback:** Early irrigation stop is blocked before maturity; selecting Tara’s live irrigation displays wrong plant and leaves it unchanged. A miscount reopens that well. Seeds are never lost by cursor error.

## State machine and triggers

LOCKED → AVAILABLE when `leak_sealed` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0304 → OBJECTIVE_2_DONE on EV-0305 → READY_TO_COMPLETE on EV-0306 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0302-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `seed_legacy` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `seed_legacy=true`, `M-0302=COMPLETE`, and `M-0401` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Harvest after the pods mature. / Keep twelve for planting and thirty protected. / Six wells of seven total 42; allocate 12 and 30.
- **Journal after objective 1:** `M-0302: The annex held frozen seedlings, not flowers. Its map points to an old cold-trap vault.`
- **Journal after objective 2:** `M-0302: Alo finished her life cycle. Twelve seeds go to planting; thirty stay protected. We kept a pressed petal.`
- **Journal after objective 3:** `M-0302: We planted twelve founder seeds. Later care records follow their descendants across five months.`
- **Completion entry:** “Make the annex safe, recover the map and harvest Alo’s legacy. Completed. Next: M-0401.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. seed_legacy_pending; old_garden_seedling_only; vault_route_known; founder_reserve=30.

Next mission: **M-0401**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
