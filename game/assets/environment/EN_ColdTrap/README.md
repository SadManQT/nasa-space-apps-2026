# EN_ColdTrap — LOC-09 surveyed road and LOC-10 vault shelf pieces (M3-4A)

Approved by Sadman on 7 Nov 2026 ("Approve all 12", [production/concept/chapter4_v1/](../../../../production/concept/chapter4_v1/README.md)).
Built procedurally by `production/tools/build_ch04_assets.py -- publish` (no AI generation, no credits).

- **Pieces:** 7, each in two LODs. `EN_ColdTrap_BeaconMast` is the survey beacon on a 5 m telescoping mast (decision 9).
  The rest are ReturnMarker, SlopeSign, ReferencePlate (the S05 dry reference), SampleStake, TetherAnchor and
  SurveyMarker2034. Driven pieces carry their depth as `mount_y`. Tags, signs and the slope value are blank `Label` slots.
- **The vault set** (in `../../props/`): `PR_VaultCase` is rebuilt hinged in the installed case's 0.60 x 0.39 m footprint,
  with 12 capped wells and `Label_Lid` under the lid for clue 15. With it come `PR_VaultProbe`, `PR_VaultCarrier` (cradle
  and MLI sleeve) and `PR_RoverCargoMount` (latch flag and a separate lock pin).
- **`coldtrap.json`** is an extension catalogue of `kit/habitat_kit.gd`. It carries the pieces and props with their
  sockets, and the survey from `production/tools/coldtrap_survey.py`, Computed from NASA LRO LOLA with JPL Horizons:
  - the real road is 8.56 km long, with a steepest cell of 11.9 deg;
  - the beacons B1 (1.02 km) and B2 (1.88 km) are sunlit at EX-CH04-S04, and B3 (5.24 km) is in terrain shadow; every
    chord clears the curved terrain;
  - the 20 x 15 m shelf is in permanent shadow.

  It also holds the staging offsets for the S04 segments, the S05 station and the shelf. The game keeps P-07's canon
  numbers.
- **Textures:** `textures/` holds the MLI set (the carrier's sleeve); the rest is the M1-05 kit's sets.
- **Tests and evidence:** `game/tools/test_ch04_assets.gd`; `production/qa/evidence/M3-4A_capture.sh`.
- **Next:** moving LOC-09 to the three segments and staging the shelf on the terrain is M3-106 (M3-4R follow-up, decision 8).
