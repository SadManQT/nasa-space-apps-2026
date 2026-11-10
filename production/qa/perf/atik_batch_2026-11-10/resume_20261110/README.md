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
