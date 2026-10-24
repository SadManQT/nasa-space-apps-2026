# Development roadmap — future work only

No milestones have been implemented by this task. These documents establish the design; source integration, balancing and paper playtests still remain before production lock; future implementation and production validation remain separate. Dependencies are sequential to control risk, not a claim of a fixed development schedule.

## MS-01 — Content lock and paper walkthrough

- **Required design documents:** 00, 01, 02, 03, 04, 05, 08, 16, 21; number references name corresponding files in [index](00_README.md).
- **Systems / work:** No implementation yet; rehearse mission interactions and numeric witness plans using documents.
- **Scenes:** All 48 scene gates, all 16 puzzle witnesses.
- **Assets:** Reference the available pitch scripts/asset inventory, no new production assets.
- **Dependencies:** None.
- **Completion criteria:** Every mandatory decision answerable; producer signs continuity and science labels.
- **Testing:** Walk all missions in order; reconcile seeds/time/physical presence; record wording changes before build.
- **Review boundary:** Confirm the delivered milestone against these criteria before broadening scope; do not replace a missing mission with a pitch montage.

## MS-02 — Shared expedition foundation

- **Required design documents:** 09, 10, 11, 13, 18, 20; number references name corresponding files in [index](00_README.md).
- **Systems / work:** SYS-01/02/03/05/07/08/10/11/12 foundations in a future build.
- **Scenes:** Commons, services, garden, airlock, shelter; SC-0101–03.
- **Assets:** A-01–04,A-10–20,A-34,A-48–61; temporary art permitted.
- **Dependencies:** MS-01.
- **Completion criteria:** Can walk, inspect, converse, plant, switch local role, journal, save and reload with exact text.
- **Testing:** Controller/keyboard/large-text checks; reload each objective; no duplicate seed items.
- **Review boundary:** Confirm the delivered milestone against these criteria before broadening scope; do not replace a missing mission with a pitch montage.

## MS-03 — Playable Chapter 1 vertical slice

- **Required design documents:** CHAPTER_01, M-0101/0102, 08, 12, 18, 20; number references name corresponding files in [index](00_README.md).
- **Systems / work:** SYS-04/09; seven shifts; preview parity; local endings; no false simulation reveal.
- **Scenes:** SC-0101–06 including sunrise and recorder.
- **Assets:** A-05/06,A-12–24,A-28/29 plus foundation.
- **Dependencies:** MS-02.
- **Completion criteria:** Complete chapter and all four local outcome paths; successful route unlocks CH02; demo can shorten travel/read time only.
- **Testing:** Run Bloom/Golden/PUMP/STACK/WAIT witnesses, unsafe oxygen/dose/plant branches, save mid-shift.
- **Review boundary:** Confirm the delivered milestone against these criteria before broadening scope; do not replace a missing mission with a pitch montage.

## MS-04 — Living legacy and evidence

- **Required design documents:** CHAPTER_02/03, M-0201–0302, 04, 08, 11, 20; number references name corresponding files in [index](00_README.md).
- **Systems / work:** Pollination, independent gauge, evidence reconstruction, harvest/lineage.
- **Scenes:** SC-0201–0306.
- **Assets:** A-17–19,A-25–30,A-38 plus shared.
- **Dependencies:** MS-03.
- **Completion criteria:** Playable pollination→quake→harvest; 42 seeds reconcile; no immortal Alo or early Noor portrait.
- **Testing:** Wrong pollen, dirty brush, wrong valve, immature harvest, evidence order, retry and skip knowledge tests.
- **Review boundary:** Confirm the delivered milestone against these criteria before broadening scope; do not replace a missing mission with a pitch montage.

## MS-05 — First exterior expedition

- **Required design documents:** CHAPTER_04, M-0401/0402, 08, 09, 10, 20; number references name corresponding files in [index](00_README.md).
- **Systems / work:** SYS-06 rover, route reserves, sampling, closed vault transfer/quarantine.
- **Scenes:** SC-0401–06.
- **Assets:** A-08,A-31–38,A-45 terrain subset.
- **Dependencies:** MS-04.
- **Completion criteria:** Round trip works with safe route and preserved specimens; arrival plan establishes Ferreira travel.
- **Testing:** Reject short steep route, missing calibration, early vault opening; guided travel parity; save at markers.
- **Review boundary:** Confirm the delivered milestone against these criteria before broadening scope; do not replace a missing mission with a pitch montage.

## MS-06 — Truth and the eclipse

- **Required design documents:** CHAPTER_05/06, M-0501–0602, 03, 04, 11, 12, 16, 20; number references name corresponding files in [index](00_README.md).
- **Systems / work:** Arrival staging, evidence/consent reveal, camera observation, protected feeder transfer.
- **Scenes:** SC-0501–0606.
- **Assets:** A-07,A-09,A-38–42,A-61 plus shared.
- **Dependencies:** MS-05.
- **Completion criteria:** Ferreira local from Dec 12; Noor identity earned; Kai payoff interactive; cotton planted before finale.
- **Testing:** Noor portrait/label gates, both factual choices and all invitations, hot pixel, F2 interlock, mute/caption tests.
- **Review boundary:** Confirm the delivered milestone against these criteria before broadening scope; do not replace a missing mission with a pitch montage.

## MS-07 — Storm, road and complete ending

- **Required design documents:** CHAPTER_07/08, M-0701–0802, 08, 09, 12, 17, 18, 20; number references name corresponding files in [index](00_README.md).
- **Systems / work:** Integrated storm plan, five-person shelter, cross-team handover, repeaters, dual-link relay, credits.
- **Scenes:** SC-0701–0806.
- **Assets:** A-13,A-16,A-22/23,A-28/29,A-31,A-33/34,A-41–47 plus shared.
- **Dependencies:** MS-06.
- **Completion criteria:** One continuous start-to-credits campaign; every major question answered; final garden and safe Continue.
- **Testing:** Storm witness, route clearance, missing spare, remote switching, wrong tuner order, return-time/seed ledger, skip end/call.
- **Review boundary:** Confirm the delivered milestone against these criteria before broadening scope; do not replace a missing mission with a pitch montage.

## MS-08 — Release presentation and acceptance

- **Required design documents:** All documents, especially 13–16, 20, 22; number references name corresponding files in [index](00_README.md).
- **Systems / work:** Finalize assets, Bangla text, sound, assistance, offline packaging and credits; no new systems without scope review.
- **Scenes:** All 48 scenes and every menu.
- **Assets:** All P0 assets; P1 only after mandatory completion.
- **Dependencies:** MS-07.
- **Completion criteria:** Entire game meets acceptance matrix, no P0 blocker, truthful source/fiction labels and content credits.
- **Testing:** Full clean install/offline run, all checkpoints, controller-only/no-timer/150%text, native Bangla review, target hardware performance and audio intelligibility.
- **Review boundary:** Confirm the delivered milestone against these criteria before broadening scope; do not replace a missing mission with a pitch montage.

## Must-have versus optional polish

Must: all 8 chapters/16 missions/48 scenes for the full-season release; every dialogue fact in text; 16 solvable puzzles; safe retries and saves; both route trips; complete Noor/Kai/Alo/Ferreira resolutions; final mixed garden; English/Bangla text; offline solo; Class facilitation; readable controls/contrast/no-timer alternatives; correct sources and credits.

Optional: fully recorded voices, photo filters, printable patch, clap input, additional ambient conversations, highly detailed Earth screen portrait animation, extra plant nicknames. Network co-op and a playable Mars season are future options. Source collection/progression systems remain part of the full season. No optional polish can become a new prerequisite for finishing an existing mission.

## Production estimates and risk handling

Assign estimates after MS-03 establishes actual interaction/animation cost. Do not promise this full adventure can be completed in one hackathon. Highest costs:48 scene performances and state testing, plant-stage animation, cross-team finale/save semantics, Bangla layout, rover comfort. Mitigations: shared room/rig/tool kits, text-complete story before VO, short authored driving, one model per system with variants, strict mission-state reuse. If capacity is limited, deliver the labelled Chapter 1 slice first while retaining the complete design; do not advertise it as the finished full campaign.

## Separate delivery gates

Hackathon: complete Chapter 1 (25–30-minute target), all four outcomes, N. recording/Tara, season map with later chapters locked, Solo/Class and the required bundled source evidence. Optional five-minute Chapter 2 sample only after that slice works. Full season: every chapter plus persistent upgrades, Station Days, album/mastery and postgame defined in SYS-07/09 and the campaign progression section. Neither milestone is achieved by this document-only review. Preserve the source rule that actual game building begins during the authorised hackathon; this review creates no game code.
