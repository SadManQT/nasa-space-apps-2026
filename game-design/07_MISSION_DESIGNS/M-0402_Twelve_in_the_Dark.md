# M-0402 — Twelve in the Dark

## Mission identity

- **Chapter:** CH04 — Into the Cold Trap.
- **Primary location:** LOC-10; exact movement is listed by scene below.
- **Purpose:** Recover a sealed vault and stabilise its dry specimens at home.
- **Active-play target:** 15 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `ice_survey=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0404, SC-0405, SC-0406 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_04.md).
- **Characters:** Use the physical/remote/archive roster of SC-0404, SC-0405, SC-0406; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-08](../08_PUZZLE_DESIGNS.md#p-08).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-06,SYS-07,SYS-09; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-08,A-11,A-14,A-31,A-33,A-34,A-37,A-38; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

The vault exterior reads below the carrier’s safe handling band.

Objective text: **Recover a sealed vault and stabilise its dry specimens at home.** Enter through LOC-10; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0402-O1

- **Scene / time / location:** SC-0404 / Oct 21 late morning / LOC-10.
- **Objective text:** Sleeve and secure the sealed vault for transport.
- **Required interactions:** Begin P-08 recovery: probe external shell, seat insulated sleeve, latch cradle and transfer to rover without breaking the inner seal.
- **Environmental result:** Two-person lift; no bare hands on frozen metal; latch indicator changes word and icon.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0404-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-08 field recovery sequence validated AND case secured in rover. Set SC-0404_done once; never on mere zone entry.
- **Discovery:** Recovery includes contamination and condensation control.
- **Journal copy:** We recovered the whole insulated case without opening it in the cold.

### Objective M-0402-O2

- **Scene / time / location:** SC-0405 / Oct 22, back at base / LOC-03.
- **Objective text:** Warm the vault sealed, inventory its seeds and scan the lid.
- **Required interactions:** Finish P-08 sealed warming, inventory twelve distinct specimen labels, scan the lid inscription, send manifest to Ferreira.
- **Environmental result:** Mei opens only inside the glovebox; Amara labels each specimen without consuming it.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0405-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-08 complete AND twelve-item inventory saved AND manifest transmitted. Set SC-0405_done once; never on mere zone entry.
- **Discovery:** Ferreira helped the gardener return; twelve seeds are recovered, viability not yet assumed.
- **Journal copy:** The vault holds twelve distinct specimens, including cotton. Its lid asks us to speak to Ferreira about Expedition Zero.

### Objective M-0402-O3

- **Scene / time / location:** SC-0406 / Oct 22 → Dec 12 / LOC-01.
- **Objective text:** Read the relief-flight notice and prepare Ferreira’s locker.
- **Required interactions:** Inspect relief flight dates Dec 8–12; install the spare locker label; confirm dated routine-care transition.
- **Environmental result:** A fifth mug is placed without introducing a new playable hero.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0406-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Flight notice read AND locker prepared AND transition accepted; commit M-0402. Set SC-0406_done once; never on mere zone entry.
- **Discovery:** Ferreira will travel; consent request concerns personal history, not safety data.
- **Journal copy:** Ferreira travels December 8–12. She thinks she recognises the writer and is asking permission to name her.

## Puzzle mechanics included in this mission

**Initial condition:** Outer case cold; biological inner seal intact. Handling order unverified; inner seed temperature history recorded in insulated vault, not equal to lunar soil temperature.

**Interaction procedure:** Outside: read probe, fit sleeve, latch cradle, secure rover mount. At base: dock sealed case in dry glovebox, run warm-up from cold→cool→room as three confirmed stages, verify no condensation, open inner seal, inventory twelve distinct specimen labels from the vault ledger in 18, scan lid.

**Accepted solution:** Probe→sleeve→cradle→mount→return→dry glovebox→three-stage sealed warm-up→condensation check→open→12 labels.

**Pass predicate:** Twelve distinct specimens recorded; lid scanned; quarantine status set pending viability evaluation, not assumed healthy.

**Incorrect feedback:** Open command outside or before dry warm-up is blocked with condensation explanation. Wrong label can be corrected; a damaged-outer-case false alarm does not destroy specimens.

## State machine and triggers

LOCKED → AVAILABLE when `ice_survey` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0404 → OBJECTIVE_2_DONE on EV-0405 → READY_TO_COMPLETE on EV-0406 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0402-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `vault_recovered` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `vault_recovered=true`, `M-0402=COMPLETE`, and `M-0501` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Keep it sealed until home. / Warm dry seeds in their closed container. / Complete sleeve/cradle, then three warm-up stages in the glovebox before opening.
- **Journal after objective 1:** `M-0402: We recovered the whole insulated case without opening it in the cold.`
- **Journal after objective 2:** `M-0402: The vault holds twelve distinct specimens, including cotton. Its lid asks us to speak to Ferreira about Expedition Zero.`
- **Journal after objective 3:** `M-0402: Ferreira travels December 8–12. She thinks she recognises the writer and is asking permission to name her.`
- **Completion entry:** “Recover a sealed vault and stabilise its dry specimens at home. Completed. Next: M-0501.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. vault_recovered_pending; vault_mustard6; vault_cotton6; brought_home_line_seen.

Next mission: **M-0501**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
