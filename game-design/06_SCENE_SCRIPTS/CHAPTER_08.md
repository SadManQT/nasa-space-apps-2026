# Chapter 08 — The Lighthouse

Purpose: Bring the voices and the garden through darkness together.

## Script execution contract

Each section is a fully authored scene. Lines are exact English master dialogue; bracket-free speaker labels identify characters. NOO before Chapter 5 is an archive-only voice labelled “N. (recording)” in player-facing captions. The cadets do not know the author’s identity yet; Ferreira and Rao know the seed legacy but leave its personal connection for the Chapter 5 reveal. Safety information is always shared. Remote speakers use screens/radio, not physical NPCs. Alo and Tara react visually and never have dialogue. Critical speech has caption/read-transcript parity. The dialogue master is indexed by line ID. Scene gates are mandatory, ordered and saved; cinematic skipping acknowledges dialogue but never bypasses a puzzle or fakes a physical interaction.

<a id="sc-0801"></a>
## SC-0801 — Before the Road

- **Chapter / mission:** CH08 / [M-0801](../07_MISSION_DESIGNS/M-0801_The_Long_Road.md)
- **Location / time:** LOC-08 / Apr 8 00:00
- **Cast / presence:** Physical: Commander Ferreira, Kai, Rafi, Mei, Amara. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Start a long journey with a visible handover.
- **Opening:** The rover cabin is lit while Aurora remains partly sunlit.
- **Environment:** Three occupied seats, 120-km route map, 72-hour independent supplies.

### Exact dialogue

- **DL-0801-01 · RAF:** “Outbound twenty-four hours. Repair window three. Return twenty-four.”

- **DL-0801-02 · AMA:** “Home reserves cover thirty-six dark hours, plus margin.”

- **DL-0801-03 · MEI:** “I have the garden.”

- **DL-0801-04 · KAI:** “We’ll call at every marker.”

- **DL-0801-05 · FER:** “No hero shortcuts. We have a road.”


### Play and presentation

- **Player objective:** Check seventy-two-hour supplies and depart on the surveyed road.
- **Player interactions:** Start P-15 loadout and route confirmation; verify 72-hour supply indicator and 120-km destination; close airlock after farewells.
- **Actions / animation:** Passengers buckle; Mei touches the closed cabin window from the habitat side.
- **Camera:** One wide departure, then player rover control.
- **Sound / atmosphere:** Pressurisation and low wheel vibration; no engine roar in exterior vacuum.
- **Discovery:** Journey duration and supplies are explicit before the dramatic departure.
- **Journal copy:** The final route is 120 km each way. We budgeted 24 h outbound, 3 h repair and 24 h return.
- **Completion event EV-0801:** P-15 departure checklist validated AND rover airlock sealed.
- **Persistence:** Once the above predicate passes, mark `SC-0801_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0802; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-15](../08_PUZZLE_DESIGNS.md#p-15); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0802"></a>
## SC-0802 — Markers in the Dark

- **Chapter / mission:** CH08 / [M-0801](../07_MISSION_DESIGNS/M-0801_The_Long_Road.md)
- **Location / time:** LOC-11 / Apr 8 00:00–17:00 outbound
- **Cast / presence:** Physical: Kai, Rafi, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Let navigation prove the crew’s growth.
- **Opening:** Cruise time-lapse stops at a damaged repeater marker.
- **Environment:** Surveyed ridge, slope warning, three repeater pads and long terrain shadows.

### Exact dialogue

- **DL-0802-01 · KAI:** “Marker two is dark.”

- **DL-0802-02 · RAF:** “Its pad is sound. The bypass is a cliff route.”

- **DL-0802-03 · FER:** “Replace the repeater battery. Keep the surveyed road.”

- **DL-0802-04 · KAI:** “Small light. Known road. I can do this.”


### Play and presentation

- **Player objective:** Restore marker two and verify the repeater chain.
- **Player interactions:** Complete route segment of P-15: stop within pad zone, set brake, replace repeater battery, confirm adjacent link and continue via all three markers.
- **Actions / animation:** Ferreira holds the cabin checklist while Rafi checks suit seal; player performs a short tethered repair.
- **Camera:** Horizon-locked driving and optional guided cruise; no forced roll over rough terrain.
- **Sound / atmosphere:** Cabin hum, local radio pings, exterior suit breathing.
- **Discovery:** Repeaters create the necessary Aurora-to-summit link; the route is useful infrastructure.
- **Journal copy:** The road repeaters will let the summit hear Aurora. We restored the dead marker before continuing.
- **Completion event EV-0802:** All three repeater links passed AND100-km approach marker reached at Apr 8 17:00; remaining cruise waits for the home-team handover.
- **Persistence:** Once the above predicate passes, mark `SC-0802_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0803; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-15](../08_PUZZLE_DESIGNS.md#p-15); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0803"></a>
## SC-0803 — Two at Home

- **Chapter / mission:** CH08 / [M-0801](../07_MISSION_DESIGNS/M-0801_The_Long_Road.md)
- **Location / time:** LOC-03 / Apr 8 18:00 → Apr 9 00:00
- **Cast / presence:** Physical: Mei, Amara. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Give the home team equal ownership of the climax.
- **Opening:** Viewpoint changes with a clear AURORA / MEI card as the Sun leaves.
- **Environment:** Garden shutters, dry reserve box, cotton leaves and original petal.

### Exact dialogue

- **DL-0803-01 · AMA:** “Same darkness. Different garden.”

- **DL-0803-02 · MEI:** “Different us.”

- **DL-0803-03 · AMA:** “Return line open. Air reserve steady.”

- **DL-0803-04 · MEI:** “Alo, your children are terrible at staying small.”

- **DL-0803-05 · AMA:** “A measurable success.”


### Play and presentation

- **Player objective:** Set the home garden loop and acknowledge summit arrival.
- **Player interactions:** Finish P-15 home handover: set garden minimum heat, dim lamps, return loop OPEN and verify two independent pressure readings; acknowledge summit arrival packet.
- **Actions / animation:** Mei adjusts a nameplate; Amara repeats the old manual gauge check calmly.
- **Camera:** No travel teleport: cut between fixed home team and rover arrival timestamp.
- **Sound / atmosphere:** Garden fans and faint local packet ping; warmth in music.
- **Discovery:** Home safety is maintained through established procedures while the relay team works.
- **Journal copy:** Mei and Amara kept minimum heat, dim lamps and the return loop open while the field team reached Malapert.
- **Completion event EV-0803:** P-15 home checks valid AND summit packet received; commit M-0801.
- **Persistence:** Once the above predicate passes, mark `SC-0803_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0804; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-15](../08_PUZZLE_DESIGNS.md#p-15); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0804"></a>
## SC-0804 — The Lighthouse

- **Chapter / mission:** CH08 / [M-0802](../07_MISSION_DESIGNS/M-0802_From_Last_Light_to_First_Light.md)
- **Location / time:** LOC-12 / Apr 9 00:00–02:00
- **Cast / presence:** Physical: Kai, Rafi, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Make the player physically restore the connection.
- **Opening:** The relay dish stands dark against a bright edge of terrain.
- **Environment:** Controller bay, local antenna, Earth dish, tether anchors and clear replacement serial.

### Exact dialogue

- **DL-0804-01 · FER:** “Same housing. Better spare. Power isolated?”

- **DL-0804-02 · KAI:** “Verified.”

- **DL-0804-03 · RAF:** “Tether set. Local repeater chain is green.”

- **DL-0804-04 · FER:** “Replace the controller. Then local link, then Earth.”

- **DL-0804-05 · KAI:** “One voice at a time.”


### Play and presentation

- **Player objective:** Replace the controller and lock the local and Earth links.
- **Player interactions:** Complete P-16 isolate/test/replace/close/reconnect; tune the local link, then the Earth dish’s azimuth/elevation dials; verify checksum round trip as Aurora’s Earth-set handover window closes. Assisted presets and untimed confirmation have identical results.
- **Actions / animation:** Ferreira braces the service door; Rafi watches the tether; Kai seats controller.
- **Camera:** Interactive shoulder camera; wide dish movement only after player confirms.
- **Sound / atmosphere:** Connector clicks, transmitted servo vibration and radio lock tone.
- **Discovery:** Repair uses the planned spare and earlier repeaters; sight of Earth alone is insufficient.
- **Journal copy:** The relay passed both links and returned the ALO42 checksum. Seeing Earth alone was not enough.
- **Completion event EV-0804:** P-16 dual-link lock and checksum passed; set relay_live_pending.
- **Persistence:** Once the above predicate passes, mark `SC-0804_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0805; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-16](../08_PUZZLE_DESIGNS.md#p-16); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0805"></a>
## SC-0805 — Hello, Aurora

- **Chapter / mission:** CH08 / [M-0802](../07_MISSION_DESIGNS/M-0802_From_Last_Light_to_First_Light.md)
- **Location / time:** LOC-12 / Apr 9 02:00–03:00; return Apr 10 03:00
- **Cast / presence:** Physical: Commander Ferreira, Kai, Rafi. Remote: Mei (Aurora), Amara (Aurora), Dr. Noor Rahman, Rao (Earth). Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue + short skippable cinematic.
- **Narrative purpose:** Pay off Noor’s chosen return and reunite both teams.
- **Opening:** The player presses Transmit after seeing Aurora’s acknowledgement.
- **Environment:** Split call: summit cabin, Aurora table, Noor’s rooftop on Earth; no continuous exterior conversation without suits.

### Exact dialogue

- **DL-0805-01 · NOO:** “Hello, Aurora. This is Noor.”

- **DL-0805-02 · MEI:** “We kept a place for you.”

- **DL-0805-03 · NOO:** “You did what I couldn’t.”

- **DL-0805-04 · FER:** “You brought us the seeds. And you came home with us.”

- **DL-0805-05 · AMA:** “The garden has more than one gardener.”

- **DL-0805-06 · KAI:** “So does the light.”

- **DL-0805-07 · MEI:** “Alo means light. So does Noor.”

- **DL-0805-08 · RAF:** “Then we know the way back.”


### Play and presentation

- **Player objective:** Verify both voices, send telemetry and bring the rover home.
- **Player interactions:** Confirm Aurora and Earth voice checks, send garden telemetry to Noor, accept a dated 24-hour return montage after all crew are back inside rover.
- **Actions / animation:** Noor speaks voluntarily; crew smiles rather than applauds; return follows the same road.
- **Camera:** Optional 35 s call cinematic intercut at breaths; skippable transcript preserves all facts.
- **Sound / atmosphere:** Radio delay respected with brief gaps; Noor/Alo themes join without overpowering words.
- **Discovery:** The mystery resolves into a relationship; all expedition members survive and physically return.
- **Journal copy:** Noor answered in her own name. Both teams spoke. The rover returned after its planned 24-hour drive.
- **Completion event EV-0805:** Both voice checks AND telemetry acknowledged AND return montage confirmed; crew location set Aurora at Apr 10 03:00.
- **Persistence:** Once the above predicate passes, mark `SC-0805_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0806; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-16](../08_PUZZLE_DESIGNS.md#p-16); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0806"></a>
## SC-0806 — What We Grew

- **Chapter / mission:** CH08 / [M-0802](../07_MISSION_DESIGNS/M-0802_From_Last_Light_to_First_Light.md)
- **Location / time:** LOC-03 / Apr 10 06:00 and epilogue
- **Cast / presence:** Physical: Mei, Kai, Amara, Rafi, Commander Ferreira. Remote: Dr. Noor Rahman. Archive: none.
- **Mode:** Exploration + scripted conversation + short skippable cinematic.
- **Narrative purpose:** Give the player the final act and a complete ending.
- **Opening:** The viewing shutter waits at the same place as the first bloom.
- **Environment:** Mustard descendants flower inside a pressurised garden; cotton is alive; Alo’s petal and lineage label remain.

### Exact dialogue

- **DL-0806-01 · MEI:** “Temperature steady.”

- **DL-0806-02 · AMA:** “Air steady. Seeds safe.”

- **DL-0806-03 · KAI:** “First light.”

- **DL-0806-04 · RAF:** “Everyone here.”

- **DL-0806-05 · FER:** “You didn’t survive the Moon. You grew it.”

- **DL-0806-06 · NOO:** “Show me the little one by the window.”

- **DL-0806-07 · MEI:** “Cotton. Alive at sunrise.”


### Play and presentation

- **Player objective:** Verify the living garden, open the shutter and take the shared photo.
- **Player interactions:** Verify final five indicators, open shutter, take the shared photo, choose one dedication, then enter credits; after credits inspect the MARS drawer or return to garden.
- **Actions / animation:** Garden already exists; dawn reveals and warms it without causing instant biological growth. Photo includes Noor on screen.
- **Camera:** Echo SC-0106, now widen to include the whole living space; no teaser interrupts emotional landing.
- **Sound / atmosphere:** Full theme with room sounds; credits fall to a quiet reprise.
- **Discovery:** First established seed-renewing garden survives the next seasonal night; every central mystery has an answer.
- **Journal copy:** All five lunar crew returned safely. Founder seeds stayed protected. Mustard descendants flowered and cotton was alive at first light.
- **Completion event EV-0806:** P-16 final indicators passed AND photo saved AND dedication chosen AND credits available; commit campaign_complete. MARS inspection is optional.
- **Persistence:** Once the above predicate passes, mark `SC-0806_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Set campaign completion through M-0802; offer credits, safe-garden Continue and separate Chapter Replay.
- **References:** [puzzle P-16](../08_PUZZLE_DESIGNS.md#p-16); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).
