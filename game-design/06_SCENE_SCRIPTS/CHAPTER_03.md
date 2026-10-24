# Chapter 03 — Moonquake

Purpose: Care includes uncertainty, loss and continuation.

## Script execution contract

Each section is a fully authored scene. Lines are exact English master dialogue; bracket-free speaker labels identify characters. NOO before Chapter 5 is an archive-only voice labelled “N. (recording)” in player-facing captions. The cadets do not know the author’s identity yet; Ferreira and Rao know the seed legacy but leave its personal connection for the Chapter 5 reveal. Safety information is always shared. Remote speakers use screens/radio, not physical NPCs. Alo and Tara react visually and never have dialogue. Critical speech has caption/read-transcript parity. The dialogue master is indexed by line ID. Scene gates are mandatory, ordered and saved; cinematic skipping acknowledges dialogue but never bypasses a puzzle or fakes a physical interaction.

<a id="sc-0301"></a>
## SC-0301 — Trust, Then Check

- **Chapter / mission:** CH03 / [M-0301](../07_MISSION_DESIGNS/M-0301_Numbers_That_Disagree.md)
- **Location / time:** LOC-02 / May 6 22:05
- **Cast / presence:** Physical: Amara, Rafi, Mei, Kai. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Put Amara’s uncertainty into the player’s hands.
- **Opening:** Alarm panel marks the oxygen tank red.
- **Environment:** Manual gauge and electronic panel disagree.

### Exact dialogue

- **DL-0301-01 · AMA:** “The display says tank. The line says spur. I can’t trust both.”

- **DL-0301-02 · RAF:** “You don’t have to. Check them.”

- **DL-0301-03 · KAI:** “What do you need powered?”

- **DL-0301-04 · AMA:** “The gauge lamp. Nothing else yet.”

- **DL-0301-05 · MEI:** “The plant chambers are sealed. We have time to do this properly.”


### Play and presentation

- **Player objective:** Read all three pressure taps with the manual gauge.
- **Player interactions:** Collect the manual gauge and inspect three pressure taps before touching isolation controls.
- **Actions / animation:** Amara steadies her hand on the gauge; Kai lights the markings.
- **Camera:** Interaction zoom shows numbers and words, not colour alone.
- **Sound / atmosphere:** Leak hiss exists only within pressurised space; alert volume ducks under speech.
- **Discovery:** The protected plant atmosphere remains separate from the leaking room line.
- **Journal copy:** Independent pressure readings can test the electronic diagnosis.
- **Completion event EV-0301:** Manual gauge equipped AND three taps read.
- **Persistence:** Once the above predicate passes, mark `SC-0301_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0302; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-05](../08_PUZZLE_DESIGNS.md#p-05); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0302"></a>
## SC-0302 — The Line That Falls

- **Chapter / mission:** CH03 / [M-0301](../07_MISSION_DESIGNS/M-0301_Numbers_That_Disagree.md)
- **Location / time:** LOC-02 / May 6 22:10 → May 8 03:00
- **Cast / presence:** Physical: Amara, Kai, Rafi, Mei. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Repair using a reproducible diagnostic procedure.
- **Opening:** A valve board shows habitat trunk and garden spur.
- **Environment:** One safe-side clamp socket is accessible beside the isolation valve.

### Exact dialogue

- **DL-0302-01 · AMA:** “Main pressure holds. Garden spur falls. Close the spur, not the whole habitat.”

- **DL-0302-02 · KAI:** “Lamp stays on the protected bus.”

- **DL-0302-03 · RAF:** “Clamp is seated. Your check.”

- **DL-0302-04 · AMA:** “Five readings. All steady. Now I believe the number.”


### Play and presentation

- **Player objective:** Isolate the garden spur, clamp the leak and verify pressure.
- **Player interactions:** Complete P-05: isolate garden spur, confirm mechanical pressure hold, apply clamp, reopen slowly and run five checks.
- **Actions / animation:** Hands turn a labelled valve; pressure loss stops before patching.
- **Camera:** Keep valve labels readable; no mandatory aiming under a timer.
- **Sound / atmosphere:** Hiss fades, then test clicks; music waits until confirmation.
- **Discovery:** The mechanical test proves the diagnosis; no blind faith in a HUD colour.
- **Journal copy:** The garden spur leaked; the main tank did not. Five stable checks confirmed our repair.
- **Completion event EV-0302:** P-05 stable verification passed; set leak_sealed_pending.
- **Persistence:** Once the above predicate passes, mark `SC-0302_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0303; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-05](../08_PUZZLE_DESIGNS.md#p-05); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0303"></a>
## SC-0303 — A Door We Knew Was There

- **Chapter / mission:** CH03 / [M-0301](../07_MISSION_DESIGNS/M-0301_Numbers_That_Disagree.md)
- **Location / time:** LOC-07 / May 7 morning
- **Cast / presence:** Physical: Mei, Amara, Rafi, Kai. Remote: Commander Ferreira (Earth). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Open the annex without making it an uncertified secret room.
- **Opening:** The displaced cover exposes a warped hatch stamped N.R.
- **Environment:** Survey tag reads ISOLATED SERVICE ANNEX; access camera shows frozen trays.

### Exact dialogue

- **DL-0303-01 · FER:** “I’m sending the technical failure notes and every repair diagram. Start with the isolation boundary.”

- **DL-0303-02 · MEI:** “Were there flowers?”

- **DL-0303-03 · FER:** “The record says seedlings. They left before the plants could flower.”

- **DL-0303-04 · AMA:** “And the hatch?”

- **DL-0303-05 · FER:** “An isolated annex. Make it safe before you make it a discovery.”

- **DL-0303-06 · RAF:** “That is a sentence I am keeping.”


### Play and presentation

- **Player objective:** Isolate the annex and inspect its hatch safely.
- **Player interactions:** Use camera inspection, disconnect annex utility feed and confirm zero differential before opening the safe viewing hatch; physical entry waits for suit check.
- **Actions / animation:** Rafi fits a warning marker; camera crawls through an existing port.
- **Camera:** Reveal tray silhouettes through the hatch; no shock-horror corpse imagery.
- **Sound / atmosphere:** Hatch metal scrape; quiet, spacious music.
- **Discovery:** Ferreira acknowledges her involvement and shares all safety facts promptly.
- **Journal copy:** Ferreira served on Expedition Zero. She shared the safety report and repair diagrams.
- **Completion event EV-0303:** Utility feed isolated AND zero differential confirmed AND hatch view inspected; commit M-0301.
- **Persistence:** Once the above predicate passes, mark `SC-0303_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0304; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-05](../08_PUZZLE_DESIGNS.md#p-05); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0304"></a>
## SC-0304 — The Garden That Didn’t Flower

- **Chapter / mission:** CH03 / [M-0302](../07_MISSION_DESIGNS/M-0302_Forty-Two.md)
- **Location / time:** LOC-07 / May 8 → May 16
- **Cast / presence:** Physical: Mei, Amara, Rafi, Kai. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Discover a map and prepare for Alo’s natural end.
- **Opening:** Suited cadets enter the cold annex after the safety check.
- **Environment:** Frozen seedlings, incomplete growth chart, map beneath a sealed clear cover.

### Exact dialogue

- **DL-0304-01 · MEI:** “These never opened.”

- **DL-0304-02 · AMA:** “The chart ends at seedling stage.”

- **DL-0304-03 · RAF:** “There’s a route under this tray. To a place with no sunrise.”

- **DL-0304-04 · KAI:** “Are we going now?”

- **DL-0304-05 · MEI:** “First we finish looking after the garden we have.”


### Play and presentation

- **Player objective:** Scan the old growth chart and vault map.
- **Player interactions:** Scan growth chart and vault route; exit and confirm the dated eight-day care montage to pod maturity to pod maturity.
- **Actions / animation:** Mei leaves the frozen plants undisturbed; photographs become journal overlays.
- **Camera:** Slow track across unfinished tray labels, then match cut to Alo’s mature pods.
- **Sound / atmosphere:** Suit breathing in annex; fans return on habitat re-entry.
- **Discovery:** The vault is a future objective; current biological care takes priority.
- **Journal copy:** The annex held frozen seedlings, not flowers. Its map points to an old cold-trap vault.
- **Completion event EV-0304:** Chart and map scanned AND suits cleared on exit AND maturity montage accepted.
- **Persistence:** Once the above predicate passes, mark `SC-0304_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0305; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-06](../08_PUZZLE_DESIGNS.md#p-06); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0305"></a>
## SC-0305 — Forty-Two

- **Chapter / mission:** CH03 / [M-0302](../07_MISSION_DESIGNS/M-0302_Forty-Two.md)
- **Location / time:** LOC-03 / May 16 → May 21
- **Cast / presence:** Physical: Mei, Amara, Kai, Rafi. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Let harvest be an emotional task with exact accounting.
- **Opening:** Alo’s last dry petal rests against the chamber wall.
- **Environment:** Dry pods, seed tray, lineage labels and one empty petal sleeve.

### Exact dialogue

- **DL-0305-01 · MEI:** “I thought keeping her alive meant... longer.”

- **DL-0305-02 · AMA:** “It meant she could finish.”

- **DL-0305-03 · KAI:** “Do you want us to wait?”

- **DL-0305-04 · MEI:** “No. Stay.”

- **DL-0305-05 · AMA:** “Forty-two seeds. Alo made forty-two seeds.”

- **DL-0305-06 · RAF:** “That is a lot of people to worry about.”

- **DL-0305-07 · MEI:** “Then every first flower in this garden will be called Alo.”


### Play and presentation

- **Player objective:** Harvest and label all forty-two mature seeds.
- **Player interactions:** Complete P-06 maturity checks on May 16, confirm the dated five-day dry-down, then harvest on May 21, count groups and allocate twelve planting seeds plus thirty reserve; sleeve the petal.
- **Actions / animation:** No exaggerated death collapse; the plant has naturally senesced. Hands pause before opening pods.
- **Camera:** Give silence four seconds before the count; optional close view controlled by player.
- **Sound / atmosphere:** Seed ticks on tray; score nearly absent until the final count.
- **Discovery:** Alo’s life continues through descendants, not through resurrection.
- **Journal copy:** Alo finished her life cycle. Twelve seeds go to planting; thirty stay protected. We kept a pressed petal.
- **Completion event EV-0305:** P-06 inventory totals exactly 42 AND pressed petal stored.
- **Persistence:** Once the above predicate passes, mark `SC-0305_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0306; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-06](../08_PUZZLE_DESIGNS.md#p-06); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0306"></a>
## SC-0306 — The Next Small Thing

- **Chapter / mission:** CH03 / [M-0302](../07_MISSION_DESIGNS/M-0302_Forty-Two.md)
- **Location / time:** LOC-03 / May 21 → Oct 21
- **Cast / presence:** Physical: Mei, Kai, Amara, Rafi. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Make continuation an action and account for skipped months.
- **Opening:** Twelve labelled positions wait in the new tray.
- **Environment:** Original reserve sealed; care photos show repeated generations and pollination.

### Exact dialogue

- **DL-0306-01 · MEI:** “This one goes here.”

- **DL-0306-02 · KAI:** “What do we call them?”

- **DL-0306-03 · AMA:** “Lineage first. Nicknames second.”

- **DL-0306-04 · RAF:** “I’m naming one Very Important Scientific Plant.”

- **DL-0306-05 · MEI:** “Alo would approve.”


### Play and presentation

- **Player objective:** Plant the next generation and seal the reserve.
- **Player interactions:** Plant the allocated twelve; select a dedication for the seed tray; confirm five-month dated maintenance montage including repeated pollen care and backup checks.
- **Actions / animation:** Player sets first seed; later photos show twelve current descendants, not five-month-old original annuals.
- **Camera:** Match original planting camera, now a wider frame with the team.
- **Sound / atmosphere:** Alo motif gains a second voice; no victory fanfare.
- **Discovery:** The expedition becomes a family of plants; the mapped reserve expedition now has purpose.
- **Journal copy:** We planted twelve founder seeds. Later care records follow their descendants across five months.
- **Completion event EV-0306:** Twelve slots planted AND reserve sealed AND montage confirmed; commit M-0302.
- **Persistence:** Once the above predicate passes, mark `SC-0306_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0401; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-06](../08_PUZZLE_DESIGNS.md#p-06); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).
