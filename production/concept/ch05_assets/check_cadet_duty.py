"""M3-5A: CH_Cadet_DutyLayer coverage check on the installed cast (Blender 5.2, read-only, no credits).

Usage:
  blender -b --factory-startup --python check_cadet_duty.py -- <glb> [<glb> ...]

For each rigged character GLB prints one CADET line:
  * height, and the mesh's depth (front-to-back extent) between 30 % and 70 % of the height, which is the
    side-view silhouette the mirrored-arm check inspects: a second arm swung forward or back (Mei's first v8 build)
    widens this band well beyond body depth + one arm;
  * the number of separate clusters across the body at hand height (expected 3: left hand, legs, right hand) and
    along the depth at forearm height (expected 1: the arms hang beside the torso, so nothing stands in front of
    or behind the body in rest pose).
Result: PASS when the depth cluster count at forearm height is 1 (no arm stands in front of or behind the torso);
the depth band and the side-to-side count are printed for the record (belts, pouches and Mei's apron bow widen them).
"""
import bpy, sys
from mathutils import Vector


def clusters(values, gap):
    values = sorted(values)
    n = 1 if values else 0
    for a, b in zip(values, values[1:]):
        if b - a > gap:
            n += 1
    return n


def main():
    for path in sys.argv[sys.argv.index("--") + 1:]:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=path)
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
        shapes = {pb.custom_shape for o in bpy.data.objects if o.type == "ARMATURE" for pb in o.pose.bones}
        meshes = [o for o in bpy.data.objects if o.type == "MESH" and o not in shapes]
        dg = bpy.context.evaluated_depsgraph_get()
        pts = []
        for o in meshes:
            oe = o.evaluated_get(dg)
            me = oe.to_mesh()
            pts += [oe.matrix_world @ v.co for v in me.vertices]
            oe.to_mesh_clear()
        zs = [p.z for p in pts]
        h = max(zs) - min(zs)
        z0 = min(zs)
        band = [p for p in pts if z0 + 0.30 * h <= p.z <= z0 + 0.70 * h]
        depth = max(p.y for p in band) - min(p.y for p in band)
        hands = [p for p in pts if z0 + 0.36 * h <= p.z <= z0 + 0.46 * h]
        side = clusters([p.x for p in hands], 0.03)
        fore = [p for p in pts if z0 + 0.42 * h <= p.z <= z0 + 0.58 * h]
        front = clusters([p.y for p in fore], 0.03)
        ok = front == 1   # belts, pouches and apron bows make the other two numbers kit-dependent; they are reported only
        name = path.split("/")[-1].replace(".glb", "")
        print(f"CADET {name} height={h:.3f} depth_band={depth:.3f} side_clusters={side} depth_clusters={front} "
              f"bones={sum(len(o.data.bones) for o in bpy.data.objects if o.type == 'ARMATURE')} "
              f"clips={len(bpy.data.actions)} result={'PASS' if ok else 'FAIL'}")


if __name__ == "__main__":
    main()
