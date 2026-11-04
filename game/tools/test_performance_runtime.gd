## Performance changes must preserve boot contact, gait cycles and independent actors.
extends SceneTree

const Meter = preload("res://scripts/review/foot_slide.gd")
var _checks := 0
var _failures := 0

func _init() -> void:
	_run.call_deferred()

func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		print("FAIL ", label)

func _run() -> void:
	for id in ["Kai", "Amara", "Mei", "Rafi", "Ferreira"]:
		var path := "res://assets/characters/CH_%s/CH_%s.glb" % [id, id]
		var actor := AssetGeometry.load_glb(path)
		var copy := AssetGeometry.load_glb(path)
		_check(actor != null and copy != null and actor != copy, id + " cached actors are distinct")
		root.add_child(actor)
		root.add_child(copy)
		_check(actor.find_children("*", "MeshInstance3D", true, false).size() == copy.find_children("*", "MeshInstance3D", true, false).size(), id + " cache retains all meshes")
		var player := actor.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var rig := actor.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		var copy_player := copy.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var copy_rig := copy.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		copy_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		_check(rig != copy_rig, id + " independent skeleton")
		var reference := LocomotionClips.new()
		_check(reference.prepare(player, rig), id + " reference gait analysis")
		_check(not copy_player.has_animation_library("motion"), id + " cached source has no instance's prepared library")
		var baked := LocomotionClips.new()
		_check(baked.prepare(copy_player, copy_rig, path), id + " baked preparation")
		_check(baked._surface_meter == null, id + " validated bake skips runtime analysis")
		for gait in reference.gaits:
			for key in ["speed", "period", "start", "source_length"]:
				_check(absf(reference.measurements[gait][key] - baked.measurements[gait][key]) < 0.000001, id + " " + gait + " " + key)
			var expected := player.get_animation("motion/" + gait + "_cycle")
			var actual := copy_player.get_animation("motion/" + gait + "_cycle")
			_check(expected.get_track_count() == actual.get_track_count(), id + " cycle retains all tracks")
			var same := true
			var max_error := 0.0
			for track in expected.get_track_count():
				if expected.track_get_path(track) != actual.track_get_path(track) or expected.track_get_key_count(track) != actual.track_get_key_count(track):
					same = false
					continue
				for key in range(0, expected.track_get_key_count(track), 30):
					var a = expected.track_get_key_value(track, key)
					var b = actual.track_get_key_value(track, key)
					if a is Quaternion:
						var error := Vector4(a.x, a.y, a.z, a.w).distance_to(Vector4(b.x, b.y, b.z, b.w))
						max_error = maxf(max_error, error)
						same = same and error < 0.000001
					else:
						max_error = maxf(max_error, a.distance_to(b))
						same = same and a.distance_to(b) < 0.000001
			_check(same, id + " " + gait + " baked cycle matches reference (max error %.9f)" % max_error)
		var meter := Meter.new()
		meter.setup(actor, rig)
		# Translation/yaw/pitch verify world-space Y, rather than ankle or bind height.
		actor.transform = Transform3D(Basis.from_euler(Vector3(0.07, 0.4, -0.03)), Vector3(2, 1.3, -3))
		for clip in ["Walk_loop", "Run_loop", "Sprint_loop", "Idle_loop"]:
			player.play("motion/" + clip)
			for phase in [0.0, 0.2, 0.5, 0.8]:
				player.seek(player.current_animation_length * phase, true)
				var full := meter.sample(1.0 / 60.0)
				var heights := meter.sample_heights()
				for side in ["left", "right"]:
					_check(absf(full[side].height - heights[side].height) < 0.00001, id + " exact " + clip + " " + side + " boot height")
		actor.free()
		copy.free()
	_check(AssetGeometry._scenes.size() <= AssetGeometry.CACHE_LIMIT, "parsed-scene cache is bounded")
	# A mismatched model never uses another revision's calibration.
	var invalid_path := OS.get_temp_dir().path_join("lla-perf-stale-%d" % OS.get_process_id())
	DirAccess.make_dir_absolute(invalid_path)
	var invalid_glb := invalid_path.path_join("CH_Kai.glb")
	var invalid := FileAccess.open(invalid_glb, FileAccess.WRITE)
	invalid.store_string("different source revision")
	invalid.close()
	var stale := LocomotionClips.new()
	stale.gaits = ["Walk_loop", "Run_loop", "Sprint_loop"]
	_check(stale._baked_measurements(invalid_glb).is_empty(), "stale source hash falls back to analysis")
	DirAccess.remove_absolute(invalid_glb)
	DirAccess.remove_absolute(invalid_path)
	print("PERFORMANCE RUNTIME RESULT: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)
