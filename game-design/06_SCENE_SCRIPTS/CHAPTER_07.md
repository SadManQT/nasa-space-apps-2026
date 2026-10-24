# Chapter 07 — The Great Storm

Purpose: The entire expedition applies what it learned.

## Script execution contract

Each section is a fully authored scene. Lines are exact English master dialogue; bracket-free speaker labels identify characters. NOO before Chapter 5 is an archive-only voice labelled “N. (recording)” in player-facing captions. The cadets do not know the author’s identity yet; Ferreira and Rao know the seed legacy but leave its personal connection for the Chapter 5 reveal. Safety information is always shared. Remote speakers use screens/radio, not physical NPCs. Alo and Tara react visually and never have dialogue. Critical speech has caption/read-transcript parity. The dialogue master is indexed by line ID. Scene gates are mandatory, ordered and saved; cinematic skipping acknowledges dialogue but never bypasses a puzzle or fakes a physical interaction.

<a id="sc-0701"></a>
## SC-0701 — A Warning We Share

- **Chapter / mission:** CH07 / [M-0701](../07_MISSION_DESIGNS/M-0701_Your_Call_Cadets.md)
- **Location / time:** LOC-01 / Feb 14, before 06:00
- **Cast / presence:** Physical: Rafi, Kai, Mei, Amara, Commander Ferreira. Remote: Rao (Earth). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Make preparation a culmination of shared information.
- **Opening:** A new forecast interrupts breakfast.
- **Environment:** All four role observations appear together on the table.

### Exact dialogue

- **DL-0701-01 · RAO:** “What if the great storm of July 2012 had hit the Moon? This historical replay uses STEREO-A’s measurements with a fictional lunar strike.”

- **DL-0701-02 · RAF:** “Three waves. Six planning steps. Crew, garden, seeds.”

- **DL-0701-03 · MEI:** “Seeds and plants have different shelter needs.”

- **DL-0701-04 · AMA:** “Air reserve first. Then scrubbers.”

- **DL-0701-05 · FER:** “Your call, cadets.”

- **DL-0701-06 · KAI:** “Read every observation. Nobody works from half a plan.”


### Play and presentation

- **Player objective:** Share the new warning and review the three-wave plan.
- **Player interactions:** Share current observations, inspect three-wave forecast and open P-13 integrated plan; photograph reserve seal.
- **Actions / animation:** No one keeps the warning private; each cadet places an observation card.
- **Camera:** One stable table-wide shot then free movement.
- **Sound / atmosphere:** Alert three notes distinct from quake; tension remains controlled.
- **Discovery:** The labelled 2012 counterfactual preserves the historical data source; lunar doses and damage are game/fiction values.
- **Journal copy:** A historical replay warning reached all four specialists. We planned together before the first wave.
- **Completion event EV-0701:** All current observations shared AND wave model inspected AND reserve photographed.
- **Persistence:** Once the above predicate passes, mark `SC-0701_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0702; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-13](../08_PUZZLE_DESIGNS.md#p-13); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0702"></a>
## SC-0702 — What Gets the Last Drop

- **Chapter / mission:** CH07 / [M-0701](../07_MISSION_DESIGNS/M-0701_Your_Call_Cadets.md)
- **Location / time:** LOC-04 / Feb 14 preparation
- **Cast / presence:** Physical: Kai, Amara, Mei, Rafi, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Require a coherent survival plan instead of separate minigames.
- **Opening:** The shelter door opens onto saved supplies and labelled water wall.
- **Environment:** Protected bus, seed container, water return bypass and shield rails coexist.

### Exact dialogue

- **DL-0702-01 · MEI:** “The living garden can wait in dim light. The reserve comes with us.”

- **DL-0702-02 · AMA:** “Scrubbers cannot wait.”

- **DL-0702-03 · RAF:** “Wall four. Bundles two. Door shut.”

- **DL-0702-04 · KAI:** “Isolate the radio’s exposed branch before the second wave.”

- **DL-0702-05 · FER:** “And say when the water comes back.”


### Play and presentation

- **Player objective:** Stage shielding, protect the reserve and verify the return schedule.
- **Player interactions:** Complete P-13 six-step schedule; load protected seed container; set base electronics isolation and return-pump priority.
- **Actions / animation:** Seed container latches inside the crew shelter; tools are stowed.
- **Camera:** Show spatial connections so decisions refer to real objects.
- **Sound / atmosphere:** Wall water, latch, quieter speech within shelter.
- **Discovery:** Old water-return failure informs a practical improvement.
- **Journal copy:** Our plan keeps essential loads running, protects the founder seeds and returns water after exposure.
- **Completion event EV-0702:** P-13 valid schedule verified AND seed reserve latched.
- **Persistence:** Once the above predicate passes, mark `SC-0702_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0703; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-13](../08_PUZZLE_DESIGNS.md#p-13); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0703"></a>
## SC-0703 — Everyone Inside

- **Chapter / mission:** CH07 / [M-0701](../07_MISSION_DESIGNS/M-0701_Your_Call_Cadets.md)
- **Location / time:** LOC-04 / Feb 14, first wave readiness
- **Cast / presence:** Physical: Rafi, Mei, Kai, Amara, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Make the crew visibly present and safe before time advances.
- **Opening:** The particle-rate indicator crosses the prepare threshold.
- **Environment:** Five seat markers, closed hatch confirmation, plant telemetry on local network.

### Exact dialogue

- **DL-0703-01 · RAF:** “Kai?”

- **DL-0703-02 · KAI:** “Here.”

- **DL-0703-03 · RAF:** “Amara? Mei? Commander?”

- **DL-0703-04 · AMA:** “Here.”

- **DL-0703-05 · MEI:** “Here. Garden feed is local.”

- **DL-0703-06 · FER:** “Here. Close it.”

- **DL-0703-07 · RAF:** “Five present. Closing.”


### Play and presentation

- **Player objective:** Account for five people and seal the shelter.
- **Player interactions:** Account for all five occupants and close shelter hatch; preview the first verified step of P-14 after presence lock; execution starts in the next mission.
- **Actions / animation:** Companions sit; no NPC remains walking outside during wave damage.
- **Camera:** Interior shoulder framing; optional wide view for counting.
- **Sound / atmosphere:** Hatch thunk and muffled station hum; no shouted roll call over music.
- **Discovery:** The mature team checks people before systems.
- **Journal copy:** All five of us are inside. The first wave has not been committed until we confirm the plan.
- **Completion event EV-0703:** Five occupants present AND hatch closed AND first wave step preview confirmed; commit M-0701.
- **Persistence:** Once the above predicate passes, mark `SC-0703_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0704; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-13](../08_PUZZLE_DESIGNS.md#p-13); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0704"></a>
## SC-0704 — The Last Log

- **Chapter / mission:** CH07 / [M-0702](../07_MISSION_DESIGNS/M-0702_What_We_Carry.md)
- **Location / time:** LOC-04 / Feb 14 06:00–Feb 16 01:12
- **Cast / presence:** Physical: Mei, Amara, Kai, Rafi, Commander Ferreira. Remote: none. Archive: Dr. Noor Rahman.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Pay off the meaning of Alo and the archived departure.
- **Opening:** A restored local recorder entry becomes available during the lull.
- **Environment:** Pressed petal image beside an intact protected seed container.

### Exact dialogue

- **DL-0704-01 · NOO:** “We’re leaving at last light. I’m calling the seeds Alo, light, so whoever finds them brings the light back.”

- **DL-0704-02 · MEI:** “She didn’t leave a success. She left a beginning.”

- **DL-0704-03 · FER:** “She left me a way to come back, too.”

- **DL-0704-04 · KAI:** “Then we keep this one.”


- **DL-0704-05 · FER:** “She named the Academy after that last light, so another crew could bring the garden through to sunrise.”

### Play and presentation

- **Player objective:** Run the storm steps and read Noor’s final log in the lull.
- **Player interactions:** Continue P-14 waves; listen/read final log once safely sheltered; compare plant and reserve telemetry before last wave.
- **Actions / animation:** Mei rests a glove beside the seed case; Ferreira watches without interrupting Noor.
- **Camera:** No flashback replacing player presence; show hands and present faces.
- **Sound / atmosphere:** Old recording becomes clean at key words; score holds a single sustained interval.
- **Discovery:** Noor named the seed hope before evacuation; her full personal arc is now available.
- **Journal copy:** Noor called the seeds Alo so someone could bring light back. Her recording is old; the reserve beside us is alive with possibility.
- **Completion event EV-0704:** Log heard/read AND second storm step committed AND reserve telemetry checked.
- **Persistence:** Once the above predicate passes, mark `SC-0704_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0705; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-14](../08_PUZZLE_DESIGNS.md#p-14); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0705"></a>
## SC-0705 — A Different Silence

- **Chapter / mission:** CH07 / [M-0702](../07_MISSION_DESIGNS/M-0702_What_We_Carry.md)
- **Location / time:** LOC-01 / Feb 16 01:12, then two clear readings
- **Cast / presence:** Physical: Kai, Amara, Rafi, Mei, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Turn failure into a specific repair objective.
- **Opening:** The storm meter drops; the Earth uplink remains dead.
- **Environment:** Local green network nodes contrast with failed external feedthrough F-EXT.

### Exact dialogue

- **DL-0705-01 · KAI:** “Local radios work. The dish branch doesn’t.”

- **DL-0705-02 · AMA:** “The isolation held inside. The external feedthrough still failed.”

- **DL-0705-03 · RAF:** “We wait for route clearance before stepping out.”

- **DL-0705-04 · FER:** “Malapert can bypass that branch. I know the old controller.”

- **DL-0705-05 · MEI:** “Then you’re coming with them.”

- **DL-0705-06 · FER:** “Yes. This time I bring the right spare.”


- **DL-0705-07 · FER:** “Twelve years ago, I couldn’t fix that relay. Will you help me finish it?”

### Play and presentation

- **Player objective:** Diagnose the external branch and verify route clearance.
- **Player interactions:** Finish P-14 diagnostics, identify external branch failure, confirm two consecutive safe-rate readings and inspect the relay bypass diagram.
- **Actions / animation:** Ferreira lays the relief-flight replacement controller on the table.
- **Camera:** Radio failure is shown by topology, not arbitrary static on every channel.
- **Sound / atmosphere:** Uplink static cuts; local voices persist; silence has a defined cause.
- **Discovery:** A replacement was delivered in December; both relay links and route repeaters are required.
- **Journal copy:** The external uplink feedthrough failed. Local radios survived. Two safe readings cleared travel to the relay.
- **Completion event EV-0705:** P-14 all waves complete AND two clear readings AND relay bypass inspected.
- **Persistence:** Once the above predicate passes, mark `SC-0705_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0706; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-14](../08_PUZZLE_DESIGNS.md#p-14); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0706"></a>
## SC-0706 — Who Stays With the Garden

- **Chapter / mission:** CH07 / [M-0702](../07_MISSION_DESIGNS/M-0702_What_We_Carry.md)
- **Location / time:** LOC-01 / Feb 16 03:00 → Apr 8 00:00
- **Cast / presence:** Physical: Commander Ferreira, Kai, Rafi, Mei, Amara. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Assign finale roles explicitly.
- **Opening:** Five names appear beside two destination boards.
- **Environment:** Rover seats three; home-team control board shows two stations.

### Exact dialogue

- **DL-0706-01 · FER:** “Kai, Rafi, with me. Mei and Amara hold Aurora.”

- **DL-0706-02 · MEI:** “We can do that.”

- **DL-0706-03 · AMA:** “We know exactly what the night costs now.”

- **DL-0706-04 · KAI:** “Keep the guide light on.”

- **DL-0706-05 · MEI:** “The small one. It’s in the plan.”

- **DL-0706-06 · RAF:** “I’ll bring the lamp back.”


### Play and presentation

- **Player objective:** Confirm the rover and home-team handover.
- **Player interactions:** Confirm team roster, spare controller, local repeater plan and minimum home reserves; sign the departure board. Confirm the dated February-to-April stable-care, route-survey and fabrication montage before final departure.
- **Actions / animation:** Two teams exchange duplicate route and shelter checklists.
- **Camera:** Hold all five before physically separating them.
- **Sound / atmosphere:** Resolve tension into determined travel motif.
- **Discovery:** There is no unassigned cadet or absent base operator in the finale.
- **Journal copy:** Ferreira,Kai and Rafi travel. Mei and Amara keep Aurora safe. We have the spare controller and a repeater route.
- **Completion event EV-0706:** Roster and cargo confirmed AND home reserve checks passed AND dated preparation montage accepted; commit M-0702 and route_clear.
- **Persistence:** Once the above predicate passes, mark `SC-0706_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0801; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-14](../08_PUZZLE_DESIGNS.md#p-14); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).
