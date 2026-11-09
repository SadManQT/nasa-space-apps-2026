# Moon Region (`M3-60`)

Data and configuration for the walkable lunar region around Aurora Station (`aurora_ridge`) and the Cold-Trap approach (`cold_trap`) built on the `M1-36` LOLA terrain provider (`TerrainStream`).

## Contents
- `moon_region.json`: Canonical definitions of the two terrain sectors (`aurora_ridge`, `cold_trap`), the 5 exterior locations (`LOC-06`, `LOC-07`, `LOC-08`, `LOC-09` with segments `B1`/`B2`/`B3` and last bend, and `LOC-10`), and the 7 places worth visiting from `game-design/25_PLAYER_CLARITY_AND_MOON_JOURNEY.md` §4.1, each with its structured reason hook (`job`, `clue`, `view`, or `measurement`).
- Scene: `res://scenes/world/moon_region.tscn` (and `res://scenes/world/moon_region/moon_region.tscn`).
- Script: `res://scripts/world/moon_region.gd` (`MoonRegion`).
