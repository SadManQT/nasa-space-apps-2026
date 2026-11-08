# EN_Airlock — LOC-05 airlock and sealed transfer vestibule (M3-2A)

Sadman/night-fable (Claude Fable 5.1), 5 November 2026. Five kit-extension pieces built procedurally in Blender 5.2 by
`production/tools/build_chapter2_assets.py` (seed 20261105; no generation service, no credits) on the conventions of the
approved habitat kit (`../kit/README.md`), plus `airlock.json`, the catalogue and the canonical 8 x 4 m double-interlock
layout, and `en_airlock.gd`, which assembles that layout from the kit and these pieces and runs the pressure interlock.
**Status: gate-passed and installed; the 2D sheets in `production/concept/chapter2_v1/` await Sadman's approval before
the registry rows become `verified`.**

The pieces tile the kit's PBR sets and reference them by uri in `../kit/textures` (nothing is stored twice; the
`.glb.import` files keep `gltf/embedded_image_handling=1` so Godot uses the already-imported textures). Materials are
plain `StandardMaterial3D`, so the toon pass can restyle them. No text on any surface, no logos.

## Pieces (metres; pivot at the base centre; +Y up; finished faces towards -Z)

| Piece | Footprint | Notes |
|---|---|---|
| `EN_Airlock_SuitLocker` | 0.6 x 0.55, 2.2 tall | open-front EVA suit locker: hanger rail 1.78 m, helmet shelf 1.86 m, boot tray, backpack brackets, retaining bar with an orange latch, blank name plate; material slot **`RoleTab`** takes the cadet's role colour (`en_airlock.gd` tints it from `cadets` in the catalogue) |
| `EN_Airlock_Bench` | 1.6 x 0.45, 0.45 tall | brushed steel seat on navy pedestals, cross rail, orange boot rail, tie-down rings; the seat repeats the kit's steel four times as often (`SEAT_GRAIN`), so the brushing reads at a real scale up close |
| `EN_Airlock_GlovePort` | 1.0 x 0.15 wall (sleeves reach 0.79 behind) | pressure window 0.56 x 0.42 m at 1.75 m and a pair of glove ports (0.27 m flanges at x +-0.22, 1.19 m); the sleeves hang on the far side, inside the sealed plant chamber. The window opens through the module (M3-104): behind the room-side frame the navy reveal splays to a 0.72 x 0.58 m opening in the far face, which is closed everywhere else, so the pane shows whatever the room builds behind it (LOC-05: Alo's chamber). Its pane is **`M_Airlock_PressureGlass`** (the kit glass at roughness 0.20, so the room's practicals reflect as soft glows, not mirrored discs) |
| `EN_Airlock_PassThrough` | 1.0 x 0.15 wall, chamber 0.42 into the room | two-sided bulkhead with the sealed carrier pass-through: 0.50 x 0.44 m white-lined chamber at 1.00–1.44 m through the wall; children **`LidA`** (room side, hinge on the left) and **`LidB`** (far side, hinge on the right) open +Y 100°; `carrier_socket` inside; `LampSafe` lamp lit while both lids are shut |
| `EN_Airlock_InterlockPanel` | 1.0 x 0.15 wall | recessed console: **`Screen`** slot 0.5 x 0.3 m at 1.70 m for the live words, two pressure gauges, three lamps (**`LampSealed`**, **`LampEqualising`**, **`LampSafe`** materials), orange equalisation wheel, pump grille; child **`CycleLever`** (pull = -70° about X) |

Each piece has `<id>_LOD0.glb` (game LOD, Godot collision nodes) and `<id>_LOD1.glb` (Compatibility LOD, no
collision); all LOD0 pieces are under 3.6k triangles (art bible: 2–8k for a modular piece).

## The vestibule (`airlock.json` → `vestibule`)

Canon ([09_WORLD_AND_LEVEL_DESIGN.md](../../../../game-design/09_WORLD_AND_LEVEL_DESIGN.md) LOC-05): an 8 x 4 m
double-door vestibule with suit lockers, bench, sealed carrier pass-through and glove-port access to Alo, and an
independent pressure interlock; connected to LOC-01, LOC-03 and LOC-06; state words SEALED / EQUALISING / SAFE TO OPEN;
pump sound only while cycling. The layout on the kit grid (interior x 0..8, z 0..4):

- **Suit-up vestibule** x 0..5: inner door to the commons (LOC-01, `EN_Kit_DoorFrame` on the west wall), five lockers
  and the bench against the near wall, the glove-port module and the pass-through on the garden wall (the sealed
  connection to LOC-03 and Alo's chamber: samples cross, people do not).
- **Partition** at x = 5: the inner hatch (`EN_Kit_Hatch`) with the vestibule's interlock panel beside it; back-to-back
  kit walls give the chamber its own finished face.
- **Airlock chamber** x 5.3..8: the outer hatch to the surface (LOC-06) on the east wall with the chamber's own panel.
- Light strips under the ceiling (warm 4000 K in the vestibule, 5000 K in the chamber); anchors for the player, the
  companion at the checklist, the cadet at tools, the suit check, the pass-through, the glove ports, both hatches and the
  exterior step.

## The interlock (`en_airlock.gd`)

```gdscript
const Airlock = preload("res://assets/environment/EN_Airlock/en_airlock.gd")
var airlock := Airlock.new()          # build_on_ready assembles the vestibule under the node
room.add_child(airlock)
airlock.request_cycle("surface")      # EQUALISING for interlock.equalise_seconds (airlock.json), pump plays
airlock.state_text("outer")           # "SAFE TO OPEN" once the chamber matches the surface; "SEALED" on the inner panel
airlock.set_hatch("outer", true)      # refused while EQUALISING, while the chamber is on the other side, or while the inner hatch is open
airlock.set_lid("LidA", true)         # the far-side lid refuses until this one is closed again
airlock.snapshot() / airlock.restore(data)   # the room owner saves and reloads it
```

Rules (from the data file, enforced in code): one hatch open at a time; a hatch opens only when the panel beside it
reads SAFE TO OPEN; the pump runs only while EQUALISING; the pass-through keeps one lid shut at all times. Duplicate
inputs are reported as `duplicate`, not applied twice. Each panel's words describe the hatch it stands beside, so the
two boundaries can never read SAFE TO OPEN together. The words are a `Label3D` on the `Screen` slot (live UI, nothing baked).
`equalise_seconds` (12 s) is compressed time: a real chamber takes minutes to pump down or repressurise, so the room
owner shows a labelled time card for the rest (`interlock.time_compression`; LOC-05 exit behaviour), never an invisible jump.

Static helpers mirror the kit's: `Airlock.instance(id)`, `Airlock.place(parent, id, position, yaw)` (kit ids pass
through to `habitat_kit.gd`), `Airlock.piece(id)`, `Airlock.prop(id)`, `Airlock.surfaces_named(node, "Lamp")`.

## Chapter 2 props in this set (`airlock.json` → `props`)

- `../../props/PR_PaperBee/PR_PaperBee.glb`: Rafi's origami bee (gold duo paper, navy bands, white wings, no face),
  0.089 m long, 152 triangles, textures embedded; each wing is one folded flap whose root panel lies on the thorax, the antennae are rolled-paper rods rooted inside the head; sockets `Socket_Grip` (held) and `Socket_Rest` (placed). The S07
  equipment number is on the recorder's sticker, never on the bee. UI icon: `../../ui/diagrams/PR_PaperBee.png`.
- `../../props/PR_SeedTray/PR_SeedTray.glb`: Kai's clean 12-cell seed tray, 0.50 m, 224 triangles.

## Rebuild and verify

1. `python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 --python production/tools/build_chapter2_assets.py` (`-- --no-render` skips the Cycles previews; `-- --only <id>` re-renders one piece; `-- --room-only` the three vestibule views).
2. `python3 production/tools/chapter2_sheets.py` writes the approval sheets and `production/review/M3-2A_chapter2_contact.png`,
   and publishes the bee's transparent render as `game/assets/ui/diagrams/PR_PaperBee.png`.
3. `Godot --headless --path game --import`, then `python3 production/tools/verify_gate.py` (specs in `production/manifest/chapter2_assets.csv`).
4. `game/tools/run_tests.sh en_airlock`; with a window, `production/qa/evidence/M3-2A_capture.sh` writes the Godot screenshots.
5. `python3 production/tools/build_registry.py` refreshes the registry rows.

Handoff: M1-06 (rooms) wires `en_airlock.gd` into the LOC-05 scene and `room_contract.gd` (the greybox contract still
says 10 x 8 m; canon and this asset are 8 x 4 m) and plays `SFX_GLOVE_PORT` / `SFX_AIRLOCK_CYCLE` from its interactions.
The mission owner (P-03) places the PR_PollinationKit carrier on `carrier_socket` and the bee on the bench.
