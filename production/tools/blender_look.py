"""The game look for review renders, shared by render_showcase.py, render_context.py and render_lipsync.py: AgX film
tonemapping, soft environment light from a studio HDRI (hidden from the camera behind a graded backdrop colour),
a warm key, a cool fill and a cool rim light. Matches the Godot look-dev setup (codex_look_report.md).
"""
import os
import bpy
from mathutils import Vector

def setup(sc, backdrop=(0.11, 0.13, 0.17), centre=Vector((0, 0, 1.0)), scale=1.0):
    """Light the scene around `centre`; `scale` grows the light rig for wider shots."""
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE"
    vt = {t.identifier for t in bpy.types.ColorManagedViewSettings.bl_rna.properties["view_transform"].enum_items}
    sc.view_settings.view_transform = "AgX" if "AgX" in vt else "Filmic"
    for look in ("AgX - Medium High Contrast", "Medium High Contrast"):
        try: sc.view_settings.look = look; break
        except TypeError: pass
    for attr, val in (("use_raytracing", True), ("use_shadows", True), ("shadow_ray_count", 2), ("use_gtao", True), ("gtao_distance", 0.4), ("taa_render_samples", 48)):
        if hasattr(sc.eevee, attr): setattr(sc.eevee, attr, val)
    res = os.path.join(os.path.dirname(bpy.app.binary_path), "..", "Resources")
    hdri = next((os.path.join(res, d, "datafiles", "studiolights", "world", "studio.exr") for d in os.listdir(res)
                 if os.path.exists(os.path.join(res, d, "datafiles", "studiolights", "world", "studio.exr"))), None)
    w = bpy.data.worlds.new("World"); sc.world = w; w.use_nodes = True; nt = w.node_tree
    bg = nt.nodes["Background"]; bg.inputs[1].default_value = 0.35; out = nt.nodes["World Output"]
    flat = nt.nodes.new("ShaderNodeBackground"); flat.inputs[0].default_value = (*backdrop, 1); flat.inputs[1].default_value = 1.0
    if hdri:
        env = nt.nodes.new("ShaderNodeTexEnvironment"); env.image = bpy.data.images.load(hdri); nt.links.new(env.outputs[0], bg.inputs[0])
    lp = nt.nodes.new("ShaderNodeLightPath"); mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(lp.outputs["Is Camera Ray"], mix.inputs[0]); nt.links.new(bg.outputs[0], mix.inputs[1]); nt.links.new(flat.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs[0])
    for name, energy, color, off, size in (("Key", 900, (1.0, 0.93, 0.84), (2.6, -3.0, 2.4), 2.5),     # warm key, front right, high
                                           ("Fill", 220, (0.80, 0.88, 1.0), (-3.2, -2.4, 0.8), 4.0),    # cool soft fill, front left
                                           ("Rim", 1100, (0.75, 0.86, 1.0), (-1.6, 3.2, 1.8), 1.5)):    # cool rim from behind
        L = bpy.data.lights.new(name, "AREA"); L.energy = energy * scale * scale; L.color = color; L.size = size * scale
        o = bpy.data.objects.new(name, L); sc.collection.objects.link(o); o.location = centre + Vector(off) * scale
        o.rotation_euler = (centre - o.location).to_track_quat("-Z", "Y").to_euler()

def floor(size=40, color=(0.20, 0.23, 0.28)):
    bpy.ops.mesh.primitive_plane_add(size=size); f = bpy.context.object; f.name = "Floor"
    m = bpy.data.materials.new("Floor"); m.use_nodes = True; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (*color, 1); bs.inputs["Roughness"].default_value = 0.85; f.data.materials.append(m)
    return f
