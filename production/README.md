# production — sources, plans and tools behind the game's assets

> **13 Nov 2026:** the large source folders listed below (concept art, audio masters and takes, terrain sources, cutscene and explainer sources, rigs, pitch and video working files) are kept in the team's archive and on the branch `archive/full-tree-2026-11-13`, not on `main`. `main` keeps what the game, its tests, the release build and the submission use.

Start with PRODUCTION_HANDBOOK.md. Finished assets go to [game/assets/](../game/assets/).

| Path | What it holds |
|---|---|
| [ASSET_REGISTRY.csv](ASSET_REGISTRY.csv) | Every asset, made or planned: status, game path, source, spec. Rebuild: `python3 production/tools/build_registry.py` |
| [ART_BIBLE.md](ART_BIBLE.md) | Look, palette, science rules, budgets, naming |
| [AI_PROMPT_LOG.md](AI_PROMPT_LOG.md) | Every AI generation (required for the submission) |
| [manifest/](manifest/) | Specs that drive the pipeline: `characters.csv`, `tripo_props_batch1.csv`, `reuse_props.csv`, `planned_assets.csv`, `scene_index.csv` (all 96 final scenes), `ch01_assets.csv` |
| concept/ | Concept art: style frames, cast turnarounds (+ split views), plant and prop concepts. **Current cast sheets are `turnarounds_v8/` only**; `turnarounds/`, `turnarounds_v7/`, `cast_v6/` and `style_lock/` are superseded earlier passes, kept because the AI prompt log, the asset registry and older pipeline notes cite them |
| [audio/](audio/) | `vo_lines.csv` (all 385 dialogue lines, speaker, delivery, target file), `music_cues.csv` (CUE-01–12 mapped to scenes), `sfx_list.csv` (effects with captions) |
| [cutscenes/](cutscenes/) | `shots.csv`: 23 shots for 17 cutscenes with ready Seedance prompts, start-frame assets, voice lines and music |
| review/ | `asset_verification.md` (automated gate), `visual_review.md` (human/AI visual check), contact sheets |
| [tools/](tools/) | Pipeline scripts (see below) |
| `models/` | Git-ignored staging: `raw/` Tripo downloads, `reuse/` pitch-video sources, `final/` pre-Godot GLBs with previews |

**Tools:** `make_character.sh` (turnaround → rigged character), `make_prop.sh` (concept or GLB → prop), `split_turnaround.py`, `blender_cleanup.py` (+ `test_blender_cleanup.sh`), `render_preview.py`, `pose_test.py`, `sync_to_godot.sh` (copy, import, gate), `verify_gate.py`, `build_registry.py`, `export_tripo_archive.sh`, `tripo_api.py` (API-credit pool).
