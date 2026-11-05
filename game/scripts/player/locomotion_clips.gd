extends RefCounted
class_name LocomotionClips

const SAMPLE_RATE: float = 120.0
const GAIT_SAMPLES: int = 120
const FootSlideScript: Script = preload("res://scripts/review/foot_slide.gd")
# Increment when gait measurement or cycle sampling changes; regenerate with
# tools/bake_locomotion.gd. Source GLB hashes also reject stale measurements.
const BAKE_VERSION := 1

var measurements: Dictionary = {}
var gaits: Array[String] = []
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _surface_meter: RefCounted
static var _prepared_cache: Dictionary = {}

## Builds resources on a worker from read-only source animations. No Nodes are
## passed across the thread boundary; the resulting library is published on main.
static func prewarm(actor: Node3D, source_path: String, tree: SceneTree) -> bool:
	var key := "%s:%d" % [source_path, FileAccess.get_modified_time(source_path)]
	if _prepared_cache.has(key):
		return true
	var players := actor.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return false
	var player := players[0] as AnimationPlayer
	var sources := {}
	for id in player.get_animation_list():
		sources[id] = player.get_animation(id)
	var job := PreparationJob.new()
	job.start(_prepare_resources.bind(sources, source_path), "gait_clips:" + source_path)
	var result := await job.finish(tree)
	if result.is_empty():
		return false
	_prepared_cache[key] = result
	if LoadTrace.enabled:
		LoadTrace.steps.append({"step": "worker_gait_clips:" + source_path, "ms": result.worker_ms})
	return true

static func _prepare_resources(sources: Dictionary, source_path: String) -> Dictionary:
	var start := Time.get_ticks_usec()
	var builder := LocomotionClips.new()
	for pair in [["Walk_loop", "WalkBasic_loop"], ["Run_loop", "RunBasic_loop"], ["Sprint_loop", "Run_loop"]]:
		var chosen: String = pair[0] if sources.has(pair[0]) else pair[1]
		if pair[0] == "Sprint_loop" and not sources.has(chosen):
			chosen = builder.gaits[1]
		if not sources.has(chosen):
			return {}
		builder.gaits.append(chosen)
	var baked := builder._baked_measurements(source_path)
	if baked.is_empty():
		# The incremental fallback below performs the original measurement on main.
		return {}
	var library := AnimationLibrary.new()
	for id in sources:
		var clean := (sources[id] as Animation).duplicate() as Animation
		builder._strip_root(clean, id)
		library.add_animation(id, clean)
	for id in builder.gaits:
		library.add_animation(id + "_cycle", builder._cycle(library.get_animation(id), baked[id]))
	return {"library": library, "gaits": builder.gaits, "measurements": baked, "worker_ms": (Time.get_ticks_usec() - start) / 1000.0}

static func prewarm_incremental(actor: Node3D, source_path: String, tree: SceneTree) -> bool:
	var player := actor.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var rig := actor.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var builder := LocomotionClips.new()
	builder._player = player
	builder._skeleton = rig
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for pair in [["Walk_loop", "WalkBasic_loop"], ["Run_loop", "RunBasic_loop"], ["Sprint_loop", "Run_loop"]]:
		var chosen: String = pair[0] if player.has_animation(pair[0]) else pair[1]
		if not player.has_animation(chosen):
			return false
		builder.gaits.append(chosen)
	var library := AnimationLibrary.new()
	for id in player.get_animation_list():
		var clean := player.get_animation(id).duplicate() as Animation
		builder._strip_root(clean, id)
		library.add_animation(id, clean)
		await tree.process_frame
	player.add_animation_library("motion", library)
	builder._surface_meter = FootSlideScript.new()
	builder._surface_meter.setup(actor, rig)
	for id in builder.gaits:
		var data := await builder._measure_incremental(id, tree)
		if data.is_empty():
			return false
		builder.measurements[id] = data
		library.add_animation(id + "_cycle", builder._cycle(library.get_animation(id), data))
		await tree.process_frame
	var key := "%s:%d" % [source_path, FileAccess.get_modified_time(source_path)]
	_prepared_cache[key] = {"library": library, "gaits": builder.gaits, "measurements": builder.measurements}
	player.stop()
	rig.reset_bone_poses()
	return true

static func bone(skeleton: Skeleton3D, suffix: String) -> int:
	for i in skeleton.get_bone_count():
		var name := skeleton.get_bone_name(i)
		if name == suffix or name.ends_with("_" + suffix) or name.ends_with(":" + suffix):
			return i
	return -1

func prepare(player: AnimationPlayer, skeleton: Skeleton3D, source_path: String = "") -> bool:
	_player = player
	_skeleton = skeleton
	var cache_key := "%s:%d" % [source_path, FileAccess.get_modified_time(source_path)] if not source_path.is_empty() and FileAccess.file_exists(source_path) else ""
	if not cache_key.is_empty() and _prepared_cache.has(cache_key):
		var cached: Dictionary = _prepared_cache[cache_key]
		gaits = (cached.gaits as Array[String]).duplicate()
		measurements = (cached.measurements as Dictionary).duplicate(true)
		player.add_animation_library("motion", cached.library as AnimationLibrary)
		player.stop()
		skeleton.reset_bone_poses()
		return true
	for suffix in ["Hips", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]:
		if bone(skeleton, suffix) < 0:
			push_error("Locomotion needs Mixamo bone " + suffix)
			return false
	for pair in [["Walk_loop", "WalkBasic_loop"], ["Run_loop", "RunBasic_loop"], ["Sprint_loop", "Run_loop"]]:
		var chosen: String = pair[0] if player.has_animation(pair[0]) else pair[1]
		if pair[0] == "Sprint_loop" and not player.has_animation(chosen):
			chosen = gaits[1]
		if not player.has_animation(chosen):
			push_error("Locomotion needs " + chosen)
			return false
		gaits.append(chosen)
	if not player.has_animation("Idle_loop"):
		return false
	var library := AnimationLibrary.new()
	for name in player.get_animation_list():
		var source := player.get_animation(name)
		var clean := source.duplicate() as Animation
		_strip_root(clean, name)
		library.add_animation(name, clean)
	player.add_animation_library("motion", library)
	var baked := _baked_measurements(source_path)
	if baked.is_empty():
		_surface_meter = FootSlideScript.new()
		_surface_meter.setup(player.get_node(player.root_node), skeleton)
	for name in gaits:
		if measurements.has(name) and measurements[name].has("speed"):
			continue
		var measured: Dictionary = baked.get(name, {})
		if measured.is_empty():
			if _surface_meter == null:
				_surface_meter = FootSlideScript.new()
				_surface_meter.setup(player.get_node(player.root_node), skeleton)
			measured = _measure(name)
		if measured.is_empty():
			return false
		measurements[name] = measured
		library.add_animation(name + "_cycle", _cycle(library.get_animation(name), measured))
	if not cache_key.is_empty():
		_prepared_cache[cache_key] = {"library": library, "gaits": gaits.duplicate(), "measurements": measurements.duplicate(true)}
	player.stop()
	skeleton.reset_bone_poses()
	return true

func _baked_measurements(source_path: String) -> Dictionary:
	if source_path.is_empty():
		return {}
	var path := "res://resources/player/gaits/" + source_path.get_file().get_basename().to_lower() + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version") != BAKE_VERSION or data.get("source_sha256") != FileAccess.get_sha256(source_path):
		return {}
	var measured = data.get("measurements", {})
	if not measured is Dictionary:
		return {}
	for gait in gaits:
		if not measured.get(gait) is Dictionary:
			return {}
		for key in ["speed", "period", "start", "min_toe_y", "source_length"]:
			if not measured[gait].has(key):
				return {}
	return measured

func _strip_root(animation: Animation, name: String) -> void:
	for track in animation.get_track_count():
		var path := String(animation.track_get_path(track))
		if not path.ends_with(":mixamorig_Hips") and not path.ends_with(":mixamorig:Hips") and not path.ends_with(":Hips"):
			continue
		if animation.track_get_type(track) == Animation.TYPE_POSITION_3D:
			var first: Vector3 = animation.track_get_key_value(track, 0)
			var last: Vector3 = animation.track_get_key_value(track, animation.track_get_key_count(track) - 1)
			var distance := 0.0
			var previous := first
			for key in animation.track_get_key_count(track):
				var value: Vector3 = animation.track_get_key_value(track, key)
				distance += Vector2(value.x - previous.x, value.z - previous.z).length()
				previous = value
			measurements[name] = {"root_distance": distance, "root_mean_speed": distance / animation.length}
			if not name.ends_with("_loop") and distance > 0.25:
				print("ROOT %s distance=%.6f m speed=%.6f m/s (removed)" % [name, distance, distance / animation.length])
			for key in animation.track_get_key_count(track):
				var value: Vector3 = animation.track_get_key_value(track, key)
				if name.ends_with("_loop"):
					var drift := (last - first) * animation.track_get_key_time(track, key) / animation.length
					value.x -= drift.x
					value.z -= drift.z
				else:
					value.x = 0.0
					value.z = 0.0
				animation.track_set_key_value(track, key, value)
		if animation.track_get_type(track) == Animation.TYPE_ROTATION_3D and name.begins_with("Turn"):
			for key in animation.track_get_key_count(track):
				var q: Quaternion = animation.track_get_key_value(track, key)
				var yaw := Basis(q).get_euler().y
				animation.track_set_key_value(track, key, Quaternion(Vector3.UP, -yaw) * q)

func _measure(name: String) -> Dictionary:
	var animation := _player.get_animation("motion/" + name)
	var count := maxi(32, int(ceil(animation.length * SAMPLE_RATE)))
	var dt := animation.length / count
	var positions: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
	var min_height: Array[float] = [INF, INF]
	var surface_speeds: Array[float] = []
	_surface_meter.reset()
	_player.play("motion/" + name)
	for frame in count + 1:
		_player.seek(minf(frame * dt, animation.length - 0.00001), true)
		var surface: Dictionary = _surface_meter.sample(dt)
		for side in ["left", "right"]:
			if surface[side].contact_samples > 0:
				surface_speeds.append(surface[side].slide_speed)
		for side in 2:
			var index := bone(_skeleton, "LeftToeBase" if side == 0 else "RightToeBase")
			var p := _skeleton.global_transform * _skeleton.get_bone_global_pose(index).origin
			positions[side].append(p)
			min_height[side] = minf(min_height[side], p.y)
	var speeds: Array[float] = []
	for side in 2:
		for frame in range(1, count):
			var p := positions[side][frame]
			var previous := positions[side][frame - 1]
			var v := (p - previous) / dt
			# Stance is low and moving backwards; swing and toe-off are excluded.
			if p.y < min_height[side] + 0.035 and previous.y < min_height[side] + 0.035 and v.z < -0.2:
				speeds.append(-v.z)
	if speeds.size() < 4:
		push_error("No measurable stance in " + name)
		return {}
	speeds.sort()
	var speed: float = speeds[speeds.size() / 2]
	var surface_mean := 0.0
	for value in surface_speeds:
		surface_mean += value / surface_speeds.size()
	# Prefer the boot surface when it agrees with the joint; reject swing scuffs.
	if surface_mean > 0.0 and absf(surface_mean - speed) / speed < 0.15:
		speed = surface_mean
	var peaks: Array[int] = []
	for frame in range(2, count - 2):
		if positions[0][frame].z >= positions[0][frame - 1].z and positions[0][frame].z > positions[0][frame + 1].z:
			if peaks.is_empty() or (frame - peaks[-1]) * dt > 0.35:
				peaks.append(frame)
	var start := float(peaks[0]) * dt if not peaks.is_empty() else 0.0
	var period := float(peaks[1] - peaks[0]) * dt if peaks.size() > 1 else animation.length
	var result := {"speed": speed, "surface_speed": surface_mean, "surface_samples": surface_speeds.size(), "period": period, "start": start, "distance": speed * period, "samples": speeds.size(), "min_toe_y": min_height, "source_length": animation.length}
	print("STRIDE %s speed=%.6f m/s period=%.6f m/cycle=%.6f stance_samples=%d source=%.6f s" % [name, speed, period, speed * period, speeds.size(), animation.length])
	print("  authored boot surface mean=%.6f m/s contacts=%d" % [surface_mean, surface_speeds.size()])
	return result

func _cycle(source: Animation, data: Dictionary) -> Animation:
	source = source.duplicate() as Animation   # sampled through cubic curves below; the clip itself stays as it plays
	var result := Animation.new()
	result.length = 1.0
	result.loop_mode = Animation.LOOP_LINEAR
	for track in source.get_track_count():
		var type := source.track_get_type(track)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var target := result.add_track(type)
		result.track_set_path(target, source.track_get_path(track))
		if type == Animation.TYPE_ROTATION_3D:   # sample a smooth curve through the 30 fps keys, not straight segments
			source.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		for frame in GAIT_SAMPLES + 1:
			var phase := float(frame) / GAIT_SAMPLES
			var time := fposmod(float(data.start) + phase * float(data.period), source.length)
			var value: Variant = _value(source, track, type, time)
			# Close imperfect source seams over the last 12% of a stride.
			if phase > 0.88:
				var first: Variant = _value(source, track, type, float(data.start))
				var weight := smoothstep(0.88, 1.0, phase)
				value = value.slerp(first, weight) if type == Animation.TYPE_ROTATION_3D else value.lerp(first, weight)
			result.track_insert_key(target, phase, value)
	return result

func _value(animation: Animation, track: int, type: Animation.TrackType, time: float) -> Variant:
	match type:
		Animation.TYPE_ROTATION_3D: return animation.rotation_track_interpolate(track, time)
		Animation.TYPE_SCALE_3D: return animation.scale_track_interpolate(track, time)
		_: return animation.position_track_interpolate(track, time)

func _measure_incremental(name: String, tree: SceneTree) -> Dictionary:
	var animation := _player.get_animation("motion/" + name)
	var count := maxi(32, int(ceil(animation.length * SAMPLE_RATE)))
	var dt := animation.length / count
	var positions: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
	var min_height: Array[float] = [INF, INF]
	var surface_speeds: Array[float] = []
	_surface_meter.reset()
	_player.play("motion/" + name)
	for frame in count + 1:
		if frame % 4 == 0:
			await tree.process_frame
		_player.seek(minf(frame * dt, animation.length - 0.00001), true)
		var surface: Dictionary = _surface_meter.sample(dt)
		for side in ["left", "right"]:
			if surface[side].contact_samples > 0:
				surface_speeds.append(surface[side].slide_speed)
		for side in 2:
			var index := bone(_skeleton, "LeftToeBase" if side == 0 else "RightToeBase")
			var p := _skeleton.global_transform * _skeleton.get_bone_global_pose(index).origin
			positions[side].append(p)
			min_height[side] = minf(min_height[side], p.y)
	var speeds: Array[float] = []
	for side in 2:
		for frame in range(1, count):
			var p := positions[side][frame]
			var previous := positions[side][frame - 1]
			var v := (p - previous) / dt
			# Stance is low and moving backwards; swing and toe-off are excluded.
			if p.y < min_height[side] + 0.035 and previous.y < min_height[side] + 0.035 and v.z < -0.2:
				speeds.append(-v.z)
	if speeds.size() < 4:
		push_error("No measurable stance in " + name)
		return {}
	speeds.sort()
	var speed: float = speeds[speeds.size() / 2]
	var surface_mean := 0.0
	for value in surface_speeds:
		surface_mean += value / surface_speeds.size()
	# Prefer the boot surface when it agrees with the joint; reject swing scuffs.
	if surface_mean > 0.0 and absf(surface_mean - speed) / speed < 0.15:
		speed = surface_mean
	var peaks: Array[int] = []
	for frame in range(2, count - 2):
		if positions[0][frame].z >= positions[0][frame - 1].z and positions[0][frame].z > positions[0][frame + 1].z:
			if peaks.is_empty() or (frame - peaks[-1]) * dt > 0.35:
				peaks.append(frame)
	var start := float(peaks[0]) * dt if not peaks.is_empty() else 0.0
	var period := float(peaks[1] - peaks[0]) * dt if peaks.size() > 1 else animation.length
	var result := {"speed": speed, "surface_speed": surface_mean, "surface_samples": surface_speeds.size(), "period": period, "start": start, "distance": speed * period, "samples": speeds.size(), "min_toe_y": min_height, "source_length": animation.length}
	print("STRIDE %s speed=%.6f m/s period=%.6f m/cycle=%.6f stance_samples=%d source=%.6f s" % [name, speed, period, speed * period, speeds.size(), animation.length])
	print("  authored boot surface mean=%.6f m/s contacts=%d" % [surface_mean, surface_speeds.size()])
	return result
