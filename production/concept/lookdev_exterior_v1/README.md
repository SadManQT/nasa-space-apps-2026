# Exterior art-direction comparison — M1-32

Prepared for Tanvir, 4 November 2026. **M1-33's human decision is pending.**
The current approved anime cast and toon interiors remain unchanged.

Start with [the A/B decision sheet](00_Compare_A_B.png). It shows the same
observation-bay frame and matching character details in two treatments:

| Option | Treatment | Decision being considered |
|---|---|---|
| A | Stepped cel shading and fine silhouette outlines | Keep the approved anime direction when detailed exteriors surround the cast. |
| B | Softer diffuse/material shading, without the added silhouette outline | Permit a softer exterior character treatment while retaining the same models, faces, clothes and proportions. |

The cast poses, camera, terrain, imported assets and lights are identical between
A and B. Kai and Amara wear their approved indoor duty coveralls **inside a
sealed, pressurized observation bay**. The visible window frame and bulkheads
establish that boundary. Neutral face-atlas overlays are hidden to expose the
approved painted neutral features, consistent with the runtime's transparent
neutral cell. No EVA costume is invented or approved by this comparison.

Individual frames:

1. [Aurora — option A](01_Aurora_A.png)
2. [Aurora — option B](02_Aurora_B.png)
3. [Relay road — rover and long shadows](03_Relay_Road.png)
4. [Cold-trap vault shelf — headlights only](04_Cold_Trap.png)
5. [Malapert relay platform](05_Malapert_Summit.png)

These are **four location studies with an extra A/B render of Aurora**. The
labels refer to intended story settings, not validated geographic placements.

## What these images establish

Grey regolith, angular rocks, hard shadows, an airless black sky, small human
hardware against open terrain, and a readable relationship between cast and
environment. The daytime studies use a 1.5-degree Sun as the specific M1-32
proposal; the existing Art Bible's general 2–6-degree range is not silently
replaced. The cold-trap frame uses only two rover headlights: no Sun, ambient
sky light, fog, atmospheric cone or dust cloud. No external characters appear
without an approved EVA outfit.

The recommendation is **A**, for continuity with the approved cast and interiors.
This is an art recommendation, not a measured frame-rate claim.

## What remains provisional

M1-34's real LOLA heightmaps and dated lighting are not present in this checkout.
The procedural crater/ridge ground is an explicitly labelled **composition
proxy**, not NASA elevation data, a surveyed site or invented geography passed
off as real. Earth is omitted until viewing geometry is verified. The pressure
bay shell, camera placement, material tuning and surface detail are render-only
studies, not installed game assets. Blender approximates the candidate character
treatments; it does not certify a pixel-identical Godot implementation.

Approval chooses an art direction. It does not approve invented mountains,
station placement, route gradients, Earth visibility, mission-date illumination,
new costumes or a hardware performance target. M1-34/M1-36 still supply and
verify those production pieces. M1-35's rock surfaces can be finalized after
M1-33, but its geometry remains the already verified local kit.

## Sources and reproduction

All character/hardware inputs come from the installed approved GLBs; rocks come
from M1-35. `provenance.json` records input SHA-256 hashes, cameras, lighting,
renderer settings and output hashes. No image-generation service, Tripo or Meshy
call was used, and no paid credits were spent. No source GLB was modified.

Run Blender 5.2.3 from the repository root:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python-exit-code 1 --python production/concept/lookdev_exterior_v1/render_studies.py -- --shot aurora --option A --width 1920 --samples 96
```

Repeat for `--shot aurora --option B`, then `--shot road`, `--shot coldtrap`, and
`--shot summit`. Raw renders and working metadata go to ignored
`production/models/lookdev_exterior_v1/`. Run `compose_review.ps1` here to produce
the labelled PNGs and comparison sheet. The script uses Windows System.Drawing
only for layout and captions; it does not paint over the rendered assets.

Review and exact validation: [production/review/M1-32.md](../../review/M1-32.md).
