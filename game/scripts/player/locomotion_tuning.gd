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
