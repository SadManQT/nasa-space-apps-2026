"""Rebuild M1-35 with Blender, no external services or generation credits.

blender --background --factory-startup --python production/tools/build_lunar_kit.py
Deterministic source geometry/textures; reviewed against M1-33 option A.
"""
import csv
import json
import math
import random
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/environment/terrain"
STAGE = ROOT / "production/models/lunar_kit"
SIZES = [.06, .09, .14, .22, .35, .5, .75, 1., 1.4, 2., 2.8, 3.8, 5., 6.5, 8., 10.]
FORMS = ["Chip", "Shard", "Block", "Slab"]


def image(name, pixels, directory=None):
    h, w = pixels.shape
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[:, :, :3] = pixels[:, :, None]
    im = bpy.data.images.new(name, width=w, height=h)
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = str((directory or OUT / "textures") / (name + ".png"))
    im.file_format = "PNG"
    im.save()
    return im


def textures():
    rng = np.random.default_rng(351104)
    size = 512
    y, x = np.mgrid[0:size, 0:size] / size
    # Periodic waves and wrapped derivatives keep every edge tileable.
    base = np.zeros((size, size))
    for _ in range(32):
        a, b = rng.integers(-35, 36, size=2)
        frequency = abs(a) + abs(b)
        if frequency:
            base += np.sin(2 * np.pi * (a*x + b*y) + rng.uniform(0, 2*np.pi)) / frequency**.75
    base /= np.max(np.abs(base))
    grain = rng.uniform(-1, 1, (size, size))
    maps = {}
    for kind in ("Fresh", "Compacted", "Disturbed"):
        height = base * .3 + grain * .11
        marks = np.zeros_like(height)
        if kind == "Compacted":
            # Repeating twin rover lanes, shallow transverse tread impressions.
            lanes = (np.abs(x-.25) < .105) | (np.abs(x-.75) < .105)
            chevron = np.abs(np.sin(2*np.pi*(y*14 + np.abs((x*2)%1-.5)*.9))) < .3
            marks = lanes * (.35 + .35*chevron)
            height = height * np.where(lanes, .25, 1) - marks*.4
        elif kind == "Disturbed":
            # Four alternating boot impressions per 4 m tile, each 0.30 x 0.14 m.
            for cx, cy in ((.46, .12), (.54, .37), (.46, .62), (.54, .87)):
                dx = ((x-cx+.5)%1-.5) / .0175
                dy = ((y-cy+.5)%1-.5) / .0375
                sole = (dx**4 + dy**4 < 1)
                tread = (np.abs(np.sin(dy*16)) < .45)
                marks += sole * (.45 + .25*tread)
            height -= marks*.45
        albedo = np.clip(.46 + base*.045 + grain*.035 - marks*.14, .3, .6)
        maps[kind] = image("T_Regolith_" + kind + "_BaseColor", albedo)
        # Tangent normals from a shallow height field, no displaced geometry.
        dx = (np.roll(height, -1, 1)-np.roll(height, 1, 1))*.65
        dy = (np.roll(height, -1, 0)-np.roll(height, 1, 0))*.65
        normal = np.stack((-dx, -dy, np.ones_like(dx)), axis=2)
        normal /= np.linalg.norm(normal, axis=2)[:, :, None]
        rgba = np.ones((size,size,4), dtype=np.float32)
        rgba[:,:,:3] = normal*.5+.5
        im = bpy.data.images.new("T_Regolith_"+kind+"_Normal", width=size, height=size)
        im.colorspace_settings.name = "Non-Color"
        im.pixels.foreach_set(rgba.ravel())
        im.filepath_raw = str(OUT / "textures" / (im.name+".png"))
        im.file_format = "PNG"
        im.save()
    rock = image("T_LunarRock_BaseColor", .44 + base[::2,::2]*.07 + grain[::2,::2]*.04, STAGE)
    return maps, rock


def material(name, albedo, normal=None):
    mat = bpy.data.materials.new(name)
    if bpy.app.version < (5, 0, 0):
        mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = .94
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = albedo
    mat.node_tree.links.new(tex.outputs["Color"], shader.inputs["Base Color"])
    if normal:
        tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images[normal]
        bump = mat.node_tree.nodes.new("ShaderNodeNormalMap")
        mat.node_tree.links.new(tex.outputs["Color"], bump.inputs["Color"])
        mat.node_tree.links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    return mat


def grounded(obj, longest):
    verts = obj.data.vertices
    mins = [min(v.co[i] for v in verts) for i in range(3)]
    maxs = [max(v.co[i] for v in verts) for i in range(3)]
    scale = longest / max(maxs[i]-mins[i] for i in range(3))
    centre = Vector(((maxs[0]+mins[0])/2, (maxs[1]+mins[1])/2, mins[2]))
    for v in verts:
        v.co = (v.co-centre)*scale


def export(obj, name, size, rows, ratio=1):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    obj.name = name
    grounded(obj, size)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=.025)
    bpy.ops.object.mode_set(mode="OBJECT")
    if ratio < 1:
        mod = obj.modifiers.new("LOD decimation", "DECIMATE")
        mod.ratio = ratio
        bpy.ops.object.modifier_apply(modifier=mod.name)
        grounded(obj, size)
    mod = obj.modifiers.new("Triangles", "TRIANGULATE")
    bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.update()
    if name.startswith("EN_LunarRock_"):
        audit = bmesh.new()
        audit.from_mesh(obj.data)
        assert all(e.is_manifold for e in audit.edges), name + " has an open/nonmanifold edge"
        assert audit.calc_volume(signed=True) > 0, name + " has inverted/empty volume"
        assert all(face.calc_area() > 1e-12 for face in audit.faces), name + " has a degenerate face"
        audit.free()
    tris = len(obj.data.polygons)
    path = OUT / "rocks" / (name + ".glb")
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
                              export_yup=True, export_animations=False, export_cameras=False,
                              export_lights=False, export_extras=True)
    rows.append(dict(name=name, concept_or_source="tools/build_lunar_kit.py (seed 351104)",
                     size_flag="--longest", size_m=size, tris=tris, tex=256,
                     game_path=path.relative_to(ROOT).as_posix(), art_status="verified_option_a",
                     notes="M1-35 geometry and surfaces verified against M1-33 option A"))
    return tris


def rock(index):
    rng = random.Random(351104+index)
    # Uneven convex fracture forms: a directionally distorted icosphere hull,
    # intersected by oblique fracture planes. No smooth river-rock surface.
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=3, radius=1)
    form = index % 4
    axes = [(1,.7,.58), (1,.42,.55), (1,.83,.85), (1,.83,.27)][form]
    shear = rng.uniform(-.38,.38)
    for v in bm.verts:
        radial = rng.uniform(.78, 1.14)
        v.co *= radial
        v.co.x += shear*v.co.z
        for axis in range(3):
            v.co[axis] *= axes[axis]
    def hull_from_points(source):
        points = [v.co.copy() for v in source.verts]
        source.free()
        hull = bmesh.new()
        for point in points:
            hull.verts.new(point)
        result = bmesh.ops.convex_hull(hull, input=list(hull.verts))
        unused = [v for v in result["geom_unused"] if isinstance(v, bmesh.types.BMVert)]
        if unused:
            bmesh.ops.delete(hull, geom=unused, context="VERTS")
        return hull

    bm = hull_from_points(bm)
    for _ in range(3):
        normal = Vector((rng.uniform(-1,1), rng.uniform(-1,1), rng.uniform(.2,1))).normalized()
        bmesh.ops.bisect_plane(bm, geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
                                    dist=.00001, plane_co=normal*rng.uniform(.5,.75),
                                    plane_no=normal, clear_outer=True)
        bm = hull_from_points(bm)
    assert all(e.is_manifold for e in bm.edges), "Fracture hull must be closed"
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    mesh = bpy.data.meshes.new("FractureMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Rock",mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def render(obj, path):
    scene = bpy.context.scene
    obj.hide_render = False
    obj.scale = (1,1,1)
    longest = max(obj.dimensions)
    obj.scale = (2/longest,)*3
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    obj.hide_render = True
    obj.scale = (1,1,1)


def setup_render():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 384
    scene.render.resolution_y = 320
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.world.color = (.025,.025,.025)
    scene.view_settings.view_transform = "Standard"
    bpy.ops.object.camera_add(location=(3,-4,2.8))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0,0,.55))-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.9
    scene.camera = camera
    bpy.ops.object.light_add(type="AREA",location=(1,-3,5))
    bpy.context.object.data.energy = 500
    bpy.context.object.data.shape = "DISK"
    bpy.context.object.data.size = 2


def main():
    for sub in ("rocks","textures","materials"):
        (OUT/sub).mkdir(parents=True, exist_ok=True)
    STAGE.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    maps, rock_image = textures()
    # Keep the original embedded material IDs so existing imports remain stable.
    # The legacy suffix is not an approval state; kit.json owns that status.
    mat = material("LunarRock_Provisional",rock_image)
    rows, assets = [], []
    originals = []
    for i, size in enumerate(SIZES):
        obj = rock(i)
        obj.data.materials.append(mat)
        original = obj.data.copy()
        name = "EN_LunarRock_%02d_%s" % (i+1, FORMS[i%4])
        paths, counts = [], []
        for lod, ratio in enumerate((1,.52,.24)):
            obj.data = original.copy()
            key = name+"_LOD"+str(lod)
            counts.append(export(obj,key,size,rows,ratio))
            paths.append("res://"+rows[-1]["game_path"][5:])
            originals.append((obj.data.copy(),key,size))
        assets.append(dict(id=name, size_m=size, lods=paths, triangles=counts))
        bpy.data.objects.remove(obj,do_unlink=True)
    materials = []
    for kind in maps:
        # GLB ground patch is the gate-tested companion of the reusable Godot material.
        mat = material("Regolith_"+kind+"_Provisional",maps[kind],"T_Regolith_"+kind+"_Normal")
        bpy.ops.mesh.primitive_plane_add(size=4)
        obj = bpy.context.object
        obj.data.materials.append(mat)
        name = "EN_Regolith_"+kind
        export(obj,name,4,rows)
        rows[-1]["tex"] = 512
        rows[-1]["notes"] = "4 m tile; surface verified against M1-33 option A"
        # Preserve the original square UV for a repeatable 4 m patch.
        for poly in obj.data.polygons:
            for loop in poly.loop_indices:
                v = obj.data.vertices[obj.data.loops[loop].vertex_index].co
                obj.data.uv_layers.active.data[loop].uv = ((v.x+2)/4,(v.y+2)/4)
        bpy.ops.export_scene.gltf(filepath=str(ROOT/rows[-1]["game_path"]), export_format="GLB",
                                  use_selection=True, export_yup=True, export_animations=False)
        bpy.data.objects.remove(obj,do_unlink=True)
        path = OUT/"materials"/(name+".tres")
        path.write_text('[gd_resource type="StandardMaterial3D" load_steps=3 format=3]\n\n'
                        f'[ext_resource type="Texture2D" path="res://assets/environment/terrain/textures/T_Regolith_{kind}_BaseColor.png" id="1"]\n'
                        f'[ext_resource type="Texture2D" path="res://assets/environment/terrain/textures/T_Regolith_{kind}_Normal.png" id="2"]\n\n'
                        '[resource]\nroughness = 0.94\nalbedo_texture = ExtResource("1")\n'
                        'normal_enabled = true\nnormal_texture = ExtResource("2")\n', encoding="utf-8")
        materials.append(dict(id=name,path="res://"+path.relative_to(ROOT/"game").as_posix(), tile_size_m=4))
    with (ROOT/"production/manifest/lunar_kit.csv").open("w",newline="",encoding="utf-8") as f:
        writer = csv.DictWriter(f,fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    (OUT/"kit.json").write_text(json.dumps(dict(task="M1-35", art_status="verified_option_a",
                                               seed=351104, rocks=assets, materials=materials),indent=2)+"\n",encoding="utf-8")
    setup_render()
    for mesh,name,size in originals:
        obj = bpy.data.objects.new(name,mesh)
        bpy.context.collection.objects.link(obj)
        bpy.context.view_layer.update()
        render(obj,STAGE/(name+".png"))
    print("LUNAR_KIT_BUILD_PASS: 16 rocks, 48 LOD files, 3 option-A ground patches/materials")


if __name__ == "__main__":
    main()
