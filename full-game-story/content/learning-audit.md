# Learning and continuity audit

Reviewed 25 October 2026. The review concerns the complete expedition story edition and its learning design. It is a document audit, not a tested game.

## Reviewed final files

| File | SHA-256 |
|---|---|
| [chapters-1-4.json](chapters-1-4.json) | `6e66b6fae4ed52c0310ce81b7a8fe1f0ae7c1091bd3637c9eeae47dd2d431ef0` |
| [chapters-5-8.json](chapters-5-8.json) | `4dcf70e6a5b983bdfbbca0c1ba0e39fc8019d422ba1f8de8cc300548a06ec62c` |
| [learning-and-continuity.json](learning-and-continuity.json) | `3855307a8b74e295061dacfcd864c486ca41c098afe34ea7bebab0dfb91f9b65` |

Any later narrative edit requires the affected checks to be repeated; these hashes identify the reviewed versions.

## Scope and results

All **96 scene prose passages, 385 dialogue lines, choices and exit conditions** were read. The review followed all eight chapter transitions and checked player actions, mission groupings, learning artifacts, source references and evidence boundaries. The final prose contains **17,735 whitespace-separated words**, counting only `scene.prose`; scene prose ranges from **166 to 209 words**. Dialogue, teaching notes, missions, summaries and production notes are additional material and are excluded from that word count.

Executed structural checks passed for eight chapters, four missions per chapter, twelve scenes per chapter, 96 sequential unique scene IDs, 385 unique dialogue IDs, at least four dialogue lines and three player actions per scene, the five required learning fields, allowed evidence tags, and resolvable source references. Every three-scene mission sums to its declared duration; chapter targets are **75 / 75 / 85 / 90 / 85 / 85 / 105 / 120 minutes = 720 minutes**. Per-chapter brisk and deliberate budgets sum **600 and 840 minutes**.

All three duration profiles contain the same 32 mandatory missions and 96 scenes. No side quest, collection threshold, compulsory failure, repeat campaign or real-time plant/travel wait contributes to the advertised 10-14-hour target. Dated transitions represent biological development, cruise, resupply and routine care; required intervening tasks account for the changes. Playtesting must still establish whether the resulting action and discussion density actually produces these durations.

## Required mission decisions

Every three-scene mission contains at least one explicit prediction, diagnostic interpretation, resource-plan comparison, safety-boundary test or evidence decision with contrasting feedback and a checked convergence. Cosmetic response/inspection-order studies remain as flavour; they are not counted as the main engineering decisions.

| Chapter | Mission 1 anchor | Mission 2 anchor | Mission 3 anchor | Mission 4 anchor |
|---|---|---|---|---|
| 1 | S01: surplus-energy destination | S06: shelter-water return schedule | S07: shared daylight allocation | S10: legal shelter response forecast |
| 2 | S03: containment and attributable tools | S04: compatible reciprocal pollen route | S08: trial-stage evidence | S10: resemblance versus verified identity |
| 3 | S02: pressure-tap fault localisation | S04: evidence before reopening | S09: maturity before dry-down/harvest | S10: physical seed allocation |
| 4 | S03: slope and two-way reserve | S05: calibrated sample/control interpretation | S07: sealed recovery procedure | S10: physical stock versus album knowledge |
| 5 | S01: five-person occupancy | S04: archive growth-stage interpretation | S07: paired impact evidence versus artifact | S12: cotton/vault inventory |
| 6 | S03: five-segment load allocation | S04: useful light versus reserve cost | S07: physical eclipse explanation | S10: isolate a bounded feeder fault |
| 7 | S02: changed occupant demand | S04: exposure-before-drain order | S09: external path versus local network | S11: two-leg relay topology |
| 8 | S02: safe road and return reserve | S05: two-then-five base occupancy | S08: both relay legs | S11: consumption follows actual return |

Scene IDs in the table expand as `EX-CHxx-Sxx`. These are design decisions and feedback contracts, not already executed game logic.

## Findings corrected during review

| Finding | Final correction and recheck |
|---|---|
| Chapter 1 initially committed both daylight shifts before performing the shift-2 drill. | S07 commits only shift 1 and stages shift 2. S08 performs the no-cost drill within shift 2, verifies unchanged state and commits at 18:00. |
| Chapter 5 initially assumed ownership of Dust Shield/Whipple protection before its post-chapter award. | S08 now requires the actual cleaning and isolated patch, verifies independent results, and earns protection only afterward for future maintenance. |
| Inherited old-trial descriptions mixed a strict seedling stage with flower buds. | The 2034 trial now contains young unflowered seedlings with curled leaves only: no flower buds, open flowers, pollination or seed production. Prose, dialogue, choices, exit conditions and learning locks were checked for residual old-bud wording. New 2046 Alo/Tara buds remain valid. |
| Three repeaters were once described as three surface links. | The topology is Aurora -> R1 -> R2 -> R3 -> summit: three repeater sites and four surface hops, plus the separate Earth leg. The adjacent-link checks and convergence text agree. |
| Post-exposure clearance readings were placed at the exact instant the last exposure sample ended. | CH07-S09 now occurs after 01:12 through the separated clearance-reading interval; exterior preparation waits for the required second check. |
| A returned ALO42 string was called a computed checksum. | CH08-S09 now teaches a known-content test phrase/current echo, checked for exact content and current session. It does not equate an echo with a checksum algorithm. |
| The final cotton payoff referred back to a history lesson absent from this standalone opening. | CH01-S03 now contains a short 2019 sealed Chang'e-4 cotton record and dialogue. SRC-COTTON2019 cites the experiment team's publication; CH04 recognition and CH08 continuation now have an explicit setup. No tissue-death temperature is invented. |
| A draft explained avoidance of backwards time inside the story prose. | The final CH03 sequence gives a natural camera-only May 7 clearance, followed by suited May 8 entry; the editorial bug explanation was removed. |

## Cross-chapter continuity checked

- Four qualified young adults occupy Aurora before December. Ferreira's scheduled December 8-12 journey is shown; five lunar occupants are counted afterward. Rao and Noor remain Earth-based.
- Before Chapter 5, the archive provides clues and an engineering-voice resemblance without a false death, a fabricated betrayal, an early full personal revelation or withheld safety procedures. Chapter 5 establishes the connection through acquired signed evidence and consent.
- Live, local, archived, queued and text messages are distinguished. The first night has no live Earth reply after its cutoff; contact returns in Chapter 2. Noor's earlier recordings/text are not live calls. Her first live voice occurs in Chapter 8 after the relay tests.
- Alo and Tara have separate identities and compatible reciprocal pollination; harvest follows maturity and dry-down. The original Alo finishes its life naturally. The founder ledger remains **42 = 12 planted + 30 reserve**; later gardens are dated descendants, and Tara remains in the parent line.
- The old 2034 garden never flowered. The vault was placed on an earlier authorised survey, avoiding an impossible evacuation-time crater journey.
- The vault contains **12 distinct specimens**. Cotton planting on December 15 leaves **11 other specimens** stored. Album/cultivar knowledge never creates physical seed stock. Cotton is not planted at the finale and instantly mature.
- Chapter 4 has Rafi/Kai in the rover and Mei/Amara at base. Return, quarantine, controlled sealed warming and inventory precede opening the lid record. The May-October generation/supply bridge and October-December relief bridge are explicit.
- Chapter 1 uses the labelled 2017 historical replay; Chapter 7 uses the labelled 2012 counterfactual. The local atmosphere, pressure, oxygen generation, carbon-dioxide removal and plant needs retain distinct functions.
- The January eclipse date is sourced, while exact Aurora viewing geometry stays authored/pending. The five-segment teaching allocation is charged once; January monitoring does not precisely predict February's event.
- Chapter 7's six steps account for five occupants. The final exposure is evaluated before draining shielding water. External uplink damage does not destroy local radios; safe February-April care, supplies and relay preparation are shown before departure.
- The final three-person rover journey is **24 h out + 3 h repair + 24 h back = 51 h**, covered by **72 h provisions**. Departure April 8 00:00, summit April 9 00:00, return begins 03:00, home April 10 03:00, dawn 06:00.
- Aurora has **two occupants for 33 h**, then **five for the last 3 h** of its 36-hour scenario night. Travellers do not consume base resources while their support comes from the rover.
- The finale tests the Aurora-to-Malapert path and Malapert-to-Earth path independently, then verifies current content and voices. Both teams return before the garden ending. Descendants, preserved petal, protected seeds and living cotton close the story; the closed MARS still is only an after-credits possibility and adds no activity.

## Source and teaching review

Fifteen source cards have bounded supported claims and direct references to NASA, JPL, ESA, Wisconsin Fast Plants and the Chang'e-4 experiment-team publication. Source-card identifiers are unique; chapter learning references and narrative repository/source-card references resolve. The January 12, 2047 total-eclipse date was checked in the NASA catalog. Source pages were reviewed for the general lunar environment, polar light/shadow, separate ECLSS functions, pollination/lifecycle, seismic hazards, ice evidence, impact-flash validation, eclipse optics, historical solar events, shielding principles and relay line-of-sight.

The story distinguishes historical observation, computation only after verification, game rules and authored fiction. No newly computed Aurora sky, surveyed 120-km road, measured lunar dose, universal water-wall guarantee, exact future NASA flight assignment, genetically guaranteed stem ratio or award outcome is claimed. The original cotton germination achievement is respected; this fictional future does not rewrite the real experiment.

## Verification limits

This audit found no unresolved contradiction within the checked final document scope. It does not prove that the finished game will be error-free or that its runtime meets the proposed duration. There is no playable engine implementation, balance test over every upgrade combination, user study, localization/editorial signoff, processed NASA dataset, actual local-horizon/antenna computation, physical safety certification or measured learning-gain result in this story export. HTML rendering, keyboard/mobile behavior and local packaging are verified separately by the parent.

Before production release, implement and playtest the mission contracts, inspect asset and botanical continuity, validate saves/checkpoints/accessibility, review the complete scientific displays with relevant specialists and recheck any changed real-world claims. Reading and assistance must continue to preserve access to the same complete ending.
