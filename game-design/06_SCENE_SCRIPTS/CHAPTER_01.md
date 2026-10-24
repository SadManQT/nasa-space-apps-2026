# Chapter 01 — Night One

Purpose: Care becomes a shared responsibility.

## Script execution contract

Each section is a fully authored scene. Lines are exact English master dialogue; bracket-free speaker labels identify characters. NOO before Chapter 5 is an archive-only voice labelled “N. (recording)” in player-facing captions. The cadets do not know the author’s identity yet; Ferreira and Rao know the seed legacy but leave its personal connection for the Chapter 5 reveal. Safety information is always shared. Remote speakers use screens/radio, not physical NPCs. Alo and Tara react visually and never have dialogue. Critical speech has caption/read-transcript parity. The dialogue master is indexed by line ID. Scene gates are mandatory, ordered and saved; cinematic skipping acknowledges dialogue but never bypasses a puzzle or fakes a physical interaction.

<a id="sc-0101"></a>
## SC-0101 — One Year, Four Names

- **Chapter / mission:** CH01 / [M-0101](../07_MISSION_DESIGNS/M-0101_A_Drawer_of_Light.md)
- **Location / time:** LOC-01 / 2046-04-11 06:00
- **Cast / presence:** Physical: Mei, Kai, Amara, Rafi. Remote: Commander Ferreira (Earth), Rao (Earth). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Make the player a member of a qualified expedition.
- **Opening:** Control begins behind Mei at the mission table; no menu lecture.
- **Environment:** Unlabelled lockers, four mugs, an Earth-facing screen; the station feels borrowed.

### Exact dialogue

- **DL-0101-01 · FER:** “You earned this place together. From this polar winter to the next: keep the habitat safe, and give a garden a future.”

- **DL-0101-02 · KAI:** “Power’s mine!”

- **DL-0101-03 · AMA:** “I make the air.”

- **DL-0101-04 · MEI:** “I keep the garden. At the moment, it is mostly empty pots.”

- **DL-0101-05 · RAF:** “And I guard the Safe Room.”

- **DL-0101-06 · RAO:** “Four specialists. One team. Your first objective is finding the kettle.”

- **DL-0101-07 · FER:** “Local emergency rules stay active when Earth cannot answer. Read them before you touch a valve.”

- **DL-0101-08 · FER:** “China sprouted cotton on the Moon in 2019. It did not survive the night. Your work begins with what theirs made possible.”


### Play and presentation

- **Player objective:** Read the charter and check all four crew roles.
- **Player interactions:** Walk to four role plaques; inspect the mission charter and emergency capsule card; select Accept assignment.
- **Actions / animation:** Companions pin their colour labels; Rafi straightens his oversized helmet.
- **Camera:** Third-person follow, optional 3 s table-wide introduction; never force a spinning camera.
- **Sound / atmosphere:** Ventilation, mug tap, gentle three-note theme.
- **Discovery:** The player controls the four named cadets, selected through specialist and team assessment.
- **Journal copy:** We accepted an assignment across the polar season cycle. Crew safety comes before every experiment.
- **Completion event EV-0101:** All four plaques inspected AND charter accepted AND emergency card acknowledged.
- **Persistence:** Once the above predicate passes, mark `SC-0101_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0102; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-01](../08_PUZZLE_DESIGNS.md#p-01); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0102"></a>
## SC-0102 — Two Seeds in a Drawer

- **Chapter / mission:** CH01 / [M-0101](../07_MISSION_DESIGNS/M-0101_A_Drawer_of_Light.md)
- **Location / time:** LOC-03 / Apr 11 10:00
- **Cast / presence:** Physical: Mei, Kai, Amara, Rafi. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Introduce Alo and Tara through an action.
- **Opening:** An inventory light blinks on a storage drawer.
- **Environment:** Dry sealed packet, old Bengali lettering, two empty chambers with different test labels.

### Exact dialogue

- **DL-0102-01 · MEI:** “আলো. Light. Someone gave these seeds a name before we arrived.”

- **DL-0102-02 · AMA:** “Two seeds. Two labels. Please don’t name both of them Light.”

- **DL-0102-03 · KAI:** “Light One and Light Two?”

- **DL-0102-04 · RAF:** “I vote against numbering our friends.”

- **DL-0102-05 · MEI:** “Alo outside. Tara inside. A star to keep our light company.”

- **DL-0102-06 · AMA:** “Same seed lot, different habitats. That gives us something useful to compare.”


### Play and presentation

- **Player objective:** Calibrate the probe and plant Alo and Tara.
- **Player interactions:** Complete P-01: verify storage seal, calibrate moisture probe, plant one seed per cassette, label independent test and reference.
- **Actions / animation:** Mei places the seed with tweezers; Kai holds a work light without comment.
- **Camera:** Macro only after player confirms planting; return to same facing.
- **Sound / atmosphere:** Paper packet, grain contact, warm motif begins.
- **Discovery:** Only N. identifies the packet owner; the exterior unit is a sealed experiment.
- **Journal copy:** Two dry seeds were marked আলো and N. Alo is our external test plant; Tara is the indoor reference.
- **Completion event EV-0102:** P-01 passed AND both labels confirmed; set pair_planted_pending, not mission completion.
- **Persistence:** Once the above predicate passes, mark `SC-0102_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0103; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-01](../08_PUZZLE_DESIGNS.md#p-01); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0103"></a>
## SC-0103 — A Very Important Lamp

- **Chapter / mission:** CH01 / [M-0101](../07_MISSION_DESIGNS/M-0101_A_Drawer_of_Light.md)
- **Location / time:** LOC-02 / Apr 11 evening → Apr 25 03:36
- **Cast / presence:** Physical: Kai, Mei, Rafi, Amara. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Plant Kai’s fear and establish two weeks of real growth.
- **Opening:** Kai remains beside the corridor work light after everyone moves away.
- **Environment:** A hand light hangs near a slowly filling plant photo strip.

### Exact dialogue

- **DL-0103-01 · MEI:** “You checked that switch already.”

- **DL-0103-02 · KAI:** “Important scientific lamp.”

- **DL-0103-03 · RAF:** “Does the important lamp need a backup?”

- **DL-0103-04 · KAI:** “It might.”

- **DL-0103-05 · RAF:** “Then this one stays here. No questions.”

- **DL-0103-06 · AMA:** “Day fourteen. A bud. That is a much better number than zero.”


### Play and presentation

- **Player objective:** Hang the hand light and record the first care photo.
- **Player interactions:** As Kai, hang the hand light at the locker and record a plant photo; confirm the labelled fourteen-day care montage.
- **Actions / animation:** Rafi offers the lamp handle-first; dated thumbnails grow roots, stems and buds.
- **Camera:** Stay at human height; dissolve through the same corridor angle.
- **Sound / atmosphere:** Small click; time-lapse fan rhythm; no alarm.
- **Discovery:** Kai’s attachment to light precedes the crisis; plants have been cared for between playable dates.
- **Journal copy:** Kai wanted a backup light. Rafi left one within reach. Two weeks of care brought the first buds.
- **Completion event EV-0103:** Hand light hung AND photo recorded AND time-advance confirmed; commit M-0101.
- **Persistence:** Once the above predicate passes, mark `SC-0103_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0104; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-01](../08_PUZZLE_DESIGNS.md#p-01); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0104"></a>
## SC-0104 — Practice Before Sunset

- **Chapter / mission:** CH01 / [M-0102](../07_MISSION_DESIGNS/M-0102_Keep_the_Night.md)
- **Location / time:** LOC-04 / Apr 25 03:36–18:00
- **Cast / presence:** Physical: Kai, Amara, Mei, Rafi. Remote: Commander Ferreira (Earth), Rao (Earth). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Teach shared planning before stakes increase.
- **Opening:** Ferreira calls a shelter drill while daylight still reaches the masts.
- **Environment:** Water wall empty; crate rails marked; oxygen tank partly filled.

### Exact dialogue

- **DL-0104-01 · FER:** “Practice building the shelter.”

- **DL-0104-02 · RAF:** “The historical storm feed says sunspot 2673 just fired a giant flare. Another big one may come.”

- **DL-0104-03 · AMA:** “Everyone heard that? Good. I can store air while we have spare sunlight.”

- **DL-0104-04 · MEI:** “The shelter borrows Alo’s water. Borrowing includes returning it.”

- **DL-0104-05 · KAI:** “We need to save. I mean power. And water. Both.”

- **DL-0104-06 · RAO:** “Say the plan out loud before you run it.”


### Play and presentation

- **Player objective:** Share all four observations and prepare before sunset.
- **Player interactions:** Deliver Kai and Amara’s private cards in shift 1 and Rafi’s card in shift 2; invite Share/discussion; acknowledge each role’s setting or Solo auto-approval; perform the no-cost drill; set and commit daylight shifts 1–2 in P-02.
- **Actions / animation:** Water demonstration uses a transparent test tube; permanent resource totals change only at commit.
- **Camera:** Player-controlled walkthrough; inset preview remains optional.
- **Sound / atmosphere:** Practice chime distinct from real alarm; friendly percussion.
- **Discovery:** Specialist observations are shared safety information, not competitive secrets.
- **Journal copy:** We rehearsed the shelter and stored oxygen while daylight power was available.
- **Completion event EV-0104:** Role settings acknowledged AND drill acknowledged AND daylight shifts 1–2 committed.
- **Persistence:** Once the above predicate passes, mark `SC-0104_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0105; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-02](../08_PUZZLE_DESIGNS.md#p-02); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0105"></a>
## SC-0105 — No Sun. No Earth.

- **Chapter / mission:** CH01 / [M-0102](../07_MISSION_DESIGNS/M-0102_Keep_the_Night.md)
- **Location / time:** LOC-01 / Apr 25 18:00–Apr 27 06:00
- **Cast / presence:** Physical: Kai, Amara, Mei, Rafi. Remote: Commander Ferreira (Earth). Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Deliver the first independent crisis.
- **Opening:** The mast indicator stops producing drops.
- **Environment:** Earth approaches a terrain edge; the base interior retains guide lighting.

### Exact dialogue

- **DL-0105-01 · FER:** “Earth-set in ten seconds. Signal loss at the ridge. From here, you’re on your own.”

- **DL-0105-02 · KAI:** “Leave the corridor light on? Just until—”

- **DL-0105-03 · MEI:** “We can keep the guide light. Tell us what you need.”

- **DL-0105-04 · KAI:** “I need to know which light comes back first.”

- **DL-0105-05 · AMA:** “This one. The protected bus. It stays on.”

- **DL-0105-06 · RAF:** “Particle alarm. This is not a drill!”

- **DL-0105-07 · MEI:** “Save the crew. Then bring that water back to Alo.”


### Play and presentation

- **Player objective:** Protect the crew through the storm and return the garden water.
- **Player interactions:** Deliver Mei’s private card at shift 3; Earth-set occurs at shift 4. Complete dark shifts 3–7 of P-02; choose PUMP, STACK or prepared WAIT at shift 5; restore borrowed water where needed; enter shelter before committing exposed shifts.
- **Actions / animation:** Kai grips and releases the hand light; water rises; shutters close; suit radios continue.
- **Camera:** Earth-set is optional window framing; storm graphics are instrument overlays, never visible particle rain outside.
- **Sound / atmosphere:** Uplink fades; local voices remain dry and close; accelerating dosimeter UI pulse.
- **Discovery:** Absence of Earth contact does not disable local systems or remove the crew’s ability to act.
- **Journal copy:** The Earth link went down, but our local radios worked. Shielding water had to return to the plants.
- **Completion event EV-0105:** P-02 reaches sunrise with crew_safe AND plant_alive; loss outcome routes to checkpoint before this gate.
- **Persistence:** Once the above predicate passes, mark `SC-0105_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0106; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-02](../08_PUZZLE_DESIGNS.md#p-02); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0106"></a>
## SC-0106 — First Light, First Question

- **Chapter / mission:** CH01 / [M-0102](../07_MISSION_DESIGNS/M-0102_Keep_the_Night.md)
- **Location / time:** LOC-03 / Apr 27 06:00
- **Cast / presence:** Physical: Mei, Kai, Amara, Rafi, Alo. Remote: none. Archive: Dr. Noor Rahman.
- **Mode:** Exploration + scripted conversation + short skippable cinematic.
- **Narrative purpose:** Earn the bloom and open the mystery.
- **Opening:** The shutters remain closed until the player checks the chamber temperature.
- **Environment:** One yellow petal catches reflected light; Tara’s bud remains in the indoor bay.

### Exact dialogue

- **DL-0106-01 · MEI:** “Wait. Look.”

- **DL-0106-02 · AMA:** “Temperature steady. Moisture steady.”

- **DL-0106-03 · KAI:** “We kept something on.”

- **DL-0106-04 · RAF:** “Someone should tell the flower it passed the drill.”

- **DL-0106-05 · MEI:** “She didn’t take a drill. She lived a night.”

- **DL-0106-06 · NOO:** “If you’re hearing this, Alo bloomed. Good. Now Alo needs a friend. — N.”


### Play and presentation

- **Player objective:** Check the chamber and photograph Alo’s first flower.
- **Player interactions:** Open the safe viewing shutter, tag the first-bloom image, listen or read the old care message; use photo framing for the earned Bloom or Golden result.
- **Actions / animation:** Alo opens; the recorder activates only on image tagging; companions lean in without obscuring the flower.
- **Camera:** 12 s restrained macro, skippable after first petal; camera restores control beside the recorder.
- **Sound / atmosphere:** First full Alo theme; fans remain beneath music; old recording has age texture without unintelligibility.
- **Discovery:** The old gardener anticipated a future bloom but did not know when or whether one would occur.
- **Journal copy:** Alo bloomed at first light. Tagging the image triggered an old recording from N.
- **Completion event EV-0106:** Bloom image tagged AND recording heard/read; commit M-0102 and first_bloom.
- **Persistence:** Once the above predicate passes, mark `SC-0106_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0201; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-02](../08_PUZZLE_DESIGNS.md#p-02); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

## Shift-specific dialogue triggers

SC-0104 does not play every line on zone entry: Kai/Amara cards arrive at shift1, the drill line DL-0104-01 and Rafi’s card/DL-0104-02 at shift2. Other planning lines follow their associated shared observations. Mei’s private card arrives at shift3. In SC-0105, DL-0105-01 plays at shift4 immediately before the Earth link closes; DL-0105-02 through05 follow that contact-loss beat; DL-0105-06 and07 wait for the shift5 particle alarm. No live Earth line plays after the link closes. SC-0106’s N. recording waits for the tagged bloom image. Cinematic skipping acknowledges only the current beat, never future shifts or messages.
