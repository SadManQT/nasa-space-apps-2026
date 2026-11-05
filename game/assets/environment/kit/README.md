# Modular habitat kit — M1-05

Sadman/night-fable (Claude Fable 5.1), 5 November 2026. Twelve pieces built from the kit sheets
Sadman approved on 5 Nov (M1-04): `production/concept/environment_v1/01_HabitatKit_sheet_A.png`
(walls and openings) and `_B.png` (floor, ceiling, runs and corridor). Built procedurally in
Blender 5.2 by `production/tools/build_habitat_kit.py` (seed 20261105, no generation credits:
image-to-3D cannot return grid-exact modular geometry with clean pivots, LODs and collision).
Photoreal PBR surfaces per the 5 Nov §3 decision (environment realistic, cast cel-shaded); the
materials are plain `StandardMaterial3D` with albedo, normal and ORM textures, so the toon pass
can still restyle them if a room asks for it. No text on any surface, no logos.

`kit.json` is the catalogue: conventions, every piece's LOD files, triangle counts, size, footprint,
mount offset and sockets, and the nine reusable materials. `habitat_kit.gd` reads it.

## Pieces (metres; pivot at the base centre; +Y up; Godot -Z forward)

| Piece | Footprint | Notes |
|---|---|---|
| `EN_Kit_Wall_Straight` | 1.0 x 0.15, 2.6 tall | quilted panel, handrail at 1.0 m, navy skirting; face on z = 0 facing -Z, body behind (+z) |
| `EN_Kit_Wall_Corner` | 0.65 x 0.65 | inside corner, two 0.5 m legs; pivot at the inside corner, the room lies towards -X and -Z |
| `EN_Kit_Wall_Window` | 1.0 x 0.15 | 0.56 x 0.42 m pressure window at 1.55 m, navy frame, transparent `M_Kit_Glass` pane |
| `EN_Kit_Wall_EquipBay` | 1.0 x 0.15 | recessed navy console; material `Screen` (0.5 x 0.3 m at y 1.65) is the live UI surface |
| `EN_Kit_DoorFrame` | 3.0 x 0.30 | two-sided module; 1.2 x 2.1 m opening centred at x = -0.5; child `DoorLeaf` slides +X 1.25 m into the wide jamb |
| `EN_Kit_Hatch` | 2.0 x 0.15 | bulkhead with a 1.18 m round hatch centred 1.2 m up (sill 0.6 m); child `HatchLeaf` hinged at the left collar, opens +Y rotation into the room |
| `EN_Kit_FloorTile` | 1.0 x 1.0 | anti-slip deck 0.06 thick, four tie-down rings; **mount at y = -0.06** so the deck is the floor plane |
| `EN_Kit_CeilingTile` | 1.0 x 1.0 | quilted, vent grille, sensor; the visible face is the base: **mount at y = 2.6** |
| `EN_Kit_LightStrip` | 1.0 x 0.14 | emissive diffuser on the base face: **mount at y = 2.52** under a ceiling tile |
| `EN_Kit_PipeRun` | 1.0 x 0.40 | two coolant pipes and an air duct on brackets, along X; stands on its brackets, rotate to a wall |
| `EN_Kit_CableRun` | 1.0 x 0.27 | navy tray with inspection window and orange latch, along X |
| `EN_Kit_BulkheadRing` | 2.6 x 0.30 | octagon 2.6 m across the flats; inner sill 0.14 above its base: **mount at y = -0.14** |

Each piece has `<id>_LOD0.glb` (game LOD, with Godot collision nodes: `-convcolonly` boxes, or a
`-colonly` trimesh for the hatch bulkhead and the ring) and `<id>_LOD1.glb` (Compatibility LOD,
flat quilt, fewer segments, 512 px textures, no collision). All LOD0 pieces are under 3.5k
triangles (art bible: 2–8k for a modular piece), textures 1024 px (budget 2K).

Room arithmetic: corners take 0.5 m of each wall, so a wall run is `corner + n straight + corner`
and a room of W x D metres needs W-1 and D-1 integer pieces per wall. Door modules replace three
slots; the hatch bulkhead replaces two. Yaw: 0 for a wall on the far (+z) edge, 180 on the near
edge, -90 on the -x edge, +90 on the +x edge. Mirror a door with `scale.x = -1` to park the leaf on
the other side.

## Using the kit

```gdscript
const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
var wall := Kit.place(room, "EN_Kit_Wall_Window", Vector3(2, 0, 4))      # mount offset applied for you
var door := Kit.place(room, "EN_Kit_DoorFrame", Vector3(2, 0, 0), 180)
Kit.set_door_open(door, 1.0)                                           # 0 closed .. 1 open
Kit.set_hatch_open(hatch, 1.0)
for slot in Kit.screen_surfaces(bay):                                 # live UI on the equipment bay
	slot.mesh.set_surface_override_material(slot.surface, screen_material)
```

`instance(id, with_collision, max_lod)` builds the two-LOD group (visibility ranges meet at 12 m,
no fade, so it works in Compatibility); `max_lod = 0` keeps the game LOD only. The LOD0 GLB
already carries `StaticBody3D` collision, so rooms get walls, floors, door leaves and hatch leaves
that block without extra work; `with_collision = false` strips it for distant dressing.

The nine `materials/*.tres` bind the committed `textures/` (tileable: quilt 0.5 m, paint 0.5 m,
steel 0.25 m, floor 1 m) for custom geometry a room builder adds beyond the kit; `uv1_scale` is
already set to the tile size.

## Rebuild and verify

1. `python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup --python production/tools/build_habitat_kit.py` (add `-- --no-render` to skip the Cycles previews).
2. `python3 production/tools/habitat_kit_contact.py` writes the review sheets to `production/review/`.
3. `/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --import`, then `python3 production/tools/verify_gate.py`.
4. `game/tools/run_tests.sh habitat_kit`; with a window, `-- --evidence` writes the Godot screenshots to `production/qa/evidence/M1-05_godot_*.png`.
5. `python3 production/tools/build_registry.py --manifest habitat_kit` refreshes the registry rows.

M1-06 assembles the Chapter 1 rooms from this kit; it owns layout, navigation, lighting and the
live screens. The hatch sill (0.6 m) and the 1.18 m clear diameter are real pressure-hatch sizes:
rooms should treat hatches as door-cycle interactions, not free walking routes.
