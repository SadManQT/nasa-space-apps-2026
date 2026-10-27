# EX-M0502 — The Parts We Left Unsaid

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Resolve biological and personal misunderstandings. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch05/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0501`; SYS02..08; chapter puzzles P-09, P-10; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 5:**Shooting Stars**; dates: 12–15 December 2046; chapter target: 85 minutes.

A physical handover leads to an investigation of Expedition Zero, accountable conversation, impact observation and maintenance. Consented records identify Noor as the living Academy founder. A respectful invitation leads to cotton planting and carefully separated seed ledgers.

Emotional arc:Anticipation → discomfort → accountability → wonder → connection..

This mission target: 20 active minutes. Predecessor:`EX-M0501`. Successor:`EX-M0503`. Chapter puzzle families: P-09, P-10; reuse their single shared implementations and map the actual relevant stages.

### EX-CH05-S04 — A Garden That Had Not Flowered
**Target:**6 minutes. **Location:**Archive images at the mission table. **POV:**Mei. **Story time:**14 December, afternoon. **Legacy provenance:**`SC-0502`.

Mei brings the frozen-garden photographs beside Alo's preserved petal. For months she has called the room below the hatch an old garden. Now that phrase seems to compete with their first bloom. If flowers were already there, what did Alo change? The player opens the growth sheet instead of accepting either flattering explanation.

The sheet records young seedlings, curled leaves and evacuation before flowering. Close images show why a curled frozen leaf is not evidence of a flower. Mei marks what is visible and leaves an uncertain patch unlabelled. Amara checks that the board describes the documented trial, rather than pretending a photograph proves every unseen moment.

Alo's record stays separate: flower, compatible pollen from Tara, mature pods, dry-down and forty-two harvested seeds. The petal is not alive. The descendants in the present room are. By aligning two timelines, the player makes space for both expeditions without stealing either achievement. Ferreira watches Mei revise the caption. She does not ask her to make an unfinished trial sound successful.

**Exact dialogue**

- `EX-CH05-S04-L01` **Mei:** I thought those shapes were flowers.
- `EX-CH05-S04-L02` **Amara:** Read the growth sheet beside the image.
- `EX-CH05-S04-L03` **Ferreira:** We left before reproduction.
- `EX-CH05-S04-L04` **Mei:** Then Alo finished a step they could not.

**Required player actions**

1. Compare growth stages and dates.
2. Identify young seedlings and curled leaves.
3. Keep founder harvest separate from later generations.

**Decision study and planned feedback**

Which interpretation is supported by the archived growth record?
- **The shapes show earlier flowers:** The growth sheet identifies young unflowered seedlings with curled leaves; revise the caption.
- **The trial ended before flowering:** Dated stage records support the conclusion without denying the trial's value.

**Convergence:**Archive interpretation must match the documented pre-flowering stage..

**Learning loop**

- **Concept:** Plant life stages
- **Predict:** Can a frozen leaf resemble a flower?
- **Observe:** Compare images, stage notes and dates.
- **Explain:** A young seedling and a flowering plant are different stages; the old trial stopped before any flowering.
- **Transfer:** Support a biological claim with more than appearance.

**Mandatory exit condition:**The old 2034 trial is documented as young unflowered seedlings only, without flower buds, pollination or seed production.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH05-S05 — What I Didn't Say
**Target:**7 minutes. **Location:**Aurora table, shared seating. **POV:**Mei. **Story time:**14 December, late afternoon. **Legacy provenance:**`SC-0503`.

Ferreira sits where a commander would usually stand. Her hands rest without touching the records. She describes Expedition Zero's final equipment-recovery minutes: a seed drawer, a service annex already cooling, and a gardener who believed another crew would come. The vault had been placed during an earlier survey. Nobody drove into a crater while the ascent vehicle waited.

The player can ask about the retreat order or the saved seeds. Both lead to facts secured by the record. Ferreira helped the gardener board. The fault made continued habitation unsafe. Returning alive was the right action, and it still hurt to leave living work unfinished. She admits that avoiding this history made discovery feel like secrecy.

Mei does not respond by pretending the delay never mattered. She asks why the commander trusted them with equipment but not disappointment. Ferreira accepts the question. The player chooses a first response, then reads the other perspective too. This is not a forgiveness meter. A working crew can keep a disagreement visible and decide together what must happen next.

**Exact dialogue**

- `EX-CH05-S05-L01` **Ferreira:** I was the engineer who could not fix the radio.
- `EX-CH05-S05-L02` **Mei:** You could have told us.
- `EX-CH05-S05-L03` **Ferreira:** Yes. I was afraid of how it would sound.
- `EX-CH05-S05-L04` **Kai:** Then we can ask before we guess.

**Required player actions**

1. Ask about the retreat order.
2. Ask about the seeds and earlier vault survey.
3. Record responsibility without inventing abandonment.

**Decision study and planned feedback**

What should Mei ask first?
- **Why did you wait?:** Ferreira acknowledges the cost of avoidance.
- **What came home?:** She describes people, records and another chance.

**Convergence:**Both factual topics acknowledged; all safety information remains available..

**Learning loop**

- **Concept:** Accountable communication
- **Predict:** Can a necessary decision leave regret?
- **Observe:** Compare the safe order with a personal account.
- **Explain:** Emotional difficulty does not erase operational responsibility.
- **Transfer:** Request missing context without inventing blame.

**Mandatory exit condition:**Both factual topics acknowledged; all safety information remains available.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH05-S06 — Two Kinds of Repair
**Target:**7 minutes. **Location:**Local records desk and spare locker. **POV:**Kai. **Story time:**14 December, before night observation. **Legacy provenance:**`SC-0503`.

Kai opens the old relay diagram beside the new controller's service card. Their housings resemble one another, but he will not call them interchangeable from a picture. The player compares connector specification, isolation points and the actual spare serial. The controller remains packed. This investigation does not repair the present uplink, which is still working normally.

Across the table, Mei rewrites the unanswered question. It no longer asks whether the old expedition cared. It asks who wrote N., and whether that person wants to hear from them. The difference fits on one line and changes the conversation. Ferreira leaves the personal identity page with Rao for consented release later.

The player produces two separate products: a technical compatibility note and a respectful question for the gardener. Kai clips his note inside the crate. Mei keeps her question beside a current photograph. Neither replaces the other. Ferreira takes her mug back to the watch station. Before observation begins, the player verifies that the repair procedure opens without an Earth connection.

**Exact dialogue**

- `EX-CH05-S06-L01` **Kai:** Matching shape is not matching specification.
- `EX-CH05-S06-L02` **Rafi:** Read the connector and isolation points.
- `EX-CH05-S06-L03` **Mei:** Our other question needs permission.
- `EX-CH05-S06-L04` **Ferreira:** Both kinds of repair deserve care.

**Required player actions**

1. Compare controller specifications.
2. Store the checked replacement procedure.
3. Prepare a respectful request for contact.

**Decision study and planned feedback**

Which specification comes first?
- **Connector and rating:** Electrical compatibility receives the first check.
- **Isolation and mounting:** Replacement safety receives the first check.

**Convergence:**Both comparisons complete; spare unused and present radio working..

**Learning loop**

- **Concept:** Appropriate evidence
- **Predict:** Does a matching shell prove compatibility?
- **Observe:** Compare service specifications, not appearance.
- **Explain:** Technical fit and personal permission answer different questions.
- **Transfer:** Choose evidence suited to the actual decision.

**Mandatory exit condition:**Both comparisons complete; spare unused and present radio working.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Ferreira arrives Dec 12; Rao and Noor remain on Earth.
- Noor is identified here; no live Noor voice before CH08.
- Cotton 1 planted +11 vault specimens retained; founder reserve 30 separate.
- Alo remains a petal and lineage, never resurrected.
- Dust Shield/Whipple pair is earned only after CH05; the chapter's cleaning and patching remain mandatory.
- The 2034 trays contain young unflowered seedlings and curled leaves only; no flower buds or reproductive development.

### Production constraints
- Camera-monitored safe landing.
- Amplified impact flashes without meteor trails.
- Correct stale source count to eleven retained specimens.
- All twelve scenes are required; each has a player evidence gate.
- The impact classification sequence is authored teaching content; do not label its individual flashes as imported historical observations without an actual dataset.

### Chapter bridge
Dated cotton care and a five-person handover lead to January's eclipse.


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
