# LAST LIGHT ACADEMY — FINAL 3D Gameplay Design

**Team The Last BrainCell · NASA Space Apps Challenge 2026**
**Challenge:** Build a Junior Astronaut Mission Trainer
**Design date:** 7 October 2026 · **Engine:** Godot 4.7.2 stable, GDScript
**Status:** complete design specification; implementation and playtest evidence are not yet claimed.

## 1. Authority, preserved canon, and scope

This is an additive 3D implementation specification. It does not edit or replace the text of [STORY_FINAL.md](STORY_FINAL.md), [CAMPAIGN_SEASON1.md](CAMPAIGN_SEASON1.md), [GAME_PLAN_FINAL.md](GAME_PLAN_FINAL.md), or [SCIENCE_AND_DATA.md](SCIENCE_AND_DATA.md). Their story, characters, chapter sequence, named endings, and intended game length remain the creative canon. For implementation details that were ambiguous in the earlier 2D plan, use the explicit rules in this document. The source snapshot reviewed was repository commit `a3c01d29a58e104eca089aada6a6d0d2a153c9dc`.

**Player promise:** Run a Moon station, protect its crew, turn Alo's family into the first Moon garden, and discover who left the seeds. Every chapter makes a real engineering trade-off understandable through actions and consequences.

**Locked:** Aurora Station on Shackleton's rim; Kai, Amara, Mei, Rafi, Ferreira, Rao, Alo, Tara and Noor; April 2046–April 2047 setting; Expedition Zero twelve years earlier; eight chapters; Alo's natural life cycle; the lighthouse climax; cotton surviving sunrise; the MARS drawer after the credits. Chapter 1's 2017 storm is a historical replay. Chapter 7 is an explicitly labelled counterfactual replay of the 2012 storm. The fiction does not become a claim of historical lunar settlement.

**Minimal necessary changes:**

| Change | Reason | Boundary |
|---|---|---|
| Replace the cut-away screen with a compact third-person 3D station | Make operating the outpost spatial and hands-on | No open-world expansion or combat |
| Turn resource buttons into consoles, valves and snap-to-slot equipment | Make the player's actions visible | Preserve sun-drops and the planning/shift loop |
| Add a small edible-crop/ration layer to the existing garden | Address food production explicitly | Alo remains the emotional science objective; no new protagonist or chapter |
| Specify resource update order, checkpoint handling and private information | Remove implementation ambiguity | Preserve the original starting Chapter 1 values wherever possible |
| Correct unsupported balance guarantees and misleading presentation | Decisions must be fair and scientifically defensible | No claim that every ignored secret automatically loses a star |
| Separate live radio, recordings and date transitions | Keep Earth-set coherent | Canonical lines and story events remain intact |

This document fixes design decisions, not measured performance or scientific values that still need processing. Tags: **[M] measured/source-derived**, **[E] estimate awaiting site-specific verification**, **[G] game design abstraction**, **[F] fiction**. All newly specified game quantities are [G] unless explicitly sourced. The chapter timing targets and later-chapter balancing values are design targets, not completed playtest results.

## 2. Audience, length, and release boundary

Primary audience: ages 10–15, at home or in a classroom. Family Mode serves ages 6+ with an adult. Engineer Mode exposes units and deeper evidence. Judges can use a five-minute guided route without completing the campaign.

| Chapter | Preserved target | Spotlight |
|---|---:|---|
| 1. Night One | 25–30 minutes | The whole crew |
| 2. Be the Bee | 20–25 minutes | Mei |
| 3. Moonquake | 25 minutes | Amara |
| 4. Into the Cold Trap | 30–35 minutes | Rafi |
| 5. Shooting Stars | 25 minutes | Ferreira |
| 6. The Red Ring | 25 minutes | Kai |
| 7. The Great Storm | 35–40 minutes | Rafi and Ferreira |
| 8. The Lighthouse | 35–45 minutes | Everyone |

Main-story range: **220–250 minutes, about four hours**. Optional Station Days add approximately 1–1.5 hours. The intended complete collection/mastery experience remains **10–14 hours**, including replays and alternative upgrades. Optional content never blocks the main story. The five-minute judge route and Chapter 2 sample are demonstrations, not replacement chapter lengths.

Hackathon deliverable: complete Chapter 1, season map with Chapters 2–8 visibly locked, Noor's ending and Tara, a debrief driven by actual bundled source data, Solo and classroom role play. A Chapter 2 sample is secondary. The complete season remains the post-hackathon product. Do not describe unbuilt chapters as playable.

## 3. What the player sees and controls

**World:** real-time 3D characters and equipment, traversable rooms, exterior chamber, rover routes and observatory. The player can move and interact. Pre-rendered footage is reserved for brief transitions and optional history material; it does not stand in for playable 3D.

**Camera:** third-person follow camera for movement; a stable close view for instruments; a raised 3D station overview at the Mission Table; short scripted views for canonical story beats. Camera collision prevents viewing through walls. Menus do not spin the camera. Equipment exits restore the previous view. Assisted camera is available in every mode.

| Input | Keyboard/mouse default | Behaviour |
|---|---|---|
| Move | WASD | Walk; no platforming skill gate |
| Look | Mouse | Adjustable sensitivity and invert-Y |
| Interact | E | One context-sensitive action; hold is optional |
| Exit/cancel | Escape | Return to world or pause |
| Role selection | 1–4 | Choose Kai, Amara, Mei or Rafi when safe |
| Mission Table | Tab | Planning screen; available after tutorial |
| Change value | Arrow keys or +/- | Same outcome as a mouse selection |
| Commit shift | Space, then confirmation | One deliberate state update |
| Task item | Left mouse / interact | Context-specific scanner, bee stick or placement |
| Pause | Escape | Stops mission time and action timers |

Controller equivalents: left stick move; right stick look; south face button interact/confirm; east cancel; shoulder buttons role cycle; menu pause. Controls are remappable. No action requires rapid repeated presses. Captions, high-contrast labels and icons accompany colour; UI starts at 18-pixel-equivalent readable text at 1080p and scales. Offer Bangla/English, reduced shake, no timed actions in Family Mode, and a hold-button alternative to dexterity tasks.

Movement does not secretly spend base oxygen or battery. Explicit tasks show their cost before confirmation. Both indoor and outdoor scenes are on the Moon; walking animation is stylised, while lunar gravity is not represented as zero gravity. Exterior sounds are suit contact/radio or score, not air-transmitted thunder or wind. Radiation has no visible laser attack; alarms and dose instruments show it. Any educational particle schematic is labelled as a diagram.

## 4. Station layout and object contract

Four rooms connect to a short central corridor and Mission Table. The Airlock leads to a small safe exterior apron and Alo's sealed chamber. The rover garage unlocks for Chapter 4. An observation window is reused for impact watching and the eclipse. The Chapter 3 hatch opens the old garden annex. No required room-to-room trip should take more than roughly 10–15 seconds in the initial layout [G]; test this with novice players.

| Space | Required objects | Main gameplay |
|---|---|---|
| Power | Battery jar, heater console, solar status display | Allocate energy, inspect incoming light and reserves |
| Air | Oxygen tank, production console, pressure sensor | Pre-produce air, detect losses, verify readings |
| Garden | Food grow rack, water manifold, Tara pot, plant console | Crop care, Alo link, pollination and seed handling |
| Safe Room | Water panels, transfer valve, crate slots, dose monitor | Prepare shelter, respond to storms |
| Corridor | Mission Table, radio, signs, logs, save point | Plan, talk, review evidence and navigate |
| Airlock | Two doors, suit check, cycle controls | Safe transition with visible procedure |
| Exterior | Alo chamber, short walkway, masts, approved interaction port | Inspect/care without opening the chamber to vacuum |
| Annex/garage | Old terminal, seed storage, rover bay | Campaign discoveries and expedition preparation |

Every interactable supports: readable prompt, permitted roles, range/line-of-sight check, current state, explicit proposed effect, confirm/cancel, one transaction ID, animation acknowledgement, result and error explanation. An object cannot charge twice because E was pressed twice. Controls near walls have enough stand space. Valves and panels have proper model pivots. Collision shapes are simpler than visual meshes.

Airlock sequence: close inner door, check suit, confirm cycle, unlock outer door. Opening both doors is prevented. Time and air costs are charged once at the planned checkpoint, never per animation frame. Chapter 1's guided inspection has its cost included in the existing mission reserve; later bee-run costs are explicit. Alo's chamber has a sealed tool interface; pollination does not expose its atmosphere to lunar vacuum.

## 5. Core loop, clocks, roles and communication

**Observe → inspect → share information → preview choices → perform actions → commit shift → see consequences → update the plan.** Each shift contains one interesting decision; walking is not its main time cost.

Three clocks are visible and distinct:

1. **Planning clock:** frozen simulation; the player can read, move, talk, and compare settings. Cadet Mode may display a soft 90-second planning suggestion, but it does not auto-commit.
2. **Action clock:** short, local challenge timer. Chapter 1's alarm has a 90-second action window [G], including selection and response. It represents compressed warning time, not 90 real seconds from the 2017 measurements.
3. **Scenario clock:** source-derived or scenario-labelled elapsed time. Chapter 1 has two preparation shifts and five dark shifts of about 7.2 hours; the dark interval is approximately 36 hours. A 5–8-second time-lapse resolves a shift. Skip animation preserves identical outcomes.

Dialogue pauses the action clock. Tutorials are inside the chapter time budgets. The Mission Table lets the player change routine settings after learning each physical console once. New faults still require inspection on location. The forecast uses the same simulation function as commitment, and it marks unknown events instead of revealing them.

**Solo:** one operator switches between four cadets; discovered messages appear in that operator's role inbox. No false secrecy claim. NPCs carry out confirmed routine orders and supply their observations, not optimal solutions. Switching is disabled during an airlock cycle, carry placement or a committed minigame; finish/cancel first.

**Family/Class:** one shared device, turn-taking operator, four role groups. Use printed/private role cards and envelopes for genuinely separate information. The public view shows common station readings; role-specific information is delivered through cards. Everyone discusses a plan; each role approves its setting; the operator confirms. A lone player can enable all approvals automatically. Family Mode removes action timers.

**Network co-op:** optional future delivery; four devices and private inboxes, one host-authoritative simulation, acknowledgement and disconnect pause. It is not required for the first build and is not advertised as implemented. Do not imply four players can independently free-roam on one keyboard.

Role-specific facts arrive at canonical moments. The debrief records receipt, acknowledgement, communication and decisions separately. A good plan can succeed without reading every line; communication badges reflect observed evidence, not an unavoidable penalty script.

## 6. Chapter 1 numerical contract

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

- **PUMP:** one transfer of up to +2 W; ordinary systems use the chosen settings. A 15-second guided valve task starts only after the player chooses it. Three broad, ordered valve confirmations unlock the full +2. Each accepted confirmation counts once. Family/assisted mode completes the same confirmations without a timer. Incomplete pumping moves only +1; the preview then recalculates.
- **STACK:** a 30-second snap-placement task. Four supply bundles fill outlined bunk slots; complete placement gives K=2, partial placement gives K=1. W does not change. Set heat COOL, O=0 and L=OFF for this shift; show that cost before selection. No detailed water-fluid or falling-crate simulation is required.
- **WAIT:** no minigame or extra shelter; keep the chosen settings. Waiting is a legitimate strategy if preparation is adequate. The shelter warning shows what is known.

PUMP, STACK and WAIT are mutually exclusive. At timer expiry resolve the selected action once, with completed progress. A human can always choose assisted input before starting; motor speed is not the learning outcome.

**Exact shift order:**

1. Save the pre-shift checkpoint; validate settings and one allowed transfer/alarm command. For shift 5, complete/resolve the alarm action before the economic update. For shift 7, remove K.
2. Add daylight income and clamp E to 20 **before** spending; record overflow. Add O and clamp A to 10 **before** breathing.
3. Exposure in shift 5 uses shelter after the alarm; exposure in shift 6 uses shelter at the start of that shift, before its ordinary transfer. Effective shelter S=min(6,W+K). Dose per storm shift: S 0–1 gives 3; 2–3 gives 2; 4–5 gives 1; 6 gives 0.
4. Apply the permitted ordinary W transfer (except shift 5); cap W to 0–6. Transfers conserve total water. Crates do not remove garden water.
5. Subtract basics + heat + O + L from E. Day heat costs 0. If the result is **below 0**, mark a blackout, set E=0, apply A-2, H-2 and C-2 [G]. Exactly E=0 is an empty battery warning, not that shift's blackout; the next unpaid demand can cause one. Oxygen production/plant growth are a deliberately simplified shift model, not second-by-second electrolysis under a failed power bus.
6. Subtract breathing A-1; apply light, cold and thirst to H/C using post-transfer W. Combine changes, then clamp to 0–10. Dead H/C do not resurrect within an attempt. Consume R by elapsed scenario days, with no new crop harvest during these shifts.
7. If A<=0 stop the mission and offer retry. If food would run out, trigger an early resupply/abort requirement instead of depicting immediate starvation; Chapter 1's starting stock covers the night. H=0 means Alo lost, but safe crew operation can continue to the ending.
8. Record before/after values, causes, event source and action success. Render the same state to all consoles, HUD and actors. Evaluate the sunrise result after shift 7.

**Endings and progress:** retain three mastery stars: crew exposure Z<=3; no blackout; Alo alive. Golden Bloom requires all three and H>=5. Bloom requires a completed mission with safe crew and H>0. Alo lost means safe crew completes the night with H=0. Mission stopped covers air failure or a crew exposure safety breach; pre-loaded flight rules initiate the abort while Earth is down. Ferreira's live response appears only in a later Earth-visible epilogue. Retry restores the complete last checkpoint. Food condition gets a visible harvest forecast and garden-care badge; it does not replace these canonical endings. Story progression requires safe completion and a living Alo; mastery stars do not gate the next chapter.

**Balance honesty:** the previous claim that COZY every night necessarily causes a blackout is not retained. Under these base values, a valid all-COZY plan has day O=[2,0], L=[FULL,FULL], night L=OFF, W fills in shifts 3–4, WAIT in 5, drain in 6–7. Final E=2, A=1, H=1, W=0, Z=2; it earns three stars. There is no unpublished guarantee about 923 states or random-win rates. Re-run balance after implementation, food calibration or any parameter change; publish the actual version and results. The lesson is informed trade-offs, not a forced single solution.

## 7. Complete chapter flow and required conversations

All lines below are the required English script for this 3D design. Canonical story lines are retained; operational dialogue expands their playable context. Dialogue IDs are stable for localisation, subtitles and triggers. Optional responses affect rapport/feedback, not the locked plot. Names in developer IDs are not spoilers: the player sees **N.** until Chapter 5. Conversations pause action timers and can be replayed in the local journal. Unvoiced builds retain every line as captioned text.

### Chapter 1 — Night One

**Entry:** title → accessibility/language/mode → season map → short history/context card → seed-packet opening → guided station tour. The packet scene is two weeks before the night, then an explicit time card moves to the mission day. Final objective: crew safe, station operating, Alo alive at sunrise.

**Playable sequence:**

| Beat | Budget | Player action / transition |
|---|---:|---|
| Opening and tour | 3 min | Pick up packet; inspect Alo and indoor crop rack; learn move/interact |
| Day shift 1 | 3 min | Learn power and oxygen; read Kai/Amara facts; preview settings |
| Day shift 2 and drill | 4 min | Practice a shelter response; receive Rafi forecast; drill restores shelter state and consumes no live mission resource |
| Last Light, shift 3 | 3 min | Inspect chamber; read Mei fact; plan heat/light/water |
| Earth-set, shift 4 | 3 min | Use last radio hint; confirm autonomous plan |
| Alarm and storm, shift 5 | 4 min | Choose one response, perform it, enter Safe Room, commit |
| Storm tail, shift 6 | 3 min | Inspect readiness; drain only after exposure snapshot |
| Last dark shift, sunrise | 3 min | Commit final budget; inspect Alo at first light |
| Debrief, message, map | 3 min | Read causes/data; hear N.; see Tara and next chapter |

This is a 29-minute target including movement and conversations. Family play can pause; experienced players can skip previously seen tutorial lines.

| ID / trigger | Speaker | Required line |
|---|---|---|
| C1-01 packet pickup | Mei | Two seeds. Alo, and one letter: N. Someone wanted these found. |
| C1-02 packet reply | Kai | Then let's give them a place to grow. |
| C1-03 mission briefing | Ferreira | Crew first. Keep the station running. Bring Alo through the night. |
| C1-04 power lesson | Kai | Sunlight fills the jar, but the jar has a limit. Save what we need; use what would spill. |
| C1-05 air lesson | Amara | I can make oxygen while the Sun is up. The tank can keep it for the night. |
| C1-06 food rack | Mei | Alo is our experiment. These crops help feed us. Both need power, water and care. |
| C1-07 drill start | Ferreira | Practice building the shelter. Check the effect before you commit. |
| C1-08 forecast, Rafi's private card | Rafi | Sunspot 2673 just fired a giant flare. Another big one may come. |
| C1-09 sharing prompt | Amara | Rafi, tell us what that changes in our plan. |
| C1-10 light loss | Kai | Last Light. From here, the jar is all we've got. |
| C1-11 chamber inspection | Mei | Alo can handle this storm's radiation in our scenario. Cold and thirst are the danger. That wall uses our garden water. |
| C1-12 Earth-set | Ferreira | Earth-set in ten seconds. From here, you're on your own. |
| C1-13 last hint | Rao | Read every room's reserve. Choose together. Your flight rules are already on board. |
| C1-14 alarm | Rafi | This is not a drill! |
| C1-15 response panel | Amara | Pump water, stack supplies, or trust the shelter we prepared. What can we afford? |
| C1-16 transfer confirmed | Mei | Protection is up. Now mark when the garden gets that water back. |
| C1-17 last dark shift | Kai | One shift left. Check the forecast before we run it. |
| C1-18 bloom | Mei | Alo... you made it. |
| C1-19 sunrise recording | N. | If you're hearing this, Alo bloomed. Good. Now Alo needs a friend. — N. |
| C1-20 Tara reveal | Mei | The second seed has a bud. Tara. Alo can't make seeds alone. |
| C1-21 later Earth-visible epilogue, explicit "Days later" card | Ferreira | You didn't survive the Moon. You ran it. |
| C1-F1 plant lost | Mei | We kept the crew safe, but Alo didn't make it. Let's find the decision we can change. |
| C1-F2 abort | Onboard system | Flight-rule limit reached. Mission stopped. Restore the last checkpoint to review your plan. |

**Data reveal:** source-labelled LROC site image, DONKI replay timeline, energy/air units, and processed CRaTER curve when available. The bloom scene does not show Earth rising prematurely. N.'s message is local storage, not a live call. The optional epilogue is after the local message and a visible date transition; no hint returns during the night.

### Chapter 2 — Be the Bee

**Entry:** late April 2046; Tara's indoor chamber is flowering. No new cast or plot branch. **Goal:** complete reciprocal cross-pollination and keep station systems safe. **Toy:** bee-stick aiming and an airlock route.

**Flow (23 min):** grandmother memory/briefing 2 → pollen demonstration 3 → three meaningful bee-run cycles 12 → stem-colour prediction 2 → debrief/N. log 3 → quake cliffhanger and upgrade 1. The seven flowering days appear as three explicitly dated snapshots; the player does not walk every simulated day.

Each run: inspect space weather → collect pollen at the correct flower → secure tool sleeve → cycle airlock → access the other sealed chamber → apply pollen → return/check readiness. One route-cycle allowance includes four airlock transitions and costs **1 sun-drop and 1 air unit [G]**, charged once for the whole run. A second trip is not charged for a camera cut. Broad target zones accept a steady 0.5-second brush contact; three accepted flower contacts complete each direction. Contamination feedback clears that contact, not the whole chapter. Family assistance slows/locks the target. Make three successful reciprocal cycles; a missed cycle can be retried without losing a flower. The existing planning loop remains active between snapshots. No instant crop harvest.

| ID | Speaker | Line |
|---|---|---|
| C2-01 memory | Mei | My grandmother pollinated apple trees by hand. When the bees can't come, we become the bees. |
| C2-02 | Amara | Alo and Tara are different plants. That's the pollen partnership we need. |
| C2-03 | Rafi | Weather check first. A good gardener comes home safely. |
| C2-04 | Kai | The airlock costs air and power. Let's finish the route we planned. |
| C2-05 tool lesson | Mei | Brush gently. Keep the pollen covered until we're inside the other chamber. |
| C2-06 completed cycle | Amara | Both directions confirmed. One successful bee run. |
| C2-07 prediction | Mei | Alo's stem is purple. Tara's is green. What colour will their children be? |
| C2-08 local recording | N. | My grandmother's fields turned yellow every winter. I wanted that colour somewhere new. |
| C2-09 cliffhanger | Rafi | Was that... a moonquake? |
| C2-F | Mei | The pollen didn't reach the flower. Keep the sleeve sealed and try that contact again. |

Record the prediction without grading it yet; explain inherited traits in Chapter 4. Do not promise an exact offspring ratio from phenotype alone. **Progress:** successful reciprocal pollination and crew safe. Stars: safe procedure; no blackout; full pollen coverage. Golden: all plus no failed cycle. **Upgrade:** red-blue LEDs or insulation blankets. **Evidence:** Mir hand-pollination history and Fast Plants methods, with fictional route costs labelled.

### Chapter 3 — Moonquake

**Entry:** May 2046. **Goal:** isolate and patch the air leak, then complete Alo's seed harvest. **Toy:** a noisy-reading investigation. **Flow (25 min):** seismic opening 2 → scanner lesson 3 → four investigation/repair phases 12 → seed dry-down and Alo's Gift 4 → annex discovery/debrief 4.

Six labelled inspection points have known connections. The event seeds a leak location for that attempt and keeps it fixed on retry. Each phase permits two readings and one repair proposal. The scanner displays a calibrated uncertainty range, not an exact red arrow. Compare pressure trend and local acoustic/contact reading; show a tutorial contradiction so players learn to cross-check. A wrong isolation costs one repair phase and one air unit [G]; it does not remove a major plot clue. Each confirmed leak costs one air unit per unresolved phase. At phase 3 an aftershock opens a second, smaller leak; the same rule applies. Four field patches are available; verified repairs do not consume duplicates. Family Mode identifies the likely zone after two inconsistent attempts.

The seed-ripening sequence is a separate dated plant-life snapshot, not four phases of instant maturity. Mei sets **seed-pot watering OFF** after the journal marks pods mature; this affects the seed pot only, not live edible crops. Harvest succeeds after the explicitly dated dry-down transition. Alo's death is natural, scripted annual-plant completion and never caused by the player meeting the objective. The canonical **42 seeds** are the story result, not a biological yield guarantee [F].

| ID | Speaker | Line |
|---|---|---|
| C3-01 | Amara | Pressure is falling. These readings disagree. I need another measurement. |
| C3-02 | Ferreira | Make your best estimate, check it, then update. Waiting for perfect numbers is a choice too. |
| C3-03 | Rafi | I'll hold the safety checklist. Tell me which section you're isolating. |
| C3-04 correct repair | Amara | Trend stabilised. We found the leak, not just the loudest noise. |
| C3-05 aftershock | Kai | Another tremor. Recheck the section we haven't inspected. |
| C3-06 pods | Mei | The pods are ready. Stopping the water feels wrong, but the seeds need to dry. |
| C3-07 Alo's Gift | Amara | Forty-two seeds. Alo made forty-two seeds. |
| C3-08 | Mei | Then every first flower in this garden will be called Alo. |
| C3-09 hatch | Rafi | N.R. Expedition Zero. There was a garden here before ours. |
| C3-10 recording/map | N. | Coldest place. Safest place. — N. |
| C3-F | Amara | That isolation didn't stop the pressure loss. Compare the readings before using another patch. |

**Progress:** both leaks verified repaired, crew safe, seed dry-down/harvest complete. Stars: minimum diagnostic waste; no blackout; safe seed protocol. Golden: all plus no wrong isolation. **Upgrade:** moon-dirt shelter or flexible seals. **Evidence:** Apollo seismic waveform/sonification; earthquake-location uncertainty retained. The frozen annex contains the map, not an unexpected combat encounter.

### Chapter 4 — Into the Cold Trap

**Entry:** October 2046, five-month transition; twelve descendants growing across documented generations. **Goal:** retrieve the vault and return both rover crew safely. **Toy:** route planning with split information and beacon placement. **Flow (33 min):** family-tree reveal/briefing 4 → loadout and driving lesson 4 → outbound route 9 → cold-trap investigation/vault 5 → return 7 → debrief/message/upgrade 4.

Use a compact playable route with four legs, not a full polar open world. The base role card has slope/terrain evidence; the driver sees local headlights and instrument limits. Solo can switch to the base display. Three beacon sites maintain line of sight; the map explains why a blind corner breaks radio. Beacon deployment is a snap interaction, not free building. Rover starts with battery 16, cap 20, reserve floor 2 [G]. Each safe route leg costs 1, shadow/heater travel costs +1, detour costs +1; show totals before confirmation. Four outbound and four return legs use a route ledger; the baseline safe route has two shadow legs. Reusing a deployed beacon costs nothing. One ice scan and one capsule release cost 1 each. The baseline route therefore uses 12 units and returns with 4; two optional detours can use that margin down to the 2-unit reserve. Charge/loadout is selected before departure; emergency return is offered before reserve failure. Slopes above the current marked vehicle limit are blocked with an explanation; upgrades can unlock a lower-cost alternative route, not impossible slopes.

Keep base operation in two meaningful planning checkpoints while the rover is at the vault and on return; pause both views while Solo switches. The cold trap is a real-environment concept with a source card, while this specific capsule and twelve seeds are fiction. Route transitions account for travelled distance without requiring continuous driving of every kilometre.

| ID | Speaker | Line |
|---|---|---|
| C4-01 | Mei | Twelve plants. Alo's children, and their children. Let's check our colour prediction. |
| C4-02 | Ferreira | We go at midsummer, when the rim gives us more sunlight to prepare. |
| C4-03 | Rafi | Battery, slope, return route, radio. Worry is useful when it becomes a checklist. |
| C4-04 | Amara | I can see the slope map. You can see the ground. Tell me what the headlights show. |
| C4-05 blind corner | Rafi | Signal fading. Place the beacon before we go farther. |
| C4-06 scan | Mei | Ice mixed into the soil. A resource, if we can use it safely. |
| C4-07 vault inscription | N. | If you found this, you're ready. Ask Commander Ferreira about Expedition Zero. |
| C4-08 radio pause | Rao | She... needs a minute. |
| C4-F | Rafi | The return reserve is too small. Choose the shorter route or charge before departure. |

**Progress:** vault scan, all twelve story seeds secured, rover returned above zero reserve, base crew safe. Stars: safe slope/return plan; no blackout; full recovery. Golden: all plus continuous planned radio coverage. **Upgrade:** ice harvester or rover lights/heater. **Evidence:** LOLA slope samples, ShadowCam, Diviner and LCROSS; do not portray all cold traps as the same measured temperature or ice fraction.

### Chapter 5 — Shooting Stars

**Entry:** around 14 December 2046. **Goal:** observe impacts, manage dust-related power loss and patch the garden dome. **Toy:** observation and verification. **Flow (25 min):** Ferreira confession 4 → instrument lesson 2 → three observation/maintenance phases 12 → records/data 3 → eclipse invitation/upgrade 4.

View surface impact flashes through an observatory instrument, not meteor streaks in a lunar atmosphere. A fixed attempt sequence offers eight flashes plus two instrument-noise events [G]. Tag event time and direction, then compare two successive frames; slow playback is available without penalty. Six verified events meet the science objective. After phase 1, dust reduces daylight income by 2 until cleaned; after phase 2, a dome micro-leak consumes 1 air per phase until patched. The player chooses maintenance order, not click speed. Dust Shield prevents that dust penalty; Whipple bumper prevents the micro-leak. If prevented, replace the repair with an inspection and explain the upgrade's effect. Source-based impact-rate playback is used when processed; a fabricated teaching sequence is tagged [G].

| ID | Speaker | Line |
|---|---|---|
| C5-01 | Ferreira | Noor stayed to the last minute to hide the seeds. I was the engineer who couldn't fix the radio. We left her garden to freeze. I left it. |
| C5-02 | Mei | Noor? The person who left Alo? |
| C5-03 | Rao | Noor is alive. She's read every one of your mission reports. She asked about Alo by name. |
| C5-04 | Amara | Record the time and direction. One bright pixel isn't enough evidence. |
| C5-05 | Kai | Dust is cutting our incoming power. Clean now, or plan with less. |
| C5-06 joke | Rao | Why was the meteor so sad? It had a crater-ble day. |
| C5-07 | Rafi | Joke recorded. Dome seal still needs checking. |
| C5-08 invitation | Ferreira | In four weeks, Earth will swallow the Sun. This time, I want you to see it. |
| C5-F | Amara | That was instrument noise. Compare the next frame; the record can be corrected. |

**Progress:** six verified observations, essential maintenance complete or upgrade-protected, crew safe. Stars: observation accuracy; stable power; safe crop/dome condition. Golden: all plus all eight verified flashes. **Upgrade:** Dust Shield or Whipple bumper. **Evidence:** NASA lunar-impact records and LROC before/after examples. Main mystery identity is now revealed; old logs retain their original signature but the journal can identify Noor.

### Chapter 6 — The Red Ring

**Entry:** 12 January 2047. **Goal:** plan the eclipse window, keep critical systems powered and capture a postcard. **Toy:** a countdown scheduling puzzle. **Flow (25 min):** Kai memory/briefing 3 → evidence and forecast 4 → build/inspect schedule 8 → eclipse and family call 5 → debrief/Noor message/upgrade 5.

Schedule five segments: precharge, ingress, total occultation, egress, recovery. Durations come from the verified site-specific file, not a globally copied lunar-eclipse totality duration. Until that file exists, label the scenario timing [E] and do not advertise an exact base view. Each segment displays energy demand proportional to elapsed time, stored oxygen and crop limits. Player sets critical/optional circuits and a reserve target. A rehearsal preview can be changed freely; one confirmation commits. Photo framing has a wide tolerance and no reaction-time requirement. Main progression does not require the photo; Family Mode supplies a stable camera position.

Earth is visible only if the selected site/horizon data supports the eclipse view. The family's call is live during that visibility window; a partial contact is buffered if local terrain interrupts it. The fictional family speech does not claim a real astronaut family transmission. No forced inescapable blackout is inserted after the player builds a sound plan.

| ID | Speaker | Line |
|---|---|---|
| C6-01 | Kai | When I was little, a blackout felt like the whole world had disappeared. |
| C6-02 | Amara | This one has a forecast. We can put every demand on the timeline. |
| C6-03 | Kai | Keep the essentials. Pause what can wait. Leave a reserve for recovery. |
| C6-04 red ring | Mei | A ring of sunsets and sunrises. One of them is home. |
| C6-05 family | Kai's family | We can hear you. Tell us what you see. |
| C6-06 | Kai | The dark is okay. If you know when it's coming, you can get ready. |
| C6-07 text | Noor | I watched a red ring from there once. Beautiful, isn't it? — N. |
| C6-08 sunspot | Rafi | A giant sunspot group is turning this way. |
| C6-09 | Ferreira | That's the biggest one I've seen since Expedition Zero. |
| C6-F | Kai | The forecast showed that demand peak. Let's move an optional task out of the dark window. |

**Progress:** crew safe and critical loads maintained. Stars: no blackout; garden preserved; complete forecast-based plan. Golden: all plus postcard and reserve intact. **Upgrade:** storm early warning or bigger Safe Room. **Evidence:** eclipse catalog plus topocentric Horizons and local horizon; the Bangladesh sunrise connection stays conditional on that verification.

### Chapter 7 — The Great Storm

**Entry:** February 2047; clear title **"What if? Historical 2012 storm replay"**. **Goal:** protect crew, garden and dry seeds across three waves. **Toy:** coordinated staged preparation with earlier upgrades. **Flow (38 min):** history/counterfactual briefing 4 → stock and upgrade inspection 6 → six planning/action phases across three waves 18 → final log and radio failure 6 → debrief/cliffhanger 4.

Three waves: fast-particle arrival, shock-associated peak, long tail. Use the processed particle profile to set order and relative hazard; do not invent a measurement at the fictional station. Before calibration, the six-phase teaching hazard multipliers are [1,1,2,2,1,1] [G] and the shelter dose table from Chapter 1 is multiplied by that phase's factor. Safe exposure target is Z<=6 [G], shown in the forecast. Seed case has two snap compartments and a thermal seal; secure both before peak phase 3. Dry seeds are not invincible. A missed seed preparation fails the mission objective and triggers checkpoint retry, without erasing the vault collection. The garden must retain living plants and a viable food batch. The same energy/air/light/water rules remain; the chapter entry ledger normalises reserves to its published scenario profile and applies owned upgrades. No surprise reset or secretly stronger storm on a successful plan.

Radio failure happens only after the survivable mission objective resolves. It is the canonical narrative incident [F], not punishment for an engineering choice. Autonomous procedure and local stored logs remain available. Earth-set then removes geometrical direct visibility as well. Ferreira's cliffhanger is a clearly labelled cached mission recording, not a new live transmission through broken hardware.

| ID | Speaker | Line |
|---|---|---|
| C7-01 history card | Narrator | In July 2012, a powerful solar storm missed Earth. This mission asks what if it had reached our Moon station. |
| C7-02 | Kai | Power plan ready. I know what we can switch off. |
| C7-03 | Amara | Best estimate entered. I'll check it against each new reading. |
| C7-04 | Mei | Protect the living garden, and keep the dry seeds sealed. Seeds first. |
| C7-05 | Rafi | Worry is just a plan you haven't written down yet. |
| C7-06 | Ferreira | Your call, cadets. |
| C7-07 peak | Rafi | Second wave. Verify the wall before moving any water. |
| C7-08 recorded log | Noor | We're leaving at last light. I'm calling the seeds Alo, light, so whoever finds them brings the light back. |
| C7-09 radio failure | Amara | Radio hardware fault. Local systems are still responding. |
| C7-10 | Ferreira, locally cached mission recording after live-radio failure | Twelve years ago, I couldn't fix that relay. Will you help me finish it? |
| C7-F | Rafi | The crew is safe in this checkpoint. Check which wave exceeded our planned shelter level. |

**Progress:** crew exposure within scenario limit, viable garden/food crop, seeds secured. Stars: crew safety; no blackout; garden/seeds protected. Golden: all plus no emergency recovery. **Upgrade:** relay parts kit or long-range rover battery. **Evidence:** STEREO-A profile and historical storm records; fiction and game thresholds are visibly separated.

### Chapter 8 — The Lighthouse

**Entry:** around April 2047, explicitly one polar season cycle after Night One. Ferreira is physically at the station for this expedition; show her arrival in the opening so the former Earth-only instructor does not teleport into a rover. **Goal:** keep the base crew safe through the returning night and restore the Malapert relay before the communication deadline. **Toy:** two teams, a shared plan and dish aiming. **Flow (42 min):** expedition briefing 4 → base/route plan 7 → three alternating trek/base phases 15 → repair/aim/link 6 → Noor call and first garden sunrise 5 → debrief/credits/post-credit drawer 5.

Trek team: Ferreira and two cadets; base team: two cadets. Two controllable cadets leave the base, so the oxygen ledger separates base and rover occupants; it never counts six crew or forgets travellers. Solo switches at safe checkpoints. Class roles receive route readings and base status on separate cards; the station simulation pauses during view changes. Network play, if later implemented, retains one shared scenario clock.

Represent the roughly 120-km fictional expedition with three playable route sections and labelled travel transitions. The trek shows preparation and communication obstacles, not dozens of minutes of empty driving. Starting rover battery 14, reserve 2 [G]. Standard path uses 10 total travel/heat/repair units; long-range battery adds 4 capacity. Two optional evidence detours cost +1 each and are never necessary. Base uses the Chapter 1 night recipe adapted to the two occupants and owned upgrades; the Mission Table publishes those rates.

At the relay: inspect connector → fit the existing parts → power check → aim azimuth/elevation → acquire → confirm uplink. Parts kit removes one connector fault; it does not auto-complete aiming. Dials aim at the Horizons-derived Earth target. Acquisition succeeds within an accessible 5-degree teaching tolerance for a steady two seconds [G], with Engineer Mode showing the exact target and labelling that tolerance as a game abstraction. Interrupted contact resumes at the last verified repair stage. The countdown starts after briefing and pauses during dialogue; it cannot expire during a mandatory cutscene.

| ID | Speaker | Line |
|---|---|---|
| C8-01 arrival | Ferreira | I couldn't finish this twelve years ago. Today, we finish it together. |
| C8-02 | Kai | The base has its night plan. The rover has its return reserve. |
| C8-03 | Amara | Two here, two in the rover. I've updated both air budgets. |
| C8-04 | Rafi | Beacon route confirmed. No one disappears behind a ridge without a link plan. |
| C8-05 | Mei | We know this night now. Keep the garden ready for First Light. |
| C8-06 connector | Ferreira | Power is stable. Give me Earth's position, not a guess. |
| C8-07 link | Amara | Signal acquired. Confirm the uplink. |
| C8-08 live call | Noor | Hello, Aurora. This is Noor. |
| C8-09 rooftop | Noor | You did what I couldn't. |
| C8-10 | Mei | Alo means light. So does Noor. |
| C8-11 first garden | Ferreira | You didn't survive the Moon. You grew it. |
| C8-12 after credits | Noor | There's one drawer in the vault you haven't opened. |
| C8-13 drawer label | On-screen | MARS |
| C8-F | Ferreira | The connector is repaired. Restore the aiming checkpoint; our work isn't lost. |

Show Noor on a rooftop in Bangladesh, then the Moon garden at sunrise, including cotton alive. No retcon revives the original Alo; these are descendants. **Progress:** base and rover crew safe, relay operational, garden viable. Stars: both team safety budgets; no blackout; verified link/garden. Golden: all plus unused emergency reserve. Unlock Moon Garden, Live Sky, optional Storm Watch and the collection replay menu. Season 2 is a tease, not another compulsory chapter.

## 8. Campaign budget and upgrade contracts

The campaign uses authored mission snapshots; months between chapters are transitions with a transparent ledger. Persistent state: upgrades, seeds, family tree, relationships, collectibles and accomplishments. Battery/oxygen cannot remain at zero across an unexplained five-month jump; chapter entry shows repaired/refilled quantities and their fictional logistics context. No real-world waiting or offline resource decay.

Chapter 1 is the fixed numerical baseline above. Later chapters have the explicit toy budgets in section 7; longer elapsed time uses per-day crew consumption and scheduled harvest records rather than multiplying the seven-shift recipe across months. Public builds bundle the scenario sheet and its applied upgrades. Release gates require a successful path for every reachable upgrade combination; this is a test requirement, not a result already obtained.

**Baseline chapter entry profiles [G], before earned upgrades:** each sampled full operational shift uses 7.2 scenario hours, basics 1, breathing 1 for four crew, and the original heat/light/oxygen costs. Each row's reserves come from the visible chapter-entry logistics ledger, not an unexplained carryover reset. Start H=6 and C=8 unless the story state explicitly uses descendants; those values describe the current plants, not resurrection of the original Alo. W=0 and K=0 at prepared chapter entry, except Chapter 7's planned shelter preparation. R is crew-days.

| Chapter | Sampled operations | E start / cap | A start / cap | R start | Baseline solar / preparation | Additional hazards and action costs |
|---|---|---|---|---:|---|---|
| 1 | 7 full shifts | 14 / 20 | 6 / 10 | 12 | +8 in 1–2; zero in 3–7 | Section 6; two radiation samples |
| 2 | 3 sampled daylight shifts across the flowering dates | 14 / 20 | 10 / 10 | 18 | +8 per sampled shift | Each reciprocal route cycle adds E-1/A-1, once; three cycles |
| 3 | 4 investigation shifts, then dated dry-down transition | 14 / 20 | 10 / 10 | 18 | +8 per sampled daylight shift | Unresolved leak A-1 each; wrong isolation A-1; repair command otherwise no extra energy |
| 4 | 2 base shifts plus the rover's separate leg ledger | 14 / 20 | 8 / 10 | 18 | +8 per sampled base shift | Rover starts 16/cap 20; eight legs, two shadow surcharges, scan/release total 2 |
| 5 | 3 observation/maintenance shifts | 14 / 20 | 8 / 10 | 18 | +8 until dust; +6 while dust penalty active | Micro-leak A-1 per unresolved shift; verification/cleaning have no hidden extra resource fee |
| 6 | 5 variable-length eclipse segments | 14 / 20 | 8 / 10 | 18 | Supply follows verified curve; teaching fallback labelled [E] | Scale normal demand by segment-hours/7.2; consume rations by actual segment duration |
| 7 | 6 dark storm shifts after two preparation commands | 30 / 32 | 10 / 10 | 18 | No free daylight income; two initial W transfer commands available | Three-wave factors [1,1,2,2,1,1]; secure seed case before phase 3 |
| 8 | 5 dark base shifts, 3 trek sections and repair/aim stage | 20 / 26 | 6 / 10 | 18 | No base solar during sampled night | Base breathing 0.5 per shift for two cadets; rover air ledger covers the other two; rover E=14, standard route/repair cost 10 |

These are labelled teaching profiles until source time samples replace the assumed illumination. For Chapters 2–5, background days between sampled operations are represented in the dated food/oxygen/supply ledger, not ignored. The implementation must apply an explicit transition record or prevent a time skip. For Chapter 6, a fallback occultation duration remains an estimate, with an actual precharge/postcharge interval displayed; do not fabricate precise horizon visibility. Source integration may change income/timing and therefore requires rebalance before a release claiming real computed events.

**Food-resupply policy:** starting stock covers each sampled mission and its defined travel. Scheduled background resupply is disclosed at chapter entry. During an active mission no invisible refill occurs. Harvest contributions use actual story elapsed days and the documented crop maturity schedule. A crop failure lowers the projected dietary contribution and requires supplies in the ledger; it does not cause sudden starvation in a short emergency. Chapter 7's viable crop objective makes production capacity itself worth protecting.

**Explicit mastery thresholds [G]:** Chapter 2 full pollen coverage means all three reciprocal cycles; Chapter 3 diagnostic star allows at most one wrong isolation, with Golden requiring none; Chapter 4 safety star requires no over-limit slope and return reserve >=2; its communication Golden requires all three planned beacons before blind corners. Chapter 5 observation star allows no false report and at least six verified flashes; Golden requires all eight. Chapter 6 plan star requires acknowledgement of all five segments before commitment; reserve for Golden is E>=2 at recovery. Chapter 7 safe exposure is <=6, and Golden means no failed response or emergency checkpoint recovery in the recorded successful run. Chapter 8 safety star requires both air ledgers positive and rover reserve >=2; link/garden star requires confirmed uplink and live garden. No-blackout stars use the exact Chapter 1 boundary in every chapter. Restarting for accessibility/practice does not erase previously earned rewards; the current run's mastery record is honest about recovery use.

| After | A / explicit effect [G] | B / explicit effect [G] |
|---|---|---|
| Ch 1 | Taller mast: +2 daylight income per full planning shift | Fuel-cell battery: energy cap +6; entry reserve includes +4 |
| Ch 2 | Red-blue LEDs: FULL costs 1 instead of 2 | Insulation blankets: COOL causes no Alo cold damage |
| Ch 3 | Moon-dirt shelter: permanent +1 effective shielding, no water | Flexible seals: unresolved leak loss reduced from 1 to 0.5 per phase |
| Ch 4 | Ice harvester: 2 shelter-water units come from a separate labelled reserve, so W water from garden is reduced accordingly | Rover lights/heater: shadow/heater leg surcharge reduced by 1, minimum 0 |
| Ch 5 | Dust Shield: prevents the Chapter 5 dust-income penalty and later equivalent events | Whipple bumper: prevents the Chapter 5 micro-leak and later small-impact leak events |
| Ch 6 | Storm early warning: one extra preparation phase before Chapter 7's first wave; no extra fictional solar income | Bigger Safe Room: full STACK grants 3 crate shielding instead of 2 |
| Ch 7 | Relay parts kit: skip one connector diagnosis/repair stage | Long-range battery: rover capacity and entry charge +4 |

Modifiers stack only once and persist. Effective shielding stays capped at 6 in the teaching dose table. Water remains conserved across garden, local reserve and shelter. Retrofit changes have visible station models; the appearance is evidence of the choice, not a new decorative purchase system.

## 9. Optional content, collections and dialogue

Station Days: no timer, no loss state, no automatic consumption. Talk, decorate garden, name sprouts, inspect logs, choose earned upgrades, review evidence and write a local letter home. A calm "Good night, Alo" screen ends every chapter. No ads, paid content, loot boxes, streaks, push notifications or off-screen plant suffering.

**Eight side activities** preserve the original subjects, each 3–5 minutes. Mechanics are optional and do not affect mission survival:

| Activity | Interaction | Required conversation |
|---|---|---|
| Who Ate the Tomato? | Inspect three storage clues and find the missing tagged tomato | Rao: "Before we blame anyone, let's check the evidence." Amara: "Found it. The record gets corrected." |
| Hammer and Feather | Release both objects together; inspect landing replay | Rafi: "One release. Same height." Kai: "No air resistance here to hold the feather back." |
| Moon Golf | Aim a broad shot and compare two launch settings | Kai: "One small swing." Ferreira: "And one useful question: what changed the distance?" |
| Space Tacos | Inspect crop harvest card and assemble ingredients | Mei: "A harvest we can eat." Rao: "Science tastes better with a tortilla." |
| Earthrise | Frame the source-driven rising Earth in photo mode | Amara: "The position changed slowly. Check the date, not just the picture." |
| The Bubble Record | Run a sealed indoor demonstration and compare observations | Amara: "Low gravity isn't zero gravity. Let's measure the difference." |
| Birthday on the Moon | Decorate a prepared cake; inspect a labelled cooking thought experiment | Kai: "A birthday needs candles in the picture, not an open flame in the habitat." |
| Letters Home | Write or choose a local postcard; transmit fiction only when Earth is visible | Mei: "Tell them what you learned, and what you miss." |

**24 log catalogue:** one main story log, one hidden Station Days log, one reflective/failure log per chapter. Main lines already appear in section 7; these are the complete additional lines. Reflective logs unlock after an objective failure or after a post-success diagnostic simulation, so completion does not require intentionally harming Alo. Players can always collect all logs without destructive replay.

| Ch | Hidden log | Reflective log |
|---|---|---|
| 1 | N.: "A drawer is a small place to leave a big hope." | N.: "My first garden froze too. Ask what needed warmth before asking who failed." |
| 2 | N.: "I kept a picture of yellow fields beside the greenhouse window." | N.: "A flower can be healthy and still need a partner. Check what the task actually asks." |
| 3 | N.: "The old garden has a door. I hope someone opens it when they're ready." | N.: "Two uncertain readings can tell you more than one confident guess." |
| 4 | N.: "Leave a way back. That is true for a rover, and for a seed." | N.: "The safest discovery is the one you bring home with the crew." |
| 5 | Noor: "Ferreira remembers the radio. I remember that she brought us home." | Noor: "An observation can be corrected. A mistake becomes useful when you record why." |
| 6 | Noor: "I saved the eclipse timetable long before I saved the photograph." | Noor: "Known darkness is a planning problem. Put the demand beside the forecast." |
| 7 | Noor: "The seeds were not my last garden. They were someone else's first." | Noor: "Protect the reserve before the peak, not after it has already passed." |
| 8 | Noor: "A relay is a promise that silence can end." | Noor: "The first repair does not have to be perfect. It has to be checked." |

**32 data cards:** four per chapter, earned through its evidence interactions; their text has a one-line finding, source, measurement/estimate tag and a "how this affected your mission" link.

| Ch | Four cards |
|---|---|
| 1 | LROC illumination; LOLA/Horizons horizon and night; DONKI timeline; CRaTER dose profile |
| 2 | Mir pollination record; Fast Plants cross-pollination; growth timeline; stem-genetics evidence |
| 3 | Apollo seismogram; uncertain epicentre; LRO fault map; dry-down/life-cycle record |
| 4 | LOLA slope; ShadowCam image; LCROSS water result; Diviner/VIPER environment card |
| 5 | Impact observation record; LROC new-crater comparison; lunar dust; Dust Shield demonstration |
| 6 | Eclipse catalog; topocentric visibility; thermal response evidence; atmospheric red-ring explanation |
| 7 | STEREO-A storm profile; 1972 storm context; shielding guidance; dry-seed space experiment |
| 8 | Malapert topography; Earth-pointing ephemeris; relay line of sight; lunar-network concept |

**16 seed collection IDs:** Alo purple-stem Fast Plant, Tara green-stem Fast Plant, Tori mustard, rice, Arabidopsis, duckweed, zinnia, red romaine lettuce, chile pepper, radish, dwarf tomato, SEEDS tomato, super-dwarf wheat, zucchini, sunflower and cotton. Preserve the sourced fact cards from the campaign; no invented lunar cultivation history. The twelve story seeds in the vault are a subset, not a contradictory new sixteen-seed capsule. Other seeds are existing story/side-activity rewards. Cotton is visible in the finale regardless of optional collection completion; claiming its card is optional.

**12 patches:** eight chapter completions plus Silent Night (Chapter 1 without hints), Clear Signal (Chapter 4 planned beacon coverage), Careful Observer (Chapter 5 perfect verification), and Garden Keeper (complete all eight chapter garden objectives). **Eight postcards:** Last Light, Earth-set, first bloom, old frozen garden, ice investigation, impact flash, red ring, Earth over Malapert. **Family tree:** approximately nine generations, source-timeline-based naming; no fixed genotype ratio invented from purple/green appearance. **Mastery:** 24 stars and eight Golden Blooms; story completion does not require them.

**Postgame:** Moon Garden decoration has no failure; Live Sky reads precomputed offline ephemerides and shows their valid date range; Storm Watch is opt-in, needs internet and displays only in-app new replay missions with provenance. No notifications or accounts. Local letters and student actions remain on the device; Class Mode stores no student identities.

## 10. Learning, NASA challenge fit and scientific presentation

The verified 2026 [challenge summary](https://www.spaceappschallenge.org/2026/challenges/build-a-junior-astronaut-mission-trainer/) asks students to operate a lunar/Martian outpost while balancing life support, radiation shielding, power and food production. This is an educational mission trainer, not professional astronaut certification.

| Requirement | Playable evidence | Debrief evidence |
|---|---|---|
| Outpost operation | Inspect, plan, operate and maintain station systems | Decision timeline and objective result |
| Life support | Oxygen reserve, breathing, leaks, thermal decisions | Units, readings, failure cause |
| Radiation shielding | Preparation, W/K trade-off and return of garden water | Source storm profile beside game exposure |
| Power | Day production, overflow, capped storage, blackout boundary | Demand/supply trace and one-change replay |
| Food production | Crop condition, real growth delay, stored rations, harvest forecast | Crop-protection decision and future yield |
| Young learners | Icon/word interface, assistance, local classroom roles | Explain one decision in their own words |
| NASA data | Bundled source-derived events actually read by the simulation | Trace from data field to player consequence |

Use the science/data plan as the source registry. LROC marks the chosen site; LOLA supplies a local horizon; Horizons supplies Sun/Earth positions; DONKI supplies historical event records; CRaTER supplies the measured profile with orbit/surface limitations explained. Do not promise the fictional base's exact dose as a direct CRaTER surface measurement. BVAD and plant references supply unit context. The terrain and sky in the current pitch renderer are concept art until connected to processed data.

Each data asset includes URL, retrieval date, license/credit note, raw identifier, processing version and units. The simulation field consuming it is documented. Select site coordinates and an actual compatible visibility interval before calling the night "computed from NASA data". The story's approximate 36-hour interval is preserved as a scenario if exact computation is not ready, with [E]/[G] labels. The 2047 eclipse's local view and claimed Dhaka sunrise association require geometry/horizon verification. A missing source file is an explicit fallback/estimate, never a fabricated live API result.

**Debrief order:** crew outcome → resource and crop timeline → role information/acknowledgements → one-change replay → real source cards → four team-skill badges (communication, situational awareness, decision making, team care). Badges require logged actions; no certification claim. After an air failure, debrief uses saved checkpoint evidence rather than a live radio voice during Earth-set.

**Classroom use:** one chapter per week for eight weeks, with Fast Plants alongside the existing curriculum plan. Measure a short pre/post concept check, observed decision explanation, usability issues and desire to replay. Report real sample sizes and results only after testing. No invented learning-improvement percentage or winning probability.

## 11. Godot implementation, assets, saves and performance

Use **Godot 4.7.2 stable + GDScript**, same version for all contributors; [official release](https://godotengine.org/download/archive/4.7.2-stable/). Target Windows offline first. Use Compatibility as the baseline for older classroom hardware and a later web route; [renderer documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html). Web currently uses Compatibility and needs a separate export/hosting test; do not assume every native feature or offline cache works identically. GDScript avoids current Godot 4 C# web-export restrictions; [web export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

Proposed project modules, to be created during the permitted implementation period:

```text
game/
  project.godot
  scenes/        station, cadets, equipment, rover, chapters, UI
  scripts/       simulation, interaction, camera, missions, dialogue, save
  resources/     chapter profiles, dialogue/localisation, items, upgrades
  data/          raw-source registry and processed offline mission data
  assets/        game-ready GLB models, textures, audio and fonts
```

Simulation is independent of rendering: one authoritative state, validated commands, pure preview/step calculation, deterministic event IDs and logs. ChapterDirector schedules events; Interactable objects submit commands; HUD/actors observe results. DialogueController handles IDs and visibility; CampaignState handles persistent collections/upgrades; SaveService versions snapshots. CharacterBody3D, Camera3D/SpringArm3D, Areas/ray queries and animation state transitions form the movement/interaction layer. Rover uses a simple controlled movement implementation first; sophisticated wheel physics is not a milestone requirement.

Use [glTF/GLB imports](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html), inspect scale, rig, textures, pivots and collision. Tripo props and Mixamo motions may need cleanup/retargeting. Keep models separate from scripts through inherited scenes or wrappers. PNG portraits are optional UI assets, not substitutes for playable characters. Existing Blender scripts remain film tools; do not modify them to masquerade as game code.

**Minimum required assets:** modular station shell/interior, four cadets sharing a compatible animation set, Alo and Tara growth states, crop rack, controls/tanks/battery, water panels and crates, airlock, masts, small terrain/horizon, old terminal/packet and UI. Later assets: rover, beacons, scanner/patches, vault, observation tool, relay, cotton/garden expansion and Noor's rooftop shot. Art follows the existing white/navy/orange suits, Bangladesh patch, mustard gold, water blue and readable role accents.

Performance targets [G]: 720p at 30 fps on a named classroom test laptop, 1080p on the presentation PC; these are goals, not verified specifications. Profile early. Use small scenes, simple collisions, limited simultaneous shadowed lights, restrained transparency, shared materials and appropriate mesh detail. The pitch's thousands of field plants become instanced/batched visual vegetation; do not turn every flower into a physics object. Character animations and material counts matter as much as polygon count. High-quality film renders are separate from baseline game settings.

Saves occur before every committed shift, after story rewards, on chapter completion and at safe expedition checkpoints. Include resources, role positions, active task progress, event flags, item transactions, upgrade IDs, plant generations, food ledger, seed/log/card/patch/postcard IDs and dialogue history. Keep checkpoint snapshot separate from persistent achievements. Retry never duplicates harvests or rewards. A corrupt save offers the last valid backup. No real-time clock advances the garden when the game is closed.

## 12. Delivery order and release acceptance

| Milestone | Deliverable | Pass condition |
|---|---|---|
| M1 | One greybox room, character and camera | A novice walks and interacts without getting stuck |
| M2 | One console, valve, simulation shift and preview | Preview equals committed result; costs occur once |
| M3 | Complete seven-shift Chapter 1 | All endings reachable; checkpoint restores exact state |
| M4 | Story, food layer, data and debrief | Canonical ordering, future harvest trade-off, source trace |
| M5 | Class roles, accessibility and offline export | One laptop/projector usable; no mandatory internet |
| M6 | Season map and optional Chapter 2 sample | Locked content labelled; first chapter remains complete |
| M7 | Remaining chapters, upgrades and collections | Full 220–250-minute route and fair alternative paths |

Six-person responsibility split: simulation/save; Godot movement/interaction; environment/animation; NASA data/science; chapter tasks/UI/debrief; dialogue/localisation/video/project page. Share a parameter sheet and object contract first. Before the hackathon, keep work within allowed preparation/design scope in [competition-rules.md](competition-rules.md); verify the local/global rule interpretation with the published event instructions. This task adds documents only.

**Necessary acceptance cases:** E exactly 0 versus below 0; overflow before spending; oxygen cap/breathing order; conserved garden/shelter/reserve water; crates not causing thirst; shift-6 exposure before drain; no resurrection after plant death; PUMP/STACK resolving once; retry not duplicating charges/rewards; radio silent when Earth is down; canonical seed count and name reveal; food not growing instantly; both occupants ledgers in Chapter 8; each upgrade combination with a safe path; assistance yielding the same conceptual outcome; source absence visibly marked; no hidden resource loss while reading or changing camera.

For each chapter record actual novice completion time, failures, confusing controls and decision explanations. Adjust traversal, hinting and numbers inside the locked story/length constraints. Public release notes distinguish implemented features, tested evidence and roadmap. The associated [final video pitch plan](../pitch-video/VIDEOPITCH_FINAL.md) uses exactly the same promises and makes no guaranteed-winning claim.
