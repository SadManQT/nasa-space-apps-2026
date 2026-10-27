"""Game names for animation clips, shared by assemble_character.py and retarget_clips.py.

Looping clips end in "_loop", which Godot's importer turns into looping animations.
"""
import re

NAMES = [  # (pattern in the source action name, game name); None drops the clip
    # v7 locomotion: turns and transitions first, then each character's own walk/run, then the rig's basic cycles
    ("idle_turn_left", "TurnIdleL"), ("idle_turn_right", "TurnIdleR"), ("walk_turn_left", "TurnWalkL"),
    ("walk_turn_right", "TurnWalkR"), ("run_turn_left", "TurnRunL"), ("run_turn_right", "TurnRunR"),
    ("run_to_walk", "RunToWalk"), ("sprint_and_sudden_stop", "SprintStop"), ("lean_forward_sprint", "Sprint_loop"),
    ("quick_walk|walking_2|casual_walk|thoughtful_walk", "Walk_loop"), (r"^run_0\d$", "Run_loop"),
    ("walking", "WalkBasic_loop"), ("running", "RunBasic_loop"), ("^idle$", None),  # library "Idle" is a fighter's stance
    ("^idle_3$", "Idle_loop"), ("^idle_9$", "IdleAlt_loop"), ("long_breathe", "Breathe_loop"),
    ("listening", "Listen_loop"), ("talk", "Talk_loop"), ("chair_sit_idle", "SitIdle_loop"),
    ("step_to_sit", "SitDown"), ("sit_to_stand", "StandUp"), ("torch_look", "LookAround_loop"),
    ("agree", "Agree"), ("open_door", "OpenDoor"), ("pick_up", "PickUp"), ("kneel", "KneelStand"),
    ("wave", "Wave"), ("cheer", "Cheer"), ("drink", "Drink"), ("carry", "Carry_loop"), ("push", "Push"),
]


def game_name(raw):
    """Game name for a raw clip name like 'Walking_man' (the middle part of 'Armature|Walking_man|baselayer')."""
    return next((n for pat, n in NAMES if re.search(pat, raw.lower())), raw)
