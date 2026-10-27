extends Node
class_name PlayerAnimation

const ACTIONS: Array[String] = ["Wave", "PickUp", "OpenDoor", "Inspect", "Pollinate", "Water", "Repair", "Type", "Agree", "Cheer", "Drink", "Push"]
const ClipScript: Script = preload("res://scripts/player/locomotion_clips.gd")
enum Hold { NONE, BOX, RIGHT }
const HOLD_CLIPS: Array[String] = ["CarryBox_pose", "HoldRight_pose"]
const HOLD_FADE: float = 0.2

@export var idle_variations: bool = true
@export_range(3.0, 30.0, 0.5) var idle_interval: float = 9.0
@export_range(0.0, 1.0, 0.05) var action_movement_scale: float = 0.0

var tree: AnimationTree
var skeleton: Skeleton3D
var player: AnimationPlayer
var tuning: LocomotionTuning
var clips: LocomotionClips
var horizontal_speed: float = 0.0
var blend_speed: float = 0.0
var phase: float = 0.0
var cadence: float = 0.0
var action_name: String = ""
var action_weight: float = 0.0
var action_time: float = 0.0
var action_duration: float = 0.0
var movement_locked: bool = false
var _graph: AnimationNodeBlendTree
var _action_node: AnimationNodeAnimation
var _idle_node: AnimationNodeAnimation
var _talk_node: AnimationNodeAnimation
var _action_fade: AnimationNodeOneShot
var _idle_fade: AnimationNodeOneShot
var _idle_timer: float = 0.0
var _idle_index: int = 0
var _talk_requested: String = ""
var _talk_weight: float = 0.0
var _pending_action: String = ""
var action_is_transition: bool = false
var hold_mode: Hold = Hold.NONE
var hold_weights := Vector2.ZERO

func setup(animation_player: AnimationPlayer, rig: Skeleton3D, settings: LocomotionTuning) -> bool:
	player = animation_player
	skeleton = rig
	tuning = settings
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	clips = ClipScript.new()
	if not clips.prepare(player, skeleton):
		return false
	var measured: Array[float] = []
	for name in clips.gaits:
		measured.append(clips.measurements[name].speed)
	if tuning.walk_speed <= 0.0:
		tuning.walk_speed = measured[0]
	if tuning.run_speed <= 0.0:
		tuning.run_speed = maxf(measured[1], tuning.walk_speed + 0.1)
	tuning.run_speed = maxf(tuning.run_speed, tuning.walk_speed + 0.1)
	if tuning.sprint_speed <= 0.0:
		tuning.sprint_speed = maxf(measured[2], tuning.run_speed * 1.15) if clips.gaits[2] != clips.gaits[1] else tuning.run_speed
	tuning.sprint_speed = maxf(tuning.sprint_speed, tuning.run_speed)
	player.play("motion/Idle_loop")
	player.seek(0.0, true)
	player.pause()
	_build_tree()
	_idle_timer = idle_interval
	advance(0.0, 0.0)
	return true

func _node(clip: String) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = "motion/" + clip
	return node

func _build_tree() -> void:
	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.root_node = player.root_node
	# The AnimationPlayer's root path is relative to the player, not this tree.
	tree.root_node = tree.get_path_to(player.get_node(player.root_node))
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_graph = AnimationNodeBlendTree.new()
	var locomotion := AnimationNodeBlendSpace1D.new()
	locomotion.min_space = 0.0
	locomotion.max_space = maxf(tuning.sprint_speed, tuning.run_speed)
	locomotion.sync_mode = AnimationNodeBlendSpace1D.SYNC_MODE_CYCLIC_CONSTANT
	locomotion.cyclic_length = 1.0
	var idle_pose := _node("Idle_loop")
	idle_pose.use_custom_timeline = true
	idle_pose.timeline_length = 1.0
	idle_pose.stretch_time_scale = false
	locomotion.add_blend_point(idle_pose, 0.0, -1, "Idle")
	locomotion.add_blend_point(_node(clips.gaits[0] + "_cycle"), tuning.walk_speed, -1, "Walk")
	locomotion.add_blend_point(_node(clips.gaits[1] + "_cycle"), tuning.run_speed, -1, "Run")
	if tuning.sprint_speed > tuning.run_speed + 0.01:
		locomotion.add_blend_point(_node(clips.gaits[2] + "_cycle"), tuning.sprint_speed, -1, "Sprint")
	_graph.add_node("Locomotion", locomotion)
	_graph.add_node("Cadence", AnimationNodeTimeScale.new())
	_graph.connect_node("Cadence", 0, "Locomotion")
	# Keep breathing at authored speed at rest, independent of the gait clock.
	_graph.add_node("Rest", _node("Idle_loop"))
	_graph.add_node("RestBlend", AnimationNodeBlend2.new())
	_graph.connect_node("RestBlend", 0, "Cadence")
	_graph.connect_node("RestBlend", 1, "Rest")
	_idle_node = _node("Idle_loop")
	_graph.add_node("Variation", _idle_node)
	_idle_fade = AnimationNodeOneShot.new()
	_idle_fade.fadein_time = tuning.idle_fade
	_idle_fade.fadeout_time = tuning.idle_fade
	_idle_fade.break_loop_at_end = true
	_graph.add_node("IdleVariation", _idle_fade)
	_graph.connect_node("IdleVariation", 0, "RestBlend")
	_graph.connect_node("IdleVariation", 1, "Variation")
	_talk_node = _node("Talk_loop" if has_clip("Talk_loop") else "Idle_loop")
	_graph.add_node("TalkClip", _talk_node)
	_graph.add_node("Talk", AnimationNodeBlend2.new())
	_graph.connect_node("Talk", 0, "IdleVariation")
	_graph.connect_node("Talk", 1, "TalkClip")
	_action_node = _node("Idle_loop")
	_graph.add_node("ActionClip", _action_node)
	_action_fade = AnimationNodeOneShot.new()
	_action_fade.fadein_time = tuning.action_fade_in
	_action_fade.fadeout_time = tuning.action_fade_out
	_graph.add_node("Action", _action_fade)
	_graph.connect_node("Action", 0, "Talk")
	_graph.connect_node("Action", 1, "ActionClip")
	var previous := "Action"
	for index in HOLD_CLIPS.size():
		var clip := HOLD_CLIPS[index]
		var layer := "HoldBox" if index == 0 else "HoldRight"
		if has_clip(clip):
			# These short poses do not use Godot's _loop naming convention.
			player.get_animation("motion/" + clip).loop_mode = Animation.LOOP_LINEAR
		_graph.add_node(layer + "Clip", _node(clip if has_clip(clip) else "Idle_loop"))
		var blend := AnimationNodeBlend2.new()
		blend.filter_enabled = true
		for path in hold_filter_paths(Hold.BOX if index == 0 else Hold.RIGHT):
			blend.set_filter_path(path, true)
		_graph.add_node(layer, blend)
		_graph.connect_node(layer, 0, previous)
		_graph.connect_node(layer, 1, layer + "Clip")
		previous = layer
	_graph.connect_node("output", 0, previous)
	tree.tree_root = _graph
	tree.active = true

func hold_filter_paths(mode: Hold) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	if skeleton == null or mode == Hold.NONE:
		return paths
	var root := player.get_node(player.root_node)
	for side in ["Left", "Right"] if mode == Hold.BOX else ["Right"]:
		var suffixes: Array[String] = ["Shoulder", "Arm", "ForeArm", "Hand"]
		for finger in ["Thumb", "Index", "Middle", "Ring", "Pinky"]:
			for joint in range(1, 4):
				suffixes.append("Hand%s%d" % [finger, joint])
		for suffix in suffixes:
			var bone := LocomotionClips.bone(skeleton, side + suffix)
			if bone >= 0:
				paths.append(NodePath(String(root.get_path_to(skeleton)) + ":" + skeleton.get_bone_name(bone)))
	return paths

func set_hold(mode: Hold) -> void:
	hold_mode = mode

func has_clip(clip: String) -> bool:
	return player != null and player.has_animation("motion/" + clip)

func request_action(clip: String) -> bool:
	if clip not in ACTIONS or not has_clip(clip) or not action_name.is_empty() or not _pending_action.is_empty():
		return false
	_pending_action = clip
	movement_locked = true
	return true

func play_transition(clip: String) -> bool:
	if not has_clip(clip) or not action_name.is_empty() or movement_locked:
		return false
	_start_action(clip, true)
	return true

func set_talking(talking: bool, listening: bool = false) -> void:
	var clip := "Listen_loop" if listening else "Talk_loop"
	_talk_requested = clip if talking and has_clip(clip) else ""

func _start_action(clip: String, transition: bool) -> void:
	action_name = clip
	action_time = 0.0
	action_duration = player.get_animation("motion/" + clip).length
	action_is_transition = transition
	_action_node.animation = "motion/" + clip
	tree.set("parameters/IdleVariation/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/Action/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func advance(delta: float, speed: float) -> void:
	if tree == null:
		return
	horizontal_speed = speed
	blend_speed = clampf(speed, 0.0, tuning.sprint_speed)
	tree.set("parameters/Locomotion/blend_position", blend_speed)
	var distance := _stride_distance(blend_speed)
	cadence = speed / distance if distance > 0.001 else 0.0
	phase = fposmod(phase + cadence * delta, 1.0)
	tree.set("parameters/Cadence/scale", cadence)
	tree.set("parameters/RestBlend/blend_amount", 1.0 - smoothstep(0.0, tuning.walk_speed * 0.25, speed))
	if not _pending_action.is_empty() and speed < 0.08 + tuning.sprint_speed * action_movement_scale:
		_start_action(_pending_action, false)
		_pending_action = ""
	_update_action(delta)
	_update_idle(delta, speed)
	var talk_target := 1.0 if not _talk_requested.is_empty() and speed < 0.08 and action_name.is_empty() else 0.0
	if not _talk_requested.is_empty() and String(_talk_node.animation) != "motion/" + _talk_requested:
		talk_target = 0.0
		if _talk_weight <= 0.001:
			_talk_node.animation = "motion/" + _talk_requested
	_talk_weight = move_toward(_talk_weight, talk_target, delta / tuning.idle_fade)
	tree.set("parameters/Talk/blend_amount", _talk_weight)
	for index in HOLD_CLIPS.size():
		var target := 1.0 if hold_mode == index + 1 and has_clip(HOLD_CLIPS[index]) else 0.0
		hold_weights[index] = move_toward(hold_weights[index], target, delta / HOLD_FADE)
		tree.set("parameters/%s/blend_amount" % ("HoldBox" if index == 0 else "HoldRight"), hold_weights[index])
	tree.advance(delta)

func _stride_distance(speed: float) -> float:
	var walk: float = clips.measurements[clips.gaits[0]].distance
	var run: float = clips.measurements[clips.gaits[1]].distance
	var sprint: float = clips.measurements[clips.gaits[2]].distance
	if speed <= tuning.walk_speed:
		return walk * speed / tuning.walk_speed
	if speed <= tuning.run_speed:
		return lerpf(walk, run, inverse_lerp(tuning.walk_speed, tuning.run_speed, speed))
	return lerpf(run, sprint, inverse_lerp(tuning.run_speed, tuning.sprint_speed, speed))

func _update_action(delta: float) -> void:
	if action_name.is_empty():
		action_weight = 0.0
		return
	action_time += delta
	action_weight = minf(clampf(action_time / tuning.action_fade_in, 0.0, 1.0), clampf((action_duration - action_time) / tuning.action_fade_out, 0.0, 1.0))
	if action_time >= action_duration:
		action_name = ""
		action_weight = 0.0
		movement_locked = false
		action_is_transition = false

func _update_idle(delta: float, speed: float) -> void:
	if speed > 0.08 or not _talk_requested.is_empty() or not action_name.is_empty():
		_idle_timer = idle_interval
		tree.set("parameters/IdleVariation/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
		return
	if bool(tree.get("parameters/IdleVariation/active")):
		return
	_idle_timer -= delta
	if not idle_variations or _idle_timer > 0.0:
		return
	var variants: Array[String] = ["IdleAlt_loop", "Breathe_loop", "LookAround_loop"]
	var chosen: String = variants[_idle_index % variants.size()]
	_idle_index += 1
	_idle_timer = idle_interval + randf_range(0.0, 4.0)
	if has_clip(chosen):
		_idle_node.animation = "motion/" + chosen
		tree.set("parameters/IdleVariation/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
