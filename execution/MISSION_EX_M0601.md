# EX-M0601 — A Plan for Darkness

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Turn human needs and service dependencies into one checked allocation. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch06/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0504`; SYS02..08; chapter puzzles P-11, P-12; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 6:**The Red Ring**; dates: 12 January–14 February 2047; chapter target: 85 minutes.

Kai turns an old fear into a shared engineering plan. The crew rehearses a five-segment protected-service budget, records a labelled eclipse view, connects family within a valid path and receives Noor's known-sender text. A bounded camera fault is isolated and recovered without losing essentials. Dated care bridges to a genuinely new February warning.

Emotional arc:Admission → preparation → shared wonder → interruption → supported action..

This mission target: 20 active minutes. Predecessor:`EX-M0504`. Successor:`EX-M0602`. Chapter puzzle families: P-11, P-12; reuse their single shared implementations and map the actual relevant stages.

### EX-CH06-S01 — The Lamp Is Still Here
**Target:**6 minutes. **Location:**Power room, hand-light locker. **POV:**Kai. **Story time:**12 January 2047, before eclipse preparation. **Legacy provenance:**`SC-0601`.

Kai remembers the locker without needing its label. Inside is the hand light Rafi left within reach during their first night. It is scratched now, and its battery needs a measured charge. The player picks it up instead of searching for a brighter replacement. Familiar equipment carries evidence of previous use.

Ferreira arrives at the doorway and waits while Kai checks the charge. He says plainly that he is still afraid of the dark. No one calls this a failure of training. Amara adds the lamp to the protected-service plan as a small, useful load. Rafi asks whether Kai wants company during the transfer. The player chooses a companion without changing anyone's assigned responsibility.

The room does not become frightening to prove his fear real. Its ordinary hum continues while the checklist fills. Kai clips the charged lamp where both hands can remain free. His first task is complete because he has identified a need and prepared for it, not because he has stopped feeling it.

**Exact dialogue**

- `EX-CH06-S01-L01` **Kai:** The lamp still matters.
- `EX-CH06-S01-L02` **Rafi:** So does asking for company.
- `EX-CH06-S01-L03` **Ferreira:** Plan with the facts you have.
- `EX-CH06-S01-L04` **Amara:** Guide light goes on the protected list.

**Required player actions**

1. Check lamp charge.
2. Review the protected-service list.
3. Choose an available companion.

**Decision study and planned feedback**

Who stays beside Kai?
- **Rafi:** He supplies calm local checkbacks.
- **Amara:** She supplies the same checkbacks from the panel.

**Convergence:**Lamp charged and companion assigned..

**Learning loop**

- **Concept:** Human factors in planning
- **Predict:** Does confidence eliminate the need for support?
- **Observe:** Check equipment and name the support required.
- **Explain:** Good planning includes predictable human needs.
- **Transfer:** Prepare tools and ask for help before pressure rises.

**Mandatory exit condition:**Lamp charged and companion assigned.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_06.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH06-S02 — A Memory With a Switch
**Target:**7 minutes. **Location:**Power room, dated personal log. **POV:**Kai. **Story time:**12 January, calm planning interval. **Legacy provenance:**`SC-0601`.

The player opens Kai's short memory beside the present circuit map. A childhood storm once left his home dark without warning. The log offers sounds and a text equivalent, not a forced frightening reenactment. Kai can stop the memory and keep every fact needed for the mission.

What frightened him was not simply a missing bulb. It was not knowing when the light would return or who had a plan. On the table, the player separates those uncertainties into questions the crew can answer: which services remain powered, what the forecast covers, and how to signal a fault. The eclipse schedule is a source-informed scenario, with local timing still awaiting verified geometry.

Rafi points to a guide-light branch that appears on every segment. Kai traces it with one finger and checks the reserve once. The animation echoes his old double-checking habit without making caution the joke. He closes the memory himself. This time the room has a map, a companion and a way to ask what happens next.

**Exact dialogue**

- `EX-CH06-S02-L01` **Kai:** I did not know when it would return.
- `EX-CH06-S02-L02` **Rafi:** This time we can read the plan.
- `EX-CH06-S02-L03` **Amara:** A forecast still has limits.
- `EX-CH06-S02-L04` **Kai:** Then label the limits too.

**Required player actions**

1. Read or skip the accessible memory.
2. Turn uncertainties into checkable questions.
3. Trace the guide-light supply.

**Decision study and planned feedback**

Which question starts the plan?
- **What stays powered?:** Kai traces protected services.
- **How do we report a fault?:** The crew rehearses the local call.

**Convergence:**Protected path and local fault-reporting method identified..

**Learning loop**

- **Concept:** Turning uncertainty into questions
- **Predict:** Which uncertainty can the team reduce?
- **Observe:** Connect each concern with a checkable plan item.
- **Explain:** A plan supports action without promising perfect prediction.
- **Transfer:** Name an uncertainty and find a relevant observation.

**Mandatory exit condition:**Protected path and local fault-reporting method identified.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_06.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH06-S03 — The Seven-Unit Promise
**Target:**7 minutes. **Location:**Power room, eclipse allocation board. **POV:**Kai. **Story time:**12 January, forecast rehearsal. **Legacy provenance:**`SC-0602`.

Five segment cards spread across the board: precharge, ingress, totality, egress and recovery. Kai places essential services beneath every card. Air circulation, minimum heat, dim growth light and the guide light travel as a protected package. The player can expand the package to see its components without making four disconnected promises.

The current rehearsal uses a labelled teaching allocation. Five essential packages, one pump preparation and one camera preparation cost seven game units altogether. They are not kilowatt-hours, and the board does not add a second elapsed-time bill. Amara checks the arithmetic against the displayed jar and return margin. The verified-data version will replace this fallback as a single model, not stack another cost on it.

Kai asks the player to predict the result before running the rehearsal. A missing package makes a specific service warning appear in its segment. Fixing it changes the forecast immediately. A correct plan is a visible relationship between choices and outcomes, not a hidden combination copied from an answer key.

**Exact dialogue**

- `EX-CH06-S03-L01` **Kai:** Five segments. Essentials in every one.
- `EX-CH06-S03-L02` **Amara:** Pump once. Camera once.
- `EX-CH06-S03-L03` **Rafi:** Seven game units, one accounting model.
- `EX-CH06-S03-L04` **Ferreira:** Show the forecast before committing.

**Required player actions**

1. Place essentials in five segments.
2. Allocate pump and camera readiness once.
3. Predict and compare the seven-unit total.

**Decision study and planned feedback**

Which allocation protects every required eclipse segment?
- **Five essentials plus pump once and camera once:7 units:** The forecast preserves all five packages and the disclosed margin.
- **Four essentials plus decorative floods:** The preview reveals an unprotected segment and wasted margin.

**Convergence:**Five-segment teaching allocation reconciled without duplicate charges..

**Learning loop**

- **Concept:** Finite energy accounting
- **Predict:** What total should the displayed plan consume?
- **Observe:** Compare component sum with the rehearsal result.
- **Explain:** A budget counts each action once in one unit system.
- **Transfer:** Check for omitted loads and double-counting.

**Mandatory exit condition:**Five-segment teaching allocation reconciled without duplicate charges.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_06.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Five lunar occupants; Noor and Rao remain Earth-based.
- Five eclipse segments, seven-unit teaching allocation, never a duplicate duration charge.
- Jan 12 eclipse date does not certify Aurora's local view or Bangladesh sunrise geometry.
- Noor sends text; the earlier eclipse memory has no invented date.
- Cotton grows through dated care; founder 30 and retainedvault 11 remain separate.

### Production constraints
- Provide a filtered instrument feed or visibly conceptual fallback until local geometry is verified.
- All voice and memory content has text parity.
- Camera F2 fault leaves protected habitat services powered.
- No cure-of-fear claim, unsafe solar viewing or assistance penalty.

### Chapter bridge
A dated monitoring montage leads to a new shared February alert, not a month-ahead prediction.


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
