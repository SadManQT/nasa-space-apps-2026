# M3-108 fix-round review — 8 November 2026

Checkout: `a0815bb`; parked implementation: `origin/night/M3-108` (`cfbf448`).

Ported the two petal GLBs, their Blender source correction, the imported/runtime
material regression checks, the garden-facing check, and the capture fixture.
Only the `alo_petal` position and rotation changed in `LOC-03.json`; the newer
Chapter 5 `by_scene` override and all other staging data are preserved. No old
board entries, unrelated handbook status, screenshots or passing logs were copied.

The new asset assertions failed on the original GLBs: eight metallic failures
across two materials, two assets and two loading paths
(`M3-108_ch03_assets_before.txt`). The fixed exports are the parked branch's
SHA-verified local LFS objects. A fresh gated Blender invocation crashed during
startup, before the build script ran (`M3-108_build.txt`); no new export is claimed.
`M3-108_asset_port.txt` records comparison against the current checkout's original
GLBs: visual vertices, indices, UVs, normals, base-colour, normal, occlusion and
roughness pixels are preserved. Paper/petal metallic factors are zero; sleeve and
clip materials match. The unused metallic texture channel changes with the export;
the only removed nodes are the petal collision hulls.

`M3-108_run_tests.txt` is the complete current runner output. The dedicated
headless material probe and asset gate must also pass on this tree; their final
results are recorded below after execution.

The first full run ended `68/70 suites passed`
(`M3-108_run_tests_sandbox.txt`): the care-panel PNG fixture could not write to
`~/Library/Caches`, and mission-trainer canaries/settings could not write to
the platform application-data directory. The care-panel retry passes all 32
checks with `env -u HOME` applied only to the test subprocess. Godot's macOS
[path implementation](https://github.com/godotengine/godot/blob/master/platform/macos/os_macos.mm)
then uses its local fallback. No test assertions, product code, project settings
or thresholds were changed for this retry. The full rerun uses the same process
environment; generated local test folders are removed before handoff.

Windowed capture is deferred under the user's sandbox exception. The installed
`godot_gated` explicitly refuses sandbox windows; no new screenshots or pixel
measurements are claimed here. The overnight host runs:

```bash
bash production/qa/evidence/M3-108_capture.sh
```

It requires printed PASS results, probes both imported and runtime materials,
opens an always-on-top garden window, checks mustard pixels at the S11 review
view, and saves `M3-108_S11_review_view.png`, `M3-108_S11_review_view_zoom.png`,
`M3-108_S11_petal_closeup.png`, `M3-108_S12_board_petal_and_tara.png`, and
`M3-108_S10_bench_sleeve.png`. It then runs the existing `M3-3R_capture.sh` to
retake the original S11 and S12 board shots along with that script's full set.

Sadman/night-shift review: inspect the newly generated images and require
`M3-108 PETAL CAPTURE RESULT: PASS` in `M3-108_capture.txt`. No new design,
canon approval, paid generation, commit or push is involved.
