# EX-M0602 — The Plan We Share

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Compare options, rehearse isolation and collect actual readiness reports. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0601`; SYS02..08; chapter puzzles P-11, P-12; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 25 active minutes. Predecessor:`EX-M0601`. Successor:`EX-M0603`. Chapter puzzle families: P-11, P-12; reuse their single shared implementations and map the actual relevant stages.

### EX-CH06-S04 — The Brightest Plan Is Not the Best Plan
**Target:**8 minutes. **Location:**Power room, side-by-side preview. **POV:**Kai. **Story time:**12 January, uncommitted rehearsal. **Legacy provenance:**`SC-0602`.

Kai makes a deliberately comfortable proposal: keep the decorative floods on so the corridor never feels dark. The player puts that proposal beside the protected guide-light plan. Neither preview spends actual reserve. Both show the same forecast and equipment, so a change in one load has an interpretable consequence.

The floodlight plan consumes margin without helping scrubbers, return water or the filtered camera. Kai can see exactly what that brightness would cost the shared mission. Rafi does not tell him to stop wanting light. He moves the small guide light into the same corridor view. The player compares usefulness, power and the available path rather than treating every comfort as waste.

Amara asks Kai to describe the chosen compromise to Mei. Explaining it makes the decision a team promise: the room can be dim while a reliable route remains visible. The player labels the guide-light branch and disables decorative floods in the proposed schedule. Both plans remain in the debrief, allowing a later learner to see why the quieter one worked.

**Exact dialogue**

- `EX-CH06-S04-L01` **Kai:** I wanted the whole corridor bright.
- `EX-CH06-S04-L02` **Rafi:** You need a known way through it.
- `EX-CH06-S04-L03` **Mei:** Keep that way in the plan.
- `EX-CH06-S04-L04` **Kai:** Small light. Protected supply.

**Required player actions**

1. Compare one changed load in matched previews.
2. Inspect reserve consequences.
3. Label and retain protected guide lighting.

**Decision study and planned feedback**

Which plan meets Kai's need and preserves shared reserves?
- **Keep decorative floods throughout:** Matched preview shows reserve spent without added essential service.
- **Protect the small guide-light route:** The useful route remains lit while circulation, pump and camera keep their margin.

**Convergence:**Decorative floods shed; guide-light need and reserve both protected..

**Learning loop**

- **Concept:** Trade-offs and controlled comparison
- **Predict:** What changes if only decorative lighting changes?
- **Observe:** Compare matched previews.
- **Explain:** A useful compromise can meet a need with less resource cost.
- **Transfer:** Distinguish a service goal from one expensive way to meet it.

**Mandatory exit condition:**Decorative floods shed; guide-light need and reserve both protected.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_06.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH06-S05 — A Fault Before It Matters
**Target:**9 minutes. **Location:**Protected-bus test panel. **POV:**Amara. **Story time:**12 January, pre-observation test. **Legacy provenance:**`SC-0603`.

Before the camera can observe anything, Amara offers the player a safe rehearsal fault. A test branch can be disconnected without touching the live habitat services. Its label is large enough to read and its status appears in text as well as colour. The player predicts which indicator should change before selecting the simulated disconnect.

Only the test branch drops. The protected essentials remain on, just as the diagram promised. If the player expected a complete blackout, the board traces the isolating boundary instead of merely announcing an incorrect answer. Kai reads the same route physically across the panel. Rafi rehearses the short local checkback they will use during an actual interruption.

The player restores the test branch through the approved sequence and verifies the return. The exercise ends in the same safe state in which it began. It has created no additional failure in the habitat. Ferreira checks that the rehearsal result and the actual mission readiness are distinct records. A successful simulation supports confidence, but the next scene still requires every real station check.

**Exact dialogue**

- `EX-CH06-S05-L01` **Amara:** Predict the affected branch first.
- `EX-CH06-S05-L02` **Kai:** Essentials should stay on.
- `EX-CH06-S05-L03` **Rafi:** Local channel check. Here.
- `EX-CH06-S05-L04` **Ferreira:** A rehearsal pass does not sign the watch.

**Required player actions**

1. Predict the safe test fault.
2. Compare affected and protected branches.
3. Restore and verify the test branch.

**Decision study and planned feedback**

How should the boundary be inspected?
- **Trace the diagram:** The isolation edge is highlighted.
- **Inspect panel labels:** The same edge is checked on equipment.

**Convergence:**Test branch restored, protected services stable, rehearsal recorded separately..

**Learning loop**

- **Concept:** Fault isolation and redundancy
- **Predict:** Will one branch fault remove every service?
- **Observe:** Observe a bounded test interruption.
- **Explain:** Isolation limits which systems a fault can affect.
- **Transfer:** Identify dependencies before resetting equipment.

**Mandatory exit condition:**Test branch restored, protected services stable, rehearsal recorded separately.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_06.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH06-S06 — Ready Is a Shared Word
**Target:**8 minutes. **Location:**Aurora mission table and filtered camera. **POV:**Kai. **Story time:**12 January, ingress readiness. **Legacy provenance:**`SC-0603`.

The player brings the checked schedule to the mission table. Mei has not watched the power rehearsal; she has been checking plants. Amara has atmosphere readings, and Rafi has the shelter and hand-light status. None of those observations becomes shared merely because they exist in different rooms.

Kai asks each role for a short report and repeats the part his schedule depends on. The player places the matching readiness token only after its observation is acknowledged. Five time segments remain visible above four role checks. The sequence cannot be completed by repeatedly pressing a single unlabelled confirmation.

The external camera's protective configuration is checked before its image appears. Nobody looks directly into a bright Sun to prove courage. If verified local geometry is not yet available in production, the screen clearly uses the source-informed scenario view and conceptual diagram. The same engineering decisions remain meaningful. Ferreira asks whose call it is. Kai looks around the occupied work positions before answering. Readiness belongs to the crew who checked the plan, not to the loudest person in the room.

**Exact dialogue**

- `EX-CH06-S06-L01` **Mei:** Plants checked.
- `EX-CH06-S06-L02` **Amara:** Atmosphere checked.
- `EX-CH06-S06-L03` **Rafi:** Shelter, lamp and local channel checked.
- `EX-CH06-S06-L04` **Kai:** Ready means all of us.

**Required player actions**

1. Collect four actual role reports.
2. Acknowledge all five schedule segments.
3. Verify the camera's protective configuration.

**Decision study and planned feedback**

How should Kai close the readiness call?
- **Repeat dependencies:** Each role hears what the plan needs.
- **Read the final checklist together:** All roles confirm the same record.

**Convergence:**Four role checks, five segments and protected camera ready..

**Learning loop**

- **Concept:** Closed-loop team communication
- **Predict:** Does a private observation help an uninformed teammate?
- **Observe:** Compare delivered, acknowledged and shared reports.
- **Explain:** Checkbacks establish a shared plan.
- **Transfer:** Repeat essential information and invite correction.

**Mandatory exit condition:**Four role checks, five segments and protected camera ready.
**Evidence boundary:**Computed-pending. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_06.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
