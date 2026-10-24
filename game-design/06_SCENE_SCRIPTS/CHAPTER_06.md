# Chapter 06 — The Red Ring

Purpose: Courage is supported action while afraid.

## Script execution contract

Each section is a fully authored scene. Lines are exact English master dialogue; bracket-free speaker labels identify characters. NOO before Chapter 5 is an archive-only voice labelled “N. (recording)” in player-facing captions. The cadets do not know the author’s identity yet; Ferreira and Rao know the seed legacy but leave its personal connection for the Chapter 5 reveal. Safety information is always shared. Remote speakers use screens/radio, not physical NPCs. Alo and Tara react visually and never have dialogue. Critical speech has caption/read-transcript parity. The dialogue master is indexed by line ID. Scene gates are mandatory, ordered and saved; cinematic skipping acknowledges dialogue but never bypasses a puzzle or fakes a physical interaction.

<a id="sc-0601"></a>
## SC-0601 — The Lamp Is Still Here

- **Chapter / mission:** CH06 / [M-0601](../07_MISSION_DESIGNS/M-0601_A_Plan_for_Darkness.md)
- **Location / time:** LOC-02 / Jan 12, before eclipse
- **Cast / presence:** Physical: Kai, Rafi, Amara, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Revisit Kai’s early fear without ridicule.
- **Opening:** Kai takes the same hand light from its locker.
- **Environment:** Eclipse schedule, protected bus diagram and the first plant photo remain nearby.

### Exact dialogue

- **DL-0601-01 · RAF:** “Important scientific lamp?”

- **DL-0601-02 · KAI:** “Very. I’m still afraid of the dark.”

- **DL-0601-03 · FER:** “Then we plan with that fact. We don’t pretend it vanished.”

- **DL-0601-04 · AMA:** “Which bus stays alive?”

- **DL-0601-05 · KAI:** “This one. I’ll show you.”


### Play and presentation

- **Player objective:** Charge the hand light and choose a companion for the transfer.
- **Player interactions:** Inspect Kai’s childhood storm-blackout memory, hand light charge, eclipse schedule and protected bus; select a companion to remain beside Kai during transfer.
- **Actions / animation:** Rafi remains within reach; Kai checks, rather than hides, the lamp.
- **Camera:** Return to SC-0103 framing; same object, changed ownership.
- **Sound / atmosphere:** Lamp click recalls opening; calm pulse, no horror sting.
- **Discovery:** Kai can name his fear and request support.
- **Journal copy:** Kai named his fear of darkness and asked for support. We can plan with that fact.
- **Completion event EV-0601:** Hand light charged AND eclipse schedule read AND companion assigned.
- **Persistence:** Once the above predicate passes, mark `SC-0601_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0602; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-11](../08_PUZZLE_DESIGNS.md#p-11); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0602"></a>
## SC-0602 — Three Loads, One Promise

- **Chapter / mission:** CH06 / [M-0601](../07_MISSION_DESIGNS/M-0601_A_Plan_for_Darkness.md)
- **Location / time:** LOC-02 / Jan 12 planning
- **Cast / presence:** Physical: Kai, Amara, Rafi, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Make Kai’s confidence emerge from a correct plan.
- **Opening:** The bus board lists mandatory services and optional loads.
- **Environment:** Four-step outage forecast; protected bus has six units.

### Exact dialogue

- **DL-0602-01 · KAI:** “We can lose the view screen. We can’t lose the return pump.”

- **DL-0602-02 · AMA:** “Air is already stored. Keep the scrubber powered.”

- **DL-0602-03 · RAF:** “Guide lights stay.”

- **DL-0602-04 · KAI:** “Guide lights stay. That is in the plan.”


### Play and presentation

- **Player objective:** Verify the protected-bus schedule.
- **Player interactions:** Complete P-11 transfer planning, shed optional loads and verify the protected services remain powered across all five segments.
- **Actions / animation:** Kai labels each cable route; Amara confirms aloud.
- **Camera:** Readable overhead board; cursor alternative to dragging.
- **Sound / atmosphere:** Four confirmation tones with distinct text indicators.
- **Discovery:** Planning includes emotional needs through low-power guide lights, not unnecessary floodlights.
- **Journal copy:** The eclipse plan keeps essentials and guide lights powered, with one return-pump operation and one camera operation.
- **Completion event EV-0602:** P-11 outage schedule verified.
- **Persistence:** Once the above predicate passes, mark `SC-0602_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0603; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-11](../08_PUZZLE_DESIGNS.md#p-11); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0603"></a>
## SC-0603 — Ready Is a Shared Word

- **Chapter / mission:** CH06 / [M-0601](../07_MISSION_DESIGNS/M-0601_A_Plan_for_Darkness.md)
- **Location / time:** LOC-01 / Jan 12 ingress readiness
- **Cast / presence:** Physical: Kai, Mei, Amara, Rafi, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Bring every companion into the upcoming event.
- **Opening:** The camera feed shows the Earth nearing the Sun.
- **Environment:** View shutter closed, feed online, local warning labels visible.

### Exact dialogue

- **DL-0603-01 · MEI:** “Plants steady.”

- **DL-0603-02 · AMA:** “Air steady.”

- **DL-0603-03 · RAF:** “Shelter and lamp ready.”

- **DL-0603-04 · FER:** “Your call, Kai.”

- **DL-0603-05 · KAI:** “Ready. All of us.”


### Play and presentation

- **Player objective:** Confirm readiness and enable the filtered camera.
- **Player interactions:** Confirm five segment acknowledgements and four role readiness checks and activate the external camera filter before viewing.
- **Actions / animation:** Everyone occupies a working position, not a semicircle of spectators.
- **Camera:** Player selects monitor focus; no forced look at bright Sun.
- **Sound / atmosphere:** Room quiets; breathing and switches remain.
- **Discovery:** The eclipse observation uses instruments with protection; no unfiltered solar viewing mechanic.
- **Journal copy:** Everyone confirmed their station before the eclipse observation.
- **Completion event EV-0603:** Five segment acknowledgements AND four role readiness confirmations AND filtered camera enabled; commit M-0601.
- **Persistence:** Once the above predicate passes, mark `SC-0603_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0604; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-11](../08_PUZZLE_DESIGNS.md#p-11); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0604"></a>
## SC-0604 — The Red Ring

- **Chapter / mission:** CH06 / [M-0602](../07_MISSION_DESIGNS/M-0602_All_the_Sunrises.md)
- **Location / time:** LOC-01 / Jan 12 eclipse window
- **Cast / presence:** Physical: Kai, Mei, Amara, Rafi, Commander Ferreira. Remote: Dr. Noor Rahman (text). Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Deliver wonder and the known Noor’s connection.
- **Opening:** A red atmospheric rim appears on the filtered monitor.
- **Environment:** An inset conceptual globe marks Bangladesh at the atmospheric limb; no resolved landscape claim.

### Exact dialogue

- **DL-0604-01 · MEI:** “Every sunrise and sunset at once.”

- **DL-0604-02 · AMA:** “Sunlight through the air around Earth. That’s the red.”

- **DL-0604-03 · KAI:** “Home is helping us see the dark.”

- **DL-0604-04 · NOO:** “I watched a red ring from there once. — N.”

- **DL-0604-05 · RAF:** “She signed it N.”

- **DL-0604-06 · MEI:** “Some names become yours twice.”


- **DL-0604-07 · MEI:** “One of those sunrises is over Bangladesh. We can mark it on the Earth diagram.”

- **DL-0604-08 · KAI:** “My family’s on the line. The dark is okay. If you know when it’s coming, you can get ready.”

### Play and presentation

- **Player objective:** Record ingress and the red ring on the filtered feed.
- **Player interactions:** Record three filtered observations in P-12: ingress, ring and egress; inspect the conceptual limb diagram and connect Kai’s family call during the valid Earth window. The Bangladesh inset is illustrative; precise sunrise timing awaits geometry verification.
- **Actions / animation:** One hand touches the screen bezel, not the scientific image.
- **Camera:** Monitor close-up with visible frame; 8 s optional quiet hold.
- **Sound / atmosphere:** Alo and Noor motifs share harmony; exterior remains silent.
- **Discovery:** N’s identity is already known; eclipse date is historical astronomy, local camera staging is authored.
- **Journal copy:** Sunlight refracted through Earth’s atmospheric limb makes the red rim. Noor sent a memory signed N.
- **Completion event EV-0604:** Ingress and ring observations logged AND diagram inspected AND family call connected; await feeder interruption.
- **Persistence:** Once the above predicate passes, mark `SC-0604_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0605; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-12](../08_PUZZLE_DESIGNS.md#p-12); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0605"></a>
## SC-0605 — The Next Light

- **Chapter / mission:** CH06 / [M-0602](../07_MISSION_DESIGNS/M-0602_All_the_Sunrises.md)
- **Location / time:** LOC-02 / Jan 12, during protected transfer
- **Cast / presence:** Physical: Kai, Rafi, Amara, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Interactive scientific challenge + contextual dialogue.
- **Narrative purpose:** Pay off fear through supported action.
- **Opening:** An unprotected feeder trips; guide lights remain on.
- **Environment:** Bus diagram retains the protected path; failed feeder is clearly labelled.

### Exact dialogue

- **DL-0605-01 · KAI:** “I’m here. Rafi, stay on the channel.”

- **DL-0605-02 · RAF:** “Here.”

- **DL-0605-03 · AMA:** “Protected bus holds. Isolate the failed feeder first.”

- **DL-0605-04 · KAI:** “Isolated. Reset, then test.”

- **DL-0605-05 · FER:** “Keep going. We’re with you.”

- **DL-0605-06 · KAI:** “I was afraid. I did it anyway.”


### Play and presentation

- **Player objective:** Isolate F2, reset safely and record egress.
- **Player interactions:** Finish P-12: isolate feeder F2, check zero fault indication, reset F2, test only the camera branch and log egress.
- **Actions / animation:** Kai uses the hand light and speaks each action; no shaking hands after correct completion.
- **Camera:** Player control remains; brief eye-level companion reaction afterward.
- **Sound / atmosphere:** Music recedes under instructions; normal fan bed returns on test.
- **Discovery:** Kai’s courage is a repeatable process with support, not absence of fear.
- **Journal copy:** Kai restored the failed feeder with Rafi and Amara on the channel. The protected bus stayed alive.
- **Completion event EV-0605:** P-12 F2 safely restored AND egress record saved.
- **Persistence:** Once the above predicate passes, mark `SC-0605_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0606; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-12](../08_PUZZLE_DESIGNS.md#p-12); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).

<a id="sc-0606"></a>
## SC-0606 — Keep Watching

- **Chapter / mission:** CH06 / [M-0602](../07_MISSION_DESIGNS/M-0602_All_the_Sunrises.md)
- **Location / time:** LOC-01 / Jan 13 → Feb 14
- **Cast / presence:** Physical: Kai, Mei, Amara, Rafi, Commander Ferreira. Remote: none. Archive: none.
- **Mode:** Exploration + scripted conversation.
- **Narrative purpose:** Bridge months without pretending an exact storm forecast.
- **Opening:** A solar monitor shows an active region on a routine image.
- **Environment:** Daily observation calendar, healthy cotton, flowering-generation records.

### Exact dialogue

- **DL-0606-01 · RAF:** “That region needs watching.”

- **DL-0606-02 · AMA:** “Watching is not predicting the date of a storm.”

- **DL-0606-03 · KAI:** “Then we watch, and keep the shelter ready.”

- **DL-0606-04 · MEI:** “And water the plants.”

- **DL-0606-05 · FER:** “Most expedition days look like that. Good work done before anyone applauds.”


### Play and presentation

- **Player objective:** Record the monitoring plan and check cotton and reserves.
- **Player interactions:** Pin a monitoring task, inspect cotton growth and reserve seal, accept a labelled routine-care montage ending at a fresh February warning.
- **Actions / animation:** Photos show routine repairs and new plant generations; crew clothes and labels evolve.
- **Camera:** Short match cuts across familiar rooms, never an unlabelled time jump.
- **Sound / atmosphere:** Domestic theme grows fuller; final warning interrupts gently before escalation.
- **Discovery:** January observation and February storm are separated by ongoing monitoring, not prophecy.
- **Journal copy:** We continued routine observations and care. A replay warning arrived in February; January’s image did not predict its date.
- **Completion event EV-0606:** Monitoring task pinned AND cotton/reserve checked AND dated transition accepted; commit M-0602.
- **Persistence:** Once the above predicate passes, mark `SC-0606_done`; actions remain idempotent on reload. Do not award a second physical item when revisiting.
- **Transition:** Unlock SC-0701; restore control at its named entrance after a time/location card whenever either changes.
- **References:** [puzzle P-12](../08_PUZZLE_DESIGNS.md#p-12); [location bible](../09_WORLD_AND_LEVEL_DESIGN.md); [cinematic guide](../12_CINEMATIC_DIRECTION.md).
