"""Keep only part of a one-clip GLB's animation (e.g. drop a text-to-motion clip's awkward ending).

  blender -b -P trim_clip.py -- <in.glb> <out.glb> <start_fraction> <end_fraction>

Keys outside the kept range are deleted and the rest shifted to start at frame 1.
"""
import sys
import bpy

src, dst, f0, f1 = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
act = bpy.data.actions[0]; a, b = act.frame_range; k0, k1 = a + (b - a) * float(f0), a + (b - a) * float(f1)
fcurves = act.fcurves if hasattr(act, "fcurves") and len(act.fcurves) else [fc for layer in act.layers for strip in layer.strips for bag in strip.channelbags for fc in bag.fcurves]
for fc in fcurves:
    for i in range(len(fc.keyframe_points) - 1, -1, -1):     # by index, last first: references go stale on removal
        if not (k0 <= fc.keyframe_points[i].co.x <= k1): fc.keyframe_points.remove(fc.keyframe_points[i])
    for kp in fc.keyframe_points:
        kp.co.x -= k0 - 1; kp.handle_left.x -= k0 - 1; kp.handle_right.x -= k0 - 1
act.frame_range = (1, k1 - k0 + 1)
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_animations=True)
print("TRIMMED", act.name, f"{a:.0f}-{b:.0f} -> frames {k0:.0f}-{k1:.0f} ->", dst)
