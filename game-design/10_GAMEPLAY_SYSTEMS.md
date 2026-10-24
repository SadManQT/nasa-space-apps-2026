# Core gameplay systems — specifications only

The complete adventure uses these 12 systems. No gameplay implementation, engine project or data importer is included. All numeric science play is a simplified game model.

## SYS-01 — Embodied exploration and role switching

- **Purpose:** Move through a familiar home and perform specialist work as a named cadet.
- **Controls:** WASD/left stick move; mouse/right stick look; E/south button interact; 1–4 or role wheel switch; Shift optional walk/run toggle.
- **Rules:** Walk2 m/s indoors, 3 m/s exterior; no jump requirement or platforming. Switch only among co-located cadets; transfer context to a safe adjacent anchor with displayed name. Mission-owned tools equip owner after confirmation.
- **States:** FREE,INTERACTING,ROLE_TRANSITION,TRAVEL_LOCK,HAZARD_LOCK.
- **Feedback:** Active name+role, footsteps appropriate to surface; valid interaction within 2 m, line of sight, aim cone 30°.
- **Dependencies:** SYS-02 dialogue, SYS-03 missions, SYS-05 equipment, location graph.
- **Edge cases:** Switch while seated/holding loose specimen waits until safe release; blocked NPC can snap to an authored off-camera anchor after 5 s; no resource consumption from wandering.
- **Acceptance criteria:** Reach every mission prop without jumps; cannot switch a rover occupant into Aurora; controller-only route reaches every required action.

## SYS-02 — Dialogue and companion interaction

- **Purpose:** Deliver companionship and essential facts without exposition walls.
- **Controls:** E/south starts; up/down or stick chooses; confirm advances; Back returns; optional auto-advance; hold Skip opens transcript confirmation.
- **Rules:** Only one speaker audible; safety instructions pause other speech. Facts gate on scene stage and knowledge flags. Main choices affect expression, not campaign solvability.
- **States:** IDLE,QUEUED,PLAYING,CHOICE,INTERRUPTED,TRANSCRIPT,CLOSED.
- **Feedback:** Speaker name, portrait if known, caption, optional subtitle hold and backlog. Unknown NOO uses N. (recording) until SC-0505 sets noor_identity_revealed. The archival FER engineer voice in CH02 uses “Engineer (recording)” until CH05, although current remote Commander Ferreira remains correctly named.
- **Dependencies:** Scene scripts, dialogue master, SYS-03, SYS-08, SYS-12.
- **Edge cases:** Skip records delivered facts but does not grant puzzle outcomes; save retains current sentence and branch; archived voice never implies a live reply.
- **Acceptance criteria:** Every essential fact available in text; no simultaneous lines; no pre-CH05 Noor nameplate or portrait; interrupted safety line resumes.

## SYS-03 — Mission and objective tracking

- **Purpose:** Keep the player oriented while allowing observation before commitment.
- **Controls:** Tab/north opens mission table; track/untrack from journal; confirm starts a ready mission.
- **Rules:** One mandatory mission ACTIVE at a time; ordered scene gates; objectives show action+place, never production IDs in normal play. Side observations do not unlock later missions.
- **States:** LOCKED,AVAILABLE,ACTIVE,OBJECTIVE_1_DONE,OBJECTIVE_2_DONE,READY_TO_COMPLETE,COMPLETE,RETRY_REVIEW.
- **Feedback:** Compact current objective, waypoint on request, completion recap and exact next destination.
- **Dependencies:** 16 mission files, SYS-07 journal, SYS-08 transactional saves.
- **Edge cases:** Re-entered zone cannot duplicate objective events; debug chapter select creates a documented prior-state snapshot only in development; final release Chapter Replay is isolated.
- **Acceptance criteria:** All 16 missions reachable in order; no circular prerequisite; completion and unlock atomic; retries never bypass a mandatory scene.

## SYS-04 — Shared habitat simulation and forecast

- **Purpose:** Make the station one system whose consequences can be understood.
- **Controls:** Interact with labelled console; change a setting by cycle/select; Preview then Commit; Space only commits after summary confirmation.
- **Rules:** Numbers and update order from P-02 and P-13/14 are authoritative. Pause while planning. Preview knows current instrument readings, not hidden future story revelations.
- **States:** OBSERVE,EDIT,PREVIEW,CONFIRM,ADVANCE,RESULT,REVIEW.
- **Feedback:** Jar, oxygen, water allocation, plant stress; forecast deltas with why; safe emergency outcome, no graphic injury.
- **Dependencies:** SYS-03 stage, SYS-09 plants, SYS-08 save, P-02/P-13/P-14.
- **Edge cases:** Caps before consumption as specified; changing plan invalidates prior preview; full battery overflow shown; pump blocked at limits; no duplicate pump from alarm choice.
- **Acceptance criteria:** Every published witness reproduces exact totals; preview and commit equal for known values; pause/save/reload do not advance a shift twice.

## SYS-05 — Equipment and scientific interactions

- **Purpose:** Let the player use a small readable tool set.
- **Controls:** E interact; tool wheel via Q/left shoulder; select source/target/confirm alternative to drag.
- **Rules:** No loot capacity or crafting. Scanner, manual gauge, brush kit, sample carrier, hand light, repair kit and seed case are named tools. Critical items are mission-owned; dropping them returns them to their labelled dock.
- **States:** DOCKED,EQUIPPED,TARGET_SELECTED,IN_USE,SEALED,STOWED.
- **Feedback:** Tool name, valid target label, calibration/seal state, cause-specific error.
- **Dependencies:** Mission stage, asset sockets, SYS-07 acquired evidence.
- **Edge cases:** Wrong tool gives an observation; cannot consume a unique seed on a decorative slot; brushes replace tips infinitely; hand light charge is checklist state, not a survival grind.
- **Acceptance criteria:** Every puzzle has keyboard/controller select-confirm; all essential equipment available at entry; no permanent loss or inventory softlock.

## SYS-06 — Rover expedition and controlled cruise

- **Purpose:** Make distance and return planning felt without hours of repetitive driving.
- **Controls:** W/S or triggers accelerate/brake; A/D or stick steer; E stop/interact; Cruise at surveyed markers; optional guided mode.
- **Rules:** Maximum displayed survey speed 8 km/h; authored travel averages include rest. P-07/P-15 reserve contracts authoritative. Road edges warn then brake; no racing or vehicle destruction.
- **States:** PARKED,CHECKLIST,DRIVING,MARKER_STOP,EVA_REPAIR,CRUISE,ARRIVED,TURNBACK.
- **Feedback:** Distance remaining, route marker, supply duration, return reserve, local link state; camera horizon lock.
- **Dependencies:** Location graph, P-07/P-15, SYS-01 role roster, SYS-08.
- **Edge cases:** Cannot exit moving or unbraked rover; cruise unavailable with required stop incomplete; motion-sensitive players use station-camera guided traversal with identical decisions; no storm EVA.
- **Acceptance criteria:** Trips have explicit 24 h final outbound/return cards; all repeaters tested; player can turn back to last safe marker; no occupant/location contradiction.

## SYS-07 — Discoveries and expedition journal

- **Purpose:** Make observations, mystery and emotional memory navigable.
- **Controls:** J/view button opens tabs; select record; pin clue; replay transcript; optional Read aloud.
- **Rules:** Journal includes only acquired pages; separate Mission, People, Garden, Evidence and Science tabs. Critical evidence auto-records on successful inspection; optional scenery never supplies an exclusive key.
- **States:** UNKNOWN,OBSERVED,VERIFIED,LINKED,ARCHIVED.
- **Feedback:** Timestamp, source type, small image, plain-language fact, linked mission; spoiler-safe silhouettes.
- **Dependencies:** SYS-02 dialogue, SYS-03 flags, source register, plant ledger.
- **Edge cases:** Replay voice labelled archive; re-reading cannot grant items; full names withheld only until evidence/consent gate; evidence remains through retries if acquired before checkpoint.
- **Acceptance criteria:** Each mandatory revelation has a journal entry; founder seed counts and knowledge chronology match; all text usable with captions and large UI.

## SYS-08 — Save, checkpoint and chapter replay

- **Purpose:** Preserve deliberate progress and reversible learning.
- **Controls:** Pause→Save/Load; three manual slots plus mission-start and rolling safe autosave; Continue last valid campaign save.
- **Rules:** Save entire mission transaction, actor positions, time, resources, seed ledger, dialogue, inventory, evidence and settings reference. Autosave after safe gates and before commits. Replay uses a copy and never writes campaign progress. Earned album/mastery records may merge idempotently into a separate local profile; that merge cannot grant campaign seeds or bypass mission gates.
- **States:** CLEAN,DIRTY,SAVING,VERIFIED,RECOVERABLE_ERROR,LOADING,REPLAY.
- **Feedback:** Saving icon then saved timestamp; failed save explains available retry and keeps last valid slot.
- **Dependencies:** All systems; versioned plain-data contract in technical blueprint.
- **Edge cases:** Interrupted write restores prior complete save; incompatible future version opens safe message, never silently resets; missing external asset cannot corrupt story state.
- **Acceptance criteria:** Reload every scene gate; no duplicate seeds/time advance; power interruption retains prior valid save; chapter replay leaves campaign state unchanged while merging only eligible profile collectibles once.

## SYS-09 — Greenhouse, biology and lineage

- **Purpose:** Keep Alo and the garden alive as organisms with a life cycle.
- **Controls:** Inspect plant, use moisture/temperature controls, pollinate, log care, harvest and label through P-01/03/06/08.
- **Rules:** Stages locked to dated care transitions; never flower from one instant water click. Health is the source game model. Alo harvested once; later plants are descendants. Tara contributes lineage; cotton planted Dec 15.
- **States:** SEED,SPROUT,BUD,BLOOM,POLLINATED,PODS,MATURE_DRY,ARCHIVED; stress overlays separate.
- **Feedback:** Readable posture, moisture, frost/thirst indicators, lineage labels and last-care date.
- **Dependencies:** SYS-04 resource state, SYS-07 ledger, mission date gates.
- **Edge cases:** Plant face does not diagnose radiation; no outside-vacuum pollen; immature drying blocked; final cotton survives rather than instantly produces bolls.
- **Acceptance criteria:** 42 founder seeds reconcile 12+30; twelve distinct vault specimens; cotton planted plus eleven retained; no original Alo alive inOctober; final garden inside pressure enclosure.

## SYS-10 — Accessibility and settings

- **Purpose:** Let more players experience the complete adventure.
- **Controls:** Settings from title/pause; text size, contrast, remapping, captions, timer, motion, volume and guided options.
- **Rules:** Assist changes input/pressure, not story knowledge or rewards. No colour-only or audio-only clue. All puzzle holds/drags have tap alternatives.
- **States:** DEFAULT,CUSTOM,PREVIEW,APPLIED,RESTORE_DEFAULTS.
- **Feedback:** Immediate text preview; hold-to-reset optional, never only input; persistent per-profile settings.
- **Dependencies:** UI layout, input, audio and every puzzle.
- **Edge cases:** Switch language mid-line resumes matching sentence; unassigned critical control warns; remap conflict offers swap; maximum text wraps rather than clips.
- **Acceptance criteria:** Entire path controller-only, keyboard-only and no-timer; all UI at 150% text; reduced shake and horizon lock; no flashing storm effect required.

## SYS-11 — Menus and mission interfaces

- **Purpose:** Present next actions clearly without exposing internal implementation.
- **Controls:** Pointer or focus navigation; confirm/back consistent; pause always accessible except atomic save boundary.
- **Rules:** Layouts in UI spec; one modal at a time; return focus to initiating control. Normal HUD hides debug IDs and raw internal flags.
- **States:** TITLE,HUD,INTERACTION,PUZZLE,JOURNAL,PAUSE,SETTINGS,RESULT,CREDITS.
- **Feedback:** Objective/action language, visible focus, reason for disabled action, concise result recap.
- **Dependencies:** All systems; localization and typography assets.
- **Edge cases:** Back from a dirty puzzle offers keep editing/discard settings; abandon never loses a unique item; no menu accidentally advances a shift.
- **Acceptance criteria:** Every screen navigable at 1280×720 and 1920×1080; captions never cover required controls; focus never escapes into hidden menus.

## SYS-12 — Audio, music and performance

- **Purpose:** Create intimacy, scale and readable instructions.
- **Controls:** Independent master/dialogue/music/effects/UI sliders; captions and speaker labels; optional dynamic-range mode.
- **Rules:** Exterior vacuum has no airborne footsteps or wind; sounds via suit/cabin/contact. Dialogue priority ducks score 6–9 dB. Motifs reflect relationship progress, not constant urgency.
- **States:** AMBIENT,EXPLORATION,DISCOVERY,HAZARD,SHELTER,REUNION,CREDITS.
- **Feedback:** Caption significant alarms and nonverbal cues; no gameplay needs hearing an exact beep.
- **Dependencies:** Scene event states, voice line IDs, camera/listener location.
- **Edge cases:** A missing VO file falls back to full captions; pause halts timer/music transitions; archive filter preserves speech intelligibility.
- **Acceptance criteria:** No overlapping essential voices; silence remains meaningful; all information survives mute; dynamic mix does not obscure instructions.

## Shared interaction policy

Inspect before Use is encouraged, but not an arbitrary duplicate click unless observation matters. Required props have icon+name when focused and a soft outline optional for accessibility. At 2 m show action; within 2–6 m show object name only. Multi-step operations require one explicit confirmation at the point physical state changes. No dialogue response commits a power shift. No companion invents a missing player answer. Mandatory role switches show the named specialist and preserve camera orientation.

Tutorial sequence: SC-0101 movement/inspect/role; P-01 equipment/calibration; SC-0103 journal/time jump; SC-0104 share/preview/commit; P-03 select-transfer; P-05 independent evidence; P-07 route/reserve; P-09 evidence board; P-11 integrated load; P-15 parallel teams. Tutorials are recorded as short replayable journal cards and never obstruct a returning player's movement with long compulsory overlays.

Class mode is one running local game, four discussion groups and genuinely private printed role cards/envelopes; do not call a shared public screen a private inbox. The operator acknowledges each role's recommendation at the table. It does not require network multiplayer or four controllers. Family/Assisted removes action timers and offers the same solutions; Engineer view shows the explicit game units and source boundaries, not unvalidated real-unit conversions.

## Role facts and communication debrief

| Role / delivery | Private card content | Observed learning evidence |
|---|---|---|
| Kai / shift 1 | Five dark shifts, about 36 h; heat spends the finite night reserve. | Team compares heat and remaining energy. |
| Amara / shift 1 | Make air during daylight before excess jar income spills. | Air production is planned before sunset. |
| Rafi / shift 2 | Labelled 2017 replay feed: sunspot 2673 fired a large flare; more activity is possible. | Team prepares shelter before the alarm. |
| Mei / shift 3 | This scenario’s direct plant threats are frost and thirst; shielding borrows the garden reservoir. | Team protects temperature and returns borrowed water. |

**Combined-evidence decision (GAME-05):** the shift 3–4 plan for *when to fill the wall and when to return the water* only becomes clear by combining two roles. Rafi's card says a storm is likely; Mei's says the shelter water is Alo's and thirst starts at W≥4. Kai's five-dark-shift budget and Amara's stored air decide what the team can afford meanwhile. DL-0105-08 to 12 stages this as a short disagreement, and the Mission Table's side-by-side Preview A/B settles it. The debrief names this decision when the shelter was ready before the alarm and the water was returned afterwards.

**Solo without deadlocks:** switching cadet (keys 1–4) shows that cadet's card, and every delivered card also appears in the journal, so no information is reachable only through a person. **Local/classroom:** one device plus printed cards, as below. Network co-op is future work and is never shown as available.

Solo receives all four role inboxes; Family/Class distribute the cards privately and share by discussion. Card receipt, acknowledgement, voluntary sharing and decisions are separate records. Reading every card is not a forced success gate. Badge evidence: communication (roles shared), situational awareness (shelter ready), decision making (no blackout), team care (safe crew and living Alo). Debrief shows who knew what, causal timeline, one-change replay and real source cards. Never claim ignoring any particular secret necessarily removes a star; the source 3D gameplay audit already corrected that balance assertion.

## Campaign progression and optional play

Five modes retain their source meaning: Family (6+ with adult, 2–4 players, no action timers), Cadet (default), Engineer (deeper units/evidence), Class (four groups/projector) and Solo (all roles/inboxes). All use the same story and conceptual solutions. No independent network co-op is required. Engine/technical details stay outside normal player flows.

### Persistent upgrades

After Chapters 1–7 choose one of two, shown in the debrief before continuing. Store one choice per chapter; retries cannot duplicate it. Changes are visible in station equipment and entry ledgers. Replay may explore the other branch on a copied state. Import the source profiles before applying each modifier; never reset an earned upgrade.

| After | Option A | Option B |
|---|---|---|
| 1 | Taller mast: +2 daylight income per full sampled shift. | Fuel-cell battery: energy cap +6 and entry charge +4. |
| 2 | Red-blue LEDs: FULL costs 1 instead of 2. | Insulation blankets: COOL causes no plant cold damage. |
| 3 | Moon-dirt shelter: +1 permanent effective shielding, capped total6. | Flexible seals: unresolved leak loss 1→0.5 per phase. |
| 4 | Ice harvester: two shelter units use a separate conserved water reserve. | Rover lights/heater: shadow/heater surcharge reduced by1, minimum0. |
| 5 | Dust Shield: prevents dust-income loss; verify the clean surface instead. | Whipple bumper: prevents small-impact micro-leak; verify pressure instead. |
| 6 | Storm early warning: one additional preparation opportunity, with no invented solar income. | Bigger Safe Room: complete STACK grants K3 instead of K2. |
| 7 | Relay parts kit: skips one connector diagnosis stage; bearings still verified. | Long-range battery: rover capacity and entry charge +4, from14 to18 in P-15. |

No upgrade is a mandatory solution key. Test all 128 complete combinations for a safe main path and three-star opportunity; this is a future release test, not an already demonstrated balance guarantee. P-07’s rover lighting upgrade can remove its separately forecast heater surcharge; route slope still governs. Show mixed-unit displays consistently or use one source unit scale throughout production.

### Station Days, album and mastery

Station Days pause hazards and never advance care without an explicit dated transition. They contain conversation, optional tending/decoration, lineage naming, source cards and local letters home. Story-required clues are automatic; hidden collectibles are optional.

| Collection | Count and acquisition | Persistence |
|---|---|---|
| Noor’s logs | 24: one story, one Station Days discovery and one recovery log per chapter. Chapter 2 story log recalls yellow mustard fields; Chapter 7 explains the Academy name. | Separate local album; recovery log survives retry. Until CH05 all attributed to N. |
| NASA data cards | 32, four per chapter, topic list below. | Provenance included; estimates/fallbacks visibly tagged. |
| Seed collection | 16 cultivar entries: two founders, twelve vault types, two optional challenges; see 18. | Album entry separate from biological seed inventory. |
| Mission patches | Eight chapter patches plus Silent Night, Clear Signal, Careful Observer and Garden Keeper =12. | Completion/mastery once; accessibility does not penalise. |
| Postcards | Eight: last light, Earth-set, first bloom, frozen garden, ice sample, impact flash, ring, Earth over Malapert. | A broad confirm action captures required viewpoint; no pixel precision. |
| Family tree | Approximately nine generations, depending on care dates. | Dates/parents retained; purple/green observations do not invent genotype ratios. |
| Mastery | Three stars and one Golden Bloom per chapter:24 stars,8 Golden Blooms. | Profile retains best earned result; no star gates the story. |

Card topics by chapter: CH01 LROC illumination/DONKI/CRaTER/MSL RAD; CH02 Mir pollination/Fast Plants lifecycle/cross-pollination/stem genetics; CH03 Apollo seismogram/1973 quake/LRO faults/plant dry-down; CH04 LOLA slopes/ShadowCam/LCROSS/Diviner; CH05 impact monitoring/LROC craters/dust/EDS; CH06 eclipse catalog/Horizons/atmospheric refraction/Diviner cooling; CH07 STEREO-A/2012 near miss/1972 event/SEEDS seed survival; CH08 Malapert/line of sight/LunaNet/Horizons bearings. Each is a distinct source-labelled entry, not a claim that its underlying data is already bundled.

Three-star criteria: CH01 uses P-02; CH02 safe procedure/no blackout/three reciprocal runs; CH03 at most one wrong isolation/no blackout/live seed harvest; CH04 safe route and reserve>=30/no blackout/all three beacons; CH05 six correct flashes/no blackout/maintenance; CH06 five acknowledged segments/no blackout/live garden; CH07 Z<=6/no blackout/living crops and protected seeds; CH08 both occupant ledgers safe and rover reserve>=2/no blackout/relay plus live garden. Golden adds CH01 H>=5; CH02 no contaminated transfer; CH03 no wrong isolation; CH04 all beacons before blind corners; CH05 all eight flashes and no false report; CH06 E>=2 at recovery; CH07 no unsafe committed response; CH08 unused emergency reserve. These [G] targets require playtesting; retries/assists remain equally available.

### Eight short side stories

Each is an optional 3–5-minute activity: Who Ate the Tomato? (match the ISS lost-tomato clues); Hammer and Feather (predict, drop, compare); Moon Golf (compare two launch settings); Space Tacos (assemble crop choices); Earthrise (record a visibility window); The Bubble Record (compare gravity diagrams); Birthday on the Moon (decorate/share a local card); Letters Home (save or discard a local note). Their required copy and activity details follow [the source optional-content specification](../docs/GAMEPLAY_DESIGN_FINAL.md#9-optional-content-collections-and-dialogue). They cannot supply exclusive main-path tools or change survival resources.

### Recovery and postgame

A loss unlocks a causal review and the chapter’s recovery log, then restores the last shift/checkpoint. After two losses offer a local hint card; while Earth is down it is stored guidance or a local companion, never a new live Rao transmission. Optional practice also exposes recovery logs, so collecting everything does not require deliberate harm.

After the finale unlock Moon Garden (no failure), Live Sky (offline precomputed ephemerides with date range), and opt-in Storm Watch (internet for new source-labelled replay content, shown only in app). A missing network or future sky range leaves the core game accessible. No notifications, purchases, accounts or personal-data collection. Extra collection/replay time is what supports the 10–14-hour target; it is not compulsory repetitive survival work.
