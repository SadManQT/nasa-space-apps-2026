# Prompt package validation

Checked 27 October 2026 against source HEAD `ca01433`. This report concerns the documentation pack.

## Executed coverage and structure checks

- **300 individual task prompts**, plus shared/navigation/validation documents.
- **75/75 registry entries** and **22 additional required asset families** have dedicated prompts.
- **32/32 mandatory missions, 96/96 scenes and 385/385 exact dialogue lines** are covered. Each scene has exactly one owning mission snapshot; prose, required actions and exit condition agree with its source.
- **385/385 voice CSV rows** resolve to the correct speaker prompt with exact line ID/text.
- **16/16 puzzles, 16 UI families, 18/18 cutscenes, 12/12 music cues, 35/35 SFX, 15 scientific evidence cards, 7 upgrade pairs, 4 endings and 3 animation families** have individual packets.
- **23 shared runtime systems** include actual boot/main-scene, biology, companions, puzzle host and portable test-harness ownership.
- **3742 local Markdown link targets** resolve across the current pack; task section completeness, minimum substance, UTF-8 replacement/private formatting tokens and code fences were checked.
- Existing CS-02/03 fallback-motion backlogs are explicitly retained; a present OGV does not prove those Seedance jobs completed.
- Existing full-game-story manifest files remain byte-identical.

## Findings: 0 structural/source-coverage errors

No structural or source-coverage error found in the executed checks.

## Verification limits

These checks do not execute the future game, asset generations, tool accounts, paid calls, renders, runtime tests, playtests or release. Prompt prose was spot-reviewed for source authority, ownership and current-state conflicts; no claim of independent line-by-line review of every new instruction is made. Executors must inspect current files, use shared contracts and produce the requested evidence before marking implementation complete.

## Per-family count

| Prefix | Task files |
|---|---|
|ANIMATION|3|
|ASSET|97|
|AUDIO|1|
|CUTSCENE|18|
|ENDING|4|
|MISSION|32|
|MUSIC|12|
|PUZZLE|16|
|QA|6|
|RELEASE|2|
|SCIENCE|15|
|SFX|35|
|SYS|23|
|UI|16|
|UPGRADE|7|
|VFX|3|
|VOICE|10|