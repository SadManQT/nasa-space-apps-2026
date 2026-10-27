# EX-M0804 — From Last Light to First Light

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Restore chosen human contact, return on time and verify the continuing garden. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0803`; SYS02..08; chapter puzzles P-15, P-16; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 30 active minutes. Predecessor:`EX-M0803`. Successor:`Completeendingandcredits`. Chapter puzzle families: P-15, P-16; reuse their single shared implementations and map the actual relevant stages.

### EX-CH08-S10 — Hello, Aurora
**Target:**10 minutes. **Location:**Relay rover cabin, Aurora and Noor's Earth rooftop. **POV:**Mei at Aurora through labelled cut. **Story time:**9 April 02: 15–03: 00. **Legacy provenance:**`SC-0805`.

The transmit control waits until both path checks are visible. The player confirms Aurora's voice, then Earth's. Rao identifies the restored route and leaves room on the channel. Only now does Noor choose to speak live: Hello, Aurora. This is Noor.

The picture cuts among the pressurised summit cabin, Aurora's table and a rooftop in Bangladesh. The Earth shot belongs to the fictional scene; it makes no unsupported claim about exact Moon phase or local visibility. The crew leaves pauses for radio delay. Nobody talks continuously from an unprotected lunar exterior.

Mei sends current garden telemetry and the preserved lineage photograph. Noor sees what reached her through the working path, not everything that happened during the blackout. She says the crew did what she could not. Ferreira answers that the seeds and the Academy made their work possible. The player selects a supported report sentence and lets each contributor remain named. This is a shared achievement, not a replacement for Noor or a redemption purchased by one heroic rescue. Before the call ends, Rafi reads the return departure time.

**Exact dialogue**

- `EX-CH08-S10-L01` **Noor (first live Earth voice):** Hello, Aurora. This is Noor.
- `EX-CH08-S10-L02` **Mei:** We kept a place for you.
- `EX-CH08-S10-L03` **Ferreira:** You brought us the seeds.
- `EX-CH08-S10-L04` **Amara:** The garden has more than one gardener.

**Required player actions**

1. Complete Aurora and Earth voice checks.
2. Send current garden telemetry.
3. Confirm return departure after the call.

**Decision study and planned feedback**

Which report accurately describes the achievement?
- **The relay crew alone saved the garden:** The debrief shows missing home care and earlier contributions.
- **Both teams and earlier work kept the expedition connected:** The checked record credits preparation, repair and ongoing care.

**Convergence:**Both voices and telemetry acknowledged; Noor's first live call complete; return starts 03:00..

**Learning loop**

- **Concept:** Shared work and evidence of success
- **Predict:** Who contributed while the player watched another team?
- **Observe:** Compare home, field and earlier preparation records.
- **Explain:** Complex achievements depend on linked visible contributions.
- **Transfer:** Credit dependencies and collaborators accurately.

**Mandatory exit condition:**Both voices and telemetry acknowledged; Noor's first live call complete; return starts 03:00.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH08-S11 — The Same Road Home
**Target:**10 minutes. **Location:**Press uri sed rover and Aurora arrival airlock. **POV:**Rafi then Amara at labelled arrival. **Story time:**9 April 03: 00–10 April 03: 00,24-hour return. **Legacy provenance:**`SC-0805`.

The crew enters the rover before the return transition starts. Rafi checks the same surveyed road in reverse and reads the remaining provision margin. The player compares actual use with the whole-mission forecast, including the three-hour repair window. Arrival at Malapert never counted as the finish.

Three short route checks show the restored repeaters still supporting communication. They test new return observations rather than asking the player to repeat the outward puzzle without change. A stale outward timestamp is rejected when the player confirms a homebound position. Guided cruise can compress travel while preserving those decisions and the full fictional duration.

At Aurora, Amara receives the approaching packet and prepares the actual arrival transition. The airlock does not open because a cinematic needs a reunion. The player verifies the three returning names and pressure procedure. At 03:00 on 10 April, five lunar crew are physically home. The home ledger changes consumption for the final three dark hours. Mei can finally put Ferreira's mug beside the others, while the player checks the margin that made this quiet return possible.

**Exact dialogue**

- `EX-CH08-S11-L01` **Rafi:** Return is part of the mission.
- `EX-CH08-S11-L02` **Kai:** Same road. New timestamps.
- `EX-CH08-S11-L03` **Amara (Aurora local radio):** Three arrivals expected and checked.
- `EX-CH08-S11-L04` **Mei:** Five home. Three hours to first light.

**Required player actions**

1. Compare actual round-trip use with forecast.
2. Verify current return packets at three route gates.
3. Complete arrival and change base occupancy tofive.

**Decision study and planned feedback**

When should home consumption increase?
- **When the rover leaves the summit:** Those people are still supplied by the rover.
- **When the three physically return at 03:00:** The base ledger changes at the actual location transition.

**Convergence:**All three return after 24 hours; five at Aurora 03:00; final 3-hour occupancy updated..

**Learning loop**

- **Concept:** Resource ownership and transitions
- **Predict:** Which system supplies people during return travel?
- **Observe:** Compare rover and base rosters over time.
- **Explain:** Consumption belongs to the location actually supporting each person.
- **Transfer:** Avoid counting people twice or omitting them between systems.

**Mandatory exit condition:**All three return after 24 hours; five at Aurora 03:00; final 3-hour occupancy updated.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH08-S12 — What We Grew
**Target:**10 minutes. **Location:**Aurora press uri sed garden. **POV:**Mei. **Story time:**10 April 06: 00, first light and complete epilogue. **Legacy provenance:**`SC-0806`.

The viewing shutter waits where the first bloom once appeared. Before touching it, the player verifies the final records: five people safely home, thirty founder seeds protected, eleven unplanted vault specimens retained, stable pressure and temperature, and cotton alive. The checks describe an established garden that survived another seasonal dark window. Dawn will reveal it, not create it instantly.

Mei opens the shutter. Mustard descendants flower inside the pressurised room. Alo's petal remains beside the lineage label, and Tara's contribution appears beside Alo's. Noor watches through the restored screen. Cotton stands by the window, continuing the historical beginning represented by the 2019 seedling without pretending this fictional plant rewrites that real experiment.

The player takes the shared photograph and chooses a dedication supported by the completed work. Credits name both teams and the people who made their first chance possible. All central questions have answers before the ending closes. A brief post-credit still may show the closed MARS drawer as a future-story image; it adds no quest, collectible or required activity to this campaign. Continue returns to the safe completed garden.

**Exact dialogue**

- `EX-CH08-S12-L01` **Mei:** Temperature and pressure steady.
- `EX-CH08-S12-L02` **Amara:** Seeds protected. Everyone home.
- `EX-CH08-S12-L03` **Ferreira:** You did not just survive the Moon. You grew it.
- `EX-CH08-S12-L04` **Noor (live Earth link):** Show me the cotton by the window.

**Required player actions**

1. Reconcile final people, seed and garden records.
2. Open shutter and save the shared photo.
3. Choose a dedication and complete the credits.

**Decision study and planned feedback**

Which dedication fits the completed evidence?
- **For every hand that kept the light:** The photo credits the whole linked expedition.
- **For the gardens we leave for others:** The lineage record connects care across generations.

**Convergence:**Final records, photo, dedication and credits complete; no extra task gates the ending..

**Learning loop**

- **Concept:** Sustained success and biological continuity
- **Predict:** What makes this more than one lucky bloom?
- **Observe:** Compare generations, protected reserve and survival through the next night.
- **Explain:** A renewing system preserves conditions and future capacity.
- **Transfer:** Define success across time rather than one impressive moment.

**Mandatory exit condition:**Final records, photo, dedication and credits complete; no extra task gates the ending.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
