# M1-98 - retained original Windows loading evidence

9 November2026, Ramim. Two requested sequential fresh-process runs completed through the real mandatory-setup runner. Both reproduce timing failures; this completes collection, not a performance fix. Source `12d82528e1c6e89d7b0d076880767b5a6016547a`; game tree `108a384a95a17d5581e4d50b6a1c3e1ac08ea89b`. It is the same game tree as the preceding83/84 full run. Compare the earlier baseline [M1-90](../2026-11-08_0130_ramim/README.md), which lacked retained stages.

Exact existing collector invocation: set `LLA_RETAIN_LOAD_TRACE=1` in the collector child environment; run `python production/qa/perf/collect_loading.py --godot C:/Users/User/AppData/Local/Temp/opencode/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --bash C:/Git/bin/bash.exe --output production/qa/evidence/M1-68_windows/2026-11-09_retained_ramim --hardware-note <the recorded note>`. Default two runs, no retries. The manifest stores both actual runner commands and the full supplied hardware note; collector.txt retains stdout. Source/output schema is [M1-97](../../../perf/M1-97.md).

Windows original failing host; Godot4.7.2 official, Ryzen7 7700,16logical CPUs, RTX4060 and integrated Radeon inventory,33397133312RAM bytes. Exact measured hardware/version in manifest. Headless results do not identify a rendered GPU. Normal desktop apps were kept; process-name snapshots retained. No other engine/render process was found at collection launch or postflight. No entirely idle-host or cold-cache claim. Existing import/OS caches, settings and assets were retained. The collector performs ordinary mandatory class-cache setup for each process.

| Run | Result | Duration | Retained trace |
|---|---|---|---|
|1|581checks/7timing failures;0/1 suites; exit1|45.896853s|16windows/322stages|
|2|581checks/6timing failures;0/1 suites; exit1|46.262806s|16windows/322stages|

Both setups completed with no errors/warnings; every suite reached its final result. All37 new trace-retention checks pass both times. No setup139, timeout, parse error or skipped suite. Collector exit1 honestly preserves the failure result.

All raw failures against unchanged50ms:

- Run1: Amara52.466, Mei57.060, Rafi50.830, Ferreira53.228, new campaign117.181, garden56.510, terrain64.841ms.
- Run2: Amara55.984, Mei57.202, Ferreira53.431, new campaign92.002, garden58.306, terrain62.910ms.

Run1 has oneObjectDB warning. Run2 also emits7 dummy-renderer RID initialization/null-mesh errors with only native Godot at-sites in this run (no GDScript backtrace), plus oneObjectDB warning. These are retained without assigning a cause or treating a PASS marker as a clean engine run.

The report keeps complete original stage records and [first_step,end_step) ranges for all measurements. Raw/gait stage capture remains disabled as before; their empty ranges are explicit. Production records are retained, including warm-up/background records outside window ranges. Original records lack absolute stage timestamps/thread IDs, so no exact longest-heartbeat attribution or sum of nested/worker durations is claimed. The UI phase can span a yield; it is not necessarily one uninterrupted CPU call.

Measured candidate regions for owner diagnosis: campaign_ui116.138/91.716ms elapsed phases; synchronous EVA glb_generate_scene Rafi51.382ms inrun1 and Kai53.225/Rafi52.860ms inrun2. These observations justify investigating those regions, not claiming every interval's cause. AssetGeometry/asset changes belong to Sadman; Atik/Ramim retains M1-68 for supported-host timing diagnosis and can request the measured foreign-owner change.

All3178 tracked game-file bytes, including1190 import sidecars, and the1988 non-import files matched before/after SHA256 fingerprints exactly; see source_before/source_after. No product edit occurred during collection. Artifact bytes are preserved by nested .gitattributes; artifacts.json covers every raw manifest/log/trace/process/fingerprint file with bytes/SHA256, and collector manifest separately hashes each loading_trace.json. Original private files remain. No human/hardware-input or new native benchmark is claimed. M1-68 remains unresolved.
