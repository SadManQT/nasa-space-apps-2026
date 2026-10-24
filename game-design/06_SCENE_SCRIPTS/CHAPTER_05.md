# Chapter 05 — Shooting Stars

Purpose: Evidence makes room for an honest conversation.

## Script execution contract

Each section is a fully authored scene. Lines are exact English master dialogue; bracket-free speaker labels identify characters. NOO before Chapter 5 is an archive-only voice labelled “N. (recording)” in player-facing captions. The cadets do not know the author’s identity yet; Ferreira and Rao know the seed legacy but leave its personal connection for the Chapter 5 reveal. Safety information is always shared. Remote speakers use screens/radio, not physical NPCs. Alo and Tara react visually and never have dialogue. Critical speech has caption/read-transcript parity. The dialogue master is indexed by line ID. Scene gates are mandatory, ordered and saved; cinematic skipping acknowledges dialogue but never bypasses a puzzle or fakes a physical interaction.

<a id="sc-0501"></a>
## SC-0501 — The Fifth Mug

- **Chapter / mission:** CH05 / [M-0501](../07_MISSION_DESIGNS/M-0501_The_Engineer_Comes_Home.md)
- **Location / time:** LOC-08 / Dec 12 arrival
- **Cast / presence:** Physical: Commander Ferreira, Mei, Kai, Amara, Rafi. Remote: Rao (Earth). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Make Ferreira’s arrival physical and human.
- **Opening:** A scheduled lander arrives at the existing pad; the player waits behind the marked line.
- **Environment:** Cargo sled, dust-settling interval, new footprints leading home.

### Exact dialogue

- **DL-0501-01 · FER:** “Permission to come aboard?”

- **DL-0501-02 · RAF:** “Seal check first, Commander.”

- **DL-0501-03 · FER:** “Correct answer.”

- **DL-0501-04 · KAI:** “Your mug survived inventory.”

- **DL-0501-05 · AMA:** “Twice.”

- **DL-0501-06 · FER:** “Eat. I’ll take the corridor watch.”

- **DL-0501-07 · RAO:** “I’m keeping the Earth end. Someone has to miss the good kettle.”


### Play and presentation

- **Player objective:** Wait for landing clearance and welcome Ferreira inside.
- **Player interactions:** After landing-clear indication, inspect cargo seal and escort Ferreira through the airlock; put her mug on the table.
- **Actions / animation:** Ferreira removes gloves only inside; tired shoulders soften at the mug.
- **Camera:** No plume view from an unsafe distance; arrival mostly seen through habitat camera.
- **Sound / atmosphere:** Filtered lander feed; interior greeting has no triumphant march.
- **Discovery:** Ferreira is now physically at Aurora; Rao remains on Earth.
- **Journal copy:** Ferreira arrived at Aurora with relief cargo and a replacement relay controller. Rao remains on Earth.
- **Completion event EV-0501:** Landing clear AND cargo seal inspected AND Ferreira entered habitat.
- **Persistence:** Once the above predicate passes, mark `SC-0501_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0502; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-09](../08_PUZZLE_DESIGNS.md#p-09); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0502"></a>
## SC-0502 — The Order We Left In

- **Chapter / mission:** CH05 / [M-0501](../07_MISSION_DESIGNS/M-0501_The_Engineer_Comes_Home.md)
- **Location / time:** LOC-01 / Dec 14 afternoon
- **Cast / presence:** Physical: Commander Ferreira, Mei, Amara, Rafi, Kai. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Reconstruct facts before the personal reveal.
- **Opening:** Four evidence cards lie on the table beside the old relay diagram.
- **Environment:** Read-only public failure report, hatch chart, vault manifest, ascent record.

### Exact dialogue

- **DL-0502-01 · FER:** “Start with what the records show. Then ask me what they don’t.”

- **DL-0502-02 · AMA:** “Seedlings. Relay fault. Evacuation order. Two boarding signatures.”

- **DL-0502-03 · RAF:** “Both names boarded?”

- **DL-0502-04 · FER:** “Both. Every member of the crew came home.”

- **DL-0502-05 · MEI:** “Then who kept the seeds?”


### Play and presentation

- **Player objective:** Reconstruct the evacuation and verify the boarding record.
- **Player interactions:** Complete P-09 evidence chronology; compare boarding count with expedition roster and select the supported conclusion.
- **Actions / animation:** Ferreira stands beside, not over, the player’s board.
- **Camera:** Alternating board close and present reactions; avoid invented flashback geography.
- **Sound / atmosphere:** Paper, tablet taps, restrained dissonance resolves at matching signatures.
- **Discovery:** No one died or was abandoned; Noor’s identity awaits consented personal context.
- **Journal copy:** The 2034 fault preceded the evacuation. All four crew members boarded. Nobody was abandoned.
- **Completion event EV-0502:** P-09 supported chronology committed AND all crew boarding conclusion selected.
- **Persistence:** Once the above predicate passes, mark `SC-0502_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0503; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-09](../08_PUZZLE_DESIGNS.md#p-09); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0503"></a>
## SC-0503 — What I Didn’t Say

- **Chapter / mission:** CH05 / [M-0501](../07_MISSION_DESIGNS/M-0501_The_Engineer_Comes_Home.md)
- **Location / time:** LOC-01 / Dec 14 dusk
- **Cast / presence:** Physical: Commander Ferreira, Mei, Kai, Amara, Rafi. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Let Ferreira own her delayed explanation.
- **Opening:** The factual reconstruction remains visible after the puzzle ends.
- **Environment:** A paused recording shows a young engineer beside an unfinished tray.

### Exact dialogue

- **DL-0503-01 · FER:** “Noor stayed to the last minute to hide the seeds. I was the engineer who couldn’t fix the radio. We left her garden to freeze. I left it.”

- **DL-0503-02 · MEI:** “You could have told us that.”

- **DL-0503-03 · FER:** “Yes. I was afraid “we left” would sound like “we didn’t care.” That was my fear, not your fault.”

- **DL-0503-04 · KAI:** “Did you stop being afraid?”

- **DL-0503-05 · FER:** “I learned to stop making the decisions alone.”

- **DL-0503-06 · RAF:** “We can work with that.”


### Play and presentation

- **Player objective:** Ask Ferreira about the order and the seeds.
- **Player interactions:** Choose Ask about the order or Ask about the seeds; both exact responses remain available and both return to the same supported facts.
- **Actions / animation:** Ferreira sits at the cadets’ eye level; no authority pose.
- **Camera:** Static shared frame; allow pauses and optional subtitle hold.
- **Sound / atmosphere:** No music under admission; fan and distant metal ticks remain.
- **Discovery:** Ferreira’s withholding was avoidant communication; she admits it rather than being excused by a fake secret rule.
- **Journal copy:** Ferreira regretted avoiding the personal story. Retreat was the safe order, and she helped the gardener return.
- **Completion event EV-0503:** Both factual question topics read/heard OR accessible Read all selected; commit M-0501.
- **Persistence:** Once the above predicate passes, mark `SC-0503_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0504; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-09](../08_PUZZLE_DESIGNS.md#p-09); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0504"></a>
## SC-0504 — Stars Without Streaks

- **Chapter / mission:** CH05 / [M-0502](../07_MISSION_DESIGNS/M-0502_Permission_to_Answer.md)
- **Location / time:** LOC-01 / Dec 14 night
- **Cast / presence:** Physical: Mei, Amara, Kai, Rafi, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Put wonder before the next revelation.
- **Opening:** The player opens the exterior camera’s impact-monitoring feed.
- **Environment:** Dark plains on a monitor; occasional amplified flashes, event times below.

### Exact dialogue

- **DL-0504-01 · KAI:** “Where are the shooting stars?”

- **DL-0504-02 · AMA:** “No atmosphere. No streaks like home.”

- **DL-0504-03 · RAF:** “The little flash at fourteen seconds?”

- **DL-0504-04 · MEI:** “A visitor, and then a new mark.”

- **DL-0504-05 · FER:** “Look long enough. The Moon keeps a record.”


### Play and presentation

- **Player objective:** Verify six impact flashes, reject detector artifacts and maintain the station.
- **Player interactions:** Run P-10’s three observation/maintenance phases: verify at least six flashes, reject two fixed artifacts, clean dusty panels and patch/verify the isolated dome spur, or verify the owned protective upgrade. All eight flashes are optional mastery.
- **Actions / animation:** Cadets lean around the screen; no EVA during a meteor observation is required.
- **Camera:** Camera feed is clearly a monitor view, not omniscient outdoor fireworks.
- **Sound / atmosphere:** Soft UI tick per confirmed flash; sparse piano or plucked notes.
- **Discovery:** Impact flashes offer a method for comparing old damage times, not proof of every historic failure.
- **Journal copy:** The impact camera distinguishes changing flashes from a fixed detector artifact. There are no atmospheric meteor streaks here.
- **Completion event EV-0504:** Six genuine flashes verified AND both artifacts rejected AND dust and leak maintenance passed or upgrade-protected.
- **Persistence:** Once the above predicate passes, mark `SC-0504_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0505; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-10](../08_PUZZLE_DESIGNS.md#p-10); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0505"></a>
## SC-0505 — Noor Is Alive

- **Chapter / mission:** CH05 / [M-0502](../07_MISSION_DESIGNS/M-0502_Permission_to_Answer.md)
- **Location / time:** LOC-01 / Dec 14 later
- **Cast / presence:** Physical: Commander Ferreira, Mei, Amara, Kai, Rafi. Remote: Rao (Earth). Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Deliver identity, consent and the emotional invitation.
- **Opening:** Rao’s call arrives with an attached consented archive page.
- **Environment:** Manifest signature aligns with N.R.; a portrait appears only after identification.

### Exact dialogue

- **DL-0505-01 · FER:** “Dr. Noor Rahman. Our gardener. From Bangladesh.”

- **DL-0505-02 · RAO:** “Noor is alive. She has read every one of your reports.”

- **DL-0505-03 · MEI:** “Why not tell us herself?”

- **DL-0505-04 · FER:** “She wanted you to discover the seeds. After we returned, she founded Last Light Academy in Bangladesh so new crews could finish her garden.”

- **DL-0505-05 · RAF:** “Then the Academy was her way of coming back.”

- **DL-0505-06 · MEI:** “We could use a friend.”

- **DL-0505-07 · FER:** “I promised to let you discover her seeds. I owed you the personal story sooner; safety was never part of that secret.”


### Play and presentation

- **Player objective:** Match the signed manifest and send Noor an invitation.
- **Player interactions:** Finish P-10 identity matching; choose one authored invitation and send the current garden photo; no wrong emotional choice.
- **Actions / animation:** Mei slides the photo beside the old portrait, leaving both intact.
- **Camera:** Return from portrait to player’s hands; no single extended exposition cutscene.
- **Sound / atmosphere:** Low Noor motif joins Alo theme; radio remains clear.
- **Discovery:** N is Noor, alive and the Academy founder; Rao has forwarded every report.
- **Journal copy:** N is Dr. Noor Rahman, the Academy founder. She is alive and has read every report forwarded by Rao.
- **Completion event EV-0505:** P-10 identity proof passed AND invitation sent; set noor_identity_revealed for captions/journal now, before the mission completion flag.
- **Persistence:** Once the above predicate passes, mark `SC-0505_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0506; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-10](../08_PUZZLE_DESIGNS.md#p-10); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0506"></a>
## SC-0506 — One More Seed

- **Chapter / mission:** CH05 / [M-0502](../07_MISSION_DESIGNS/M-0502_Permission_to_Answer.md)
- **Location / time:** LOC-03 / Dec 15 → Jan 12
- **Cast / presence:** Physical: Mei, Kai, Amara, Rafi, Commander Ferreira. Remote: Dr. Noor Rahman (text). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Turn the reveal into a new act of care.
- **Opening:** A short text reply waits beside the quarantine tray.
- **Environment:** One viable cotton specimen is released from quarantine; five remain sealed.

### Exact dialogue

- **DL-0506-01 · NOO:** “Thank you for asking. I would like to see what you grow next.”

- **DL-0506-02 · KAI:** “We know what this one is.”

- **DL-0506-03 · MEI:** “Cotton. A new seed. Another chance.”

- **DL-0506-04 · AMA:** “Cotton planted. Eleven other vault specimens stay protected.”

- **DL-0506-05 · RAF:** “I’ll make a smaller nameplate. We are running out of wall.”


### Play and presentation

- **Player objective:** Plant one approved cotton seed and retain eleven other vault specimens.
- **Player interactions:** Plant one approved cotton seed in the indoor reference bay, record the eleven other specimens, pin Noor’s text; accept transition to eclipse preparation.
- **Actions / animation:** Mei waters the cassette; no instant cotton boll or flower appears.
- **Camera:** Match opening packet framing; the new relationship is quiet.
- **Sound / atmosphere:** Water drop and ventilation; hopeful two-theme arrangement.
- **Discovery:** Cotton’s final survival is prepared months before the ending.
- **Journal copy:** Noor replied to our invitation. We planted one cotton seed from the recovered lot and retained the other eleven vault specimens.
- **Completion event EV-0506:** Cotton planted AND eleven unplanted vault specimens confirmed AND Noor reply read; commit M-0502.
- **Persistence:** Once the above predicate passes, mark `SC-0506_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0601; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-10](../08_PUZZLE_DESIGNS.md#p-10); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).
