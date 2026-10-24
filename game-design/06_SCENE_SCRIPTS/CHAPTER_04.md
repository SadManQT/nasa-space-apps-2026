# Chapter 04 — Into the Cold Trap

Purpose: Caution becomes leadership beyond home.

## Script execution contract

Each section is a fully authored scene. Lines are exact English master dialogue; bracket-free speaker labels identify characters. NOO before Chapter 5 is an archive-only voice labelled “N. (recording)” in player-facing captions. The cadets do not know the author’s identity yet; Ferreira and Rao know the seed legacy but leave its personal connection for the Chapter 5 reveal. Safety information is always shared. Remote speakers use screens/radio, not physical NPCs. Alo and Tara react visually and never have dialogue. Critical speech has caption/read-transcript parity. The dialogue master is indexed by line ID. Scene gates are mandatory, ordered and saved; cinematic skipping acknowledges dialogue but never bypasses a puzzle or fakes a physical interaction.

<a id="sc-0401"></a>
## SC-0401 — A Return Is Part of a Route

- **Chapter / mission:** CH04 / [M-0401](../07_MISSION_DESIGNS/M-0401_Where_the_Sun_Cannot_Follow.md)
- **Location / time:** LOC-08 / Oct 21 06:00
- **Cast / presence:** Physical: Rafi, Kai, Mei, Amara. Remote: Commander Ferreira (Earth). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Establish Rafi’s leadership and rover constraints.
- **Opening:** Rafi stands beside the pressurised rover checklist.
- **Environment:** Route board, reserve meter, sealed vault carrier and a marked return line.

### Exact dialogue

- **DL-0401-01 · RAF:** “I checked the route twice.”

- **DL-0401-02 · KAI:** “Only twice?”

- **DL-0401-03 · RAF:** “Three times. I wanted to sound relaxed.”

- **DL-0401-04 · AMA:** “I’ll be here. Send measurements, not brave noises.”

- **DL-0401-05 · FER:** “Rafi leads the field team. Coming back is part of the objective.”


- **DL-0401-06 · MEI:** “Our prediction is here. Let’s count what actually grew.”

### Play and presentation

- **Player objective:** Check the rover, carrier and base handover.
- **Player interactions:** Compare the saved stem prediction with the twelve descendants (seven purple, five green [F], no promised genetic ratio). Check rover seal, take scanner and closed carrier, leave Mei and Amara’s base handover and open P-07 route planning.
- **Actions / animation:** Rafi checks each passenger harness without a joke at his expense.
- **Camera:** Frame Rafi and Kai in two occupied seats, the third rover seat empty; Mei and Amara remain at the base handover screen.
- **Sound / atmosphere:** Rover pumps, harness snaps; outbound motif.
- **Discovery:** Rafi’s caution is recognised as leadership.
- **Journal copy:** Rafi and Kai take the field trip. Mei and Amara remain at Aurora. Our route must include a safe return.
- **Completion event EV-0401:** Seal, scanner, carrier and base handover checks complete.
- **Persistence:** Once the above predicate passes, mark `SC-0401_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0402; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-07](../08_PUZZLE_DESIGNS.md#p-07); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0402"></a>
## SC-0402 — Ice Is Evidence

- **Chapter / mission:** CH04 / [M-0401](../07_MISSION_DESIGNS/M-0401_Where_the_Sun_Cannot_Follow.md)
- **Location / time:** LOC-09 / Oct 21 morning
- **Cast / presence:** Physical: Rafi, Kai. Remote: Mei and Amara (Aurora local radio). Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Traverse and distinguish measured ice from a visual guess.
- **Opening:** The chosen ridge path curves away from a shorter steep descent.
- **Environment:** Hard shadows, headlamp cones, fixed survey beacons; no fog.

### Exact dialogue

- **DL-0402-01 · KAI:** “The short route is right there.”

- **DL-0402-02 · RAF:** “So is the slope limit.”

- **DL-0402-03 · MEI:** “Then we take the long route.”

- **DL-0402-04 · AMA:** “Scanner reference first. A bright patch is not a water report.”

- **DL-0402-05 · RAF:** “Dry reference recorded. Now the sample.”


### Play and presentation

- **Player objective:** Choose the safe ridge and verify the ice-bearing sample.
- **Player interactions:** Complete P-07 route B, reference scan and three-point ice-bearing sample comparison; place and test all three beacons before the blind corners. The base team’s slope map and rover team’s headlight view are separate role cards.
- **Actions / animation:** Wheels grip slowly; scanner contacts soil; sample remains in a sealed cup.
- **Camera:** Low horizon outside; horizon-locked rover camera available.
- **Sound / atmosphere:** Vehicle sounds via cabin/chassis, exterior EVA mostly suit sounds.
- **Discovery:** The survey supports ice-bearing soil, not instantly drinkable water or a complete mining system.
- **Journal copy:** The surveyed ridge meets our slope and reserve limits. Calibrated readings support ice-bearing soil.
- **Completion event EV-0402:** P-07 safe route and calibrated sample completed; ice_survey_pending.
- **Persistence:** Once the above predicate passes, mark `SC-0402_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0403; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-07](../08_PUZZLE_DESIGNS.md#p-07); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0403"></a>
## SC-0403 — Something With Corners

- **Chapter / mission:** CH04 / [M-0401](../07_MISSION_DESIGNS/M-0401_Where_the_Sun_Cannot_Follow.md)
- **Location / time:** LOC-10 / Oct 21 10:30
- **Cast / presence:** Physical: Rafi, Kai. Remote: Mei and Amara (Aurora local radio). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Reveal the vault as a human object in an ancient environment.
- **Opening:** A headlamp beam crosses a manufactured corner.
- **Environment:** Frost on an insulated box; an old survey marker matches the recovered map.

### Exact dialogue

- **DL-0403-01 · MEI:** “That shape didn’t grow here.”

- **DL-0403-02 · KAI:** “Neither did we.”

- **DL-0403-03 · RAF:** “No opening it outside. We lift the whole box.”

- **DL-0403-04 · MEI:** “Someone wanted it found. They also wanted it to survive being found.”


### Play and presentation

- **Player objective:** Photograph the vault and secure the closed carrier.
- **Player interactions:** Photograph marker and case; tether the carrier beside it; inspect intact outer latch without opening the biological seal.
- **Actions / animation:** Rafi clips a tether; Kai brushes only the external identification window.
- **Camera:** Light reveals the box slowly through player aim; no forced jump cut.
- **Sound / atmosphere:** Tether snap transmitted through gloves; small discovery interval.
- **Discovery:** The vault was deliberately deposited on an earlier authorised route.
- **Journal copy:** A human-made vault matches the old map. We will keep its biological seal closed until home.
- **Completion event EV-0403:** Marker and case photographed AND carrier tethered AND seal visually intact; commit M-0401.
- **Persistence:** Once the above predicate passes, mark `SC-0403_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0404; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-07](../08_PUZZLE_DESIGNS.md#p-07); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0404"></a>
## SC-0404 — Do Not Open Yet

- **Chapter / mission:** CH04 / [M-0402](../07_MISSION_DESIGNS/M-0402_Twelve_in_the_Dark.md)
- **Location / time:** LOC-10 / Oct 21 late morning
- **Cast / presence:** Physical: Rafi, Kai. Remote: Mei and Amara (Aurora local radio). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Make preservation more important than immediate revelation.
- **Opening:** The vault exterior reads below the carrier’s safe handling band.
- **Environment:** Closed sleeve, cradle, temperature probe and blank quarantine label.

### Exact dialogue

- **DL-0404-01 · KAI:** “The message is under the lid.”

- **DL-0404-02 · MEI:** “Then the lid can wait.”

- **DL-0404-03 · RAF:** “Probe, sleeve, cradle. Same order home.”

- **DL-0404-04 · KAI:** “Fine. I’m becoming very patient in a hurry.”


### Play and presentation

- **Player objective:** Sleeve and secure the sealed vault for transport.
- **Player interactions:** Begin P-08 recovery: probe external shell, seat insulated sleeve, latch cradle and transfer to rover without breaking the inner seal.
- **Actions / animation:** Two-person lift; no bare hands on frozen metal; latch indicator changes word and icon.
- **Camera:** Side-on staging shows continuous transfer, not inventory teleportation.
- **Sound / atmosphere:** Carrier creak; heartbeat-like low percussion, no magical vault sound.
- **Discovery:** Recovery includes contamination and condensation control.
- **Journal copy:** We recovered the whole insulated case without opening it in the cold.
- **Completion event EV-0404:** P-08 field recovery sequence validated AND case secured in rover.
- **Persistence:** Once the above predicate passes, mark `SC-0404_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0405; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-08](../08_PUZZLE_DESIGNS.md#p-08); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0405"></a>
## SC-0405 — Ask the Engineer

- **Chapter / mission:** CH04 / [M-0402](../07_MISSION_DESIGNS/M-0402_Twelve_in_the_Dark.md)
- **Location / time:** LOC-03 / Oct 22, back at base
- **Cast / presence:** Physical: Mei, Amara, Rafi, Kai. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Expose the invitation and contradictory evidence.
- **Opening:** The sealed vault rests inside a dry quarantine glovebox.
- **Environment:** Warm-up trend reaches stable green band; twelve numbered seed wells.

### Exact dialogue

- **DL-0405-01 · AMA:** “Temperature stable. Seal dry. Now we can open it here.”

- **DL-0405-02 · MEI:** ““If you found this, you’re ready. Ask Commander Ferreira about Expedition Zero.””

- **DL-0405-03 · RAF:** “Twelve specimens. One closed record for each.”

- **DL-0405-04 · KAI:** “And cotton among them.”

- **DL-0405-05 · MEI:** “Then we keep the whole collection safe.”


### Play and presentation

- **Player objective:** Warm the vault sealed, inventory its seeds and scan the lid.
- **Player interactions:** Finish P-08 sealed warming, inventory twelve distinct specimen labels, scan the lid inscription, send manifest to Ferreira.
- **Actions / animation:** Mei opens only inside the glovebox; Amara labels each specimen without consuming it.
- **Camera:** Hold lid and handwritten line readable together.
- **Sound / atmosphere:** Glovebox fan, pencil; discovery theme resolves into uncertainty.
- **Discovery:** Ferreira helped the gardener return; twelve seeds are recovered, viability not yet assumed.
- **Journal copy:** The vault holds twelve distinct specimens, including cotton. Its lid asks us to speak to Ferreira about Expedition Zero.
- **Completion event EV-0405:** P-08 complete AND twelve-item inventory saved AND manifest transmitted.
- **Persistence:** Once the above predicate passes, mark `SC-0405_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0406; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-08](../08_PUZZLE_DESIGNS.md#p-08); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0406"></a>
## SC-0406 — A Seat Kept Ready

- **Chapter / mission:** CH04 / [M-0402](../07_MISSION_DESIGNS/M-0402_Twelve_in_the_Dark.md)
- **Location / time:** LOC-01 / Oct 22 → Dec 12
- **Cast / presence:** Physical: Mei, Kai, Amara, Rafi. Remote: Commander Ferreira and Rao (Earth). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Prepare Ferreira’s physical arrival and bridge the calendar.
- **Opening:** Ferreira’s channel falls quiet after the vault inscription, then Rao answers. A relief-flight notice remains beside the report.
- **Environment:** Cargo order includes a relay controller, quarantine supplies and one additional suit locker.

### Exact dialogue

- **DL-0406-01 · RAO:** “She… needs a minute. Your safety plans are approved; the personal story can wait until she is ready.”

- **DL-0406-02 · KAI:** “We have a spare mug.”

- **DL-0406-03 · AMA:** “We have a carefully inventoried spare mug.”

- **DL-0406-04 · MEI:** “Bring the whole story when you come.”

- **DL-0406-05 · FER:** “My relief assignment brings me there in December. I owe you the whole story.”


### Play and presentation

- **Player objective:** Read the relief-flight notice and prepare Ferreira’s locker.
- **Player interactions:** Inspect relief flight dates Dec 8–12; install the spare locker label; confirm dated routine-care transition.
- **Actions / animation:** A fifth mug is placed without introducing a new playable hero.
- **Camera:** Repeat opening table angle with one extra place.
- **Sound / atmosphere:** Earth radio closes normally; transition music avoids cliffhanger manipulation.
- **Discovery:** Ferreira will travel; consent request concerns personal history, not safety data.
- **Journal copy:** Ferreira travels December 8–12. She thinks she recognises the writer and is asking permission to name her.
- **Completion event EV-0406:** Flight notice read AND locker prepared AND transition accepted; commit M-0402.
- **Persistence:** Once the above predicate passes, mark `SC-0406_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0501; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-08](../08_PUZZLE_DESIGNS.md#p-08); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).
