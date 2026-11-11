# Windows build check, 11 Nov 2026

**Result: PASS on a real Windows machine.** GitHub Actions `Native export smoke`, run 43051374551, `windows-latest`, commit 1fc4c52f.
- Fresh checkout, Godot 4.7.2 and export templates installed on the runner, `python3 production/qa/build_release.py --platform windows --install-tools --smoke`.
- `EXPORT SMOKE RESULT: PASS (10 checks, 0 failures)`: the packaged `LastLightAcademy.exe` starts outside the project, reaches the title, starts Chapter 1, uses its first job and saves.
- `BUILD RESULT: windows PASS sha256 51fb7359ba0dfc5d32bb6caafb0743c5a870b2fd856854989aee9d9a222c7bac`; the package zip is about 1.0 GB.

Fixed on the way (all on `main`):
1. The export dropped the imported room models (`runtime_assets` export plugin), so the Commons and Garden could not load.
2. The export excluded `addons/*`, but the UI kit `addons/gohud` is needed at runtime, so the UI scripts failed to parse.
3. CI fetched only part of the LFS files, and the build script treated the first-import texture notice and the exporting editor's exit leak report as export errors.

Also checked on the Mac: the Windows `.pck` boots through the same smoke, and all 96 scenes play in the campaign QA sweep (`production/qa/evidence/qa_campaign/`).

Not done: publishing a GitHub Release (needs Sadman's OK), and the final release after Ramim's M4-20 UI pass and the clip renders.
