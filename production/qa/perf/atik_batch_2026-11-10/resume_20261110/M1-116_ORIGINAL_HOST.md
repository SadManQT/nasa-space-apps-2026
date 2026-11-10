# M1-116 original-host investigation checkpoint

10 November 2026, Atik/codex. Status: blocked; no original-host repair claimed.

The original reproduction is Windows 11 / Intel Arc 130V / Godot 4.7.2,
Forward+ Vulkan, 1280x720. The retained native manifest at source
`cc4e18075dc999a2af300edea237cd6b971162b9` records the real campaign input fixture printing
44 checks /0 failures and writing five screenshots and an input trace, followed
by a180.017s process timeout (exit124, capture_checks_passed:false).
Compatibility completed in13.450s with44/0. Both attempts remain separate;
neither proves a driver or deadlock cause.

Original manifest SHA-256:

- native/run.json: `df7896695130354f1a5d8fa76939447ea70a82a85ea80dcd68cad70a07713d37`
- native_compatibility/run.json: `ba913ef87d46a65d8fc4afa7f2f581ee3f3ac4097e56cf8a97c8cf47907181ea`

Paths are relative to
`production/qa/playtests/first_impressions/retest_2026-11-09/`.
These hashes identify existing evidence; they are not fresh Windows runs.

## Access and tool blocker

This session exposes an Apple M4 Mac. No configured SSH alias/host or remote
execution connector addresses Tanvir's laptop. The user authorized autonomous
commands but supplied no original-host connection or collection route. There is
no reachable original Windows process to inspect. The GitHub workflow uses
hosted windows-latest, which does not reproduce the original Arc machine.

The saved collector's --sample-after path is macOS-only. It does not collect
Windows native stacks automatically. No Windows process/thread trace, dump,
GPU-driver version or matching native symbol resolution has been obtained in
this session. The saved M4 Metal native44/0 exit0 in9.225s and headless P01
results remain comparisons; they cannot certify the Arc teardown.

## Exact resume conditions

Use the unchanged original-host command in ../M1-116.md in a new evidence
directory after safely synchronizing source. Record executable version/hash,
source and local diff, OS/GPU driver/hardware, renderer, process ID and its exact
command. Retain stdout/engine log, five PNGs, trace and collector run.json.
Do not reuse the original evidence directory or existing player saves.

If PASS is printed but that same process remains alive, capture its native
thread stacks/wait states and loaded modules while it is still alive, with
monotonic timing relative to PASS and before the collector's180s deadline.
Identify the process by PID and exact command; do not terminate unrelated Godot
sessions. Keep the raw trace and the process exit/timeout record even if a later
retry passes. A PASS followed by timeout remains a failed run. A wait-stack
observation alone does not establish the blocking cause.

Choose a source/engine/settings repair only after those diagnostics identify
a testable cause. Preserve existing input/loading fixes; obtain an owner handoff
for actively reserved shared files. Compare controlled runs on that same host,
then rerun the relevant mandatory runner and integrated full gate. Acceptance
requires valid fixture results AND normal Forward+ Vulkan process termination,
without forced timeout. No speculative runtime patch or Metal certification is
substituted for that evidence.
