"""Review renders of the built PL_Alo_Sprout / PL_Tara_Sprout GLBs (reads the GLBs, never rebuilds them).

Usage:
  blender -b --factory-startup --python review_sprout_glb.py -- <out_dir>

Per species: each stage alone at 3/4, front, side and back; the Droop and Cup morph targets; and the whole pot.
"""
import bpy, math, os, sys
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "production", "concept", "narrative_props"))
import sheet_common as C  # noqa: E402

VIEWS = {"q": -28.0, "front": 0.0, "side": 90.0, "back": 180.0}


def shot(name, stage, out, azim, key=None, whole=False, top=False):
    C.reset()
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x = sc.render.resolution_y = 640
    bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT, "game", "assets", "plants", name, name + ".glb"))
    objs = {o.name: o for o in sc.objects if o.type == 'MESH'}
    for n, o in objs.items():
        if n.startswith("Stage_") and n != stage:
            o.hide_render = True
    s = objs[stage]
    if key and s.data.shape_keys:
        s.data.shape_keys.key_blocks[key].value = 1.0
    # close-ups share the true-leaf framing, so the three stages compare at one scale
    frame = [objs["Pot"], s] if whole else [objs["Stage_TrueLeaf"]]
    cam = C.studio(frame, elev=8 if whole else 18, azim=azim, margin=1.25 if whole else 1.6)
    if top:  # straight down on the soil: shows any remnant of the cut plant
        mn, mx = C.bbox([objs["Pot"]])
        cam.location = ((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mx.z + 0.3)
        cam.rotation_euler = (0, 0, 0)
        cam.data.ortho_scale = (mx.x - mn.x) * 1.05
    C.render(out)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    os.makedirs(out, exist_ok=True)
    for name in ("PL_Alo_Sprout", "PL_Tara_Sprout"):
        for stage in ("Stage_Seed", "Stage_Cotyledon", "Stage_TrueLeaf"):
            for v, az in VIEWS.items():
                shot(name, stage, f"{out}/{name}_{stage}_{v}.png", az)
            shot(name, stage, f"{out}/{name}_{stage}_pot.png", -28, whole=True)
            shot(name, stage, f"{out}/{name}_{stage}_top.png", 0, whole=True, top=True)
        for stage in ("Stage_Cotyledon", "Stage_TrueLeaf"):
            for key in ("Droop", "Cup"):
                shot(name, stage, f"{out}/{name}_{stage}_{key}.png", -28, key=key)
