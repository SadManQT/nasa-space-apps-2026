# strip the skeleton from a rigged GLB: mesh in bind pose with its materials, for re-rigging elsewhere
import sys, bpy
src, dst = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
shapes = {pb.custom_shape for o in bpy.context.scene.objects if o.type == "ARMATURE" for pb in o.pose.bones}
for o in [o for o in bpy.context.scene.objects if o in shapes]:  # importer's bone-display icosphere
    bpy.data.objects.remove(o)
for o in list(bpy.context.scene.objects):
    if o.type == "MESH":
        for m in [m for m in o.modifiers if m.type == "ARMATURE"]:
            o.modifiers.remove(m)
        o.vertex_groups.clear()
        wm = o.matrix_world.copy(); o.parent = None; o.matrix_world = wm
for o in [o for o in bpy.context.scene.objects if o.type != "MESH"]:
    bpy.data.objects.remove(o)
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_yup=True, export_skins=False, export_animations=False)
print("STRIPPED", [o.name for o in bpy.context.scene.objects], "->", dst)
