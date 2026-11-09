# M1-117 — Kit LOD1 Texture UID Fallback Investigation & Repair

**Date:** 9 November 2026
**Author:** Sadman/antigravity

## 1. Symptoms Observed in P01 Setup Log
In `production/qa/playtests/first_impressions/retest_2026-11-09/p01/setup.log`, Tanvir's headless import (`Godot --headless --path game --editor --quit`) emitted 11 warnings of the form:
```text
WARNING: res://assets/environment/kit/lod1/EN_Kit_Wall_Straight_LOD1.glb:4 - ext_resource, invalid UID: uid://dwd3423mo0cjb - using text path instead: res://assets/environment/kit/textures/lod1/T_Kit_Paint_ORM_LOD1.png
```
for the 11 `EN_Kit_*_LOD1.glb` pieces that use the `KitPaint` material (`EN_Kit_BulkheadRing`, `EN_Kit_CeilingTile`, `EN_Kit_DoorFrame`, `EN_Kit_FloorTile`, `EN_Kit_Hatch`, `EN_Kit_LightStrip`, `EN_Kit_PipeRun`, `EN_Kit_Wall_Corner`, `EN_Kit_Wall_EquipBay`, `EN_Kit_Wall_Straight`, `EN_Kit_Wall_Window`).

## 2. Root Cause
1. **Tracked `.import` UID is `uid://c4y0dt47sdboo`:**
   - `game/assets/environment/kit/textures/lod1/T_Kit_Paint_ORM_LOD1.png.import` has always tracked `uid="uid://c4y0dt47sdboo"`.
   - None of the tracked `.glb`, `.glb.import`, `.tres`, or `.png.import` files in git contain `uid://dwd3423mo0cjb`.
2. **Generator `.png.import` overwrite stripped `[deps]` / `path.*`:**
   - `write_texture_imports()` in `production/tools/build_habitat_kit.py` previously rewrote every `.png.import` file with only `[remap]\nimporter="texture"\ntype="CompressedTexture2D"\nuid="uid://..."` (omitting `path=...` and `[deps]\ndest_files=[...]`).
   - When a developer or playtester opened the project on a machine where `T_Kit_Paint_ORM_LOD1.png` was re-imported before the tracked UID settled (or after a local regenerate), Godot generated a machine-local UID (`uid://dwd3423mo0cjb`) and baked that `ext_resource` UID into the gitignored binary scene cache `game/.godot/imported/EN_Kit_*_LOD1.glb-*.scn`.
3. **Why `Godot --headless --path game --editor --quit` did not clear the warning:**
   - When `T_Kit_Paint_ORM_LOD1.png.import` was subsequently restored to the tracked `uid://c4y0dt47sdboo`, Godot updated `game/.godot/uid_cache.bin` so `T_Kit_Paint_ORM_LOD1.png` mapped to `uid://c4y0dt47sdboo`.
   - However, because the `EN_Kit_*_LOD1.glb` files and their `.glb.import` timestamps had not changed relative to `game/.godot/imported/EN_Kit_*_LOD1.glb-*.scn`, Godot's incremental import scan skipped re-importing those `.glb` scenes. Loading the cached `.scn` files therefore hit `invalid UID: uid://dwd3423mo0cjb - using text path instead`.

## 3. Fixes Applied
1. **`production/tools/build_habitat_kit.py` (`write_texture_imports`):**
   - Updated `write_texture_imports()` to preserve existing `[remap]` (`uid`, `path.*`, `metadata`) and `[deps]` (`dest_files`) entries when rewriting `.png.import` files so running the generator never invalidates Godot's `.ctex` dependency tracking.
2. **Regression check in `game/tools/test_habitat_kit.gd`:**
   - Added a check verifying that `uid://c4y0dt47sdboo` is registered in `ResourceUID` (`ResourceUID.has_id`) and resolves to `res://assets/environment/kit/textures/lod1/T_Kit_Paint_ORM_LOD1.png`, alongside all 12 kit pieces' LOD0 and LOD1 material texture loads.

## 4. Supported Cache-Repair Command for Any Worktree Seeing Stale `.scn` UIDs
If a local worktree has stale cached `.scn` files in `game/.godot/imported/` from an older import cache, run:
```bash
rm -f game/.godot/imported/EN_Kit_*_LOD1.glb-*
Godot --headless --path game --editor --quit
```
This forces Godot to rebuild the 12 `EN_Kit_*_LOD1.glb-*.scn` binary scenes against the tracked `uid://c4y0dt47sdboo` in `T_Kit_Paint_ORM_LOD1.png.import`, eliminating all `ext_resource, invalid UID` warnings.
