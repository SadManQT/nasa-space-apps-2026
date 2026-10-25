# Last Light Academy — extended story edition

User request: a compelling, coherent 10–14-hour junior-astronaut experience, delivered as a polished offline HTML story bible for a professional development/art team. Local files only; do not push or publish. Existing canonical documents are read-only.

## Shared authorship contract

Preserve plot and eight chapters from docs/STORY_FINAL.md and docs/CAMPAIGN_SEASON1.md; resolve chronology/physical presence with game-design/03_STORY_TIMELINE.md, characters with 04_CHARACTER_BIBLE.md, and survival mechanics with 08_PUZZLE_DESIGNS.md. This is a newly authored expansion, not a claim that the game exists or that target playtimes have been playtested.

USER CONFIRMED: THE ENTIRE MAIN CAMPAIGN MUST BE 10–14 HOURS. NO SIDE CONTENT, OPTIONAL MISSIONS, MASTERY PADDING OR COLLECTION GRIND. The standalone edition supersedes the previous four-hour scope. Target720 active minutes (12hours): all32missions and96scenes mandatory. Brisk/guided traversal targets600minutes; deliberate reading/planning targets840minutes over the SAME complete content. These are design budgets, not measured playtests. No fabricated waiting, mandatory failure, repeated campaign runs or resource grinding. All eight chapters form one causally connected campaign.

Core chapter minutes: [75,75,85,90,85,85,105,120]=720. Exactly12 main scenes per chapter, EX-CH01-S01 through EX-CH08-S12, four missions per chapter EX-M0101..EX-M0804, three consecutive scenes per mission. All are required and consequential. Retain the original major puzzle functions/outcomes; new linked engineering investigations, setup, evidence checking and consequences deepen the main story. New dialogue uses EX-CHxx-Sxx-Lxx IDs; legacyScene identifies originalSCwhenadapted. Finished prose150–220Englishwords/scene, at least4actual dialogue lines/scene, meaningful actions/choices/feedback. English body copy for studio use; Bengali reading guidance and summaries added centrally. Do not lengthen a cutscene to pretend it is playable time.

Character ages: Kai19, Mei19, Amara20, Rafi20; young learners are the audience, not unsupervised child astronauts. Ferreira is Earth-based until scheduled Dec12 2046 arrival; local thereafter. Rao and Noor remain on Earth. Nobody teleports. Local radios survive Earth outages. No live Noor voice before CH08; earlier archive recordings/text are labelled. Reveal Noor's identity, survival and Academy-founder role at CH05; hint only earlier. Safety instructions are never concealed for mystery.

Alo and Tara planted Apr11 2046, bloom Apr27/Apr30, cross-pollinate Apr30–May6. Alo harvest May21: exactly42=12 planted+30 reserve. Original Alo dies naturally after seed maturity; later flowers are descendants. Old2034 garden contains unflowered seedlings, never previous lunar blooms. Vault contains12 distinct specimens; cotton planted Dec15 leaves11 stored. Album16 cultivar entries is a different thing from physical seeds. Do not invent additional fixed physical harvests. Cotton survives finale; no resurrected Alo. No harvest, radiation immunity, atmosphere, plant oxygen or pollination misconceptions.

CH01 2017 historical solar-event replay; CH07 explicitly counterfactual2012 replay, with five occupants including Ferreira. Future story dates are fiction; 36h scenario night/local sky not independently computed. Jan12 2047 eclipse calendar date does not prove Aurora's site-specific view; camera/illustrative fallback. Endings: Golden Bloom/Bloom/Alo lost/Mission stopped. Loss endings close respectfully and retry locally; only a successful Bloom advances this expedition campaign, assisted play remains valid and has equal story access.

CH04 Rafi+Kai rover, Mei+Amara base. CH08 Ferreira+Kai+Rafi rover, Mei+Amara base. Finale120km out24h + repair3h + back24h=51h, provisions72h. Apr8 00 depart, Apr9 00 arrive, Apr9 03 return starts, Apr10 03 home, Apr10 06 dawn. Base occupants2 for33h then5 for3h. Final radio repairs a local Aurora-to-Malapert link AND an Earth link. CH07 damage to external uplink persists until this bypass; Feb–Apr safe local operation/preparation shown explicitly. Final garden is an established renewing garden surviving its next seasonal dark window. MARS drawer only after complete ending.

Modes share outcomes; assist never removes rewards. Pause/reading/exploration do not secretly spend oxygen. No actual studio assets or runtime assumed. All science statements distinguish observed source, computed only after verification, simulated gameplay, fictional events. Do not claim award guarantees.

## Chapter JSON schema

Each chapter object: id(integer), title, subtitle, date, coreMinutes(integer), summary, emotionalArc, openingHook, transitionOut, missions(array of {id,title,minutes,goal}), scenes(array of exactly12), learning(array3), continuity(array), production(array).

Each scene: id(EX-CHxx-Sxx), legacyScene(originalSCornew), title, minutes(integer; scene sum equals coreMinutes), location, pointOfView, storyTime, prose(150–220 English words of finished narrative), dialogue(array of at least4 {speaker,line}), playerActions(array3), choice({prompt,options:[{label,consequence},{label,consequence}],convergence}), learning({concept,predict,observe,explain,transfer}), exitCondition, evidenceTag(one of Observed/Computed-pending/Simulated/Fiction), sourceRefs(array source IDs from sources.json or repo paths). Options cannot break future canon; exploratory and stylistic outcomes may differ while hard safety gates stay shared.

Chapter agents write ONLY their assigned JSON and an accompanying notes.md in content/. Do not edit HTML or other agents' files. JSON UTF8 and valid. New prose elaborates required playable beats using twelve expansion scene IDs per chapter and preserves prerequisite chronology; consult existing CHAPTER_0x.md scenes for legacy mapping.

## Learning and audit package

Third agent writes content/learning-and-continuity.json: eight chapter entries (chapter, question, misconception, predict, test, observe, explain, transfer, evidenceArtifact, assessment, accessibility, scienceBoundary), a global 12-item continuityLock array, canonChanges explaining mandatory12hour expansion without plot replacement, and primary-source cards. It will subsequently audit narrative outputs with file/scene-specific findings. All learning is embedded in the mandatory mission route. Do not create side activities or mastery padding.

## Verification

Parent will assemble standalone index.html from data; validate schemas, IDs, timing arithmetic, reference edges, character presence and knowledge, scene/side ordering, seed/travel ledgers, links, keyboard/mobile rendering and interaction. Parent and a fresh reviewer then inspect cross-file contradictions. Record limits honestly; do not label untested gameplay or unresolved local astronomy as verified.
