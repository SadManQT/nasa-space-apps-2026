extends SceneTree
const Session = preload("res://scripts/campaign/terrain_session.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var outside := Session.new()
	_check(not outside.prepare("LOC-06", "EX-CH04-S09").accepted, "preparation outside tree rejects safely")
	outside.free()
	var indoor := Session.new()
	root.add_child(indoor)
	_check(not indoor.prepare("LOC-01", "EX-CH01-S01").enabled and indoor.get_child_count() == 0, "interior keeps its authored floor and lighting")
	indoor.free()
	var retryable := Session.new()
	root.add_child(retryable)
	_check(not retryable.prepare("LOC-06", "UNKNOWN-SCENE").accepted and retryable.stream == null and retryable.get_child_count() == 0, "missing dated row releases failed terrain without invented light")
	_check(retryable.prepare("LOC-06", "EX-CH04-S09").accepted, "failed session can retry without duplicate streams")
	retryable.free()
	for shot in [["LOC-06", "EX-CH04-S09", true], ["LOC-06", "EX-CH01-S07", false], ["LOC-09", "EX-CH04-S04", false], ["LOC-10", "EX-CH04-S06", false], ["LOC-11", "EX-CH08-S03", false]]:
		var session := Session.new()
		root.add_child(session)
		var stamp := Time.get_ticks_usec()
		var result := session.prepare(shot[0], shot[1])
		print("TERRAIN session prepare ", shot[0], " ", (Time.get_ticks_usec() - stamp) / 1000.0, " ms")
		_check(result.accepted and result.get("enabled", false), "surveyed session prepares " + shot[0])
		if result.accepted and result.get("enabled", false):
			_check(session.earth_presented == shot[2], "Earth obeys dated horizon " + shot[1])
			_check(session.stream.position == -session.origin, "provider and room share published origin " + shot[0])
			var start: Vector3 = result.player_anchor
			_check(session.move_focus(start), "local player anchor becomes valid site-frame focus " + shot[0])
			_check(session.stream.focus.is_equal_approx(start + session.origin), "stream focus has origin applied exactly once " + shot[0])
			_check(not session.prepare(shot[0], shot[1]).accepted, "configured session cannot append duplicate terrain/rig")
			await physics_frame
			var ray := PhysicsRayQueryParameters3D.create(start + Vector3.UP * 2, start - Vector3.UP * 2, 1)
			var hit := root.world_3d.direct_space_state.intersect_ray(ray)
			_check(not hit.is_empty() and hit.position.distance_to(start) < 0.08, "campaign-frame collision matches published start " + shot[0])
		var queue = session.stream._loads if session.stream != null else null
		session.free()
		var deadline := Time.get_ticks_msec() + 10000
		while is_instance_valid(queue) and Time.get_ticks_msec() < deadline:
			await process_frame
		_check(not is_instance_valid(queue), "terrain teardown drains outstanding loads")
	var pending := Session.new()
	root.add_child(pending)
	_check(not pending.prepare("LOC-12", "EX-CH08-S08").enabled, "unfinished summit placement retains authored staging")
	pending.free()
	print("TERRAIN SESSION RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + message)
