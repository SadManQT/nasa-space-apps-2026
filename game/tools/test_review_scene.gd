# Run: Godot --headless --path game --script res://tools/test_review_scene.gd
# Override the scratch build directory with: -- --v4-root=/absolute/path/to/v4
extends SceneTree

const ReviewScene: PackedScene = preload("res://scenes/review/character_review.tscn")
const V4_ROOT: String = "/private/tmp/claude-501/-Users-sadmansakib-nasa-space-apps-2026/8b783e13-4d3f-4549-8fec-ee82b9a2d7f4/scratchpad/v4"
const CAST: Array[String] = ["CH_Kai", "CH_Amara", "CH_Mei", "CH_Rafi", "CH_Ferreira"]
const CLIPS: Array[String] = ["Agree", "Breathe_loop", "Cheer", "Drink", "IdleAlt_loop", "Idle_loop", "Inspect", "KneelStand", "Listen_loop", "LookAround_loop", "OpenDoor", "PickUp", "Pollinate", "Push", "Repair", "Run_loop", "SitDown", "SitIdle_loop", "StandUp", "Talk_loop", "Type", "Walk_loop", "Water", "Wave"]
const POSES: Array[String] = ["HandRelaxed", "HandOpen", "HandGrip", "HandFist", "HandPoint", "HandPinch"]
const PROP: String = "res://assets/props/PR_SeedPacket/PR_SeedPacket.glb"

var _failures: int = 0
var _checks: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("REVIEW TEST Godot ", Engine.get_version_info().string)
	var build_root := V4_ROOT
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--v4-root="):
			build_root = arg.trim_prefix("--v4-root=")
	var review = ReviewScene.instantiate()
	review.auto_load = false
	root.add_child(review)
	review.set_process(false)
	for character in CAST:
		print("CHARACTER ", character)
		if not _check(review.load_character(build_root.path_join(character).path_join(character + ".glb")), "runtime GLTFDocument load"):
			continue
		var skeleton: Skeleton3D = review._skeleton
		var player: AnimationPlayer = review._animation_player
		_check(skeleton.get_bone_count() == 65, "65 bones")
		_check(review._face_mesh.mesh.get_blend_shape_count() == 21, "21 blend shapes")
		var missing: Array[String] = []
		for clip in CLIPS + POSES:
			if not player.has_animation(clip):
				missing.append(clip)
		_check(missing.is_empty() and player.get_animation_list().size() == 30, "24 body clips + 6 hand poses; missing=" + str(missing))
		_test_playback(review)
		_test_hands(review)
		for hand in ["left", "right"]:
			_check(review.attach_prop(PROP, hand), "real seed packet attaches " + hand)
			var prop: Node3D = review.get_attached_prop()
			var attachment := prop.get_parent() as BoneAttachment3D
			var suffix := "LeftHand" if hand == "left" else "RightHand"
			_check(attachment != null and attachment.get_parent() == skeleton and attachment.bone_name.ends_with(suffix), "BoneAttachment3D resolves " + suffix)
			review.select_clip("Wave")
			review.seek_animation(0.6)
			await process_frame
			await process_frame
			var expected := skeleton.global_transform * skeleton.get_bone_global_pose(attachment.bone_idx)
			_check(prop.global_transform.is_equal_approx(expected), "prop follows animated hand transform")
		# Offsets must update the already attached prop, not just the next instance.
		review._prop_x.value = 0.03
		review._prop_ry.value = 90.0
		_check(_near(review.get_attached_prop().position.x, 0.03) and _near(review.get_attached_prop().rotation_degrees.y, 90.0), "prop offsets update live, rotations accept degrees")
		review._prop_x.value = 0.0
		review._prop_ry.value = 0.0
		review.clear_props()
		_check(review.get_attached_prop() == null, "remove props clears attachment")
		_check(review._prop_option.item_count >= 30, "prop picker includes props, plants and vehicles")
		review._skeleton_check.button_pressed = true
		review._update_bone_lines()
		_check(review._bone_lines.mesh.get_surface_count() == 1, "bone-line overlay builds")
		review._skeleton_check.button_pressed = false
		_test_lips(review)
		_test_walk(review, character)
		# Test a known world translation as an independent control for skinning/speed.
		review.select_clip("Idle_loop")
		review.seek_animation(0.5)
		review.reset_measurements()
		review._character.position.x += 0.1
		var translated: Dictionary = review._foot_slide.sample(0.1)
		_check(_near(translated.root_speed, 1.0), "measurement control: 10 cm / 100 ms = 1 m/s root")
		for side in ["left", "right"]:
			var foot: Dictionary = translated[side]
			_check(foot.contact_samples > 0 and absf(foot.slide_speed - 1.0) < 0.0001, "measurement control: planted " + side + " surface moves at 1 m/s")
		review._character.position.x -= 0.1
	_check(review.attach_prop(PROP, "right"), "attach before character replacement")
	# Replacement after attaching catches dangling BoneAttachment3D references.
	_check(review.load_character(build_root.path_join("CH_Kai/CH_Kai.glb")) and review.attach_prop(PROP, "right"), "reload after attachment, then attach again")
	review.free()
	await process_frame
	print("REVIEW RESULT: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

func _test_playback(review: Node) -> void:
	review.set_one_shot(false)
	review.set_loop(true)
	review.select_clip("Walk_loop")
	review.seek_animation(0.4)
	review.play_clip()
	review.step_frame(1)
	_check(_near(review.get_current_animation_time(), 0.4 + 1.0 / 30.0) and not review.is_clip_playing(), "frame step pauses and advances exactly 1/30 s")
	review.step_frame(-1)
	_check(_near(review.get_current_animation_time(), 0.4), "back step subtracts 1/30 s")
	review.set_speed(0.5)
	review.play_clip()
	review.advance_playback(0.2)
	_check(_near(review.get_current_animation_time(), 0.5), "half speed: 0.2 s advances 0.1 s")
	review.pause_clip()
	review.advance_playback(0.2)
	_check(_near(review.get_current_animation_time(), 0.5), "pause holds time")
	review.set_speed(1.0)
	review.set_one_shot(true)
	review.select_clip("Wave")
	var length: float = review.get_current_clip_length()
	review.seek_animation(length)
	var last := _poses(review._skeleton)
	review.seek_animation(length - 0.01)
	review.play_clip()
	review.advance_playback(0.1)
	review.advance_playback(1.0)
	_check(_near(review.get_current_animation_time(), length) and not review.is_clip_playing(), "one-shot holds exact last time")
	_check(_same_pose(last, _poses(review._skeleton)), "one-shot holds last bone pose")
	review.set_one_shot(false)
	review.set_loop(true)
	review.select_clip("Walk_loop")
	length = review.get_current_clip_length()
	review.seek_animation(length - 0.01)
	review.play_clip()
	review.advance_playback(0.03)
	_check(_near(review.get_current_animation_time(), 0.02) and review.is_clip_playing(), "loop wraps")
	review.set_loop(false)
	review.seek_animation(length - 0.01)
	review.advance_playback(0.03)
	_check(_near(review.get_current_animation_time(), length) and not review.is_clip_playing(), "loop off stops at end")
	_check(not review.play_clip("DoesNotExist"), "unknown clip rejected")
	review._on_clip_selected(review.get_clip_names().find("Talk_loop"))
	_check(review._animation_player.assigned_animation == "Talk_loop" and _near(review.get_current_animation_time(), 0.0), "UI clip selection samples new clip immediately")

func _test_hands(review: Node) -> void:
	var skeleton: Skeleton3D = review._skeleton
	review.select_clip("Repair")
	review.seek_animation(0.5)
	var base := _poses(skeleton)
	for pose in POSES:
		review.select_clip("Repair")
		review.seek_animation(0.5)
		base = _poses(skeleton)
		for side in ["left", "right", "both"]:
			review.set_hand_pose(pose, side)
			var changed := 0
			var outside := 0
			for bone in skeleton.get_bone_count():
				var name := skeleton.get_bone_name(bone)
				var allowed: bool = review._is_finger_bone(name) and (side == "both" or name.contains("LeftHand" if side == "left" else "RightHand"))
				if not base[bone].is_equal_approx(skeleton.get_bone_pose(bone)):
					if allowed:
						changed += 1
					else:
						outside += 1
			_check(outside == 0 and (pose != "HandFist" or changed > 0), "%s %s preserves other bones (%d changed, %d outside)" % [pose, side, changed, outside])
			var animation: Animation = review._animation_player.get_animation(pose)
			var matches := true
			for track in animation.get_track_count():
				var path := animation.track_get_path(track)
				if path.get_subname_count() != 1 or animation.track_get_type(track) != Animation.TYPE_ROTATION_3D:
					continue
				var name := String(path.get_subname(0))
				if not review._is_finger_bone(name) or (side != "both" and not name.contains("LeftHand" if side == "left" else "RightHand")):
					continue
				var expected: Quaternion = animation.track_get_key_value(track, 0)
				var actual := skeleton.get_bone_pose_rotation(skeleton.find_bone(name))
				matches = matches and absf(expected.dot(actual)) > 0.99999
			_check(matches, "overlay matches authored " + pose + " rotations")
			review.set_hand_pose("None")
			_check(_same_pose(base, _poses(skeleton)), "removing overlay restores body pose")
	review.set_hand_pose("HandFist", "left")
	review.play_clip()
	review.advance_playback(0.1)
	review.pause_clip()
	review.set_hand_pose("None")
	var restored := _poses(skeleton)
	review.select_clip("Repair")
	review.seek_animation(0.6)
	_check(_same_pose(restored, _poses(skeleton)), "overlay removal restores animated body without accumulated curls")

func _test_lips(review: Node) -> void:
	review._on_lip_play_pressed()
	_check(review._audio_player.playing and review._lip_seek.max_value > 1.0, "LipSync play_line starts audio; scrub spans full line")
	review._on_lip_pause_pressed()
	_check(review._audio_player.stream_paused, "lip panel pause")
	review._on_lip_seek_changed(0.5)
	var weights: Dictionary = review._lip_sync.get_current_weights()
	_check(weights == review._lip_sync.weights_at(0.5) and weights.values().any(func(value): return value > 0.0), "LipSync seek updates current weights")
	var mesh: MeshInstance3D = review._face_mesh
	var applied := true
	for shape in weights:
		var index := mesh.find_blend_shape_by_name(shape)
		if index >= 0:
			applied = applied and _near(mesh.get_blend_shape_value(index), weights[shape])
	_check(applied, "speech weights applied to v4 face")
	review._on_lip_pause_pressed()
	_check(not review._audio_player.stream_paused, "lip panel resumes")
	review._lip_sync.stop(true)

func _test_walk(review: Node, character: String) -> void:
	review.set_one_shot(false)
	review.set_loop(false)
	review.set_speed(1.0)
	review.play_clip("Walk_loop")
	var count := int(floor(review.get_current_clip_length() * 30.0))
	var root_sum := 0.0
	var hip_sum := 0.0
	var summaries: Array[Dictionary] = []
	for side in 2:
		summaries.append({"contact_frames": 0, "sum": 0.0, "max": 0.0, "ankle_sum": 0.0, "min_y": INF, "max_y": -INF})
	for frame in count:
		review.advance_playback(1.0 / 30.0)
		var values: Dictionary = review.get_measurements()
		root_sum += values.root_speed
		hip_sum += values.hip_speed
		for side in 2:
			var foot: Dictionary = values["left" if side == 0 else "right"]
			var summary: Dictionary = summaries[side]
			summary.ankle_sum += foot.foot_speed
			summary.min_y = minf(summary.min_y, foot.height)
			summary.max_y = maxf(summary.max_y, foot.height)
			if foot.contact_samples > 0:
				summary.contact_frames += 1
				summary.sum += foot.slide_speed
				summary.max = maxf(summary.max, foot.slide_speed)
	print("WALK %s duration=%.6f samples=%d dt=1/30 root_mean=%.6f hip_mean=%.6f m/s" % [character, review.get_current_clip_length(), count, root_sum / count, hip_sum / count])
	for side in 2:
		var summary: Dictionary = summaries[side]
		_check(summary.contact_frames > 0 and is_finite(summary.sum), "Walk_loop has measured " + ("left" if side == 0 else "right") + " floor contacts")
		print("  %s contact_frames=%d slide_mean=%.6f slide_max=%.6f ankle_mean=%.6f m/s sole_y=[%.6f, %.6f] m" % ["L" if side == 0 else "R", summary.contact_frames, summary.sum / maxi(summary.contact_frames, 1), summary.max, summary.ankle_sum / count, summary.min_y, summary.max_y])

func _poses(skeleton: Skeleton3D) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for bone in skeleton.get_bone_count():
		result.append(skeleton.get_bone_pose(bone))
	return result

func _same_pose(a: Array[Transform3D], b: Array[Transform3D]) -> bool:
	for bone in a.size():
		if not a[bone].is_equal_approx(b[bone]):
			return false
	return true

func _near(actual: float, expected: float) -> bool:
	return absf(actual - expected) < 0.00001

func _check(condition: bool, message: String) -> bool:
	_checks += 1
	if condition:
		print("  ok ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
	return condition
