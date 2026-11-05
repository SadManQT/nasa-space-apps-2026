# game/assets — everything the game loads

One folder per asset; the folder name equals the file name. Do not add files by hand: run `production/tools/sync_to_godot.sh`, which copies finished assets here, imports them and runs the quality gate. Full rules: [PRODUCTION_HANDBOOK.md](../../PRODUCTION_HANDBOOK.md). Every asset, made or planned: [production/ASSET_REGISTRY.csv](../../production/ASSET_REGISTRY.csv).

```text
characters/CH_<Name>/CH_<Name>.glb       current v7/v8 cast, 65 bones (Mei 68 with hair), 44 clips
plants/PL_<Name>/PL_<Name>.glb           growth stages; no faces, ever
props/PR_<Name>/PR_<Name>.glb            hero props 2K textures, small props 1K
vehicles/VH_<Name>/VH_<Name>.glb
environment/EN_<Name>/EN_<Name>.glb
audio/music/MUS_<CUE-xx>_<Title>.ogg     cue list: production/audio/music_cues.csv
audio/sfx/SFX_<ID>.ogg                   list + captions: production/audio/sfx_list.csv
audio/voice/<Speaker>/VO_<line_id>.ogg   every line: production/audio/vo_lines.csv
cutscenes/CS-<nn>_<scene>.ogv            Ogg Theora only (Godot 4); shots: production/cutscenes/shots.csv
ui/                                      icons, fonts, HUD art
```

Textures stay embedded in each GLB (project import default), so a folder holds only `<Name>.glb` and `<Name>.glb.import`. The habitat kit (`environment/kit/`) is the exception: its 24 pieces tile the same texture sets, which live once in `kit/textures/` and are referenced by every GLB, so Godot imports each texture one time (the terrain kit's `textures/` folder holds only its ground materials; the rock GLBs embed their own small texture). Commit the `.import` files; `game/.godot/` is cache.

**Chapter 7 set (M3-7A):** the storm-shelter and uplink props (`props/PR_ShelterDiagram`, `PR_SeedCase`, `PR_ValveDiagram`, `PR_TelemetryDisplay`, `PR_ArchivePlayer`, `PR_UplinkFeedthrough`, `PR_NetworkDiagnostic`) and `environment/EN_Fabrication/` are kit extensions like the airlock: each prop folder holds `<Name>.glb` (the game LOD, with collision) and `<Name>_LOD1.glb` (the Compatibility LOD), and both reference the kit's shared textures by uri instead of embedding them (the reused Tripo feedthrough keeps its own embedded maps). `props/chapter7_assets.json` is their catalogue (sizes, mount heights, sockets, moving parts, live screens, lamps, states and the route simulator's LOLA line-of-sight data) and `props/chapter7_assets.gd` builds the two-LOD node and drives the states. Rebuild with `production/tools/build_chapter7_assets.py`; details in `environment/EN_Fabrication/README.md`.
