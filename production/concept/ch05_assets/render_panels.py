"""M3-5A review panels: studio renders of the built GLBs (Blender 5.2 Cycles, light settings), plus stats.

Usage:
  blender -b --factory-startup --threads 4 --python render_panels.py -- <out_dir> <glb> [<glb> ...] [--shapes] [--views 34,front,side]

For every GLB: imports it, prints STATS (meshes, triangles, materials, images and their sizes, shape keys),
and renders <out_dir>/<Name>_<view>.png on the neutral studio sweep used by the M3-99 sheets.
With --shapes, every blend shape is also rendered at value 1.0 from the 3/4 view (<Name>_shape_<Key>.png).
Set M35A_SAMPLES to lower the Cycles sample count (default 64).
"""
import bpy, math, os, sys
from mathutils import Vector

GREY = (0.62, 0.62, 0.62, 1.0)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = int(os.environ.get("M35A_SAMPLES", "64"))
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = 900
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.58, 0.58, 0.59, 1)
    bg.inputs[1].default_value = 0.65
    sc.world = world
    return sc


def material(name, color, rough=0.5):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = color
    b.inputs["Roughness"].default_value = rough
    return m


def bbox(objs):
    pts = []
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        if o.type != "MESH":
            continue
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        pts += [oe.matrix_world @ v.co for v in me.vertices]
        oe.to_mesh_clear()
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx


def studio(objs, elev, azim, margin=1.25):
    mn, mx = bbox(objs)
    c = (mn + mx) / 2
    size = max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z)
    bpy.ops.mesh.primitive_plane_add(size=size * 40, location=(c.x, c.y, mn.z))
    floor = bpy.context.object
    floor.name = "Floor"   # the per-view clean-up removes it by this name (stacked coplanar floors shadow each other black)
    floor.data.materials.append(material("Floor", GREY, rough=0.8))
    for name, rot, energy in (("Key", (math.radians(48), 0, math.radians(-38)), 3.2),
                              ("Fill", (math.radians(65), 0, math.radians(130)), 1.0)):
        bpy.ops.object.light_add(type="SUN", rotation=rot)
        bpy.context.object.data.energy = energy
        bpy.context.object.data.angle = math.radians(8)
        bpy.context.object.name = name
    bpy.ops.object.camera_add()
    cam = bpy.context.object
    cam.data.type = "ORTHO"
    e, a = math.radians(elev), math.radians(azim)
    d = size * 6
    cam.location = c + Vector((math.sin(a) * math.cos(e) * d, -math.cos(a) * math.cos(e) * d, math.sin(e) * d))
    cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.ortho_scale = size * margin
    cam.data.clip_end = d * 4
    bpy.context.scene.camera = cam
    return cam, floor


def render(path):
    sc = bpy.context.scene
    sc.render.filepath = path
    sc.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    print("WROTE", path)


VIEWS = {"34": (14.0, -32.0), "front": (6.0, 0.0), "side": (6.0, -90.0), "back": (6.0, 180.0), "top34": (48.0, -32.0)}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = argv[0]
    shapes = "--shapes" in argv
    views = ["34", "front", "side"]
    if "--views" in argv:
        views = argv[argv.index("--views") + 1].split(",")
    glbs = [a for a in argv[1:] if a.endswith(".glb")]
    os.makedirs(out, exist_ok=True)
    for glb in glbs:
        name = os.path.splitext(os.path.basename(glb))[0]
        reset()
        bpy.ops.import_scene.gltf(filepath=glb)
        # the glTF importer makes the first animation the active action; measure and show the rest pose instead
        for arm in [o for o in bpy.data.objects if o.type == "ARMATURE"]:
            if arm.animation_data:
                arm.animation_data.action = None
            for pb in arm.pose.bones:
                pb.location = (0, 0, 0)
                pb.rotation_quaternion = (1, 0, 0, 0)
                pb.rotation_euler = (0, 0, 0)
                pb.scale = (1, 1, 1)
        bpy.context.view_layer.update()
        # a rig's bone display shapes (e.g. a 2 m Icosphere) are not geometry: hide them and keep them out of framing
        shapes = {pb.custom_shape for o in bpy.data.objects if o.type == "ARMATURE" for pb in o.pose.bones}
        for o in shapes - {None}:
            o.hide_render = True
        meshes = [o for o in bpy.data.objects if o.type == "MESH" and o not in shapes]
        for o in meshes:
            if o.data.shape_keys:
                for kb in o.data.shape_keys.key_blocks:
                    kb.value = 0.0
        tris = sum(len(p.vertices) - 2 for o in meshes for p in o.data.polygons)
        keys = sorted({k.name for o in meshes if o.data.shape_keys for k in o.data.shape_keys.key_blocks if k.name != "Basis"})
        imgs = [(i.name, tuple(i.size)) for i in bpy.data.images]
        mats = sorted({m.name for o in meshes for m in o.data.materials if m})
        mn, mx = bbox(meshes)
        print(f"STATS {name} meshes={[o.name for o in meshes]} tris={tris} size=({mx.x-mn.x:.4f},{mx.y-mn.y:.4f},{mx.z-mn.z:.4f}) "
              f"min_z={mn.z:.4f} materials={mats} images={imgs} shapes={keys}")
        for v in views:
            for o in bpy.data.objects:
                if o.type in ("CAMERA", "LIGHT") or o.name == "Floor":
                    bpy.data.objects.remove(o)
            studio(meshes, *VIEWS[v])
            render(os.path.join(out, f"{name}_{v}.png"))
        if shapes:
            for key in keys:
                for o in meshes:
                    if o.data.shape_keys and key in o.data.shape_keys.key_blocks:
                        o.data.shape_keys.key_blocks[key].value = 1.0
                for o in bpy.data.objects:
                    if o.type in ("CAMERA", "LIGHT") or o.name == "Floor":
                        bpy.data.objects.remove(o)
                studio(meshes, *VIEWS["34"])
                render(os.path.join(out, f"{name}_shape_{key}.png"))
                for o in meshes:
                    if o.data.shape_keys and key in o.data.shape_keys.key_blocks:
                        o.data.shape_keys.key_blocks[key].value = 0.0


if __name__ == "__main__":
    main()
