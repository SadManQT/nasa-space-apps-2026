extends SceneTree

const Crew = preload("res://scripts/world/campaign_crew.gd")
const Room = preload("res://scripts/world/campaign_room.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
var checks := 0
var failures := 0
var capture_dir := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
	var crew := Crew.new()
	root.add_child(crew)
	var seen := {}
	for scene_id in ["EX-CH01-S02", "EX-CH07-S06", "EX-CH05-S05", "EX-CH05-S11", "EX-CH01-S02"]:
		var room := Room.new()
		room.room_id = Contract.room_for_scene(scene_id)
		room.upcoming_scene = scene_id
		root.add_child(room)
		crew.place(scene_id, room, Vector3(0, 0, -1.5))
		_check(crew.local_ids.all(func(id): return is_zero_approx(crew.bodies[id].animation._talk_weight)), scene_id + " cut clears previous talking/listening pose before chair alignment")
		_check(not crew._seated.is_empty(), scene_id + " stages actual seated listeners")
		_check(not crew._seated.any(func(id): return crew.bodies[id] == crew.player) and crew.player.controlled, scene_id + " active player remains movable")
		var origins := {}
		var cycle_seconds := 2.0
		for id in crew._seated:
			origins[id] = crew.bodies[id].position
			seen[id] = true
			cycle_seconds = maxf(cycle_seconds, crew.bodies[id].animation.player.get_animation("motion/SitIdle_loop").length)
		print("SEATED CYCLE %s %.2f seconds" % [scene_id, cycle_seconds])
		for frame in ceili(cycle_seconds * 60.0) + 3:
			await physics_frame
			if frame % 20 != 19:
				continue
			for id in crew._seated:
				var body: PlayerController = crew.bodies[id]
				var chair := _chair_at(room, body.global_position)
				_check(chair != null, scene_id + " " + id + " sits in real visible furniture")
				if chair == null:
					continue
				var rig := body.animation.skeleton
				var pelvis := chair.to_local(rig.global_transform * rig.get_bone_global_pose(LocomotionClips.bone(rig, "Hips")).origin)
				_check(absf(pelvis.x) < 0.06, scene_id + " " + id + " centered between armrests: " + str(pelvis))
				_check(pelvis.y > 0.49 and pelvis.y < 0.59, scene_id + " " + id + " supported above 0.44 m cushion: " + str(pelvis))
				_check(pelvis.z > -0.04 and pelvis.z < 0.28, scene_id + " " + id + " clear of backrest and front edge: " + str(pelvis))
				_check(body.position.is_equal_approx(origins[id]) and not body.foot_ik_enabled, scene_id + " " + id + " retains floor collider and seated pose")
				for side in ["Left", "Right"]:
					var foot := rig.global_transform * rig.get_bone_global_pose(LocomotionClips.bone(rig, side + "Foot")).origin
					_check(foot.y > chair.global_position.y - 0.04, scene_id + " " + id + " foot stays above deck")
		await _capture(room, crew, scene_id)
		# Reusing persistent bodies at a standing scene must remove all seated offsets.
		var standing := Room.new()
		standing.room_id = "LOC-01"
		root.add_child(standing)
		crew.place("EX-CH01-S01", standing, Vector3(0, 0, -1.5))
		for id in crew.local_ids:
			var body: PlayerController = crew.bodies[id]
			_check(body.visual.position.is_zero_approx() and body.foot_ik_enabled, id + " standing scene clears seating offset and restores feet")
		# A normal caption makes the standing cast talk/listen. The next cut must
		# discard that blend before sampling the seated pelvis, not fade it later.
		crew.present_line({"speaker_id": "amara", "origin_label": "LOCAL LIVE"}, false)
		for frame in 30:
			await physics_frame
		_check(crew.bodies.amara.animation._talk_weight > 0.5, "standing dialogue establishes a talk blend before the next seated cut")
		room.free()
		standing.free()
		await process_frame
	_check(seen.size() == 5, "all five character models checked in installed seats")
	crew.free()
	await process_frame
	print("SEATED CREW RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _chair_at(room: CampaignRoom, floor_at: Vector3) -> Node3D:
	for spec in room._layout.get("props", []) + room.stage().get("props", []):
		if String(spec.get("path", "")).get_file() != "PR_CrewSeat.glb":
			continue
		var chair := room.visual_root.find_child(String(spec.id), true, false) as Node3D
		if chair != null and chair.is_visible_in_tree():
			var local := chair.to_local(floor_at)
			if Vector2(local.x, local.z - 0.3).length() < 0.15:
				return chair
	return null

func _capture(room: CampaignRoom, crew: CampaignCrew, scene_id: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	var camera := Camera3D.new()
	room.add_child(camera)
	if room.room_id == "LOC-04":
		camera.position = Vector3(2.7, 1.9, -2.3)
		camera.look_at(Vector3(0, 0.65, 0.8))
	else:
		camera.position = Vector3(3.7, 2.1, 4.8)
		camera.look_at(Vector3(0, 0.8, 0))
	camera.fov = 74
	camera.make_current()
	crew.player.hide()
	for frame in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join(scene_id + ".png"))
	crew.player.show()
	camera.free()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL " + message)
