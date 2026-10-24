# M-0801 — The Long Road

## Mission identity

- **Chapter:** CH08 — The Lighthouse.
- **Primary location:** LOC-11; exact movement is listed by scene below.
- **Purpose:** Prepare two teams and traverse the relay route with verified reserves.
- **Active-play target:** 20 minutes, excluding freely extended dialogue reading and optional exploration.
- **Prerequisite:** `route_clear=true`; only New Game establishes arrival_accepted; all later prerequisites require their owning mission to be COMPLETE. No optional collectible blocks this mission.
- **Scenes:** SC-0801, SC-0802, SC-0803 — [chapter script](../06_SCENE_SCRIPTS/CHAPTER_08.md).
- **Characters:** Use the physical/remote/archive roster of SC-0801, SC-0802, SC-0803; the scene roster is authoritative and includes anonymous recordings without exposing names in player UI.
- **Puzzle:** [P-15](../08_PUZZLE_DESIGNS.md#p-15).
- **Systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-06,SYS-07,SYS-09; plus SYS-08 save, SYS-10 accessibility, SYS-11 UI, SYS-12 audio in every mission.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-10,A-11,A-12,A-14,A-28,A-31,A-33,A-34,A-42,A-44,A-45; plus shared A-48–A-61 from [asset manifest](../14_ASSET_PRODUCTION_LIST.md).

## Starting situation and immediate objective

The rover cabin is lit while Aurora remains partly sunlit.

Objective text: **Prepare two teams and traverse the relay route with verified reserves.** Enter through LOC-08; selectable cadets are restricted to those physically present. The initial viewpoint uses the currently selected locally present cadet (Mei at campaign start); remote FER/RAO/NOO never becomes player-controlled.

## Ordered player experience

### Objective M-0801-O1

- **Scene / time / location:** SC-0801 / Apr 8 00:00 / LOC-08.
- **Objective text:** Check seventy-two-hour supplies and depart on the surveyed road.
- **Required interactions:** Start P-15 loadout and route confirmation; verify 72-hour supply indicator and 120-km destination; close airlock after farewells.
- **Environmental result:** Passengers buckle; Mei touches the closed cabin window from the habitat side.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0801-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-15 departure checklist validated AND rover airlock sealed. Set SC-0801_done once; never on mere zone entry.
- **Discovery:** Journey duration and supplies are explicit before the dramatic departure.
- **Journal copy:** The final route is 120 km each way. We budgeted 24 h outbound, 3 h repair and 24 h return.

### Objective M-0801-O2

- **Scene / time / location:** SC-0802 / Apr 8 00:00–17:00 outbound / LOC-11.
- **Objective text:** Restore marker two and verify the repeater chain.
- **Required interactions:** Complete route segment of P-15: stop within pad zone, set brake, replace repeater battery, confirm adjacent link and continue via all three markers.
- **Environmental result:** Ferreira holds the cabin checklist while Rafi checks suit seal; player performs a short tethered repair.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0802-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** All three repeater links passed AND100-km approach marker reached at Apr 8 17:00; remaining cruise waits for the home-team handover. Set SC-0802_done once; never on mere zone entry.
- **Discovery:** Repeaters create the necessary Aurora-to-summit link; the route is useful infrastructure.
- **Journal copy:** The road repeaters will let the summit hear Aurora. We restored the dead marker before continuing.

### Objective M-0801-O3

- **Scene / time / location:** SC-0803 / Apr 8 18:00 → Apr 9 00:00 / LOC-03.
- **Objective text:** Set the home garden loop and acknowledge summit arrival.
- **Required interactions:** Finish P-15 home handover: set garden minimum heat, dim lamps, return loop OPEN and verify two independent pressure readings; acknowledge summit arrival packet.
- **Environmental result:** Mei adjusts a nameplate; Amara repeats the old manual gauge check calmly.
- **Dialogue trigger:** entering the marked interaction zone within 2 m and choosing Inspect/Start queues DL-0803-01 onward; line order is fixed, interruptions follow dialogue contract. Scripted quake/alarm trigger only at the listed objective gate, never during optional dialogue.
- **Exact completion:** P-15 home checks valid AND summit packet received; commit M-0801. Set SC-0803_done once; never on mere zone entry.
- **Discovery:** Home safety is maintained through established procedures while the relay team works.
- **Journal copy:** Mei and Amara kept minimum heat, dim lamps and the return loop open while the field team reached Malapert.

## Puzzle mechanics included in this mission

**Initial condition:** Rover E14 (source units); independent supplies 72 h; 120 km each way; outbound travel/heat/repair allowance 5, return allowance 5; minimum reserve 2. Marker2 battery dead. Home E20/cap26,A8,H6,C8,R18,W0; 36 h COOL/DIM/basic demand is 5*(1+1+1)=E15. COOL costs H1 per 7.2 h without insulation; the five-shift night ends H1, so no unavailable upgrade is required. Air use is 0.5 per 7.2 h for the two home cadets for 33 h, then 1.25 per 7.2 h for all five for the final 3 h: total 2.8125.

**Interaction procedure:** Load controller, battery spare and 72 h supplies; assign FER/KAI/RAF rover and MEI/AMA home. Choose surveyed road (max 12°, allowance 5), not shortcut (22°, allowance 3.5). At marker 2 stop, brake, isolate buoy, replace battery, reconnect and test chain 1→2→3. At home set heatMIN (COOL), lampDIM, returnOPEN, verify independent pressure; acknowledge summit packet.

**Accepted solution:** 14−5−5=4>=2; total journey 51 h<=72 h. Restore marker 2 before leaving. Home end E5,A5.1875,H1,C8,R14.625; all four checks valid. Travel sim advances 24 h outbound; local playable road length is intentionally compressed.

**Pass predicate:** Loadout valid, three buoys link, summit arrival at Apr 9 00:00, home checks verified.

**Incorrect feedback:** Missing spare blocks departure; off-road slope barrier offers return to last marker; unbraked exterior repair cannot start; home returnCLOSED prompts thirst forecast. No character switching across locations during free movement.

## State machine and triggers

LOCKED → AVAILABLE when `route_clear` exists → ACTIVE when the first scene's Start/Inspect is accepted → OBJECTIVE_1_DONE on EV-0801 → OBJECTIVE_2_DONE on EV-0802 → READY_TO_COMPLETE on EV-0803 → COMPLETE when completion transaction persists the final scene and mission flag together. M-0801-O2 cannot complete before O1. O3 cannot complete before O2 even if its props were inspected earlier; earlier inspections may set evidence flags but never skip a mandatory reaction.

Puzzle may span O1–O3 (notably storm, route and ending missions); require all declared subchecks, not only the central puzzle scene. A scene's “pending” flag is provisional inside the mission snapshot. `summit_reached` is the committed campaign flag and is set only when all three scenes are complete. No next-mission gate reads a pending flag.

Any unsafe confirmed operation enters RETRY_REVIEW; restore the last safe checkpoint on Retry. Only P-02 displays the four named local ending cards. Other missions use safe retry with an explanatory observation, never an alternate dead-end story. Failure cannot delete a clue, kill a required seed permanently, trap an NPC behind a locked hatch or skip the player's story.

## Checkpoints and persistence

Checkpoint on mission acceptance, after each scene gate and before each destructive/timed commitment. Save phase, scene gate, dialogue cursor, observations, plant lineage, tool state, valid route, all actor locations, mission time, puzzle state, inventory counts and temporary resources together. Saving mid-puzzle restores its exact reversible state. Retry restores the current commitment checkpoint, not a later resource total. A manual save may replace an exploration slot; keep the mission-start safe save separately. Final completion is atomic: `summit_reached=true`, `M-0801=COMPLETE`, and `M-0802` AVAILABLE where applicable. Reload cannot grant duplicate seeds or repeat a time jump.

## Player guidance

- **Default interact:** Inspect [object], Read [label], Use [tool] or Confirm [operation]; hide unavailable destructive controls and show the unmet condition in text.
- **Hint ladder:** A return reserve belongs in the departure plan. / Marker2 is part of the radio path. / Use surveyed route, restore buoy 2, home heatMIN/lampDIM/returnOPEN.
- **Journal after objective 1:** `M-0801: The final route is 120 km each way. We budgeted 24 h outbound, 3 h repair and 24 h return.`
- **Journal after objective 2:** `M-0801: The road repeaters will let the summit hear Aurora. We restored the dead marker before continuing.`
- **Journal after objective 3:** `M-0801: Mei and Amara kept minimum heat, dim lamps and the return loop open while the field team reached Malapert.`
- **Completion entry:** “Prepare two teams and traverse the relay route with verified reserves. Completed. Next: M-0802.” UI uses the next mission's human title as well as ID in debug views only.

## Reward, transition and acceptance

Reward is the discovery, changed environment and following mission; there is no XP or consumable currency. summit_reached_pending; aurora_home_ready; repeater_chain_live; travellers_at_summit.

Next mission: **M-0802**. Transition uses the exact scene time card; require explicit Continue before days/months pass. A fresh input release prevents accidentally accepting the next scene. Optional dialogue may be revisited from the journal without replaying physical rewards.

Acceptance: a player can enter using only mandatory predecessor completion, perform every listed interaction with keyboard and controller, receive every essential spoken fact in captions, fail/retry without state loss, reload each checkpoint without duplicate rewards, and reach the next mission with no developer intervention. Verify the puzzle witness in [testing](../20_TESTING_AND_ACCEPTANCE.md).
