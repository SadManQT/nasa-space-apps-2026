# EX-M0401 — Make the Old Map Current

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Test the trait prediction, split ledgers correctly and justify a safe route. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch04/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0304`; SYS02..08; chapter puzzles P-07, P-08; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 4:**Into the Cold Trap**; dates: 21 October-12 December 2046, with dated return and relief-flight gates; chapter target: 90 minutes.

The crew tests the old trait prediction, sends Rafi and Kai on a safely budgeted ridge expedition and keeps Mei and Amara at base. Calibrated ice evidence leads to a sealed vault recovery. Twelve distinct specimens and a handwritten instruction connect the investigation to Ferreira, whose scheduled arrival sets up the next chapter.

Emotional arc:Curiosity tested -> caution recognised -> field confidence -> preserved discovery -> personal anticipation..

This mission target: 22 active minutes. Predecessor:`EX-M0304`. Successor:`EX-M0402`. Chapter puzzle families: P-07, P-08; reuse their single shared implementations and map the actual relevant stages.

### EX-CH04-S01 — What Actually Grew
**Target:**7 minutes. **Location:**Aurora descendant rack and prediction notebook. **POV:**Mei. **Story time:**2046-10-21 06: 00 UTC. **Legacy provenance:**`SC-0401`.

Before Rafi can open the rover checklist, Mei places the old stem prediction beside the current garden. The player inspects twelve current descendants, recording seven purple stems and five green in this authored observation. The game does not present this small fictional sample as a verified genetic ratio.

Amara asks the player to compare the actual observation with the prediction saved in May. A confident prediction can be wrong without making the investigation a failure. An uncertain prediction can gain information without pretending it was secretly correct all along. The original entry remains visible, with the new evidence added beside it rather than written over it.

Kai asks which seed was Alo. Mei points to the parent line, not a surviving original plant. The pressed petal and founder photograph are archived nearby; the present plants belong to continuing generations. The player checks the thirty-seed founder reserve separately from the twelve current descendants. Counting these plants does not spend or replenish those protected founder seeds. Rafi closes the comparison with one question: what observation should they make next? The answer becomes a new journal question, while the safe route expedition proceeds with the lesson already earned: a useful prediction leads back to evidence.

**Exact dialogue**

- `EX-CH04-S01-L01` **Mei:** Our old prediction is here. Now count what actually grew.
- `EX-CH04-S01-L02` **Amara:** Seven purple, five green in this sample. Not a promised ratio.
- `EX-CH04-S01-L03` **Kai:** So which one is Alo?
- `EX-CH04-S01-L04` **Mei:** Their lineage is Alo and Tara. The original plant finished its life.

**Required player actions**

1. Observe all twelve descendants with accessible trait labels.
2. Compare the saved prediction without rewriting it.
3. Separate current plants, founder reserve and archived original Alo evidence.

**Decision study and planned feedback**

What conclusion fits the sample?
- **This proves a universal inheritance ratio:** The evidence board rejects a claim beyond the fictional sample.
- **This describes the twelve observed descendants:** The board accepts the limited observation and retains new questions.

**Convergence:**Either study preserves the original prediction and records the same actual sample honestly..

**Learning loop**

- **Concept:** Predictions are tested by observations, not protected from them.
- **Predict:** Does one sample establish a universal rule?
- **Observe:** The notebook retains prediction and observation separately.
- **Explain:** Sample size and unknown genetics limit conclusions.
- **Transfer:** Keep the original hypothesis when reporting a classroom experiment.

**Mandatory exit condition:**Saved prediction compared with twelve current descendants and limits recorded.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH04-S02 — Two Seats Out, Two Voices Home
**Target:**7 minutes. **Location:**Rover bay and base handover screen. **POV:**Rafi. **Story time:**2046-10-21 before departure UTC. **Legacy provenance:**`SC-0401`.

Rafi checks the rover twice, then admits it was three times. Kai starts to tease him and stops when Ferreira formally assigns field leadership. Caution has become a qualification. Two occupied rover seats appear beside the home-team screen: Rafi and Kai go; Mei and Amara remain at Aurora.

The player prepares the rover seal, scanner, closed carrier and independent consumables manifest. The base ledger accounts only for the two people staying home. The rover's dated round trip has its own support manifest, so the same occupants are not charged twice. The interface lets the player trace each person from the name list to the correct ledger.

Mei sends the map and current garden status. Amara holds the detailed slope card, while the field team will supply the headlight view. Neither perspective alone contains the whole route. Rafi asks for the handover in plain words before the hatch closes. Kai checks the spare light once, reads the labelled position and leaves it there. The habit recalls April without pretending his fear is cured. The team leaves a station with people in it, and takes a plan that has room for returning.

**Exact dialogue**

- `EX-CH04-S02-L01` **Rafi:** I checked twice. Three times. I wanted to sound relaxed.
- `EX-CH04-S02-L02` **Ferreira (Earth link):** Rafi leads the field team. Returning is part of the objective.
- `EX-CH04-S02-L03` **Amara:** Two at base, two in the rover. Each ledger counts its own people.
- `EX-CH04-S02-L04` **Kai:** Light checked. Once more is not a new person in the manifest.

**Required player actions**

1. Verify rover seal, scanner, carrier and independent provisions.
2. Assign two field and two base occupants to separate ledgers.
3. Read back shared map, communications and return responsibilities.

**Decision study and planned feedback**

Which occupant ledger is valid?
- **Charge four people at base and two again in the rover:** The preview detects duplicated consumption.
- **Charge two at base and two on the independent rover manifest:** The ledger accounts for each crew member once.

**Convergence:**The field departure gate requires exactly two field and two home occupants..

**Learning loop**

- **Concept:** System boundaries prevent double-counting.
- **Predict:** Should travellers also consume the home-team allocation?
- **Observe:** Each person appears in exactly one active location ledger.
- **Explain:** Totals depend on who is where and for how long.
- **Transfer:** When splitting a team, assign resources and responsibilities to actual participants.

**Mandatory exit condition:**Seal, equipment, provisions and two-plus-two handover verified.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH04-S03 — The Short Road Is Not the Safe Road
**Target:**8 minutes. **Location:**Shared route preview and rover navigation display. **POV:**Rafi. **Story time:**2046-10-21 departure UTC. **Legacy provenance:**`SC-0402`.

The old map becomes three current route cards. Route A is short but too steep for the rover. Route C is darker and also exceeds its slope limit while consuming the return reserve. Route B follows a longer ridge with an acceptable slope and a supported round trip. Kai sees the short line first; Amara's base card adds what its attractive distance does not show.

The player predicts reserve after both outbound and return travel, then compares that result with the slope constraint. In the canonical game profile, route B uses thirty units each way from a hundred, leaving forty against a required thirty. Its twelve-degree maximum remains below the fifteen-degree rover limit. These are scenario values, not a surveyed lunar road certification.

The route does not become valid because the player found a clever way to ignore one requirement. Both limits must hold. Rafi records the reason for rejecting each alternative, allowing the base team to understand the decision rather than merely receive it. Kai moves the short-route card aside himself. Beyond the rover window, the ridge bends out of sight. Their next job is making sure the radio plan can bend with it.

**Exact dialogue**

- `EX-CH04-S03-L01` **Kai:** The short route is right there.
- `EX-CH04-S03-L02` **Amara (local link):** So is its slope limit.
- `EX-CH04-S03-L03` **Rafi:** Both directions count. Both constraints count.
- `EX-CH04-S03-L04` **Mei (local link):** Then we take the ridge together, even from different rooms.

**Required player actions**

1. Compare route distance, slope and two-way resource forecasts.
2. Calculate route B return reserve under the canonical game profile.
3. Reject unsupported routes with explicit reasons and save the route B plan.

**Decision study and planned feedback**

Which route passes both constraints?
- **Route A, the shortest:** Its slope exceeds the rover limit even though its resource forecast looks attractive.
- **Route B, the ridge:** Its slope and two-way reserve both pass; route C is also tested and rejected in the comparison.

**Convergence:**Only route B can be committed; the player must explain both constraints before departure..

**Learning loop**

- **Concept:** Planning combines constraints instead of optimising one number.
- **Predict:** Does shortest always mean safest or cheapest?
- **Observe:** Each route has a different slope and roundtrip cost.
- **Explain:** A valid solution must satisfy every hard constraint.
- **Transfer:** Compare safety limits and return needs before choosing an apparently convenient route.

**Mandatory exit condition:**Canonical route B chosen with slope and return-reserve justification.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- The Octobertrait sample pays off the May prediction without a guaranteed genetic ratio.
- Rafi and Kai occupy the rover; Mei and Amara stay at base; Ferreira is remote until December 12.
- Canonical route B returns 40 against a required 30; all three beacons are tested before blind corners.
- Scanner reference 2, threshold 12 and sample signals 2/18/19 are explicitly tagged game-profile values.
- The vault remains sealed through transport and controlled warming. Its 12 specimens are physical inventory, distinct from album entries.
- Cotton is identified but not planted here; its December 15 planting leaves 11 other vault specimens stored.
- No identification of N., survival announcement or Academy-founder reveal occurs before Chapter 5.
- October-to-December care, scheduled resupply and the December 8-12 flight are explicit.

### Production constraints
- Use hard black shadows and cabin, suit or contact audio; no airborne vacuum wind or fog.
- Maintain separate base and field viewpoints and occupant ledgers.
- Show continuous case handling and readable labels, with no unexplained object relocation.
- All 90 minutes are mandatory investigation, planning, field checks and recovery; cruise is transitioned rather than padded.

### Chapter bridge
Ferreira arrives December 12 on her planned relief flight. Chapter 5 can reveal an identity and history after the evidence-supported personal inquiry.


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
