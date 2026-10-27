# game/assets — everything the game loads

One folder per asset; the folder name equals the file name. Do not add files by hand: run `production/tools/sync_to_godot.sh`, which copies finished assets here, imports them and runs the quality gate. Full rules: [PRODUCTION_HANDBOOK.md](../../PRODUCTION_HANDBOOK.md). Every asset, made or planned: [production/ASSET_REGISTRY.csv](../../production/ASSET_REGISTRY.csv).

```text
characters/CH_<Name>/CH_<Name>.glb       rigged, 78 bones, ~50k tris, 4K textures
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

Textures stay embedded in each GLB (project import default), so a folder holds only `<Name>.glb` and `<Name>.glb.import`. Commit the `.import` files; `game/.godot/` is cache.
