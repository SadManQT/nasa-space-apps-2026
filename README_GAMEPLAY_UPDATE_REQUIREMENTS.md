# LAST LIGHT ACADEMY — Gameplay Design Update Requirements

**Team:** The Last BrainCell  
**Challenge:** NASA Space Apps Challenge 2026 — Build a Junior Astronaut Mission Trainer  
**Document type:** Proposed implementation/design changes; does **not** supersede numerical puzzle contracts  
**Status:** Planning / review — no playable build or completed testing is asserted here

## 1. Goal and delivery boundary

Deliver a **playable, stable, scientifically transparent Chapter 1 vertical slice** that demonstrates space-outpost training rather than only a cinematic vision. Prioritize a complete decision-to-consequence loop over building the entire eight-chapter campaign.

**Hackathon scope:** Chapter 1 (*Night One*), its two missions, P-02 (*Seven Shifts, One Night*), all four endings, credible onboarding, debrief, and the N./Tara teaser. A sample of Chapter 2 is optional. The eight-chapter campaign, side stories, collection targets and late-game upgrades remain future scope.

**Source of truth:** `docs/GAMEPLAY_DESIGN_FINAL.md`, `game-design/08_PUZZLE_DESIGNS.md`, `game-design/10_GAMEPLAY_SYSTEMS.md`, `game-design/18_TECHNICAL_BLUEPRINT.md`, `game-design/20_TESTING_AND_ACCEPTANCE.md`, and `game-design/21_STORY_CONSISTENCY_REPORT.md`.

## 2. Existing mechanics — lock and preserve

- [ ] Preserve Chapter 1's variables **E/A/H/W/K/C/R/Z**, initial state and shift timetable from the existing P-02 contract; do not reinterpret or rename them without a synchronized approved revision.
- [ ] Preserve the seven-shift schedule, two daylight/five dark shifts, actions, costs, resource update order, threshold effects and exactly the four named outcomes.
- [ ] Preserve the **exclusive alarm action** and distinct **PUMP/STACK** mechanics; no free daylight crate staging.
- [ ] Preserve crew safety priority, resource limits, explicit zero-energy/blackout distinction, and solved reference trajectories.
- [ ] Preserve one-to-four-person local/classroom role-sharing design and solo mode; do not present unimplemented online multiplayer as available.
- [ ] Keep one compact embodied station and hands-on consoles/equipment; no open-world expansion or combat.
- [ ] Preserve the connection between simulated resource decisions and the established Chapter 1 narrative beats.

**Important:** Numbers and worked examples in `game-design/08_PUZZLE_DESIGNS.md` are authoritative **until a documented, tested rebalancing decision** is approved. This README intentionally supplies no replacement resource values.

## 3. Critical requirements — P0

### GAME-01 — Complete an executable Chapter 1 vertical slice
**Deliverable:** A launchable Godot build that permits a player to begin, make decisions across all seven shifts, experience the storm response and reach a deterministic ending plus debrief.

**Acceptance:**
- [ ] Clean build runs on the target submission platform with documented controls.
- [ ] A first-time player can complete the chapter without developer intervention.
- [ ] All four endings are reachable with known test inputs.
- [ ] A run can be restarted and completed twice without state corruption.
- [ ] Judge-facing footage is captured from the actual build and labelled as such.

**Files:** `game-design/18_TECHNICAL_BLUEPRINT.md`; `game-design/19_DEVELOPMENT_ROADMAP.md`; `game-design/20_TESTING_AND_ACCEPTANCE.md`.

### GAME-02 — Deterministic simulation and automated contract tests
**Deliverable:** A pure or testable resource-update function with traceable before/after state per shift.

**Acceptance:**
- [ ] Test exact resource values for each shift using existing P-02 witnesses (Golden, Bloom, PUMP, STACK).
- [ ] Verify ordering of hazard/exposure, drain, recharge and outcome checks matches the locked specification.
- [ ] Validate negative/zero values, forbidden actions, shift-transition input, retry and checkpoint behavior.
- [ ] Resource changes shown by UI match actual simulation state (no disconnected cosmetic bars).
- [ ] Automated regression checks run after gameplay or balance changes.

**Files:** `game-design/08_PUZZLE_DESIGNS.md`; `game-design/10_GAMEPLAY_SYSTEMS.md`; `game-design/20_TESTING_AND_ACCEPTANCE.md`.

### GAME-03 — Make NASA data visibly affect a mission decision
**Deliverable:** At least one full pipeline: **source → retrieval → metadata → processing → validated game input → player decision → visible consequence**.

**Suggested first pipeline:** source-documented Sun-position/illumination inputs for the fictional south-polar site that influence available solar power. Use LROC/LOLA/Horizons only where their actual processed products support the depicted quantity. A training fallback must be explicitly labelled if precise local geometry has not been validated.

**Acceptance:**
- [ ] Display source name, exact data product/URL, collection/query date, lunar site/time, units, processing method and limitations.
- [ ] One adjustable/data-dependent value demonstrably changes the mission planning or resource forecast.
- [ ] No simulated/local values are falsely labelled “NASA measured.”
- [ ] Game works offline using a licensed/cacheable snapshot with provenance, without claiming live data.
- [ ] Data ingestion has explicit error handling, license/attribution and reproducibility steps.

**Files:** `docs/SCIENCE_AND_DATA.md`; `game-design/16_SCIENTIFIC_ACCURACY.md`; `game-design/18_TECHNICAL_BLUEPRINT.md`.

### GAME-04 — Clear core loop and early onboarding
**Loop:** **Observe → Discuss/interpret → Choose → Execute → See impact → Debrief/retry**.

**Acceptance:**
- [ ] The player makes a meaningful interactive decision early, before prolonged exposition.
- [ ] Only the most immediately relevant resource indicators are emphasized first; other indicators are progressively explained without changing the underlying numerical model.
- [ ] The HUD clearly communicates each action's costs, predicted consequences, and irreversible commit point.
- [ ] Simple onboarding is skippable/replayable without changing the simulation outcome.
- [ ] A novice can explain the immediate objective after the tutorial (measured in playtesting).

**Files:** `game-design/13_UI_UX_DESIGN.md`; `game-design/10_GAMEPLAY_SYSTEMS.md`; Chapter 1 scene scripts.

### GAME-05 — Four roles must make cooperation meaningful
**Acceptance:**
- [ ] Kai, Amara, Mei and Rafi each possess relevant information or a distinct action responsibility.
- [ ] At least one mission decision improves through combining multiple roles' evidence.
- [ ] For solo players, role switching reveals the same necessary information without hidden deadlocks.
- [ ] Local/classroom sharing can be demonstrated; unbuilt network co-op remains marked as future work.
- [ ] Debrief explains at least one case where discussion affected the plan.

**Files:** `game-design/10_GAMEPLAY_SYSTEMS.md`; `game-design/13_UI_UX_DESIGN.md`; `game-design/20_TESTING_AND_ACCEPTANCE.md`.

### GAME-06 — Science/evidence panel and honest simulation labels
**Three required categories:** **Historical observation**, **computed reconstruction**, **educational simulation/fiction**.

**Acceptance:**
- [ ] Distinct labels appear beside scientifically significant mission displays.
- [ ] Users can inspect underlying source citation or explanation.
- [ ] 2017 storm replay and later 2012 counterfactual are explicitly tagged.
- [ ] Exact dates, local horizon, Earth visibility, shielding, dose and storm response do not receive unsupported precision.
- [ ] Any simplified model identifies units, assumptions and the limits of its interpretation.

**Files:** `game-design/16_SCIENTIFIC_ACCURACY.md`; `docs/SCIENCE_AND_DATA.md`; `game-design/13_UI_UX_DESIGN.md`.

### GAME-07 — Outcome-driven educational debrief
**Acceptance:**
- [ ] Every ending states: crew safety, station status, Alo's outcome and the most influential decision(s).
- [ ] Explain one relevant engineering trade-off with clear cause and effect.
- [ ] Offer a retry or alternative strategy comparison **using the game's real update rules**.
- [ ] Do not prescribe unsafe crew-sacrificing strategies to optimize a flower score.
- [ ] Provide a short optional comprehension check (not just an achievement badge).

**Files:** `game-design/08_PUZZLE_DESIGNS.md`; `game-design/13_UI_UX_DESIGN.md`; Chapter 1 endings.

### GAME-08 — Integration, accessibility and reliability
**Acceptance:**
- [ ] Text/subtitles, keyboard/mouse navigation, visible focus, non-color-only status indicators and adjustable/pausable timing are tested as appropriate to the target devices.
- [ ] Checkpoint/restart and scene transitions are validated against mission and dialogue gates.
- [ ] All necessary offline/cached content is included or clearly identified.
- [ ] On-screen control hints, build instructions, version and known limitations are documented.
- [ ] No reported pass is claimed unless the exact build/version and evidence are recorded.

**Files:** `game-design/13_UI_UX_DESIGN.md`; `game-design/20_TESTING_AND_ACCEPTANCE.md`; `game-design/22_FINAL_PRODUCTION_CHECKLIST.md`.

## 4. High-value requirements — P1

### GAME-09 — Quantify learning and usability
- [ ] Pilot-test the actual build with several learners in or near the intended age band, subject to appropriate consent/safeguarding.
- [ ] Ask consistent short pre/post questions about power allocation, shelter response and interpreting evidence.
- [ ] Track tutorial completion, confusion points, task completion and voluntary feedback.
- [ ] Report actual sample size, age range where appropriate, method and results; do not claim statistically established gains from tiny samples.

### GAME-10 — Compare strategies and show uncertainty
- [ ] Offer a side-by-side replay comparison with alternative **safe** actions and computed outcomes.
- [ ] Indicate forecast uncertainty where uncertainty actually exists; do not add fake random numbers to imply NASA precision.
- [ ] Ensure comparison never contradicts the locked P-02 arithmetic.

### GAME-11 — Teacher / classroom export
- [ ] Optional lightweight end-of-mission summary: initial state, choices, final outcome, learning points and data citations.
- [ ] Export/print functionality only if it does not jeopardize the stable playable slice; otherwise provide a screen-based summary.

### GAME-12 — Efficient 3D scope and performance
- [ ] Prioritize readable consoles, feedback animation, audio cues and a small coherent station over decorative map size.
- [ ] Validate startup, frame stability and input latency on the team's stated minimum test device.
- [ ] Clearly differentiate concept art/cinematics from captured gameplay in presentation.

## 5. Deferred — P2 / post-hackathon

- Full playable Chapters 2–8 and all sixteen missions.
- Advanced upgrades, collection goals, Station Days, comprehensive replay/mastery, and long-form side stories.
- Extended rover/relay exploration, expanded cinematic pipeline and network multiplayer.
- More sophisticated physical radiation and plant-growth models **only after calibration and science review**.

These remain part of the approved long-term design and should not be deleted merely to shorten the hackathon scope.

## 6. Suggested implementation sequence

| Order | Team deliverable | Exit criterion |
|---|---|---|
| 1 | Canon/state contract freeze | P-02 values, actions, outcomes and update order documented as single authoritative spec |
| 2 | Pure game simulation | All reference trajectories pass tests |
| 3 | Minimal playable UI + scene | Full run to all endings without narration polish |
| 4 | One NASA data pathway | Reproducible provenance + demonstrated gameplay effect |
| 5 | Role information + tutorial | All four role functions observable; solo path works |
| 6 | Story integration + debrief | Chapter 1 has coherent dialogue, outcomes and learning explanations |
| 7 | QA, accessibility, learner tests | Issues triaged; critical blockers fixed; evidence recorded |
| 8 | Judge build + README/demo | Launch link/build guide, 1–3-minute real-gameplay demonstration, known limits |

## 7. Evidence and submission checklist

- [ ] Git commit/tag matching the actual playable release.
- [ ] Reproducible installation/build instructions and tested platform.
- [ ] Short **actual gameplay** video clearly showing choice → consequence.
- [ ] Link to at least one NASA dataset and documented use in the simulation.
- [ ] Science caveats/reconstruction assumptions visible in the game and README.
- [ ] Screenshots of role interactions and each ending.
- [ ] Regression-test output, key known issues and target-device test record.
- [ ] Learner/user testing summary if completed (otherwise explicitly **not tested**).
- [ ] Scope note: Chapter 1 delivered; other chapters future roadmap.
- [ ] Organizer rules for eligible development window, asset licensing and required submission fields checked against current official instructions.

## 8. Issue tracker template

**Rule constraint:** the global FAQ says teams may not begin working on the challenge before the hackathon ([competition rules](docs/competition-rules.md)). GAME-01/02/03 are implementation work, so on 24 Oct 2026 they were written as ready-to-build specs only, and building starts 13 Nov. "Spec ready" and "Designed" mean documents only: no build, test run or playtest exists.

| ID | Priority | Owner | Status | Evidence (commit/test/demo) |
|---|---|---|---|---|
| GAME-01 | P0 | TBD | Spec ready, build 13 Nov | [Build plan](game-design/18_TECHNICAL_BLUEPRINT.md#hackathon-build-plan-from-13-november-game-01020308) steps 2 and 6; six reference plans as manual ending inputs |
| GAME-02 | P0 | TBD | Spec ready, build 13 Nov | [P-02 contract test suite](game-design/20_TESTING_AND_ACCEPTANCE.md#p-02-contract-test-suite-game-02): reference plans, hand-traced shift trace, ordering/boundary cases |
| GAME-03 | P0 | TBD | Design approved 24 Oct, build 13 Nov | DONKI + CRaTER severity ratio → debrief "same plan, another real storm" compare; canonical night unchanged; must appear in demo footage; fallback stated (build plan step 3) |
| GAME-07 note | P0 | TBD | Decided 24 Oct | Golden Bloom stays a rare expert goal with no number changes; Golden hints unlock after a first Bloom; measured on 13 Nov with a pre-agreed H>=4 fallback ([P-02](game-design/08_PUZZLE_DESIGNS.md#executed-chapter-1-arithmetic-witnesses)) |
| GAME-04 | P0 | TBD | Designed | [Onboarding and HUD disclosure](game-design/13_UI_UX_DESIGN.md#chapter-1-onboarding-and-hud-disclosure-game-04); first decision in SC-0101 |
| GAME-05 | P0 | TBD | Designed | [Combined-evidence decision](game-design/10_GAMEPLAY_SYSTEMS.md#role-facts-and-communication-debrief) + shift-3 Preview A/B |
| GAME-06 | P0 | TBD | Designed | [Evidence chips](game-design/13_UI_UX_DESIGN.md#evidence-chips-game-06) and [three labels](game-design/16_SCIENTIFIC_ACCURACY.md#three-evidence-labels-story-04-game-06) |
| GAME-07 | P0 | TBD | Designed | [Chapter 1 debrief](game-design/13_UI_UX_DESIGN.md#chapter-1-debrief-game-07): five panels, safe-only alternatives, optional check |
| GAME-08 | P0 | TBD | Spec ready, build 13 Nov | Build plan step 5; release record in the test suite |

**Definition of done:** A judge can run Chapter 1, make a data-informed choice, observe consequential system behavior, finish a valid ending and understand the science from a source-labelled debrief. Design documents and passing document-consistency checks **do not** count as completed implementation or playtesting.

**Source basis:** User-supplied `STORY_FINAL(1).zip` and `game-design(1).zip`. All items in this file are proposed reviewer recommendations until accepted and implemented by the team.
