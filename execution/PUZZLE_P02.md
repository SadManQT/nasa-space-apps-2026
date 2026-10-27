# P-02 — Seven Shifts, One Night

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Scientific puzzle.**



## Assignment

Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [game-design/08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md)
- [docs/GAMEPLAY_DESIGN_FINAL.md](../docs/GAMEPLAY_DESIGN_FINAL.md)
- [full-game-story/story-data.json](../full-game-story/story-data.json)
- [game-design/10_GAMEPLAY_SYSTEMS.md](../game-design/10_GAMEPLAY_SYSTEMS.md)


## Ownership and dependencies

Own one puzzle model/controller and focused tests. Reuse SYS04 simulation for shared arithmetic, SYS05 transactions, SYS06 dialogue and the appropriate UI panel; do not fork them.

SYS02 content, SYS03 state, SYS04 simulation, SYS05 interactions, SYS07 checkpoints, appropriate room/prop/UI tasks and its owning expansion missions.


## Detailed work sequence

1. Translate source initial state, legal inputs, subchecks and completion predicate into typed data and explicit testable transitions.
2. Agree which shared state/profile fields the puzzle reads/writes; proposed root `game/scripts/puzzles/`. Keep presentation separate from the pure rule model.
3. Build observable equipment/diagram/UI feedback for correct, incorrect, partial and blocked actions, including the documented progressive hints.
4. Implement the real action sequence with keyboard/controller/tap alternatives and timer assistance; no motor precision penalty changes story access.
5. Use the same rule function in preview and commit; protect idempotent costs/evidence and current knowledge.
6. Create source witness/boundary tests, including reset/cancel/paused/reloaded/duplicate input cases. When the source gives numbers, assert exact results, not just non-null states.
7. Embed the puzzle at its actual expansion mission gates and verify the actor/location/time/pressure/inventory implications.
8. Document the versioned inputs, accepted result receipt and next consumer; report any source counterexample without quietly changing rules.


## Task-specific source and implementation detail

## P-02 — Seven Shifts, One Night

- **Mission / reason:** [M-0102](../game-design/07_MISSION_DESIGNS/M-0102_Keep_the_Night.md) — Prepare, survive and restore shared water before first light.
- **Location / equipment:** LOC-01; four room consoles, battery jar, air tank, garden manifold, shelter and supply bundles.
- **Initial state:** E14/20, A6/10, Alo H6/10, W0/6, K0/2, crop C8/10, rations R12 crew-days, exposure Z0. Shifts 1–2 daylight (+8 each); 3–7 dark. Each shift is 7.2 h, so darkness totals 36 h.
- **Player instructions and intermediate steps:** Deliver the four role facts at their specified shifts; inspect, discuss, preview, choose physical actions and commit once. Drill at shift 2, Earth-set at shift 4, alarm at shift 5. PUMP, STACK or WAIT is one exclusive alarm choice. Resolve exposure before the shift-6 ordinary drain.
- **Accepted solution:** The all-COZY Bloom witness in the numeric contract ends E2, A1, H1, W0, K0, C3, R3.6, Z2 with no blackout. The Golden witness ends E0, A1, H5, W0, K0, C9, R3.6, Z2 with no blackout. Exactly E0 is not a blackout. Additional PUMP and STACK witnesses are listed there.
- **Incorrect actions and feedback:** A negative energy balance causes the published blackout penalties; it is not an automatic mission stop. A<=0 or unsafe exposure stops operations; H0 gives Alo lost if the crew completes safely. Show the cause and offer the complete last-shift checkpoint. Invalid transfer directions do not create water.
- **Progressive hints H1 / H2 / H3:** Store air while sunlight would overflow. / Prepare shielding before the alarm, then return the water. / Open the worked Bloom plan or Guided plan.
- **Golden hints G1 / G2 (unlock only after a first Bloom):** Golden needs Alo at 5 or more with no blackout, so every drop must reach the garden at exactly the right time. / Open the worked Golden plan.
- **Difficulty, timing and retry:** Main night portion approximately 20 minutes; action pressure optional. Reading and preview pause time. Retry restores pre-shift resources, actions and evidence.
- **Completion trigger:** Complete seven shifts with A>0, Z<=3, all four crew sheltered during exposure, and H>0. Golden requires all three stars (safe exposure, no blackout, living Alo) plus H>=5. Other safe/loss outcomes remain viewable without unlocking Chapter 2.
- **Narrative consequence / flags:** first_bloom_pending; ending/mastery record; first_bloom committed after SC-0106 and its old recording.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-03"></a>

### Final-edition mapping

Use expansion chapter 1 and its four `EX-M` missions. Legacy SC/M identifiers inside the quoted source provide puzzle provenance only. Keep the full 96 scene/32 mission graph.

### Exact P-02 numeric appendix

This contract is reproduced from [the existing 3 D gameplay design, section 6](../docs/GAMEPLAY_DESIGN_FINAL.md#6-chapter-1-numerical-contract). It replaces this folder’s incompatible B/O/G/frost/thirst model and free daytime crate staging. E=energy, A=air, H=Alo health, W=water shielding, K=crate shielding, C=edible-crop condition, R=crew-day rations, Z=game exposure. Changes must update both documents and the mission/test summaries together.


The original energy, air, Alo, light, heat and shelter values are retained. Costs and thresholds are [G], with real-unit context from the science document. A new crop/ration layer reuses the garden's existing circuit and reservoir; it does not add another allocation console or energy currency.

| State/control | Cadet baseline |
|---|---|
| Energy E | Start 14; cap 20; day income 8 in shifts 1–2 |
| Air A | Start 6; cap 10; normal breathing costs 1 per shift |
| Alo health H | Start 6; cap 10; zero is terminal within that attempt |
| Water wall W | Start 0; cap 6; garden usable water = 6-W |
| Crate shielding K | Start 0; cap 2; separate from water; removed before shift 7 |
| Heat | Day automatically warm; night COZY cost 2 / damage 0; COOL cost 1 / Alo damage 1; COLD cost 0 / Alo damage 2 |
| Air production O | 0, 1 or 2 energy, adding the same air amount |
| Garden light L | OFF cost 0 / plant change -1; DIM cost 1 / change 0; FULL cost 2 / change +1 |
| Basics | Cost 1 energy every shift; always scheduled |
| Ordinary transfer | FILL +2 W; HOLD; DRAIN -2 W; one command in shifts other than 5 |
| Thirst | W >= 4 after transfers causes Alo -1 |
| Crop condition C | Start 8; cap 10; shares L and water manifold; light change as above, thirst -1, COLD -1, COOL/COZY 0 |
| Stored food R | Start 12 crew-days; use 1.2 crew-days per 7.2-hour shift for four crew; no harvest during Chapter 1 |
| Exposure Z | Sum of two storm-shift game doses; never presented as sieverts |

**Food production:** the indoor rack contains an already growing edible crop batch. Planting-to-harvest takes its documented crop life cycle, not one shift. Light/cold/water decisions change C and its later yield. The forecast shows the projected next harvest. At a scheduled mature harvest after a story time transition, yield is `round(4*C/10, 1)` crew-days [G], then a newly planted batch starts at C=8. This is a small dietary supplement, not a claim that one rack feeds the whole crew indefinitely. A dead batch yields zero; stored supplies bridge the interval. During chapter-to-chapter time jumps, a labelled station ledger records resupply, consumption, mature harvest and new planting rather than silently resetting food. The educational question is whether saving power now damages later food production.

**Alarm choices, shift 5:**

- **PUMP:** one transfer of up to +2 W; ordinary systems use the chosen settings. A 15-second guided valve task starts only after the player chooses it. Three broad, ordered valve confirmations unlock the full +2. Each accepted confirmation counts once. Family/assisted mode completes the same confirmations without a timer. Incomplete pumping moves only +1; the preview then re calculates.
- **STACK:** a 30-second snap-placement task. Four supply bundles fill outlined bunk slots; complete placement gives K=2, partial placement gives K=1. W does not change. Set heat COOL, O=0 and L=OFF for this shift; show that cost before selection. No detailed water-fluid or falling-crate simulation is required.
- **WAIT:** no minigame or extra shelter; keep the chosen settings. Waiting is a legitimate strategy if preparation is adequate. The shelter warning shows what is known.

PUMP, STACK and WAIT are mutually exclusive. At timer expiry resolve the selected action once, with completed progress. A human can always choose assisted input before starting; motor speed is not the learning outcome.

**Exact shift order:**

1. Save the pre-shift checkpoint; validate settings and one allowed transfer/alarm command. For shift 5, complete/resolve the alarm action before the economic update. For shift 7, remove K.
2. Add daylight income and clamp E to 20 **before** spending; record overflow. Add O and clamp A to 10 **before** breathing.
3. Exposure in shift 5 uses shelter after the alarm; exposure in shift 6 uses shelter at the start of that shift, before its ordinary transfer. Effective shelter S=min(6, W+K). Dose per storm shift: S 0–1 gives 3; 2–3 gives 2; 4–5 gives 1; 6 gives 0.
4. Apply the permitted ordinary W transfer (except shift 5); cap W to 0–6. Transfers conserve total water. Crates do not remove garden water.
5. Subtract basics + heat + O + L from E. Day heat costs 0. If the result is **below 0**, mark a blackout, set E=0, apply A-2, H-2 and C-2 [G]. Exactly E=0 is an empty battery warning, not that shift's blackout; the next unpaid demand can cause one. Oxygen production/plant growth are a deliberately simplified shift model, not second-by-second electrolysis under a failed power bus.
6. Subtract breathing A-1; apply light, cold and thirst to H/C using post-transfer W. Combine changes, then clamp to 0–10. Dead H/C do not resurrect within an attempt. Consume R by elapsed scenario days, with no new crop harvest during these shifts.
7. If A<=0 stop the mission and offer retry. If food would run out, trigger an early resupply/abort requirement instead of depicting immediate starvation; Chapter 1's starting stock covers the night. H=0 means Alo lost, but safe crew operation can continue to the ending.
8. Record before/after values, causes, event source and action success. Render the same state to all consoles, HUD and actors. Evaluate the sunrise result after shift 7.

**Endings and progress:** retain three mastery stars: crew exposure Z<=3; no blackout; Alo alive. Golden Bloom requires all three and H>=5. Bloom requires a completed mission with safe crew and H>0. Alo lost means safe crew completes the night with H=0. Mission stopped covers air failure or a crew exposure safety breach; pre-loaded flight rules initiate the abort while Earth is down. Ferreira's live response appears only in a later Earth-visible epilogue. Retry restores the complete last checkpoint. Food condition gets a visible harvest forecast and garden-care badge; it does not replace these canonical endings. Story progression requires safe completion and a living Alo; mastery stars do not gate the next chapter.

**Balance honesty:** the previous claim that COZY every night necessarily causes a blackout is not retained. Under these base values, a valid all-COZY plan has day O=[2,0], L=[FULL, FULL], night L=OFF, W fills in shifts 3–4, WAIT in 5, drain in 6–7. Final E=2, A=1, H=1, W=0, Z=2; it earns three stars. There is no unpublished guarantee about 923 states or random-win rates. Re-run balance after implementation, food calibration or any parameter change; publish the actual version and results. The lesson is informed trade-offs, not a forced single solution.

## Executed Chapter 1 arithmetic witnesses

Each row is `heat / air production / light / ordinary water transfer`; heat is ignored in daylight. Numeric heat 0/1/2 = COLD/COOL/COZY, light 0/1/2 = OFF/DIM/FULL. At shift 5 the alarm action replaces the ordinary transfer. STACK forces COOL/O0/OFF regardless of previous settings. Exactly E0 counts as no blackout; negative demand causes a blackout.

| Plan | Shift 1 | Shift 2 | Shift 3 | Shift 4 | Shift 5 | Shift 6 | Shift 7 | Result E/A/H/W/K/C/R/Z |
|---|---|---|---|---|---|---|---|---|
| Bloom / WAIT | DAY/2/2/HOLD | DAY/0/2/HOLD | 2/0/0/FILL | 2/0/0/FILL | 2/0/0/WAIT | 2/0/0/DRAIN | 2/0/0/DRAIN | 2 / 1 / 1 / 0 / 0 / 3 / 3.6 / 2 |
| Golden | DAY/2/2/HOLD | DAY/0/2/DRAIN | 1/0/2/DRAIN | 1/0/2/FILL | 1/0/0/STACK | 2/0/0/HOLD | 1/0/2/DRAIN | 0 / 1 / 5 / 0 / 0 / 9 / 3.6 / 2 |
| PUMP | DAY/1/2/DRAIN | DAY/1/2/DRAIN | 1/0/0/HOLD | 1/0/0/FILL | 2/0/1/PUMP | 1/0/2/HOLD | 1/0/2/FILL | 0 / 1 / 1 / 6 / 0 / 7 / 3.6 / 2 |
| STACK | DAY/2/0/FILL | DAY/2/1/DRAIN | 1/0/1/DRAIN | 1/0/2/FILL | 1/0/0/STACK | 2/0/0/HOLD | 2/0/1/DRAIN | 0 / 3 / 1 / 0 / 0 / 6 / 3.6 / 2 |

**Golden Bloom difficulty: decided 24 Oct 2026.** Golden Bloom is a deliberately rare expert goal, as the story says ("Rare: the expert goal"). Under the locked values it is expected to be very narrow, possibly only reachable with Alo ending at exactly H=5. No number changes. Support is added instead: the G1/G2 hints and a worked Golden plan (the witness above) unlock after the player's first Bloom, and Bloom, not Golden, is what unlocks the story. **On 13 Nov:** count every possible plan with the implemented simulation and record how many reach each ending and Golden's final-H range. **Pre-agreed fallback:** if no play tester reaches Golden unaided within three attempts after a Bloom, lower the threshold to H>=4. That only happens after re-running the full P-02 test suite and balance count, and updating this contract, GAMEPLAY_DESIGN_FINAL §6 and the mission/test summaries together.

These worked paths were recalculated for this review, without a game runtime. The PUMP example deliberately leaves W6 after scoring to exercise conservation; a post-night return command empties the wall without changing the scored ending. A player need not execute a drain when no water is borrowed. Full/partial alarm actions follow the source rules; no extra pump, free daylight STACK or second crate rail is awarded.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- Every source completion conjunct is tested and driven by actual validated actions.
- Shared numeric contracts, resource caps/order and dated biological/logistical effects remain unchanged.
- Wrong hypotheses produce explanatory feedback and a local supported retry.
- Assistance and captions preserve the same accepted result and ending eligibility.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
