# EX-M0604 — The Light That Returns

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Restore the camera, account for recovery and hand over sustained monitoring. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0603`; SYS02..08; chapter puzzles P-11, P-12; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 20 active minutes. Predecessor:`EX-M0603`. Successor:`EX-M0701`. Chapter puzzle families: P-11, P-12; reuse their single shared implementations and map the actual relevant stages.

### EX-CH06-S10 — The Next Light
**Target:**6 minutes. **Location:**Power room, camera feeder F2. **POV:**Kai. **Story time:**12 January, protected transfer. **Legacy provenance:**`SC-0605`.

The view screen drops. The guide light stays on. For a second Kai's hand closes around the lamp before he remembers to read the protected-service indicators. Atmosphere, circulation and garden minimums remain stable. The interruption belongs to camera feeder F2, not to the entire habitat.

The player calls the local checkback rehearsed earlier. Rafi answers. Amara points to the same isolation boundary used on the safe test board. The player isolates F2 and checks the cleared fault indication before resetting anything. A button pressed out of sequence offers the missing condition in words; it does not manufacture a lethal punishment.

Kai speaks the actions as they occur. The room never becomes bright enough to erase his fear, and it does not need to. After the protected sequence, he reconnects only the camera branch for its test. Ferreira remains nearby without taking over the player's task. A successful reset returns a view, but the important change is a repeatable method: stop, identify, isolate, verify and ask someone to stay on the channel.

**Exact dialogue**

- `EX-CH06-S10-L01` **Kai:** Rafi, stay on the channel.
- `EX-CH06-S10-L02` **Rafi:** Here.
- `EX-CH06-S10-L03` **Amara:** Essentials hold. Isolate F2.
- `EX-CH06-S10-L04` **Kai:** Isolated. Check, then reset.

**Required player actions**

1. Identify F2 without shedding essentials.
2. Isolate and verify fault clearance.
3. Reset and reconnect the camera branch safely.

**Decision study and planned feedback**

Which response fits the bounded F2 fault?
- **Reset all habitat power:** The preview identifies unnecessary disruption to protected services; revise the procedure.
- **Isolate, verify and restore camera F2 only:** The affected branch returns while protected services remain powered.

**Convergence:**F2 safely restored in the approved sequence; protected services uninterrupted..

**Learning loop**

- **Concept:** Safe fault response
- **Predict:** Which systems actually lost power?
- **Observe:** Read protected and failed branch indicators.
- **Explain:** A bounded fault requires a bounded response.
- **Transfer:** Diagnose before resetting everything.

**Mandatory exit condition:**F2 safely restored in the approved sequence; protected services uninterrupted.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_06.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH06-S11 — Egress Is a Result
**Target:**7 minutes. **Location:**Restored camera and debrief board. **POV:**Kai. **Story time:**12 January, egress and recovery. **Legacy provenance:**`SC-0605`.

The camera image returns before the last observation gate. The player checks its time label, records egress and compares the recovered view with the saved ingress and ring frames. The interruption remains visible in the record. There is no need to pretend the camera never failed in order to report a successful observation.

Amara asks for the final energy check under the same teaching model. The player reconciles the one-time pump and camera allocations, the essential packages and the remaining margin. No extra fault penalty is silently charged for following the correct procedure. If an earlier setting needs revision, the checkpoint identifies that setting rather than demanding an entire chapter replay.

Kai places the lamp back in its clip without turning it into a trophy. He says he was afraid and completed the work anyway. Rafi repeats the part that made it possible: a plan, a known light and a crew who answered. The player saves the causal debrief, linking the protected design to the services that survived. Courage is recorded as supported action, not an emotion supposedly cured.

**Exact dialogue**

- `EX-CH06-S11-L01` **Amara:** Keep the interruption in the record.
- `EX-CH06-S11-L02` **Kai:** I was afraid. I still followed the steps.
- `EX-CH06-S11-L03` **Rafi:** And we stayed on the channel.
- `EX-CH06-S11-L04` **Ferreira:** That is something you can repeat.

**Required player actions**

1. Record egress with correct timestamp.
2. Reconcile recovery reserve.
3. Save the fault-and-recovery causal debrief.

**Decision study and planned feedback**

What should Kai highlight in the report?
- **The protected design:** The stable services demonstrate its purpose.
- **The checkback sequence:** The crew's response remains reproducible.

**Convergence:**Egress recorded, reserve reconciled, interruption and recovery both documented..

**Learning loop**

- **Concept:** Resilience and honest reporting
- **Predict:** Must a successful system never experience a fault?
- **Observe:** Compare service continuity and recovery evidence.
- **Explain:** Resilience includes detecting and recovering from bounded failure.
- **Transfer:** Report interruptions and the reasons recovery worked.

**Mandatory exit condition:**Egress recorded, reserve reconciled, interruption and recovery both documented.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_06.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH06-S12 — Keep Watching
**Target:**7 minutes. **Location:**Aurora monitoring calendar and garden. **POV:**Rafi. **Story time:**13 January–14 February, explicit dated transition. **Legacy provenance:**`SC-0606`.

The next morning's solar image contains an active region worth monitoring. Rafi pins it to the calendar, then stops the player from drawing a line straight to a February storm date. A region is a reason to watch. It is not a precise month-ahead prediction of the next chapter.

The player builds a monitoring handover that names instruments, observations and who checks the next report. Cotton has leaves now. The garden's current generation has its own dates, and the preserved petal remains in the archive rather than reappearing on a living stem. Amara reconciles the protected founder reserve and the eleven unplanted vault specimens before the calendar advances.

A required montage moves through dated care, maintenance and ordinary meals. It shows what keeps an expedition alive between spectacular events without asking the player to wait through real weeks. Each short interaction checks a changed observation or hands over responsibility. February's alert arrives as new information after that work, not as proof of an impossible January forecast. The player opens the shared warning, with all five occupants present.

**Exact dialogue**

- `EX-CH06-S12-L01` **Rafi:** That region needs watching.
- `EX-CH06-S12-L02` **Amara:** Watching is not an exact storm forecast.
- `EX-CH06-S12-L03` **Mei:** Cotton care stays on the calendar.
- `EX-CH06-S12-L04` **Kai:** So does the next handover.

**Required player actions**

1. Pin a bounded monitoring plan.
2. Check dated cotton and generation care.
3. Confirm reserves before the February transition.

**Decision study and planned feedback**

How should the watch be handed over?
- **By instrument:** Each source gets a named check.
- **By crew responsibility:** Each watcher states the observation they own.

**Convergence:**Monitoring ownership and care ledger checked; new February warning explicitly dated..

**Learning loop**

- **Concept:** Forecast limits and sustained care
- **Predict:** What does an active-region image justify?
- **Observe:** Compare new observations across dated records.
- **Explain:** Monitoring supports readiness without proving a precise future event.
- **Transfer:** Update a plan when fresh evidence arrives.

**Mandatory exit condition:**Monitoring ownership and care ledger checked; new February warning explicitly dated.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_06.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
