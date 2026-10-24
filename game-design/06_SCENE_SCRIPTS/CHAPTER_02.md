# Chapter 02 — Be the Bee

Purpose: The first bloom needs another living partner.

## Script execution contract

Each section is a fully authored scene. Lines are exact English master dialogue; bracket-free speaker labels identify characters. NOO before Chapter 5 is an archive-only voice labelled “N. (recording)” in player-facing captions. The cadets do not know the author’s identity yet; Ferreira and Rao know the seed legacy but leave its personal connection for the Chapter 5 reveal. Safety information is always shared. Remote speakers use screens/radio, not physical NPCs. The archival FER voice is labelled “Engineer (recording)” in the player UI until Chapter 5, preserving the resemblance as a clue. Alo and Tara react visually and never have dialogue. Critical speech has caption/read-transcript parity. The dialogue master is indexed by line ID. Scene gates are mandatory, ordered and saved; cinematic skipping acknowledges dialogue but never bypasses a puzzle or fakes a physical interaction.

<a id="sc-0201"></a>
## SC-0201 — A Star in the Other Room

- **Chapter / mission:** CH02 / [M-0201](../07_MISSION_DESIGNS/M-0201_Borrow_a_Bee.md)
- **Location / time:** LOC-03 / Apr 30 morning
- **Cast / presence:** Physical: Mei, Amara, Kai, Rafi, Tara. Remote: Commander Ferreira (Earth). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Make Tara a partner rather than a spare.
- **Opening:** Earth contact returns as the player looks at Tara.
- **Environment:** Tara has a yellow flower and a handwritten comparison chart.

### Exact dialogue

- **DL-0201-01 · FER:** “You didn’t survive the Moon. You ran it.”

- **DL-0201-02 · MEI:** “We have another flower. Tara.”

- **DL-0201-03 · KAI:** “We gave Alo a sunrise and forgot to congratulate the star.”

- **DL-0201-04 · AMA:** “Same care standard for both. Also, flowers are not guaranteed seeds.”

- **DL-0201-05 · MEI:** “Then we help them meet.”


### Play and presentation

- **Player objective:** Inspect Tara and collect the pollination protocol.
- **Player interactions:** Inspect both plant identity tags and request the cross-pollination protocol at the indoor bench.
- **Actions / animation:** Mei moves Tara’s nameplate beside Alo’s on the board.
- **Camera:** Keep both names in the same shot; Earth screen stays secondary.
- **Sound / atmosphere:** Returned radio tone, lighter version of flower motif.
- **Discovery:** Both compatible individuals are needed for the selected self-incompatible cultivar.
- **Journal copy:** Tara has flowered too. Our selected mustard plants need compatible pollen from one another.
- **Completion event EV-0201:** Both identity tags inspected AND pollination protocol opened.
- **Persistence:** Once the above predicate passes, mark `SC-0201_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0202; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-03](../08_PUZZLE_DESIGNS.md#p-03); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0202"></a>
## SC-0202 — Be the Bee

- **Chapter / mission:** CH02 / [M-0201](../07_MISSION_DESIGNS/M-0201_Borrow_a_Bee.md)
- **Location / time:** LOC-05 / Apr 30–May 6, three reciprocal bee runs
- **Cast / presence:** Physical: Mei, Rafi, Amara. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Let the player perform a precise, gentle scientific task.
- **Opening:** A clean brush waits in a sealed transfer carrier.
- **Environment:** Glove ports, pollen microscope, donor/recipient labels, carrier seal indicator.

### Exact dialogue

- **DL-0202-01 · RAF:** “Bzzzz.”

- **DL-0202-02 · AMA:** “The bee is on the radio channel.”

- **DL-0202-03 · RAF:** “The bee apologises.”

- **DL-0202-04 · MEI:** “My grandmother used a brush in an orchard in China. There weren’t enough pollinators.”

- **DL-0202-05 · AMA:** “Our atmosphere is doing rather worse for bees.”

- **DL-0202-06 · MEI:** “Good thing we brought hands.”


- **DL-0202-07 · MEI:** “When the bees can’t come, we become the bees. Michael Foale used a bee stick with mustard on Mir in 1997.”

### Play and presentation

- **Player objective:** Transfer pollen between Alo and Tara through sealed ports.
- **Player interactions:** Complete P-03’s three reciprocal runs, with one E1/A1 route charge per run, space-weather check and sealed glove ports; log seven care dates. Inspect Alo’s purple stem and Tara’s green stem, then record an offspring-colour prediction.
- **Actions / animation:** Brush tip collects visible magnified grains; no pollen floats in lunar vacuum.
- **Camera:** Interactive close camera with large-target cursor alternative.
- **Sound / atmosphere:** Brush rustle, glove squeak, one restrained bee joke.
- **Discovery:** Pollination is a relationship between plants, not a button that immediately produces pods.
- **Journal copy:** We used clean brushes and sealed carriers to cross-pollinate Alo and Tara.
- **Completion event EV-0202:** P-03 three reciprocal runs validated AND seven care dates and stem prediction recorded.
- **Persistence:** Once the above predicate passes, mark `SC-0202_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0203; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-03](../08_PUZZLE_DESIGNS.md#p-03); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0203"></a>
## SC-0203 — Not Tomorrow’s Seeds

- **Chapter / mission:** CH02 / [M-0201](../07_MISSION_DESIGNS/M-0201_Borrow_a_Bee.md)
- **Location / time:** LOC-01 / May 6 afternoon
- **Cast / presence:** Physical: Mei, Kai, Amara, Rafi. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Set patient expectations and direct investigation.
- **Opening:** The team places a dated pollination strip on the table.
- **Environment:** Pollinated flowers remain flowers; no instant pods appear.

### Exact dialogue

- **DL-0203-01 · KAI:** “Seeds tomorrow?”

- **DL-0203-02 · AMA:** “No.”

- **DL-0203-03 · RAF:** “The day after tomorrow?”

- **DL-0203-04 · AMA:** “Also no.”

- **DL-0203-05 · MEI:** “We keep caring. We don’t pull a plant into the future.”

- **DL-0203-06 · KAI:** “Fine. What can I pull?”

- **DL-0203-07 · MEI:** “The recorder drawer. Gently.”


### Play and presentation

- **Player objective:** Record the care visits and inspect the recorder label.
- **Player interactions:** Record pollination journal entry and inspect the recorder’s equipment label to unlock the investigation station.
- **Actions / animation:** Rafi adds a small paper bee; Mei writes the actual date.
- **Camera:** Unhurried group composition; let the player walk away after required lines.
- **Sound / atmosphere:** Soft table taps; equipment hum.
- **Discovery:** Reproduction takes weeks; the recorder shares a part number with the old garden equipment.
- **Journal copy:** We logged seven pollination visits across seven days. Seeds need time to develop.
- **Completion event EV-0203:** Journal pollination entry read AND recorder label inspected; commit M-0201.
- **Persistence:** Once the above predicate passes, mark `SC-0203_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0204; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-03](../08_PUZZLE_DESIGNS.md#p-03); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0204"></a>
## SC-0204 — A Label Under a Label

- **Chapter / mission:** CH02 / [M-0202](../07_MISSION_DESIGNS/M-0202_A_Voice_Before_Us.md)
- **Location / time:** LOC-02 / May 6 late afternoon
- **Cast / presence:** Physical: Kai, Mei, Amara. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Introduce evidence reconstruction.
- **Opening:** The recorder’s service sticker lifts at one corner.
- **Environment:** Three local files carry scrambled date/device/channel fields.

### Exact dialogue

- **DL-0204-01 · KAI:** “Someone put the new label over the old one.”

- **DL-0204-02 · AMA:** “Labels are observations too.”

- **DL-0204-03 · MEI:** ““Trial One. Reproductive stage: not reached.””

- **DL-0204-04 · KAI:** “Then Alo really was the first flower here.”

- **DL-0204-05 · AMA:** “In these records, yes. Let’s finish reading before we finish deciding.”


### Play and presentation

- **Player objective:** Photograph the recorder’s three source labels.
- **Player interactions:** Inspect the serial plate, maintenance date and trial chart; place their copies on the reconstruction board.
- **Actions / animation:** Mei photographs instead of peeling an irreplaceable original.
- **Camera:** Board and object share framing; no clue hidden in pixel hunting.
- **Sound / atmosphere:** Recorder relay click; faint archived room tone.
- **Discovery:** The old trial ended before flowering; data supports rather than invalidates the current achievement.
- **Journal copy:** An older trial record says its reproductive stage was never reached.
- **Completion event EV-0204:** All three evidence cards collected.
- **Persistence:** Once the above predicate passes, mark `SC-0204_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0205; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-04](../08_PUZZLE_DESIGNS.md#p-04); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0205"></a>
## SC-0205 — The Young Engineer

- **Chapter / mission:** CH02 / [M-0202](../07_MISSION_DESIGNS/M-0202_A_Voice_Before_Us.md)
- **Location / time:** LOC-02 / May 6 evening
- **Cast / presence:** Physical: Amara, Mei, Kai, Rafi. Remote: none. Archive: anonymous Engineer (FER, 2034) and N. (NOO, gardener memory).
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Reveal a recognisable voice without naming Noor.
- **Opening:** The restored device waits for the correct file mapping.
- **Environment:** Date, recorder ID and voice channel each have one verified match.

### Exact dialogue

- **DL-0205-01 · AMA:** “Same recorder, twelve years earlier.”

- **DL-0205-02 · FER:** “Annex power isolated. Biological trial suspended. Crew retreat is mandatory.”

- **DL-0205-03 · KAI:** “That sounds like Ferreira.”

- **DL-0205-04 · RAF:** “Younger. Not calmer.”

- **DL-0205-05 · MEI:** “Send it to her. We’re not solving a person by guessing.”


- **DL-0205-06 · NOO:** “My grandmother’s mustard fields turned yellow every winter. I wanted to bring a little of that light here. — N.”

### Play and presentation

- **Player objective:** Restore the recorder metadata and send the fragment.
- **Player interactions:** Complete P-04; play the 2034 fragment and send its checksum and transcript in the current Earth contact window.
- **Actions / animation:** Rafi places the evidence file in the transmit queue; no secret theft animation.
- **Camera:** Close on the timestamp before the voice begins.
- **Sound / atmosphere:** Older Ferreira recording, intact words; modern radio confirmation beep.
- **Discovery:** The engineer voice resembles Ferreira; the identification remains a suspicion until Chapter 5.
- **Journal copy:** The 2034 engineering voice sounded like Ferreira. We sent her the evidence.
- **Completion event EV-0205:** P-04 validated AND N.’s mustard-fields clue heard/read AND fragment transmission acknowledged.
- **Persistence:** Once the above predicate passes, mark `SC-0205_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0206; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-04](../08_PUZZLE_DESIGNS.md#p-04); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0206"></a>
## SC-0206 — The Floor Answers

- **Chapter / mission:** CH02 / [M-0202](../07_MISSION_DESIGNS/M-0202_A_Voice_Before_Us.md)
- **Location / time:** LOC-01 / May 6 22:00
- **Cast / presence:** Physical: Mei, Kai, Amara, Rafi. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Bridge directly into the quake.
- **Opening:** The reply queue blinks, then a cup vibrates against the table.
- **Environment:** A shallow tremor becomes a sustained shake; dust falls inside from panel seams.

### Exact dialogue

- **DL-0206-01 · RAF:** “Under the table. Away from the window.”

- **DL-0206-02 · KAI:** “Hand light. I have it.”

- **DL-0206-03 · AMA:** “Garden spur pressure falling. Main display says tank fault.”

- **DL-0206-04 · MEI:** “Those are different problems.”

- **DL-0206-05 · AMA:** “I know. I need another measurement.”


### Play and presentation

- **Player objective:** Take cover and account for all four cadets.
- **Player interactions:** Move to the marked interior brace and confirm all four cadets accounted for; no timed dexterity requirement.
- **Actions / animation:** Companions crouch; a loose cover shifts without opening the unsafe annex.
- **Camera:** Reduced-shake option substitutes static shot and directional icons.
- **Sound / atmosphere:** Structural creak and transmitted vibration, no exterior atmospheric rumble.
- **Discovery:** The displayed diagnosis may be wrong; independent measurement is necessary.
- **Journal copy:** A quake shook the station. The garden pressure reading disagreed with the panel diagnosis.
- **Completion event EV-0206:** All crew at brace AND quake beat finished; commit M-0202; enter CH03 without time jump.
- **Persistence:** Once the above predicate passes, mark `SC-0206_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0301; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-04](../08_PUZZLE_DESIGNS.md#p-04); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).
