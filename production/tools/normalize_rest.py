"""Give a rigged character a clean, symmetric A-pose rest: both arms straight, 35 degrees out from the body in its side
plane (no forward or backward swing), forearms and hands in line, then bake the mesh into that pose and make it the
rest pose. Tripo builds the arms' depth from the front and back views alone, so its rest arms can swing 15-30 cm
forward or back, unequally on the two sides; a twisted rest makes every animated arm roll the forearm and splay the
hand. Weights are kept.

  blender -b -P normalize_rest.py -- <rig.glb> <out.glb>
"""
import math, sys
import bpy
from mathutils import Matrix, Vector

src, dst = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
sc = bpy.context.scene
for o in {pb.custom_shape for o in sc.objects if o.type == "ARMATURE" for pb in o.pose.bones} - {None}: bpy.data.objects.remove(o)
for o in [o for o in sc.objects if o.type == "MESH" and o.name.startswith("Icosphere")]: bpy.data.objects.remove(o)
arm = next(o for o in sc.objects if o.type == "ARMATURE")
meshes = [o for o in sc.objects if o.type == "MESH"]
B = {b.name.split(":")[-1]: b.name for b in arm.data.bones}
inv = arm.matrix_world.to_3x3().inverted()

def aim(name, direction):
    """Turn a bone (with the least twist) so it points along a world direction."""
    pb = arm.pose.bones[name]; bpy.context.view_layer.update()
    m = pb.matrix.to_3x3(); cur = m.col[1].normalized(); want = (inv @ direction).normalized()
    pb.matrix = Matrix.Translation(pb.matrix.translation) @ (cur.rotation_difference(want).to_matrix() @ m).to_4x4()
    bpy.context.view_layer.update()

before = {}
for side, sg in (("Left", 1), ("Right", -1)):      # the character faces -Y: its left is +X
    a = math.radians(35)
    down_out = Vector((sg * math.sin(math.radians(90 - 35)), 0.0, -math.cos(math.radians(90 - 35))))   # 35 deg below horizontal
    before[side] = arm.matrix_world @ arm.data.bones[B[side + "Hand"]].head_local
    for part in ("Arm", "ForeArm", "Hand"):
        aim(B[side + part], down_out)

# bake: the mesh takes the pose, then the pose becomes the rest
bpy.context.view_layer.objects.active = None
for o in meshes:
    mod = next((m for m in o.modifiers if m.type == "ARMATURE"), None)
    if mod is None: continue
    bpy.context.view_layer.objects.active = o; o.select_set(True)
    bpy.ops.object.modifier_apply(modifier=mod.name); o.select_set(False)
bpy.context.view_layer.objects.active = arm; arm.select_set(True)
bpy.ops.object.mode_set(mode="POSE"); bpy.ops.pose.select_all(action="SELECT"); bpy.ops.pose.armature_apply(selected=False)
bpy.ops.object.mode_set(mode="OBJECT")
for o in meshes:
    if not any(m.type == "ARMATURE" for m in o.modifiers):
        mod = o.modifiers.new("Armature", "ARMATURE"); mod.object = arm
for side in ("Left", "Right"):
    after = arm.matrix_world @ arm.data.bones[B[side + "Hand"]].head_local
    print(f"REST {side} hand moved {(after - before[side]).length * 100:.1f} cm to {tuple(round(v, 3) for v in after)}")
l, r = (arm.matrix_world @ arm.data.bones[B[s + "Hand"]].head_local for s in ("Left", "Right"))
print(f"REST mirror error {((l.x + r.x) ** 2 + (l.y - r.y) ** 2 + (l.z - r.z) ** 2) ** 0.5 * 100:.1f} cm")
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_yup=True, export_skins=True, export_animations=False)
print("NORMALIZED ->", dst)
