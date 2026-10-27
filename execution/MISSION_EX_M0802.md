# EX-M0802 — Two Teams, One Night

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Restore the road chain while the home team verifies its changing-occupancy plan. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [full-game-story/story-data.json](../full-game-story/story-data.json)
- [full-game-story/STORY_FULL.md](../full-game-story/STORY_FULL.md)
- [production/manifest/scene_index.csv](../production/manifest/scene_index.csv)
- [production/audio/vo_lines.csv](../production/audio/vo_lines.csv)
- [game-design/08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md)
- [game-design/09_WORLD_AND_LEVEL_DESIGN.md](../game-design/09_WORLD_AND_LEVEL_DESIGN.md)


## Ownership and dependencies

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch08/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0801`; SYS02..08; chapter puzzles P-15, P-16; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


## Detailed work sequence

1. Verify predecessor, chapter entry profile, roster, location, time and acquired knowledge before constructing this mission scene/data.
2. Map every listed player action and exit conjunct to an explicit predicate/interaction/evidence owner. Publish this gate map before wiring visuals.
3. Assemble the required rooms/props with current assets, stable anchors and correct physical positions; use shared dialogue/UI/audio services.
4. Implement the three scenes in order; use the relevant shared puzzle stages rather than a second numerical model. A response/inspection choice may converge while its feedback remains distinct.
5. Keep active interaction time substantive through observation, setup, hypothesis-testing, consequences and team communication; fictional days/cruise advance only at accepted gates.
6. Wire exact line IDs, origin/speaker labels, acquired evidence, source boundaries, captions and optional assistance. Apply current English-only/natural plant overrides to any older source label.
7. Test invalid action, partial response, cancel, repeat input, pause, save/load, retry and boundary hand off; preserve authoritative receipts/inventories/actor locations.
8. Run through this mission from its actual predecessor and into its successor, producing a short trace with all gate predicates and the resulting snapshot.


## Task-specific source and implementation detail

### Chapter contract

Chapter 8:**The Lighthouse**; dates: 8–10 April 2047; chapter target: 120 minutes.

A complete round-trip budget and three-repeater road take Ferreira, Kai and Rafi to Malapert while Mei and Amara maintain Aurora. The crew replaces a compatible controller, independently verifies local and Earth legs, checks exact data and restores voices. Noor's first live answer follows proof of the connection. After a dated 24-hour return, all five see the renewing garden and cotton alive at first light.

Emotional arc:Separation → known-road confidence → parallel responsibility → exact repair → chosen reunion → shared homecoming..

This mission target: 30 active minutes. Predecessor:`EX-M0801`. Successor:`EX-M0803`. Chapter puzzle families: P-15, P-16; reuse their single shared implementations and map the actual relevant stages.

### EX-CH08-S04 — The Small Light That Carries a Voice
**Target:**10 minutes. **Location:**Marker-two service pad and repeater chain. **POV:**Kai. **Story time:**8 April,10: 00–17: 00 including compressed onward cruise. **Legacy provenance:**`SC-0802`.

Kai checks the service drawing while Rafi verifies suit readiness and the tether point. Ferreira holds the cabin checklist. The player isolates the repeater before removing its battery, compares the replacement specification, then secures the closed housing before reconnecting. No bare-handed repair occurs in vacuum, and no exterior engine roar fills the silence.

The marker lights, but the task is not finished. The player tests the first-to-second and second-to-third paths separately. A bright indicator can mean local power without proving a communication link. When one test is run before the housing check, the panel names the missing condition and holds the procedure rather than allowing an unsafe completion.

Only after adjacent links pass does the rover continue to marker three and the hundred-kilometre approach. Kai repeats his old phrase about a small light and a known road. It now describes infrastructure he helped repair, not a charm against darkness. The final twenty kilometres remain on the route schedule. A time card holds the field position while control returns explicitly to Aurora.

**Exact dialogue**

- `EX-CH08-S04-L01` **Kai:** Power isolated before the battery.
- `EX-CH08-S04-L02` **Rafi:** Tether and suit checked.
- `EX-CH08-S04-L03` **Ferreira:** A light is not yet a link.
- `EX-CH08-S04-L04` **Kai:** Test both neighbours. Then continue.

**Required player actions**

1. Perform isolated battery replacement.
2. Test adjacent links independently.
3. Verify marker three before the final approach.

**Decision study and planned feedback**

The marker lights. What completes verification?
- **Assume the whole chain works:** The local power result does not prove either neighbouring link.
- **Test both adjacent links:** The chain's actual communication function is checked.

**Convergence:**All three repeater sites and their four surface hops are verified through current adjacent-link tests..

**Learning loop**

- **Concept:** Function versus appearance
- **Predict:** Does a lit device prove its network works?
- **Observe:** Compare power indication with end-to-end packets.
- **Explain:** A component can be powered and still fail its intended function.
- **Transfer:** Test the service a device must provide.

**Mandatory exit condition:**All three repeater sites and their adjacent links verified; field team reaches the 100-kilometre approach at 17:00.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH08-S05 — Two at Home
**Target:**10 minutes. **Location:**Aurora garden and life-support console. **POV:**Mei. **Story time:**8 April 18: 00, start of final 36-hour night. **Legacy provenance:**`SC-0803`.

The viewpoint card names Aurora and Mei before the player regains movement. Kai is still on the road; no role-selection shortcut brings him into the room. Beside Mei, Amara checks the same independent gauge that once exposed the misleading leak indication. It is an ordinary check now, performed calmly.

The player sets the established home loop: minimum heat under the COOL profile, dim growth lamps and the water return open. Current plants are labelled descendants. Cotton grows in its indoor reference bay. The original petal remains preserved beside the founder record, rather than appearing on a miraculously restored Alo.

The Sun leaves at the scenario's stated gate. This night will last thirty-six fictional hours, not thirty-six hours of required player waiting. The home ledger counts two occupants for the first thirty-three hours and reserves the higher draw for the returning three. The player predicts the changed consumption before testing the schedule. Mei adjusts one crooked nameplate and leaves the small guide light exactly where it was planned. Keeping home is half the expedition's climax.

**Exact dialogue**

- `EX-CH08-S05-L01` **Amara:** Same darkness. Different garden.
- `EX-CH08-S05-L02` **Mei:** Different us.
- `EX-CH08-S05-L03` **Amara:** Two here until the return.
- `EX-CH08-S05-L04` **Mei:** Then five for the last three hours.

**Required player actions**

1. Set COOL, DIM and return OPEN home loop.
2. Verify independent pressure readings.
3. Forecast the two-to-five occupancy transition.

**Decision study and planned feedback**

Which home forecast matches the signed journey?
- **Two occupants for the whole night:** It omits the returning three during the final hours.
- **Two for 33 hours, then five for 3 hours:** The consumption transition matches the dated roster.

**Convergence:**Home loop and segmented occupancy forecast valid; two people remain physically at Aurora..

**Learning loop**

- **Concept:** Time-dependent demand
- **Predict:** Why is a single occupancy count insufficient?
- **Observe:** Compare demand before and after the return.
- **Explain:** Changing conditions require segmented accounting.
- **Transfer:** Divide a plan at meaningful system transitions.

**Mandatory exit condition:**Home loop and segmented occupancy forecast valid; two people remain physically at Aurora.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH08-S06 — The Packet From the Summit
**Target:**10 minutes. **Location:**Aurora console and rover summit approach. **POV:**Amara then Rafi at labelled cut. **Story time:**8 April 18: 00–9 April 00: 00. **Legacy provenance:**`SC-0803`.

At Aurora, the player watches the garden forecast meet the first checked result. Amara verifies air, temperature and the open return path before acknowledging any field message. A working relay later cannot compensate for a neglected home system now. The scene keeps both responsibilities visible without letting one player move characters between sites.

A timestamped rover packet reports the final approach. The three road repeaters carry local traffic across the four required surface hops; the broken Earth uplink remains broken. The player checks sender, location and packet age. A stored earlier position is available as a comparison, making it possible to recognise why a stale acknowledgement would mislead the other team.

The viewpoint card then cuts to Rafi at the summit, exactly twenty-four scenario hours after departure. Ferreira and Kai are with him in the pressurised rover. The dark relay housing lies beyond the window. Rafi sends the arrival packet and waits for Aurora's local acknowledgement. The player has completed a complete outward leg and preserved home, not repaired Earth by implication. The next mission starts with a compatible spare and two explicit communication paths still to verify.

**Exact dialogue**

- `EX-CH08-S06-L01` **Amara:** Home checks first. Then acknowledge.
- `EX-CH08-S06-L02` **Mei:** The packet says when and where.
- `EX-CH08-S06-L03` **Rafi (local radio):** Summit reached. Three aboard.
- `EX-CH08-S06-L04` **Amara (Aurora local radio):** Current arrival packet acknowledged.

**Required player actions**

1. Check home state against forecast.
2. Reject stale position as a new arrival.
3. Confirm timestamped summit arrival over local radio.

**Decision study and planned feedback**

Which packet can certify arrival?
- **The earlier approach packet:** Its location and timestamp cannot prove summit arrival.
- **The new summit packet:** Sender, position and time match the planned 24-hour leg.

**Convergence:**Summit reached 9 April 00:00; home checks and fresh local acknowledgement complete..

**Learning loop**

- **Concept:** Freshness and information integrity
- **Predict:** Is an old correct message correct for the present question?
- **Observe:** Compare sender, position and timestamp.
- **Explain:** Evidence must be current enough for the decision it supports.
- **Transfer:** Check the age of information as well as its content.

**Mandatory exit condition:**Summit reached 9 April 00:00; home checks and fresh local acknowledgement complete.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Ferreira, Kai and Rafi rover; Mei and Amara Aurora.
- 120 kilometres each way,24 hours out+3 hours repair+24 hours back=51 hours; provisions 72 hours.
- Depart 8 April 00:00, summit 9 April 00:00, return 9 April 03:00, home 10 April 03:00, dawn 10 April 06:00.
- Base has two occupants for 33 dark hours, then five for 3 hours.
- Founder 30, retainedvault 11 and plantedcotton 1 remain distinct.
- First live Noor voice occurs only after verified dual-link checks.
- MARS is only a post-credit future-story image, with no additional playable task.

### Production constraints
- Explicit viewpoint cards prevent physical teleportation.
- Local rover packets do not imply Earth was repaired early.
- Scenario bearings remain labelled until geometry is verified.
- No real-time 24-hour drive, forced dexterity clock or penalty for assisted controls.
- Final garden exists before dawn; original Alo stays an archived petal and living lineage.

### Chapter bridge
The campaign is complete before any future-story image; Continue opens the safe final garden.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- Exactly the quoted three final scene IDs complete once before the next mission unlocks.
- Every required action has actual gameplay and observable feedback; a film/dialogue click does not replace it.
- Exit predicates, learning evidence, roster, time, knowledge and numeric state agree with canon.
- The mission integrates with the previous/next mission under a validated save/checkpoint, not a disconnected devdemo.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
