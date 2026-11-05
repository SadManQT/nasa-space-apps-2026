"""Shared Blender helpers for the M3-99 narrative-prop approval sheets.

Run only inside Blender (bpy). Studio look matches the existing concept
renders in production/concept/plants/: neutral grey sweep, soft key light.
"""
import bpy, math
from mathutils import Vector

GREY = (0.62, 0.62, 0.62, 1.0)


def reset():
    """Empty the file and set up a Cycles CPU render with faithful colours."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = int(__import__("os").environ.get("M399_SAMPLES", "96"))
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = 900
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.58, 0.58, 0.59, 1)
    bg.inputs[1].default_value = 0.65
    sc.world = world
    return sc


def material(name, color, rough=0.5, metal=0.0, sss=0.0):
    """Return a simple Principled material."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = color
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if sss:
        b.inputs["Subsurface Weight"].default_value = sss
        b.inputs["Subsurface Radius"].default_value = (0.4, 1.0, 0.25)
        b.inputs["Subsurface Scale"].default_value = 0.002
    return m


def bbox(objs):
    """World-space min/max over the evaluated geometry of mesh/curve/text objects."""
    pts = []
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        if o.type not in {'MESH', 'CURVE', 'FONT'}:
            continue
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        pts += [oe.matrix_world @ v.co for v in me.vertices]
        oe.to_mesh_clear()
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx


def studio(objs, elev=12.0, azim=-28.0, margin=1.22, top_down=False, floor_z=0.0):
    """Floor, two suns and an orthographic camera framed on objs."""
    mn, mx = bbox(objs)
    c = (mn + mx) / 2
    size = max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z)
    bpy.ops.mesh.primitive_plane_add(size=size * 40, location=(c.x, c.y, floor_z))
    floor = bpy.context.object
    floor.data.materials.append(material("Floor", GREY, rough=0.8))
    for name, rot, energy in (("Key", (math.radians(48), 0, math.radians(-38)), 3.2),
                              ("Fill", (math.radians(65), 0, math.radians(130)), 1.0)):
        bpy.ops.object.light_add(type='SUN', rotation=rot)
        bpy.context.object.data.energy = energy
        bpy.context.object.data.angle = math.radians(8)
        bpy.context.object.name = name
    bpy.ops.object.camera_add()
    cam = bpy.context.object
    cam.data.type = 'ORTHO'
    if top_down:
        e, a = math.radians(62), math.radians(azim)
    else:
        e, a = math.radians(elev), math.radians(azim)
    d = size * 6
    cam.location = c + Vector((math.sin(a) * math.cos(e) * d, -math.cos(a) * math.cos(e) * d, math.sin(e) * d))
    cam.rotation_euler = (c - cam.location).to_track_quat('-Z', 'Y').to_euler()
    cam.data.ortho_scale = size * margin
    cam.data.clip_end = d * 4
    bpy.context.scene.camera = cam
    return cam


def render(path):
    """Render the current scene to a PNG."""
    sc = bpy.context.scene
    sc.render.filepath = path
    sc.render.image_settings.file_format = 'PNG'
    bpy.ops.render.render(write_still=True)


def import_glb(path):
    """Import a GLB and return its single mesh object."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
    return objs[0]
