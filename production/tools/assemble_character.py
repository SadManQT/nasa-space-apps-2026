"""Build the game GLB for a Meshy-rigged character: the fully textured rigged model plus every clip.

  blender -b -P assemble_character.py -- <rigged_character.glb> <out.glb> <clips.glb> [<clips.glb> ...] [Name=<one_clip.glb> ...]

Meshy's clip files carry the same skeleton but only a base-colour texture, so the mesh comes from the
rigged model and only the actions are taken from the clip files. Name=file gives a one-clip file's
action that name (Meshy text-to-motion clips all arrive as "retarget_clip"). Clips get short names; looping ones end
in "_loop", which Godot's importer turns into looping animations.
"""
import re, sys
import bpy

NAMES = [  # (pattern in Meshy's action name, game name); None drops the clip
    ("walking", "Walk_loop"), ("running", "Run_loop"), ("^idle$", None),  # library "Idle" is a fighter's stance
    ("^idle_3$", "Idle_loop"), ("^idle_9$", "IdleAlt_loop"), ("long_breathe", "Breathe_loop"),
    ("listening", "Listen_loop"), ("talk", "Talk_loop"), ("chair_sit_idle", "SitIdle_loop"),
    ("step_to_sit", "SitDown"), ("sit_to_stand", "StandUp"), ("torch_look", "LookAround_loop"),
    ("agree", "Agree"), ("open_door", "OpenDoor"), ("pick_up", "PickUp"), ("kneel", "KneelStand"),
    ("wave", "Wave"), ("cheer", "Cheer"), ("drink", "Drink"), ("push", "Push"),
]

src, dst, *clips = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)

def import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    shapes = {pb.custom_shape for o in new if o.type == "ARMATURE" for pb in o.pose.bones}
    keep = [o for o in new if o not in shapes]
    for o in shapes - {None}:  # glTF importer's bone-display icosphere
        bpy.data.objects.remove(o)
    return keep

arm = next(o for o in import_glb(src) if o.type == "ARMATURE")
for t in list(arm.animation_data.nla_tracks):  # the rigged model's own placeholder clip and its track
    arm.animation_data.nla_tracks.remove(t)
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)

for arg in clips:
    given, _, path = arg.partition("=") if "=" in arg else ("", "", arg)
    objs = import_glb(path)
    for o in objs:
        if o.animation_data and o.animation_data.action:
            o.animation_data.action.use_fake_user = True
            if given:
                o.animation_data.action.name = f"Armature|{given}|named"
    for o in objs:
        bpy.data.objects.remove(o)

arm.animation_data_create()
seen = set()
for act in sorted(bpy.data.actions, key=lambda a: a.name):
    raw = act.name.split("|")[1] if "|" in act.name else act.name  # "Armature|Walking_man|baselayer"
    name = raw if act.name.endswith("|named") else next((n for pat, n in NAMES if re.search(pat, raw.lower())), raw)
    if name is None or name in seen:
        bpy.data.actions.remove(act); continue
    seen.add(name)
    act.name = name
    track = arm.animation_data.nla_tracks.new(); track.name = name
    track.strips.new(name, int(act.frame_range[0]), act); track.mute = True

bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_yup=True, export_skins=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS")
# Meshy rigs sit under a 0.01-scaled armature in centimetres; bake that into the joints (metres throughout)
import subprocess
from pathlib import Path
subprocess.run(["python3", str(Path(__file__).with_name("glb_unscale_armature.py")), dst, dst], check=True)
print("ASSEMBLED", sorted(seen), "->", dst)
