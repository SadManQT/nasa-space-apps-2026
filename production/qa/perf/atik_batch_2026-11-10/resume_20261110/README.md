# Resumed Atik verification — 10 November 2026

Priority: M1-68. This run preserves the earlier batch evidence and fixes.

## First fresh integrated Mac gate (interrupted)

The full mandatory runner uses an isolated detached checkout of daa014145922e2646027140f3bd34c53a0afe3cb (game tree 1c3a0dd3517226d7c9c3a79138249593e4955d2a). All117 discovered suites are included. Runtime source and settings come from the committed checkout; the user's local import/settings edits remain in the original workspace. APFS copy-on-write clones preserve the3052 existing LFS files and existing import cache. No cache is deleted; no cold-cache or original-Windows result is inferred.

Only the whole-suite process timeout is1500s, to allow the known full-campaign
text sweep. Every assertion and the50ms loading gate are unchanged. There is a
separate5400s collection watchdog; reaching it would mean an incomplete failed
collection, not a full pass. Complete setup/suite/runner logs and result metadata
are retained under full/. Logic-file hashes before/after check source stability.

## Original Windows host access

The original Ryzen7 7700/RTX4060 and IntelArc130V machines are not exposed to this
session. No SSH config/host alias or remote-execution connector is available.
The repository's release workflow uses GitHub-hosted windows-latest/macOS runners,
which are not the original machines; release/package work remains deferred.
The requested connection/collection route was not supplied. There is no new
original-host evidence beyond the retained9 November captures. Metal/headless or
cloud-hosted runs cannot satisfy those host-specific conditions.

Required Ryzen-host collection: the existing collect_loading.py, two fresh
processes with LLA_RETAIN_LOAD_TRACE=1, normal caches retained, exact hardware and
source recorded, followed by the mandatory integrated full runner. Existing
M1-68.md contains the command and original path/hardware record. Passing retries
alone do not establish a timing cause or fix.

M1-53's raw AssetGeometry polling remains unbounded in current source; the saved
patch is not applied. The user leaves that change to Sadman. A reviewed owner
change is required before held-raw tests and ten consecutive full windowed probes.
M1-92 requires matching native campaign profiling and controlled measurements;
the previous unsymbolicated title sample is not campaign-cause proof. M1-116
requires the original Arc Windows/Vulkan host and process/thread diagnostics.
No task is marked Done by starting this collection.

The first collection was stopped after 1005.463s: 28 suites reported, six failed,
and the next UI suite printed a null-node SCRIPT ERROR then remained alive.
Its partial log, exact failures, interruption record and unchanged source hashes
are retained in full/. This is incomplete, not a full-suite result. Ramim has
active reservations for the affected gameplay/fixture files.

## Bounded runner repair

The runner now fails and stops its own child promptly after the same fatal
script diagnostics it already rejected at exit. TERM has a three-second grace
then KILL and reap, so a failed teardown cannot block the remaining gate.
The normal process guard remains 300s. PLAYER_TEXT_TIMEOUT optionally changes
only test_player_text.gd; the next full run uses 1500s for that known long walk.
No assertion, loading limit or gameplay was changed.

runner/red.txt reproduces the old live-engine hang in two injected scenarios.
runner/green.txt records all six unittest methods (13 scenarios), including
fatal errors after PASS, ignored TERM, and the text-only guard isolation.
A frozen-source full rerun will be recorded separately under full_bounded/.

## Additional original-host route check

The gh CLI is not installed. A noninteractive read-only request using the
repository credential to the GitHub self-hosted-runners API returned HTTP403:
“You must have repository read permissions or have the repository runners
fine-grained permission.” This does not prove no self-hosted runner exists;
it means this credential cannot enumerate or establish access through that route.
No workflow was launched and no hosted runner was substituted for either host.
The user’s instruction to proceed autonomously supplied no host connection data.

## Frozen bounded full rerun (complete, failed)

Source a2362955f204601d04d09e3e4e4073ee2e452a61, game tree
e149235dd5277ea93f7dc4b3058b878d52ab3b8c; all117 suites. This uses committed
settings and existing cloned caches. SUITE_TIMEOUT=300 and
PLAYER_TEXT_TIMEOUT=1500; loading assertions remain50ms. The5400s overall guard
still treats interruption as incomplete, never green. Source hashes, exact
manifest, all117 raw suite logs and final result are retained under full_bounded/.
The same fatal UI script error was stopped with process exit143, recorded as
failed, and the runner continued. Project settings still match committed source.

[M1-53 reviewed owner request](M1-53_REVIEW_REQUEST.md),
[M1-92 matching tools](M1-92_MATCHING_TOOLS.md), and
[M1-116 original-host evidence](M1-116_ORIGINAL_HOST.md) preserve each separate
resume condition. None of the four tasks is marked Done.

## Retained original Ryzen evidence identity

The existing9 November manifest was re-read without changing its files:
SHA-256 `f683b62d658c4960ad67229a460bc571d47a0630a8a2584db1f3725b0bfc22f5`.
Source12d82528e1c6e89d7b0d076880767b5a6016547a, game tree
108a384a95a17d5581e4d50b6a1c3e1ac08ea89b. Its two fresh processes fail581/7
and581/6 under the50ms limits, with all37 retention checks passing. Hardware:
Ryzen7 7700, RTX4060 plus integrated Radeon inventory,16 logical CPUs,
33397133312 RAM bytes. Those remain the last retained original-host measurements;
no post-M1-120 Windows pass or causal improvement is demonstrated.

The executable last recorded on that machine is
`C:/Users/User/AppData/Local/Temp/opencode/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe`.
For the original host only, use that installed executable if still present with
collect_loading.py, --bash C:/Git/bin/bash.exe, LLA_RETAIN_LOAD_TRACE=1 and a
new output directory (default two fresh processes). Confirm the host and binary
version rather than copying these labels onto a different Windows machine.
Existing caches, assets, settings and all failed attempts must remain intact.
The prior UI phase duration can include yields; nested/worker stage durations
cannot establish the cause of a main-thread interval by summation. Passing Mac
retries and projected Windows improvements remain separate from cause/fix proof.

## Final fresh full result and separate focused results

The mandatory runner completed all117 suites in1785.970s, exit1:
**99/117 suites passed;18 failed**. No suite or assertion was skipped. Both
fatal-script suites were failed and their owned engine processes stopped, so the
remaining gate completed. No source hashes changed; committed project settings
match after collection. Subsequent synchronized team changes through c8d23f8
are board/document changes; the game tree still matches e149235d.

Separate verification:

- Runner infrastructure: six unittest methods /13 injected process scenarios
  pass (runner/green.txt); RED hang reproduction retained in runner/red.txt.
- Actual campaign loading watchdog:29 checks /0 failures in the full gate.
- Actual production loading performance:582 checks /0 failures, including37
  retention checks;16 windows and326 stages retained in loading_trace.json.
- Actual P01 inputs:319 checks /0 failures; see
  full_bounded/test_p01_inputs.gd.log. These headless results do not certify either Windows host.

| Production loading window | Maximum interval, ms | Limit |
|---|---:|---:|
| Title |17.741|<50|
| New campaign |37.908|<50|
| Garden |26.290|<50|
| Full cast |29.658|<50|
| Terrain exterior |24.486|<50|

The full gate is failed. This Mac timing pass follows earlier unchanged-source
pass/fail variability; no timing cause, Windows improvement or native first-draw
repair is claimed. The demonstrated repair is bounded handling of an already
fatal test-process diagnostic. Original raw loading remains unbounded pending
Sadman’s reviewed change; watchdog29/0 does not include held-raw acceptance.

### Remaining full-suite failures (separate from focused passes)

Each row links to its complete raw log; assertion counts and fatal diagnostics
are preserved, with no source repair claimed for these owners’ active files.

| Suite | Result |
|---|---|
| [test_campaign_later_runtime.gd](full_bounded/test_campaign_later_runtime.gd.log) | LATER CAMPAIGN RUNTIME RESULT: FAIL (78 checks, 30 failures) |
| [test_ch01_game_feel.gd](full_bounded/test_ch01_game_feel.gd.log) | CH01 GAME FEEL RESULT: FAIL (101 checks, 3 failures) |
| [test_ch06_missions.gd](full_bounded/test_ch06_missions.gd.log) | CH06 MISSIONS RESULT: FAIL (149 checks, 105 failures) |
| [test_ch08_missions.gd](full_bounded/test_ch08_missions.gd.log) | CH08 MISSIONS RESULT: FAIL (173 checks, 123 failures) |
| [test_chapter1_campaign_flow.gd](full_bounded/test_chapter1_campaign_flow.gd.log) | CHAPTER 1 CAMPAIGN FLOW RESULT: FAIL (314 checks, 7 failures) |
| [test_chapter1_outcomes.gd](full_bounded/test_chapter1_outcomes.gd.log) | CHAPTER 1 OUTCOMES RESULT: FAIL (134 checks, 2 failures) |
| [test_chapter1_ui_regressions.gd](full_bounded/test_chapter1_ui_regressions.gd.log) | SCRIPT ERROR: Invalid access to property or key 'visible' on a base object of type 'null instance'.; engine stopped (exit143) |
| [test_chapter2_rooms.gd](full_bounded/test_chapter2_rooms.gd.log) | CHAPTER 2 ROOMS RESULT: FAIL (3603 checks, 7 failures) |
| [test_chapter3_rooms.gd](full_bounded/test_chapter3_rooms.gd.log) | CHAPTER 3 ROOMS RESULT: FAIL (4717 checks, 3 failures) |
| [test_chapter5_rooms.gd](full_bounded/test_chapter5_rooms.gd.log) | CHAPTER 5 ROOMS RESULT: FAIL (2837 checks, 32 failures) |
| [test_chapter6_puzzles.gd](full_bounded/test_chapter6_puzzles.gd.log) | CHAPTER 6 PUZZLES RESULT: FAIL (18 checks, 1 failures) |
| [test_chapter6_rooms.gd](full_bounded/test_chapter6_rooms.gd.log) | CHAPTER 6 ROOMS RESULT: FAIL (3579 checks, 33 failures) |
| [test_chapter8_puzzles.gd](full_bounded/test_chapter8_puzzles.gd.log) | CHAPTER 8 PUZZLES RESULT: FAIL (41 checks, 2 failures) |
| [test_journal_tabs.gd](full_bounded/test_journal_tabs.gd.log) | SCRIPT ERROR: Invalid access to property or key 'frames' on a base object of type 'Nil'.; SCRIPT ERROR: Cannot call method 'get_children' on a null value.; engine stopped (exit143) |
| [test_main_menu_contrast.gd](full_bounded/test_main_menu_contrast.gd.log) | MAIN MENU CONTRAST RESULT: FAIL (154 checks, 12 failures) |
| [test_outpost_status.gd](full_bounded/test_outpost_status.gd.log) | OUTPOST STATUS RESULT: FAIL (62 checks, 29 failures) |
| [test_player_text.gd](full_bounded/test_player_text.gd.log) | PLAYER TEXT RESULT: FAIL (18162 checks, 3026 failures) |
| [test_upgrade_profiles.gd](full_bounded/test_upgrade_profiles.gd.log) | UPGRADE PROFILES RESULT: FAIL (3180 checks, 129 failures) |

Text sweep failure is18162 checks /3026 assertions, not timeout. It reports
96 scenes /420 later jobs while its coverage assertion still expects283 jobs;
the other failed assertions remain in the raw log. This observation alone does
not assign all3026 failures to that one assertion. UI/journal null accesses,
mission/route/prop/menu/outpost/upgrade assertions all remain separate failures.
Engine ObjectDB/resource warnings are retained; no clean teardown claim is made.
Other owners’ reservations and source remain untouched.

### End state of Atik’s four IDs

Completed IDs: **none**. All four remain blocked with saved work:

- **M1-68:** original Ryzen/RTX post-M1-120 two-process evidence is inaccessible;
  SSH/remote route absent and runner discovery HTTP403. Fresh integrated gate is
  now99/117, with exact18 failures above. Resume with original-host measurement
  and owner repairs, then a fresh green integrated gate; preserve all attempts.
- **M1-53:** current raw blob17cb725681c9074ac8b66f64ed34df73e105bc1c is unchanged.
  Sadman’s reviewed raw change has not landed. Watchdog code and saved patch are
  preserved; reviewed request is published. Held-raw regression and ten consecutive
  full windowed probes begin after that delivery, followed by the full gate.
- **M1-92:** matching dSYM/native profiler and controlled campaign before/after
  remain unavailable. Exact UUID/tool evidence is linked above; old unsymbolicated
  title sample and this headless pass do not establish campaign-hitch cause.
- **M1-116:** original Arc Windows/Vulkan process/thread evidence remains
  inaccessible. Original44/0 then180.017s timeout stays failed. Follow the linked
  original-host resume conditions; no Metal/headless host certification.

Saved runner code a236295 is pushed under ProgrammerAtik’s identity. Code changes in this follow-up are limited to the
two reserved runner files; no raw-loader, gameplay,
asset, import or local settings edit was made. Prior watchdog fixes/logs and all
other owners’ updates are preserved. No extra task was claimed, and submission,
video, release packaging and manual QA remain deferred.
