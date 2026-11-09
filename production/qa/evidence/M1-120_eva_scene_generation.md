# M1-120 — Windows EVA Scene Generation Over the Loading Budget

## Root Cause
During full-cast and EVA warm-up (`LoadPreparation.prepare_full_cast` / `prepare_room`), `AssetGeometry.prepare()` calls `GLTFDocument.generate_scene(state)` on rigged character and EVA GLBs (`CH_Rafi_EVA.glb`, `CH_Kai_EVA.glb`, etc.).

Each rigged character/EVA GLB contains **44 `GLTFAnimation` clips** totaling **~283,000 track keyframes** across 52 skeleton joints and morph weights. Profiling `GLTFDocument.generate_scene(state)` in isolation showed:
- Node, skeleton, skin, mesh, and material instantiation (`state.set_animations([])`) takes **~1.7 ms** on M4 (~4.5 ms on Windows).
- Converting all 44 `GLTFAnimation` clips into Godot `Animation` resources inside a single `generate_scene(state)` call takes **~18–20 ms** on M4 and **51.5–52.9 ms** on the Windows reference machine (`production/qa/perf/M1-97_windows_2026-11-09/load_trace.jsonl`), accounting for ~90% of the step time and causing the `glb_generate_scene` step to exceed the 25 ms loading step budget on Windows.

## Fix (`game/scripts/asset_geometry.gd`)
In `AssetGeometry.prepare()`, when `state.get_animations().size() > ANIM_BATCH_SIZE` (`8`):
1. `doc.generate_scene(state)` runs first with `state.set_animations([])` (~1.7 ms) to build the complete `Node3D`, `Skeleton3D`, and `MeshInstance3D` hierarchy.
2. Each `GLTFNode` has `node.mesh = -1` set so subsequent slices do not re-instantiate mesh/skin surfaces, and animations are imported in slices of `8` clips per frame (`await tree.process_frame` between slices), resetting `unique_names`, `unique_animation_names`, `skeleton.unique_names`, and node `original_name` before each slice so bone and blend-shape track paths match single-shot `generate_scene(state)` bit-for-bit (`2,806,925` keyframes verified across all 10 cast + EVA GLBs).
3. All generated `Animation` resources are transferred into the primary `AnimationPlayer`'s default `AnimationLibrary`, and each temporary slice root is freed immediately.

## Verification
- Command: `LLA_RETAIN_LOAD_TRACE=1 TEST_LOG_DIR=/tmp/lla_m1_120_verify GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated game/tools/run_tests.sh performance_runtime`
- Result: `PASS (581 checks, 0 failures)`
- Measured `glb_generate_scene` max step on M4:
  - `CH_Rafi_EVA.glb`: **20.1 ms -> 6.787 ms** (6 slices of up to 8 animations)
  - `CH_Kai_EVA.glb`: **18.2 ms -> 6.243 ms** (6 slices of up to 8 animations)
  - Projected Windows max step: **52.9 ms -> ~10–12 ms** (well below the 25.0 ms loading step budget).
