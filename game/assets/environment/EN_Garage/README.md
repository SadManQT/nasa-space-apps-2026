# EN_Garage — the LOC-08 rover garage (M3-4A)

Approved by Sadman on 7 Nov 2026 ("Approve all 12", [production/concept/chapter4_v1/](../../../../production/concept/chapter4_v1/README.md)).
Built procedurally by `production/tools/build_ch04_assets.py -- publish` (no AI generation, no credits).

- **Section (decision 1):** a loading-dock garage. The pressurised ready room stands on a sintered plinth with its deck at
  +1.40 m, level with VH_Rover's side hatch (1.85 m sill). The unpressurised rover bay has the EVA porch at the rover's rear.
  The rover docks its side hatch to the telescoping tunnel (`EN_Garage_DockingPort`, part `DockCollar`), so a trip pumps
  down about 1 m3 of tunnel, never the bay.
- **Pieces:** 17, each `<id>_LOD0.glb` (collision) and `_LOD1.glb` (Compatibility): DockingPort, BayWindow, CargoLock,
  SuitSealPanel, RouteBoard, DepartureBoard, HandoverConsole, CargoRack, ReliefLocker, BayFrame, BayDoor, BayEndWall,
  EVAPorch, Umbilical, Plinth, BayMarkings, Berm. They tile the M1-05 kit's sets (`../kit/textures`), this folder's
  `textures/` (sintered pavers, bellows fabric) and the M1-35 regolith (`../terrain/textures`).
- **`garage.json`** is an extension catalogue of `kit/habitat_kit.gd` (place, bounds, `set_part_open`). It holds the
  pieces with their sockets and moving parts, the approved 12 x 9 m layout (finished-floor positions, anchors, the rover),
  the dock rules (SEALED / EQUALISING / SAFE TO OPEN) and the site (80 m from Aurora at azimuth 150, door facing azimuth 100).
- **`en_garage.gd`** assembles the room and drives the dock collar and hatch, the rover door (it coils into its drum with
  the part kind `scale`), the cargo-lock doors (never both open: the lock fills with dry nitrogen, decision 5) and the
  relief locker.
- **Live UI:** every word is a `Screen*` or `Label*` slot. The route board shows the route cards and the beacon chain, the
  two departure boards show the rosters, the console shows the map, the slope card and the pad camera, and the cargo rack
  carries the ledger.
- **Tests and evidence:** `game/tools/test_ch04_assets.gd`; `production/qa/evidence/M3-4A_capture.sh`.
- **Next:** the campaign room, staging, navigation and the dock cycle are M3-105 (M3-4R follow-up).
