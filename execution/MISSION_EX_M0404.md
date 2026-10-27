# EX-M0404 — Bring the Question Home

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Stabilise and inventory 12 specimens, send the inscription and prepare for Ferreira's actual arrival. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0403`; SYS02..08; chapter puzzles P-07, P-08; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 24 active minutes. Predecessor:`EX-M0403`. Successor:`EX-M0501`. Chapter puzzle families: P-07, P-08; reuse their single shared implementations and map the actual relevant stages.

### EX-CH04-S10 — Twelve Wells, Twelve Questions
**Target:**8 minutes. **Location:**Dry quarantine glove box. **POV:**Mei. **Story time:**2046-10-22 after controlled sealed warming UTC. **Legacy provenance:**`SC-0405`.

The case warms while sealed, under a controlled profile in the dry glovebox. The player checks that the stabilisation criterion is met before breaking the biological seal inside that protected workspace. Warming is not represented as proof that every seed is viable. It is the next careful step towards assessing what was preserved.

Twelve distinct specimen wells appear beneath the lid, including cotton. The player matches each label with the case manifest and creates a separate condition entry. An illustrated collection page can record knowledge about a specimen, but it does not add another physical seed. The founder reserve and current garden remain on different pages with different counts.

Kai recognises cotton from the first chapter's real-history reference. Mei asks everyone to keep the whole collection safe before choosing a future planting. None is consumed in this scene. The full physical vault inventory remains twelve until cotton is planted later in December, after which eleven other specimens remain stored. The player scans the lid only after the handling work is complete. The reward arrives as a line of handwriting, supported by a chain of decisions that has kept both the object and its meaning intact.

**Exact dialogue**

- `EX-CH04-S10-L01` **Amara:** Stable and dry. Now we open it inside the glovebox.
- `EX-CH04-S10-L02` **Rafi:** Twelve distinct specimens. Twelve condition entries.
- `EX-CH04-S10-L03` **Kai:** Cotton. Like the first chapter of the real history.
- `EX-CH04-S10-L04` **Mei:** We keep the whole collection safe before we choose what to grow.

**Required player actions**

1. Verify sealed warming and dry protected handling.
2. Inventory twelve distinct specimens without consuming any.
3. Separate physical vault inventory, founder reserve and collection album.

**Decision study and planned feedback**

Which inventory statement is correct?
- **An album entry adds another physical seed:** The ledger rejects a category error between knowledge and stock.
- **An album entry records knowledge about an existing specimen:** The physical vault remains twelve while its documented information grows.

**Convergence:**All twelve physical specimens remain stored at this gate; no cotton planting occurs yet..

**Learning loop**

- **Concept:** A collection record is not a physical resource.
- **Predict:** Does documenting a specimen duplicate it?
- **Observe:** Album and specimen store carry separate counts.
- **Explain:** Information and conserved material require different ledgers.
- **Transfer:** Keep photographs or records distinct from the objects they describe.

**Mandatory exit condition:**Warming verified, twelve specimen entries reconciled and all specimens retained.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH04-S11 — Ask Commander Ferreira
**Target:**8 minutes. **Location:**Glove box scan station and Earth console. **POV:**Mei. **Story time:**2046-10-22 valid Earth contact window UTC. **Legacy provenance:**`SC-0405`.

The handwriting asks the finder to speak to Commander Ferreira about Expedition Zero. It supplies a connection, not the complete story. Mei reads the line once, then sends a clear image and the reconciled manifest through the available Earth path. Nobody supplies a name from initials alone.

The player compares what the new evidence changes. The case was intentionally preserved; the trial had a human history; Ferreira is the appropriate person to ask. It does not establish that the writer died, that the commander abandoned anyone or that the seed specimens will all grow. Those conclusions remain outside the acquired evidence.

Ferreira's channel is quiet for a moment. Rao confirms the technical receipt and approved safety instructions, keeping personal hesitation separate from operational support. Mei chooses how to phrase an invitation to explain, without turning disclosure into a coercive dialogue puzzle. Kai begins a joke and lets it go. The crew can feel that a familiar adult has a difficult connection to their discovery. That feeling gives the scene weight without replacing the Chapter 5 reveal. The player saves the exact inscription and the unanswered question together, allowing the next chapter to answer what this one has honestly earned.

**Exact dialogue**

- `EX-CH04-S11-L01` **Mei:** The lid says: ask Commander Ferreira about Expedition Zero.
- `EX-CH04-S11-L02` **Kai:** That is a question with an address.
- `EX-CH04-S11-L03` **Rao (Earth link):** Manifest received. Your safety support is unchanged.
- `EX-CH04-S11-L04` **Mei:** Then tell her we would like the whole story when she is ready.

**Required player actions**

1. Scan the inscription and send exact evidence with the manifest.
2. Classify new supported claims separately from speculative personal conclusions.
3. Send a respectful request and record actual receipt status.

**Decision study and planned feedback**

What does the inscription support?
- **A final verdict about who was abandoned:** The evidence board rejects a personal accusation not established by the record.
- **A direct request for Ferreira to explain her connection:** The next inquiry follows the supported personal reference.

**Convergence:**The question remains open until Chapter 5; safety information is already available..

**Learning loop**

- **Concept:** New evidence can identify the next question without answering it.
- **Predict:** Does a named contact establish the whole history?
- **Observe:** The inscription connects an inquiry, not a verdict.
- **Explain:** Responsible investigation avoids turning incomplete evidence into accusation.
- **Transfer:** Ask a source what they can verify and retain the exact supporting record.

**Mandatory exit condition:**Exact lid record saved, manifest delivered and personal question left open.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH04-S12 — A Fifth Mug Has a Journey
**Target:**8 minutes. **Location:**Mission table, relief manifest and prepared locker. **POV:**Kai. **Story time:**2046-10-22 through December 12 UTC. **Legacy provenance:**`SC-0406`.

Kai puts a fifth mug beside the four familiar ones. Amara adds it to the inventory before anyone can describe the gesture as reckless generosity. The spare place belongs to a scheduled traveller. Kai reads the flight notice before putting her name on the locker.

The player reads the relief assignment: Ferreira departs Earth on December 8 and arrives on December 12 with the planned support flight. Rao remains at the Earth console. Hardware, quarantine supplies and routine habitat needs are checked against the cargo manifest, while the current garden and protected specimens retain their care plan. This is resupply supporting an operating base, not an unexplained ability to survive indefinitely on a mustard flower.

Ferreira promises to bring the personal story. She does not ask the crew to postpone a safety check until then. The player prepares her locker, verifies the fifth-occupant handover for arrival and confirms the dated October-to-December maintenance transition. Photos and care entries show the intervening work. At the final date card the mug is still waiting, and the player can name the route that brought its owner. A room once made for four is ready to listen to a fifth person who will have to speak as herself.

**Exact dialogue**

- `EX-CH04-S12-L01` **Kai:** We have a spare mug.
- `EX-CH04-S12-L02` **Amara:** A carefully inventoried spare mug.
- `EX-CH04-S12-L03` **Ferreira (Earth link before travel):** December 8 to 12. My relief assignment brings me there. I owe you the story.
- `EX-CH04-S12-L04` **Mei:** Bring it when you come. The safety report is already here.

**Required player actions**

1. Verify relief flight dates, cargo and continuing Earth support.
2. Prepare locker and fifth-occupant arrival handover.
3. Complete dated maintenance and specimen-care bridge to December 12.

**Decision study and planned feedback**

Which arrival account is physically supported?
- **Ferreira appears without transit while still commanding from Earth:** The chronology review rejects duplicate physical presence.
- **Ferreira travels December 8-12 and arrives with the planned relief:** Her Earth role ends for transit  while Rao retains Earth support.

**Convergence:**Chapter 5 begins at her actual arrival; all later lunar occupancy includes the fifth person..

**Learning loop**

- **Concept:** People, supplies and responsibilities require transitions.
- **Predict:** Can a character change location without time and support?
- **Observe:** The manifest and date cards trace her flight and role handover.
- **Explain:** Continuity is logistical as well as emotional.
- **Transfer:** A team handover should state who travels, who covers and when responsibility changes.

**Mandatory exit condition:**Flight and support manifest checked, locker ready and dated arrival transition confirmed.
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
