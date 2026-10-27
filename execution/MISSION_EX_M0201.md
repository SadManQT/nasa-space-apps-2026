# EX-M0201 — Understand the Missing Bee

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Identify compatible partners, transfer structures and the full contained route. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch02/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0104`; SYS02..08; chapter puzzles P-03, P-04; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 2:**Be the Bee**; dates: 30 April-6 May 2046; authored UTC chronology; chapter target: 75 minutes.

Tara flowers as Earth contact returns. The crew carries out three sealed reciprocal pollen runs across seven care days, records a testable inheritance prediction and reconstructs an older horticulture recording. The evening ends with a quake.

Emotional arc:Recognition -> patient precision -> curiosity -> tentative personal connection -> decisive reprioritising..

This mission target: 18 active minutes. Predecessor:`EX-M0104`. Successor:`EX-M0202`. Chapter puzzle families: P-03, P-04; reuse their single shared implementations and map the actual relevant stages.

### EX-CH02-S01 — The Star in the Other Room
**Target:**6 minutes. **Location:**Tara reference bay and Earth console. **POV:**Mei. **Story time:**2046-04-30 morning UTC. **Legacy provenance:**`SC-0201`.

Tara opens while everyone is still choosing a place for Alo's photograph. Mei notices the second flower before the Earth console lights. When contact returns, Ferreira's praise arrives days after sunrise, exactly when a conversation is possible again. The delay gives the player time to understand that the crew's achievement did not require a live audience.

The player compares Tara's identity card with Alo's. Both are compatible individuals of the selected mustard cultivar, but one flower cannot simply make the full experiment happen alone. A sealed protocol identifies pollen donor, recipient and the parts to be observed. Mei turns the recorder's instruction into a question the team can investigate rather than an order to obey blindly.

Kai suggests placing the two chambers together. Amara points to their separate services and research purposes. Moving the whole experiment would change more than one thing and create work they have not planned. Instead, the crew will move pollen in a controlled carrier. Tara receives a new photograph beside Alo's. The page now looks less like a heroic portrait and more like a partnership, which is precisely the discovery Mei wants everyone to see.

**Exact dialogue**

- `EX-CH02-S01-L01` **Ferreira (Earth link):** You did not just endure the night. You operated it.
- `EX-CH02-S01-L02` **Mei:** Tara opened too. She belongs in the report.
- `EX-CH02-S01-L03` **Kai:** Two flowers. Do we introduce them?
- `EX-CH02-S01-L04` **Amara:** First we read how this cultivar makes seeds.

**Required player actions**

1. Compare both plant identities and flowering records.
2. Distinguish delayed Earth conversation from the prior stored recording.
3. Open the compatible cross-pollination protocol.

**Decision study and planned feedback**

What leads the paired report?
- **Two portraits:** The plants receive equal visual attention.
- **Two identity-and-condition records:** The experimental relationship is foregrounded.

**Convergence:**Both preserve Alo and Tara as equally cared-for compatible partners..

**Learning loop**

- **Concept:** Reproduction can depend on compatible partners.
- **Predict:** Is one flower always sufficient for seed production?
- **Observe:** The selected cultivar protocol requires compatible cross-pollination.
- **Explain:** Plant reproductive systems vary; the claim applies to these plants.
- **Transfer:** Check the biology of the species instead of assuming every flower works alike.

**Mandatory exit condition:**Both identity cards inspected, live link acknowledged and protocol opened.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_02.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH02-S02 — A Bee Is More Than a Costume
**Target:**6 minutes. **Location:**Indoor botanical bench. **POV:**Mei. **Story time:**2046-04-30 morning UTC. **Legacy provenance:**`SC-0201`.

Rafi folds a paper bee and puts it beside the protocol. Mei smiles, then asks what the real bee's useful job would be. The player examines magnified flower images, matching the pollen-bearing anthers and receptive stigma to a simple diagram. The game accepts words and shapes together; recognising a yellow spot by colour alone is never required.

Amara lays out two clean brushes with separate labels. One will move compatible pollen from Tara to Alo; the other will support the reciprocal transfer without mixing the records. Mei describes her grandmother's hand-pollination work in an orchard where pollinators were scarce. She does not claim every bee in China disappeared. A remembered family action becomes a carefully bounded example.

The player rehearses on a nonliving model first, identifying contact points and checking that both plant records agree on direction. A wrong model placement returns an explanation rather than damaging a real flower. Kai tests a carrier latch and discovers the challenge is not making bee noises. It is delivering a small biological material without losing the atmosphere or the evidence. Rafi leaves the paper bee on the bench as a reminder of the function they are learning to replace.

**Exact dialogue**

- `EX-CH02-S02-L01` **Rafi:** I brought the bee.
- `EX-CH02-S02-L02` **Mei:** Good. What does it actually do?
- `EX-CH02-S02-L03` **Amara:** One brush for each recorded direction.
- `EX-CH02-S02-L04` **Kai:** I was hoping the answer was making that noise.

**Required player actions**

1. Identify anthers and stigma on accessible magnified images.
2. Match two labelled brushes to reciprocal transfer directions.
3. Practise on a nonliving model before working at the chambers.

**Decision study and planned feedback**

How should the team explain pollination?
- **Trace a pollen grain:** The route from donor to recipient becomes concrete.
- **Label the flower diagram:** The structures and their roles become clear.

**Convergence:**Both identify the same compatible transfer before touching a living flower..

**Learning loop**

- **Concept:** Pollination transfers pollen; it is not instant seed formation.
- **Predict:** Which contact moves pollen to a receptive surface?
- **Observe:** The model shows donor, tool and recipient separately.
- **Explain:** Successful reproduction has biological stages after pollination.
- **Transfer:** Observe flowers with a diagram and avoid treating all yellow material as the same structure.

**Mandatory exit condition:**Structures and transfer directions correctly matched on the practice model.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_02.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH02-S03 — The Route Must Keep Its Air
**Target:**6 minutes. **Location:**Garden service corridor and transfer interlock. **POV:**Rafi. **Story time:**2046-04-30 before the first bee run UTC. **Legacy provenance:**`SC-0202`.

The shortest line on Kai's sketch runs straight from Tara to Alo. The real route has doors, pressure boundaries and a return leg. Rafi puts the sketch beside the station diagram, letting the player discover what the line has omitted. Pollen is tiny. The atmosphere supporting both plants is not optional.

The player checks space-weather status, prepares the closed carrier and traces each transfer boundary before committing the first run. A mock latch indicator offers both an icon and a word. Two boundaries cannot be opened together. The interface previews one complete reciprocal cycle and its single canonical route charge, instead of charging the same cycle again at every animation cut.

Amara asks which observations will prove completion. Mei lists both plant identities, both transfer directions and the dated care record. Kai adds the carrier check without making a joke. The crew can now explain the route from memory, but the checklist remains available. Planning has earned them confidence rather than permission to skip verification. The player closes the last practice boundary and sees both chamber pressure indicators unchanged. Their first pollination visit is ready to be useful because getting there and coming back are part of the same mission.

**Exact dialogue**

- `EX-CH02-S03-L01` **Kai:** My line was shorter.
- `EX-CH02-S03-L02` **Rafi:** It left out the air.
- `EX-CH02-S03-L03` **Amara:** Count the whole reciprocal cycle once, not every camera cut.
- `EX-CH02-S03-L04` **Mei:** And bring back records for both plants.

**Required player actions**

1. Check space weather and the complete sealed route.
2. Verify carrier latches and pressure-boundary order.
3. Preview the whole reciprocal cycle and its canonical charge.

**Decision study and planned feedback**

Which transfer design preserves both containment and attributable evidence?
- **Use one unlabelled brush for both directions:** The paused model loses donor-direction attribution and flags the cleaning/control failure before either living flower is touched.
- **Use separately labelled clean tools in the closed carrier:** The model preserves donor identity and pressure boundaries across the full reciprocal route.

**Convergence:**The crew corrects any unsupported model and commits only the sealed, separately labelled reciprocal protocol..

**Learning loop**

- **Concept:** A route includes interfaces and return requirements.
- **Predict:** Does small cargo make containment unnecessary?
- **Observe:** The carrier and interlocks preserve both atmosphere and sample identity.
- **Explain:** Physical boundaries matter even when transported material is tiny.
- **Transfer:** Plan the full path of a sample, including its container and return record.

**Mandatory exit condition:**Weather, carrier, boundary order and complete-cycle budget confirmed.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_02.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Earth contact returns April 30, not at the earlier first bloom.
- Three reciprocal cycles occur April 30,May 3,May 6; all seven care dates are logged.
- Whole-cycle route costs apply once; sealed transfers never expose flowers to vacuum.
- Stem prediction is retained for the Chapter 4 observation, without promised genotype ratio.
- N. remains anonymous; engineer resemblance is an inference; no death is invented.
- Quake at May 6 22:00 leads directly to Chapter 3.

### Production constraints
- Give Tara equal visual and record status.
- Use magnification, labels and shapes together for flower structures.
- Keep original media provenance visible in archive playback.
- All 75 minutes are required authored play, with dates advanced explicitly rather than by idle waiting.

### Chapter bridge
No date jump follows the quake. The four accounted-for cadets begin testing the changed pressure warning at 22:05.


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
