# EX-M0101 — Give the Station a Crew

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Commission, rehearse independent safety and inspect the seed evidence. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch01/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `NewExpeditionsetup`; SYS02..08; chapter puzzles P-01, P-02; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 1:**Night One**; dates: 11-27 April 2046; authored UTC chronology; chapter target: 75 minutes.

Commission Aurora, plant Alo and Tara, prepare for a 36-hour scenario night and survive a labelled historical storm replay. First bloom closes the night and opens the mystery of N.

Emotional arc:Curiosity -> shared care -> prepared fear -> controlled crisis -> earned relief..

This mission target: 18 active minutes. Predecessor:`NewExpeditionsetup`. Successor:`EX-M0102`. Chapter puzzle families: P-01, P-02; reuse their single shared implementations and map the actual relevant stages.

### EX-CH01-S01 — Sunlight We Cannot Keep
**Target:**6 minutes. **Location:**Aurora mission table. **POV:**Mei. **Story time:**2046-04-11 06: 00 UTC. **Legacy provenance:**`SC-0101`.

The first thing Aurora asks of Mei is not her name. It is where the spare sunlight should go. A gold band has reached the top of the battery display, while the mast outside is still producing. Kai reaches for a switch, then stops when Amara points to the overflow arrow. A full store cannot promise to hold more.

The player traces the diagram to the air tank or planting bay. Both are safe commissioning choices. The air gauge rises if they store oxygen; the empty garden glows if they light the bay. A comparison preview also shows what spilling the spare supply means. The result remains visible while the crew accepts its assignment.

Ferreira watches from an Earth console. She asks each specialist to describe one responsibility and one limit. Mei notices four mugs with no names. Aurora feels borrowed, but its first decision already belongs to them. Before anyone celebrates, Rafi turns the emergency card towards every seat. Their first shared achievement is knowing how to stop.

**Exact dialogue**

- `EX-CH01-S01-L01` **Kai:** A full battery sounds like a good problem.
- `EX-CH01-S01-L02` **Amara:** Only if we notice what spills.
- `EX-CH01-S01-L03` **Mei:** Can we store it somewhere that is not a battery?
- `EX-CH01-S01-L04` **Ferreira (Earth link):** Show each other your reasoning, then commit it.

**Required player actions**

1. Trace production, storage and overflow.
2. Compare air-tank and planting-light routes, then confirm one.
3. Read the charter and acknowledge emergency limits.

**Decision study and planned feedback**

Where should spare commissioning energy go?
- **Store air:** The air gauge rises in this exercise.
- **Light the planting bay:** The planting bench receives warm light.

**Convergence:**Both preserve the later April 25 survival baseline; their visible commissioning results persist until the dated transition..

**Learning loop**

- **Concept:** Storage limits and useful loads.
- **Predict:** What reaches a full store?
- **Observe:** The preview distinguishes useful routing from overflow.
- **Explain:** Available production is not unlimited storage.
- **Transfer:** Check where energy can be used or stored before treating it as spare.

**Mandatory exit condition:**Route confirmed, result inspected, charter and emergency card acknowledged.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH01-S02 — The Rule That Works Without Earth
**Target:**6 minutes. **Location:**Mission table and Safe Room doorway. **POV:**Rafi. **Story time:**2046-04-11 07: 00 UTC. **Legacy provenance:**`SC-0101`.

Rafi places four name tokens on the Safe Room board. None is an oxygen token, and none can be traded for a better score. They stand for people. A harmless fault appears on a disconnected practice panel. The player must find which information comes from a local sensor, which is stored guidance, and which requires Earth.

Kai points to Ferreira's screen. What happens when that rectangle disappears? Rafi shows him the printed retreat sequence. Emergency rules, suit radios and the station network remain local. Losing the direct Earth path removes conversation, not the crew's ability to care for itself. Amara tests the labelled acknowledgement without activating a hazard. Mei checks that the gardening bench can be made safe before anyone leaves it.

The team rehearses a quiet roll call. Nobody sprints. The player explains the stored card in their own order and discovers the same instruction beneath both views: experiments wait when the habitat cannot support them. Ferreira asks for a local stop decision before approving the assignment. Responsibility includes the right to pause.

**Exact dialogue**

- `EX-CH01-S02-L01` **Rafi:** These are names. We do not spend them.
- `EX-CH01-S02-L02` **Kai:** And if Earth cannot hear the roll call?
- `EX-CH01-S02-L03` **Amara:** The station still can. So can we.
- `EX-CH01-S02-L04` **Ferreira (Earth link):** You have local authority to stop an unsafe operation.

**Required player actions**

1. Classify local, stored and live-link information.
2. Rehearse bench shutdown and four-person roll call.
3. Resolve the practice fault without live-link hints.

**Decision study and planned feedback**

Who leads the rehearsal?
- **Rafi:** His checklist establishes the order.
- **Amara:** Her read-back tests a second user of the procedure.

**Convergence:**All four confirm the same local response..

**Learning loop**

- **Concept:** Independent operations and shared procedures.
- **Predict:** Which instructions disappear with a radio path?
- **Observe:** Local cards, sensors and suit links remain.
- **Explain:** Communications and life support are separate systems.
- **Transfer:** A school emergency plan should not depend on one phone.

**Mandatory exit condition:**Local response checked and every crew token accounted for.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH01-S03 — A Label Older Than Our Names
**Target:**6 minutes. **Location:**Dry-storage drawer and calibration bench. **POV:**Mei. **Story time:**2046-04-11 10: 00 UTC. **Legacy provenance:**`SC-0102`.

The inventory lamp blinks beside a drawer that seems too small to contain a story. Inside lies a sealed dry packet with two seeds, Bengali lettering and a single initial. Mei reads the word for light. Kai proposes Light One and Light Two. Amara writes two blank identity labels before anyone can make the joke permanent.

A historical card shows cotton germinating in China's sealed Chang'e-4 experiment in 2019. Mei separates that real seedling from their future flowering goal.

The player examines the seal and storage record, then copies the packet label. The original stays protected. A moisture probe offers a confident-looking number, but confidence is not a reference. Mei calibrates it against the provided reference sample before it touches a planting cassette. The reading changes; a measurement becomes useful because its basis is visible.

One cassette belongs to the exterior pressurised test chamber; the other belongs to the indoor reference bay. Neither seed will sit in lunar vacuum. The player compares the atmosphere diagrams and notices how much machinery the word outside conceals. Warmth, pressure, water and light still need supplying. The initial remains unanswered. For now, a more important question is whether the station can give two old seeds a fair beginning.

**Exact dialogue**

- `EX-CH01-S03-L01` **Mei:** Alo means light. Someone named the packet before us.
- `EX-CH01-S03-L02` **Kai:** Light One and Light Two?
- `EX-CH01-S03-L03` **Amara:** Two labels first. Names second.
- `EX-CH01-S03-L04` **Rafi:** And a reference before the interesting number.
- `EX-CH01-S03-L05` **Mei:** A sealed experiment grew a cotton seedling on the Moon in 2019. We are building on that beginning.

**Required player actions**

1. Inspect seal, record and inscription without damaging the packet.
2. Calibrate the moisture probe.
3. Compare both chamber atmosphere diagrams and distinguish the historical cotton germination record from the expedition flowering goal.

**Decision study and planned feedback**

Which record is made first?
- **Packet provenance:** Seed handling becomes traceable.
- **Calibration result:** Measurement becomes traceable.

**Convergence:**Both are required before planting..

**Learning loop**

- **Concept:** Measurements need references.
- **Predict:** Does outside mean exposed?
- **Observe:** Both chambers maintain atmosphere.
- **Explain:** A reading needs an instrument and a reference.
- **Transfer:** Check how an instrument was zeroed before relying on it.

**Mandatory exit condition:**Provenance and reference checks complete; destinations identified.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`, `SRC-COTTON2019`.

### Cross-mission continuity
- Commissioning never changes the fixed April 25 P-02 initial state.
- Two daylight and five dark shifts;36-hour night is an authored scenario.
- Earth link ends at shift 4; local radios and stored guidance persist.
- N. remains anonymous and recorded; Tara is cared for from planting.
- Safe crew and living Alo advance the campaign; losses close locally with retry.

### Production constraints
- Maintain plant pressure enclosures; no exposure to vacuum.
- Use instrument traces and cabin/suit sound for the storm.
- Assistance preserves outcomes and rewards.
- This standalone 75-minute mandatory route supersedes the old 28-minute target only in this edition.

### Chapter bridge
Earth contact returns days later on April 30. Tara opens and the recorded request becomes a pollination problem.


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
