"""Pose a rigged character (arm up, leg forward, spine/head turned) and export a static GLB,
so render_preview.py can show whether skin weights survived decimation.

  blender -b -P pose_test.py -- <rigged.glb> <posed_out.glb>
"""
import math, sys
import bpy

src, dst = sys.argv[sys.argv.index("--") + 1:][:2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
# (Meshy name, Tripo name): whichever the rig has
for bones, rot in ((("LeftArm", "L_Upperarm"), (0, 0, -60)), (("RightUpLeg", "R_Thigh"), (-50, 0, 0)),
                   (("Spine01", "Spine02"), (0, 20, 0)), (("Head", "Head"), (0, 25, 0))):
    pb = next((arm.pose.bones[b] for b in bones if b in arm.pose.bones), None)
    if pb:
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = [math.radians(r) for r in rot]
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_apply=True, export_skins=False)
