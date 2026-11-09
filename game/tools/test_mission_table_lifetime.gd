extends SceneTree
const PanelScene = preload("res://scenes/ui/mission_table_panel.tscn")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Director = preload("res://scripts/core/campaign_director.gd")
var checks := 0
var failures := 0
var shots: Array[String] = []
var errors := ErrorRecorder.new()

class ErrorRecorder extends Logger:
	var mutex := Mutex.new()
	var messages := PackedStringArray()
	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, kind: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if kind != Logger.ERROR_TYPE_WARNING:
			mutex.lock()
			messages.append(code + " " + rationale)
			mutex.unlock()
	func snapshot() -> PackedStringArray:
		mutex.lock()
		var result := messages.duplicate()
		mutex.unlock()
		return result

func _init() -> void:
	OS.add_logger(errors)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_cmdline_user_args().has("--capture"):
		root.always_on_top = true
		root.grab_focus()
	var route := Route.new(Director.new())
	route.start_at("EX-CH01-S07")
	var before: Dictionary = route.director().snapshot()
	for large in [false, true]:
		var panel := _panel(route, large)
		await _frames(6)
		var target := panel.find_child("Choice_1_air_production_0", true, false) as Control
		var scroll := panel.find_child("TableBodyScroll", true, false) as ScrollContainer
		var guide := panel.find_child("GuideStep1", true, false) as Control
		_check(target != null and root.gui_get_focus_owner() == target, "real guided choice retains focus at " + str(large))
		_check(guide != null and scroll.get_global_rect().encloses(guide.get_global_rect()), "guide remains visible after layout at " + str(large))
		_check(scroll.scroll_vertical == 0, "guided layout resets to top at " + str(large))
		await _capture("large" if large else "normal")
		panel.close()
		panel.free()
		await _frames(4)
	for mode in range(3):
		var panel := _panel(route, false)
		await _frames(6)
		var target := panel.find_child("Choice_1_air_production_0", true, false) as Control
		_check(target != null, "production guided target exists for lifetime case " + str(mode))
		panel._focus_later(target)
		# Match the real deferred-call order: this waiter runs before focus resumes.
		await process_frame
		if mode == 1:
			await process_frame
		if mode == 2:
			panel.queue_free()
		else:
			panel.free()
		await _frames(4)
	_check(route.director().snapshot() == before, "layout/free paths never change campaign state")
	var captured := errors.snapshot()
	OS.remove_logger(errors)
	_check(captured.is_empty(), "no engine error after panel free: " + str(captured))
	if OS.get_cmdline_user_args().has("--capture"):
		var file := FileAccess.open("res://../production/qa/evidence/M1-118_probe.json", FileAccess.WRITE)
		_check(file != null, "native probe can be saved")
		if file != null:
			file.store_string(JSON.stringify({"checks": checks, "failures": failures, "errors": captured, "screenshots": shots}, " "))
	print("MISSION TABLE LIFETIME RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _panel(route: RefCounted, large: bool) -> MissionTablePanel:
	var panel := PanelScene.instantiate() as MissionTablePanel
	root.add_child(panel)
	panel.open(route, "p02_shift1", {"large_text": large, "timer_free": true})
	return panel

func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame

func _capture(id: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"):
		return
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var name := "M1-118_" + id + ".png"
	_check(root.get_texture().get_image().save_png("res://../production/qa/evidence/" + name) == OK, "native screenshot " + id)
	shots.append(name)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
