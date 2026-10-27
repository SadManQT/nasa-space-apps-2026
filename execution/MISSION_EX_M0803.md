# EX-M0803 — Both Ends of the Light

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Replace the controller and prove both communication legs and exact data. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0802`; SYS02..08; chapter puzzles P-15, P-16; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 30 active minutes. Predecessor:`EX-M0802`. Successor:`EX-M0804`. Chapter puzzle families: P-15, P-16; reuse their single shared implementations and map the actual relevant stages.

### EX-CH08-S07 — The Spare Has a History
**Target:**10 minutes. **Location:**Mala pert relay service bay. **POV:**Kai. **Story time:**9 April 00: 00–00: 45, repair window. **Legacy provenance:**`SC-0804`.

The controller crate opens beside the service housing its diagram promised. Kai recognises the note he wrote in December. The player checks the actual connectors and serial once more because preparation does not excuse verification at the point of use. Ferreira braces the service door while Rafi controls the tether.

The first command isolates power. The second verifies zero before the damaged controller is removed. A tempting reset control remains visible but cannot certify a safe replacement. The player follows the sequence through removal, compatible insertion and closed housing. Only then is power reconnected. Each step has a direct physical change rather than another decorative inspection.

Nothing sparks theatrically in the vacuum. The score stays quiet enough for the local checkbacks to be understood. When the controller powers, the antenna panel wakes with two unverified channels. Kai does not announce success yet. Months of care, the delivered spare and the restored road have made this moment possible, but the device still has to connect Aurora with Earth. The player has repaired a component and created the conditions for testing a system.

**Exact dialogue**

- `EX-CH08-S07-L01` **Ferreira:** Power isolated?
- `EX-CH08-S07-L02` **Kai:** Isolated. Zero verified.
- `EX-CH08-S07-L03` **Rafi:** Tether set. Housing clear.
- `EX-CH08-S07-L04` **Kai:** Closed before reconnecting.

**Required player actions**

1. Verify actual compatible spare.
2. Isolate, test zero and replace.
3. Close housing before reconnecting power.

**Decision study and planned feedback**

Which action is safe before removal?
- **Reset the damaged controller while live:** The sequence blocks removal until isolation and zero are verified.
- **Isolate and verify zero:** The supported replacement procedure can proceed.

**Convergence:**Compatible controller installed, housing closed, power safely restored..

**Learning loop**

- **Concept:** Safe replacement sequence
- **Predict:** Does having the correct spare remove electrical hazards?
- **Observe:** Compare component compatibility and isolation state.
- **Explain:** Correct parts and correct procedure are separate requirements.
- **Transfer:** Verify safe state at the point of work.

**Mandatory exit condition:**Compatible controller installed, housing closed, power safely restored.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH08-S08 — A Lighthouse Needs Both Shores
**Target:**10 minutes. **Location:**Mala pert local antenna and Earth dish controls. **POV:**Kai. **Story time:**9 April 00: 45–01: 45. **Legacy provenance:**`SC-0804`.

Two signal panels appear, and only one points toward Earth. The player first tunes the local channel toward the restored road chain. An image of Earth above a ridge cannot prove that Aurora is audible below the terrain. The local test must pass on its own evidence.

With the first leg checked, the player adjusts the Earth dish. The displayed bearings are labelled scenario values until surveyed geometry is verified in production. Strength alone is insufficient when the path remains obstructed; the panel pairs signal with an explicit blockage indication. An assisted preset and tap-confirm offer the same engineering result as the dials, without taking away story access or rewards.

The upcoming Aurora Earth-set handover appears as a planned window, not a reason to force fast motor input. Reading and accessibility settings pause the pressure. Ferreira reads the two-channel checklist while Rafi confirms the local path remains stable. Kai touches each verified label once. The relay's useful achievement is not pointing at a distant object. It is maintaining a route that can carry a message between people.

**Exact dialogue**

- `EX-CH08-S08-L01` **Kai:** Aurora first.
- `EX-CH08-S08-L02` **Rafi:** Road chain stable.
- `EX-CH08-S08-L03` **Ferreira:** Now the Earth leg. Check obstruction too.
- `EX-CH08-S08-L04` **Kai:** Both shores, not just the bright one.

**Required player actions**

1. Lock and verify the local repeater leg.
2. Tune the Earth leg using labelled scenario bearings.
3. Check obstruction and stability on both paths.

**Decision study and planned feedback**

Which result makes the relay useful to Aurora?
- **Earth signal strong, local leg unverified:** Aurora still has no checked path to the summit.
- **Local and Earth legs independently passed:** The intended two-leg route now exists.

**Convergence:**Local and Earth legs independently locked and stable before handover..

**Learning loop**

- **Concept:** End-to-end network reasoning
- **Predict:** Can a relay work with only its distant leg?
- **Observe:** Compare two independent path results.
- **Explain:** A network service needs every necessary link.
- **Transfer:** Trace a message from origin to destination.

**Mandatory exit condition:**Local and Earth legs independently locked and stable before handover.
**Evidence boundary:**Computed-pending. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH08-S09 — Forty-Two Comes Back Correctly
**Target:**10 minutes. **Location:**Relay data check and Aurora acknowledgement panel. **POV:**Rafi. **Story time:**9 April 01: 45–02: 15. **Legacy provenance:**`SC-0804`.

The player sends ALO42 through the checked local path and waits for an exact response. The string carries no new seed quantity; it is a known-content test phrase chosen for the current session. A nearly matching reply is available in the diagnostic preview, and the player must distinguish resemblance from equality.

A signal meter can be strong while content arrives incorrectly. Rafi checks that the returned characters match and that the acknowledgement belongs to this test rather than an old saved packet. The player then confirms the Earth channel separately. Two independent voice checks remain visible as required next steps, so a successful data echo does not silently stand in for a conversation.

At Aurora, Mei sees the verified route appear on the board. Her own garden forecast still needs its scheduled care; the radio did not refill the battery or reverse time. Amara sends a current telemetry packet, with the station's clock and five-person return plan attached. The network is now useful because the player can show where the information went and what came back. Only after that evidence does the transmit button invite a human voice.

**Exact dialogue**

- `EX-CH08-S09-L01` **Rafi:** Strong is not the same as correct.
- `EX-CH08-S09-L02` **Kai:** ALO42 sent. Exact match returned.
- `EX-CH08-S09-L03` **Amara (Aurora local radio):** Current telemetry follows.
- `EX-CH08-S09-L04` **Ferreira:** Now verify the voices at both ends.

**Required player actions**

1. Send and exactly compare ALO42.
2. Reject stale or mismatched acknowledgements.
3. Prepare separate Aurora and Earth voice checks.

**Decision study and planned feedback**

Which response passes the content check?
- **A similar-looking or older reply:** It fails the exact-current-match requirement.
- **The exact current ALO42 response:** The test demonstrates present content integrity.

**Convergence:**Exact current test phrase and both path records pass; voice verification remains explicit..

**Learning loop**

- **Concept:** Signal versus data integrity
- **Predict:** Does a strong connection guarantee correct information?
- **Observe:** Compare exact content and current test identifiers.
- **Explain:** Connectivity and correct delivery need separate verification.
- **Transfer:** Check both transport and meaning when information matters.

**Mandatory exit condition:**Exact current test phrase and both path records pass; voice verification remains explicit.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
