# Lunar rock and regolith kit — M1-35

Tanvir/Codex, 4 November 2026. **Geometry is ready for integration; all materials
are provisional until the human exterior choice in M1-33.** This kit is not yet
placed in the campaign. M1-36 owns the terrain provider and streaming.

`kit.json` lists 16 fracture forms, their actual longest dimension (0.06–10 m),
three explicit GLB LODs per form, triangle counts, and three ground materials.
Forms alternate chips, shards, blocks and slabs. Each closed convex rock has its
base at Y=0, centred X/Z, identity object transforms, and metre units. No NASA
marks, vegetation, atmospheric effects, paid generation or external source art.
These are original procedural shapes, not scanned lunar specimens.

The ground GLBs are 4 m square patches with 0–1 UVs. Their equivalent `.tres`
materials can be assigned to the actual terrain: one UV repeat per 4 m. Surface
variants are fresh, twin rover tracks and alternating boot impressions. Textures
are repeatable grey base colour and tangent normals, not animated dust or
displacement. They are illustrative surfaces, not measurements of lunar soil.

## Scatter integration

```gdscript
const Scatter = preload("res://assets/environment/terrain/lunar_scatter.gd")
# All points, normals and exclusion centres must use the chunk's local space.
# Supply stable, jittered terrain samples (typically 1–4 square metres per cell).
var samples = [{"position": Vector3(2, 0, 3), "normal": Vector3.UP, "area_m2": 4.0}]
var exclusions = [{"position": Vector3.ZERO, "radius_m": 3.0}]
var records = Scatter.placements(samples, 351104, exclusions)
var chunk = Scatter.build_group(records)
add_child(chunk)
# Release the complete chunk with queue_free() when it streams out.
```

`scatter_rules.json` owns density, slope falloff, variant weights, separation,
collision cutoff and LOD distances. Density falls to zero at 50 degrees. Null,
zero, non-finite and downward normals are rejected. Sized exclusion circles keep
landing sites, habitat boundaries and routes clear; greedy size-aware spacing
prevents overlapping rocks within a chunk. **The terrain integrator must also
exclude neighbouring chunk placements to avoid overlaps along chunk borders.**
Samples are not generated or raycast by this helper, and the helper never moves
or edits the terrain. A stable sample order plus per-chunk seed reproduces a
layout. Call it during chunk construction, not every frame.

The three imported meshes use adjoining visibility ranges with no fade (works
in Compatibility). Auto-generated importer LODs are disabled because explicit
LOD meshes are supplied. Rocks at least 0.35 m get a simplified convex collider
from LOD2 on world layer 1; pebbles are decorative. Pass `false` to `build_group`
for collision-free distant chunks. Runtime cache retains at most the 48 shared
rock resources while chunk nodes remain independently disposable. Final draw
call budgets, terrain navigation, chunk sizes and device performance belong to
M1-36, not this kit's verification.

## Rebuild and verify

1. Run Blender 5.2: `blender --background --factory-startup --python production/tools/build_lunar_kit.py`.
2. On Windows, run `production/tools/lunar_contact_sheet.ps1` for diagnostic contact sheets of all 48 meshes and the surfaces.
3. Run `game/tools/run_tests.sh lunar_kit`, then `python -X utf8 production/tools/verify_gate.py` with `GODOT` set.
4. Refresh only these registry rows: `python -X utf8 production/tools/build_registry.py --manifest lunar_kit`.

The generator audits closed manifold edges, positive volume and non-degenerate
faces for all rock LODs before export. The shared gate checks actual Godot import,
triangle/texture budgets, size and floor position. `test_lunar_kit.gd` covers
scatter reproducibility, slope alignment, spacing, exclusions, real resources,
LOD ranges and collision. Its optional native `-- --evidence` writes Godot
screenshots. Contact lighting is diagnostic; the separate ground preview uses a
5-degree hard Sun and black sky with no ambient/fog.
