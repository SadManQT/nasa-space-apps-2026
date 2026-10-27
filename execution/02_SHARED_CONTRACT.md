# Shared execution contract — every task must use this

Prepared against `ca01433` on 27 October 2026. Re-read current repository instructions at execution time. User directions override older project text. Existing documented approval remains valid for its authorized scope.

## Authority and scope

1. `AGENTS.md`, `PRODUCTION_HANDBOOK.md` locked decisions and newest `HANDOFF.md` entries govern production. Historical sections inside these files can be superseded by their newer dated entries.
2. Story: `full-game-story/STORY_FULL.md` and `story-data.json`: 8 chapters, 32 required missions, 96 scenes, 385 authored dialogue lines. IDs: `EX-M0101` through `EX-M0804`, `EX-CH01-S01` through `EX-CH08-S12`. The older 16-mission/48-scene runtime outline is superseded.
3. Mathematics: `game-design/08_PUZZLE_DESIGNS.md`, including the P-02 numeric appendix and P-13/P-14 upgrade/occupancy appendix. Story expansion changes pacing, not the numbers.
4. Places: `game-design/09_WORLD_AND_LEVEL_DESIGN.md`, LOC-01..12; use current production names/aliases when assembling assets.
5. Presentation: approved anime/cel direction and current v 8-built characters; current handbook overrides stale realistic, MetaHuman, old rig, Bangla UI, plant-face and Compatibility-only descriptions.
6. Target main route: 720 active minutes, range 600–840 over the same required content. Eight chapter target minutes: 75/75/85/90/85/85/105/120. No side-mission, collection, mandatory-loss or complete-replay padding.

## Locked production decisions

- Godot 4.7.2, Forward+ project; metre scale, Godot Y-up, consistent ground pivots. Recheck actual tool availability without silently migrating the engine.
- Adults: Kai 19, Mei 19, Amara 20, Rafi 20; the audience is junior learners. Approved current heights: Kai 1.74m, Amara1.72m, Mei 1.60m, Rafi1.84m, Ferreira 1.68m.
- Navy indoor coveralls are already installed. Later EVA outfits and individually fitted role helmets are separate variants, not a reason to regenerate the current base cast.
- Current characters have 44 clips each, 65 bones except Mei 68 including hair. Preserve clip/face/runtime contracts; actual current GLB inspection outranks stale registry specs.
- Bangladesh flag: LEFT sleeve. Round mustard-flower/crescent Aurora patch: right shoulder and chest. No NASA marks or implied endorsement.
- **All in-game visible text is English.** The packet displays `ALO` and `N.`. Bangla etymology or source-document prose is not a runtime UI label.
- Plants have **no eyes, faces or mouths**. Express growth/stress through plant posture, light and biological stages.
- Ferreira has the current approved dark-brown pixie cut with grey streaks. Do not restore an older jet-black/grey-hair prescription.

## Presence, knowledge and continuity

- Ferreira is on Earth until her scheduled arrival on 12 December 2046; Rao and Noor remain Earth-based. CH04: Rafi/Kai field, Mei/Amara base. CH08: Ferreira/Kai/Rafi rover, Mei/Amara base.
- Before CH05, the recovered gardener is `N.`. A voice resemblance is a clue. CH05 reveals Noor's identity, survival and Academy-founder connection with consent. Her first live voice is EX-CH08-S10; earlier material is explicitly stored recording or text.
- Safety instructions are available independently of the personal mystery. Acquired journal pages, subtitles, accessibility labels, UI portraits and objective text obey the same knowledge gate.
- Two seeds are planted 11 April 2046. Alo blooms 27 April, Tara 30 April. Three reciprocal pollen runs span seven dated care days. Mature pods, dry-down and harvest occur later; harvest 21 May gives **42=12 planting+30 protected founder reserve**.
- Original Alo completes its life and never returns alive. Later garden plants are descendants; Tara remains credited in the lineage.
- Old 2034 annex: young unflowered seedlings with curled leaves, no flower buds, blooms, pollination or seed production. Do not reuse the older cinematic's unopened-bud language.
- Vault 12 distinct specimens; cotton planted 15 December leaves 11 stored. Album entries are not physical seeds. CH04 visible descendant sample is 12 plants: 7 purple/5 green.
- December relief brings the compatible relay controller. February-to-April preparation tests/prepares it and the repeater infrastructure; it does not fabricate a second unexplained controller.
- CH07 uses five occupants, six 7.2-hour steps and a labelled 2012 counter factual replay. The original 2017 replay belongs to CH01.
- External Earth uplink remains broken after CH07 until the final bypass. Local radios and stored guidance continue; no new live Earth reply appears through the outage.
- Three repeaters form four surface hops: Aurora→R1→R2→R3→summit. A local path and an Earth path must pass separately. `ALO42` is a known-content echo/test phrase, not a computed checksum.
- Finale: 120 km each way; 24h outward+3h repair+24h return=51h within 72h provisions. Depart 8 Apr 2047 00: 00; summit 9 Apr 00: 00; return 9 Apr 03: 00; home 10 Apr 03: 00; dawn 10 Apr 06: 00. Base occupancy 2 for 33 dark hours, then 5 for 3.
- The final garden is established before sunrise. Credits close all central questions; the closed MARS drawer is only a short post-credit image, not another required mission.

## Simulation and interaction boundaries

- One authoritative state and one mathematical transition function. Preview computes the same result as commit without persistence or world mutation.
- Required events are idempotent. A dialogue answer, animation end, cinematic skip, reopened UI or duplicated input cannot silently commit a shift, spend resources twice or award another seed.
- Reading, pause, planning and ordinary exploration do not secretly consume mission oxygen or advance dates. Explicit dated commits advance scenario time.
- Core P-02 entry: E14/20, A6/10, H6/10, W0/6, K0/2, C8/10, R12 crew-days, Z0. Seven 7.2-hour shifts; 1–2 daylight(+8 each),3–7 dark. Drill 2, Earth-set 4, alarm 5. Exact costs/order come from the numeric appendix.
- PUMP/STACK/WAIT are exclusive shift-5 actions. Complete/partial actions, exposure-before-drain order, capacity caps, crop/ration changes and exactly-zero versus negative energy must match the source. Do not approximate them in UI code.
- Bloom/Golden can advance this expedition; Alo-lost/Mission-stopped close meaningfully and restore a checkpoint before advancement. Assistance preserves outcome/reward eligibility.
- Upgrade modifiers apply once and retain their acquisition order. Test all 128 combinations as a release requirement; do not claim they were balanced before those tests execute.

## Science and player access

- Lunar sky is black; no fog, wind, atmosphere glow or billowing dust. Grounded lunar gravity, hard directional shadows, ballistic kicked r egoli th. No airborne exterior sound.
- Plants remain in press uri sed enclosures. Pollination carriers, samples, doors, suit/EVA and repair boundaries preserve the pressure logic.
- Radiation is instrument-led, not visible projectiles. Game exposure is not a measured dose. Historical replay dates remain distinct from fictional 2046–2047 dates.
- Illumination, horizon visibility and the scenario 36-hour night are site-dependent. Jan 12 2047 eclipse date does not prove Aurora's actual view. Use observed/computed/simulated labels and a qualified camera/illustrative fallback until the real pipeline is validated.
- Every essential clue has readable text/icon context; no colour-only, audio-only, pixel-perfect or compulsory rapid-input gate. Pause, captions, input remap, large text, reduced motion and timer alternatives remain equal routes.

## Tools, permissions and data handling

- Read current account/tool state only when the task needs a generation. Historical balances, model versions, endpoint names and Mac scratch paths are not live facts.
- Existing paid plans/credits may be used only within the authorized work flow; no new paid subscription/tool. Never print tokens or keys, store them in prompts, commit them, or include them in reports.
- `AGENTS.md` explicitly requires approval of 2 D sheets before spending Tripo credits on new characters/hero props. Check for an existing approval of the exact design; if absent, prepare the concrete sheet and ask only for that remaining approval. Continue independent ready work.
- Tripo account switching: `tripo config use`, no `TRIPO_API_KEY`; API pool uses `TRIPO_OPENAPI_KEY`; private visibility; rig exports include animation. Preserve the actual existing models until replacements pass comparison and are approved.
- Every AI generation has provenance in `production/AI_PROMPT_LOG.md`. Keep licenses, inputs, prompts, result IDs and human changes without secrets.
- Raw/intermediate files belong in the established ignored staging area; final runtime assets follow the existing asset layout and Git LFS policy.
- User has not authorized a commit/push merely by assigning one of these prompts. Commit only when explicitly asked, as `sadmanqt`, without AI co-author lines. Never push unrelated local history.
- Cleanup only exact owned temporary files after validation. Verify absolute targets before recursive operations; preserve user work, approved variants and evidence.

## Recheck after every task

Update the affected manifests, verification evidence and handbook/handoff status in the same change as the implementation. Report what was executed and what remains untested. If source documents disagree, record the conflict and apply the authority order above; never silently blend two versions.
