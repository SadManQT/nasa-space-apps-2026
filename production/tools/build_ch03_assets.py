"""Build the Chapter 3 (Moonquake) assets that need no generation credits (board M3-3A), with Blender alone.

    python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 \
        --python production/tools/build_ch03_assets.py -- [helmet|descendants|petal|annex|all] [--no-render]

Everything here is either a Blender derivation of an installed, visually approved asset (the execution prompts'
own build methods: "Blender recolour of PR_Helmet", "Blender instancing of PL_Alo_* and PL_Tara_*",
"Blender (small)", "Blender + PL_ZeroSeedlingTray + PR_AnnexDrum") or procedural hardware in the habitat kit's
conventions, so no Tripo or Meshy credit is spent and no new design needs a 2D approval first. The one genuinely
new design of the task, the fitted EVA outfits (CH_Cadet_EVA), is a separate 2D approval request
(production/concept/turnarounds_eva_v1/) and is not built here.

Outputs (deterministic, seed 20261103):
  game/assets/props/PR_Helmet_Roles/PR_Helmet_Roles.glb        PR_Helmet with a separate "RoleStripe" material slot
      (crown stripe, colour set per cadet at runtime), a hinged "Visor" child, the approved flag and Aurora patch
      decals, equip sockets; helmet_roles.json carries the per-cadet stripe colour, fit scale and head offset.
  game/assets/plants/PL_Descendants/PL_Descendants.glb         the October descendant rack: 12 positions (Pos_01..12),
      7 purple-stem Alo and 5 green-stem Tara descendants instanced from the installed bloom models, a lineage
      label plate per position ("Label" material, live UI) and a dedication card slot; descendants.json lists which
      position carries which stem colour (CH04-S01: seven purple, five green).
  game/assets/plants/PL_Descendants_Planted/PL_Descendants_Planted.glb   the same rack on 21 May: twelve filled
      cassettes, no plants (EX-CH03-S11).
  game/assets/props/PR_PressedPetal/PR_PressedPetal.glb        one dried Alo petal in a dated archival sleeve (flat;
      the date label is a "Label" live-UI slot, nothing is baked).
  game/assets/props/PR_PressedPetal_Mounted/PR_PressedPetal_Mounted.glb  the sleeve standing in a board clip for the
      lineage board, the shelter and the final garden close-up.
  game/assets/environment/EN_ZeroAnnex/EN_ZeroAnnex_*_LOD0/1.glb     ten Expedition Zero annex pieces (2034
      generation hardware, frosted on the cold side) in the habitat kit's grid conventions: floor hatch module with
      the displaced cover, the N.R. hatch leaf and its camera port, ladder, wall, corner, floor grating, ceiling
      panel and the ceiling panel with its dead fixture, frozen-tray bench (two PL_ZeroSeedlingTray sockets), chart archive (growth chart, sealed route sheet, map
      pouch, loop-valve photograph, 2034 service tag) and the warm-side support station; textures stored once in
      textures/; annex.json is the catalogue habitat_kit.gd reads as an extension.
  production/manifest/ch03_assets.csv                            gate specs for production/tools/verify_gate.py
  production/models/ch03/preview/*.png                           Cycles previews for production/tools/ch03_contact.py

Conventions as in build_habitat_kit.py (metres, +Y up, Godot -Z forward, pivots at the base centre, moving parts as
named child nodes with their own pivots, no text on any surface: labels, charts, screens and nameplates are
separate material slots named Label*, Document* and Screen* for live UI).
"""
import csv
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_habitat_kit as K  # noqa: E402  (Builder, textures, export, preview rig; it defines nothing at import but constants)

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / "game/assets"
STAGE = ROOT / "production/models/ch03"
PREVIEW = STAGE / "preview"
MAIN_CHECKOUT = Path("/Users/sadmansakib/nasa-space-apps-2026")  # Git LFS smudged files live in the main checkout
SEED = 20261103
TASK = "M3-3A"
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
WHAT = next((a for a in ARGS if not a.startswith("--")), "all")
RENDER = "--no-render" not in ARGS
WALL_H, WALL_D = K.WALL_H, K.WALL_D
ROLE_COLOURS = {  # ART_BIBLE §3 role colours (sRGB), gold for the commander's tabs
    "kai": ("Kai", "orange", (0.949, 0.420, 0.129)),
    "amara": ("Amara", "cyan", (0.102, 0.737, 0.824)),
    "mei": ("Mei", "green", (0.231, 0.682, 0.337)),
    "rafi": ("Rafi", "purple", (0.541, 0.286, 0.741)),
    "ferreira": ("Ferreira", "gold", (0.949, 0.760, 0.188)),
}
# Head regions measured on the installed v8 bodies (Blender frame, metres above the floor), production/tools inspect
# run of 5 Nov 2026: x and y extents of every vertex above the neck bone, and the Neck / Head bone origins.
HEADS = {
    "kai": dict(width=0.273, depth=0.292, height=0.323, neck_y=1.417, head_y=1.560, head_front=-0.198, head_back=0.094, bone_y=-0.031),
    "amara": dict(width=0.222, depth=0.349, height=0.413, neck_y=1.307, head_y=1.401, head_front=-0.126, head_back=0.223, bone_y=0.010),
    "mei": dict(width=0.280, depth=0.380, height=0.347, neck_y=1.253, head_y=1.347, head_front=-0.176, head_back=0.204, bone_y=-0.028),
    "rafi": dict(width=0.357, depth=0.385, height=0.305, neck_y=1.535, head_y=1.650, head_front=-0.145, head_back=0.240, bone_y=0.018),
    "ferreira": dict(width=0.225, depth=0.263, height=0.312, neck_y=1.368, head_y=1.473, head_front=-0.071, head_back=0.192, bone_y=0.062),
}
COL = K.COL_SUFFIXES
NOCOL = ((0, 0, 0),)


def lfs(path):
    """A repo file, read from the main checkout when this worktree only holds its Git LFS pointer."""
    p = ROOT / path
    if p.exists() and p.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n":
        return p
    return MAIN_CHECKOUT / path


# ----------------------------------------------------------------------------------------------- textures

def grid(size):
    y, x = np.mgrid[0:size, 0:size] / size
    return x, 1 - y


def paint_set(rng, tints, wear=1.0, tile=0.5, prefix="Zero"):
    """The kit's powder-coat generator with more chips and scuffs: 2034 hardware that has been cold for 12 years."""
    size = 512
    x, y = grid(size)
    peel = K.fractal(rng, size, 20, 120, 1.2)
    scuff = K.fractal(rng, size, 3, 40, 2.2)
    # chips gather where hands, boots and carts wore the coat (a low-frequency wear field), not as an even speckle
    worn = np.clip(K.fractal(rng, size, 1, 4, 2.0), 0, None)
    chips = (K.fractal(rng, size, 6, 60, 1.6) > 2.4 - 0.5 * wear * worn)
    height = 0.00010 * peel + 0.00025 * np.clip(scuff - 1.6, 0, None) - 0.00030 * chips
    tone = 1 - 0.035 * wear * np.clip(scuff - 1.1, 0, None) - 0.012 * (K.fractal(rng, size, 2, 10, 2.0) > 0.9)
    rough = np.clip(0.48 + 0.08 * K.fractal(rng, size, 3, 30, 1.8) + 0.3 * wear * np.clip(scuff - 1.3, 0, None) + 0.2 * chips, 0, 1)
    normal = K.normal_map(height, tile)
    orm = np.stack([np.ones_like(tone), rough, 0.9 * chips], -1)
    out = {}
    for name, c in tints.items():
        base = np.stack([tone * c[0], tone * c[1], tone * c[2]], -1)
        base = np.where(chips[..., None], np.stack([0.50 + 0.02 * peel] * 3, -1), base)
        out[prefix + name] = dict(tile=tile, base=base, normal=normal, orm=orm, shared=prefix + "Paint")
    return out


def annex_texture_sets(rng):
    sets = {}
    # Frost: the 2034 olive-grey panel paint under a thin hoar-frost film (deposited from the annex's residual moisture
    # when it went cold). Real hoar frost on a flat panel is an even crystalline film: millimetre crystals and small
    # feathered clumps, only gently thicker or thinner over tens of centimetres, the paint faintly showing where it is
    # thin. A surface, never a haze. (Fix round 2: the first version modulated the film by +-45 % at 4-25 cm and read
    # as camouflage blotches in the room.) The fields of the first version are still drawn from the shared generator
    # so every texture set after this one stays byte-identical; the film itself uses its own seeded generator.
    size = 1024
    for low, high, beta in ((2, 12, 1.9), (60, 400, 0.8), (10, 80, 1.4)):
        K.fractal(rng, size, low, high, beta)
    frng = np.random.default_rng(SEED + 31)
    drift = K.fractal(frng, size, 1, 3, 2.0)          # 17-50 cm: the film's slow thickness drift
    clumps = K.fractal(frng, size, 18, 90, 1.3)       # 6-28 mm: feathered crystal clumps
    grain = K.fractal(frng, size, 120, 480, 0.6)      # 1-4 mm: single crystals
    film = np.clip(0.70 + 0.06 * drift + 0.07 * np.tanh(clumps) + 0.05 * grain, 0.45, 0.92)
    height = 0.00018 * np.clip(clumps, 0, None) + 0.00009 * np.clip(grain, 0, None) + 0.00004 * drift
    paint = np.array([0.46, 0.49, 0.43])[None, None, :]
    white = np.array([0.85, 0.88, 0.91])[None, None, :]
    sparkle = (0.035 * (grain > 2.2))[..., None]       # crystal facets catching the headlamp
    base = paint * (1 - film[..., None]) + white * film[..., None] + sparkle
    rough = np.clip(0.80 + 0.06 * clumps.clip(-1, 1) - 0.25 * (grain > 2.2), 0.45, 0.95)
    sets["Frost"] = dict(tile=0.5, base=base, normal=K.normal_map(height, 0.5), orm=np.stack([np.ones_like(rough), rough, 0 * rough], -1))
    sets.update(paint_set(rng, {"Grey": (0.62, 0.64, 0.60), "Navy": (0.14, 0.18, 0.26), "Orange": (0.86, 0.43, 0.17), "Dark": (0.17, 0.175, 0.18), "Olive": (0.46, 0.49, 0.42)}))
    # Grating: open steel floor grating 25 x 100 mm cells over a dark pit (the lower annex deck). The bars have
    # rounded 1.5 mm shoulders (a soft mask) rather than a hard 6 mm step: the step made one-pixel normal spikes that
    # shimmered as moire on the floor in Godot (fix round 2, Codex's visual second opinion).
    size = 1024
    x, y = grid(size)
    soft = lambda frac, half, edge: np.clip((half - np.abs(frac - 0.5)) / edge + 0.5, 0.0, 1.0)
    bx = soft((x * 20) % 1, 0.12, 0.06)
    by = soft((y * 5) % 1, 0.05, 0.015)
    cover = np.maximum(bx, by)
    shoulder = cover * cover * (3 - 2 * cover)
    grain = K.streaks(rng, size)
    height = 0.006 * shoulder + 0.00003 * grain * shoulder
    tone = 0.08 + (0.34 + 0.03 * grain) * shoulder
    base = np.stack([tone, tone * 1.01, tone * 1.03], -1)
    rough = np.clip(0.95 - (0.50 - 0.05 * grain) * shoulder, 0, 1)
    ao = 0.35 + 0.65 * shoulder
    sets["Grating"] = dict(tile=0.5, base=base, normal=K.normal_map(height, 0.5), orm=np.stack([ao, rough, shoulder], -1))
    # Steel: brushed stainless (handrails, hinges, the dogging wheel).
    size = 512
    grain = K.streaks(rng, size)
    tone = 0.78 + 0.035 * grain
    sets["Steel"] = dict(tile=0.25, base=np.stack([tone, tone * 1.005, tone * 1.01], -1), normal=K.normal_map(0.00004 * grain, 0.25),
                         orm=np.stack([np.ones_like(tone), np.clip(0.36 + 0.07 * grain, 0.1, 0.8), np.ones_like(tone)], -1))
    return sets


def save_sets(sets, directory, prefix, lods=(0, 1)):
    """Writes every set at LOD0 (and halved at LOD1); returns {lod: {name: {base, normal, orm, tile}}}."""
    images = {lod: {} for lod in lods}
    for name, s in sets.items():
        shared = s.get("shared", name)
        for lod in lods:
            sub = directory if lod == 0 else directory / "lod1"
            sub.mkdir(parents=True, exist_ok=True)
            suffix = "_LOD1" if lod else ""
            shrink = (lambda a: a) if lod == 0 else K.half
            maps = {"base": K.save_image(f"T_{prefix}_{name}_BaseColor{suffix}", shrink(s["base"]), sub)}
            for key, label in (("normal", "Normal"), ("orm", "ORM")):
                img_name = f"T_{prefix}_{shared}_{label}{suffix}"
                if img_name not in bpy.data.images:
                    arr = shrink(s[key])
                    if key == "normal" and lod:
                        arr = K.renormalise(arr)
                    K.save_image(img_name, arr, sub, srgb=False)
                maps[key] = bpy.data.images[img_name]
            images[lod][name] = dict(maps, tile=s["tile"])
    return images


def flat(name, color, roughness=0.5, emission=None, alpha=None, metallic=0.0):
    mat = K.pbr_material(name, None, roughness, color, emission=emission, alpha=alpha)
    mat.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = metallic
    return mat


def dielectric(mat):
    """A textured material with no metal in it (paper, plant tissue): Metallic becomes a constant 0 instead of the ORM's
    blue channel, so the GLB carries metallicFactor 0. Wired to the texture, the exporter leaves the factor out (glTF
    default 1.0) and Godot imports metallic 1.0 and roughness 1.0 times the map (M3-108). Roughness and occlusion
    still come from the ORM's green and red channels."""
    tree = mat.node_tree
    socket = tree.nodes["Principled BSDF"].inputs["Metallic"]
    for link in list(socket.links):
        tree.links.remove(link)
    socket.default_value = 0.0
    return mat


# ----------------------------------------------------------------------------------------------- shared helpers

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if bpy.context.scene.world is None:
        bpy.context.scene.world = bpy.data.worlds.new("World")
    K._gltf_group = None


def export_embedded(objs, path, root=None):
    """GLB with its textures embedded (single-folder assets: textures are never stored twice for one asset)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    if root is not None:
        root.select_set(True)
        bpy.context.view_layer.objects.active = root
    else:
        bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_animations=False, export_cameras=False, export_lights=False,
                              export_extras=False, export_image_format="AUTO", export_texcoords=True, export_normals=True)
    print(f"WROTE {path.relative_to(ROOT)} {path.stat().st_size // 1024} KB")


def import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:  # the glTF importer's bone-display icosphere never belongs to a prop
        if o.type == "MESH" and o.name.lower().startswith("icosphere"):
            bpy.data.objects.remove(o)
    return [o for o in new if o.name in bpy.data.objects]


def image_pixels(img):
    arr = np.empty(img.size[0] * img.size[1] * 4, dtype=np.float32)
    img.pixels.foreach_get(arr)
    return arr.reshape(img.size[1], img.size[0], 4)


def face_colours(obj):
    """sRGB base colour sampled under each face's UV centre (Tripo atlases: colour is the only material cue)."""
    mat = obj.data.materials[0]
    tex = next(n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE" and n.image and "basecolor" in n.image.name.lower())
    px = image_pixels(tex.image)
    h, w = px.shape[:2]
    uv = obj.data.uv_layers.active.data
    out = np.zeros((len(obj.data.polygons), 3))
    for p in obj.data.polygons:
        u = np.mean([uv[l].uv[0] for l in p.loop_indices]) % 1.0
        v = np.mean([uv[l].uv[1] for l in p.loop_indices]) % 1.0
        out[p.index] = px[int(v * (h - 1)), int(u * (w - 1)), :3]
    return out


def connected_components(obj, faces):
    """Groups a face index set into edge-connected components, largest first."""
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    chosen = set(faces)
    seen, comps = set(), []
    for f in faces:
        if f in seen:
            continue
        stack, comp = [f], []
        seen.add(f)
        while stack:
            i = stack.pop()
            comp.append(i)
            for e in bm.faces[i].edges:
                for g in e.link_faces:
                    if g.index in chosen and g.index not in seen:
                        seen.add(g.index)
                        stack.append(g.index)
        comps.append(comp)
    bm.free()
    return sorted(comps, key=len, reverse=True)


def fill_holes(obj, faces, rounds=3):
    """Adds faces that share two or more edges with the selection (texture sampling misses faces on chart seams)."""
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    chosen = set(faces)
    for _ in range(rounds):
        added = set()
        for f in bm.faces:
            if f.index in chosen:
                continue
            shared = sum(1 for e in f.edges for g in e.link_faces if g is not f and g.index in chosen)
            if shared >= 2:
                added.add(f.index)
        if not added:
            break
        chosen |= added
    bm.free()
    return sorted(chosen)


def separate_faces(obj, faces, name):
    """Moves the given faces into a new object (same materials and UVs), returns it."""
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    chosen = {bm.faces[i] for i in faces}
    new_mesh = bpy.data.meshes.new(name)
    bm_new = bm.copy()
    bm_new.faces.ensure_lookup_table()
    keep_new = {bm_new.faces[i] for i in faces}
    bmesh.ops.delete(bm_new, geom=[f for f in bm_new.faces if f not in keep_new], context="FACES")
    bm_new.to_mesh(new_mesh)
    bm_new.free()
    bmesh.ops.delete(bm, geom=list(chosen), context="FACES")
    bm.to_mesh(obj.data)
    bm.free()
    for m in obj.data.materials:
        new_mesh.materials.append(m)
    new = bpy.data.objects.new(name, new_mesh)
    new.matrix_world = obj.matrix_world.copy()
    bpy.context.scene.collection.objects.link(new)
    return new


def set_origin(obj, point):
    """Moves an object's origin to a world point without moving its geometry."""
    offset = obj.matrix_world.inverted() @ Vector(point)
    obj.data.transform(Matrix.Translation(-offset))
    obj.matrix_world = obj.matrix_world @ Matrix.Translation(offset)


def mesh_bounds(objs):
    """World bounds of the visible meshes (collision shapes excluded), as Godot's gate measures them."""
    pts = [o.matrix_world @ Vector(c) for o in objs if o.type == "MESH" and not o.name.endswith(COL) for c in o.bound_box]
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])


def tri_count(objs):
    return sum(len(p.vertices) - 2 for o in objs if o.type == "MESH" and not o.name.endswith(COL) for p in o.data.polygons)


def decimate(obj, target):
    polys = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if polys <= target:
        return
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = target / polys
    mod.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)


def render_rig():
    camera, rig = K.setup_render()
    bpy.context.scene.cycles.samples = 96
    bpy.context.scene.render.threads_mode = "FIXED"
    bpy.context.scene.render.threads = 4
    return camera, rig


def render(camera, objs, name, direction=(0.7, 1.0, 0.55), pad=1.25):
    """Cycles preview of the visual meshes; the Godot collision shapes (-colonly objects) are hidden for the picture."""
    PREVIEW.mkdir(parents=True, exist_ok=True)
    colliders = [o for o in objs if o.name.endswith(COL)]
    K.set_visible(colliders, False)
    K.render_piece(camera, [o for o in objs if o.type == "MESH" and not o.name.endswith(COL)], PREVIEW / f"{name}.png", direction, pad)
    K.set_visible(colliders, True)
    print("PREVIEW", name)


MANIFEST_ROWS = []


def manifest(name, source, flag, size, tris, tex, game_path, notes):
    MANIFEST_ROWS.append(dict(name=name, concept_or_source=source, size_flag=flag, size_m=size, tris=tris, tex=tex,
                              game_path=game_path, art_status="derived_from_verified_assets", notes=f"{TASK} {notes}"))


def write_manifest():
    path = ROOT / "production/manifest/ch03_assets.csv"
    rows = {}
    if path.exists():
        for r in csv.DictReader(open(path, encoding="utf-8")):
            rows[r["name"]] = r
    for r in MANIFEST_ROWS:
        rows[r["name"]] = r
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["name", "concept_or_source", "size_flag", "size_m", "tris", "tex", "game_path", "art_status", "notes"])
        w.writeheader()
        w.writerows(rows[k] for k in sorted(rows))
    print("MANIFEST", path.relative_to(ROOT), len(rows), "rows")


# =============================================================================================== PR_Helmet_Roles

def face_data(obj):
    centres = np.array([obj.matrix_world @ p.center for p in obj.data.polygons])
    normals = np.array([(obj.matrix_world.to_3x3() @ p.normal).normalized() for p in obj.data.polygons])
    return centres, normals


def weld(obj, dist=0.00002):
    """Tripo GLBs are split at every UV seam; weld them so face connectivity means something (UVs stay per loop)."""
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=dist)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()


def clean_visor(tripo_visor, centre, shell):
    """A clean gold sun visor in place of the one cut from the Tripo texture (whose edge followed ragged texels).

    The new visor is a spherical shell about the hinge point covering the same angular footprint as Tripo's raised
    visor (2nd to 98th percentiles, so stray texels do not widen it), with a superellipse outline, 3 mm thick, gold
    on the faces and a grey rim. Its radius clears the shell and crown under it in both the raised and the lowered
    (closed) pose, so rotating the Visor child about X never cuts into the helmet."""
    pts = np.array([tuple(tripo_visor.matrix_world @ v.co - centre) for v in tripo_visor.data.vertices])
    dist = np.linalg.norm(pts, axis=1)
    lat = np.arcsin(np.clip(pts[:, 0] / dist, -1, 1))  # angle out of the YZ plane
    arc = np.arctan2(pts[:, 2], -pts[:, 1])  # angle about X from the front (-Y) up over the crown
    half_lat = float(np.mean(np.abs(np.percentile(lat, [2, 98]))))
    arc_lo, arc_hi = (float(v) for v in np.percentile(arc, [2, 98]))
    closed = math.radians(78.0)
    # clearance: shell and crown vertices inside the footprint in either pose
    sv = np.array([tuple(shell.matrix_world @ v.co - centre) for v in shell.data.vertices])
    sd = np.linalg.norm(sv, axis=1)
    slat = np.arcsin(np.clip(sv[:, 0] / np.maximum(sd, 1e-6), -1, 1))
    sarc = np.arctan2(sv[:, 2], -sv[:, 1])
    inside = (np.abs(slat) < half_lat * 0.92) & (sarc > arc_lo - closed) & (sarc < arc_hi)
    radius = max(float(np.median(dist)), float(np.percentile(sd[inside], 97)) if inside.any() else 0.0) + 0.004
    radius = min(radius, float(np.median(dist)) + 0.015)
    n_lat, n_arc = 28, 20
    verts, faces, uvs = [], [], []
    for j in range(n_arc + 1):
        for i in range(n_lat + 1):
            u, v = -1 + 2 * i / n_lat, -1 + 2 * j / n_arc
            m = max(abs(u), abs(v))
            sq = (abs(u) ** 4 + abs(v) ** 4) ** 0.25
            if sq > 1e-9:
                u, v = u * m / sq, v * m / sq  # square grid onto a superellipse (rounded corners, smooth edge)
            a = u * half_lat
            t = (arc_lo + arc_hi) / 2 + v * (arc_hi - arc_lo) / 2
            verts.append(centre + radius * Vector((math.sin(a), -math.cos(a) * math.cos(t), math.cos(a) * math.sin(t))))
            uvs.append((0.5 + 0.5 * u, 0.5 + 0.5 * v))
    for j in range(n_arc):
        for i in range(n_lat):
            k = j * (n_lat + 1) + i
            faces.append((k, k + 1, k + n_lat + 2, k + n_lat + 1))
    mesh = bpy.data.meshes.new("Visor")
    mesh.from_pydata([tuple(p) for p in verts], [], faces)
    gold = flat("M_VisorGold", (0.80, 0.60, 0.26), 0.12, metallic=1.0)
    rim = flat("M_VisorRim", (0.70, 0.71, 0.73), 0.4)
    mesh.materials.append(gold)
    mesh.materials.append(rim)
    uv = mesh.uv_layers.new(name="UVMap")
    for poly in mesh.polygons:
        poly.use_smooth = True
        for li, vi in zip(poly.loop_indices, poly.vertices):
            uv.data[li].uv = uvs[vi]
    mesh.update()
    first = mesh.polygons[0]
    if first.normal.dot(Vector(first.center) - centre) < 0:
        mesh.flip_normals()
    visor = bpy.data.objects.new("Visor", mesh)
    bpy.context.scene.collection.objects.link(visor)
    solid = visor.modifiers.new("Solidify", "SOLIDIFY")
    solid.thickness = 0.003
    solid.offset = 1.0
    solid.material_offset_rim = 1
    bpy.context.view_layer.objects.active = visor
    bpy.ops.object.select_all(action="DESELECT")
    visor.select_set(True)
    bpy.ops.object.modifier_apply(modifier=solid.name)
    bpy.ops.object.select_all(action="DESELECT")
    print(f"HELMET clean visor: radius {radius:.3f} (Tripo median {float(np.median(dist)):.3f}), half width {math.degrees(half_lat):.1f} deg, "
          f"arc {math.degrees(arc_lo):.1f}..{math.degrees(arc_hi):.1f} deg")
    # Tripo bumps on the crown (a brow box, slivers) that reach the visor's sweep would pierce it: remove each such
    # protrusion whole (the clean crown cap lies under them, so no hole opens)
    sweep = (np.abs(slat) < half_lat + 0.05) & (sarc > arc_lo - closed - 0.05) & (sarc < arc_hi + 0.05)
    out_v = sweep & (sd > radius - 0.004)
    hit = [p.index for p in shell.data.polygons if any(out_v[v] for v in p.vertices)]
    if hit:
        crown_r = float(np.median(sd[sweep & (sv[:, 2] > 0.05)])) if (sweep & (sv[:, 2] > 0.05)).any() else radius - 0.02
        above = [p.index for p in shell.data.polygons if all(sweep[v] and sd[v] > crown_r - 0.003 for v in p.vertices)
                 and p.material_index == 0]
        comps = connected_components(shell, above)
        doomed = sorted({i for comp in comps if set(comp) & set(hit) and len(comp) < 600 for i in comp})
        import bmesh
        bm = bmesh.new()
        bm.from_mesh(shell.data)
        bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[bm.faces[i] for i in doomed], context="FACES")
        bm.to_mesh(shell.data)
        bm.free()
        shell.data.update()
        print(f"HELMET removed {len(doomed)} crown faces in {sum(1 for c in comps if set(c) & set(hit))} protrusions from the visor's sweep "
              f"({len(hit)} faces reached it)")
    return visor


def build_helmet():
    reset_scene()
    src = GAME / "props/PR_Helmet/PR_Helmet.glb"
    objs = import_glb(src)
    shell = next(o for o in objs if o.type == "MESH")
    shell.name = "Shell"
    weld(shell)
    bpy.context.view_layer.update()
    colours = face_colours(shell)
    centres, normals = face_data(shell)
    # 1. the gold sun visor: warm, saturated faces form one connected shell over the crown (Tripo built it raised)
    r, g, b = colours[:, 0], colours[:, 1], colours[:, 2]
    gold = (r > 0.28) & (r > b * 1.4) & ((r - b) > 0.12) & (centres[:, 2] > 0.10)
    comps = connected_components(shell, [int(i) for i in np.flatnonzero(gold)])
    visor_faces = fill_holes(shell, comps[0])
    print(f"HELMET visor faces {len(visor_faces)} of {len(shell.data.polygons)} ({len(comps)} gold components, next {len(comps[1]) if len(comps) > 1 else 0})")
    visor = separate_faces(shell, visor_faces, "Visor")
    # Tripo modelled the raised visor as the crown surface itself, so a lowered visor would leave a hole: keep a copy of
    # that surface in the shell as the helmet's own crown (white, like the rest of the shell) under the gold visor.
    # The crown is a clean spherical cap just inside the visor (the shell hides it everywhere else).
    visor_pts = [visor.matrix_world @ v.co for v in visor.data.vertices]
    sphere_c = Vector((0.0, 0.004, 0.233))
    radius = float(np.mean([(p - sphere_c).length for p in visor_pts])) - 0.005
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=radius, location=sphere_c)
    crown = bpy.context.object
    crown.name = "Crown"
    crown.data.materials.append(flat("M_Crown", (0.80, 0.81, 0.83), 0.4))
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(crown.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.02], context="VERTS")  # keep the upper cap only
    bm.to_mesh(crown.data)
    bm.free()
    for poly in crown.data.polygons:
        poly.use_smooth = True
    crown.data.uv_layers.new(name="UVMap")
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = shell
    shell.select_set(True)
    crown.select_set(True)
    bpy.ops.object.join()
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.update()
    centres, normals = face_data(shell)
    # 2. the sphere centre of the outer shell: the hinge of a raised visor runs through it, along X
    outer = [i for i in range(len(centres)) if centres[i][2] > 0.14 and normals[i].dot(centres[i] - np.array([0, 0, 0.2])) > 0]
    hinge = Vector((0.0, float(np.mean(centres[outer][:, 1])), float(np.mean(centres[outer][:, 2]))))
    tripo_visor = visor
    visor = clean_visor(tripo_visor, hinge, shell)
    bpy.data.objects.remove(tripo_visor)
    # the Tripo visor held the name until now, so the clean one was "Visor.001": claim "Visor" (helmet_roles.gd
    # drives the child by that exact name) before the export
    visor.name = "Visor"
    visor.data.name = "Visor"
    set_origin(visor, hinge)
    # gold texels the visor cut left on the shell (hinge arms, brow) take the shell's white instead of a ragged gold edge
    colours = face_colours(shell)
    centres, normals = face_data(shell)
    tripo_face = np.array([p.material_index == 0 for p in shell.data.polygons])  # the joined crown has no texture to sample
    stray = np.flatnonzero((colours[:, 0] > 0.28) & (colours[:, 0] > colours[:, 2] * 1.4) & ((colours[:, 0] - colours[:, 2]) > 0.12)
                           & (centres[:, 2] > 0.10) & tripo_face)
    if len(stray):
        slot = next(i for i, m in enumerate(shell.data.materials) if m.name.startswith("M_Crown"))
        for i in stray:
            shell.data.polygons[int(i)].material_index = slot
    print(f"HELMET {len(stray)} stray gold faces repainted shell white")
    bpy.context.view_layer.update()
    vlo, vhi = mesh_bounds([visor])
    print(f"HELMET hinge {tuple(round(v, 3) for v in hinge)} visor bounds {tuple(round(v, 3) for v in vlo)} {tuple(round(v, 3) for v in vhi)}")
    # inner clearance: shell vertices whose normal points at the centre, above the neck ring
    inner = [shell.matrix_world @ v.co for v in shell.data.vertices
             if (shell.matrix_world @ v.co).z > 0.16 and (shell.matrix_world.to_3x3() @ v.normal).dot(hinge - shell.matrix_world @ v.co) > 0]
    ilo = Vector([min(p[i] for p in inner) for i in range(3)])
    ihi = Vector([max(p[i] for p in inner) for i in range(3)])
    clear_w, clear_d = ihi.x - ilo.x, ihi.y - ilo.y
    lo, hi = mesh_bounds([shell, visor])
    clear_h = hi.z - 0.012  # crown liner to the ring bottom (the ring sits around the neck, so the whole height is usable)
    print(f"HELMET clearance w {clear_w:.3f} d {clear_d:.3f} h {clear_h:.3f}; outer {tuple(round(v, 3) for v in (hi - lo))}")
    # 3. the role stripe: a raised band over the rear crown behind the visor, its own material slot
    # (the whole crown is the visor, so the stripe runs down the back of the shell: it reads from behind and in profile)
    # Built as a crisp strip projected onto the shell, not from the ragged Tripo triangles.
    bvh = BVHTree.FromObject(shell, bpy.context.evaluated_depsgraph_get())
    stripe_mat = flat("RoleStripe", (0.122, 0.165, 0.267), 0.45)
    verts, faces = [], []
    n_along, n_across, half_w = 16, 2, 0.012
    for j in range(n_along + 1):
        phi = math.radians(-42 + (55 + 42) * j / n_along)
        for i in range(n_across + 1):
            x = -half_w + 2 * half_w * i / n_across
            p = hinge + Vector((x, 0.2 * math.cos(phi), 0.2 * math.sin(phi)))
            loc, nrm, _, _ = bvh.find_nearest(p)
            verts.append(loc + nrm * 0.0025)
    for j in range(n_along):
        for i in range(n_across):
            a = j * (n_across + 1) + i
            faces.append((a, a + 1, a + n_across + 2, a + n_across + 1))
    stripe_mesh = bpy.data.meshes.new("RoleStripe")
    stripe_mesh.from_pydata([tuple(v) for v in verts], [], faces)
    stripe_mesh.materials.append(stripe_mat)
    stripe_mesh.uv_layers.new(name="UVMap")
    for poly in stripe_mesh.polygons:
        poly.use_smooth = True
    stripe_mesh.update()
    stripe = bpy.data.objects.new("RoleStripe", stripe_mesh)
    bpy.context.scene.collection.objects.link(stripe)
    bpy.context.view_layer.update()
    # the strip's winding may face inward: flip if the first face points at the hinge
    f0 = stripe.data.polygons[0]
    if (stripe.matrix_world.to_3x3() @ f0.normal).dot(Vector(f0.center) - (stripe.matrix_world.inverted() @ hinge)) < 0:
        stripe.data.flip_normals()
    solid = stripe.modifiers.new("Solidify", "SOLIDIFY")
    solid.thickness = 0.003
    solid.offset = -1.0
    bpy.context.view_layer.objects.active = stripe
    bpy.ops.object.modifier_apply(modifier=solid.name)
    bpy.ops.object.select_all(action="DESELECT")
    # 4. the approved patches as curved decals on the sides (flag on the character's LEFT, +X; Aurora on the RIGHT)
    decals = []
    for side, name, png, size in ((1, "PatchFlag", "production/concept/patches/patch_bangladesh.png", (0.060, 0.036)),
                                  (-1, "PatchAurora", "production/concept/patches/patch_aurora.png", (0.046, 0.046))):
        img = bpy.data.images.load(str(lfs(png)))
        img.name = name
        mat = K.pbr_material("M_" + name, None, 0.7)
        tree = mat.node_tree
        tex = tree.nodes.new("ShaderNodeTexImage")
        tex.image = img
        bsdf = tree.nodes["Principled BSDF"]
        tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        tree.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        mat.surface_render_method = "BLENDED"
        n = 6
        verts, faces, uvs = [], [], []
        anchor = Vector((side * (hi.x - lo.x) / 2, hinge.y + 0.09, 0.175))
        for j in range(n + 1):
            for i in range(n + 1):
                u, v = i / n, j / n
                p = anchor + Vector((0, (u - 0.5) * size[0] * -side, (v - 0.5) * size[1]))
                loc, nrm, _, _ = bvh.find_nearest(p)
                verts.append(loc + nrm * 0.0018)
                uvs.append((u, v))
        for j in range(n):
            for i in range(n):
                a = j * (n + 1) + i
                faces.append((a, a + 1, a + n + 2, a + n + 1) if side > 0 else (a, a + n + 1, a + n + 2, a + 1))
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([tuple(v) for v in verts], [], faces)
        mesh.materials.append(mat)
        uv = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            poly.use_smooth = True
            for li, vi in zip(poly.loop_indices, poly.vertices):
                uv.data[li].uv = uvs[vi]
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        decals.append(obj)
    # 5. sockets and the visor child under a root
    root = K.make_empty("PR_Helmet_Roles")
    for o in [shell, visor, stripe] + decals:
        o.parent = root
    head_socket = K.make_empty("Socket_Head", (hinge.x, hinge.y, hinge.z), root)
    camera_socket = K.make_empty("Socket_Lamp", (0, lo.y - 0.005, hi.z - 0.03), root)
    bpy.context.view_layer.update()
    all_objs = [shell, visor, stripe, head_socket, camera_socket] + decals
    tris = tri_count(all_objs)
    lo2, hi2 = mesh_bounds([shell, visor, stripe] + decals)
    print(f"HELMET tris {tris} size {tuple(round(v, 3) for v in (hi2 - lo2))} min z {lo2.z:.4f}")
    out = GAME / "props/PR_Helmet_Roles/PR_Helmet_Roles.glb"
    export_embedded(all_objs, out, root)
    # 6. per-cadet fit data (gameplay values live in data, not code)
    roles = {}
    for key, (display, colour_name, rgb) in ROLE_COLOURS.items():
        h = HEADS[key]
        scale = max(1.0, (h["width"] + 0.040) / clear_w, (h["depth"] + 0.040) / clear_d, (h["height"] + 0.025) / clear_h)
        scale = round(math.ceil(scale * 100) / 100, 2)
        head_centre_y = (h["head_front"] + h["head_back"]) / 2  # Blender y of the head's centre (front is -y)
        roles[key] = dict(display=display, role_colour=colour_name, stripe_rgb=[round(c, 3) for c in rgb], scale=scale,
                          # the helmet base sits on the neck ring 3 cm below the Neck bone; x/z centre the shell on the head
                          equip_offset_from_head_bone_m=[0.0, round(h["neck_y"] - 0.03 - h["head_y"], 3), round(-(head_centre_y - h["bone_y"]), 3)],
                          head_clearance_m=dict(width=round(clear_w * scale - h["width"], 3), depth=round(clear_d * scale - h["depth"], 3), height=round(clear_h * scale - h["height"], 3)))
    data = dict(task=TASK, source="game/assets/props/PR_Helmet/PR_Helmet.glb (reuse_props: space_helmet, visually approved)",
                stripe_material="RoleStripe", visor_node="Visor", visor_closed_rotation_deg_x=78.0, patches=dict(left_sleeve_side="PatchFlag", right_side="PatchAurora"),
                sockets=dict(Socket_Head="the head centre when equipped (the visor hinge point)", Socket_Lamp="a helmet lamp mount above the brow"),
                interior_clearance_m=dict(width=round(clear_w, 3), depth=round(clear_d, 3), height=round(clear_h, 3)),
                states=dict(stored="helmet on its base, visor open (the GLB rest pose)", equipped="parented to the Head bone with equip_offset_from_head_bone_m and scale",
                            visor="rotate the Visor child about +X by visor_closed_rotation_deg_x times the closed fraction"),
                roles=roles)
    (out.parent / "helmet_roles.json").write_text(json.dumps(data, indent=1), encoding="utf-8")
    manifest("PR_Helmet_Roles", "props/PR_Helmet (Blender: separated Visor child, RoleStripe slot, approved patch decals)", "--longest",
             round(max(hi2 - lo2), 3), tris, 1024, "game/assets/props/PR_Helmet_Roles/PR_Helmet_Roles.glb",
             "cadet helmet: RoleStripe material coloured per cadet from helmet_roles.json, Visor child (closed = +78 deg about X), flag decal on the +X side, Aurora decal on the -X side; fit scale per cadet in the json")
    if RENDER:
        camera, rig = render_rig()
        meshes = [shell, visor, stripe] + decals
        for key, (display, _, rgb) in ROLE_COLOURS.items():
            stripe_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*rgb, 1)
            root.scale = (roles[key]["scale"],) * 3
            bpy.context.view_layer.update()
            # back-left three quarter: the role stripe runs down the back of the shell, the flag sits on the left
            render(camera, meshes, f"PR_Helmet_Roles_{display}", (0.8, 0.9, 0.5), 1.3)
        root.scale = (1, 1, 1)
        stripe_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*ROLE_COLOURS["kai"][2], 1)
        render(camera, meshes, "PR_Helmet_Roles_left", (1.0, 0.05, 0.25), 1.3)
        render(camera, meshes, "PR_Helmet_Roles_right", (-1.0, 0.05, 0.25), 1.3)
        render(camera, meshes, "PR_Helmet_Roles_back", (0.0, 1.0, 0.45), 1.3)
        visor.rotation_euler = (math.radians(data["visor_closed_rotation_deg_x"]), 0, 0)
        bpy.context.view_layer.update()
        render(camera, meshes, "PR_Helmet_Roles_visor_closed", (-0.75, -1.0, 0.5), 1.3)
        visor.rotation_euler = (0, 0, 0)
    print("HELMET_PASS")


# =============================================================================================== PL_Descendants

RACK_W, RACK_D, RACK_TOP, LAMP_Y = 1.30, 0.44, 0.85, 1.55
POT_PITCH = 0.21


CASSETTE = dict(top=(0.170, 0.146), base=(0.150, 0.128), height=0.070, lip=0.008, soil_y=0.054)  # the bloom models' cassette


def soil_set(rng):
    """Seed-starting substrate for the planting-day cassettes: dark brown granules and small clods with a few pale
    flecks of expanded mineral (a soilless mix like the habitat's), 0.15 m tile."""
    size = 512
    grains = K.fractal(rng, size, 40, 200, 0.9)
    clods = K.fractal(rng, size, 6, 30, 1.6)
    flecks = K.fractal(rng, size, 100, 256, 0.3) > 2.7
    tone = np.clip(1.0 + 0.12 * grains + 0.10 * clods, 0.6, 1.4)
    base = np.stack([0.21 * tone, 0.155 * tone, 0.11 * tone], -1)
    base = np.where(flecks[..., None], np.array([0.78, 0.76, 0.70])[None, None, :], base)
    height = 0.0015 * clods + 0.0006 * grains
    rough = np.clip(0.9 + 0.04 * grains, 0, 1)
    return {"Soil": dict(tile=0.15, base=base, normal=K.normal_map(height, 0.15), orm=np.stack([np.ones_like(rough), rough, 0 * rough], -1))}


def planting_cassette(b):
    """A filled cassette on planting day (21 May 2046, EX-CH03-S11): the bloom models' cassette footprint and rim
    height, tapered dark plastic walls with a rim lip, soil levelled 16 mm below the rim, nothing sprouted. Authored in
    the Godot frame about the position node (base at y = 0). (Fix round 2: the first planting-day rack cut the cassette
    out of the Tripo bloom model and kept its low leaves; the Tripo soil has no surface under the leaves, so no cut can
    leave a clean empty cassette.)"""
    (w0, d0), (w1, d1) = CASSETTE["top"], CASSETTE["base"]
    h, lip, soil = CASSETTE["height"], CASSETTE["lip"], CASSETTE["soil_y"]

    def rect(w, d, y):
        return [(-w / 2, y, -d / 2), (w / 2, y, -d / 2), (w / 2, y, d / 2), (-w / 2, y, d / 2)]

    sides = ((0, 0, -1), (1, 0, 0), (0, 0, 1), (-1, 0, 0))
    base, top_o, top_i = rect(w1, d1, 0.0), rect(w0, d0, h), rect(w0 - 2 * lip, d0 - 2 * lip, h)
    floor_i = rect(w0 - 2 * lip - 0.004, d0 - 2 * lip - 0.004, soil)
    for k, n in enumerate(sides):
        a, c = k, (k + 1) % 4
        b.quad([base[a], base[c], top_o[c], top_o[a]], "ZeroDark", outward=n)
        b.quad([top_o[a], top_o[c], top_i[c], top_i[a]], "ZeroDark", outward=(0, 1, 0))
        b.quad([top_i[a], top_i[c], floor_i[c], floor_i[a]], "ZeroDark", outward=(-n[0], 0, -n[2]))
    b.quad(floor_i, "Soil", outward=(0, 1, 0))
    b.quad(base, "ZeroDark", outward=(0, -1, 0))


def rack_table(images):
    table = {k: (K.pbr_material("M_Rack_" + k, images[0][k]), images[0][k]["tile"]) for k in ("ZeroNavy", "ZeroGrey", "ZeroDark", "Steel", "Soil")}
    table["Label"] = (flat("Label", (0.95, 0.95, 0.93), 0.55), 1.0)
    table["Document"] = (flat("Document_Dedication", (0.96, 0.94, 0.88), 0.6), 1.0)
    table["GrowLamp"] = (flat("GrowLamp", (1.0, 0.80, 0.92), 0.5, emission=((1.0, 0.70, 0.90), 6.0)), 1.0)
    table["Rubber"] = (flat("Rubber", (0.06, 0.06, 0.065), 0.9), 1.0)
    table["PaintGrey"] = table["ZeroGrey"]  # the kit's collision builder keys its boxes on PaintGrey
    return table


def build_rack(table, with_dedication=True):
    """Navy aluminium rack: drip tray, legs, lamp bar, 12 label plates as separate objects, a dedication card slot."""
    b = K.Builder(table)
    t = RACK_TOP
    b.box((0, t - 0.015, 0), (RACK_W, 0.03, RACK_D), "ZeroNavy")
    for sx in (-1, 1):  # drip-tray lip
        b.box((sx * (RACK_W / 2 - 0.01), t + 0.012, 0), (0.02, 0.025, RACK_D), "ZeroNavy")
        b.box((0, t + 0.012, sx * (RACK_D / 2 - 0.01)), (RACK_W, 0.025, 0.02), "ZeroNavy")
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.box((sx * (RACK_W / 2 - 0.04), (t - 0.03) / 2, sz * (RACK_D / 2 - 0.04)), (0.04, t - 0.03, 0.04), "ZeroGrey")
            b.cylinder((sx * (RACK_W / 2 - 0.04), 0.0, sz * (RACK_D / 2 - 0.04)), (sx * (RACK_W / 2 - 0.04), 0.012, sz * (RACK_D / 2 - 0.04)), 0.028, "Rubber", segs=12)
    b.box((0, 0.25, 0), (RACK_W - 0.08, 0.02, RACK_D - 0.08), "ZeroGrey")  # lower shelf
    for sx in (-1, 1):  # lamp uprights and bar
        b.box((sx * (RACK_W / 2 - 0.04), (LAMP_Y + t) / 2, RACK_D / 2 - 0.04), (0.04, LAMP_Y - t, 0.04), "ZeroGrey")
    b.box((0, LAMP_Y - 0.03, 0), (RACK_W, 0.06, 0.16), "ZeroNavy", skip=((0, -1, 0),))
    b.box((0, LAMP_Y - 0.061, 0), (RACK_W - 0.06, 0.004, 0.12), "GrowLamp")
    if with_dedication:
        b.box((0, t + 0.09, -RACK_D / 2 - 0.004), (0.14, 0.07, 0.008), "ZeroNavy")
        b.box((0, t + 0.09, -RACK_D / 2 - 0.0095), (0.12, 0.056, 0.003), "Document")
    rack = b.to_object("Rack")
    labels = []
    for k in range(12):
        x, z = pot_x(k), pot_z(k)
        lb = K.Builder(table)
        lb.box((x, t + 0.03, z - 0.095), (0.07, 0.03, 0.004), "Label")
        lb.box((x, t + 0.03, z - 0.09), (0.074, 0.034, 0.006), "ZeroNavy")
        labels.append(lb.to_object("Label_%02d" % (k + 1)))
    cols = [("Rack_Col-convcolonly", (0, t / 2 + 0.02, 0), (RACK_W, t + 0.04, RACK_D)),
            ("Lamp_Col-convcolonly", (0, LAMP_Y - 0.03, 0), (RACK_W, 0.06, 0.16))]
    return rack, labels, cols


def pot_x(k):
    return (k % 6 - 2.5) * POT_PITCH


def pot_z(k):
    return (0.11 if k < 6 else -0.11)


def build_descendants():
    reset_scene()
    rng = np.random.default_rng(SEED)
    tex_dir = STAGE / "textures_rack"
    images = save_sets(paint_set(rng, {"Navy": (0.14, 0.18, 0.26), "Grey": (0.62, 0.64, 0.60), "Dark": (0.17, 0.175, 0.18)}, wear=0.4) |
                       {"Steel": annex_texture_sets(np.random.default_rng(SEED + 1))["Steel"]} | soil_set(np.random.default_rng(SEED + 41)),
                       tex_dir, "Rack", lods=(0,))
    table = rack_table(images)
    alo = [o for o in import_glb(GAME / "plants/PL_Alo_Bloom/PL_Alo_Bloom.glb") if o.type == "MESH"][0]
    tara = [o for o in import_glb(GAME / "plants/PL_Tara_Bloom/PL_Tara_Bloom.glb") if o.type == "MESH"][0]
    alo.name, tara.name = "AloSource", "TaraSource"
    # CH04-S01: seven purple stems, five green, in a fixed pseudo-random layout (seeded, so the data file is stable)
    order = list(range(12))
    rng.shuffle(order)
    green = sorted(order[:5])
    positions = []
    for k in range(12):
        positions.append(dict(position=k + 1, node="Pos_%02d" % (k + 1), stem="green" if k in green else "purple",
                              line="Tara-type descendant" if k in green else "Alo-type descendant", yaw_degrees=int(rng.integers(0, 360)),
                              scale=round(float(rng.uniform(0.9, 1.06)), 3), lean_degrees=round(float(rng.uniform(0, 4)), 1)))
    assert sum(p["stem"] == "purple" for p in positions) == 7 and sum(p["stem"] == "green" for p in positions) == 5
    for variant in ("grown", "planted"):
        rack, labels, cols = build_rack(table, with_dedication=True)
        root = K.make_empty("PL_Descendants" if variant == "grown" else "PL_Descendants_Planted")
        rack.parent = root
        for l in labels:
            l.parent = root
        objs = [rack] + labels
        colliders = K.collision_objects(cols, rack, table)
        for c in colliders:
            c.parent = root
        objs += colliders
        for p in positions:
            k = p["position"] - 1
            pos = K.make_empty(p["node"], (pot_x(k), RACK_TOP, pot_z(k)), root)
            if variant == "grown":
                src = tara if p["stem"] == "green" else alo
                plant = src.copy()
                plant.data = src.data.copy()
                plant.name = "Plant_%02d" % (k + 1)
                bpy.context.scene.collection.objects.link(plant)
                K.set_visible([plant], True)  # a copy inherits the source's hide flags; a hidden copy is not exported
                # the Tripo models are Blender Z-up already: author the plant in Godot frame (y up) under the position
                plant.data.transform(K.GODOT_TO_BLENDER.inverted())
                decimate(plant, 2700)
                plant.rotation_euler = (math.radians(p["lean_degrees"]), math.radians(p["yaw_degrees"]), 0)
                plant.scale = (p["scale"],) * 3
            else:
                cb = K.Builder(table)
                planting_cassette(cb)
                plant = cb.to_object("Cassette_%02d" % (k + 1))
            plant.parent = pos
            objs += [pos, plant]
        bpy.context.view_layer.update()
        K.bake_blender_space(objs)
        bpy.context.view_layer.update()
        lo, hi = mesh_bounds(objs)
        tris = tri_count(objs)
        name = root.name
        print(f"DESCENDANTS {name}: tris {tris} size {tuple(round(v, 3) for v in (hi - lo))} min z {lo.z:.4f}")
        out = GAME / f"plants/{name}/{name}.glb"
        export_embedded(objs, out, root)
        manifest(name, "plants/PL_Alo_Bloom + plants/PL_Tara_Bloom (Blender instancing, decimated) + procedural rack" if variant == "grown"
                 else "procedural rack and planting-day cassettes (the bloom models' cassette footprint, seeded soil texture)", "--height",
                 round(hi.z - lo.z, 3), tris, 2048, f"game/assets/plants/{name}/{name}.glb",
                 "12-position descendant rack, 7 purple-stem and 5 green-stem plants (CH04-S01), Label_01..12 live-UI plates, Document_Dedication card slot"
                 if variant == "grown" else "the same rack on planting day (EX-CH03-S11): twelve filled cassettes, no plants, labels and the dedication card slot")
        if RENDER:
            camera, rig = render_rig()
            K.set_visible([alo, tara], False)  # the instancing sources stay in the scene but are not part of the asset
            render(camera, objs, name + "_34", (0.7, 1.0, 0.5), 1.15)
            render(camera, objs, name + "_front", (0.0, 1.0, 0.25), 1.1)
            if variant == "grown":
                render(camera, objs, name + "_closeup", (0.35, 1.0, 0.45), 0.5)
            for o in rig:
                bpy.data.objects.remove(o)
        for o in objs:
            bpy.data.objects.remove(o)
        bpy.data.objects.remove(root)
    data = dict(task=TASK, scene="EX-CH04-S01 sample: seven purple stems and five green in this authored observation (not a ratio claim)",
                lineage="Alo x Tara (founders); descendants carry the lineage label, the original Alo is never revived",
                counts=dict(purple=7, green=5, positions=12), label_material="Label", dedication_material="Document_Dedication",
                dedication_options=["Light and Star", "For Alo and Tara", "The Next Small Thing"],
                planted_variant="res://assets/plants/PL_Descendants_Planted/PL_Descendants_Planted.glb", positions=positions)
    (GAME / "plants/PL_Descendants/descendants.json").write_text(json.dumps(data, indent=1), encoding="utf-8")
    print("DESCENDANTS_PASS")


# =============================================================================================== PR_PressedPetal

SLEEVE_W, SLEEVE_H, CARD_W, CARD_H = 0.090, 0.065, 0.084, 0.059


def petal_outline(n=36):
    """A pressed Brassica rapa petal: obovate blade about 9.5 mm long and 5.6 mm wide on a 4 mm claw (x along the
    length), widest two thirds of the way up and closing in a rounded apex. (Fix round 2: the first outline stopped at
    a 2.6 mm wide flat cut, so the close-up showed a square tip.) Points are denser towards the apex."""
    claw, length, half = 0.3, 0.0135, 0.0028
    pts = []
    for i in range(n + 1):
        t = 1.0 - (1.0 - i / n) ** 1.6
        if t < claw:
            w = 0.0005 + 0.0008 * t / claw
        else:
            s = (t - claw) / (1.0 - claw)
            if s < 0.62:  # the blade widens from the claw (smoothstep) to its widest point
                k = s / 0.62
                w = 0.0013 + (half - 0.0013) * k * k * (3 - 2 * k)
            else:  # the rounded apex: an elliptical arc that closes on the midline
                w = half * math.sqrt(max(0.0, 1.0 - ((s - 0.62) / 0.38) ** 2))
        pts.append((t * length, w))
    # the apex point (w = 0) is shared; the claw's base keeps both corners so the cut end is square to the midline
    return [(x, y) for x, y in pts] + [(x, -y) for x, y in reversed(pts[:-1])]


def petal_textures(rng, directory):
    size = 256
    x, y = grid(size)
    # veins fan out from the claw (the petal's UVs: u along the 13.5 mm length, v across 7.5 mm, claw at u 0..0.3),
    # gently wavy; they fade towards the rim. (Fix round 2: the first veins were parallel lines that read as wood grain.)
    dx, dy = (x - 0.12) * 13.5, (y - 0.5) * 7.5
    theta, dist = np.arctan2(dy, dx), np.hypot(dx, dy)
    veins = (np.cos(15.0 * theta + 0.25 * np.sin(1.3 * dist)) ** 2) ** 14 * np.clip((x - 0.22) / 0.1, 0, 1) * np.clip(1.2 - dist / 9.0, 0, 1)
    cells = K.fractal(rng, size, 20, 120, 1.2)
    edge = np.clip((np.abs(y - 0.5) - 0.38) / 0.12, 0, 1)
    tone = np.stack([0.90 - 0.10 * edge - 0.05 * veins + 0.02 * cells, 0.80 - 0.18 * edge - 0.08 * veins + 0.02 * cells, 0.42 - 0.15 * edge - 0.08 * veins + 0.02 * cells], -1)
    height = 0.00006 * veins + 0.00002 * cells
    sets = {"Petal": dict(tile=0.0135, base=np.clip(tone, 0, 1), normal=K.normal_map(height, 0.0135), orm=np.stack([np.ones((size, size)), 0.75 + 0.1 * veins, 0 * veins], -1))}
    fibre = K.fractal(rng, size, 10, 120, 1.0)
    card = np.stack([0.93 + 0.012 * fibre, 0.92 + 0.012 * fibre, 0.88 + 0.012 * fibre], -1)
    sets["Card"] = dict(tile=0.09, base=np.clip(card, 0, 1), normal=K.normal_map(0.00002 * fibre, 0.09), orm=np.stack([np.ones((size, size)), 0.8 + 0.03 * fibre, 0 * fibre], -1))
    return save_sets(sets, directory, "Petal", lods=(0,))


def build_petal():
    reset_scene()
    rng = np.random.default_rng(SEED + 2)
    images = petal_textures(rng, STAGE / "textures_petal")
    table = {"Card": (dielectric(K.pbr_material("M_Card", images[0]["Card"])), 0.09), "Petal": (dielectric(K.pbr_material("M_Petal", images[0]["Petal"])), 0.0135),
             "Sleeve": (flat("M_Sleeve", (0.85, 0.90, 0.96), 0.08, alpha=0.16), 1.0), "Label": (flat("Label", (0.97, 0.97, 0.95), 0.55), 1.0),
             "Tape": (flat("M_Tape", (0.95, 0.93, 0.85), 0.7), 1.0), "ZeroNavy": (flat("M_ClipNavy", (0.122, 0.165, 0.267), 0.45), 1.0),
             "Steel": (flat("M_ClipSteel", (0.75, 0.76, 0.78), 0.35, metallic=1.0), 1.0)}
    for variant in ("flat", "mounted"):
        b = K.Builder(table)
        name = "PR_PressedPetal" if variant == "flat" else "PR_PressedPetal_Mounted"
        root = K.make_empty(name)
        parts = []
        # the sleeve assembly, authored lying flat (x along the width, z along the height, +y up), then posed
        sb = K.Builder(table)
        sb.box((0, 0.0009, 0), (CARD_W, 0.0018, CARD_H), "Card")
        sb.box((0, 0.0026, 0.0225), (0.040, 0.0006, 0.010), "Label")  # the date label, live UI
        sb.box((0, 0.0024, 0.0225), (0.044, 0.0005, 0.013), "Tape")
        card = sb.to_object("Card")
        pb = K.Builder(table)
        outline = petal_outline()
        pts = [(x - 0.0068 + 0.002, 0.0021 + 0.0002 * math.sin(math.pi * (x / 0.0135)), y - 0.004) for x, y in outline]
        pb.quad(pts, "Petal", uvs=[(x / 0.0135, 0.5 + y / 0.0075) for x, y in outline], smooth=True, outward=(0, 1, 0))
        pts_under = [(x - 0.0068 + 0.002, 0.0019 + 0.0002 * math.sin(math.pi * (x / 0.0135)), y - 0.004) for x, y in outline]
        pb.quad(pts_under, "Petal", uvs=[(x / 0.0135, 0.5 + y / 0.0075) for x, y in outline], smooth=True, outward=(0, -1, 0))
        petal = pb.to_object("Petal")
        petal.rotation_euler = (0, math.radians(-28), 0)
        vb = K.Builder(table)
        vb.box((0, 0.0032, 0), (SLEEVE_W, 0.0008, SLEEVE_H), "Sleeve")
        vb.box((0, 0.0004, 0), (SLEEVE_W, 0.0008, SLEEVE_H), "Sleeve")
        for sx in (-1, 1):
            vb.box((sx * (SLEEVE_W / 2 - 0.0015), 0.0018, 0), (0.003, 0.0036, SLEEVE_H), "Sleeve")
        vb.box((0, 0.0018, SLEEVE_H / 2 - 0.0015), (SLEEVE_W, 0.0036, 0.003), "Sleeve")
        sleeve = vb.to_object("Sleeve")
        parts = [card, petal, sleeve]
        if variant == "mounted":
            cb = K.Builder(table)
            cb.box((0, 0.004, 0.010), (0.11, 0.008, 0.028), "ZeroNavy")  # clip base plate on the board
            cb.box((0, 0.012, 0.0205), (0.11, 0.008, 0.005), "ZeroNavy")  # the lip the sleeve stands against
            for sx in (-1, 1):
                cb.box((sx * 0.047, 0.016, 0.004), (0.006, 0.030, 0.010), "Steel")  # spring clips
            clip = cb.to_object("Clip")
            for o in (card, petal, sleeve):
                o.location.z += 0.0  # keep local
            holder = K.make_empty("SleeveStand", (0, 0.012, 0.012), root)
            for o in (card, petal, sleeve):
                o.parent = holder
                o.location.z += SLEEVE_H / 2
            holder.rotation_euler = (math.radians(-82), 0, 0)  # stands up, leaning back 8 degrees
            clip.parent = root
            parts = [card, petal, sleeve, holder, clip]
        else:
            for o in parts:
                o.parent = root
        # No collision hull (M3-108): rooms stage props through AssetGeometry.load_glb (GLTFDocument at runtime), which
        # draws a -convcolonly box as a plain grey mesh over the sleeve; a 9-11 cm sleeve needs none (the bench and the
        # board carry the room's obstacles).
        objs = parts
        bpy.context.view_layer.update()
        K.bake_blender_space(objs)
        bpy.context.view_layer.update()
        lo, hi = mesh_bounds(objs)
        tris = tri_count(objs)
        print(f"PETAL {name}: tris {tris} size {tuple(round(v, 4) for v in (hi - lo))} min z {lo.z:.4f}")
        out = GAME / f"props/{name}/{name}.glb"
        export_embedded(objs, out, root)
        manifest(name, "Blender (procedural, small): dried Brassica rapa petal, archival card and sleeve", "--longest", round(max(hi - lo), 3), tris, 256,
                 f"game/assets/props/{name}/{name}.glb",
                 "one archived Alo petal in its dated sleeve (flat on the harvest bench); the date label is the Label slot" if variant == "flat"
                 else "the same sleeve standing in a navy board clip for the lineage board, the shelter remembrance and the final garden close-up")
        if RENDER:
            camera, rig = render_rig()
            render(camera, objs, name + "_34", (0.5, 1.0, 0.9) if variant == "flat" else (0.6, 1.0, 0.45), 1.15)
            render(camera, objs, name + "_closeup", (0.1, 1.0, 1.2) if variant == "flat" else (0.15, 1.0, 0.35), 0.35)
            for o in rig:
                bpy.data.objects.remove(o)
        for o in objs:
            bpy.data.objects.remove(o)
        bpy.data.objects.remove(root)
    print("PETAL_PASS")


# =============================================================================================== EN_ZeroAnnex

ANNEX = GAME / "environment/EN_ZeroAnnex"
DECK_TOP = 0.064  # the floor-hatch module's anti-slip deck faces (4 mm proud of the 0.056 m deck, like the kit tiles)
HATCH_R = 0.45
PORT_R = 0.075


def annex_table(images, lod):
    table = {k: (K.pbr_material("M_Annex_" + k + ("" if lod == 0 else "_LOD1"), images[lod][k]), images[lod][k]["tile"])
             for k in ("Frost", "ZeroGrey", "ZeroNavy", "ZeroOrange", "ZeroDark", "ZeroOlive", "Grating", "Steel")}
    s = "" if lod == 0 else "_LOD1"
    table["Glass"] = (flat("M_Annex_Glass" + s, (0.75, 0.85, 0.95), 0.05, alpha=0.22), 1.0)
    table["Screen"] = (flat("Screen" + s, (0.02, 0.025, 0.03), 0.12), 1.0)
    table["ScreenGauge"] = (flat("Screen_Gauge" + s, (0.90, 0.90, 0.86), 0.4), 1.0)
    table["DocChart"] = (flat("Document_Chart" + s, (0.93, 0.92, 0.86), 0.65), 1.0)
    table["DocRoute"] = (flat("Document_Route" + s, (0.94, 0.93, 0.90), 0.65), 1.0)
    table["DocPhoto"] = (flat("Document_Photo" + s, (0.85, 0.85, 0.84), 0.4), 1.0)
    table["Label"] = (flat("Label" + s, (0.95, 0.95, 0.93), 0.55), 1.0)
    table["LabelTag"] = (flat("Label_ServiceTag" + s, (0.80, 0.80, 0.78), 0.35, metallic=1.0), 1.0)
    table["LabelPlate"] = (flat("Label_Nameplate" + s, (0.85, 0.84, 0.80), 0.35, metallic=1.0), 1.0)
    table["DeadLamp"] = (flat("DeadLamp" + s, (0.55, 0.56, 0.58), 0.5), 1.0)
    table["Rubber"] = (flat("M_Annex_Rubber" + s, (0.06, 0.06, 0.065), 0.9), 1.0)
    table["Canvas"] = (flat("M_Annex_Canvas" + s, (0.36, 0.35, 0.30), 0.85), 1.0)
    table["PaintGrey"] = table["ZeroGrey"]  # the kit's collision builder keys its boxes on PaintGrey
    return table


def hole_in_deck(radius, w, d, cx, cz, segs):
    """Inner and outer loops of a square deck with a round hole, as (x, 0, z) points, counter-clockwise seen from +Y."""
    inner, outer = K.hole_loops(radius, (-w / 2, w / 2, -d / 2, d / 2), cx, cz, segs)
    to3 = lambda loop: [(x, 0.0, y) for x, y in loop]
    return to3(inner), to3(outer)


def piece_floor_hatch(b, lod):
    """2 x 2 m corridor deck module: round N.R. hatch coaming at the centre, utility feed coupling, cover seat."""
    segs = 32 if lod == 0 else 16
    t = 0.056
    inner, outer = hole_in_deck(HATCH_R + 0.02, 2.0, 2.0, 0, 0, segs)
    b.ring_prism(inner, outer, (0, t, 0), "ZeroNavy", (0, -1, 0), centre=(0, 0, 0), smooth_inner=True)
    # anti-slip deck faces around the opening (four quads with the grating/deck look), sitting 4 mm proud like the kit tiles
    for (x0, x1, z0, z1) in ((-0.97, 0.97, 0.56, 0.97), (-0.97, 0.97, -0.97, -0.56), (-0.97, -0.56, -0.56, 0.56), (0.56, 0.97, -0.56, 0.56)):
        b.box(((x0 + x1) / 2, t + 0.004, (z0 + z1) / 2), (x1 - x0, 0.008, z1 - z0), "Grating", skip=((0, -1, 0),))
    circle = lambda rad, y: [(rad * math.cos(a), y, rad * math.sin(a)) for a in (2 * math.pi * i / segs for i in range(segs))]
    # coaming: a 0.12 m ring standing on the deck, the seat for the cover plate
    b.ring_prism(circle(HATCH_R + 0.02, t), circle(HATCH_R + 0.08, t), (0, 0.12, 0), "ZeroGrey", (0, -1, 0), centre=(0, t, 0), smooth_inner=True)
    b.ring_prism(circle(HATCH_R + 0.01, t + 0.12), circle(HATCH_R + 0.09, t + 0.12), (0, 0.012, 0), "ZeroOrange", (0, -1, 0), centre=(0, t, 0))
    if lod == 0:
        for k in range(16):
            a = 2 * math.pi * (k + 0.5) / 16
            p = Vector(((HATCH_R + 0.05) * math.cos(a), t + 0.132, (HATCH_R + 0.05) * math.sin(a)))
            b.cylinder(p, p + Vector((0, 0.006, 0)), 0.009, "Steel", segs=8)
    # utility feed coupling in one corner: a pipe stub with the quarter-turn valve (child FeedValve) and its plate
    fx, fz = -0.75, -0.75
    b.cylinder((fx, t, fz), (fx, t + 0.22, fz), 0.035, "ZeroGrey", segs=12 if lod == 0 else 8)
    b.cylinder((fx, t + 0.22, fz), (fx, t + 0.26, fz), 0.045, "Steel", segs=12 if lod == 0 else 8)
    b.cylinder((fx, t + 0.12, fz), (fx + 0.34, t + 0.12, fz), 0.022, "ZeroGrey", segs=10 if lod == 0 else 6)
    b.box((fx + 0.36, t + 0.12, fz), (0.05, 0.10, 0.10), "ZeroNavy")
    b.box((fx + 0.386, t + 0.12, fz), (0.004, 0.06, 0.06), "Label")  # feed status plate, live UI
    cols = [("FloorHatch_Col-colonly", lambda cb: cb.ring_prism(*hole_in_deck(HATCH_R + 0.02, 2.0, 2.0, 0, 0, 16), (0, t, 0), "ZeroNavy", (0, -1, 0), centre=(0, 0, 0))),
            ("Coaming_Col-colonly", lambda cb: cb.ring_prism(circle(HATCH_R + 0.02, t), circle(HATCH_R + 0.08, t), (0, 0.13, 0), "ZeroGrey", (0, -1, 0), centre=(0, t, 0))),
            ("Feed_Col-convcolonly", (fx + 0.15, t + 0.13, fz), (0.42, 0.26, 0.12))]
    return cols


def hatch_leaf_nr(b, lod):
    """The N.R. hatch leaf about its hinge (the -X edge of the coaming): a disc 0.47 m along +X from the pivot, with the
    camera viewing port, its sliding shutter (child PortShutter), two handles, the dogging wheel and the nameplate."""
    c = Vector((HATCH_R + 0.02, 0.0, 0.0))
    segs = 32 if lod == 0 else 16
    b.cylinder(c + Vector((0, 0.0, 0)), c + Vector((0, 0.05, 0)), HATCH_R + 0.005, "ZeroGrey", segs=segs)
    b.torus(c + Vector((0, 0.05, 0)), (0, 1, 0), HATCH_R - 0.04, 0.012, "ZeroNavy", segs=segs, rings=6)
    # the viewing port: a short collar on the top face with a glass disc, and the shutter plate that slides across it
    pc = c + Vector((0.0, 0.05, -0.17))
    b.cylinder(pc, pc + Vector((0, 0.03, 0)), PORT_R + 0.025, "ZeroNavy", segs=16 if lod == 0 else 8)
    b.cylinder(pc + Vector((0, 0.028, 0)), pc + Vector((0, 0.029, 0)), PORT_R, "Glass", segs=16 if lod == 0 else 8)
    b.box(pc + Vector((0, 0.02, 0)), (0.30, 0.012, 0.04), "ZeroGrey")  # the shutter's guide rail (the plate slides along it)
    # dogging wheel and handles
    wc = c + Vector((0.0, 0.11, 0.12))
    b.torus(wc, (0, 1, 0), 0.12, 0.014, "Steel", segs=segs, rings=8 if lod == 0 else 6)
    b.cylinder(c + Vector((0, 0.05, 0.12)), wc, 0.03, "Steel", segs=12 if lod == 0 else 6)
    for k in range(3):
        a = 2 * math.pi * k / 3
        b.cylinder(wc, wc + Vector((0.12 * math.cos(a), 0, 0.12 * math.sin(a))), 0.009, "Steel", segs=8 if lod == 0 else 6)
    for sx in (-1, 1):
        hb = c + Vector((sx * 0.30, 0.05, 0.0))
        b.cylinder(hb + Vector((0, 0, -0.08)), hb + Vector((0, 0.06, -0.08)), 0.012, "ZeroOrange", segs=10 if lod == 0 else 6)
        b.cylinder(hb + Vector((0, 0, 0.08)), hb + Vector((0, 0.06, 0.08)), 0.012, "ZeroOrange", segs=10 if lod == 0 else 6)
        b.cylinder(hb + Vector((0, 0.06, -0.08)), hb + Vector((0, 0.06, 0.08)), 0.014, "ZeroOrange", segs=10 if lod == 0 else 6)
    # the nameplate that carries "N.R." as live UI (nothing baked): a riveted plate near the rim
    b.box(c + Vector((0.0, 0.053, 0.30)), (0.14, 0.006, 0.05), "LabelPlate")
    # underside: dogs and a second small handle so it closes from below too
    for k in range(6):
        a = 2 * math.pi * (k + 0.5) / 6
        b.box(c + Vector(((HATCH_R - 0.03) * math.cos(a), -0.01, (HATCH_R - 0.03) * math.sin(a))), (0.05, 0.02, 0.05), "Steel")
    return [("HatchLeaf_Col-convcolonly", c + Vector((0, 0.025, 0)), (2 * HATCH_R, 0.05, 2 * HATCH_R))]


def port_shutter(b, lod):
    """The camera-port shutter plate, authored about its own pivot on the leaf; slides +X by 0.17 m to open."""
    b.box((0, 0.006, 0), (0.17, 0.012, 0.17), "ZeroNavy")
    b.cylinder((0.05, 0.012, 0), (0.05, 0.03, 0), 0.012, "ZeroOrange", segs=10 if lod == 0 else 6)
    return []


COVER_W, COVER_H = 1.3, 0.30  # the service cover hood: it stands on the deck and clears the leaf's dogging wheel


def floor_cover(b, lod):
    """The service cover the quake displaced: a 1.3 m square hood standing on the deck over the whole hatch (grating
    top with four latch tabs, 2 cm skirts, two recessed lifting grips), 0.30 m tall so the leaf's dogging wheel,
    handles and port collar stay under it. (Fix round 2: the first cover was a flat 4 cm plate resting on the coaming
    top, so the wheel and handles pierced it in the pre-quake pose that CH02-S12 shows.) Pivot at the skirts' base."""
    w, h, t = COVER_W, COVER_H, 0.02
    b.box((0, h - 0.02, 0), (w, 0.04, w), "ZeroDark")
    b.box((0, h + 0.002, 0), (w - 0.08, 0.004, w - 0.08), "Grating", skip=((0, -1, 0),))
    for sx in (-1, 1):
        b.box((sx * (w - t) / 2, (h - 0.04) / 2, 0), (t, h - 0.04, w), "ZeroDark")
        b.box((0, (h - 0.04) / 2, sx * (w - t) / 2), (w - 2 * t, h - 0.04, t), "ZeroDark")
        for sz in (-1, 1):
            b.box((sx * 0.6, h + 0.008, sz * 0.6), (0.08, 0.02, 0.08), "ZeroOrange")
        # lifting grips on the two +-Z skirts: orange bars in a navy recess, at three quarters of the skirt height
        b.box((0, 0.62 * h, sx * (w / 2 + 0.003)), (0.24, 0.06, 0.006), "ZeroNavy")
        b.cylinder((-0.09, 0.62 * h, sx * (w / 2 + 0.012)), (0.09, 0.62 * h, sx * (w / 2 + 0.012)), 0.011, "ZeroOrange", segs=10 if lod == 0 else 6)
        for gx in (-0.09, 0.09):
            b.cylinder((gx, 0.62 * h, sx * (w / 2 + 0.006)), (gx, 0.62 * h, sx * (w / 2 + 0.016)), 0.009, "ZeroOrange", segs=8 if lod == 0 else 6)
    b.box((0.0, h + 0.008, -0.55), (0.18, 0.02, 0.06), "Label")  # the cover's plan reference plate (live UI)
    return [("Cover_Col-convcolonly", (0, h / 2, 0), (w, h, w))]


def piece_ladder(b, lod):
    """A 3.0 m fixed ladder: two rails 0.5 m apart, rungs every 0.3 m, standoff brackets to the wall behind (z = +0.15)."""
    h = 3.0
    segs = 12 if lod == 0 else 6
    for sx in (-1, 1):
        b.cylinder((sx * 0.25, 0.0, -0.10), (sx * 0.25, h, -0.10), 0.022, "ZeroGrey", segs=segs)
    for k in range(10):
        y = 0.15 + 0.3 * k
        b.cylinder((-0.25, y, -0.10), (0.25, y, -0.10), 0.016, "Steel", segs=segs)
    for y in (0.4, 1.5, 2.6):
        for sx in (-1, 1):
            b.box((sx * 0.25, y, -0.03), (0.04, 0.05, 0.14), "ZeroGrey")
            b.box((sx * 0.25, y, 0.03), (0.10, 0.10, 0.02), "ZeroGrey")
    return [("Ladder_Col-convcolonly", (0, h / 2, -0.09), (0.55, h, 0.08))]


def piece_annex_wall(b, lod):
    """2034 generation wall panel: riveted aluminium, a horizontal stiffener rib, a conduit along the top, frosted."""
    b.box((0, WALL_H / 2, WALL_D / 2 + 0.02), (1.0, WALL_H, WALL_D - 0.04), "ZeroOlive", skip=((0, 0, -1),))
    b.box((0, WALL_H / 2, 0.02), (1.0, WALL_H, 0.04), "Frost")
    b.box((0, 1.30, -0.012), (1.0, 0.06, 0.024), "ZeroGrey")
    b.box((0, 0.10, -0.012), (1.0, 0.20, 0.024), "ZeroDark")
    b.cylinder((-0.5, WALL_H - 0.12, -0.04), (0.5, WALL_H - 0.12, -0.04), 0.022, "ZeroGrey", segs=10 if lod == 0 else 6)
    if lod == 0:
        for x in (-0.46, -0.23, 0.0, 0.23, 0.46):
            for y in (0.35, 0.95, 1.65, 2.25):
                b.cylinder((x, y, 0.0), (x, y, -0.004), 0.008, "Steel", segs=8)
    return [("AnnexWall_Col-convcolonly", (0, WALL_H / 2, WALL_D / 2), (1.0, WALL_H, WALL_D))]


def piece_annex_corner(b, lod):
    b.box((-0.25, WALL_H / 2, WALL_D / 2 + 0.02), (0.5, WALL_H, WALL_D - 0.04), "ZeroOlive", skip=((0, 0, -1),))
    b.box((-0.25, WALL_H / 2, 0.02), (0.5, WALL_H, 0.04), "Frost")
    # leg A's rib and skirting run 24 mm past the corner so they meet leg B's (the first build left a notch there)
    b.box((-0.25 + 0.012, 1.30, -0.012), (0.524, 0.06, 0.024), "ZeroGrey")
    b.box((-0.25 + 0.012, 0.10, -0.012), (0.524, 0.20, 0.024), "ZeroDark")
    b.box((WALL_D / 2, WALL_H / 2, WALL_D / 2 + 0.02), (WALL_D, WALL_H, WALL_D - 0.04), "ZeroOlive")
    b.box((WALL_D / 2 + 0.02, WALL_H / 2, -0.25), (WALL_D - 0.04, WALL_H, 0.5), "ZeroOlive", skip=((-1, 0, 0),))
    b.box((0.02, WALL_H / 2, -0.25), (0.04, WALL_H, 0.5), "Frost")
    b.box((0.012, 1.30, -0.25), (0.024, 0.06, 0.5), "ZeroGrey")
    b.box((0.012, 0.10, -0.25), (0.024, 0.20, 0.5), "ZeroDark")
    return [("AnnexCornerA_Col-convcolonly", (-0.25, WALL_H / 2, WALL_D / 2), (0.5, WALL_H, WALL_D)),
            ("AnnexCornerB_Col-convcolonly", (WALL_D / 2, WALL_H / 2, -0.25 + WALL_D / 2), (WALL_D, WALL_H, 0.5 + WALL_D))]


def piece_annex_floor(b, lod):
    t = 0.06
    b.box((0, (t - 0.004) / 2, 0), (1.0, t - 0.004, 1.0), "ZeroDark")
    b.box((0, t - 0.004, 0), (0.96, 0.008, 0.96), "Grating", skip=((0, -1, 0),))
    return [("AnnexFloor_Col-convcolonly", (0, t / 2, 0), (1.0, t, 1.0))]


CEIL_RIB = 0.016  # the stiffener ribs hang this far below the frosted face of a ceiling panel
LAMP_DROP = 0.03  # the dead fixture hangs this far below the ribs


def ceiling_panel(b, y0):
    """A hanging 2034 ceiling panel whose lowest point (the rib faces) is at y0: five stiffener ribs, the frosted skin
    CEIL_RIB above them, the olive panel body above that. Hanging pieces keep their lowest point at the local origin
    (the gate's floor rule) and are seated by their mount_y, like the kit's ceiling tile and light strip."""
    face = y0 + CEIL_RIB
    b.box((0, face + 0.004 + 0.021, 0), (1.0, 0.042, 1.0), "ZeroOlive", skip=((0, -1, 0),))
    b.box((0, face + 0.002, 0), (1.0, 0.004, 1.0), "Frost")
    for k in range(-2, 3):
        b.box((0, y0 + CEIL_RIB / 2, k * 0.2), (1.0, CEIL_RIB, 0.03), "ZeroGrey")


def piece_annex_ceiling(b, lod):
    """Ribbed 2034 ceiling panel, hanging (rib faces at y = 0, frosted face 16 mm above them; mounted so the frosted
    face meets the 2.6 m wall tops and the ribs run into the walls). Plain:
    the dead light fixtures are the separate EN_ZeroAnnex_CeilingLamp tile, placed every two or three metres. (Fix
    round 2: the first version had a fixture on every 1 m tile, coplanar with the frosted face, so it z-fought into
    rows of black dashes, and its ribs sat inside the panel where nobody could see them.)"""
    ceiling_panel(b, 0.0)
    return [("AnnexCeiling_Col-convcolonly", (0, (CEIL_RIB + 0.046) / 2, 0), (1.0, CEIL_RIB + 0.046, 1.0))]


def piece_annex_ceiling_lamp(b, lod):
    """The ceiling panel with its dead 2034 light fixture: a 0.9 m linear luminaire fixed under the ribs (dark
    housing, frosted diffuser on the DeadLamp slot, rims and grey end caps). Its diffuser is the lowest point (y = 0),
    so it mounts LAMP_DROP lower than the plain panel and the two panels line up. Unlit in EX-CH03-S07
    (headlamp-led detail); a material swap on DeadLamp lights it for a fault or occupied state."""
    ceiling_panel(b, LAMP_DROP)
    b.box((0, 0.004 + (LAMP_DROP - 0.004) / 2, 0), (0.90, LAMP_DROP - 0.004, 0.16), "ZeroDark", skip=((0, -1, 0),))
    b.box((0, 0.002, 0), (0.86, 0.004, 0.12), "DeadLamp")
    for sz in (-1, 1):
        b.box((0, 0.002, sz * 0.07), (0.90, 0.004, 0.02), "ZeroDark")
    for sx in (-1, 1):
        b.box((sx * 0.44, 0.002, 0), (0.02, 0.004, 0.12), "ZeroDark")
        b.box((sx * 0.456, LAMP_DROP / 2, 0), (0.012, LAMP_DROP, 0.17), "ZeroGrey")
    top = LAMP_DROP + CEIL_RIB + 0.046
    return [("AnnexCeilingLamp_Col-convcolonly", (0, top / 2, 0), (1.0, top, 1.0))]


def piece_tray_bench(b, lod):
    """1.2 x 0.6 m frozen-tray bench: two tray sockets on top, a dead grow-lamp bar on uprights, drip lip, frost."""
    w, d, t = 1.2, 0.6, 0.9
    b.box((0, t - 0.015, 0), (w, 0.03, d), "ZeroOlive")
    b.box((0, t + 0.001, 0), (w - 0.04, 0.002, d - 0.04), "Frost", skip=((0, -1, 0),))
    for sx in (-1, 1):
        b.box((sx * (w / 2 - 0.01), t + 0.01, 0), (0.02, 0.02, d), "ZeroGrey")
        b.box((0, t + 0.01, sx * (d / 2 - 0.01)), (w, 0.02, 0.02), "ZeroGrey")
        for sz in (-1, 1):
            b.box((sx * (w / 2 - 0.04), (t - 0.03) / 2, sz * (d / 2 - 0.04)), (0.04, t - 0.03, 0.04), "ZeroGrey")
        b.box((sx * (w / 2 - 0.04), (1.55 + t) / 2, d / 2 - 0.04), (0.04, 1.55 - t, 0.04), "ZeroGrey")
    b.box((0, 0.3, 0), (w - 0.1, 0.02, d - 0.1), "ZeroGrey")
    b.box((0, 1.52, 0), (w, 0.06, 0.14), "ZeroDark", skip=((0, -1, 0),))
    b.box((0, 1.489, 0), (w - 0.06, 0.004, 0.10), "DeadLamp")
    b.box((0.0, t + 0.04, -d / 2 - 0.004), (0.10, 0.05, 0.008), "ZeroNavy")
    b.box((0.0, t + 0.04, -d / 2 - 0.0095), (0.08, 0.036, 0.003), "Label")  # bench label, live UI
    return [("TrayBench_Col-convcolonly", (0, t / 2 + 0.01, 0), (w, t + 0.02, d)), ("TrayLamp_Col-convcolonly", (0, 1.52, 0), (w, 0.06, 0.14))]


def piece_chart_archive(b, lod):
    """1.0 x 0.45 m archive stand: sloped chart board (Document_Chart), the route sheet under a hinged sealed cover
    (child SealedCover over Document_Route), the map pouch (child MapPouch), the loop-valve photograph (Document_Photo)
    and the 2034 service tag (Label_ServiceTag) hanging on a wire."""
    w, d = 1.0, 0.45
    b.box((0, 0.5, 0), (w, 1.0, d), "ZeroOlive")
    b.box((0, 1.0 + 0.0, 0), (w, 0.02, d), "ZeroGrey")
    for sx in (-1, 1):
        b.box((sx * 0.45, 0.55, -d / 2 - 0.004), (0.06, 0.9, 0.008), "ZeroGrey")
    for k in range(3):  # drawer fronts
        b.box((0, 0.2 + 0.26 * k, -d / 2 - 0.006), (0.84, 0.22, 0.012), "ZeroGrey")
        b.cylinder((-0.1, 0.2 + 0.26 * k, -d / 2 - 0.02), (0.1, 0.2 + 0.26 * k, -d / 2 - 0.02), 0.01, "Steel", segs=8 if lod == 0 else 6)
    # the chart board: sloped 25 degrees, the chart surface is a live-UI slot
    board = b  # drawn straight into the archive mesh so its face indices and material keys stay valid
    sl = math.radians(25)
    for key, size, off in (("ZeroNavy", (0.50, 0.012, 0.36), 0.0), ("DocChart", (0.44, 0.004, 0.30), 0.008)):
        cx, cy, cz = -0.20, 1.03 + 0.18 * math.sin(sl) + off * math.cos(sl), 0.03 + off * -math.sin(sl)
        base = len(board.verts)
        hx, hz = size[0] / 2, size[2] / 2
        for (x, z) in ((-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz)):
            y = cy + z * math.sin(sl)
            zz = cz + z * math.cos(sl)
            board.verts.append(Vector((cx + x, y, zz)))
        board.add_face([base, base + 1, base + 2, base + 3], [(0, 0), (1, 0), (1, 1), (0, 1)], key, False, outward=(0, math.cos(sl), -math.sin(sl)))
        if key == "ZeroNavy":  # the board's edges
            for i in range(4):
                j = (i + 1) % 4
                p0, p1 = board.verts[base + i], board.verts[base + j]
                board.cylinder(p0, p1, 0.008, "ZeroGrey", segs=6)
    board.box((-0.20, 1.03 + 0.34 * math.sin(sl) + 0.02, 0.03 + 0.17 * math.cos(sl) + 0.005), (0.08, 0.02, 0.03), "Steel")  # the clip
    # route sheet tray at the right: the sheet lies flat, the sealed cover hinges from its far edge
    b.box((0.27, 1.015, 0.0), (0.36, 0.01, 0.27), "ZeroNavy")
    b.box((0.27, 1.021, 0.0), (0.30, 0.002, 0.21), "DocRoute", skip=((0, -1, 0),))
    # photograph in a small frame on the left side panel
    b.box((-w / 2 - 0.004, 0.72, 0.0), (0.008, 0.11, 0.16), "ZeroDark")
    b.box((-w / 2 - 0.0085, 0.72, 0.0), (0.001, 0.09, 0.14), "DocPhoto")
    # the 2034 service tag on a wire at the front right corner
    b.cylinder((0.47, 0.98, -d / 2 - 0.01), (0.47, 0.86, -d / 2 - 0.02), 0.002, "Steel", segs=6)
    b.box((0.47, 0.83, -d / 2 - 0.02), (0.06, 0.035, 0.002), "LabelTag")
    return [("Archive_Col-convcolonly", (0, 0.52, 0), (w, 1.04, d)), ("ChartBoard_Col-convcolonly", (-0.20, 1.12, 0.03), (0.5, 0.2, 0.36))]


def sealed_cover(b, lod):
    """Clear cover over the route sheet, hinged at its far (+Z) edge: 0.36 x 0.27 m, opens by rotating about -X."""
    b.box((0, 0.004, -0.135), (0.36, 0.008, 0.27), "Glass")
    b.box((0, 0.01, -0.135), (0.36, 0.02, 0.02), "ZeroGrey")
    b.box((0, 0.01, -0.26), (0.36, 0.02, 0.02), "ZeroOrange")
    return []


def map_pouch(b, lod):
    """The sealed map pouch, a 0.25 x 0.18 m canvas flat pouch clipped to the archive front (removable)."""
    b.box((0, 0.09, -0.01), (0.25, 0.18, 0.02), "Canvas")
    b.box((0, 0.17, -0.022), (0.25, 0.03, 0.004), "ZeroOrange")
    b.box((0, 0.10, -0.022), (0.06, 0.03, 0.002), "Label")  # pouch label, live UI
    return [("MapPouch_Col-convcolonly", (0, 0.09, -0.01), (0.25, 0.18, 0.03))]


def piece_support_station(b, lod):
    """Warm-side support cart 1.0 x 0.6 x 1.1 m: sloped console with Screen, the boundary gauge (Screen_Gauge), two
    radio handsets, a bench shelf with the tool-tag hook (Socket_ToolTag) and the hand-light bracket (Socket_HandLight)."""
    w, d = 1.0, 0.6
    segs = 12 if lod == 0 else 6
    b.box((0, 0.5, 0), (w, 0.9, d), "ZeroNavy")
    b.box((0, 0.93, 0), (w, 0.06, d), "ZeroGrey")
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.cylinder((sx * 0.42, 0.0, sz * 0.22), (sx * 0.42, 0.05, sz * 0.22), 0.04, "Rubber", segs=segs)
            b.box((sx * 0.42, 0.07, sz * 0.22), (0.06, 0.04, 0.06), "ZeroGrey")
    # sloped console face on top: a navy wedge with the screen and the gauge
    sl = math.radians(20)
    for key, cx, size, off in (("ZeroNavy", 0.0, (0.90, 0.012, 0.40), 0.0), ("Screen", -0.18, (0.40, 0.004, 0.25), 0.008)):
        base = len(b.verts)
        cy, cz = 0.96 + 0.2 * math.sin(sl) + off * math.cos(sl), 0.05 + off * -math.sin(sl)
        hx, hz = size[0] / 2, size[2] / 2
        for (x, z) in ((-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz)):
            b.verts.append(Vector((cx + x, cy + z * math.sin(sl), cz + z * math.cos(sl))))
        b.add_face([base, base + 1, base + 2, base + 3], [(0, 0), (1, 0), (1, 1), (0, 1)], key, False, outward=(0, math.cos(sl), -math.sin(sl)))
    gc = Vector((0.26, 0.96 + 0.2 * math.sin(sl) + 0.004, 0.05))
    axis = Vector((0, math.cos(sl), -math.sin(sl)))
    b.cylinder(gc, gc + axis * 0.03, 0.09, "Steel", segs=24 if lod == 0 else 12)
    b.cylinder(gc + axis * 0.03, gc + axis * 0.031, 0.075, "ScreenGauge", segs=24 if lod == 0 else 12)
    # two radio handsets in cradles on the right end
    for k in range(2):
        hc = Vector((0.32 + 0.12 * k, 0.96, -0.20))
        b.box(hc, (0.09, 0.03, 0.14), "ZeroGrey")
        b.box(hc + Vector((0, 0.045, 0)), (0.05, 0.06, 0.10), "ZeroDark")
        b.cylinder(hc + Vector((0, 0.06, -0.06)), hc + Vector((0, 0.06, 0.06)), 0.018, "ZeroDark", segs=segs)
    # bench shelf on the left end with the tool-tag hook and the hand-light bracket
    b.box((-0.30, 0.955, -0.18), (0.36, 0.01, 0.18), "ZeroGrey")
    b.cylinder((-0.44, 0.96, -0.24), (-0.44, 1.02, -0.24), 0.005, "Steel", segs=6)
    b.cylinder((-0.44, 1.02, -0.24), (-0.40, 1.02, -0.24), 0.005, "Steel", segs=6)
    b.box((-0.18, 0.985, -0.22), (0.10, 0.05, 0.06), "ZeroOrange")  # hand-light bracket
    b.box((-0.18, 1.0, -0.22), (0.06, 0.03, 0.04), "ZeroDark")
    # pressure-boundary indicator and the local-radio panel on the front face
    b.box((0, 0.6, -d / 2 - 0.004), (0.30, 0.16, 0.008), "ZeroGrey")
    b.box((0, 0.6, -d / 2 - 0.0095), (0.26, 0.12, 0.003), "Label")
    return [("Station_Col-convcolonly", (0, 0.55, 0), (w, 1.1, d))]


ANNEX_PIECES = [
    dict(id="EN_ZeroAnnex_FloorHatch", build=piece_floor_hatch, flag="--longest", size=2.0, footprint=(2.0, 2.0), mount_y=-0.056,
         display="Corridor floor module with the N.R. hatch", notes="2 x 2 m deck module (mount at y=-0.056 so the deck is y=0): round 0.9 m hatch coaming, child HatchLeaf hinged at the -X edge (opens 100 deg about Z), child Cover (the 1.3 m service cover hood that stands on the deck over the hatch; the quake slid it aside), child PortShutter on the leaf over the camera port, utility feed coupling with its status plate",
         children=[("HatchLeaf", (-(HATCH_R + 0.02), 0.056 + 0.132, 0.0), hatch_leaf_nr), ("Cover", (0, DECK_TOP, 0), floor_cover)]),
    dict(id="EN_ZeroAnnex_Ladder", build=piece_ladder, flag="--height", size=3.0, footprint=(0.60, 0.20), mount_y=0.0,  # rails 0.5 m apart, brackets to 0.6
         display="Fixed access ladder", notes="3.0 m ladder from the annex floor to the corridor deck, rails 0.5 m apart, rungs every 0.3 m; stands against a wall at z=0"),
    dict(id="EN_ZeroAnnex_Wall", build=piece_annex_wall, flag="--height", size=WALL_H, footprint=(1.0, WALL_D), mount_y=0.0,
         display="2034 annex wall panel", notes="1 x 2.6 m riveted olive-grey aluminium panel under frost, stiffener rib at 1.3 m, conduit along the top; face on z=0 facing -Z"),
    dict(id="EN_ZeroAnnex_Wall_Corner", build=piece_annex_corner, flag="--height", size=WALL_H, footprint=(0.65, 0.65), mount_y=0.0,
         display="2034 annex inside corner", notes="two 0.5 m legs at 90 deg, pivot at the inside corner; the room lies towards -X and -Z"),
    dict(id="EN_ZeroAnnex_Floor", build=piece_annex_floor, flag="--longest", size=1.0, footprint=(1.0, 1.0), mount_y=-0.06,
         display="Annex grating deck", notes="1 x 1 m steel grating deck 0.06 m thick; mount at y=-0.06"),
    dict(id="EN_ZeroAnnex_Ceiling", build=piece_annex_ceiling, flag="--longest", size=1.0, footprint=(1.0, 1.0), mount_y=round(WALL_H - CEIL_RIB, 4),
         display="Annex ceiling panel", notes="1 x 1 m frosted panel with five stiffener ribs, hanging: the rib faces are the base (y=0), the frosted face 16 mm above; mount at y=2.584 so the frosted face meets the 2.6 m wall tops"),
    dict(id="EN_ZeroAnnex_CeilingLamp", build=piece_annex_ceiling_lamp, flag="--longest", size=1.0, footprint=(1.0, 1.0), mount_y=round(WALL_H - CEIL_RIB - LAMP_DROP, 4),
         display="Annex ceiling panel with dead fixture", notes="the ceiling panel with a dead 0.9 m linear 2034 luminaire under its ribs (DeadLamp diffuser slot, the lowest point); mount at y=2.554 so its panel lines up with the plain panels; place one every two or three metres"),
    dict(id="EN_ZeroAnnex_TrayBench", build=piece_tray_bench, flag="--height", size=1.55, footprint=(1.2, 0.6), mount_y=0.0,
         display="Frozen-tray bench", notes="1.2 x 0.6 m bench, top at 0.9 m with Socket_Tray_A/B for PL_ZeroSeedlingTray, dead grow-lamp bar at 1.5 m (DeadLamp slot), bench label slot"),
    dict(id="EN_ZeroAnnex_ChartArchive", build=piece_chart_archive, flag="--height", size=1.22, footprint=(1.0, 0.45), mount_y=0.0,
         display="Chart archive stand", notes="growth chart board (Document_Chart), route sheet (Document_Route) under child SealedCover (hinged, opens 110 deg about -X), child MapPouch (removable), loop-valve photograph (Document_Photo), 2034 service tag (Label_ServiceTag)",
         children=[("SealedCover", (0.27, 1.025, 0.135), sealed_cover), ("MapPouch", (0.0, 0.52, -0.225 - 0.006), map_pouch)]),
    dict(id="EN_ZeroAnnex_SupportStation", build=piece_support_station, flag="--height", size=1.1, footprint=(1.0, 0.6), mount_y=0.0,
         display="Warm-side support station", notes="1.0 x 0.6 m cart: sloped console with Screen and Screen_Gauge slots, two local-radio handsets, Socket_ToolTag hook, Socket_HandLight bracket, boundary status plate (Label)"),
]
ANNEX_SOCKETS = {
    "EN_ZeroAnnex_FloorHatch": dict(opening_centre=[0, 0.056, 0], opening_diameter=2 * HATCH_R, deck_y=0.056, coaming_top_y=0.056 + 0.132,
                                    parts=dict(HatchLeaf=dict(kind="rotate", axis="z", degrees=100.0), Cover=dict(kind="pose", rest_position=[0, DECK_TOP, 0], position=[1.145, DECK_TOP, -0.285], yaw_degrees=14.0),  # quake pose: the hood slid 1.18 m along the deck and its own +X (so its edge, not a corner, faces the hole), clear of the 0.53 m coaming
                                               PortShutter=dict(kind="slide", axis="x", metres=0.17), FeedValve=dict(kind="rotate", axis="y", degrees=90.0)),
                                    camera_socket="Socket_Camera (on the leaf, above the port)", hatch_axis="+Z rotation lifts the +X side of the leaf"),
    "EN_ZeroAnnex_Ladder": dict(top_y=3.0, rung_pitch_m=0.3, climb_axis="-Z face"),
    "EN_ZeroAnnex_TrayBench": dict(tray_sockets=["Socket_Tray_A", "Socket_Tray_B"], tray_asset="res://assets/plants/PL_ZeroSeedlingTray/PL_ZeroSeedlingTray.glb", bench_top_y=0.9, lamp_material="DeadLamp"),
    "EN_ZeroAnnex_ChartArchive": dict(documents=["Document_Chart", "Document_Route", "Document_Photo"], labels=["Label_ServiceTag"],
                                      parts=dict(SealedCover=dict(kind="rotate", axis="x", degrees=-110.0), MapPouch=dict(kind="pose", rest_position=[0.0, 0.52, -0.231], position=[0.0, 0.52, -0.231], yaw_degrees=0.0))),
    "EN_ZeroAnnex_SupportStation": dict(screens=["Screen", "Screen_Gauge"], sockets=["Socket_ToolTag", "Socket_HandLight"], tool_tag_asset="PR_ToolTag_Gear (M3-99)", hand_light_asset="res://assets/props/PR_HandLight/PR_HandLight.glb"),
    "EN_ZeroAnnex_Ceiling": dict(frosted_face_y=CEIL_RIB),
    "EN_ZeroAnnex_CeilingLamp": dict(lamp_material="DeadLamp", diffuser_y=0.0, frosted_face_y=LAMP_DROP + CEIL_RIB, spacing_m="every 2-3 m (LOC-07 sample: x = -1.5, 1.5, 4.5, 7.5 on rows z = -1.5 and 1.5)"),
}
ANNEX_EMPTIES = {
    "EN_ZeroAnnex_TrayBench": [("Socket_Tray_A", (-0.30, 0.902, 0.0)), ("Socket_Tray_B", (0.30, 0.902, 0.0))],
    "EN_ZeroAnnex_SupportStation": [("Socket_ToolTag", (-0.42, 1.02, -0.24)), ("Socket_HandLight", (-0.18, 1.015, -0.22))],
}
LEAF_EMPTIES = {"HatchLeaf": [("Socket_Camera", (HATCH_R + 0.02, 0.09, -0.17))]}


def build_annex_piece(spec, lod, table):
    root = K.make_empty(spec["id"] + f"_LOD{lod}")
    b = K.Builder(table)
    cols = spec["build"](b, lod)
    body = b.to_object(spec["id"] + f"_Mesh_LOD{lod}")
    body.parent = root
    objs = [body] + (K.collision_objects(cols, body, table) if lod == 0 else [])
    for name, pivot, fn in spec.get("children", []):
        taken = bpy.data.objects.get(name)
        if taken is not None:
            taken.name = name + "_prev"
        child = K.make_empty(name, pivot, root)
        cb = K.Builder(table)
        ccols = fn(cb, lod)
        cmesh = cb.to_object(name + f"_Mesh_LOD{lod}")
        cmesh.parent = child
        objs += [child, cmesh] + (K.collision_objects(ccols, cmesh, table) if lod == 0 else [])
        if name == "HatchLeaf":
            for sub, at, sfn in (("PortShutter", (HATCH_R + 0.02, 0.05 + 0.032, -0.17), port_shutter),):
                taken = bpy.data.objects.get(sub)
                if taken is not None:
                    taken.name = sub + "_prev"
                se = K.make_empty(sub, at, child)
                sb = K.Builder(table)
                sfn(sb, lod)
                sm = sb.to_object(sub + f"_Mesh_LOD{lod}")
                sm.parent = se
                objs += [se, sm]
            for ename, at in LEAF_EMPTIES.get(name, []):
                taken = bpy.data.objects.get(ename)
                if taken is not None:
                    taken.name = ename + "_prev"
                objs.append(K.make_empty(ename, at, child))
    if spec["id"] == "EN_ZeroAnnex_FloorHatch":  # the feed valve: a quarter-turn handle on the coupling, child FeedValve
        taken = bpy.data.objects.get("FeedValve")
        if taken is not None:
            taken.name = "FeedValve_prev"
        fe = K.make_empty("FeedValve", (-0.75, 0.056 + 0.26, -0.75), root)
        fb = K.Builder(table)
        fb.box((0.0, 0.006, 0.0), (0.16, 0.012, 0.03), "ZeroOrange")
        fb.cylinder((0, 0, 0), (0, 0.02, 0), 0.02, "Steel", segs=10 if lod == 0 else 6)
        fm = fb.to_object(f"FeedValve_Mesh_LOD{lod}")
        fm.parent = fe
        objs += [fe, fm]
    for ename, at in ANNEX_EMPTIES.get(spec["id"], []):
        taken = bpy.data.objects.get(ename)
        if taken is not None:
            taken.name = ename + "_prev"
        objs.append(K.make_empty(ename, at, root))
    return root, objs


def build_annex():
    reset_scene()
    ANNEX.mkdir(parents=True, exist_ok=True)
    for old in list(ANNEX.glob("*.glb")) + list((ANNEX / "textures").glob("*.png")) + list((ANNEX / "textures/lod1").glob("*.png")):
        old.unlink()
    rng = np.random.default_rng(SEED)
    images = save_sets(annex_texture_sets(rng), ANNEX / "textures", "Annex")
    tables = {lod: annex_table(images, lod) for lod in (0, 1)}
    catalogue, built = [], {}
    for spec in ANNEX_PIECES:
        entry = dict(id=spec["id"], display=spec["display"], notes=spec["notes"], footprint_m=list(spec["footprint"]), mount_y=spec["mount_y"],
                     lods=[], triangles=[], lod_distance_m=K.LOD_DISTANCE_M, collision=True)
        for lod in (0, 1):
            root, objs = build_annex_piece(spec, lod, tables[lod])
            bpy.context.view_layer.update()
            lo, hi = mesh_bounds(objs)
            tris = tri_count(objs)
            assert abs(lo.y) < 0.005, f"{spec['id']} LOD{lod} lowest point {lo.y:.4f} is not on the floor"
            measured = (hi.y - lo.y) if spec["flag"] == "--height" else max(hi - lo)
            assert abs(measured - spec["size"]) <= 0.02 * spec["size"], f"{spec['id']} LOD{lod} measures {measured:.3f}, spec {spec['size']}"
            assert tris <= 8000, f"{spec['id']} LOD{lod} has {tris} triangles"
            for o in objs:  # a vertex no face uses is dropped by the exporter and would fake the measured size
                if o.type == "MESH":
                    used = {v for poly in o.data.polygons for v in poly.vertices}
                    assert len(used) == len(o.data.vertices), f"{o.name} has {len(o.data.vertices) - len(used)} loose vertices"
            name = spec["id"] + f"_LOD{lod}"
            path = ANNEX / (name + ".glb")
            K.bake_blender_space(objs)
            bpy.context.view_layer.update()
            K.export_glb(root, objs, path)
            manifest(name, "tools/build_ch03_assets.py (seed 20261103): procedural 2034 annex hardware in the habitat kit conventions", spec["flag"], spec["size"], tris,
                     1024 if lod == 0 else 512, path.relative_to(ROOT).as_posix(), f"{spec['display']}; " + ("game LOD with collision" if lod == 0 else "Compatibility LOD, no collision"))
            entry["lods"].append("res://assets/environment/EN_ZeroAnnex/" + name + ".glb")
            entry["triangles"].append(tris)
            if lod == 0:
                entry["size_m"] = [round(v, 3) for v in (hi - lo)]
                entry["bounds_min_m"] = [round(v, 3) for v in lo]
            built[(spec["id"], lod)] = (root, objs)
            print(f"ANNEX {name}: {tris} tris, size {[round(v, 3) for v in (hi - lo)]}, {path.stat().st_size // 1024} KB")
        if spec["id"] in ANNEX_SOCKETS:
            entry["sockets"] = ANNEX_SOCKETS[spec["id"]]
        catalogue.append(entry)
    K.OUT = ANNEX  # the kit's import-file writers work on this folder now
    K.write_texture_imports()
    K.write_scene_imports()
    (ANNEX / "annex.json").write_text(json.dumps(dict(
        task=TASK, seed=SEED, extends="res://assets/environment/kit/kit.json (same conventions; habitat_kit.gd reads this file as an extension catalogue)",
        canon="LOC-07 Expedition Zero service annex: a 10 x 6 m lower annex reached through the N.R. floor hatch from the service corridor (09_WORLD_AND_LEVEL_DESIGN.md); EX-CH03-S06..S08 and doc 24 clues 10-13",
        conventions=dict(units="metres", up="+Y", front="-Z (Godot forward); wall faces lie on z=0 and face -Z, bodies extend to +z", pivot="base centre; moving parts on their own child pivots",
                         grid_m=1.0, wall_height_m=WALL_H, wall_depth_m=WALL_D, annex_floor_below_corridor_m=3.0, lod_distance_m=K.LOD_DISTANCE_M,
                         live_ui="material slots named Screen*, Document* and Label* carry no texture text; the game draws N.R., the chart's last line, the route sheet, the 2034 tag and the feed status"),
        pieces=catalogue), indent=1), encoding="utf-8")
    if RENDER:
        camera, rig = render_rig()
        K.set_visible(bpy.context.scene.objects, False)
        K.set_visible(rig, True)
        for spec in ANNEX_PIECES:
            for lod in (0, 1):
                root, objs = built[(spec["id"], lod)]
                hanging = spec["id"] in ("EN_ZeroAnnex_Ceiling", "EN_ZeroAnnex_CeilingLamp")
                if hanging:
                    root.rotation_euler = (0, math.radians(180), 0)
                    root.location.z = CEIL_RIB + 0.046 + (LAMP_DROP if spec["id"].endswith("Lamp") else 0.0)
                K.set_visible([root] + objs, True)
                K.set_visible([o for o in objs if o.name.endswith(COL)], False)
                direction = (-0.7, 1.0, 0.55) if spec["id"] == "EN_ZeroAnnex_Wall_Corner" else (0.7, 1.0, 0.55)
                render(camera, objs, f"{spec['id']}_LOD{lod}", direction)
                if lod == 0 and spec["id"] == "EN_ZeroAnnex_FloorHatch":
                    leaf = next(o for o in objs if o.type == "EMPTY" and o.name.startswith("HatchLeaf"))
                    cover = next(o for o in objs if o.type == "EMPTY" and o.name.startswith("Cover"))
                    sockets = ANNEX_SOCKETS[spec["id"]]["parts"]
                    cp = sockets["Cover"]["position"]
                    cover.location = K.GODOT_TO_BLENDER @ Vector(cp)
                    cover.rotation_euler = (0, 0, math.radians(sockets["Cover"]["yaw_degrees"]))
                    render(camera, objs, f"{spec['id']}_LOD0_displaced", direction)
                    leaf.rotation_euler = (0, math.radians(-100), 0)  # Godot +Z = Blender -Y
                    render(camera, objs, f"{spec['id']}_LOD0_open", direction)
                    leaf.rotation_euler = (0, 0, 0)
                    cover.location = K.GODOT_TO_BLENDER @ Vector(sockets["Cover"]["rest_position"])
                    cover.rotation_euler = (0, 0, 0)
                if lod == 0 and spec["id"] == "EN_ZeroAnnex_ChartArchive":
                    cov = next(o for o in objs if o.type == "EMPTY" and o.name.startswith("SealedCover"))
                    cov.rotation_euler = (math.radians(-110), 0, 0)
                    render(camera, objs, f"{spec['id']}_LOD0_open", (-0.7, 1.0, 0.55))
                    cov.rotation_euler = (0, 0, 0)
                if hanging:
                    root.rotation_euler = (0, 0, 0)
                    root.location.z = 0
                K.set_visible([root] + objs, False)
    print(f"ANNEX_PASS: {len(ANNEX_PIECES)} pieces")


# =============================================================================================== main

def main():
    STAGE.mkdir(parents=True, exist_ok=True)
    steps = dict(helmet=build_helmet, descendants=build_descendants, petal=build_petal, annex=build_annex)
    for key, fn in steps.items():
        if WHAT in (key, "all"):
            fn()
    write_manifest()
    print("CH03_BUILD_PASS", WHAT)


if __name__ == "__main__":
    main()
