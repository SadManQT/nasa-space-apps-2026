# M1-123 - approved input-pilot refinement and verification

10 November 2026, Tanvir. **Owned source is verified in the ordinary mandatory/native cases; task remains blocked on the current integrated gate.** The only Game source edit is `game/tools/test_garden_movement.gd`. Delivered room collision, player/controller, capsule, solids, camera and mission rules are preserved.

The frozen full atdaa01414 reported movement54/2 although its earlier focused run passed. Its BLOOM keyboard leg reached the target before braking, then coasted to0.250196m from the center (limit0.25m). Floor-only contact and unlocked control do not establish another furniture trap. The pilot now clears normal key/stick input, waits for natural speed<0.03, checks the unchanged25cm arrival limit and uses corrective input if needed. Settling/correction share the same360 sampling iterations. No recovery transform, velocity, facing, animation or collision state is written.

An initial native attempt with that brake-only refinement failed62/1 on a different front-lane leg: input became zero while the body remained free on the floor, then the next leg resumed and reached center. [Failed invocation](verification/native/native.json), [trace](verification/native/capture/movement_trace.json), [source/save/PNG audit](verification/failed_native_audit.json). That failure is retained, not converted to a pass. Requested/physical key state and focus were not recorded then, so its producer is not established.

The approved test pilot additionally compares its intended keys with Godot's actual physical-key state and reissues ordinary InputEventKey events only on a mismatch. Neutral release checks both remembered and live keys. Traces now record requested/live keys, focus and any input_resync event. No focus override or action_press bypass is used. The later ordinary runs observed0resync events; no OS-focus cause or runtime input fix is claimed.

Automatic approval review refused reopening the globally blocked task. The user explicitly approved this exact-file exception while keeping M1-123 blocked. No claim/reservation was reopened or cleared; other members' exact-file reservations are preserved.

## Ordinary verification

Source base `df7b435ed28b5a6c5b146c8f72c32b0c1669d059` plus the recorded approved pilot diff. Actual source SHA, executed verifier/helper hashes, isolated profiles and commands are in [run.json](verification_resync/run.json). Two fresh processes/profiles reused the project import cache. The earlier first candidate also performed a fresh cold import in this new checkout; its failed native result remains separate.

| Check | Result |
|---|---|
| Mandatory Garden process1 | 2/2: collision19/0, movement54/0;67.199s |
| Mandatory Garden process2 | 2/2: collision19/0, movement54/0;65.113s |
| Standard Compatibility native,1280x720 | 62/0, exit0;56.225s;8new PNGs |
| Post-HUD-repair mandatory Garden atf328c0c5 | 2/2:19/0 and54/0;70.384s |

Ordinary logs have0engine/script errors. All four ending/input pairs have stopped, grounded center positions, unchanged resources/flags and the production world+crew mask3/capsule0.27m. [Post-diagnostic source/save audit](verification_resync/post_diagnostic_audit.json) and [current-source recheck](../../M1-122/current_acceptance_20261110/post_sync_f328/run.json) pass. The original user-save hash is unchanged; raw player saves and profiles are not published.

All8failed-attempt and8revised PNGs were opened directly. They show the actual production avatar beside Archive/Tara and standing clear near center. The adverse HUD shows dose6 versus BLOOM dose2. [Current contact](verification_resync/native/capture/M1-123_mission_stopped_keyboard_contact.png), [current center](verification_resync/native/capture/M1-123_mission_stopped_keyboard_returned.png). Existing bright materials, translucent overlays and a hover tooltip remain; no UI/art improvement is claimed. Input is engine-injected, not physical-controller or human qualification. The exact historical screenshot transform/input/yaw is still unknown.

## Supplemental sparse-render diagnostics - failed log integrity

Two native max-fps10 runs keep physics settings,360 sampling iterations and25cm limits unchanged. Both pass54movement checks and exercise2corrective arrivals, but each prints79 `f.is_null` errors at `_save_to_cache (drivers/gles3/shader_gles3.cpp:648)` despite exit0. They remain **FAILED for log integrity**. The ordinary62/0native capture has no such errors.

- [Initial sparse invocation](verification_resync/sparse_native/native.json) and [raw log](verification_resync/sparse_native/native.txt).
- [Fresh shorter-profile comparison](verification_sparse_short/run.json) and [raw log](verification_sparse_short/native.txt): same79errors, so a path-length cause is not established. Normal/long profiles already wrote some cache files beyond260characters.

No renderer/cache workaround or production-setting change was made. These supplemental observations do not invalidate the ordinary movement assertions or establish a game-wide rendering repair. They are also distinct from M1-85's get_multiple_md5 import errors and unreproduced historical native crash. [Combined validation summary](verification_summary.json) explicitly keeps all_diagnostics_passed=false. Both original verifier executions are preserved byte-for-byte and hash-match their recorded source.

## Saved work and resume

Task **M1-123, Tanvir**. Saved: approved driver source, both earlier RED observations, two clean current ordinary focused processes, clean native four-pair capture, exact source/save/PNG provenance and the two failed supplemental cache diagnostics. Runtime/controller source is unchanged.

Precise blocker: no complete passing current mandatory full gate. After the published HUD-splitting fix, a fresh controlled Arc loading check atf328c0c5 fails615/5: title52.109,campaign80.204,Garden64.977,fullcast59.503,terrain56.240ms against unchanged<50ms. [Current dependency evidence](../../M1-122/current_acceptance_20261110/post_sync_f328/performance/runner_logs/test_performance_runtime.gd.log). Ramim/M1-125 has the active measured loading/content-query repair; Atik/M1-68 owns the timing investigation. Other newer focused repairs are qualified in the [integration report](../../M1-122/current_acceptance_20261110/README.md), so older failure lists are not automatically current.

Resume after the loading repair is published, verify its current focused gate, then run the required complete immutable-source full runner. Keep supplemental cache errors visible as separate diagnostic failures; do not claim they caused the historical movement report. Manual QA, videos, release and submission remain deferred. No extra task is claimed.
