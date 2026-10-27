# Showcase cutscenes

Game-ready Ogg Theora videos (`.ogv`, 1152x648, 24 fps, Vorbis audio). The asset
showcase discovers them at runtime, sorts by filename, and displays
`CS-01_Arrival.ogv` as `CS-01 Arrival`.

Made from the masters in `production/cutscenes/v7/` (sources and specs in its `src/`):
`production/tools/compose_cutscene.py`, then `production/tools/ogv_writer.gd`.

Open `res://scenes/dev/asset_showcase.tscn`, then press C. Select a video to play;
Space pauses, and Skip or Esc returns to the list. C or Esc closes the list.
