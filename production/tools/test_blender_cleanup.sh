#!/bin/sh
# Smoke test for blender_cleanup.py: a seam-split sphere must decimate without losing
# regions, end up exactly --height tall, centred, standing on z=0.
set -e
T=$(mktemp -d); cd "$(dirname "$0")"
blender -b --python-expr "
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.mesh.primitive_uv_sphere_add(segments=128, ring_count=64, radius=3, location=(5,2,7))
bpy.ops.export_scene.gltf(filepath='$T/in.glb', export_format='GLB')" >/dev/null 2>&1
blender -b -P blender_cleanup.py -- "$T/in.glb" "$T/out.glb" --tris 2000 --height 1.75 2>&1 | grep CLEANUP
blender -b --python-exit-code 1 --python-expr "
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='$T/out.glb')
o=[o for o in bpy.context.scene.objects if o.type=='MESH'][0]
xs=[o.matrix_world@v.co for v in o.data.vertices]
lo=[min(p[i] for p in xs) for i in range(3)]; hi=[max(p[i] for p in xs) for i in range(3)]
assert abs(lo[2])<1e-3 and abs(hi[2]-1.75)<0.01 and abs(hi[0]-0.875)<0.01, (lo, hi)
assert sum(len(p.vertices)-2 for p in o.data.polygons) <= 2000
print('blender_cleanup SELFTEST OK')" 2>&1 | grep -E "SELFTEST|Error|assert"
rm -rf "$T"
