# M-0602 — All the Sunrises

## Mission identity

- **Chapter:** CH06 — The Red Ring.
- **Primary location:** LOC-01; exact movement is listed by scene below.
- **Purpose:** Use a camera to observe the eclipse and restore a feeder safely.
- **Active-play target:** 12 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `eclipse_ready=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0604, SC-0605, SC-0606 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_06.md).
- **Characters:** Use the physical/remote/archive roster of SC-0604, SC-0605, SC-0606; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-12](../08_PUZZLE_DESIGNS.md#p-12).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-09,A-10,A-11,A-12,A-40,A-42; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

A red atmospheric rim appears on the filtered monitor.

Objective text: **Use a camera to observe the eclipse and restore a feeder safely.** Enter through LOC-01; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0602-O1

- **Scene / time / location:** SC-0604 / Jan 12 eclipse window / LOC-01.
- **Objective text:** Record ingress and the red ring on the filtered feed.
- **Required interactions:** Record three filtered observations in P-12: ingress, ring and egress; inspect the conceptual limb diagram and connect Kai’s family call during the valid Earth window. The Bangladesh inset is illustrative; precise sunrise timing awaits geometry verification.
- **Environmental result:** One hand touches the screen bezel, not the scientific image.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0604-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Ingress and ring observations logged AND diagram inspected AND family call connected; await feeder interruption. Set SC-0604_done once; never on mere zone entry.
- **Discovery:** N’s identity is already known; eclipse date is historical astronomy, local camera staging is authored.
- **Journal copy:** Sunlight refracted through Earth’s atmospheric limb makes the red rim. Noor sent a memory signed N.

### Objective M-0602-O2

- **Scene / time / location:** SC-0605 / Jan 12, during protected transfer / LOC-02.
- **Objective text:** Isolate F2, reset safely and record egress.
- **Required interactions:** Finish P-12: isolate feeder F2, check zero fault indication, reset F2, test only the camera branch and log egress.
- **Environmental result:** Kai uses the hand light and speaks each action; no shaking hands after correct completion.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0605-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-12 F2 safely restored AND egress record saved. Set SC-0605_done once; never on mere zone entry.
- **Discovery:** Kai’s courage is a repeatable process with support, not absence of fear.
- **Journal copy:** Kai restored the failed feeder with Rafi and Amara on the channel. The protected bus stayed alive.

### Objective M-0602-O3

- **Scene / time / location:** SC-0606 / Jan 13 → Feb 14 / LOC-01.
- **Objective text:** Record the monitoring plan and check cotton and reserves.
- **Required interactions:** Pin a monitoring task, inspect cotton growth and reserve seal, accept a labelled routine-care montage ending at a fresh February warning.
- **Environmental result:** Photos show routine repairs and new plant generations; crew clothes and labels evolve.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0606-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** Monitoring task pinned AND cotton/reserve checked AND dated transition accepted; commit M-0602. Set SC-0606_done once; never on mere zone entry.
- **Discovery:** January observation and February storm are separated by ongoing monitoring, not prophecy.
- **Journal copy:** We continued routine observations and care. A replay warning arrived in February; January’s image did not predict its date.

## Puzzle mechanics included in this mission

**Initial condition:** Camera filtered; protected bus normal; F2 trips during ring observation. Camera and view-screen branch only; habitat services unaffected.

**Interaction procedure:** Log ingress and ring, inspect conceptual atmosphere diagram; on trip isolate F2, confirm current=0 and FAULT CLEARED, reset breaker, close isolation, test camera branch only, log egress. Acknowledge companion’s radio support.

**Accepted solution:** Isolate→zero/fault check→reset→reconnect→camera test; three observation records include the restored egress.

**Pass predicate:** F2 tested, ingress/ring/egress recorded, support call acknowledged.

**Incorrect feedback:** Reset before isolation is interlocked and explained; choosing protected main bus displays survival services warning and does not switch it. Egress waits for authored restoration, not real-time solar timing.

## State machine and triggers

LOCKED → AVAILABLE when `eclipse_ready` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0604 → OBJECTIVE_2_DONE on EV-0605 → READY_TO_COMPLETE on EV-0606 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0602-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `kai_supported` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `kai_supported=true`, `M-0602=COMPLETE`, and `M-0701` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** Keep the protected bus untouched. / Isolate the failed feeder before reset. / F2 off, confirm 0, reset, reconnect, camera test.
- **Journal after objective 1:** `M-0602: Sunlight refracted through Earth’s atmospheric limb makes the red rim. Noor sent a memory signed N.`
- **Journal after objective 2:** `M-0602: Kai restored the failed feeder with Rafi and Amara on the channel. The protected bus stayed alive.`
- **Journal after objective 3:** `M-0602: We continued routine observations and care. A replay warning arrived in February; January’s image did not predict its date.`
- **Completion entry:** “Use a camera to observe the eclipse and restore a feeder safely. Completed. Next: M-0701.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. kai_supported_pending; eclipse_observed.

Next mission: **M-0701**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
