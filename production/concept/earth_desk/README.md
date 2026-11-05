# EN_EarthDesk: the Earth control room behind a caller (screen backdrop), sheet for approval

Board task M1-07. **Status: built and in the game, no credits spent; waiting for Sadman's approval of [EN_EarthDesk_sheet_v1.png](EN_EarthDesk_sheet_v1.png).**

The asset is a 2D screen render (registry method "2D/screen render"): the room behind an Earth-side caller on the station's Earth screen in the commons (LOC-01). It is not a playable Earth level.

**It is Rao's room.** The installed Rao portrait (`game/assets/ui/portraits/CH_Rao_screen.png`) is opaque and carries its own painted control room, so the backdrop only shows behind a caller without one: Ferreira, whose Earth-screen portrait is a cut-out. The backdrop rebuilds Rao's room in 3D so the two callers read as one place: a dark blue-teal operations room, a wall of four large displays (telemetry charts, an orbit ground track, a lunar route map, the near side of the full Moon), two rows of workstations with low dividers and glowing monitors, a shelf of binders, and the warm desk lamp at the left. The camera stands at the caller's seated eye height, focused on the caller at 0.9 m, so the room falls softly out of focus like the portrait's background. A painted grade (Kuwahara brush filter, soft screen glow, teal shadows, vignette) brings the render close to the portrait's illustrated look.

| File | Use |
|---|---|
| `game/assets/ui/screens/EN_EarthDesk.png` (1536 x 864) | live Earth link, radio and queued text |
| `game/assets/ui/screens/EN_EarthDesk_archive.png` | stored recordings (desaturated, dimmer, cooler) |
| [build_earth_desk.py](build_earth_desk.py) | the Blender Eevee scene (procedural, deterministic, 64 samples) |
| [EN_EarthDesk_render.png](EN_EarthDesk_render.png) | the raw render, the source of the grade |
| [compose_earth_desk.py](compose_earth_desk.py) | the painted grade, the archive variant and this sheet (numpy, SciPy, Pillow) |

Rebuild: `python3 production/tools/heavy.py blender -b --factory-startup --python production/concept/earth_desk/build_earth_desk.py`, then `python3 production/concept/earth_desk/compose_earth_desk.py`, then re-import in Godot (`production/qa/evidence/M1-07_capture.sh` does the import, the portrait and every screenshot in the right order).

## Runtime binding

`CampaignCrew._build_screen` (game/scripts/world/campaign_crew.gd) builds three layers on the commons' back wall: the room (opaque, so nothing behind the screen shows through), the caller's portrait fitted to the room's height, and the caption with the caller's name and the source word ("Rao · Earth link", "Ferreira · Recording") from `ui_text.json`. The screen is 4.8 m wide (16:9) and centred 1.78 m up, so it stays clear of the room's "Commons" wall sign; size, height and the variant per origin label live in `earth_screen` in `game/resources/ui/ui_kit.json`. Nothing on the screen casts a shadow, and the whole screen goes dark when a local crew member speaks. `game/tools/test_earth_screen.gd` checks all of this.

Ferreira's portrait is re-rendered at 1376 x 768 with a transparent background by `game/tools/probe_earth_screen.gd --portrait`, lit like the room (warm key from the lamp side, teal rim from the displays). Run it in its own Godot process: a session that rewrites the PNG keeps showing the old import.

## Canon checks done

- No text, logos or flags on any readout; every trace is abstract, so nothing contradicts a dated fact. No NASA mark.
- The Moon display shows the real near side as seen from Earth with north up: the maria at their true positions, bright Tycho with its ray system, Copernicus, Kepler and Aristarchus, almost no limb darkening at full Moon (ART_BIBLE §2).
- Earth-side only: this never appears as a place the player walks.
- Palette ART_BIBLE §3: navy and blue-teal, water blue and green traces, one warm lamp, a mustard-gold route.

## Decisions for Sadman (approve, change or decline)

1. The room as Rao's room (dark operations room with the warm lamp, matched to the installed portrait), or a different room for Ferreira.
2. The painted grade (top left on the sheet) against the plain render (`EN_EarthDesk_render.png`).
3. The archive treatment for stored recordings (top right).
4. Ferreira's relit portrait over the room (bottom right), same height as Rao's.
5. Later, optional: a cut-out Rao portrait (a CH_Rao task) would put Rao in this same 3D room too; today his portrait keeps its own painted room, which the backdrop matches.
