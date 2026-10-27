# EX-M0504 — Permission to Answer

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Identify Noor, invite contact and plant cotton. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [full-game-story/story-data.json](../full-game-story/story-data.json)
- [full-game-story/STORY_FULL.md](../full-game-story/STORY_FULL.md)
- [production/manifest/scene_index.csv](../production/manifest/scene_index.csv)
- [production/audio/vo_lines.csv](../production/audio/vo_lines.csv)
- [game-design/08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md)
- [game-design/09_WORLD_AND_LEVEL_DESIGN.md](../game-design/09_WORLD_AND_LEVEL_DESIGN.md)


## Ownership and dependencies

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch05/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0503`; SYS02..08; chapter puzzles P-09, P-10; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


## Detailed work sequence

1. Verify predecessor, chapter entry profile, roster, location, time and acquired knowledge before constructing this mission scene/data.
2. Map every listed player action and exit conjunct to an explicit predicate/interaction/evidence owner. Publish this gate map before wiring visuals.
3. Assemble the required rooms/props with current assets, stable anchors and correct physical positions; use shared dialogue/UI/audio services.
4. Implement the three scenes in order; use the relevant shared puzzle stages rather than a second numerical model. A response/inspection choice may converge while its feedback remains distinct.
5. Keep active interaction time substantive through observation, setup, hypothesis-testing, consequences and team communication; fictional days/cruise advance only at accepted gates.
6. Wire exact line IDs, origin/speaker labels, acquired evidence, source boundaries, captions and optional assistance. Apply current English-only/natural plant overrides to any older source label.
7. Test invalid action, partial response, cancel, repeat input, pause, save/load, retry and boundary hand off; preserve authoritative receipts/inventories/actor locations.
8. Run through this mission from its actual predecessor and into its successor, producing a short trace with all gate predicates and the resulting snapshot.


## Task-specific source and implementation detail

### Chapter contract

Chapter 5:**Shooting Stars**; dates: 12–15 December 2046; chapter target: 85 minutes.

A physical handover leads to an investigation of Expedition Zero, accountable conversation, impact observation and maintenance. Consented records identify Noor as the living Academy founder. A respectful invitation leads to cotton planting and carefully separated seed ledgers.

Emotional arc:Anticipation → discomfort → accountability → wonder → connection..

This mission target: 20 active minutes. Predecessor:`EX-M0503`. Successor:`EX-M0601`. Chapter puzzle families: P-09, P-10; reuse their single shared implementations and map the actual relevant stages.

### EX-CH05-S10 — The Name on the Page
**Target:**6 minutes. **Location:**Mission table, live Earth data link. **POV:**Mei. **Story time:**14 December, later. **Legacy provenance:**`SC-0505`.

Rao's call arrives with a signed page and a permission note. The player checks its signature against the recovered manifest. N.R. is no longer an invitation to guess a name. It is Dr. Noor Rahman, the botanist who left the seeds, returned to Bangladesh and founded Last Light Academy.

Rao says she has read the crew's transmitted reports. Transmitted matters: Noor did not see through April's Earth blackout and never watched private moments through an invisible camera. The player opens the receipt list, comparing creation times with delivery after contact returned. Mei finds the first bloom photograph and the forty-two-seed harvest entry. Support has an actual information path.

Ferreira explains that Noor wanted future crews to finish a garden her own expedition left unfinished. This does not make the cadets actors in a secret test. Their repairs and decisions belonged to them. The player places the signed page beside the anonymous packet image. Only after the shared reveal does the journal expand the initials into Noor's full name.

**Exact dialogue**

- `EX-CH05-S10-L01` **Rao (live Earth link):** She gave permission to share the page.
- `EX-CH05-S10-L02` **Ferreira:** Dr. Noor Rahman. Our gardener, from Bangladesh.
- `EX-CH05-S10-L03` **Mei:** She read the reports we sent?
- `EX-CH05-S10-L04` **Rao (live Earth link):** Every one that reached Earth.

**Required player actions**

1. Match identity records.
2. Check report delivery receipts.
3. Update shared journal knowledge.

**Decision study and planned feedback**

Open a report receipt.
- **First bloom:** It shows when Noor could see the photo.
- **Harvest forty-two:** It connects later knowledge with delivered evidence.

**Convergence:**Noor identity, survival and founder role established with consented evidence..

**Learning loop**

- **Concept:** Information provenance
- **Predict:** What can someone know without a connection?
- **Observe:** Compare creation and receipt timestamps.
- **Explain:** Records can arrive later than their events.
- **Transfer:** Check who received information before assuming shared knowledge.

**Mandatory exit condition:**Noor identity, survival and founder role established with consented evidence.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH05-S11 — An Invitation, Not an Answer Owed
**Target:**7 minutes. **Location:**Message composer at the mission table. **POV:**Mei. **Story time:**14 December, after the reveal. **Legacy provenance:**`SC-0505`.

The composer offers a current garden photograph and a cursor. Mei spent months wanting an answer from N. Now that the name is known, the first sentence feels harder. Kai suggests sending every graph. Amara says the graphs can be attachments. The player decides what the invitation itself should ask.

Both authored invitations leave Noor a choice. One asks whether she would like to see the next stage. The other says a place for her work remains at their table. Neither demands a reply, accuses her of abandoning anyone or turns a private history into a puzzle prize. The camera stays on Mei's hands while the player checks the text.

Rao confirms delivery through the available Earth path. No immediate voice sounds from the speaker. The crew finishes its checked report while the new relationship waits at its own pace. Ferreira places her mug beside four familiar ones. The table has not gained a magical sixth occupant. It has gained a connection to someone who may choose a later conversation.

**Exact dialogue**

- `EX-CH05-S11-L01` **Kai:** Should we send every graph?
- `EX-CH05-S11-L02` **Amara:** Attachments can do that.
- `EX-CH05-S11-L03` **Mei:** The invitation should sound like one.
- `EX-CH05-S11-L04` **Ferreira:** Leave her room to answer.

**Required player actions**

1. Choose a respectful authored invitation.
2. Attach photo and checked report.
3. Send and retain the delivery receipt.

**Decision study and planned feedback**

How should the invitation begin?
- **Would you like to see what grows next?:** It offers a future conversation.
- **We kept a place for your work.:** It acknowledges contribution without demanding contact.

**Convergence:**Invitation delivered once; first live Noor voice remains reserved for Chapter 8..

**Learning loop**

- **Concept:** Respectful collaboration
- **Predict:** Does a story entitle us to someone's answer?
- **Observe:** Compare invitation with demand.
- **Explain:** Participation can be invited without being forced.
- **Transfer:** Ask clearly while leaving space for consent.

**Mandatory exit condition:**Invitation delivered once; first live Noor voice remains reserved for Chapter 8.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH05-S12 — One More Seed
**Target:**7 minutes. **Location:**Aurora indoor reference bay. **POV:**Mei. **Story time:**15 December; dated care into January. **Legacy provenance:**`SC-0506`.

Noor replies in text the next day. She thanks the crew for asking and would like to see what grows next. Mei pins the message where a gardener can read it without bending over the console. The player opens the approved quarantine record, not the entire seed case.

One viable cotton specimen is cleared for the indoor reference bay. Eleven other vault specimens remain protected. Amara reads those quantities aloud, then closes that ledger before opening the separate founder reserve: thirty original Alo-by-Tara seeds, still sealed. No inventory gains a seed because an album picture was unlocked.

Planting repeats the opening game's gesture with better understanding. The player labels the cassette, checks the medium and closes the pressure-safe bay. No cotton flower appears on command. A dated montage shows leaves and repeated care over subsequent weeks while Alo's descendants continue nearby. Mei places the preserved petal beside the label. It remembers an individual; the living room continues a lineage. Kai has already begun marking the guide-light circuit for January's eclipse. At chapter completion, the player selects Dust Shield or Whipple protection for later chapters, with neither option required to solve today's maintenance.

**Exact dialogue**

- `EX-CH05-S12-L01` **Noor (text):** Thank you for asking. I would like to see what you grow next.
- `EX-CH05-S12-L02` **Amara:** Cotton planted. Eleven other vault specimens protected.
- `EX-CH05-S12-L03` **Rafi:** Founder reserve is a separate ledger.
- `EX-CH05-S12-L04` **Mei:** A new seed, not the old flower returning.

**Required player actions**

1. Plant one cleared cotton specimen.
2. Confirm eleven retained vault types and thirty founder seeds separately.
3. Record dated care before January.

**Decision study and planned feedback**

Which physical inventory closes after planting cotton?
- **One planted plus eleven other vault specimens:** The vault ledger reconciles 12 while the founder 30 stays separate.
- **Sixteen minus one equals fifteen stored:** Sixteen counts album entries; the mismatched physical ledger is rejected for correction.

**Convergence:**Cotton 1 + retainedvault 11 reconciles vault 12; founder 30 remains a distinct protected stock..

**Learning loop**

- **Concept:** Inventory and living continuity
- **Predict:** Does an album entry create a seed?
- **Observe:** Reconcile planted cotton, retained specimens and founder reserve.
- **Explain:** Distinct inventories cannot be combined as one stock.
- **Transfer:** Separate physical quantities from records and achievements.

**Mandatory exit condition:**Cotton planted Dec 15; eleven vault specimens and thirty founder seeds protected.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Ferreira arrives Dec 12; Rao and Noor remain on Earth.
- Noor is identified here; no live Noor voice before CH08.
- Cotton 1 planted +11 vault specimens retained; founder reserve 30 separate.
- Alo remains a petal and lineage, never resurrected.
- Dust Shield/Whipple pair is earned only after CH05; the chapter's cleaning and patching remain mandatory.
- The 2034 trays contain young unflowered seedlings and curled leaves only; no flower buds or reproductive development.

### Production constraints
- Camera-monitored safe landing.
- Amplified impact flashes without meteor trails.
- Correct stale source count to eleven retained specimens.
- All twelve scenes are required; each has a player evidence gate.
- The impact classification sequence is authored teaching content; do not label its individual flashes as imported historical observations without an actual dataset.

### Chapter bridge
Dated cotton care and a five-person handover lead to January's eclipse.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- Exactly the quoted three final scene IDs complete once before the next mission unlocks.
- Every required action has actual gameplay and observable feedback; a film/dialogue click does not replace it.
- Exit predicates, learning evidence, roster, time, knowledge and numeric state agree with canon.
- The mission integrates with the previous/next mission under a validated save/checkpoint, not a disconnected devdemo.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
