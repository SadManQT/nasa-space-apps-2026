extends RefCounted

const PlayerScene: PackedScene = preload("res://scenes/player/player.tscn")
const CAST: Array[String] = ["CH_Kai", "CH_Amara", "CH_Mei", "CH_Rafi", "CH_Ferreira"]

static func switch_character(old: PlayerController, index: int) -> PlayerController:
	if index < 0 or index >= CAST.size():
		return old
	var parent := old.get_parent()
	var fresh := PlayerScene.instantiate() as PlayerController
	fresh.character_glb = "res://assets/characters/%s/%s.glb" % [CAST[index], CAST[index]]
	fresh.position = old.position
	fresh.rotation.y = old.visual.global_rotation.y - parent.global_rotation.y - PI
	var hold := old.animation.hold_mode if old.animation != null else PlayerAnimation.Hold.NONE
	var yaw := old.follow_camera.yaw
	var pitch := old.follow_camera.pitch
	var camera_transform := old.follow_camera.global_transform
	var anchor := old.follow_camera._anchor
	var arm_length := old.follow_camera._arm_length
	var quiet_time := old.follow_camera._quiet_time
	var initialized := old.follow_camera._initialized
	var camera_position := old.follow_camera.camera.position
	var mouse_mode := Input.mouse_mode
	fresh.get_node("FollowCamera").capture_mouse = old.follow_camera.capture_mouse
	fresh.process_mode = old.process_mode
	old.name = "PlayerLeaving"
	parent.remove_child(old)
	old.queue_free()
	fresh.name = "Player"
	parent.add_child(fresh)
	fresh.follow_camera.yaw = yaw
	fresh.follow_camera.pitch = pitch
	fresh.follow_camera.global_transform = camera_transform
	fresh.follow_camera._anchor = anchor
	fresh.follow_camera._arm_length = arm_length
	fresh.follow_camera._quiet_time = quiet_time
	fresh.follow_camera._initialized = initialized
	fresh.follow_camera.spring.spring_length = arm_length
	fresh.follow_camera.camera.position = camera_position
	fresh.set_hold(hold)
	Input.mouse_mode = mouse_mode
	return fresh
