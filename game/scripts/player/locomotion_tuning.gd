extends Resource
class_name LocomotionTuning

# Zero uses the measured clip speed; overrides change cadence, not stride length.
@export_range(0.0, 8.0, 0.01) var walk_speed: float = 0.0
@export_range(0.0, 12.0, 0.01) var run_speed: float = 0.0
@export_range(0.0, 15.0, 0.01) var sprint_speed: float = 0.0
@export_range(0.05, 0.6, 0.01) var acceleration_time: float = 0.22
@export_range(0.05, 0.6, 0.01) var braking_time: float = 0.18
@export_range(1.0, 20.0, 0.1) var turn_rate: float = 9.0
@export_range(0.0, 8.0, 0.1) var lean_degrees: float = 4.0
@export_range(0.0, 0.4, 0.01) var step_height: float = 0.22
@export_range(0.1, 0.6, 0.01) var action_fade_in: float = 0.28
@export_range(0.1, 0.8, 0.01) var action_fade_out: float = 0.35
@export_range(0.1, 0.8, 0.01) var idle_fade: float = 0.4
@export_range(0.01, 0.4, 0.005) var pose_smoothing: float = 0.035
@export_range(360.0, 1200.0, 30.0) var maximum_bone_degrees_per_second: float = 900.0

# Seated fit in an installed crew seat (PR_CrewSeat, cushion 0.38-0.44 m, backrest reclined ~15 degrees).
# The authored SitIdle clips were made for a lower seat, so their thighs slope down through the cushion.
# A small backward lean about the pelvis rests the thighs on the cushion and the back near the backrest.
# Measured per character over a whole SitIdle cycle (13 Nov, M1-129); the defaults keep the old upright fit.
@export_range(0.0, 30.0, 0.5) var seat_recline_degrees: float = 0.0
## Pelvis joint above the seat's floor, in metres (chair space, before the seat's own scale).
@export_range(0.3, 0.8, 0.005) var seat_pelvis_height: float = 0.54
## Pelvis joint in front of the seat pivot, in metres (the backrest is behind the pivot).
@export_range(-0.2, 0.3, 0.005) var seat_pelvis_forward: float = 0.12
## Extra backward spine rotation while seated, for clips that slump forward over the knees.
@export_range(0.0, 30.0, 0.5) var seat_spine_back_degrees: float = 0.0
