> **Administrative ownership update —10Nov2026:** M1-122 and M1-123 are now assigned to **Tanvir**, together with M1-85, under [CURRENT_BATCH.md](../../../../plan/CURRENT_BATCH.md). Tanvir may implement the task-scoped room/world/player fixes after publishing exact-file reservations. Do not wait solely for the former Sadman/Atik owner labels in the historical report below. M1-65 manual playtesting is deferred. This update changes assignment only; it does not claim a collision fix or new test pass.

# M1-65 T02: Garden movement/collision report, 9 November 2026

**Status: geometry mismatches measured; proposed repair not applied; the reported real-player stop remains unresolved.** Sadman owns room repair M1-122; Atik owns live-controller reproduction M1-123. M1-65 remains incomplete.

## Player evidence

Tanvir reported: "I cant go in this way here / some invisible obstacle is stopping my way fix this kinda bugs" and supplied a screenshot in this conversation. Asked which direction, he answered **"Back toward the room's center"** (not toward the Commons door).

The image shows Chapter 1, 26 to 27 April 2046/dark shifts 6 and 7; goal "Review how the night ended"; Seed Archive, Tara/Indoor Reference and the Commons doorway. It also shows battery 2/20, shelter 1/6 and radiation dose 6 with an over-limit notice. These displayed values do not establish a cause of movement failure. The exact keys, camera yaw, body coordinates and executable revision are unrecorded. No duration, new participant, successful earlier gate, ending completion or fresh-player result is inferred. The screenshot is in chat, not archived as a repository image. A read-only local save metadata check returned EX-CH01-S11; that does not certify the screenshot's exact position/build.

## Source and measurement

Pulled main before working; tested source `d59f426eec16d1dad3dc65ec771c4752e1e20cef` (main 0e266bc plus Tanvir's QA claim). The base LOC-03 obstacle dimensions match the earlier 2a506b6 QA source; later staging work does not supply an exact replay of the player's movement.

[probe_garden.gd](probe_garden.gd) builds the production LOC-03 room in EX-CH01-S11 context. It takes the production player capsule (radius 0.27 m, height 1.7 m), removes the controller/animation script and queries actual static physics. [garden_probe.json](garden_probe.json) retains the grid, collider paths, visible mesh bounds and candidate motions; [run metadata](garden_probe_run.json) records source hashes.

| Object | Visible geometry | Current collision | Finding |
|---|---|---|---|
| Tara bay | Bench 1.7 x 0.8 x 1.1 m, plus central enclosure about 0.782 m on each axis | Full 1.7 x 1.6 x 1.1 m box | Empty upper air outside the enclosure is blocked. The solid bench footprint itself is legitimate. |
| Crop rack | X[-5.260542,-4.539459], Z[0.576803,2.023197], height 2 m | X[-5.25,-4.55], Z[0.45,2.15], height 2 m | Proxy extends about 12.7 cm beyond each visible Z end and is slightly narrow in X. |
| Seed Archive | Visible 1.4 x 1.3 x 0.6 m box | Matching 1.4 x 1.3 x 0.6 m box | No matching-size defect established. |

From the clean candidate start(-4.4,0.04,-2.2), a direct diagonal toward the center contacts `CollisionRoot/tara_bay`; a separate +Z leg contacts `crop_rack`. A route via(-4.4,-0.5), then(0,-0.5), then(0,0.5) remains clear on the original geometry. The alternative start(-4.2,-2.3) already overlaps the Archive and is excluded as a clean repair reproduction.

**These are static capsule contacts, not a replay of Tanvir's movement.** `_motion` uses `move_and_collide` and stops at its first contact. The real controller uses `move_and_slide`, steering and step-up. A valid collision with the solid bench is not proof of an invisible-wall bug or a movement deadlock. NPCs, the actual camera/input/pose state and exact historical position were not reproduced.

## Unapplied geometry proposal

[proposed_LOC-03_collision.patch](proposed_LOC-03_collision.patch) changes only the room data: preserve Tara's bench-sized blocker, add a separate conservative 0.8 m enclosure box, and tighten the crop-rack box to 0.73 x 2.01 x 1.46 m. [proposed_obstacles.json](proposed_obstacles.json) contains the same values for the diagnostic capture. The crop-rack proposal conservatively encloses the measured visible bounds. `git apply --check` passes; `game/resources/campaign/rooms/LOC-03.json` is unchanged in this checkout.

[verify_candidate.gd](verify_candidate.gd) changes these shapes **in memory only**. It corrects two specific excess-collision cases while preserving bench/rack solidity and the already-clear route around the bench. It does not widen that route or remove the solid bench from a diagonal walk. Applying this proposal alone must not be called a complete fix for the player's report. Navigation is not rebuilt by this fixture; the room owner must test the actual JSON application and generated navigation.

| Verification | Result |
|---|---|
| Mandatory `game/tools/run_tests.sh habitat_rooms` | **1/1 suites passed**, 359 checks/0 failures, exit 0; [summary](habitat_runner.txt), [metadata](habitat_run.json), full logs under `habitat_rooms/` |
| Diagnostic collection | 2 checks/0 failures, exit 0; PASS means data collection only |
| Proposed assertions against original collision | **RED: 7 checks/2 failures**, exit 1, specifically upper-air and rack-front clearance; [log](baseline_red/run.txt), [trace](baseline_red/candidate_trace.json) |
| Same assertions with runtime-only candidate | **GREEN: 7 checks/0 failures**, exit 0; preserved solid furniture and all return-route legs; [log](candidate_green/run.txt), [trace](candidate_green/candidate_trace.json) |
| Compatibility diagnostic capture | 2 PNG writes/0 failures, exit 0; [run](capture_run.json) and [log](capture.txt) |

The [current](M1-65_collision_current.png) and [proposed](M1-65_collision_proposed.png) images were opened and inspected. Red lines show physics boxes; blue represents the capsule dimensions at a candidate location. Labels explicitly say diagnostic/non-live and NOT APPLIED. They are not images of a fixed game or a real-controller playthrough. The rack is mostly outside this camera view; its overhang evidence is numerical. The initial capture script failed to parse due to inferred directory type; [failed log](capture_initial_parse_error.txt) and metadata are retained. An explicit String annotation fixed the capture-only error, then the camera was reframed to show Tara clearly. The passing room suite and geometry assertions do not use this capture script.

## Owner acceptance and remaining work

- **Sadman M1-122:** review/apply the narrow data patch or an equivalent geometry-aligned repair; audit nearby proxies and return-lane clarity; preserve furniture solidity. Run mandatory relevant room/staging/navigation checks and full runner after application; capture actual before/after geometry. Only Sadman edits the room/world files under the current ownership rules.
- **Atik M1-123:** reproduce the reported EX-CH01-S11 movement with real input/controller, logging camera yaw, input vector, player transform/placement/action state and named contacts. Use an isolated checkpoint copy; fix an established runtime cause or publish exact layout clearance for Sadman. Preserve the global capsule, normal collision, pressure doors, mission gates and saved expedition. No noclip, teleport or auto-completion workaround counts as repair.
- The original checkout's unfinished collision work was read as history and left untouched. Tanvir's existing local editor/import changes are preserved; QA scripts write only their own evidence and do not write expedition saves. No game process is left running.
- No full regression, live player replay, fixed-build claim, chapter gate or new human session is certified. Existing onboarding/physical-work findings remain open. Independent second-AI review passed with no material finding, while retaining all limits above.
