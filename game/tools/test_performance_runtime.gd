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
	await _test_threaded_geometry()
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
	await _test_loading_transitions()
	print("PERFORMANCE RUNTIME RESULT: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

var _last_tick := 0
var _longest_tick := 0.0
var _tick_count := 0

func _heartbeat() -> void:
	if _last_tick == 0:
		return
	var now := Time.get_ticks_usec()
	_longest_tick = maxf(_longest_tick, (now - _last_tick) / 1000.0)
	_last_tick = now
	_tick_count += 1

func _start_monitor() -> void:
	_last_tick = Time.get_ticks_usec()
	_longest_tick = 0.0
	_tick_count = 0

func _stop_monitor(label: String) -> void:
	_last_tick = 0
	_check(_tick_count > 1, label + " yields moving loading frames")
	_check(_longest_tick < 50.0, label + " main-thread interval <50 ms (%.3f)" % _longest_tick)

func _test_threaded_geometry() -> void:
	process_frame.connect(_heartbeat)
	for id in ["Kai", "Amara", "Mei", "Rafi", "Ferreira", "PR_MissionTable"]:
		var path := "res://assets/characters/CH_%s/CH_%s.glb" % [id, id] if not id.begins_with("PR_") else "res://assets/props/%s/%s.glb" % [id, id]
		_start_monitor()
		_check(await AssetGeometry.prepare(path, self), id + " threaded raw preparation succeeds")
		await process_frame
		_stop_monitor(id + " raw load")
		var threaded := AssetGeometry.load_glb(path)
		# Independent original decoder catches omitted mesh-conversion extensions,
		# transforms, skeletons, face layers or clip tracks, not just cached copies.
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
		_check(document.append_from_file(path, state) == OK, id + " original raw decoder")
		var original := document.generate_scene(state)
		var meshes := threaded.find_children("*", "MeshInstance3D", true, false)
		var reference := original.find_children("*", "MeshInstance3D", true, false)
		_check(meshes.size() == reference.size() and not meshes.is_empty(), id + " every original mesh retained")
		for index in mini(meshes.size(), reference.size()):
			var a := meshes[index] as MeshInstance3D
			var b := reference[index] as MeshInstance3D
			_check(a.name == b.name and a.transform.is_equal_approx(b.transform), id + " mesh transform " + a.name)
			_check(a.mesh.get_surface_count() == b.mesh.get_surface_count(), id + " mesh surfaces " + a.name)
			for surface in a.mesh.get_surface_count():
				_check(a.mesh.surface_get_arrays(surface).hash() == b.mesh.surface_get_arrays(surface).hash(), id + " exact vertices/indices/weights " + a.name)
				var source := a.mesh.surface_get_material(surface) as StandardMaterial3D
				var expected := b.mesh.surface_get_material(surface) as StandardMaterial3D
				if source != null and expected != null and source.albedo_texture != null:
					_check(source.albedo_texture.get_size() == expected.albedo_texture.get_size(), id + " full texture resolution " + a.name)
					_check(source.albedo_texture.get_image().get_data().slice(0, expected.albedo_texture.get_image().get_data().size()) == expected.albedo_texture.get_image().get_data(), id + " unchanged base pixels " + a.name)
		if not id.begins_with("PR_"):
			_start_monitor()
			_check(await LocomotionClips.prewarm(threaded, path, self), id + " gait worker succeeds")
			await process_frame
			_stop_monitor(id + " gait worker")
		threaded.free()
		original.free()

func _test_loading_transitions() -> void:
	_check(not await AssetGeometry.prepare("res://missing-perf-model.glb", self), "missing threaded GLB fails without blocking")
	LoadTrace.enabled = true
	LoadTrace.steps.clear()
	var main := preload("res://scenes/main.tscn").instantiate()
	var slot := OS.get_temp_dir().path_join("lla-perf-runtime-%d.json" % OS.get_process_id())
	main.save_path = slot
	main.legacy_save_path = slot + ".legacy"
	_start_monitor()
	root.add_child(main)
	while not main.title_ready:
		await process_frame
	_stop_monitor("production title")
	_start_monitor()
	await main._launch_campaign({})
	await process_frame
	_stop_monitor("production new campaign")
	var campaign := main._campaign as Chapter1Campaign
	_check(campaign.incremental_loading and not campaign.loading, "production uses incremental loader and completes")
	_check(campaign._crew.bodies.size() == 5, "title prepares all five cast actors")
	for id in campaign._crew.bodies:
		_check(campaign._crew.bodies[id].character.find_children("*", "MeshInstance3D", true, false).size() > 0, id + " prepared body has visible geometry")
	while main.preparation._room_busy:
		await process_frame
	_evict_room("LOC-03")
	_start_monitor()
	campaign.route.start_at("EX-CH01-S04")
	campaign._sync_route_projection()
	campaign._refresh_world()
	await campaign.wait_loading()
	await process_frame
	_stop_monitor("production garden entry")
	_check(campaign._room.room_id == "LOC-03" and campaign._player.character != null, "garden transition keeps room/player ready")
	_evict_room("LOC-01")
	_start_monitor()
	campaign._start_extended("EX-CH05-S02")
	await campaign.wait_loading()
	await process_frame
	_stop_monitor("production full cast entry")
	_check(campaign._crew.local_ids.size() == 5, "full cast is placed exactly once")
	# A lamp must advance under the same frame pump used while workers load.
	var card := LoadingCard.new()
	root.add_child(card)
	for frame in 4:
		await process_frame
	_check(card.ticks >= 3, "loading lamp keeps processing")
	card.free()
	# Finish optional look-ahead before tearing down this test's world.
	while main.preparation._room_busy:
		await process_frame
	var sync_decode := false
	for step in LoadTrace.steps:
		sync_decode = sync_decode or String(step.step).begins_with("glb_decode:")
	_check(not sync_decode, "production transitions never escape to synchronous GLB decode")
	# M1-36: a ready exterior (LOC-10, EX-CH04-S06 under its verified work lights) enters on the LOLA terrain
	# through the same card, its heightfield and tiles prepared off the main thread.
	while main.preparation._room_busy:
		await process_frame
	# The suited cast still decodes its EVA GLBs on the main thread (board M1-113), so warm them with S06 first and
	# measure the terrain on the next scene in the same room, which prepares its terrain again from nothing.
	campaign._start_extended("EX-CH04-S06")
	await campaign.wait_loading()
	while main.preparation._room_busy:
		await process_frame
	var traced := LoadTrace.steps.size()
	_start_monitor()
	campaign._start_extended("EX-CH04-S07")
	await campaign.wait_loading()
	await process_frame
	_stop_monitor("production terrain exterior entry")
	_check(campaign._room.room_id == "LOC-10" and campaign._room.on_terrain() and campaign._terrain != null, "LOC-10 stands on the streamed LOLA terrain")
	_check(campaign._terrain != null and campaign._terrain.stream.settled() and campaign._terrain.stream.rocks.size() > 0, "terrain rocks and LOD settled before the card closes")
	var ground := PhysicsRayQueryParameters3D.create(campaign._player.global_position + Vector3.UP * 5.0, campaign._player.global_position + Vector3.DOWN * 5.0, 1)
	_check(not campaign._player.get_world_3d().direct_space_state.intersect_ray(ground).is_empty(), "player stands over terrain collision")
	var terrain_sync := false
	for step in LoadTrace.steps.slice(traced):
		terrain_sync = terrain_sync or String(step.step).begins_with("glb_decode:")
	_check(not terrain_sync, "terrain exterior entry never escapes to synchronous GLB decode")
	LoadTrace.enabled = false
	main.free()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(slot + suffix):
			DirAccess.remove_absolute(slot + suffix)

func _evict_room(room_id: String) -> void:
	for path in LoadPreparation.room_paths(room_id):
		AssetGeometry._scenes.erase(path)
		AssetGeometry._recent.erase(path)
