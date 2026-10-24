# Project review and story consistency report

Reviewed 24 October 2026. Result: the game-design folder contained substantial drift from the main story and existing gameplay specification. The implementation companion has been corrected to follow those sources. This is a document review and repair; the game remains unimplemented.

## Scope and authority

The project inventory contains 102 non-system files: the root navigation/package files, eight documents under `docs/`, 47 pitch/production references and 45 game-design documents. The review compared the main narrative and gameplay sources with all eight chapter scripts, sixteen missions, puzzle contracts, character/world/system specifications, dialogue, production handoffs and acceptance criteria. Versioned pitch scripts, narration, subtitles, manifests and edit plans were inspected for story framing, dependencies and structural consistency. External research claims, unavailable media and runtime behaviour were not independently verified.

Use [STORY_FINAL.md](../docs/STORY_FINAL.md) for the plot and [CAMPAIGN_SEASON1.md](../docs/CAMPAIGN_SEASON1.md) for the season. [GAMEPLAY_DESIGN_FINAL.md](../docs/GAMEPLAY_DESIGN_FINAL.md) resolves ambiguous mechanics in [GAME_PLAN_FINAL.md](../docs/GAME_PLAN_FINAL.md); [SCIENCE_AND_DATA.md](../docs/SCIENCE_AND_DATA.md) supplies the evidence/data plan. The game-design folder elaborates these sources. An earlier adaptation, an absent film, or an instruction remembered from another session cannot override them.

All 55 canonical `docs/` and archived `pitch-video/` files retain their original byte hashes. Root navigation and the game-design companion were edited. A pre-review snapshot was saved outside the project before changes.

## Corrections made

| Finding | Correction and resulting behaviour | Main implementation references |
|---|---|---|
| The design claimed the story/campaign files were missing and relied on four files from another checkout. | Replaced that provenance with the actual source hierarchy and local asset inventory. Removed reliance on a missing MP4, root SRT and .gitattributes. | 00, 01, 02, 14, 22 |
| An earlier “611 assertions” result was presented as evidence for this package. | Withdrew it; current executed checks and untested limits are reported below. | 00, this report |
| The design replaced the cooperative classroom premise with a solo-first adaptation. | Restored one-to-four-player role sharing, five modes, private role cards and a communication debrief. Solo still controls all roles; independent network play remains future scope. | 01, 10, 13 |
| The campaign expanded to 307 active minutes and a 5–6-hour promise. | Rebudgeted the sixteen missions to 240 minutes, within the source's 220–250-minute range. Restored Station Days and the 10–14-hour collection/replay target, subject to playtesting. | 01, 05, missions, 18, 20 |
| A polar season cycle became an exactly 365-day Earth year; Chapter 7 moved from February to March. | Restored April-to-April seasonal framing, February's counterfactual storm and approximately 350 days between winter windows. Scene dates are explicitly authored around the source estimates. | 02, 03, 05, scripts, 17 |
| Chapter 1's 2017 replay and Chapter 7's 2012 counterfactual became invented future storms. | Restored both source labels and the historical region-2673 feed. Historical measurements, future story dates, game exposure and fictional lunar damage stay distinct. | 02, 08, 10, 16, scripts |
| Noor ceased to be the Academy founder. | Restored her return to Bangladesh, founding Last Light Academy, Rao forwarding the reports, Chapter 5's identity/founder reveal and Chapter 7's explanation of the Academy name. | 02, 04, CH05/07, 11 |
| Ferreira confessed her Expedition Zero role in Chapter 3, weakening Chapter 5. | Chapter 2's voice remains a suspicion; Chapter 3 supplies safety notes; Chapter 4's inscription prompts her silence; the confession occurs in Chapter 5. Safety instructions are never withheld. | 04, CH02–05, 11, 17 |
| Chapter 2 omitted N.'s yellow-mustard-fields clue, the colour prediction and its later payoff. | Restored the archive clue, purple-stemmed Alo/green-stemmed Tara, three reciprocal bee runs across seven dated days, explicit route costs and Chapter 4 phenotype comparison. No offspring ratio is guaranteed. | 04, P-03/04, CH02/04, 11, 14 |
| Chapter 4 sent three cadets out and left one at base. | Rafi and Kai take the rover; Mei and Amara run the base with the slope map. Field casts, camera direction, radio dialogue and mission copies now agree. Three beacons are tested before blind corners. | 03, P-07, CH04, 09, 12 |
| A diverse twelve-seed vault became six mustard and six cotton seeds. | Restored twelve distinct specimen types, including cotton. Separated physical founder harvest42, vault12 and album16. Cotton planting leaves eleven other vault specimens; album entries do not generate physical seeds. | P-08, CH04/05, 10, 18, 20 |
| Chapter 5's observation/maintenance toy became a short identity puzzle. | Restored six verified impact flashes, optional eight-flash mastery, dust cleaning, dome repair and protective-upgrade alternatives. Noor's signed identity and invitation remain. | P-10, CH05, 10, 20 |
| The eclipse lost Kai's family call and some of the established emotional context. | Restored the childhood-blackout memory, five acknowledged planning segments, family contact, Bangladesh sunrise connection on an illustrative diagram and the original planning payoff. Local sky/timing claims remain tagged until verified. | P-11/12, CH06, 11, 16 |
| Chapter 1 changed resource names, starting values, heat damage, water/thirst rules, crate limits and Golden conditions. | Restored the source E/A/H/W/K/C/R/Z contract, all four outcomes, one exclusive alarm action, partial/full action rules, exposure-before-drain ordering and no free daytime crate staging. | P-02, M-0102, 13, 20 |
| The new Chapter 1 Golden witness depended on different rules. | Recalculated Bloom, Golden, PUMP and STACK examples under the restored source rules. Exactly zero energy is distinguished from a negative-demand blackout. | P-02 worked examples |
| Chapter 7 used five steps, a different shield model and four-person air consumption despite Ferreira being present. | Restored six steps/three waves and source shielding, with explicit five-person air/food rates. Worked baseline ends E6,A2.5,H1,C3,R9,Z0. | P-13/14, CH07, 20 |
| Upgrades, collection counts, side stories, healthy recovery and postgame were largely absent. | Restored seven upgrade pairs,24 logs,32 cards,16 cultivar entries,12 patches,8 postcards, lineage,24 stars/8 Golden Blooms, eight side stories and the source postgame modes. Runtime implementation and complete-path balance remain future work. | 10, 14, 19, 20, 22 |
| The finale changed the route to 140 km and did not bind link restoration to the Earth-set handover. | Restored about 120 km, explicit24-hour outbound/return travel, separate local/Earth links, azimuth/elevation aiming and the source handover climax, with accessible equivalents. | 03, P-15/16, CH08, 09, 12, 17 |
| The finale's base budget did not account for the three travellers returning before dawn. | Accounted for two home occupants for33 hours, then five for3 hours. Base air use2.8125; E20/A8/H6 entry ends E5/A5.1875/H1 under COOL/DIM. Rover E14 minus ten total leaves4, above reserve2;72-hour provisions cover51 hours. | P-15, 03, 20 |
| Two location gates required committed flags before the scenes that commit them. | Annex viewing can use leak_sealed_pending inside M-0301; vault approach can use ice_survey_pending inside M-0401. Following missions still require committed flags. | LOC-02/10, 09 |
| Generic dialogue triggers could play Earth-set and the particle alarm immediately on entering the scene. | Bound the drill to shift2, Mei's card to3, Earth-set speech to4 and alarm lines to5. Skip only acknowledges the current beat. | CH01, M-0102 |
| The data plan became optional “NASA-inspired” flavour. | Restored the named source-integration obligations. A labelled prototype fallback does not fulfil a release claim of measured charts or computed local geometry. | 16, 18, 19, 22 |

## Useful clarifications retained

The old frozen garden contains unflowered seedlings, preserving Alo's first-bloom achievement. Alo matures and dies naturally; later plants descend from Alo × Tara. Dry-down is dated before harvest 40 days after planting, and the original42=12+30 ledger remains intact. Pressurised chambers and sealed pollen transfer preserve the exterior plant premise. The vault was deposited on an earlier survey, avoiding an impossible last-minute trip. Ferreira's scheduled December arrival explains her later physical presence. Local radios survive the direct Earth-uplink fault; repeaters make the Malapert bypass a real two-link task. Cotton is planted well before the finale. MARS remains optional after the complete ending.

An exact 2033 deployment/eclipse backstory was removed: the main story supplies an earlier eclipse memory without specifying that date. The February-to-April interval explicitly shows stable local operations and relay preparation; it does not leave the crew in an ignored life-support emergency. None of these clarifications asserts a surveyed route, verified local sky or flight-certified shielding.

## Executed verification

Current document audit: **zero reported errors** in the following checks.

- 45 game-design Markdown files: 21 top-level specifications,8 scene scripts and16 mission specifications.
- 48 scene gates,16 puzzle definitions and a16-mission dependency chain from arrival_accepted to campaign_complete, with three owned scenes per mission and no missing predecessor.
- 273 exact English dialogue lines matched between scene scripts and the dialogue index; duplicate line IDs checked.
- 240 active mission minutes; chapter totals28/23/25/33/25/25/38/43 fit the original ranges.
- Local game-design Markdown links/anchors and numbered puzzle/asset/location/system references resolved; balanced code fences checked. The final pass resolves 529 local game-design links/anchors.
- Four JSON files parsed; eight SRT files checked across 414 cues for positive durations and chronological start order. This does not verify speech synchronisation or film content.
- The final-production manifest's source SHA-256 matches its supplied VIDEOPITCH_FINAL.md. Production input paths still describe assets to supply in the render environment.
- All55 original docs/pitch files retain their byte hashes.
- Recalculated all four Chapter 1 worked paths and the Chapter 7/finale budgets; checked42=12+30, vault12=1+11, album16=2+12+2 and51<=72 hours of rover provisions.

The prior audit numbers were not reused. These checks concern the documents and their arithmetic, not an engine build.

## Remaining production work and limits

No executable, Godot project, editable models, MP4/audio files or processed NASA datasets are included in this export. The historical pitch reports refer to their original production environments; version folders may deliberately retain different timings, wording, spoilers and missing render-script paths. They are archived references, not alternate game canon. Their media was not played or visually reviewed here.

Before release: implement and playtest the game, validate every upgrade path and mode, complete the optional-content targets, acquire licensed assets, translate/review Bangla, verify saves/accessibility/performance, integrate the NASA data and validate local sky/route geometry. The eclipse fallback allocation and other teaching profiles are explicitly [G]/[E] until replaced or calibrated; no fresh scientific, competition-rule or engine-version verification is claimed. The original source's broad radiation/first-flower promises must retain the companion's fictional-history and biological qualifications in educational material.

The hackathon deliverable remains Chapter 1 and its season-map/message/Tara ending, with a Chapter 2 sample secondary. The full season and collection systems are later production. Neither has been represented as built or playtested by this review.
