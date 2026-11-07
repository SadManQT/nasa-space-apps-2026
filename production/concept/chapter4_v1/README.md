# Chapter 4 (Into the Cold Trap) environments: 2D sheets for approval (M3-4A)

Board task M3-4A. **Status: phase 1 done, waiting for Sadman's approval (7 Nov 2026).** The two sheets show what the
assets will look like, their measured plans, their pieces and states, the scenes and story objects they serve, and the
canon and science checks. **No Tripo, Meshy or other AI credits were spent, and no AI image was generated:** every
picture is a Blender 5.2 Cycles render of procedural geometry (the route the M3-2A airlock and the M3-3A annex took),
set on the real NASA LRO LOLA terrain and lit by the JPL Horizons Sun rows in `sun_positions.json`. Phase 2 rebuilds
the same pieces from the same functions, so what is approved is what ships.

| File | What it shows |
|---|---|
| [00_Approval_Sheet.png](00_Approval_Sheet.png) | both assets on one page, with the twelve decisions below |
| [M3-4A_EN_Garage_sheet.png](M3-4A_EN_Garage_sheet.png) | LOC-08: the exterior at the dated S02 Sun, the vacuum bay, the ready room, a cutaway, the measured 12 x 9 m plan with anchors, a section through the docking port, 14 new pieces with their states |
| [M3-4A_EN_ColdTrap_sheet.png](M3-4A_EN_ColdTrap_sheet.png) | LOC-09 and LOC-10: a map of the real road, lit at the S04 hour with cast shadows and the PSR, the computed beacon chain, the road profile, three views (sunlit B2, dark B3, the vault shelf), the 20 x 15 m shelf plan, 7 new site pieces and the 4-piece vault set |

Sources (all regenerable): `production/tools/coldtrap_survey.py` (the LOLA survey, writes
`production/models/ch04/coldtrap_survey.json`), `production/tools/build_ch04_assets.py` (pieces, rooms, terrain scenes,
Cycles renders into `production/models/ch04/preview/`), `production/tools/ch04_sheets.py` (these sheets).

```
python3 production/tools/coldtrap_survey.py
python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 \
    --python production/tools/build_ch04_assets.py -- all --samples 96
python3 production/tools/ch04_sheets.py
```

## Design followed

- **Canon.** LOC-08 in `game-design/09_WORLD_AND_LEVEL_DESIGN.md`: the garage is 12 x 9 m with a pressure-rated rover bay,
  cargo rack, an external pad 500 m away seen through a camera, and a marked path to the courtyard. Its interactables
  are the rover, cargo cradle, route board, supply ledger, suit seals and relief locker, with vehicle work lights and
  an interior pump hum. LOC-09 is a 12 km authored ridge road played as three 100 m segments plus cruise, slopes up to
  12 deg, with three survey beacons, a dry reference plate, sample points, a slope sign and a return marker; light
  "diminishes in discrete terrain occlusion". LOC-10 is a 20 x 15 m level shelf with an old marker, the small insulated
  box (vault V12), two tether anchors, the outer probe socket, the carrier tether and the archival survey tag; no
  cavern and no maze. The scenes are STORY_FULL EX-CH04-S01 to S12, and also CH05-S01, CH07-S12, CH08-S01 and CH08-S11
  for the garage. The objects come from the doc 24 §2.9 CH04 bridges (rover checklist, the hatch closing on two field
  and two home, the beacon chain, the next sealed sample, the carrier tethered beside the vault, probe, sleeve and
  cradle, the dry glovebox, the line of handwriting under the lid, the fifth mug and the 8-12 Dec flight) and from §4
  clues 14 and 15 (the cotton note on the manifest and the lid inscription; both are live text, never baked).
- **Look.** Photoreal environments, per the 5 Nov realism lock. The ready room is built from the approved M1-05 kit
  (quilted panels, navy skirting, orange handles, 3,500 K practicals). The vacuum bay is steel portal frames with a
  ribbed shield, 5,000 K LED floods and sintered-regolith pavers. The exteriors are LOLA terrain (5 m Aurora ridge,
  10 m cold trap and 40 m vista, all with the Moon's curvature) with procedural sub-metre relief, the M1-35 rocks and
  regolith grey #7A7672. The grey and white figures are 1.75 m scale stand-ins; the cel-shaded cast is composited at
  runtime.

## Measured facts (Computed)

- **Rover.** The installed VH_Rover is 6.0 m long, 4.66 m across the wheels and 2.84 m across the body. Its side
  hatches sit 1.85-2.96 m above the ground, just behind the front wheels, and it has two suitports above its rear
  cargo rack. Measured on the GLB.
- **Road.** The real slope-limited road (make_terrain's own search, kept at every 20 m cell) is 8.56 km long, with a
  steepest cell of 11.9 deg (under the rover's 15 deg limit), 802 m of descent, and an end at the edge of the
  permanently shadowed region. The game keeps canon's P-07 numbers: route B, 12 km, 30 + 30 of 100 units.
- **Beacon chain.** Each beacon stands on the last road cell its predecessor can still see, and every chord is checked
  true-scale over the curved Moon:

  | Beacon | Road distance | Light at S04 (21 Oct 2046 08:00) | Clearance back to the previous relay |
  |---|---|---|---|
  | B1 | 1.02 km | sunlit | 6.1 m to Aurora's 10 m mast |
  | B2 | 1.88 km | sunlit | 1.7 m to B1 |
  | B3 | 5.24 km | dark (horizon 5.4 deg above a 1.6 deg Sun) | 2.7 m to B2 |

  B3 reaches the shelf with 3.5 m to spare. Aurora's mast cannot see the shelf: the terrain stands 220 m above the
  chord. The chain covers 73 % of the road. B3 has only one possible window, road 5.22-5.30 km. M1-82's LOC-09 point
  (7.82 km) sees the shelf but not B2.
- **Vault shelf.** It stands on the M1-82 LOC-10 site, the lowest PSR pixel, 510 m past the road end and 50 m lower.
  The real 10 m cells under the 20 x 15 m footprint fit a 3.7 deg slope with 2.1 m of relief, so the shelf is graded
  flat. The Sun never reaches it: the terrain horizon at S06 is 9.9 deg against a 1.6 deg Sun.

## Decisions (please approve or change each)

1. **Garage section: a loading-dock garage, not a pump-down hangar.** The ready room is pressurised and stands on a
   sintered plinth with its deck 1.40 m above the floor of a vacuum (unpressurised) rover bay, level with the rover's
   cabin sill. The rover docks its side hatch to a telescoping docking tunnel (0.90 x 1.15 m hatch, 1.10 m tunnel), so
   a trip pumps down only about 1 m3 of tunnel (the "pump hum"), as NASA's pressurised-rover concepts dock to a
   habitat. *Alternative:* pressurise the whole bay and pump it down for each trip. People could then walk around the
   rover unsuited, but every sortie would cycle about 330 m3, roughly 400 kg of air at sea-level pressure; even with
   95 % pumped back into tanks, about 20 kg would be lost per trip.
2. **Connection: the ready room's inner door joins the habitat by a pressurised kit corridor.** The rover door's marked
   path joins the courtyard (LOC-06), as canon says. Doc 09's map draws only LOC-06 to LOC-08, so this adds an indoor
   link: nobody has to walk outside to reach the rover. *Alternative:* no corridor; the crew suit up in LOC-05 and walk
   the marked path to a personnel airlock in the garage.
3. **Site and look.** The garage stands 80 m from Aurora's site at azimuth 150, on the courtyard edge, with the rover
   door facing azimuth 100. It sits under a 1 m regolith berm (35 deg sides, sintered wing walls and headwall) for
   shielding, thermal mass and micrometeoroid cover. At the S02 hour the low Sun (azimuth 59.8, elevation 1.8) lights
   the door face. The 500 m landing pad appears only on the pad camera (Screen3), as canon says.
4. **Suits and the EVA porch.** The EVA suits stay on the rover's two rear suitports and are reached from an EVA porch
   (3.30 x 5.85 m at +1.40 m, with a rail, a gate at the suitports and a stair). The ready room's suit-seal station
   checks both suitport seals and the dock seal (the LOC-08 "suit seals"). People enter the bay only in suits.
5. **A dry cargo lock for the vault (S09 to S10).** The sealed case comes home in its sleeve through a 0.72 x 0.56 m
   cargo lock. The lock is back-filled with dry nitrogen, never humid cabin air, because a case at cold-trap
   temperature would frost over. The case then goes to the dry quarantine glovebox (PR_Glovebox). The lock sits at
   bench height in the room and at chest height on the porch; one door opens at a time.
6. **The relief locker holds the relief cargo** for the 8-12 Dec flight (S12; the CH05 crates). Ferreira's personal
   locker stays the airlock's fifth suit locker, which is already built with her gold tab.
7. **Boards and console.** Two portrait departure boards stand side by side (CH07-S12 "two destination boards",
   CH08-S01), and the handbook moves them here from the Commons. Next to them are a 2 m route board (route cards A/B/C
   and the beacon chain) and Amara's three-screen handover console (map, slope card, pad camera). The cargo rack carries
   the supply-ledger tablet. Every word is drawn live; nothing is baked.
8. **LOC-09 = three 100 m segments at the computed corners B1 (1.02 km), B2 (1.88 km) and B3 (5.24 km).** The first
   two are sunlit at the S04 hour and the third is in terrain shadow, which is canon's "light diminishes in discrete
   terrain occlusion" on the real ground. M1-82 placed one LOC-09 point, the 7.82 km bend (dark, sees the shelf but not
   B2). M3-4R either moves LOC-09 to the three segments (`exterior_terrain.json` is its file, and adding Sun rows at B1
   and B2 is a small M1-88 follow-up) or keeps that point as the last-bend viewpoint.
9. **Beacons stand on 5 m telescoping masts.** With the installed 1.8 m tripod (PR_SurveyBeacon), the real road would
   need five beacons; on a 5 m mast (the beacon head on top, guyed to screw anchors, two retroreflective bands) it needs
   exactly canon's three. *Alternative:* keep the tripod and show five beacons, which breaks canon's "three beacons".
10. **The vault shelf as rendered.** It stands on the M1-82 LOC-10 site and is graded flat. The 2034 crew's boot prints
    and tracks are still crisp (no wind). The 2034 marker is not sun-faded, because there is no UV in a permanently
    shadowed region. The case carries only a thin dust film on its identification window. The light is the rover's
    headlights and the helmet lamps, with distant sunlit rims high above. No stars are drawn, because the lamp-lit
    exposure would hide them. *Alternative:* faint stars in the darkest shots.
11. **The vault set.** PR_VaultCase is rebuilt procedurally as one hinged asset in the installed case's look, with
    closed and open states, the outer probe socket, the identification window, a 12-well inner container (capped
    tubes, blank tabs) and a `Label_Lid` plate under the lid for clue 15. Three new props join it: PR_VaultProbe;
    PR_VaultCarrier (a cradle with an MLI sleeve, two lift points and a tether eye, the "closed carrier" of S02 and S06);
    and PR_RoverCargoMount on VH_Rover's rear rack, whose latch flag and separate lock pin give S08's two results.
    *Alternative:* keep the Tripo closed case and add only an open variant.
12. **Build method.** Both assets are fully procedural in Blender, like the airlock and the annex: grid-exact modular
    pieces, two LODs, collision and live-UI slots. Phase 2 spends no Tripo or Meshy credits. The board prompt's
    "generate (Tripo/Meshy)" step does not apply: image-to-3D cannot return grid-exact, pivot-exact modular pieces.

## Canon checks done

The sheets were checked image by image. Everything is in English, and no text is baked into any surface: screens are
`Screen`, `Screen2` and `Screen3` slots, and plates, tags, signs, cards and the lid are blank `Label` slots, so nothing
names Noor before CH05. There are no logos, flags or NASA marks, and no plants in this set. The Moon rules
(ART_BIBLE §2) hold in every exterior: black sky, no fog, haze, wind or dust plumes, hard near-black shadows, one low
Sun from JPL Horizons, no light beams in vacuum, retroreflectors brightening only beside their light source, crisp
tracks, lunar gravity, and the PSR floor never sunlit. Earth is below the terrain for S04 to S08 and outside every
frame at S02, so it is never shown. There is no airborne sound outside: the pump hum is in the ready room. The NASA
data credit line for the terrain is in the handbook §5.

## After approval (phase 2)

1. Extend `build_ch04_assets.py` with LOD1 (Compatibility), the collision export, the `garage.json` and `coldtrap.json`
   catalogues (sizes, pivots, sockets, states, the layout and the survey), `production/manifest/ch04_assets.csv` gate
   rows and `.import` files. Publish into `game/assets/environment/EN_Garage/`, `game/assets/environment/EN_ColdTrap/`
   and the props folders. Bake the procedural sintered, MLI and fabric shaders into PBR sets beside the kit's.
2. Rebuild PR_VaultCase as decided in 11, keeping its path so existing references hold; add PR_VaultProbe,
   PR_VaultCarrier and PR_RoverCargoMount.
3. Sync to Godot and run the quality gate (`verify_gate.py`, a 0 cm floor, ±2 % size, triangle and texture budgets).
   Then make a contact sheet in `production/review/`, record visual verdicts with a Codex second opinion in
   `visual_review.md`, take Godot evidence captures, and run `game/tools/run_tests.sh`.
4. Set the registry rows (EN_Garage, EN_ColdTrap and the new pieces) to `verified` with
   `production/tools/build_registry.py`, update the handbook (§8.3, §8.4, §10), log in `production/AI_PROMPT_LOG.md`, and
   file the M3-4R follow-up for the LOC-08 room and the LOC-09 move (decision 8).
