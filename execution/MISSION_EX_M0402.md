# EX-M0402 — Measure Before Claiming

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Verify the beacon chain, calibrate sample evidence and identify the deposited vault. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0401`; SYS02..08; chapter puzzles P-07, P-08; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 22 active minutes. Predecessor:`EX-M0401`. Successor:`EX-M0403`. Chapter puzzle families: P-07, P-08; reuse their single shared implementations and map the actual relevant stages.

### EX-CH04-S04 — Put the Link Before the Corner
**Target:**7 minutes. **Location:**Surveyed ridge and three beacon positions. **POV:**Rafi. **Story time:**2046-10-21 morning UTC. **Legacy provenance:**`SC-0402`.

The first bend hides the station behind a ridge. Rafi stops before the blind corner, not after the base voice disappears. The player places a beacon on its surveyed mount, tests the link and confirms that it reaches the next segment. A neat-looking marker does not count unless its communication test passes.

The same reasoning develops across three short playable route segments. One site has a clear view but an unsuitable local mounting position; another has an approved mount but needs its relay alignment checked. The player combines the base slope card with the rover's close view to select the supported position at each authored checkpoint. Cruise between the segments is labelled rather than presented as empty driving time.

Kai watches a small link indicator settle beside each name. He calls the beacons little returning lights. Rafi accepts the description and keeps the engineering labels. Local radio remains the channel between the two field and two home cadets. No Earth voice substitutes for an untested ridge link. At the final corner, the player can trace an unbroken chain home on the map. The expedition has earned its view into the cold place by checking how its observations will get back.

**Exact dialogue**

- `EX-CH04-S04-L01` **Rafi:** Beacon before the blind corner.
- `EX-CH04-S04-L02` **Kai:** A little returning light.
- `EX-CH04-S04-L03` **Amara (local link):** Only if the link test says so.
- `EX-CH04-S04-L04` **Mei (local link):** We see the chain. Keep the last position in the record.

**Required player actions**

1. Place and test three beacons before blind corners.
2. Combine base map with rover view at each checkpoint.
3. Trace and verify the complete local return-link chain.

**Decision study and planned feedback**

Which beacon result permits crossing the next corner?
- **A mounted beacon with no link test:** The gate holds because physical placement does not prove communication.
- **A mounted beacon with a verified next-hop link:** The next segment becomes available with a saved checkpoint.

**Convergence:**Each corner requires its own supported link, not a repeated decorative placement..

**Learning loop**

- **Concept:** Communication infrastructure needs tested paths.
- **Predict:** Does seeing a beacon mean it can carry a message?
- **Observe:** Mounting and link verification are separate results.
- **Explain:** Line of sight and functioning relays both matter.
- **Transfer:** Test that a message reaches its destination instead of assuming a connected-looking device works.

**Mandatory exit condition:**All three beacons placed and linked before their blind corners.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH04-S05 — A Bright Patch Is Not a Report
**Target:**7 minutes. **Location:**Cold-trap reference and sample stations. **POV:**Amara through local link. **Story time:**2046-10-21 morning UTC. **Legacy provenance:**`SC-0402`.

Headlights brighten a patch of ground, and Kai wants to call it ice. Amara asks for the dry reference first. The player records the scanner's reference signal and compares sample readings using the canonical threshold rule. A low reading remains a negative control even when the image looks interesting.

The game profile gives a dry reference of two and a threshold ten units above it. Two samples exceed that threshold; one does not. The player tags the supported positives and keeps the negative result instead of hiding it from the report. The instrument scale is an educational scenario profile, not a claim of newly measured lunar water from this fictional expedition.

Rafi repeats one reading from the same controlled contact position, and the comparison agrees. Mei watches the base evidence board gain a useful map of where the signal differs. No one promises a drink or an instant mining system. The next sample is collected because evidence supports ice-bearing material, not because a bright pixel deserves a treasure animation. The player saves the control, threshold and sample positions together, giving the eventual laboratory record enough context to be challenged and understood.

**Exact dialogue**

- `EX-CH04-S05-L01` **Kai:** That bright patch is ice, right?
- `EX-CH04-S05-L02` **Amara (local link):** Reference first. Bright is an image description.
- `EX-CH04-S05-L03` **Rafi:** Dry reference recorded. Now the comparison.
- `EX-CH04-S05-L04` **Mei (local link):** Keep the negative result on the map too.

**Required player actions**

1. Record canonical dry reference 2 and threshold 12.
2. Compare sample signals 2,18,19 and tag only supported positives.
3. Repeat controlled contact and save negative control with sample positions.

**Decision study and planned feedback**

Which report is supported?
- **Every bright patch is water:** The dry reference and low sample reject a visual-only claim.
- **Signals above the calibrated threshold support ice-bearing material:** The two positive readings and retained control support a limited sample claim.

**Convergence:**Only calibrated positives can be reported; no drinking-water or mining conclusion is granted..

**Learning loop**

- **Concept:** Controls and calibration distinguish signals from appearances.
- **Predict:** Can a bright image alone establish composition?
- **Observe:** Calibrated readings separate positive samples from a negative control.
- **Explain:** Measurements support a bounded claim with a stated method.
- **Transfer:** Use a comparison or control before interpreting an attractive image.

**Mandatory exit condition:**Reference, threshold, two positives and negative control saved correctly.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH04-S06 — Something With Corners
**Target:**8 minutes. **Location:**Cold-trap sample point and vault approach. **POV:**Kai. **Story time:**2046-10-21 10: 30 UTC. **Legacy provenance:**`SC-0403`.

The sealed sample enters its holder. As Kai turns the light back towards the survey marker, a manufactured corner appears beyond it. The shape belongs to an insulated case, not to the rock. Mei sees the match to the recovered map on the base screen while Rafi checks their present position and return forecast.

The player records the sample context before moving to the case. Two discoveries do not become one mixed bag of evidence. The sample retains its position and calibrated result; the vault gets a separate photographic record, marker match and handling assessment. Kai brushes only the external identification window with the approved tool. The biological seal stays closed.

The old deposit date agrees with the earlier authorised route. Somebody intended the case to outlast a disrupted mission, but the game offers no certainty yet about who or what survived inside. Rafi tethers the closed carrier alongside the vault and asks the player to check reserve before beginning recovery. Curiosity has created a new task, not permission to forget the return plan. The final photograph shows both case and marker, making the discovery understandable even to someone who was never there.

**Exact dialogue**

- `EX-CH04-S06-L01` **Mei (local link):** That shape did not grow there.
- `EX-CH04-S06-L02` **Kai:** Neither did we.
- `EX-CH04-S06-L03` **Rafi:** Separate sample record. Separate case record. Seal stays closed.
- `EX-CH04-S06-L04` **Amara (local link):** Reserve supports recovery. Record the handling assessment first.

**Required player actions**

1. Seal the verified sample with its own provenance.
2. Photograph case and matching survey marker separately.
3. Check return reserve and tether a closed recovery carrier.

**Decision study and planned feedback**

How should the two discoveries be recorded?
- **Combine everything as a single treasure find:** The evidence board requests separate sample and case records before proceeding.
- **Maintain separate sample and vault provenance:** Both discoveries retain the context needed for later interpretation.

**Convergence:**The sealed sample and untouched vault remain distinct physical objects with distinct evidence..

**Learning loop**

- **Concept:** Independent evidence streams should not be conflated.
- **Predict:** Does finding a case prove what its seeds experienced?
- **Observe:** Exterior provenance cannot establish inner biological condition.
- **Explain:** Object history and specimen viability are different questions.
- **Transfer:** Keep separate labels when collecting different kinds of samples or records.

**Mandatory exit condition:**Sample sealed, case provenance saved and recovery carrier secured.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
