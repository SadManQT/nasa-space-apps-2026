# Last Light Academy — Complete Game Production Bible

Version 1.1 ·24 October 2026 · status: **reviewed design documentation; game not implemented**.

Start with [vision](01_GAME_VISION.md), [definitive story](02_COMPLETE_STORY.md), [timeline](03_STORY_TIMELINE.md), then [chapter breakdown](05_CHAPTER_BREAKDOWN.md). A developer should read [puzzle contracts](08_PUZZLE_DESIGNS.md), [technical blueprint](18_TECHNICAL_BLUEPRINT.md) and [acceptance tests](20_TESTING_AND_ACCEPTANCE.md) before building.

## Source and authority

The source documents are present in this package: [main story](../docs/STORY_FINAL.md), [Season 1](../docs/CAMPAIGN_SEASON1.md), [game plan](../docs/GAME_PLAN_FINAL.md), [3D gameplay specification](../docs/GAMEPLAY_DESIGN_FINAL.md), and [science/data plan](../docs/SCIENCE_AND_DATA.md). Their hierarchy is defined in [01](01_GAME_VISION.md#authority). The root README and versioned pitch material provide context, not a replacement canon. No earlier conversation or missing film is authority for this review.

This folder is the implementation companion to those sources. Version 1.1 corrects drift found on 24 October 2026. The story remains a fictional expedition using explicitly labelled historical replays and measured/estimated/game/fiction tags. No engine project, runtime assets or processed NASA dataset is included.

## Contents

- [01_GAME_VISION.md](01_GAME_VISION.md)

- [02_COMPLETE_STORY.md](02_COMPLETE_STORY.md)

- [03_STORY_TIMELINE.md](03_STORY_TIMELINE.md)

- [04_CHARACTER_BIBLE.md](04_CHARACTER_BIBLE.md)

- [05_CHAPTER_BREAKDOWN.md](05_CHAPTER_BREAKDOWN.md)

- [08_PUZZLE_DESIGNS.md](08_PUZZLE_DESIGNS.md)

- [09_WORLD_AND_LEVEL_DESIGN.md](09_WORLD_AND_LEVEL_DESIGN.md)

- [10_GAMEPLAY_SYSTEMS.md](10_GAMEPLAY_SYSTEMS.md)

- [11_DIALOGUE_MASTER.md](11_DIALOGUE_MASTER.md)

- [12_CINEMATIC_DIRECTION.md](12_CINEMATIC_DIRECTION.md)

- [13_UI_UX_DESIGN.md](13_UI_UX_DESIGN.md)

- [14_ASSET_PRODUCTION_LIST.md](14_ASSET_PRODUCTION_LIST.md)

- [15_AUDIO_AND_MUSIC_DIRECTION.md](15_AUDIO_AND_MUSIC_DIRECTION.md)

- [16_SCIENTIFIC_ACCURACY.md](16_SCIENTIFIC_ACCURACY.md)

- [17_GAME_FLOWCHARTS.md](17_GAME_FLOWCHARTS.md)

- [18_TECHNICAL_BLUEPRINT.md](18_TECHNICAL_BLUEPRINT.md)

- [19_DEVELOPMENT_ROADMAP.md](19_DEVELOPMENT_ROADMAP.md)

- [20_TESTING_AND_ACCEPTANCE.md](20_TESTING_AND_ACCEPTANCE.md)

- [21_STORY_CONSISTENCY_REPORT.md](21_STORY_CONSISTENCY_REPORT.md)

- [22_FINAL_PRODUCTION_CHECKLIST.md](22_FINAL_PRODUCTION_CHECKLIST.md)

## Scene scripts

- [CH01 — Night One](06_SCENE_SCRIPTS/CHAPTER_01.md): SC-0101 through SC-0106.

- [CH02 — Be the Bee](06_SCENE_SCRIPTS/CHAPTER_02.md): SC-0201 through SC-0206.

- [CH03 — Moonquake](06_SCENE_SCRIPTS/CHAPTER_03.md): SC-0301 through SC-0306.

- [CH04 — Into the Cold Trap](06_SCENE_SCRIPTS/CHAPTER_04.md): SC-0401 through SC-0406.

- [CH05 — Shooting Stars](06_SCENE_SCRIPTS/CHAPTER_05.md): SC-0501 through SC-0506.

- [CH06 — The Red Ring](06_SCENE_SCRIPTS/CHAPTER_06.md): SC-0601 through SC-0606.

- [CH07 — The Great Storm](06_SCENE_SCRIPTS/CHAPTER_07.md): SC-0701 through SC-0706.

- [CH08 — The Lighthouse](06_SCENE_SCRIPTS/CHAPTER_08.md): SC-0801 through SC-0806.

## Mission traceability

| Mission | Scenes | Puzzle | Completion → next |
|---|---|---|---|
| [M-0101 — A Drawer of Light](07_MISSION_DESIGNS/M-0101_A_Drawer_of_Light.md) | SC-0101, SC-0102, SC-0103 | [P-01](08_PUZZLE_DESIGNS.md#p-01) | pair_planted → M-0102 |
| [M-0102 — Keep the Night](07_MISSION_DESIGNS/M-0102_Keep_the_Night.md) | SC-0104, SC-0105, SC-0106 | [P-02](08_PUZZLE_DESIGNS.md#p-02) | first_bloom → M-0201 |
| [M-0201 — Borrow a Bee](07_MISSION_DESIGNS/M-0201_Borrow_a_Bee.md) | SC-0201, SC-0202, SC-0203 | [P-03](08_PUZZLE_DESIGNS.md#p-03) | pollen_shared → M-0202 |
| [M-0202 — A Voice Before Us](07_MISSION_DESIGNS/M-0202_A_Voice_Before_Us.md) | SC-0204, SC-0205, SC-0206 | [P-04](08_PUZZLE_DESIGNS.md#p-04) | recorder_context → M-0301 |
| [M-0301 — Numbers That Disagree](07_MISSION_DESIGNS/M-0301_Numbers_That_Disagree.md) | SC-0301, SC-0302, SC-0303 | [P-05](08_PUZZLE_DESIGNS.md#p-05) | leak_sealed → M-0302 |
| [M-0302 — Forty-Two](07_MISSION_DESIGNS/M-0302_Forty-Two.md) | SC-0304, SC-0305, SC-0306 | [P-06](08_PUZZLE_DESIGNS.md#p-06) | seed_legacy → M-0401 |
| [M-0401 — Where the Sun Cannot Follow](07_MISSION_DESIGNS/M-0401_Where_the_Sun_Cannot_Follow.md) | SC-0401, SC-0402, SC-0403 | [P-07](08_PUZZLE_DESIGNS.md#p-07) | ice_survey → M-0402 |
| [M-0402 — Twelve in the Dark](07_MISSION_DESIGNS/M-0402_Twelve_in_the_Dark.md) | SC-0404, SC-0405, SC-0406 | [P-08](08_PUZZLE_DESIGNS.md#p-08) | vault_recovered → M-0501 |
| [M-0501 — The Engineer Comes Home](07_MISSION_DESIGNS/M-0501_The_Engineer_Comes_Home.md) | SC-0501, SC-0502, SC-0503 | [P-09](08_PUZZLE_DESIGNS.md#p-09) | zero_sequence → M-0502 |
| [M-0502 — Permission to Answer](07_MISSION_DESIGNS/M-0502_Permission_to_Answer.md) | SC-0504, SC-0505, SC-0506 | [P-10](08_PUZZLE_DESIGNS.md#p-10) | noor_known → M-0601 |
| [M-0601 — A Plan for Darkness](07_MISSION_DESIGNS/M-0601_A_Plan_for_Darkness.md) | SC-0601, SC-0602, SC-0603 | [P-11](08_PUZZLE_DESIGNS.md#p-11) | eclipse_ready → M-0602 |
| [M-0602 — All the Sunrises](07_MISSION_DESIGNS/M-0602_All_the_Sunrises.md) | SC-0604, SC-0605, SC-0606 | [P-12](08_PUZZLE_DESIGNS.md#p-12) | kai_supported → M-0701 |
| [M-0701 — Your Call, Cadets](07_MISSION_DESIGNS/M-0701_Your_Call_Cadets.md) | SC-0701, SC-0702, SC-0703 | [P-13](08_PUZZLE_DESIGNS.md#p-13) | storm_prepared → M-0702 |
| [M-0702 — What We Carry](07_MISSION_DESIGNS/M-0702_What_We_Carry.md) | SC-0704, SC-0705, SC-0706 | [P-14](08_PUZZLE_DESIGNS.md#p-14) | route_clear → M-0801 |
| [M-0801 — The Long Road](07_MISSION_DESIGNS/M-0801_The_Long_Road.md) | SC-0801, SC-0802, SC-0803 | [P-15](08_PUZZLE_DESIGNS.md#p-15) | summit_reached → M-0802 |
| [M-0802 — From Last Light to First Light](07_MISSION_DESIGNS/M-0802_From_Last_Light_to_First_Light.md) | SC-0804, SC-0805, SC-0806 | [P-16](08_PUZZLE_DESIGNS.md#p-16) | campaign_complete → credits / safe final garden |

## Review and production status

The full folder review and corrections are recorded in [21_STORY_CONSISTENCY_REPORT.md](21_STORY_CONSISTENCY_REPORT.md). The earlier “611 assertions / four preserved source files” result belonged to another source snapshot and is withdrawn. Current checks cover local links, identifiers, mission dependencies, dialogue parity, pacing, inventory and worked resource calculations; they do not certify gameplay, rendering or scientific computation.

Implementation, translation review, asset production, NASA data processing, upgrade-path balance and classroom playtests remain future work. Read [testing](20_TESTING_AND_ACCEPTANCE.md), [roadmap](19_DEVELOPMENT_ROADMAP.md) and [checklist](22_FINAL_PRODUCTION_CHECKLIST.md) before production. The hackathon slice and full-season release have separate completion gates.

## Current executed document checks — 24 October 2026

45 design files; 48 scenes; 16 missions; 16 puzzle definitions; 273 matching scene/dialogue lines; 529 valid local links/anchors; 240 active mission minutes. The project-wide pass also parsed 4 JSON files, checked 8 subtitle files/414 cue intervals and confirmed all 55 canonical docs/pitch hashes unchanged. Published Chapter 1 plan rows were executed in a temporary source-rule calculation; all four match their documented final totals. These are document/number checks, not a running-game or external-science certification.
